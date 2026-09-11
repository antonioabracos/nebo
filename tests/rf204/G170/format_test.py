#!/usr/bin/env python3
"""Public typed formatting, independent of the legacy seed-driven reports."""
import json
import tempfile
from pathlib import Path
from harness import ROOT, Failure, pipeline, reject, execute, elf
from text_test import literal, document


def cases():
    rows=[]
    def add(name,template,args,value):
        source='start(){'+literal(template)+'.format('+','.join(args)+').console();23.return;}'
        rows.append((name,source,23,document(value)))
    for index,(name,value) in enumerate((('Nebo',29),('Lang',83),('ação',-17))):
        add('template-values-'+str(index),'Olá %s %d',[literal(name),str(value)],f'Olá {name} {value}')
    for value in (0,7,-29,83,9223372036854775807,-9223372036854775808):
        add('decimal-'+str(value),'%d',[str(value)],str(value))
    for value in (True,False):add('bool-'+str(value),'%b',[str(value).lower()],str(value).lower())
    for value in ('','Nebo','ação','A\nB'):
        add('text-'+value.encode().hex(),'%s',[literal(value)],value)
    for value in (7,29,255):
        add('hex-'+str(value),'%x',[str(value)],format(value,'x'))
        add('octal-'+str(value),'%o',[str(value)],format(value,'o'))
        add('zero-width-'+str(value),'%04d',[str(value)],format(value,'04d'))
    for value in ('Nebo','ação',''):
        # Width is measured in UTF-8 bytes by the current native profile.
        add('align-right-'+value.encode().hex(),'%8s',[literal(value)],' '*(8-len(value.encode()))+value)
        add('align-left-'+value.encode().hex(),'%-8s',[literal(value)],value+' '*(8-len(value.encode())))
    for value in (0.0,17.5,-29.25,83.75):
        add('fixed-'+str(value),'%.2f',[str(value)],format(value,'.2f'))
    for value in (0.0,-0.0,1.25,17.5,-29.25,0.125,9.999,99.99):
        add('scientific-'+str(value),'%.2e',[str(value)],format(value,'.2e'))
    for value in (1.125,1.375,-1.125,-1.375):
        add('fixed-nearest-even-'+str(value),'%.2f',[str(value)],format(value,'.2f'))
    for precision in (0,1,3,6):
        for value in (0.0,1.0,9.9999999,-29.25):
            add('scientific-precision-'+str(precision)+'-'+str(value),'%.'+str(precision)+'e',[str(value)],format(value,'.'+str(precision)+'e'))
    add('literal-percent','100%%',[],'100%')
    add('empty-template','',[],'')
    add('position-reorder','%2$s %1$d',['29','"Nebo"'],'Nebo 29')
    add('position-repeat','%1$d/%1$d',['29'],'29/29')
    for name,value in (('Nebo',29),('ação',83)):
        add('named-'+str(value),'%{nome:s} %{idade:d}',['idade:'+str(value),'nome:'+literal(name)],name+' '+str(value))
    add('named-repeat','%{value:d}/%{value:d}',['value:29'],'29/29')
    for kind,argument,value in [('Text','"Nebo"','Nebo'),('Int','-29','-29'),('Bool','true','true'),('Float','17.5','17.500000')]:
        add('value-'+kind,'%v',[argument],value)
        add('typename-'+kind,'%T',[argument],kind)
    for value in ('Nebo','ação','A\nB','A"B\\C'):
        add('json-'+value.encode().hex(),'%j',[literal(value)],json.dumps(value,ensure_ascii=False,separators=(',',':')))
        add('quote-'+value.encode().hex(),'%q',[literal(value)],json.dumps(value,ensure_ascii=False,separators=(',',':')))
    for value in (-29,0,83):
        add('signed-padding-'+str(value),'%+06d',[str(value)],format(value,'+06d'))
    for status in (0,7,23,29,255):
        rows.append(('return-'+str(status),'start(){"%d".format(83).console();'+str(status)+'.return;}',status,document('83')))
    add('arguments-64','|'.join('%d' for _ in range(64)),list(map(str,range(64))),'|'.join(map(str,range(64))))
    for size in (4095,4096):add('template-'+str(size),'a'*size,[],'a'*size)
    rows.extend([
        ('two-live','start(){"%d".format(17).one;"%s".format("Nebo").two;one.console();two.console();one.console();23.return;}',23,dict(kinds=[2,2,2],text=b'17Nebo17')),
        ('evaluated-once','(Int.x)value(){x.console();x.return;}start(){"%d:%d".format(17.value(),29.value()).console();23.return;}',23,dict(kinds=[4,4,2],text=b'172917:29')),
        ('format-is-silent','start(){"%s %d".format("Nebo",29);23.return;}',23,{}),
        ('named-once','(Int.x)value(){x.console();x.return;}start(){"%{first:d}/%{second:d}".format(second:29.value(),first:17.value()).console();23.return;}',23,dict(kinds=[4,4,2],text=b'291717/29')),
    ])
    return rows


