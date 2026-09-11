# MF055 — Multi-Console scan independence

`mf055_multi_console_test.asm` contains the seven native scenarios required by MF055. `mf055_visual_support.asm` is test-only and makes retained document/editor state readable in the committed visual evidence; it does not select a production font.

CLI:

```txt
build/tests/mf055/multi_console_test <scenario 1..7> <x11-socket> <cookie-hex> <out-a.ppm> [out-b.ppm]
```

Scenario mapping:

1. named `musica` / `programacao`;
2. two anonymous chains;
3. one default scan;
4. multiple default scans;
5. resolve second before first;
6. close one window, survivor continues;
7. two Consoles progress interleaved without blocking.
