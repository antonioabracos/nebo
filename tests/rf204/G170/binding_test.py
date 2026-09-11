#!/usr/bin/env python3
"""Atomic public bindings: compare live slots/stores with source value oracles."""
import json
import tempfile
from pathlib import Path
from harness import Failure, pipeline, reject


def cases():
    result = []
    for kind, values in (
        ('Int', (37, 71)), ('Float', (3.75, 7.25)), ('Bool', (False, True)),
        ('Char', ('Q', 'Ω')), ('Text', ('Nebo', 'ação')),
        ('Bytes', ((17, 29, 71, 83), (0, 255, 53, 11))),
    ):
        for ordinal, value in enumerate(values):
            if kind == 'Bytes':
                expression = 'Bytes.fromValues(' + ','.join(map(str, value)) + ')'
                observer = 'value.at(2).console();value.byteLength().console();'
                options = dict(kinds=[4, 4], text=(str(value[2]) + '4').encode())
            elif kind in ('Text', 'Char'):
                expression = json.dumps(value, ensure_ascii=False) if kind == 'Text' else repr(value)
                if kind == 'Text':
                    observer = 'value.byteLength().console();value.codepointCount().console();'
                    options = dict(kinds=[4, 4], text=(str(len(value.encode())) + str(len(value))).encode())
                else:
                    observer = 'value.codepoint().console();'
                    options = dict(kinds=[4], text=str(ord(value)).encode())
            elif kind == 'Float':
                expression = repr(value)
                observer = f'flow.assert(value=={value});'
                options = {}
            elif kind == 'Bool':
                expression = str(value).lower()
                observer = 'value.console();'
                options = dict(kinds=[5], text=expression.encode())
            else:
                expression = str(value)
                observer = 'value.console();'
                options = dict(kinds=[4], text=str(value).encode())
            for typed in (False, True):
                declaration = kind + '.value;' if typed else ''
                result.append((f'{kind}-{ordinal}-' + ('typed' if typed else 'implicit'),
                               'start(){' + declaration + expression + '.value;' + observer + '23.return;}', 23, options))
            result.append((f'{kind}-{ordinal}-constant',
                           'start(){' + expression + '.VALUE;' + observer.replace('value', 'VALUE') + '29.return;}', 29, options))
            if kind == 'Float':
                result.append((f'Float-{ordinal}-wrong-assertion',
                               f'start(){{{expression}.value;flow.assert(value=={value+1});23.return;}}', 175, {}))
    for kind, initial, replacement, observation, expected in (
        ('Int', '17', '71', 'value', 71),
        ('Bool', 'true', 'false', 'value', 0),
        ('Char', "'Q'", "'Z'", 'value.codepoint()', 90),
        ('Text', '"Nebo"', '"language"', 'value.byteLength()', 8),
        ('Bytes', 'Bytes.fromByte(17)', 'Bytes.fromByte(71)', 'value.at(0)', 71),
    ):
        result.append((kind + '-store', f'start(){{{initial}.value.mutable;value={replacement};{observation}.return;}}', expected, {}))
    result.append(('Float-store', 'start(){3.75.value.mutable;value=7.25;flow.assert(value==7.25);23.return;}', 23, {}))
    for operation, right, expected in (('+=', 11, 28), ('-=', 3, 14), ('*=', 7, 119), ('/=', 3, 5), ('%=', 7, 3), ('^=', 2, 289)):
        result.append(('Int-compound-' + {'+':'add','-':'subtract','*':'multiply','/':'divide','%':'remainder','^':'power'}[operation[0]], f'start(){{17.value.mutable;value{operation}{right};value.console();23.return;}}', 23,
                       dict(kinds=[4], text=str(expected).encode())))
    for index, expected in ((0, 17), (1, 29), (2, 71), (3, 83), (-1, 172), (4, 172)):
        result.append(('Bytes-index-' + str(index), f'start(){{Bytes.fromValues(17,29,71,83).data;({index}).index.mutable;data.at(index).return;}}', expected, {}))
    # The shipped Bytes API widens an unsigned byte to Int on read. It does
    # not publish a separate Byte(...) constructor or implicit narrowing.
    for value in (0, 7, 128, 255):
        for typed in (False, True):
            declaration = 'Int.octet;' if typed else ''
            result.append((f'byte-value-{value}-' + ('typed' if typed else 'implicit'),
                           f'start(){{Bytes.fromByte({value}).data;{declaration}data.at(0).octet;octet.console();23.return;}}',
                           23, dict(kinds=[4], text=str(value).encode())))
    result += [
        ('Bytes-index-store', 'start(){Bytes.fromValues(17,29,71,83).data;1.index.mutable;index+=1;data.at(index).return;}', 71, {}),
        ('Text-two-live', 'start(){"Nebo".one;"language".two;one.byteLength().console();two.byteLength().return;}', 8, dict(kinds=[4], text=b'4')),
        ('Text-function-local', '(Int.self)size(){"Nebo".text;text.byteLength().return;}start(){1.size().return;}', 4, {}),
        ('ordinary-visible-shadow', 'start(){"Nebo".value;if(true){"other".value;value.byteLength().console();}value.byteLength().return;}', 4, dict(kinds=[4],text=b'5')),
        ('ordinary-mutable-shadow', 'start(){17.value.mutable;if(true){29.value.mutable;value=71;value.console();}value.console();23.return;}', 23, dict(kinds=[4,4],text=b'7117')),
        ('shadow-initializer-reads-outer', 'start(){17.value;if(true){(value+7).value;value.console();}value.return;}', 17, dict(kinds=[4],text=b'24')),
        ('same-name-sibling-and-outer', 'start(){17.value;if(true){29.value;value.console();}if(true){71.value;value.console();}value.return;}', 17, dict(kinds=[4,4],text=b'2971')),
        ('sibling-scopes', 'start(){if(true){17.value;value.console();}if(true){29.value;value.console();}23.return;}', 23, dict(kinds=[4, 4], text=b'1729')),
        ('Int-add-overflow', 'start(){9223372036854775807.value.mutable;value+=1;value.return;}', 172, {}),
        ('Int-divide-zero', 'start(){17.value.mutable;0.divisor;value/=divisor;value.return;}', 173, {}),
        ('constant-runtime-once', 'start(){"Nebo".value.mutable;value.byteLength().LENGTH;value="language";LENGTH.console();value.byteLength().console();LENGTH.return;}', 4, dict(kinds=[4, 4], text=b'48')),
    ]
    return result