def negatives():
    rows=[('unknown','%z','17','NEBO-FORMAT-001'),('missing','%s %d','"Nebo"','NEBO-FORMAT-002'),
          ('extra','%s','"Nebo",17','NEBO-FORMAT-002'),('wrong-type','%d','"Nebo"','NEBO-FORMAT-003'),
          ('coercion-forbidden','%s','17','NEBO-FORMAT-007'),
          ('width-limit','%257s','"Nebo"','NEBO-FORMAT-004'),('precision-limit','%.7f','1.5','NEBO-FORMAT-004'),
          ('position-zero','%0$s','"Nebo"','NEBO-FORMAT-006'),('pointer','%p','17','NEBO-FORMAT-001')]
    rows.extend([('arguments-65','%d',','.join(map(str,range(65))),'NEBO-FORMAT-002'),
                 ('template-4097','a'*4097,'','NEBO-FORMAT-008'),
                 ('nodes-129','%1$dX'*64+'%1$d','17','NEBO-FORMAT-008'),
                 ('position-missing','%2$d','17','NEBO-FORMAT-006')])
    rows.extend([('named-duplicate','%{value:d}','value:17,value:29','NEBO-FORMAT-005'),
                 ('named-absent','%{other:d}','value:17','NEBO-FORMAT-005'),
                 ('named-type','%{value:d}','value:"Nebo"','NEBO-FORMAT-003')])
    for name,template,arg in [('bool','%b','17'),('float','%f','17'),('scientific','%e','17'),
                              ('hex','%x','"Nebo"'),('octal','%o','"Nebo"'),('quote','%q','true'),
                              ('json','%j','false'),('value','%v','List<Int>.new()'),('typename','%T','List<Int>.new()')]:
        rows.append(('wrong-'+name,template,arg,'NEBO-FORMAT-003'))
    result=[(name,'start(){'+literal(template)+'.format('+args+');23.return;}',code) for name,template,args,code in rows]
    result.extend([
        ('checked-policy-type','start(){"%d".formatWith(true,17);23.return;}','NEBO-FORMAT-003'),
        ('checked-policy-missing','start(){"%d".formatWith();23.return;}','NEBO-FORMAT-002'),
        ('checked-fallback-type','start(){"%d".formatWith(0,17).unwrapOr(29);23.return;}','NEBO-FORMAT-003'),
        ('checked-fallback-arity','start(){"%d".formatWith(0,17).unwrapOr();23.return;}','NEBO-FORMAT-002'),
        ('checked-predicate-arity','start(){"%d".formatWith(0,17).isOk(29);23.return;}','NEBO-FORMAT-002'),
        ('dynamic-strict','start(){"%d".t.mutable;t="%s";t.format(29);23.return;}','NEBO-FORMAT-001'),
    ])
    return result


