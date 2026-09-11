#!/usr/bin/env python3
"""Public binary64 methods with independent Python and IEEE value oracles."""
import json
import math
import hashlib
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf


def approximate_cases():
    rows=[]
    def source_number(value):
        if math.isnan(value): return '(∞-∞)'
        if math.isinf(value): return '∞' if value>0 else '(-∞)'
        from decimal import Decimal
        text=format(Decimal(repr(value)), 'f')
        if '.' not in text:text+='.0'
        return '('+text+')' if value<0 or text.startswith('-') else text
    values=[(0.0,-0.0),(17.0,17.005),(17.0,17.5),(-7.0,-7.01),
            (1000.0,1001.0),(1e-300,0.0),(1e308,-1e308),
            (float('inf'),float('inf')),(float('-inf'),float('-inf')),
            (float('inf'),float('-inf')),(float('inf'),17.0),
            (float('nan'),17.0),(17.0,float('nan'))]
    # Python's public math.isclose supplies the oracle before execution.
    for n,(absolute,relative) in enumerate([(0.0,0.0),(0.01,0.0),(0.0,0.001),
                                            (0.01,0.001),(0.0,2.0),(float('inf'),0.0),(0.0,float('inf'))]):
        prefix=f'Vector<Float> [{source_number(absolute)},{source_number(relative)}].t;'
        for reverse in (False,True):
            body=prefix;expected=[]
            for a,b in values:
                if reverse:a,b=b,a
                body+=f'{source_number(a)}.approxEquals({source_number(b)},t).console();'
                expected.append(str(math.isclose(a,b,abs_tol=absolute,rel_tol=relative)).lower())
            rows.append((f'approx-oracle-{n}-{reverse}','start(){'+body+'23.return;}',23,dict(kinds=[5]*len(expected),text=''.join(expected).encode())))
    for returned in (0,7,23,29,255):
        source=f'start(){{Vector<Float> [0.01,0.001].t;17.0.approxEquals(17.005,t).console();{returned}.return;}}'
        rows.append((f'approx-return-{returned}',source,returned,dict(kinds=[5],text=b'true')))
    rows.extend([
        ('approx-two-live','start(){Vector<Float> [0.01,0.0].a;Vector<Float> [0.0,0.0].b;17.0.approxEquals(17.005,a).console();17.0.approxEquals(17.005,b).console();17.0.approxEquals(17.005,a).console();23.return;}',23,dict(kinds=[5]*3,text=b'truefalsetrue')),
        ('approx-effects-once','(Float.x)mark(){x.floor().console();x.return;}start(){17.0.mark().approxEquals(17.005.mark(),Vector<Float> [0.01.mark(),0.001.mark()]).console();23.return;}',23,dict(kinds=[4]*4+[5],text=b'171700true')),
        ('approx-owned-argument','import "std.scientific" { Matrix; }.scientific;\nstart(){Vector<Float> [0.01,0.001].t;Matrix<Float>.filled(2,2,17.0).at(1,1).approxEquals(Matrix<Float>.filled(2,2,17.005).at(0,1),t.scale(1.0)).console();23.return;}',23,dict(kinds=[5],text=b'true')),
        ('approx-function-return','(Float.x)near(Float.y){Vector<Float> [0.01,0.0].t;x.approxEquals(y,t).return;}start(){17.0.near(17.005).console();17.0.near(18.0).console();23.return;}',23,dict(kinds=[5,5],text=b'truefalse')),
        # The existing process-status contract admits Int, Bool and Char.
        ('approx-bool-status-true','start(){Vector<Float,2>.filled(0.01).t;17.0.approxEquals(17.0,t).return;}',1,{}),
        ('approx-bool-status-false','start(){Vector<Float,2>.filled(0.01).t;17.0.approxEquals(29.0,t).return;}',0,{}),
        ('approx-uncertain-owner','start(){Uncertain(17,2).a;Uncertain(18,1).b;a.approxEquals(b).console();a.measuredValue().console();23.return;}',23,dict(kinds=[5,4],text=b'true17')),
        ('approx-interpolation','start(){Vector<Float> [0.01,0.0].t;"${17.0.approxEquals(17.005,t)}".console();23.return;}',23,dict(kinds=[2],text=b'true')),
        ('approx-loop-temporaries','start(){0.i.mutable;0.n.mutable;while(i<10000){if(17.0.approxEquals(17.005,Vector<Float,2>.filled(0.01))){n=n+1;}i=i+1;}n.console();23.return;}',23,dict(kinds=[4],text=b'10000',stack_bytes=1048576)),
    ])
    for count in (0,1,2,3,64):
        source=f'import "std.scientific" {{ Matrix; }}.scientific;\nstart(){{Matrix<Float>.filled(1,{count},0.01).m;m.sum(0).t;17.0.approxEquals(17.005,t).console();23.return;}}'
        rows.append((f'approx-dynamic-shape-{count}',source,23 if count==2 else 177,dict(kinds=[5],text=b'true') if count==2 else {}))
    for a,b in [('-1.0','0.0'),('0.0','-1.0'),('(∞-∞)','0.0'),('0.0','(∞-∞)')]:
        rows.append((f'approx-domain-{len(rows)}',f'start(){{Vector<Float> [{a},{b}].t;17.0.approxEquals(17.0,t);23.return;}}',177,{}))
    return rows


