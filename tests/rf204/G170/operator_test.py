#!/usr/bin/env python3
"""Atomic Registry operators with operand-derived, independent observations."""
import json
import math
import operator
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject
from text_test import document


def cases():
    rows=[]
    arithmetic=[('+',operator.add),('-',operator.sub),('*',operator.mul),
                ('/',lambda a,b: math.trunc(a/b)),
                ('%',lambda a,b:a-math.trunc(a/b)*b),('^',pow),
                ('xor',operator.xor),('−',operator.sub),('÷',lambda a,b:math.trunc(a/b)),('⊻',operator.xor)]
    comparisons=[('<',operator.lt),('<=',operator.le),('>',operator.gt),('>=',operator.ge),
                 ('==',operator.eq),('!=',operator.ne),('≤',operator.le),('≥',operator.ge),('≠',operator.ne)]
    for symbol,oracle in arithmetic+comparisons:
        for index,(left,right) in enumerate([(17,3),(29,3),(17,7),(3,17),(-17,3),(17,-3),(0,3),(3,3)]):
            if symbol=='^' and (right<0 or right>7):continue
            source=f'(Int.left)calculate(Int.right){{(left {symbol} right).return;}}start(){{({left}).calculate({right}).console();23.return;}}'
            rows.append(('binary-'+symbol.encode().hex()+'-'+str(index),source,23,document(oracle(left,right))))
    for symbol,oracle in [('&&',operator.and_),('||',operator.or_),('xor',operator.xor),('∧',operator.and_),('∨',operator.or_),('⊻',operator.xor)]:
        for left in (False,True):
            for right in (False,True):
                a,b=str(left).lower(),str(right).lower()
                source=f'(Bool.left)calculate(Bool.right){{(left {symbol} right).return;}}start(){{{a}.calculate({b}).console();23.return;}}'
                rows.append((f'logic-{symbol.encode().hex()}-{a}-{b}',source,23,document(oracle(left,right))))
    for symbol,values,oracle in [('+',[17,-29,0],operator.pos),('-',[17,-29,0],operator.neg),('−',[17,-29,0],operator.neg),('!',[False,True],operator.not_),('¬',[False,True],operator.not_)]:
        for index,value in enumerate(values):
            kind='Bool' if isinstance(value,bool) else 'Int'
            literal=str(value).lower()
            source=f'({kind}.value)calculate(){{({symbol}value).return;}}start(){{({literal}).calculate().console();23.return;}}'
            rows.append(('unary-'+symbol.encode().hex()+'-'+str(index),source,23,document(oracle(value))))
    for symbol,values,oracle in [('√',[0,1,81,625],math.isqrt),('∛',[-125,-8,0,27,343],lambda n:round(math.copysign(abs(n)**(1/3),n))),('∜',[0,1,81,625],lambda n:math.isqrt(math.isqrt(n)))]:
        for value in values:
            source=f'(Int.value)calculate(){{({symbol}value).return;}}start(){{({value}).calculate().console();23.return;}}'
            rows.append(('root-'+symbol.encode().hex()+'-'+str(value),source,23,document(oracle(value))))
    for value in (0,1,5,9,20):
        source=f'(Int.value)calculate(){{(value!).return;}}start(){{{value}.calculate().console();23.return;}}'
        rows.append(('factorial-'+str(value),source,23,document(math.factorial(value))))
    for left,right in [('⌊','⌋'),('⌈','⌉')]:
        for value in (-17.75,-0.0,0.5,29.25):
            oracle=math.floor if left=='⌊' else math.ceil
            source=f'(Float.value)calculate(){{({left}value{right}).return;}}start(){{({value}).calculate().console();23.return;}}'
            rows.append(('round-'+left.encode().hex()+'-'+str(value),source,23,document(oracle(value))))
    for name,body,wanted in [
        ('short-and','(false && (1/0==0)).console();',False),
        ('short-or','(true || (1/0==0)).console();',True),
        ('short-unicode-and','(false ∧ (1/0==0)).console();',False),
        ('short-unicode-or','(true ∨ (1/0==0)).console();',True)]:
        rows.append((name,'start(){'+body+'23.return;}',23,document(wanted)))
    for symbol,expression,status in [('sqrt','√2',177),('factorial','(-1)!',177),('factorial-overflow','21!',172),('divide','17/0',173),('add','9223372036854775807+1',172)]:
        rows.append(('domain-'+symbol,'start(){('+expression+').console();23.return;}',status,{}))
    rows.extend(scientific_cases())
    rows.extend(set_cases())
    rows.extend(option_flow_cases())
    rows.extend(bytes_ordering_cases())
    rows.extend(reduction_cases())
    rows.extend(structural_cases())
    return rows


