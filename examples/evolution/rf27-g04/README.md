# RF27-G04 bounded ownership and cleanup

These examples exercise explicit copy/move state, a lexical unique borrow with
release, and reverse exactly-once cleanup before a non-local return. The arena,
OOM, leak and adversarial safety proofs live under `tests/rf27-g04/f05` and
`tests/rf27-g04/f06`.

Raw references, a general borrow checker, mandatory GC and panic unwinding are
outside this bounded profile.
