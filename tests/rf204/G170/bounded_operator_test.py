"""Current finite domain grammars, observed through their public value API.

These profiles expose one aggregate expression as the program result. Cases
stay inside that documented grammar; typed statement composition has separate
tests. Expected values are computed before compilation, never from artifacts.
"""
import json
import math
import tempfile
from fractions import Fraction
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject

def cases():
    rows=[]
    def add(number,label,body,value,imports=""):
        rows.append((f'dom-{number:03}-{label}',imports+'start(){'+body+';}',int(value)%256,{}))
    for n,(a,b) in enumerate([([2,3,4],[5,6,8]),([7,3,4],[5,6,8]),([-2,3,4],[5,11,8])]):
        prefix='Vector<Int,3> ['+','.join(map(str,a))+'].a;Vector<Int,3> ['+','.join(map(str,b))+'].b;'
        for number,method,expected in [(36,'dot',sum(x*y for x,y in zip(a,b))),
                (37,'cross',sum((a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]))),
                (38,'hadamard',sum(x*y for x,y in zip(a,b))),
                (39,'tensorProduct',sum(a)*sum(b)),(40,'directSum',sum(a)+sum(b)),
                (47,'isOrthogonalTo',sum(x*y for x,y in zip(a,b))==0),
                (48,'isParallelTo',all(a[i]*b[j]==a[j]*b[i] for i in range(3) for j in range(i+1,3)))]:
            add(number,f'named-{n}',prefix+f'a.{method}(b)'+('.sum()' if number in (37,38,39,40) else ''),expected)
        add(40,f'symbol-{n}',prefix+'(a ⊕ b).sum()',sum(a)+sum(b))
        prefix+='Vector<Int,3> [3,5,7].x;'
        value=sum(outer*(inner*x) for outer,inner,x in zip(a,b,(3,5,7)))
        for label,expression in [('named','a.compose(b)'),('symbol','(a ∘ b)')]:
            add(46,f'{label}-{n}',prefix+expression+'.apply(x).sum()',value)
    for n,values in enumerate(((2,5,7,11),(3,7,11,29),(-2,5,7,-11))):
        prefix='Matrix<Int,2,2> ['+','.join(map(str,values))+'].m;'
        for i,j in ((0,1),(1,0),(1,1)):
            for label,expression in [('symbol','mᵀ'),('named','m.transpose()')]:
                add(41,f'{label}-{n}-{i}-{j}',prefix+expression+f'.at({i},{j})',values[j*2+i],imports='import "std.scientific" { Matrix; }.scientific;\n')
    for n,(a,b,c,d) in enumerate(((1,2,3,-4),(7,-11,17,29),(-5,13,23,-31))):
        prefix=f'Matrix<Complex,2,1> [({a},{b}),({c},{d})].m;'
        for label,expression in [('symbol','m†'),('named','m.adjoint()')]:
            for method,j,value in [('realAt',0,a),('imagAt',0,-b),('realAt',1,c),('imagAt',1,-d)]:
                add(42,f'{label}-{n}-{method}-{j}',prefix+expression+f'.{method}(0,{j})',value,imports='import "std.scientific" { Matrix; }.scientific;\n')
    for n,(a,b,c,d) in enumerate(((2,1,1,1),(3,1,2,1),(2,5,7,11))):
        prefix=f'Matrix<Int,2,2> [{a},{b},{c},{d}].m;'
        determinant=a*d-b*c
        for label,expression in [('symbol','m⁻¹'),('named','m.inverse()')]:
            for i,j,value in [(0,0,d),(0,1,-b),(1,0,-c),(1,1,a)]:
                add(43,f'{label}-{n}-{i}-{j}',prefix+expression+f'.numeratorAt({i},{j})',value,imports='import "std.scientific" { Matrix; }.scientific;\n')
            add(43,f'{label}-{n}-denominator',prefix+expression+'.denominator()',determinant,imports='import "std.scientific" { Matrix; }.scientific;\n')
    for n,(a,b) in enumerate(((3,4),(5,12),(8,15),(0,0))):
        prefix=f'Vector<Int,2> [{a},{b}].a;Vector<Int,2> [7,11].b;'
        for label,expression in [('symbol','‖a‖'),('named','a.norm()')]:
            add(44,f'{label}-{n}',prefix+expression,math.isqrt(a*a+b*b))
        for label,expression in [('symbol','⟨a,b⟩'),('named','a.innerProduct(b)')]:
            add(45,f'{label}-{n}',prefix+expression,a*7+b*11)
    for n,samples in enumerate(((0,1,2),(2,3,4),(7,11,17),(0,0,0))):
        array='['+','.join(map(str,samples))+']'
        value=Fraction(samples[0]+2*sum(samples[1:-1])+samples[-1],2)
        for form in ('∫','integrate'):
            observer='value' if value.denominator==1 else 'numerator'
            # The public numeric result preserves the unsimplified quadrature.
            expected=int(value) if observer=='value' else (samples[0]+2*sum(samples[1:-1])+samples[-1])*2
            add(49,f'{form.encode().hex()}-{n}',f'{form}(x,0,2,trapezoid,1,16,{array}).{observer}()',expected)
    for dimensions,symbol,method in ((2,'∬','integrate2D'),(3,'∭','integrate3D')):
        for n,samples in enumerate(((1,2,3,4),(3,5,7,9),(0,0,0,0))):
            domains='x,0,2,y,0,2'+(',z,0,2' if dimensions==3 else '')
            array='['+','.join(map(str,samples))+']'
            for form in (symbol,method):
                add(48+dimensions,f'{form.encode().hex()}-{n}',f'{form}({domains},rectangle,1,16,{array}).value()',sum(samples)*2**dimensions//len(samples))
    for n,samples in enumerate(((1,0,2,0,0,1,0,3),(2,3,5,7,11,13,17,19))):
        value=sum(samples[i]*samples[i+2]+samples[i+1]*samples[i+3] for i in (0,4))
        for orientation,sign in [('clockwise',-1),('counterclockwise',1)]:
            for form in ('∮','contourIntegrate'):
                add(52,f'{form.encode().hex()}-{n}-{orientation}',f'{form}(t,0,2,line,{orientation},1,16,['+','.join(map(str,samples))+']).value()',sign*value)
    for n,(coefficient,power,x) in enumerate(((3,2,4),(2,3,2),(7,1,11))):
        for form in ('∂','partial'):
            add(53,f'{form.encode().hex()}-{n}',f'{form}(x,unitless,symbolic,analytic,{x},1,64,[{coefficient},{power}]).value()',coefficient*power*x**(power-1))
    for n,values in enumerate(((6,10,2,2),(8,14,4,6),(0,0,0,0))):
        for form in ('∇','gradient'):
            for i in (0,1):add(54,f'{form.encode().hex()}-{n}-{i}',f'{form}(2,unitless,numeric,central,1,64,['+','.join(map(str,values))+f']).component({i})',(values[i]-values[i+2])//2)
    for n,values in enumerate(((2,3,4),(7,11,17),(-2,3,-4))):
        for form in ('∇·','divergence'):
            add(55,f'{form.encode().hex()}-{n}',f'{form}(3,unitless,numeric,central,64,['+','.join(map(str,values))+']).value()',sum(values))
    for n,jacobian in enumerate((list(range(9)),[2,3,5,7,11,13,17,19,23])):
        curl=(jacobian[7]-jacobian[5],jacobian[2]-jacobian[6],jacobian[3]-jacobian[1])
        for form in ('∇×','curl'):
            for i,value in enumerate(curl):add(56,f'{form.encode().hex()}-{n}-{i}',f'{form}(3,unitless,numeric,central,64,['+','.join(map(str,jacobian))+f']).component({i})',value)
    for n,(center,values) in enumerate(((5,(7,9,3,5)),(3,(5,7,3,5)),(0,(0,0,0,0)))):
        value=sum(values[i]+values[i+2]-2*center for i in (0,1))//4
        for form in ('Δ','laplacian'):
            add(57,f'{form.encode().hex()}-{n}',f'{form}(2,unitless,numeric,central,dirichlet,4,{center},64,['+','.join(map(str,values))+']).value()',value)
    for n,(jn,jd,cn,cd) in enumerate(((1,4,1,2),(1,3,2,3),(2,5,4,5))):
        value=Fraction(jn,jd)/Fraction(cn,cd)
        for form,args in [('conditionalOn',f'17,{jn},{jd},{cn},{cd},83'),('P',f'17,{jn},{jd} | {cn},{cd},83')]:
            for observer,expected in [('numerator',value.numerator),('denominator',value.denominator)]:
                add(60,f'{form}-{n}-{observer}',f'{form}({args}).{observer}()',expected)
    for relation,value in [('independent',1),('dependent',0)]:
        for symbol in (False,True):
            args='23,5 ⫫ 8' if symbol else '23,5,8'
            add(59,f'{relation}-{symbol}',f'independentOf({args},{relation},67).value()',value)
    for shape in (1,2,3):
        for symbol in (False,True):
            args=f'17,3 ∼ bernoulli,discrete,{shape},discrete,{shape},0,1,64' if symbol else f'17,3,discrete,{shape},bernoulli,discrete,{shape},0,1,64'
            add(58,f'discrete-{shape}-{symbol}',f'distributedAs({args}).shape()',shape)
    for number,symbol,method in ((61,'∀','forAll'),(62,'∃','exists'),(63,'∄','notExists')):
        for n,(domain,count,unknown,timeout) in enumerate(((1,0,0,0),(5,5,0,0),(7,2,0,0),(7,0,1,0),(7,0,0,1))):
            if number==61:status=1 if domain-count-unknown-timeout else 5 if timeout else 4 if unknown else 0
            elif number==62:status=2 if count else 5 if timeout else 4 if unknown else 3
            else:status=1 if count else 5 if timeout else 4 if unknown else 0
            for form in (symbol,method):
                add(number,f'{form.encode().hex()}-{n}',f'{form}({domain},{count},{unknown},{timeout},31).status()',status)
    for number,symbol,method,rule in ((64,'⇒','implies',lambda a,b:not a or b),
            (65,'⇔','iff',lambda a,b:a==b),(68,'⊼','nand',lambda a,b:not(a and b)),(69,'⊽','nor',lambda a,b:not(a or b))):
        for a in (0,1):
            for b in (0,1):
                for symbolic in (False,True):
                    args=f'{a} {symbol} {b},7' if symbolic else f'{a},{b},7'
                    add(number,f'{a}-{b}-{symbolic}',f'{method}({args}).value()',rule(a,b))
    for number,method,symbol,statuses in [(66,'proves','⊢',[('proved',0),('disproved',1),('unknown',4),('timeout',5)]),
            (67,'satisfies','⊨',[('sat',2),('unsat',3),('unknown',4),('timeout',5)])]:
        for status,code in statuses:
            evidence=17 if status in ('proved','disproved','unsat') else 0
            for symbolic in (False,True):
                args=f'11 {symbol} 13' if symbolic else '11,13'
                add(number,f'{status}-{symbolic}',f'{method}({args},{status},{evidence},31).status()',code)
    for number,method,symbol in [(70,'directedEdgeTo','→'),(71,'bidirectionalEdge','↔'),(72,'asyncEdgeTo','⇢'),(73,'transitionTo','⟶')]:
        for n,(a,b) in enumerate(((17,29),(31,43),(53,71))):
            for symbolic in (False,True):
                args=f'{a} {symbol} {b}' if symbolic else f'{a},{b}'
                extra=',3,5,7,7,11,0' if number<72 else ',3,5,7,7,11,1,3' if number==72 else ',3,5,7,7,1,1,3'
                add(number,f'endpoint-{n}-{symbolic}',f'{method}({args}{extra}).replay()',b)
        if number==73:
            add(number,'guard-denied','transitionTo(17 ⟶ 29,3,5,7,7,0,0,1).replay()',17)
    for n,(a,b) in enumerate((('Nebo','Text'),('altered','Text'),('é','🚀'))):
        for symbolic in (False,True):
            args=json.dumps(a,ensure_ascii=False)+(' ⧺ ' if symbolic else ',')+json.dumps(b,ensure_ascii=False)
            add(74,f'bytes-{n}-{symbolic}',f'concat({args}).byteLength()',len((a+b).encode()))
    for number in (75,76):
        for n,(text,pattern,expected) in enumerate((('atlas','a.las',True),('altered','a.las',False),('xxabczz','a.c',True),('ab','abc',False))):
            symbol='=~' if number==75 else '!~'
            value=expected if number==75 else not expected
            add(number,f'match-{n}',f'matches({json.dumps(text)} {symbol} Pattern({json.dumps(pattern)},1,200)).matched()',value)
    for n,(level,enabled,seed) in enumerate(((7,True,17),(11,False,29),(63,True,255))):
        for observer,value in [('levelValue',level),('enabledValue',enabled),('argumentCount',3),('argumentMask',7)]:
            add(80,f'metadata-{n}-{observer}',f'@stable(version:1,level:{level},enabled:{str(enabled).lower()}) function item(seed:{seed},privacy:0).{observer}()',value)
    return rows

# Each diagnostic comes from the current native owner's permanent regression
# contract. These files are product inputs, never expected compiler output.
NEGATIVES={
 40:('G134','dot-shape-mismatch','NEBO_TYPE_MISMATCH'),
 46:('G134','composition-shape-mismatch','NEBO_TYPE_MISMATCH'),
 41:('G135','transpose-bounds','NEBO_TUPLE_INDEX_OUT_OF_RANGE'),
 42:('G135','adjoint-real-domain','NEBO_TYPE_MISMATCH'),
 43:('G135','singular-inverse','NEBO_TYPE_DIVISION_BY_ZERO'),
 44:('G135','inexact-norm','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 45:('G135','inner-shape-mismatch','NEBO_TYPE_MISMATCH'),
 49:('G136','zero-tolerance','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 50:('G136','repeated-binder','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 51:('G136','reversed-domain','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 52:('G136','contour-domain-mismatch','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 53:('G137','zero-step','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 54:('G137','gradient-shape','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 55:('G137','bad-unit','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 56:('G137','curl-dimension','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 57:('G137','laplacian-boundary','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 58:('G138','distribution-type','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 59:('G138','self-independence','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 60:('G138','zero-condition','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 61:('G139','quantifier-domain-zero','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 62:('G139','quantifier-count-overflow','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 63:('G139','domain-limit','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 64:('G139','bool-nonbool','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 65:('G139','iff-chain','NEBO_PARSE_UNEXPECTED_TOKEN'),
 66:('G139','proved-zero-proof','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 67:('G139','unsat-zero-witness','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 68:('G139','bool-nonbool','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 69:('G139','bool-nonbool','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 70:('G140','schema-mismatch','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 71:('G140','wrong-arrow-family','NEBO_PARSE_UNEXPECTED_TOKEN'),
 72:('G140','zero-capability','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 73:('G140','missing-effect-capability','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 74:('G141','concat-number','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 75:('G141','pattern-bad-mode','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 76:('G141','wrong-nonmatch-operator','NEBO_TYPE_UNSUPPORTED_OPERATOR'),
 80:('G143','bare-at','NEBO_PARSE_UNEXPECTED_TOKEN'),
}

def negatives():
    rows=[(f'dom-{number:03}-negative',('import "std.scientific" { Matrix; }.scientific;\n' if number in (41,42,43) else '')+(ROOT/f'tests/rf204/{group}/negative/{name}.no').read_text(),code)
          for number,(group,name,code) in NEGATIVES.items() if number not in (40,55,68,69)]
    rows.append(('dom-040-negative','start(){Vector<Int,1> [1].a;Vector<Int,1> [9223372036854775807].b;(a ⊕ b).sum();}',
                 'NEBO_TYPE_CONSTANT_OVERFLOW'))
    rows.append(('dom-055-negative','start(){divergence(3,invalidUnit,numeric,central,64,[2,3,4]).value();}',
                 'NEBO_TYPE_UNSUPPORTED_OPERATOR'))
    for number,method in ((68,'nand'),(69,'nor')):
        rows.append((f'dom-{number:03}-negative',f'start(){{{method}(2,0,7).value();}}','NEBO_TYPE_UNSUPPORTED_OPERATOR'))
    for form in ('Δ','laplacian'):
        rows.append((f'dom-057-nonexact-{form.encode().hex()}',
                     f'start(){{{form}(2,unitless,numeric,central,dirichlet,4,3,64,[5,7,3,3]).value();}}',
                     'NEBO_TYPE_UNSUPPORTED_OPERATOR'))
    return rows

def run():
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-bounded-operators-',dir='/tmp') as directory:
        root=Path(directory)
        for name,source,status,options in cases():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=pipeline(path,work,status,**options)
            except Failure as error:raise Failure(name+':'+str(error)) from error
            results.append(dict(id=name,result='PASS',category='positive',**proof))
        for name,source,code in negatives():
            work=root/name;work.mkdir();path=work/'source.no';path.write_text(source)
            try:proof=reject(path,work,code)
            except Failure as error:raise Failure(name+':'+str(error)) from error
            results.append(dict(id=name,result='PASS',category='negative',**proof))
    return dict(schema=1,oracle='independent-finite-domain-mathematics-v1',cases=results,
                passed=len(results),total=len(cases())+len(negatives()))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
