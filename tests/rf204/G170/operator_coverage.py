"""Explicit Registry-to-source joins; declarations alone never prove coverage."""
from operator_test import cases, negatives


def joins():
    positive = [row[0] for row in cases()]
    negative = {row[0] for row in negatives()}
    result = {}

    def family(group, number, prefixes, bad, reason=''):
        selected = [name for name in positive if name.startswith(tuple(prefixes))]
        assert selected and set(bad) <= negative
        result[f'NSR-{group}-{number:03d}'] = (
            ','.join('operator:'+name for name in selected),
            ','.join('operator:'+name for name in bad), reason)

    def binary(group, number, symbol):
        key=symbol.encode().hex()
        family(group, number, ['binary-'+key+'-'], ['wrong-'+key])

    for number in (1,2,3,7):
        family('CORE',number,['binary-2b-','discard-scope'],['discard-mutable'])
    for number in (4,5):
        family('CORE',number,['reduce-e28891-','reduce-e2888f-'],
               ['wrong-domain-e28891','reduce-overflow-e2888f'])
    family('CORE',6,['bytes-construct-four-'],['bytes-four-arity'])
    result['NSR-CORE-008']=('format:named-29,format:named-83,format:named-once',
                            'format:named-duplicate,format:named-absent,format:named-type','')
    family('CORE',9,['wildcard-'],['discard-mutable'])
    family('CORE',10,['wildcard-','discard-'],['discard-read','discard-mutable'])
    family('CORE',11,['comment-'],['comment-does-not-bind'])
    for number,symbol in enumerate(('+','-','*','/','%','^'),12):binary('CORE',number,symbol)
    for number,symbol in ((18,'+'),(19,'-'),(20,'!')):
        family('CORE',number,['unary-'+symbol.encode().hex()+'-'],['wrong-unary-'+symbol.encode().hex()])
    for number,symbol in ((21,'&&'),(22,'||')):
        family('CORE',number,['logic-'+symbol.encode().hex()+'-','short-and' if number==21 else 'short-or'],['wrong-logic-int'])
    family('CORE',23,['binary-786f72-','logic-786f72-','bytes-xor-','bytes-construct-'],
           ['wrong-786f72','bytes-xor-mixed','bytes-bool','bytes-arity'],
           'Equal Int/Bool/Bytes operands; immutable Bytes XOR requires equal lengths at most 4096; '
           'fromByte takes one Int and fromValues four Ints in 0..255; private initialized storage; ordered effects and two live outputs.')
    for number,symbol in enumerate(('<','<=','>','>=','==','!='),24):binary('CORE',number,symbol)
    family('CORE',30,['ordering-'],['ordering-type'])
    result['NSR-CORE-031']=('binding:Int-store,binding:Bool-store,binding:Bytes-store',
                           'binding:constant-bool-write,binding:constant-text-write','')
    for number,operation in enumerate(('add','subtract','multiply','divide','remainder','power'),32):
        result[f'NSR-CORE-{number:03d}']=(f'binding:Int-compound-{operation}',
                                        'binding:constant-bool-write','')
    family('CORE',38,['propagate-'],['result-outside-context'])
    family('CORE',39,['coalesce-False-','coalesce-True-'],['coalesce-type-mismatch'])
    family('CORE',40,['option-chain-'],['optional-chain-invalid-member'])
    family('CORE',41,['coalesce-store-'],['option-assign-immutable'])
    family('CORE',42,['ratio-25-'],['wrong-domain-25'])
    for number,symbol in enumerate(('…','…<','<…','<…<'),43):
        family('CORE',number,['range-'+symbol.encode().hex()+'-'],['chained-range','ascii-three-dot-range'])
    family('CORE',47,['lateral-effect-','lateral-owned-effect-'],['lateral-mutation'],
           'The linked receiver frame survives native Console and owned Text allocations; body effects occur once before the preserved return.')
    for number,symbol in enumerate(('−','÷','≤','≥','≠'),1):binary('UA',number,symbol)
    for number,symbol in ((6,'∧'),(7,'∨')):
        family('UA',number,['logic-'+symbol.encode().hex()+'-','short-unicode-and' if number==6 else 'short-unicode-or'],['wrong-logic-int'])
    family('UA',8,['unary-c2ac-'],['wrong-unary-c2ac'])
    family('UA',9,['binary-e28abb-','logic-e28abb-','bytes-xor-'],['wrong-e28abb','bytes-xor-mixed'])
    for number,symbol in enumerate(('√','∛','∜'),1):
        family('DOM',number,['root-'+symbol.encode().hex()+'-'],['wrong-unary-'+symbol.encode().hex()],
               'Native checked exact signed Int roots; nonintegral/invalid real roots trap through the arithmetic domain owner.')
    family('DOM',4,['factorial-','domain-factorial'],['wrong-unary-666163746f7269616c'])
    for number,name,symbol in ((5,'infinity','∞'),(6,'pi','π'),(7,'tau','τ')):
        family('DOM',number,['constant-'+name+'-'],['wrong-domain-'+symbol.encode().hex()])
    for number,symbol in ((8,'∑'),(9,'∏')):
        family('DOM',number,['reduce-'+symbol.encode().hex()+'-'],
               ['wrong-domain-'+symbol.encode().hex(),'reduce-overflow-'+symbol.encode().hex()],
               'Finite immutable Array<Int,N> domain; canonical checked constant fold in source order; empty identities 0/1; '
               'constant overflow is rejected with NEBO_TYPE_CONSTANT_OVERFLOW; later publication and explicit return remain in the shared Program.')
    family('DOM',10,['uncertain-value-'],['wrong-domain-c2b1'])
    for number,symbol in ((11,'≈'),(12,'≉'),(13,'≡'),(18,'∝')):
        family('DOM',number,['uncertain-'+symbol.encode().hex()+'-'],['wrong-domain-'+symbol.encode().hex()])
    for number,symbol in ((14,'∣'),(15,'∤')):
        family('DOM',number,['divisibility-'+symbol.encode().hex()+'-'],['wrong-domain-'+symbol.encode().hex()])
    for number,symbol,name in ((16,'⌊','floor'),(17,'⌈','ceil')):
        family('DOM',number,['round-'+symbol.encode().hex()+'-'],['wrong-unary-'+name.encode().hex()])
    family('DOM',19,['angle-'],['wrong-domain-c2b0'])
    for number,symbol in ((20,'‰'),(21,'‱')):
        family('DOM',number,['ratio-'+symbol.encode().hex()+'-'],['wrong-domain-'+symbol.encode().hex()])
    for number,symbol in ((22,'°C'),(23,'°F')):
        family('DOM',number,['temperature-'],['wrong-domain-'+symbol.encode().hex()])
    for number,symbol in enumerate(('∈','∉','∪','∩','∖','△','⊆','⊂','⊇','⊃','×'),24):
        family('DOM',number,[('membership-' if number<26 else 'set-')+symbol.encode().hex()+'-'],
               ['wrong-set-'+symbol.encode().hex()],
               'Current G133 finite immutable Array<Int,N> set profile with distinct values in 0..62; '
               'canonical mask/cardinality owner; independent Python set operations. This does not substitute for the separately proved native Dict/Set APIs.')
    family('DOM',35,['set-empty-context-'],['wrong-set-e288aa'])
    result['NSR-DOM-077']=('interpolation:tooling-format-source,composite:typed-struct-source',
                          'interpolation:tooling-format-invalid,composite:typed-struct-interpolation-effects','')
    result['NSR-DOM-079']=('slash:directive-bold,slash:directive-title,slash:directive-table,slash:directive-task,slash:target-plain-23,slash:target-ansi-7,slash:target-markdown-29,slash:target-html-255,slash:target-console-0,slash:two-live,slash:two-live-other,slash:depth-16,slash:tokens-boundary',
                          'slash:constructor-type,slash:target-unknown,slash:status-type,slash:domain-unknown,slash:domain-depth,slash:domain-tokens',
                          'Actual typed RenderPlan(Text).render(contextual target) consumes all source statements. The existing native Slash parser and two-pass renderer own 64 finite directives, 4096 input bytes, 256 aggregate tokens, depth 16 and 32 argument bytes. Target output is an owned Text projection; its separate Console publication is observed. Unknown directives and overflowing plans fail closed. Independent G064 grammar/render oracle, actual contents, two live plans and explicit returns replace the old template metadata/seed profile.')
    result['NSR-DOM-078']=('format:named-29,format:named-83,format:literal-percent,format:fixed-17.5',
                          'format:wrong-type,format:unknown','')
    from linear_test import cases as linear_cases, negatives as linear_negatives
    from bounded_operator_test import cases as bounded_cases, negatives as bounded_negatives
    bounded_ids=[row[0] for row in bounded_cases()]
    bounded_bad=[row[0] for row in bounded_negatives()]
    linear_ids=[row[0] for row in linear_cases()]
    linear_bad=[row[0] for row in linear_negatives()]
    typed={36:'dot',37:'cross',38:'hadamard',39:'tensor',47:'orthogonal',48:'parallel'}
    profiles={
        'linear':'Exact immutable Int Vector aggregate grammar, extent 1..4; matrix Int/Complex profile at most four logical cells; '
                 'vector observers sum, checked rational inverse numerator/denominator, exact integer norm; symbolic/named parity; '
                 'all source tokens consumed by the canonical current profile, without adjacent statements.',
        'calculus':'Explicit finite samples, dimensions, method, tolerance/step and budget in the current checked calculus grammar; '
                   'exact rational/integer observations; no implicit integration domain, numeric truncation, live solver or hidden callback.',
        'probability':'Explicit bounded model/distribution metadata and finite rational conditional probabilities; '
                      'independence is an explicit model assumption, not an inferred statistical proof.',
        'logic':'Finite domain partition/result grammar, explicit proof/model status and budget; exhaustive Boolean truth tables; '
                'unknown and timeout remain distinct outcomes; this does not claim an automatic theorem prover.',
        'graph':'Bounded typed edge/transition descriptor and deterministic replay projection; explicit endpoints, schema, guard, '
                'effect and capability; no asynchronous external execution.',
        'text':'Current Text/Pattern finite profile: UTF-8 concat and literal/dot Pattern matching with explicit mode/work budget; '
               'matched/negated values change with content, without a fixed operator report.',
        'metadata':'Current annotation registry with typed version/level/enabled arguments, targets and bounded seed/privacy; '
                   'actual argument values and masks are observed; no claim of arbitrary annotation evaluation.'}
    for number in list(range(36,77))+[80]:
        prefix=f'dom-{number:03}-'
        positive=['boundedoperator:'+name for name in bounded_ids if name.startswith(prefix)]
        negative=['boundedoperator:'+name for name in bounded_bad if name.startswith(prefix)]
        profile=('linear' if number<=48 else 'calculus' if number<=57 else 'probability' if number<=60
                 else 'logic' if number<=69 else 'graph' if number<=73 else 'text' if number<=76 else 'metadata')
        reason=profiles[profile]
        if number in typed:
            name=typed[number]
            positive+=['linear:'+case for case in linear_ids if case.startswith(name+'-')]
            negative+=['linear:'+case for case in linear_bad if case.startswith(name+'-')]
            positive+=['linear:operand-effects-once','linear:dict-owned-argument','linear:loop-temporary-reclamation']
            reason+=' Typed infix statement profile additionally supports Int extents 1..64 (cross/parallel exactly 3), tensor result at most 64 lanes; '
            reason+='native checked kernels, distinct owned results, ordered operands and explicit program return.'
        assert positive and negative
        result[f'NSR-DOM-{number:03}']=(','.join(positive),','.join(negative),reason)
    return result