def approximate_negatives():
    rows=[]
    for name,other,tolerance in [('other-type','17','Vector<Float,2>.filled(0.01)'),
                                ('tolerance-type','17.0','0.01'),('element-type','17.0','Vector<Int,2>.filled(1)'),
                                ('shape-one','17.0','Vector<Float,1>.filled(0.01)'),('shape-three','17.0','Vector<Float,3>.filled(0.01)')]:
        rows.append(('approx-'+name,f'start(){{{tolerance}.t;17.0.approxEquals({other},t);23.return;}}','NEBO_CALL_UNDEFINED'))
    for args in ('','17.0','17.0,t,t'):
        rows.append(('approx-arity-'+str(len(args)),f'start(){{Vector<Float,2>.filled(0.01).t;17.0.approxEquals({args});23.return;}}','NEBO_CALL_UNDEFINED'))
    rows.append(('approx-status-type','start(){Vector<Float,2>.filled(0.01).t;17.0.approxEquals(17.0,t);t.return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'))
    return rows


def cases():
    rows = []
    for value in (-7.75, -2.5, -1.5, -0.0, 0.0, 1.5, 2.5, 7.75):
        for mode, operation in enumerate((round, math.floor, math.ceil, math.trunc)):
            expected = float(operation(value))
            source = f'start(){{({value!r}).value;value.round({mode}).out;(out=={expected!r}).console();23.return;}}'
            rows.append((f'round-{value}-{mode}', source, 23, dict(kinds=[5], text=b'true')))
    for returned in (0, 7, 23, 29, 255):
        source = f'start(){{2.5.value;value.round(nearestEven).out;(out==2.0).console();{returned}.return;}}'
        rows.append((f'round-return-{returned}', source, returned, dict(kinds=[5], text=b'true')))
    for value in (-7.75, -1.5, -0.0, 0.0, 1.5, 7.75):
        for name, operation in [('floor', math.floor), ('ceil', math.ceil)]:
            source = f'start(){{({value!r}).value;value.{name}().console();23.return;}}'
            rows.append((f'{name}-{value}', source, 23, dict(kinds=[4], text=str(operation(value)).encode())))
    ieee = [('finite', '1.5', (True, False, False, False)),
            # Exponent literal notation is deferred by the current lexer.
            # Produce a nonzero subnormal through ordinary Float arithmetic.
            ('subnormal', '('+'1.0'+'/1000000000000000000.0'*17+'/100.0)', (True, False, False, False)),
            ('positive-zero', '0.0', (True, False, False, False)),
            ('negative-zero', '(-0.0)', (True, False, False, True)),
            ('infinite', '∞', (False, False, True, False)),
            ('negative-infinite', '(-∞)', (False, False, True, False)),
            ('nan', '(∞-∞)', (False, True, False, False))]
    for name, expression, answers in ieee:
        for method, expected in zip(('isFinite', 'isNaN', 'isInfinite', 'isNegativeZero'), answers):
            source = f'start(){{{expression}.value;value.{method}().console();23.return;}}'
            rows.append((name+'-'+method, source, 23, dict(kinds=[5], text=str(expected).lower().encode())))
    for mode in range(4):
        for name, value in [('positive-bound', '9223372036854775808.0'),
                            ('negative-bound', '(-9223372036854775808.0)'),
                            ('nan', '(∞-∞)'), ('infinite', '∞')]:
            source = f'start(){{{value}.x;x.round({mode});23.return;}}'
            rows.append((f'round-domain-{mode}-{name}', source, 128+49, {}))
    for mode in (-1, 4, 4294967296, 9223372036854775807):
        rows.append((f'round-mode-{mode}', f'start(){{1.5.x;x.round({mode});23.return;}}', 128+49, {}))
    rows += [
        ('float-two-live-floor', 'start(){1.5.a;7.25.b;a.floor().console();b.ceil().console();a.floor().console();23.return;}', 23, dict(kinds=[4,4,4], text=b'181')),
        ('float-two-live-classifiers', 'start(){(-0.0).a;1.5.b;a.isNegativeZero().console();b.isNegativeZero().console();a.isNegativeZero().console();23.return;}', 23, dict(kinds=[5,5,5], text=b'truefalsetrue')),
        ('round-assert-true', 'start(){1.5.x;x.round(nearestEven).out;flow.assert(out==2.0);23.return;}', 23, {}),
        ('round-assert-false', 'start(){1.5.x;x.round(nearestEven).out;flow.assert(out==7.0);23.return;}', 175, {}),
        ('round-mode-effect-once', '(Int.self)mode(){self.console();self.return;}start(){1.5.x;x.round(1.mode()).out;(out==1.0).console();23.return;}', 23, dict(kinds=[4,5], text=b'1true')),
        ('round-mode-binding', 'start(){1.mode.mutable;1.5.x;x.round(mode).a;mode=2;x.round(mode).b;(a==1.0).console();(b==2.0).console();23.return;}', 23, dict(kinds=[5,5], text=b'truetrue')),
        ('round-nearest-name-binding', 'start(){2.nearestEven;1.5.x;x.round(nearestEven).out;(out==2.0).console();23.return;}', 23, dict(kinds=[5], text=b'true')),
        ('round-wrong-expected', 'start(){1.5.x;x.round(nearestEven).out;(out==7.0).console();23.return;}', 23, dict(kinds=[5], text=b'false')),
        ('round-negative-zero', 'start(){(-0.0).x;x.round(nearestEven).out;out.isNegativeZero().console();23.return;}', 23, dict(kinds=[5], text=b'true')),
    ]
    for value in (-7.25,-0.0,0.0,1.5,7.25):
        for returned in (0,7,23,29,255):
            source='(Float.x)twice(){(x*2.0).return;}start(){'+f'({value}).twice().a;a.twice().b;"${{a:fixed(2)}}/${{b:fixed(2)}}".console();{returned}.return;}}'
            expected=f'{value*2:.2f}/{value*4:.2f}'.encode()
            rows.append((f'float-function-{value}-{returned}',source,returned,dict(kinds=[2],text=expected)))
    for value in (1.5,7.25):
        for operand in (2.75,5.5):
            source='import "std.scientific" { Matrix; }.scientific;\n(Float.x)add(Float.y){(x+y).return;}start(){'+f'{value}.add(Matrix<Float>.filled(1,1,{operand}).at(0,0)).v;"${{v:fixed(2)}}".console();23.return;}}'
            rows.append((f'float-owned-argument-{value}-{operand}',source,23,dict(kinds=[2],text=f'{value+operand:.2f}'.encode())))
    rows.append(('float-call-six-owned-arguments','import "std.scientific" { Matrix; }.scientific;\n(Float.x)sum(Float.a,Float.b,Float.c,Float.d,Float.e){(x+a+b+c+d+e).return;}start(){1.5.sum(2.5,3.5,4.5,5.5,Matrix<Float>.filled(1,1,6.5).at(0,0)).v;"${v:fixed(2)}".console();23.return;}',23,dict(kinds=[2],text=b'24.00')))
    rows.append(('float-function-matrix-local','import "std.scientific" { Matrix; }.scientific;\n(Float.x)scale(){Matrix<Float>.filled(2,3,x).m;m.sum().return;}start(){1.5.scale().a;2.75.scale().b;"${a:fixed(2)}/${b:fixed(2)}".console();23.return;}',23,dict(kinds=[2],text=b'9.00/16.50')))
    return rows+approximate_cases()