def checked_cases():
    rows=[]
    def add(name,template,policy,args,value):
        source='start(){'+literal(template)+'.template;template.formatWith('+str(policy)+(' ,'+','.join(args) if args else '')+').unwrapOr("fallback").console();23.return;}'
        rows.append((name,source,23,document(value)))
    for value in (0,7,-29,83,9223372036854775807,-9223372036854775808):
        add('checked-int-'+str(value),'value=%d',0,[str(value)],'value='+str(value))
    for value in ('Nebo','ação','A\nB'):
        add('checked-text-'+value.encode().hex(),'value=%s',0,[literal(value)],'value='+value)
    add('checked-named','%{nome:s} %{idade:d}',32,['idade:29','nome:"Nebo"'],'Nebo 29')
    add('checked-named-duplicate','%{nome:s}',32,['nome:"Nebo"','nome:"Lang"'],'fallback')
    for name,template,args in [('unknown','%z',['17']),('arity','%d %s',['17']),('type','%d',['"Nebo"']),
                               ('width','%257d',['17']),('named','%{absent:d}',['17']),('position','%0$d',['17']),
                               ('coercion','%s',['17']),('limit','a'*4097,[])]:
        add('checked-error-'+name,template,0,args,'fallback')
    for name,policy,template,args,value in [('coercion',1,'%s',['17'],'17'),('extra',4,'%s',['"Nebo"','17'],'Nebo'),
                                         ('unknown',8,'A%z',[],'A%z'),('missing',2,'%s',[],'<missing>'),
                                         ('validate',16,'%d',['17'],''),('position',64,'%2$s %1$d',['29','"Nebo"'],'Nebo 29'),
                                         ('invalid',128,'%d',['17'],'fallback'),('contradictory',96,'%d',['17'],'fallback')]:
        add('policy-'+name,template,policy,args,value)
    rows.extend([
        ('checked-two-live','start(){"%d".formatWith(0,17).one;"%z".formatWith(0,29).two;one.unwrapOr("bad").console();two.unwrapOr("error").console();one.unwrapOr("bad").console();23.return;}',23,dict(kinds=[2,2,2],text=b'17error17')),
        ('checked-once','(Int.x)value(){x.console();x.return;}start(){"%d".formatWith(0.value(),29.value()).unwrapOr("fallback").console();23.return;}',23,dict(kinds=[4,4,2],text=b'02929')),
        ('checked-nested','start(){"[%s]".formatWith(0,"%d".formatWith(0,83).unwrapOr("bad")).unwrapOr("bad").console();23.return;}',23,document('[83]')),
        ('checked-silent','start(){"%z".formatWith(0,29);23.return;}',23,{}),
    ])
    for size in (8191,8192,8193):
        source='start(){'+literal('x'*size)+'.value;'+literal('%1$s'*128)+'.formatWith(0,value).unwrapOr("fallback").byteLength().console();23.return;}'
        rows.append(('output-limit-'+str(size),source,23,document(size*128 if size<=8192 else len('fallback'))))
    for success,template in ((True,'%d'),(False,'%z')):
        for method,expected in (('isOk',success),('isErr',not success)):
            rows.append(('checked-'+method+'-'+str(success),'start(){'+literal(template)+'.formatWith(0,29).'+method+'().console();23.return;}',23,document(expected)))
    # The same valid, within-limit output request succeeds with the ordinary
    # stack budget and returns Err before writing with a smaller owned budget.
    template=literal('%1$s'*128)
    value=literal('x'*8192)
    for budget,valid in ((1048576,False),(8388608,True)):
        source='start(){'+value+'.value;'+template+'.formatWith(0,value).isOk().console();23.return;}'
        rows.append(('allocation-'+str(budget),source,23,dict(**document(valid),stack_bytes=budget)))
    source='start(){'+value+'.value;'+template+'.formatWith(0,value).unwrapOr("allocation failed").console();23.return;}'
    rows.append(('allocation-atomic-fallback',source,23,dict(**document('allocation failed'),stack_bytes=1048576)))
    return rows


