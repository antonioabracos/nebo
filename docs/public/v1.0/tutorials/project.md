# Three units with a re-exported value

This application is derived from the RF172 typed multiunit scenario. A core module exports token=29, a facade re-exports it, and the consumer calculates 29*3+7=94. Three separate source units are required.

Change the core value to 41 and the result must become 130. Emit a current .ni interface for the core and remove its source: the consumer must still produce the same result. The package project demonstrates two exact dependency pins, offline freeze/verify/build and deterministic relocation.

```nebo
// Qualified module values flow into the typed application.
module app;import "project.facade" { token; }.values;start(){(values.token*3+7).return;}
```

Expected context:
```json
{
  "expected_exit": 94,
  "units": {
    "core.no": "module core;export public token = 29;\n",
    "facade.no": "module facade;export import \"project.core\" { token; }.source;\n"
  }
}
```
neboc module-check main.no --unit core.no --unit facade.no
neboc link main.no --unit core.no --unit facade.no -o app
./app
# Expected process status: 94. Provider sources are in the context above.
neboc emit-interface core.no --unit interface-query.no --unit facade.no -o core.ni
neboc link main.no --unit core.ni --unit facade.no -o app-ni
./app-ni
# Expected status: 94. interface-query.no is distributed with this project.
