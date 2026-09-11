# Two live views and an independent oracle

Every published native reference example is enumerated with its full source, provider units, input files, process result and value/effect oracle. Repeated identical contexts execute once and all page occurrences join to that proof.

The two Lists below retain separate values, observed as 31 then 41. Tests also change inputs, add statements, return early, and feed a wrong expected output to the runner. Stable source examples are always executed; excluded internal records and Python reference models are explicitly labelled and are not silently treated as native examples.

```nebo
// Neither view overwrites the other view's retained value.
start(){List<Int>.from([23,31]).a;List<Int>.from([41,53]).b;a.at(1).console();b.at(0).console();61.return;}
```

Expected context:
```json
{
  "expected_exit": 61,
  "kinds": [
    4,
    4
  ],
  "text": {
    "bytes_hex": "33313431"
  }
}
```
