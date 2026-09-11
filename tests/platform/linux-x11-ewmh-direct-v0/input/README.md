# MF053 native-input scenario

`mf053_native_input_test.asm` owns the single live X11 input contract:

- real FocusOut/FocusIn normalization;
- native pointer move/down/up and input focus selection;
- server-derived keymap with shifted/unshifted text, Backspace and KeyUp;
- Tab and Shift+Tab document-order traversal;
- basic 26.6 HiDPI pointer normalization;
- ENTER through input submission with `BindingId` and compiler `PendingId` preservation.

Clipboard, full IME/composition and MF054 visual evidence remain deferred.
