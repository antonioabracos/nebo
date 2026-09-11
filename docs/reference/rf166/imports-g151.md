# Canonical compile-time imports (G151)

G151 makes three import declarations material in the bounded three-unit
compiler profile. Every full import has an explicit lowercase alias:

```nebo
import "project.users".users;
import { import "project.users".users; import "project.roles".roles; }.identity;
import { import "project.users".users; import "project.roles".roles; };
```

The first form binds one module namespace. A named capsule exposes the unique
public export selected through the capsule name. An anonymous capsule exposes
only its declared entry aliases. All three forms are compile-time declarations:
they allocate no runtime object, execute no initializer, and grant no effect or
capability.

Qualification uses `alias.symbol` (or `capsule.symbol`). `::` remains reserved.
Wildcard, dynamic, and selective imports are rejected in G151; selective
imports and reexports belong to G152.

The compiler accepts at most two entries in one declaration and three source
units in this stable profile. Logical paths contain at most eight lowercase
ASCII segments of at most 32 bytes each. Duplicate aliases or duplicate target
modules are rejected before publishing graph state. Named-capsule lookup also
rejects two imported public exports with the same `SymbolId`.

The public inspection commands reuse the already parsed and analyzed module
snapshot:

```text
neboc imports list root.no --unit core.no --unit util.no
neboc imports explain alias.symbol root.no --unit core.no --unit util.no
```

`list` reports the form, paths, aliases and semantic trace. `explain` adds the
resolution stages `parse>module-graph>alias-bind>export>symbol`. Reports are
deterministic under auxiliary-unit ordering and host-path relocation.
