# Nebo Runtime Core v0

Pure x86-64 Linux Assembly. Provides Runtime ABI version, process exit, traps,
UTF-8 `TextDescriptor` equality and the first logical headless Console Runtime
boundary.

## MF036 entry bridge

`nebo_runtime_start` receives the address of the lowered Nebo `start()` function
in `RDI`, initializes the process-wide logical `ConsoleRuntimeContext`, calls
`start()` with System V AMD64 stack alignment, and forwards its `EAX` status to
`nebo_runtime_exit`.

MF037 adds deterministic checked-Int overflow and division-by-zero trap
entrypoints with exit statuses 172 and 173.

## MF041 Console contracts

- contract 1 performs default Console logical get-or-create;
- contract 2 creates a new named Console from an immutable UTF-8 descriptor;
- the manager also exposes anonymous logical creation to the future runtime
  lowering path;
- contract 3 remains the complete anonymous scan contract and still traps,
  because `Pending`, input and continuation semantics are outside MF041.

The runtime owns no ConsoleDocument, native window, adapter, command queue or
thread. Those boundaries remain reserved for later fronts.
