#!/usr/bin/env python3
"""Atomic control and callable source/runtime regressions with independent oracles."""
import json,struct,tempfile
from pathlib import Path
from harness import pipeline,reject,Failure

def cases():
    cases=[]
    for value in [0,3,7]:
     cases += [(f'branch-{value}',f'start(){{{value}.value;if(value<5){{17.return;}}else{{29.return;}}}}',17 if value<5 else 29,{}),
     (f'while-{value}',f'start(){{0.total.mutable;0.i.mutable;while(i<{value}){{total+=i;i+=1;}}total.return;}}',sum(range(value)),{}),
     (f'loop-break-{value}',f'start(){{0.i.mutable;loop{{if(i=={value}){{break;}}i+=1;}}i.return;}}',value,{})]
    cases += [('continue','start(){0.total.mutable;0.i.mutable;while(i<7){i+=1;if(i==3){continue;}total+=i;}total.return;}',25,{}),
     ('for','(Int.self)work(){Range.exclusive(0,5).indices;0.total.mutable;for(index in indices){total+=index;}total.return;}start(){7.work().return;}',10,{}),
     ('for-break','(Int.self)work(){Range.exclusive(0,7).indices;0.total.mutable;for(index in indices){if(index==3){break;}total+=index;}total.return;}start(){7.work().return;}',3,{}),
     ('for-continue','(Int.self)work(){Range.exclusive(0,7).indices;0.total.mutable;for(index in indices){if(index==3){continue;}total+=index;}total.return;}start(){7.work().return;}',18,{})]
    for v in [17,29]:
     cases += [(f'function-{v}',f'(Int.self)add(Int.delta){{(self+delta).return;}}start(){{{v}.add(7).return;}}',v+7,{}),
     (f'nested-{v}',f'(Int.self)outer(){{(Int.self)helper(){{(self+7).return;}}self.helper().return;}}start(){{{v}.outer().return;}}',v+7,{}),
     (f'default-{v}',f'(Int.self)add(Int.a,Int.b=7){{(self+a+b).return;}}start(){{{v}.add(3).return;}}',v+10,{}),
     (f'named-{v}',f'(Int.self)add(Int.a,Int.b=7){{(self+a+b).return;}}start(){{{v}.add(b:11,a:3).return;}}',v+14,{}),
     (f'callable-copy-{v}',f'callable work(Int.value) capture copy {v} {{ sum.return; }}start(){{work.call(7).drop().return;}}',v+7,{}),
     (f'callable-move-{v}',f'callable work(Int.value) capture move {v} {{ sum.return; }}start(){{work.call(7).return;}}',v+7,{}),
     (f'callable-borrow-{v}',f'callable work(Int.value) capture borrow {v} {{ capture.return; }}start(){{work.call(7).drop().return;}}',v,{})]
    for value in [0,1,63,64]:
     source='(Int.self)countdown(){if(self<=0){7.return;}else{(self-1).countdown().return;}}start(){'+str(value)+'.countdown().return;}'
     cases.append((f'recursion-{value}',source,7 if value<=63 else 175,{}))
    for value,returned in [('17',37),('true',71)]:
     cases.append(('overload-'+value,'(Int.self)pick(){(self+20).return;}(Bool.self)pick(){if(self){71.return;}else{83.return;}}start(){'+value+'.pick().return;}',returned,{}))
    cases += [
        ('do-while', 'start(){0.i.mutable;do{i+=1;}while(i<3);i.return;}', 3, {}),
        ('nested-loop', 'start(){0.i.mutable;0.total.mutable;while(i<3){i+=1;0.j.mutable;loop{j+=1;if(j==2){break;}total+=i;}}total.return;}', 6, {}),
        ('early-return', '(Int.self)work(){if(self<7){17.return;}29.return;}start(){3.work().return;}', 17, {}),
        ('six-registers', '(Int.self)add(Int.a,Int.b,Int.c,Int.d,Int.e){(self+a+b+c+d+e).return;}start(){1.add(3,7,11,17,23).return;}', 62, {}),
    ]
    # Asymmetric repeated reads make a swapped named/default binding visible
    # even in the established pure-sum scalar projection profile.
    body='(self+a+a+a+b+b+b+b+b+b+b).return;'
    for a,b in ((3,7),(11,7),(3,17),(11,17)):
        source=f'(Int.self)weighted(Int.a,Int.b=7){{{body}}}start(){{5.weighted(b:{b},a:{a}).return;}}'
        cases.append((f'named-weighted-{a}-{b}',source,5+3*a+7*b,{}))
    for a in (3,11):
        source=f'(Int.self)weighted(Int.a,Int.b=7){{{body}}}start(){{5.weighted({a}).return;}}'
        cases.append((f'default-weighted-{a}',source,5+3*a+49,{}))
    for value,selected in (('17',37),('true',71)):
        for reverse in (False,True):
            declarations=['overload (Int.self)pick(Int.value) where Any symbol picked_int {37.return;}',
                          'overload (Int.self)pick(Bool.value) where Any symbol picked_bool {71.return;}']
            if reverse: declarations.reverse()
            source=''.join(declarations)+f'start(){{7.pick({value}).return;}}'
            cases.append((f'explicit-overload-{value}-{reverse}',source,selected,{}))
    for value in (17,29):
        source='import "std.scientific" { Matrix; }.scientific;\n(Int.x)add(Int.y){(x+y).return;}start(){'+f'{value}.add(Matrix<Int>.filled(1,1,43).at(0,0)).a;a.add(7).b;"${{a}}/${{b}}".console();23.return;}}'
        cases.append((f'call-result-owned-argument-{value}',source,23,dict(kinds=[2],text=f'{value+43}/{value+50}'.encode())))
    cases.append(('call-result-loop-storage','(Int.x)next(){(x+1).return;}start(){0.i.mutable;while(i<10000){i.next().nextValue;i=nextValue;}i.console();23.return;}',23,dict(kinds=[4],text=b'10000',stack_bytes=1048576)))
    cases.append(('call-arguments-effects-once','(Int.x)observe(){x.console();x.return;}(Int.x)sum(Int.a,Int.b){(x+a+b).return;}start(){17.observe().sum(29.observe(),43.observe()).v;v.console();23.return;}',23,dict(kinds=[4]*4,text=b'17294389',publications=4)))
    return cases