def configured_cases():
    rows=[]
    def add(name,template,policy,args,wanted):
        source='start(){'+literal(template)+'.'+policy+'.format('+args+').unwrapOr("fallback").console();23.return;}'
        rows.append((name,source,23,document(wanted)))
    for value in (0,7,29,-83):
        add('configured-strict-'+str(value),'%d','strict()',str(value),str(value))
        add('configured-coerce-'+str(value),'%s','allowCoerce()',str(value),str(value))
        add('configured-no-coerce-'+str(value),'%s','allowCoerce().noCoerce()',str(value),'fallback')
        add('configured-strict-reset-'+str(value),'%s','loose().strict()',str(value),'fallback')
    for name,template,policy,args,wanted in [
        ('loose-extra','%s','loose()','17,29','17'),
        ('loose-missing','%s','loose()','','<missing>'),
        ('loose-unknown','A%z','loose()','','A%z'),
        ('validate','%d','validateOnly()','17',''),
        ('format','%d','validateOnly().formatOnly()','17','17'),
        ('named','%{value:d}','placeholderMode(1)','value:29','29'),
        ('position','%2$s/%1$d','placeholderMode(2)','29,"Nebo"','Nebo/29'),
        ('mode-reset','%d','placeholderMode(1).placeholderMode(0)','29','29'),
        ('mode-named-error','%d','placeholderMode(1)','29','fallback'),
        ('mode-position-error','%{value:d}','placeholderMode(2)','value:29','fallback'),
        ('unknown','A%z','unknownPlaceholder(1)','','A%z'),
        ('unknown-reset','A%z','unknownPlaceholder(1).unknownPlaceholder(0)','','fallback'),
        ('missing','%s','missingArgs(1)','','<missing>'),
        ('missing-reset','%s','missingArgs(1).missingArgs(0)','','fallback'),
        ('extra','%d','extraArgs(1)','17,29','17'),
        ('extra-reset','%d','extraArgs(1).extraArgs(0)','17,29','fallback')]:add('configured-'+name,template,policy,args,wanted)
    rows.extend([
        ('configured-two-live','start(){"%s".strict().a;a.allowCoerce().b;a.format(17).unwrapOr("first").console();b.format(29).unwrapOr("bad").console();a.format("Nebo").unwrapOr("bad").console();23.return;}',23,dict(text=b'first29Nebo',kinds=[2]*3)),
        ('configured-effects','(Int.x)observe(){x.console();x.return;}start(){"%d".extraArgs(1.observe()).format(17.observe(),29.observe()).unwrapOr("bad").console();23.return;}',23,dict(text=b'1172917',kinds=[4,4,4,2])),
        ('configured-silent','start(){"%d".strict().format(17);23.return;}',23,{}),
        ('configured-snapshot','start(){"%d".template.mutable;template.strict().a;template="%s";a.format(17).unwrapOr("bad").console();23.return;}',23,document('17')),
        ('configured-nested','start(){"[%s]".strict().format("%s".allowCoerce().format(29).unwrapOr("bad")).unwrapOr("bad").console();23.return;}',23,document('[29]')),
    ])
    for returned in (0,7,23,29,255):
        rows.append(('configured-return-'+str(returned),'start(){"%s".allowCoerce().format(83).unwrapOr("bad").console();'+str(returned)+'.return;}',returned,document('83')))
    for method,arg in [('placeholderMode',3),('unknownPlaceholder',2),('missingArgs',-1),('extraArgs',2)]:
        rows.append(('configured-domain-'+method,'start(){"%d".'+method+'('+str(arg)+');23.return;}',170,{}))
    for profile,opening,separator,closing in [('#','{',':','}'),('?','<',' ','>')]:
        for kind,arg,value in [('Int','17','17'),('Int','-83','-83'),('Float','1.5','1.500000'),('Bool','true','true'),('Bool','false','false'),('Text','"Nebo"','"Nebo"'),('Text',literal('A"B\\C\n'),json.dumps('A"B\\C\n',ensure_ascii=False))]:
            text=opening+kind+separator+value+closing
            rows.append(('structure-'+profile+'-'+kind+'-'+arg.encode().hex(),'start(){'+literal('%'+profile)+'.format('+arg+').console();23.return;}',23,document(text)))
    return rows