def negatives():
    return [('round-process-return','start(){1.5.x;x.round(nearestEven).return;}','NEBO_ENTRYPOINT_INVALID_SIGNATURE'), ('round-assert-type','start(){1.5.x;x.round(0);flow.assert(17);23.return;}','NEBO_TYPE_MISMATCH')] + [(name, 'start(){'+body+'}', 'NEBO_CALL_UNDEFINED') for name, body in [
        ('round-receiver-type', '17.x;x.round(0);23.return;'),
        ('round-mode-type', '1.5.x;x.round(true);23.return;'),
        ('round-extra-mode', '1.5.x;x.round(0,1);23.return;'),
        ('round-missing-mode', '1.5.x;x.round();23.return;'),
        ('round-shadow-wrong-type', 'true.nearestEven;1.5.x;x.round(nearestEven);23.return;'),
        ('floor-extra-argument', '1.5.x;x.floor(0);23.return;'),
        ('classifier-extra-argument', '1.5.x;x.isFinite(0);23.return;'),
    ]] + approximate_negatives()


def native_controls(root):
    target=ROOT/'build/tests/rf27-g14/f03/transcendental_test'
    commands=[['ninja','-j2','build/obj/transcendental.o',str(target.relative_to(ROOT))],
              ['nasm','-f','elf64','-I','./','tests/rf204/G170/rounding_native.asm','-o',root/'round.o'],
              ['ld','-m','elf_x86_64','-nostdlib','-z','noexecstack','--build-id=none','-o',root/'round',root/'round.o',ROOT/'build/obj/transcendental.o']]
    for command in commands:
        status,out,err=execute(command,root,timeout=45)
        if status or err:raise Failure('ROUND_NATIVE_BUILD:'+str(status))
    rows=[]
    for name,path in [('native-control-word',root/'round'),('native-transcendental',target)]:
        elf(path)
        if execute([path],root,runtime=True)!=(0,b'',b''):raise Failure('ROUND_NATIVE_CONTROL:'+name)
        rows.append(dict(id=name,category='native-control',result='PASS',elf_sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    return rows


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='nebo-G170-precision-') as directory:
        root = Path(directory)
        rows.extend(native_controls(root))
        for negative, matrix in ((False, cases()), (True, negatives())):
            for name, source, expected, *options in matrix:
                work = root/name
                work.mkdir()
                path = work/'source.no'
                path.write_text(source)
                try:
                    proof = reject(path, work, expected) if negative else pipeline(path, work, expected, **options[0])
                    row = dict(result='PASS', **proof)
                except Failure as error:
                    row = dict(result='FAIL', failure=str(error))
                rows.append(dict(id=name, category='negative' if negative else 'positive', **row))
    return dict(cases=rows, passed=sum(row['result']=='PASS' for row in rows), total=len(rows))


if __name__ == '__main__':
    print(json.dumps(run(), sort_keys=True))
