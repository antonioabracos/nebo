# MF052 native-window scenarios

`mf052_native_window_test.asm` owns three live X11/EWMH scenarios:

1. deterministic Nebo chrome pixels and hit-test priority, then real minimize/restore;
2. real maximize/restore and a controlled 400x240 resize, ignoring stale ConfigureNotify records until exact geometry commits;
3. close hit-test, normalized close request, duplicate rejection, destroy and stale-action rejection.

Pointer, keyboard and text event integration remains deferred to MF053.
