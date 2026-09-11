# Nebo cookbook

## Check, build and run

<!-- expect-exit: 42 -->
```nebo
generic<T: Copy> (T.value)hold() {
    value.return;
}

start() {
    42.hold();
}
```

```bash
build/bin/neboc check example.no
build/bin/neboc build example.no -o example
./example
```

## Reproducibility

Run `emit-asm` twice under `LC_ALL=C`, `LANG=C`, `TZ=UTC` and compare the
results byte for byte. For repository-wide checks, use `ninja -j1 test`. Use
the local release dry-run only with a fresh caller-owned path in the build directory; it
does not create a release, tag or publication.

```bash
build/bin/neboc release prepare 1.1.0
build/bin/neboc release materialize 1.1.0 --dry-run -o build/local-candidate
build/bin/neboc release restore-test build/local-candidate
```

Use a fresh output directory. `release publish` is deliberately denied; a
successful dry-run is evidence about repeatability, not publication authority.