def configured_negatives():
    rows=[]
    for method in ('strict','loose','allowCoerce','noCoerce','validateOnly','formatOnly'):
        rows.append(('configured-arity-'+method,'start(){"%d".'+method+'(17);23.return;}','NEBO-FORMAT-002'))
    for method in ('placeholderMode','unknownPlaceholder','missingArgs','extraArgs'):
        rows.append(('configured-type-'+method,'start(){"%d".'+method+'(true);23.return;}','NEBO-FORMAT-003'))
        rows.append(('configured-arity-'+method,'start(){"%d".'+method+'();23.return;}','NEBO-FORMAT-002'))
    return rows


def parsed_cases():
    rows=[]
    for template,valid in [('%d',True),('%s/%d',True),('%{value:d}',True),('%2$s/%1$d',True),('',True),('%%',True),('%z',False),('%',False),('%257d',False),('%.7f',False),('%0$d',False),('x'*4097,False)]:
        source='start(){FormatString.parseChecked('+literal(template)+').r;r.isOk().console();r.isErr().console();23.return;}'
        rows.append(('parsed-status-'+template.encode().hex()[:60],source,23,dict(text=(str(valid).lower()+str(not valid).lower()).encode(),kinds=[5,5])))
    for template,types,valid in [('%d','Int',True),('%s','Text',True),('%f','Float',True),('%b','Bool',True),('%s/%d','Text,Int',True),('%2$s/%1$d','Int,Text',True),('%s/%d','Int,Text',False),('%d','Text',False),('%s','Int',False),('%d','',False),('%d','Int,Int',False),('','',True)]:
        source='start(){FormatString.parseChecked('+literal(template)+').get().t;t.validate(Tuple.of('+types+')).console();23.return;}'
        rows.append(('parsed-validate-'+template.encode().hex()+'-'+types.replace(',','_'),source,23,document(valid)))
    for index,(signature,wanted) in enumerate([
        ('value:Int',True),('other:Int',False),('value:Text',False),
        ('value:Int,value:Int',False),('Int',False),('value:Int,extra:Text',False)]):
        source='start(){FormatString.parseChecked("%{value:d}").get().t;t.validate(Tuple.of('+signature+')).console();23.return;}'
        rows.append(('parsed-named-signature-'+str(index),source,23,document(wanted)))
    rows.append(('parsed-interpolation','start(){"${FormatString.parseChecked("%d").get().validate(Tuple.of(Int))}".console();23.return;}',23,document('true')))
    for value in (7,17,-29,83):
        for returned in (0,7,23,29,255):
            source='start(){FormatString.parseChecked("%d").get().t;t.format('+str(value)+').unwrapOr("bad").console();'+str(returned)+'.return;}'
            rows.append((f'parsed-value-{value}-{returned}',source,returned,document(str(value))))
    rows.extend([
        ('parsed-unwrap-fallback','start(){FormatString.parseChecked("%z").unwrapOr("%d".strict()).t;t.format(29).unwrapOr("bad").console();23.return;}',23,document('29')),
        ('parsed-unwrap-success','start(){FormatString.parseChecked("%s").unwrapOr("%d".strict()).t;t.format("Nebo").unwrapOr("bad").console();23.return;}',23,document('Nebo')),
        ('parsed-two-live','start(){FormatString.parseChecked("%d").get().a;FormatString.parseChecked("%s").get().b;a.format(17).unwrapOr("bad").console();b.format("Nebo").unwrapOr("bad").console();a.format(29).unwrapOr("bad").console();23.return;}',23,dict(text=b'17Nebo29',kinds=[2]*3)),
        ('parsed-policy','start(){FormatString.parseChecked("%s").get().allowCoerce().format(29).unwrapOr("bad").console();23.return;}',23,document('29')),
        ('parsed-named','start(){FormatString.parseChecked("%{value:d}").get().format(value:29).unwrapOr("bad").console();23.return;}',23,document('29')),
        ('parsed-snapshot','start(){"%d".source.mutable;FormatString.parseChecked(source).get().a;source="%s";a.format(29).unwrapOr("bad").console();23.return;}',23,document('29')),
        ('parsed-failed-get','start(){FormatString.parseChecked("%z").get();23.return;}',170,{}),
    ])
    for operation in ('FormatString.parseChecked("%d").isOk()','"%d".formatWith(0,17).isOk()','"%d".strict().validate(Tuple.of(Int))'):
        source='start(){0.i.mutable;0.total.mutable;while(i<10000){if('+operation+'){total+=1;}i+=1;}total.console();23.return;}'
        rows.append(('parsed-loop-'+str(len(rows)),source,23,dict(text=b'10000',kinds=[4],stack_bytes=1048576)))
    return rows


