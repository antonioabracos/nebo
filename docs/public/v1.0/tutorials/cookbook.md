# Input, text and independent collections

A typed scripted Scan result is stored in one Dict. A second Dict uses the same key with a different value, demonstrating independent instances. The retained Console document contains 43 followed by 61; process status is 47.

Mock input makes this recipe reproducible without keyboard or network. For real input, follow the current Scan reference and cancellation/privacy rules. Imports only grant visibility. The executor must separately authorize filesystem, network or device effects.

```nebo
// Input is scripted; dictionaries have independent state.
start(){"Count".scan(.int(),.mock("43")).n;Dict<Int,Int>.new().a;Dict<Int,Int>.new().b;a.insert(7,n);b.insert(7,61);a.get(7).expect("a").console();b.get(7).expect("b").console();47.return;}
```

Expected context:
```json
{
  "expected_exit": 47,
  "kinds": [
    4,
    4
  ],
  "text": {
    "bytes_hex": "34333631"
  }
}
```
