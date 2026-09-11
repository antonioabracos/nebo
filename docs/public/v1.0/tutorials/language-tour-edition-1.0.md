# Values, control, functions and typed errors

Edition 1 uses explicit types in receiver signatures, typed values, lexical bindings, mutable state marked .mutable, parenthesized control conditions, and terminal .return. The example imports 7 through a module facade, scans 13, traverses an owned List, wraps the sum in a Result, calls a receiver function and renders the computed 122. (7+13+19)*3+5 is 122.

List and Result lifetimes are local. Do not use a value after moving or releasing its owner. The complete context supplies tour-core.no and tour-facade.no; pass both with --unit when checking or building. Cookbook input uses typed Scan; visual recipes use the retained headless Console. Unknown functions and type mismatches reject before executable publication.

```nebo
// The owned list and result remain local to this function.
module tour;import "project.facade" { token; }.values;
(Int.value)scale(){(value*3+5).return;}
start(){"Count".scan(.int(),.mock("13")).n;List<Int>.from([values.token,n,19]).xs;0.i.mutable;0.total.mutable;while(i<xs.length()){total+=xs.at(i);i+=1;}Result<Int,Int>(Ok(total)).r;r.get().scale().answer;answer.console();answer.return;}
```

Expected context:
```json
{
  "expected_exit": 122,
  "kinds": [
    4
  ],
  "text": {
    "bytes_hex": "313232"
  },
  "units": {
    "tour-core.no": "module core;export public token = 7;\n",
    "tour-facade.no": "module facade;export import \"project.core\" { token; }.source;\n"
  }
}
```