def negatives():
    return [
        ('char-codepoint-arity', "start(){'Q'.value;value.codepoint(1).return;}", 'NEBO_TYPE_MISMATCH'),
        ('text-length-arity', 'start(){"Nebo".value;value.byteLength(1).return;}', 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-ARGUMENTS-NOT-ALLOWED'),
        ('text-count-arity', 'start(){"Nebo".value;value.codepointCount(1).return;}', 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-ARGUMENTS-NOT-ALLOWED'),
        ('bytes-at-type', 'start(){Bytes.fromByte(17).value;value.at(true).return;}', 'NEBO_TYPE_MISMATCH'),
        ('bytes-at-arity', 'start(){Bytes.fromByte(17).value;value.at(0,1).return;}', 'NEBO_TYPE_MISMATCH'),
        ('bytes-length-arity', 'start(){Bytes.fromByte(17).value;value.byteLength(1).return;}', 'NEBO_TYPE_MISMATCH'),
        ('constant-bool-mutable', 'start(){true.VALUE.mutable;VALUE.return;}', 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('constant-char-mutable', "start(){'Q'.VALUE.mutable;VALUE.codepoint().return;}", 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('constant-text-mutable', 'start(){"Nebo".VALUE.mutable;VALUE.byteLength().return;}', 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('constant-bytes-mutable', 'start(){Bytes.fromByte(17).VALUE.mutable;VALUE.at(0).return;}', 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('constant-bool-write', 'start(){true.VALUE;VALUE=false;VALUE.return;}', 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('constant-text-write', 'start(){"Nebo".VALUE;VALUE="language";VALUE.byteLength().return;}', 'NEBO_CONST_WRITE_FORBIDDEN'),
        ('char-store-type', "start(){'Q'.value.mutable;value=17;value.codepoint().return;}", 'NEBO_TYPE_MISMATCH'),
        ('text-store-type', 'start(){"Nebo".value.mutable;value=17;value.byteLength().return;}', 'NEBO_TYPE_MISMATCH'),
        ('constant-visible-shadow', 'start(){"Nebo".VALUE;if(true){"other".VALUE;VALUE.byteLength().console();}VALUE.byteLength().return;}', 'NEBO_NAME_DUPLICATE'),
    ]


def run():
    results = []
    with tempfile.TemporaryDirectory(prefix='nebo-G170-bindings-', dir='/tmp') as directory:
        for negative, rows in ((False, cases()), (True, negatives())):
            for case in rows:
                name, body, expected, *arguments = case
                work = Path(directory) / name
                work.mkdir()
                source = work / 'source.no'
                source.write_text(body)
                result = dict(id=name, category='negative' if negative else 'positive', result='FAIL')
                try:
                    proof = reject(source, work, expected) if negative else pipeline(source, work, expected, **arguments[0])
                    result.update(proof)
                    result['result'] = 'PASS'
                except Failure as error:
                    result['failure'] = str(error).replace(directory, '<scratch>')
                results.append(result)
    return dict(cases=results, passed=sum(r['result'] == 'PASS' for r in results), total=len(results))


if __name__ == '__main__':
    print(json.dumps(run(), sort_keys=True))