def callable_oracle(mode, argument, result, argument_type=1):
    # Literal/source reference values; the runtime receives only a trace flag.
    return struct.pack('<8sQQqqQQQ', b'NEBOCAL1', mode, 0, argument, result,
                       1, int(mode != 0), argument_type)


def callable_cases():
    result = []
    for mode, label in ((0,'none'),(1,'copy'),(2,'move'),(3,'borrow')):
        for capture, argument in ((17,7),(29,7),(17,11),(-17,7)):
            capture_form = 'none' if mode == 0 else f'{label} {capture}'
            body = 'value' if mode == 0 else 'sum'
            expected = argument if mode == 0 else capture + argument
            suffix = '.drop()' if mode in (1,3) else ''
            source = f'callable work(Int.value) capture {capture_form} {{ {body}.return; }}start(){{work.call({argument}){suffix}.return;}}'
            result.append((f'callable-runtime-{label}-{capture}-{argument}', source, expected % 256,
                           dict(callable_trace=True, stdout=callable_oracle(mode,argument,expected))))
    for kind, literal, value, type_id in (('Bool','true',1,2),('Bool','false',0,2),
                                         ('Char',"'Q'",81,3),('Char',"'Ω'",937,3)):
        for callback in (False,True):
            invocation = f'callback(work,{literal})' if callback else f'work.call({literal})'
            source = f'callable work({kind}.value) capture none {{ value.return; }}start(){{{invocation}.return;}}'
            result.append((f'callable-runtime-{kind}-{value}-{callback}',source,value % 256,
                           dict(callable_trace=True,stdout=callable_oracle(0,value,value,type_id))))
    return result


def negatives():
    return [
        ('break-outside', 'start(){break;23.return;}', 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-030'),
        ('continue-outside', 'start(){continue;23.return;}', 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-031'),
        ('while-condition', 'start(){while(17){break;}23.return;}', 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-032'),
        ('if-condition', 'start(){if(17){23.return;}29.return;}', 'NEBO_CONTROL_CONDITION_TYPE'),
        ('call-arity', '(Int.self)add(Int.delta){(self+delta).return;}start(){17.add().return;}', 'NEBO_CALL_ARITY'),
        ('call-argument', '(Int.self)add(Int.delta){(self+delta).return;}start(){17.add(true).return;}', 'NEBO_CALL_UNDEFINED'),
        ('callable-borrow-escape', 'callable view(Int.value) capture borrow 9 {capture.return;}start(){view.call(1).return;}', 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-SECURITY-006'),
        ('callable-double-drop', 'callable take(Int.value) capture move 9 {capture.return;}start(){take.call(1).drop().drop().return;}', 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-SECURITY-006'),
        ('callable-type', 'callable work(Int.value) capture none {value.return;}start(){work.call(true).return;}', 'NEBO_CALL_ARGUMENT_TYPE'),
        ('callable-trailing-statement', 'callable work(Int.value) capture none {value.return;}start(){work.call(17).return;23.return;}', 'NEBO_PARSE_UNEXPECTED_TOKEN'),
        ('callable-adjacent-statement', 'callable work(Int.value) capture none {value.return;}start(){17.console();work.call(23).return;}', 'NEBO_PARSE_UNEXPECTED_TOKEN'),
    ]


def run():
    results = []
    with tempfile.TemporaryDirectory(prefix='nebo-G170-control-',dir='/tmp') as directory:
        root = Path(directory)
        for name, source, status, options in cases()+callable_cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try: proof=pipeline(path,work,status,**options);row=dict(result='PASS',**proof)
            except Failure as error: row=dict(result='FAIL',failure=str(error))
            results.append(dict(id=name,category='positive',**row))
        for name,source,code in negatives():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            span=None
            if name in ('if-condition','while-condition'):
                start=source.encode().index(b'17');span=(start,start+2)
            try: proof=reject(path,work,code,span=span);row=dict(result='PASS',**proof)
            except Failure as error: row=dict(result='FAIL',failure=str(error))
            results.append(dict(id=name,category='negative',**row))
    return dict(cases=results,passed=sum(r['result']=='PASS' for r in results),total=len(results))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