def structural_cases():
    rows=[]
    for first,second,status in [(17,29,23),(29,83,7),(83,17,255)]:
        source=f'start(){{{first}.console()._;{second}.console()._;{status}.return;}}'
        rows.append((f'discard-effects-{first}-{second}',source,status,dict(kinds=[4,4],text=f'{first}{second}'.encode())))
        source=f'// 99.return; ignored as source comment\nstart(){{"//".console();{first}.console();{status}.return;}}// comment at EOF'
        rows.append((f'comment-{first}',source,status,dict(kinds=[2,4],text=f'//{first}'.encode())))
        for arm in ('_','Value(_)'):
            source=f'enum Number {{ Empty, Value(Int) }}start(){{Number.Value({first}).v;match(v){{Empty -> 0.return;{arm} -> {status}.return;}}}}'
            rows.append((f'wildcard-{arm}-{first}',source,status,{}))
    rows.append(('discard-scope','start(){17.console()._;if(true){29.console()._;}83.console()._;23.return;}',23,dict(kinds=[4]*3,text=b'172983')))
    rows.append(('discard-owned','start(){"%d".format(17).console()._;"%d".format(29).console()._;23.return;}',23,dict(kinds=[2,2],text=b'1729')))
    return rows


def reduction_cases():
    rows=[]
    for values in ([],[17],[2,3,5],[2,7,5],[-2,3,5],[0,7,29]):
        for symbol,expected in [('∑',sum(values)),('∏',math.prod(values))]:
            body=f'Array<Int,{len(values)}> [{",".join(map(str,values))}].values;({symbol}values).console();'
            rows.append(('reduce-'+symbol.encode().hex()+'-'+str(values).replace(', ', '_'),'start(){'+body+'23.return;}',23,document(expected)))
    return rows


def bytes_ordering_cases():
    rows=[]
    for ordinal,(left,right) in enumerate([([17,29,0,255],[7,83,255,0]),([29,29,0,255],[7,83,255,0]),([17,29,0,255],[3,83,255,0])]):
        a='Bytes.fromValues('+','.join(map(str,left))+')'
        b='Bytes.fromValues('+','.join(map(str,right))+')'
        for symbol in ('xor','⊻'):
            for direct in (False,True):
                prefix='' if direct else a+'.a;'+b+'.b;'
                operation=f'({a if direct else "a"} {symbol} {b if direct else "b"})'
                body=operation+'.out;'+''.join(f'out.at({i}).console();' for i in range(4))+'out.byteLength().console();'
                rows.append((f'bytes-xor-{ordinal}-{symbol.encode().hex()}-{direct}','start(){'+prefix+body+'23.return;}',23,dict(kinds=[4]*5,text=(''.join(str(x^y) for x,y in zip(left,right))+'4').encode())))
    rows.extend([
        ('bytes-xor-empty','start(){(Bytes.empty() xor Bytes.empty()).byteLength().console();23.return;}',23,document(0)),
        ('bytes-xor-nested','start(){((Bytes.fromByte(17) xor Bytes.fromByte(29)) xor Bytes.fromByte(7)).at(0).console();23.return;}',23,document(17^29^7)),
        ('bytes-xor-two-live','start(){(Bytes.fromByte(17) xor Bytes.fromByte(29)).a;(Bytes.fromByte(83) xor Bytes.fromByte(7)).b;a.at(0).console();b.at(0).console();a.at(0).console();23.return;}',23,dict(kinds=[4]*3,text=f'{17^29}{83^7}{17^29}'.encode())),
        ('bytes-xor-length-domain','start(){(Bytes.fromByte(17) xor Bytes.empty()).byteLength().console();23.return;}',177,{}),
        ('bytes-xor-effects','(Int.x)observe(){x.console();x.return;}start(){(Bytes.fromByte(17.observe()) xor Bytes.fromByte(29.observe())).at(0).console();23.return;}',23,dict(kinds=[4]*3,text=f'1729{17^29}'.encode())),
    ])
    for value in (0,7,23,29,255):
        for mode in ('binding','call','four'):
            if mode=='binding':source=f'start(){{{value}.v;Bytes.fromByte(v).at(0).console();{value}.return;}}';options=document(value)
            elif mode=='call':source=f'(Int.v)bytes(){{Bytes.fromByte(v).at(0).return;}}start(){{{value}.bytes().console();{value}.return;}}';options=document(value)
            else:source=f'(Int.v)observe(){{v.console();v.return;}}start(){{Bytes.fromValues({value}.observe(),17.observe(),29.observe(),83.observe()).b;b.at(0).console();b.at(3).console();{value}.return;}}';options=dict(kinds=[4]*6,text=f'{value}172983{value}83'.encode())
            rows.append((f'bytes-construct-{mode}-{value}',source,value,options))
    for value in (-1,256,9223372036854775807):
        source=f'(Int.v)bytes(){{Bytes.fromByte(v).at(0).return;}}start(){{({value}).bytes().console();23.return;}}'
        rows.append((f'bytes-construct-domain-{value}',source,177,{}))
    for left,right in [(17,29),(29,17),(17,17),(-17,0),(0,-17)]:
        comparison=(left>right)-(left<right)
        for a,b in [(-1,0),(0,0),(1,0)]:
            reference=(a>b)-(a<b)
            source=f'start(){{({left}<=>{right}).order;(order==({a}<=>{b})).console();23.return;}}'
            rows.append((f'ordering-{left}-{right}-{a}-{b}',source,23,document(comparison==reference)))
    return rows


