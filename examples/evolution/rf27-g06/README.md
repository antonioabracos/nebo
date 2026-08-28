# RF27-G06 bounded composite and generic examples

These examples form the public closeout surface for the bounded RF27-G06 profile:

- deterministic named-struct layout and access;
- checked stepped `Range` construction;
- lexical borrowed `Slice` views over bounded arrays;
- AOT generic monomorphization with explicit constraints;
- nominal enums with exhaustive payload matching.

Reflection and unbounded specialization remain outside this profile.
