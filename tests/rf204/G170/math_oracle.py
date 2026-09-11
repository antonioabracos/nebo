"""Independent Python arithmetic oracle for the public scalar literal profile.

Binary64 comparisons use abs=rel=1e-12 (oracle version 1). Neither emitted ASM
nor compiler/runtime tables participate in expected-value computation.
"""
import math
import re
import struct
from harness import Failure

OPERATIONS = {'abs': (1, 1), 'clamp': (2, 1), 'min': (3, 1), 'max': (4, 1),
              'sqrt': (5, 2), 'pow': (6, 2), 'hypot': (7, 2),
              'sin': (8, 2), 'cos': (9, 2), 'tan': (10, 2), 'atan2': (11, 2), 'exp': (12, 2), 'log': (13, 2), 'log2': (14, 2)}

def source_oracle(source):
    text = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.S)
    matches = re.findall(r'std\s*\.\s*math\s*\.\s*(\w+)\s*\(([^()]*)\)', text)
    records = []
    for name, arguments in matches:
        if name not in OPERATIONS:
            raise Failure('MATH_ORACLE_OPERATION')
        op, kind = OPERATIONS[name]
        values = [(int if kind == 1 else float)(x.strip()) for x in arguments.split(',')]
        if name == 'abs': result = abs(values[0])
        elif name == 'clamp': result = min(max(values[0], values[1]), values[2])
        elif name == 'min': result = min(values)
        elif name == 'max': result = max(values)
        else: result = getattr(math, name)(*values)
        records.append((op, kind, result))
    if not records:
        raise Failure('MATH_ORACLE_EMPTY')
    return records

def compare_trace(data, expected):
    if len(data) != 32 * len(expected):
        raise Failure('MATH_TRACE_CARDINALITY')
    for i, (op, kind, expected_value) in enumerate(expected):
        magic, actual_op, actual_kind, bits = struct.unpack_from('<8sQQQ', data, i * 32)
        if (magic, actual_op, actual_kind) != (b'NEBOMTH1', op, kind):
            raise Failure('MATH_TRACE_OWNER_OR_TYPE')
        if kind == 1:
            actual = struct.unpack('<q', struct.pack('<Q', bits))[0]
            equal = actual == expected_value
        else:
            actual = struct.unpack('<d', struct.pack('<Q', bits))[0]
            equal = math.isclose(actual, expected_value, rel_tol=1e-12, abs_tol=1e-12)
        if not equal:
            raise Failure(f'MATH_TRACE_VALUE:{i}:{actual!r}!={expected_value!r}')
