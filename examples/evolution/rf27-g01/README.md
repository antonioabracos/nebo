# RF27-G01 bounded Bytes and bits

`bounded-bytes-bits.no` exercises the public bounded native profile without a
general Buffer, public Slice or dynamic index/count. It constructs four static
bytes, observes their length, takes an immutable bounded slice, reads its first
byte and applies 64-bit AND plus arithmetic right shift. The native exit status
is `17`.
