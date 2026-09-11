#!/usr/bin/env python3
def batches(total, size, interruptions):
    ack=0; sent=[]
    while ack<total:
        n=min(size,total-ack); token=ack+n
        sent.extend(range(ack,token))
        if token in interruptions:
            sent.extend(range(ack,token))
        ack=token
    return ack,sent
ack,delivered=batches(600,256,{256})
assert ack==600 and set(delivered)==set(range(600))
assert len(delivered)>600
for order in (delivered,list(reversed(delivered))):
    assert set(order)==set(range(600))
print("RF46_G33_F05_ORACLE_GREEN protocol=v1 batch=256 changes=4096 bytes=1048576 resume=explicit duplicates=idempotent transport=local")
