; Nebo Assembly — MF028 precise Console routing diagnostic mapping
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"
%include "compiler/semantic/console-routing/console_route_diagnostics.inc"

section .rodata
diag_duplicate_binding: db "duplicate-console-binding"
diag_scan_binding: db "scan-binding-required"
diag_invalid_receiver: db "invalid-scan-receiver"
diag_ambiguous_chain: db "ambiguous-console-chain"
diag_invalid_terminal: db "invalid-route-terminal-type"

section .text

; console_route_diagnostic_name(error_code, out_text_ptr*, out_length*)
NEBOC_ABI_FUNCTION neboc_console_route_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp rdi,NEBOC_CONSOLE_ROUTE_ERROR_DUPLICATE_BINDING
 je .duplicate
 cmp rdi,NEBOC_CONSOLE_ROUTE_ERROR_SCAN_BINDING_REQUIRED
 je .scan_binding
 cmp rdi,NEBOC_CONSOLE_ROUTE_ERROR_INVALID_SCAN_RECEIVER
 je .invalid_receiver
 cmp rdi,NEBOC_CONSOLE_ROUTE_ERROR_AMBIGUOUS_CHAIN
 je .ambiguous
 cmp rdi,NEBOC_CONSOLE_ROUTE_ERROR_INVALID_TERMINAL_TYPE
 je .terminal
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.duplicate:
 lea rax,[rel diag_duplicate_binding]
 mov [rsi],rax
 mov qword [rdx],NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_DUPLICATE_BINDING_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.scan_binding:
 lea rax,[rel diag_scan_binding]
 mov [rsi],rax
 mov qword [rdx],NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_SCAN_BINDING_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_receiver:
 lea rax,[rel diag_invalid_receiver]
 mov [rsi],rax
 mov qword [rdx],NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_INVALID_RECEIVER_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.ambiguous:
 lea rax,[rel diag_ambiguous_chain]
 mov [rsi],rax
 mov qword [rdx],NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_AMBIGUOUS_CHAIN_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.terminal:
 lea rax,[rel diag_invalid_terminal]
 mov [rsi],rax
 mov qword [rdx],NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_INVALID_TERMINAL_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
