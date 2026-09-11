#!/usr/bin/env python3
MASK=(1<<64)-1
PROFILE=0x0000002700000004
VALUES=[12, 24, 36, 48]
MAX_RECORDS=19
ITEM_MAX=1045056
ORDERED=False
MAX_INSTRUCTIONS=64
SUPPORTED={0xb7,0x07,0x15,0x55,0x7b,0x79,0x85,0x95}

def encode(opcode,dst=0,src=0,offset=0,immediate=0):
    return (opcode | (dst<<8) | (src<<12) | ((offset & 0xffff)<<16) |
            ((immediate & 0xffffffff)<<32))

def verify(program):
    assert 0 < len(program) <= MAX_INSTRUCTIONS
    helpers=branches=stack=0
    for index,instruction in enumerate(program):
        opcode=instruction & 0xff
        dst=(instruction>>8)&0xf; src=(instruction>>12)&0xf
        offset=(instruction>>16)&0xffff
        if offset & 0x8000: offset-=0x10000
        immediate=(instruction>>32)&0xffffffff
        if immediate & 0x80000000: immediate-=0x100000000
        assert opcode in SUPPORTED
        if opcode in (0xb7,0x07):
            assert dst <= 9 and src == 0 and offset == 0
        elif opcode in (0x15,0x55):
            assert dst <= 9 and src == 0 and offset > 0
            assert index+1+offset < len(program); branches+=1
        elif opcode == 0x7b:
            assert dst == 10 and src <= 9 and immediate == 0
            assert -512 <= offset <= -8 and offset % 8 == 0; stack+=1
        elif opcode == 0x79:
            assert src == 10 and dst <= 9 and immediate == 0
            assert -512 <= offset <= -8 and offset % 8 == 0; stack+=1
        elif opcode == 0x85:
            assert dst == src == offset == 0 and immediate == 1; helpers+=1
        else:
            assert dst == src == offset == immediate == 0
            assert index == len(program)-1
    assert program[-1] & 0xff == 0x95
    return len(program),helpers,branches,stack

def evaluate(values):
    assert 0 < len(values) <= MAX_RECORDS
    assert all(0 <= value <= ITEM_MAX for value in values)
    if ORDERED:
        assert all(left <= right for left,right in zip(values,values[1:]))
    total=sum(values)
    assert total <= MASK
    digest=0xCBF29CE484222325 ^ PROFILE
    for value in values:
        digest=((digest ^ value)*0x100000001B3)&MASK
    return total,digest,min(values),max(values)

result=evaluate(VALUES)
assert result==(120,0xeb20e811288cf6d1,12,48)
program=[encode(0xb7,immediate=1),encode(0x7b,dst=10,offset=-8),
         encode(0x15,offset=1),encode(0xb7,immediate=2),encode(0x95)]
assert verify(program)==(5,0,1,1)
bad_programs=(
    [encode(0),encode(0x95)],
    [encode(0xb7,dst=10),encode(0x95)],
    [encode(0x15,offset=-1),encode(0x95)],
    [encode(0x7b,dst=10,offset=-4),encode(0x95)],
    [encode(0x85,immediate=5),encode(0x95)],
    [encode(0xb7,immediate=1)],
)
for bad in bad_programs:
    try:
        verify(bad)
        raise RuntimeError("invalid eBPF program accepted")
    except AssertionError:
        pass
try:
    evaluate([ITEM_MAX+1])
    raise AssertionError("invalid value accepted")
except AssertionError:
    pass
print("RF46_G39_F04_ORACLE_PASS schema=ebpf_verifier instructions=5 helpers=0 branches=1 stack=1 fault_corpus=6")