def option_flow_cases():
    rows=[]
    for value in (0,7,23,29,255):
        for some in (False,True):
            ctor=f'Option<Int>({"Some("+str(value)+")" if some else "None()"})'
            rows.append((f'coalesce-{some}-{value}',f'start(){{{ctor}.v;v ?? 83.return;}}',value if some else 83,{}))
            source=f'start(){{{ctor}.v.mutable;v ??= 83;v.unwrapOr(0).return;}}'
            rows.append((f'coalesce-store-{some}-{value}',source,value if some else 83,{}))
            source=f'start(){{{ctor}.v;v?.wrappingAdd(17).mapped;mapped.unwrapOr(83).return;}}'
            rows.append((f'option-chain-{some}-{value}',source,(value+17)%256 if some else 83,{}))
        source=f'(Int.self)observe(){{self..{{17.console();}}.return;}}start(){{{value}.observe().return;}}'
        rows.append((f'lateral-effect-{value}',source,value,document(17)))
        source=f'(Int.self)observe(){{self..{{"%d".format(17).console();}}.return;}}start(){{{value}.observe().return;}}'
        rows.append((f'lateral-owned-effect-{value}',source,value,document('17')))
        decl='(Result<Int,Int>.context)propagate(Result<Int,Int>.value){value? .return;}'
        for ok in (False,True):
            ctor=f'Result<Int,Int>({"Ok" if ok else "Err"}({value}))'
            source=decl+f'start(){{Result<Int,Int>(Ok(0)).propagate({ctor}).'+('get()' if ok else 'getErr()')+'.return;}'
            rows.append((f'propagate-{ok}-{value}',source,value,{}))
    return rows


def set_cases():
    rows=[]
    for ordinal,(a,b) in enumerate([([2,3,5],[3,7]),([2,3,5],[3,5]),([2,3,5],[2,3,5]),([0,62],[62,17]),([],[])]):
        left,right=set(a),set(b)
        declarations=f'Array<Int,{len(a)}> [{",".join(map(str,a))}].left;Array<Int,{len(b)}> [{",".join(map(str,b))}].right;'
        for symbol,result in [('∪',len(left|right)),('∩',len(left&right)),('∖',len(left-right)),('△',len(left^right)),('×',len(left)*len(right)),('⊆',left<=right),('⊂',left<right),('⊇',left>=right),('⊃',left>right)]:
            expression='(left '+symbol+' right)'+('' if isinstance(result,bool) else '.cardinality()')
            source='start(){'+declarations+expression+'.console();23.return;}'
            rows.append((f'set-{symbol.encode().hex()}-{ordinal}',source,23,document(result)))
        for value in (2,7,62):
            for symbol,negated in [('∈',False),('∉',True)]:
                source='start(){'+declarations+f'({value} {symbol} left).console();23.return;}}'
                rows.append((f'membership-{symbol.encode().hex()}-{ordinal}-{value}',source,23,document((value in left)^negated)))
        source='start(){'+declarations+'(left ∪ ∅).cardinality().console();23.return;}'
        rows.append(('set-empty-context-'+str(ordinal),source,23,document(len(left))))
    return rows


