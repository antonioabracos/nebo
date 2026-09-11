# Consume two explicit package values

The consumer reads token=61 from sample.core and delta=47 from sample.util, yielding 108. The workspace stores exact versions and no capabilities. Offline restore requires the exact lock SHA-256.

The package profile admits Edition 1, x86_64-systemv-elf-linux, up to three source roots/modules and two direct dependencies. Freeze derives material interfaces. A changed source value changes the content identity and executable result; a stale digest must reject before output publication.

Imports: explicit project imports with the two supplied provider units. Required effects/capabilities: none beyond computation and local allocation. No network, live display, external credentials or device capability is used.

```nebo
// The companion workspace supplies two independently pinned packages.
module app;import { import "project.core".left; import "project.util".right; }.values;start values.token + values.delta;
```

Expected context:
```json
{
  "expected_exit": 108,
  "units": {
    "core.no": "module core;export public token = 61;\n",
    "util.no": "module util;export public delta = 47;\n"
  }
}
```