def parsed_negatives():
    rows=[]
    for name,body,code in [('argument-type','FormatString.parseChecked(17);','NEBO-FORMAT-003'),('arity','FormatString.parseChecked();','NEBO-FORMAT-002'),('extra','FormatString.parseChecked("%d",17);','NEBO-FORMAT-002'),('get-arity','FormatString.parseChecked("%d").get(1);','NEBO-FORMAT-002'),('unwrap-type','FormatString.parseChecked("%d").unwrapOr("%s");','NEBO-FORMAT-003'),('signature-type','"%d".strict().validate(Tuple.of(17));','NEBO-FORMAT-003'),('signature-unknown','"%d".strict().validate(Tuple.of(Missing));','NEBO-FORMAT-003'),('signature-shadow','17.Int;"%d".strict().validate(Tuple.of(Int));','NEBO-FORMAT-003'),('signature-limit','"%d".strict().validate(Tuple.of(Int,Int,Int,Int,Int,Int,Int));','NEBO-FORMAT-003')]:rows.append(('parsed-'+name,'start(){'+body+'23.return;}',code))
    return rows


def run():
    rows=[]
    targets=[f'build/tests/rf204/G{group}/g{group}_runtime_test' for group in ('059','060','062')]
    targets.append('build/tests/rf204/G170/format_plan_native')
    with tempfile.TemporaryDirectory(prefix='nebo-G170-format-') as d:
        built=execute(['ninja','-j2',*targets],Path(d),timeout=60)
        if built[0]!=0: raise Failure('FORMAT_NATIVE_BUILD:'+str(built))
        for target in targets:
            elf(ROOT/target)
            value=execute([str(ROOT/target)],Path(d),timeout=30,runtime=True)
            rows.append(dict(id='native-'+Path(target).stem,category='native-owner',result='PASS' if value==(0,b'',b'') else 'FAIL',exit=value[0]))
        for negative,matrix in ((False,cases()+checked_cases()+configured_cases()+parsed_cases()),(True,negatives()+configured_negatives()+parsed_negatives())):
            for name,source,expected,*options in matrix:
                work=Path(d)/name;work.mkdir();path=work/'source.no';path.write_text(source)
                try:
                    proof=reject(path,work,expected) if negative else pipeline(path,work,expected,**options[0])
                    result=dict(result='PASS',**proof)
                except Failure as e:result=dict(result='FAIL',failure=str(e))
                rows.append(dict(id=name,category='negative' if negative else 'positive',**result))
    return dict(passed=sum(r['result']=='PASS' for r in rows),total=len(rows),cases=rows)


if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