def scientific_cases():
    rows=[]
    for base in (-2.0,-0.0,0.5,1.5,2.0):
        for exponent in (-3,0,1,4):
            if base==0 and exponent<0:continue
            value=base**exponent
            source=f'(Float.base)raiseTo(Int.exponent){{(base^exponent).return;}}start(){{"%.6f".format(({base}).raiseTo({exponent})).console();23.return;}}'
            rows.append((f'float-power-{base}-{exponent}',source,23,document(format(value,'.6f'))))
    for base,exponent in [('0.0',-1),('2.0',1000001),('2.0',1024),('∞',1)]:
        source=f'(Float.base)raiseTo(Int.exponent){{(base^exponent).return;}}start(){{({base}).raiseTo({exponent});23.return;}}'
        rows.append((f'float-power-domain-{base}-{exponent}',source,177,{}))
    for name,expression,value in [('pi','π',math.pi),('tau','τ',math.tau),('infinity','∞',math.inf)]:
        for returned in (7,23,255):
            observer='v.isInfinite().console();' if math.isinf(value) else '"%.6f".format(v).console();'
            source=f'start(){{{expression}.v;{observer}{returned}.return;}}'
            rows.append((f'constant-{name}-{returned}',source,returned,document(True if math.isinf(value) else format(value,'.6f'))))
    for opening,closing,expected in [('…','',5),('…<','',4),('<…','',4),('<…<','',3)]:
        for start in (0,7,29):
            source=f'start(){{({start}{opening}{start+4}).values;values.length().console();23.return;}}'
            rows.append(('range-'+opening.encode().hex()+'-'+str(start),source,23,document(expected)))
    # Known-bad assertions make typed quantity relations observable even
    # when their values are constant-folded by the canonical quantity owner.
    for suffix,factor in [('%',100),('‰',10),('‱',1)]:
        for value in (0,7,29):
            for wrong in (False,True):
                source=f'start(){{({value}{suffix}).q;flow.assert(q == {value*factor+int(wrong)}‱);23.return;}}'
                rows.append((f'ratio-{suffix.encode().hex()}-{value}-{wrong}',source,175 if wrong else 23,{}))
    for value in (0,17,29):
        for wrong in (False,True):
            source=f'start(){{({value}°).q;flow.assert((q+7°)=={value+7+int(wrong)}°);23.return;}}'
            rows.append((f'angle-{value}-{wrong}',source,175 if wrong else 23,{}))
    for celsius in (0,20,100):
        fahrenheit=celsius*9//5+32
        for wrong in (False,True):
            # Nine Fahrenheit degrees have an exact milli-Celsius image;
            # one degree would instead exercise the conversion-domain trap.
            source=f'start(){{({celsius}°C).c;({fahrenheit+9*int(wrong)}°F).f;flow.assert(c==f);23.return;}}'
            rows.append((f'temperature-{celsius}-{wrong}',source,175 if wrong else 23,{}))
    for value,error in [(17,3),(29,3),(17,7)]:
        source=f'start(){{({value} ± {error}).m;m.measuredValue().console();m.uncertainty().console();23.return;}}'
        rows.append((f'uncertain-value-{value}-{error}',source,23,dict(text=f'{value}{error}'.encode(),kinds=[4,4])))
    for a,u,b,v in [(17,3,23,3),(17,3,24,3),(29,3,29,3),(8,2,12,3)]:
        for symbol,wanted in [('≈',abs(a-b)<=u+v),('≉',abs(a-b)>u+v),('≡',(a,u)==(b,v)),('∝',a*v==b*u)]:
            source=f'start(){{(({a} ± {u}) {symbol} ({b} ± {v})).console();23.return;}}'
            rows.append((f'uncertain-{symbol.encode().hex()}-{a}-{u}-{b}-{v}',source,23,document(wanted)))
    for divisor,value in [(0,17),(7,63),(8,63),(-7,63),(7,-63)]:
        for symbol,negated in [('∣',False),('∤',True)]:
            wanted=bool(divisor and value%divisor==0)^negated
            source=f'start(){{(({divisor}) {symbol} ({value})).console();23.return;}}'
            rows.append((f'divisibility-{symbol.encode().hex()}-{divisor}-{value}',source,23,document(wanted)))
    return rows


