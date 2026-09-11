# MF009 StringPool tests

`mf009_string_pool_test.asm` proves the complete primary contract:

- identical insertion order in pools at different addresses yields identical IDs;
- IDs use typed tag + ordinal and never pointer bits;
- duplicate interning reuses the existing ID;
- the known FNV-1a 32-bit collision `ctgfhnxe` / `ybzaqr9e` produces two distinct IDs;
- collision equality falls through to full byte comparison;
- ASCII identifier policy rejects a non-ASCII spelling;
- pointer values are rejected when presented as IDs.