def negatives():
    rows=[]
    for symbol in ('+','-','*','/','%','^','xor','<','<=','>','>=','==','!=','−','÷','≤','≥','≠','⊻'):
        source=f'(Int.left)calculate(){{(left {symbol} true).return;}}start(){{17.calculate().console();23.return;}}'
        rows.append(('wrong-'+symbol.encode().hex(),source,'NEBO_TYPE_MISMATCH'))
    for name,expression in [('power-float-exponent','2.0^3.0'),('power-int-float','2^3.0'),('logic-int','true && 17'),('compare-text-int','"Nebo"==17')]:
        rows.append(('wrong-'+name,'start(){('+expression+').console();23.return;}','NEBO_TYPE_MISMATCH'))
    for symbol,expression in [('+','+true'),('-','-true'),('!','!17'),('¬','¬17'),('√','√true'),('∛','∛true'),('∜','∜true'),('factorial','true!'),('floor','⌊17⌋'),('ceil','⌈17⌉')]:
        rows.append(('wrong-unary-'+symbol.encode().hex(),'(Int.self)invalid(){('+expression+').return;}start(){17.invalid().console();23.return;}','NEBO_TYPE_MISMATCH'))
    for symbol in ('∈','∉','∪','∩','∖','△','⊆','⊂','⊇','⊃','×'):
        source=f'(Int.self)invalid(){{(17 {symbol} 29).return;}}start(){{7.invalid().console();23.return;}}'
        rows.append(('wrong-set-'+symbol.encode().hex(),source,'NEBO_TYPE_MISMATCH'))
    for name,body in [('bytes-bool','Bytes.fromByte(true)'),('bytes-text','Bytes.fromValues(17,29,"bad",83)'),('bytes-arity','Bytes.fromByte(17,29)'),('bytes-four-arity','Bytes.fromValues(17,29,83)'),('bytes-instance-constructor','Bytes.fromByte(17).b;b.fromByte(29)'),('bytes-xor-mixed','Bytes.fromByte(17) xor 29'),('ordering-type','17<=>true')]:
        rows.append((name,'(Int.self)invalid(){'+body+';23.return;}start(){7.invalid().return;}','NEBO_TYPE_MISMATCH'))
    for symbol,values in [('∑',[9223372036854775807,1]),('∏',[9223372036854775807,2])]:
        source=f'start(){{Array<Int,2> [{values[0]},{values[1]}].values;({symbol}values).console();23.return;}}'
        rows.append(('reduce-overflow-'+symbol.encode().hex(),source,'NEBO_TYPE_CONSTANT_OVERFLOW'))
    for symbol,expression in [('∑','∑17'),('∏','∏17'),('±','17 ± true'),('≈','17 ≈ 29'),('≉','17 ≉ 29'),('≡','17 ≡ 29'),('∝','17 ∝ 29'),('∣','true ∣ 29'),('∤','17 ∤ false'),('%','true%'),('‰','true‰'),('‱','true‱'),('°','true°'),('°C','true°C'),('°F','true°F'),('π','π + true'),('τ','τ + true'),('∞','∞ + true')]:
        # The Registry explicitly rejects bare numeric approximate equality
        # in the lexer. A Bool followed by '%' has no valid postfix quantity
        # form and leaves the infix remainder operand missing in the parser.
        code='NEBO_LEX_REJECTED_FORM' if symbol=='≈' else 'NEBO_PARSE_UNEXPECTED_TOKEN' if symbol=='%' else 'NEBO_TYPE_MISMATCH'
        rows.append(('wrong-domain-'+symbol.encode().hex(),'(Int.self)invalid(){('+expression+').return;}start(){7.invalid().return;}',code))
    rows.append(('comment-does-not-bind','// 17.hidden;\nstart(){hidden.console();23.return;}','NEBO_NAME_UNDEFINED'))
    rows.append(('discard-read','start(){17.console()._;_.console();23.return;}','NEBO_NAME_UNDEFINED'))
    rows.append(('discard-mutable','start(){17.console()._.mutable;23.return;}','NEBO_PARSE_EXPECTED_TOKEN'))
    for name,code in [('coalesce-type-mismatch','NEBO_TYPE_MISMATCH'),('optional-chain-invalid-member','NEBO_PARSE_UNEXPECTED_TOKEN'),('option-assign-immutable','NEBO_PARSE_UNEXPECTED_TOKEN'),('chained-range','NEBO_PARSE_UNEXPECTED_TOKEN'),('lateral-mutation','NEBO_PARSE_EXPECTED_TOKEN'),('result-outside-context','NEBO_TYPE_MISMATCH'),('ascii-three-dot-range','NEBO_LEX_RESERVED_SYMBOL')]:
        rows.append((name,(ROOT/'tests/rf204/G124'/f'{name}.no').read_text(),code))
    return rows


def run():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-operators-') as directory:
        for negative,matrix in ((False,cases()),(True,negatives())):
            for name,source,expected,*options in matrix:
                work=Path(directory)/name;work.mkdir();path=work/'source.no';path.write_text(source)
                try:
                    proof=reject(path,work,expected) if negative else pipeline(path,work,expected,**options[0])
                    result=dict(result='PASS',**proof)
                except Failure as error:result=dict(result='FAIL',failure=str(error))
                rows.append(dict(id=name,category='negative' if negative else 'positive',**result))
    return dict(cases=rows,passed=sum(r['result']=='PASS' for r in rows),total=len(rows))


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
