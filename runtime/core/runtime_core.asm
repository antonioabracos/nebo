; Nebo Runtime Core v0 — no libc, MF049 lifecycle/cancellation/reclaim runtime
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/core/runtime_core.inc"
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"
%include "runtime/scalars/option_result_runtime.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/console/renderer-registry/renderer_registry.inc"
%include "runtime/console/renderers/basic/basic_renderer.inc"
%include "runtime/console/render/output_conformance.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"
%include "runtime/console/lifecycle/console_lifecycle.inc"
%ifdef NEBO_RUNTIME_PRACTICAL_IO
%include "runtime/textual/scan_plan.inc"
%include "runtime/console/document/linear_console_document.inc"
%include "runtime/console/live/live_console.inc"
extern nebo_runtime_live_set_presentation
extern nebo_console_color_bgra
extern nebo_runtime_live_finalize
extern nebo_runtime_live_scan_roundtrip
extern nebo_runtime_live_available
extern nebo_runtime_live_input_security
extern nebo_runtime_live_input_wipe
%endif

global nebo_runtime_abi_version
global nebo_runtime_start
global nebo_runtime_exit
global nebo_runtime_trap
global nebo_runtime_trap_overflow
global nebo_runtime_trap_division_by_zero
global nebo_runtime_trap_arithmetic_domain
global nebo_runtime_trap_stack_budget
global nebo_runtime_owned_stack_floor
global nebo_runtime_quantity_percent
global nebo_runtime_quantity_per_mille
global nebo_runtime_quantity_angle
global nebo_runtime_quantity_celsius
global nebo_runtime_quantity_fahrenheit
global nebo_runtime_math_square_root_exact
global nebo_runtime_math_cube_root_exact
global nebo_runtime_math_fourth_root_exact
global nebo_runtime_math_factorial_checked
global nebo_runtime_math_infinity
global nebo_runtime_math_pi
global nebo_runtime_math_tau
global nebo_runtime_math_floor
global nebo_runtime_math_ceil
global nebo_runtime_uncertain_create
global nebo_runtime_measurement_create
global nebo_runtime_uncertain_approx_equal
global nebo_runtime_uncertain_not_approx_equal
global nebo_runtime_uncertain_equivalent
global nebo_runtime_int_divides
global nebo_runtime_int_not_divides
global nebo_runtime_uncertain_proportional
global nebo_runtime_uncertain_add_worst_case
global nebo_runtime_uncertain_add_independent
global nebo_runtime_uncertain_add_correlated
global nebo_runtime_uncertain_add_interval
global nebo_runtime_uncertain_value
global nebo_runtime_uncertain_uncertainty
global nebo_runtime_uncertain_unit
global nebo_runtime_uncertain_quality
global nebo_runtime_uncertain_confidence
global nebo_runtime_uncertain_separator_codepoint
global nebo_runtime_checked_divide
global nebo_runtime_checked_remainder
global nebo_runtime_checked_power
global nebo_runtime_checked_float_power_int
global nebo_runtime_bytes_xor
global nebo_runtime_text_equal
global nebo_runtime_numeric_safety_is_negative_zero
global nebo_runtime_numeric_safety_is_infinite
global nebo_runtime_numeric_safety_is_nan
global nebo_runtime_numeric_safety_is_finite
global nebo_runtime_numeric_safety_int_to_float
global nebo_runtime_textual_text_byte_length
global nebo_runtime_textual_text_contract
global nebo_runtime_textual_text_codepoint_count
global nebo_runtime_textual_char_codepoint
global nebo_runtime_textual_bytes_empty
global nebo_runtime_textual_bytes_byte_length
global nebo_runtime_textual_bytes_at
global nebo_runtime_textual_bytes_construct
global nebo_runtime_textual_empty_bytes_descriptor
global neboc_runtime_store_zero_payload
global neboc_runtime_store_integer
global neboc_runtime_store_float
global neboc_runtime_load_tag
global neboc_runtime_load_integer
global neboc_runtime_load_float
global neboc_runtime_tag_test
global neboc_runtime_unwrap_integer
global neboc_runtime_unwrap_float
global neboc_runtime_validate_option
global neboc_runtime_validate_result
global neboc_runtime_roundtrip_integer_aggregate
global neboc_runtime_roundtrip_sse_aggregate
global nebo_runtime_console_ensure_initialized
global nebo_runtime_console_context
global nebo_runtime_console_publish_text
global nebo_runtime_console_publish_int
global nebo_runtime_console_publish_bool
global nebo_runtime_input_ensure_initialized
global nebo_runtime_contract_1
global nebo_runtime_contract_2
global nebo_runtime_contract_3
%ifdef NEBO_RUNTIME_PRACTICAL_IO
global nebo_runtime_scan_stdin_text
global nebo_runtime_scan_console_handle
%endif

section .rodata align=8
nebo_runtime_abi_version: dq NEBO_RUNTIME_ABI_VERSION_V0
align 8
nebo_runtime_textual_empty_bytes_data: db 0
align 8
nebo_runtime_textual_empty_bytes_descriptor:
 dq nebo_runtime_textual_empty_bytes_data
 dq 0
 dd NEBO_RUNTIME_BYTES_FLAGS_EMPTY
 dw NEBO_RUNTIME_BYTES_ELEMENT_WIDTH
 dw NEBO_RUNTIME_LIFETIME_STATIC
align 8
nebo_runtime_float_one: dq 0x3ff0000000000000

section .bss align=64
section .bss.runtime_base nobits alloc noexec write align=16
nebo_runtime_owned_stack_floor: resq 1
global nebo_runtime_network_cleanup_hook
nebo_runtime_network_cleanup_hook: resq 1
nebo_runtime_console_finalize_hook: resq 1
section .bss.runtime_console nobits alloc noexec write align=64
nebo_runtime_console_context: resb NEBO_CONSOLE_CONTEXT_SIZE
nebo_runtime_console_slots: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_SLOT_SIZE
nebo_runtime_fake_clock: resb NEBO_FAKE_CLOCK_SIZE
nebo_runtime_fake_platform: resb NEBO_FAKE_PLATFORM_SIZE
nebo_runtime_console_scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
nebo_runtime_console_domains: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DOMAIN_SIZE
nebo_runtime_console_command_buffers: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
nebo_runtime_console_event_buffers: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
nebo_runtime_console_documents: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DOCUMENT_SIZE
nebo_runtime_console_document_nodes: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
nebo_runtime_console_document_text: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
nebo_runtime_headless_storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
nebo_runtime_input_runtime: resb NEBO_INPUT_RUNTIME_SIZE
nebo_runtime_input_storage: resb NEBO_INPUT_RUNTIME_STORAGE_SIZE
nebo_runtime_input_registries: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_REGISTRY_SIZE
nebo_runtime_input_records: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_DEFAULT_CAPACITY*NEBO_INPUT_RECORD_SIZE
nebo_runtime_pending_registries: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_PENDING_REGISTRY_SIZE
nebo_runtime_pending_records: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_DEFAULT_CAPACITY*NEBO_PENDING_RECORD_SIZE
%ifdef NEBO_RUNTIME_PRACTICAL_IO
global nebo_runtime_process_stack
section .bss.runtime_base nobits alloc noexec write align=16
nebo_runtime_process_stack: resq 1
section .bss.runtime_console nobits alloc noexec write align=64
nebo_runtime_publication_count: resq 1
nebo_runtime_last_console_handle: resq 1
nebo_runtime_scan_result_count: resq 1
nebo_runtime_scan_descriptors: resb NEBO_RUNTIME_SCAN_RESULT_CAPACITY*NEBO_RUNTIME_TEXT_DESCRIPTOR_SIZE
nebo_runtime_scan_values: resb NEBO_RUNTIME_SCAN_RESULT_CAPACITY*SCAN_MAX_INPUT_BYTES
nebo_runtime_stdin_buffer: resb SCAN_MAX_INPUT_BYTES
nebo_runtime_trace_buffer: resb 32+8*NEBO_CONSOLE_DEFAULT_NODE_CAPACITY+NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
%endif

section .text
; Runtime entry bridge. RDI = pointer to the lowered Nebo start() function.
; The process entry stack is 16-byte aligned before _start calls this function.
; At function entry RSP is therefore 8 mod 16; push RBP restores call alignment.
section .text.runtime_entry progbits alloc exec nowrite align=16
nebo_runtime_start:
 test rdi,rdi
 jz .invalid_entry
 push rbp
 mov rbp,rsp
 sub rsp,32
 mov [rsp],rdi
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov [rel nebo_runtime_process_stack],rsi
%endif
 ; Read the existing process limit; never change an OS resource limit.
 ; The untouched half accommodates arguments, environment and non-owned
 ; frames. The additional reserve covers our bounded native helper calls.
 mov eax,97 ; Linux x86-64 getrlimit
 mov edi,3 ; RLIMIT_STACK
 lea rsi,[rsp+16]
 syscall
 test rax,rax
 jnz nebo_runtime_trap_stack_budget
 mov rax,[rsp+16]
 shr rax,1
 mov edx,NEBO_RUNTIME_OWNED_STACK_CAP
 cmp rax,rdx
 cmova rax,rdx
 sub rax,NEBO_RUNTIME_NATIVE_STACK_RESERVE
 jbe nebo_runtime_trap_stack_budget
 mov rdx,rsp
 sub rdx,rax
 jc nebo_runtime_trap_stack_budget
 mov [rel nebo_runtime_owned_stack_floor],rdx
 mov rdi,[rsp]
 call rdi
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov [rsp+8],rax
 mov r11,[rel nebo_runtime_console_finalize_hook]
 test r11,r11
 jz .practical_done
 call r11
 test eax,eax
 jnz .console_init_failed
.practical_done:
 mov rax,[rsp+8]
%endif
 mov edi,eax
 add rsp,32
 pop rbp
 jmp nebo_runtime_exit
.console_init_failed:
 add rsp,32
 pop rbp
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
.invalid_entry:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_ENTRY
 jmp nebo_runtime_trap

section .text.runtime_exit progbits alloc exec nowrite align=16
nebo_runtime_exit:
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov r12d,edi
 and rsp,-16
 mov r11,[rel nebo_runtime_network_cleanup_hook]
 test r11,r11
 jz .no_network_cleanup
 call r11
.no_network_cleanup:
 mov edi,r12d
%endif
 mov eax,60
 syscall
 ud2

; G130 typed-mathematics runtime.  Exact integer roots and factorial trap on
; domain/overflow instead of silently approximating or wrapping.
section .text.runtime_math progbits alloc exec nowrite align=16
nebo_runtime_math_square_root_exact:
 xor r11d,r11d
 test rdi,rdi
 js nebo_runtime_trap_arithmetic_domain
 mov esi,2
 jmp nebo_runtime_math_root_exact
nebo_runtime_math_cube_root_exact:
 xor r11d,r11d
 test rdi,rdi
 jns .cube_root_nonnegative
 neg rdi
 mov r11d,1
.cube_root_nonnegative:
 mov esi,3
 jmp nebo_runtime_math_root_exact
nebo_runtime_math_fourth_root_exact:
 xor r11d,r11d
 test rdi,rdi
 js nebo_runtime_trap_arithmetic_domain
 mov esi,4
nebo_runtime_math_root_exact:
 cmp esi,2
 je .root_square
 cmp esi,3
 je .root_cube
 mov r9,0x10001
 jmp .root_search_init
.root_square:
 mov r9,0x100000001
 jmp .root_search_init
.root_cube:
 mov r9,0x300000
.root_search_init:
 xor r8d,r8d
.root_search:
 cmp r8,r9
 jae nebo_runtime_trap_arithmetic_domain
 lea r10,[r8+r9]
 shr r10,1
 mov eax,1
 mov ecx,esi
.root_power:
 mul r10
 test rdx,rdx
 jnz .root_too_large
 loop .root_power
 cmp rax,rdi
 je .root_found
 ja .root_too_large
 lea r8,[r10+1]
 jmp .root_search
.root_too_large:
 mov r9,r10
 jmp .root_search
.root_found:
 mov rax,r10
 test r11d,r11d
 jz .root_return
 neg rax
.root_return:
 ret

nebo_runtime_math_factorial_checked:
 test rdi,rdi
 js nebo_runtime_trap_arithmetic_domain
 cmp rdi,20
 ja nebo_runtime_trap_overflow
 mov eax,1
 mov ecx,2
.factorial_loop:
 cmp rcx,rdi
 ja .factorial_done
 mul rcx
 test rdx,rdx
 jnz nebo_runtime_trap_overflow
 inc rcx
 jmp .factorial_loop
.factorial_done:
 ret

nebo_runtime_math_infinity:
 mov rax,0x7ff0000000000000
 movq xmm0,rax
 ret
nebo_runtime_math_pi:
 mov rax,0x400921fb54442d18
 movq xmm0,rax
 ret
nebo_runtime_math_tau:
 mov rax,0x401921fb54442d18
 movq xmm0,rax
 ret

; RDI carries an IEEE-754 binary64 bit pattern; RAX returns an Int.  NaN,
; infinity and values outside the signed 64-bit result domain trap.
nebo_runtime_math_floor:
 mov rax,rdi
 mov rcx,rax
 mov rdx,0x7ff0000000000000
 and rcx,rdx
 cmp rcx,rdx
 je nebo_runtime_trap_arithmetic_domain
 movq xmm0,rdi
 cvttsd2si rax,xmm0
 mov rcx,0x8000000000000000
 cmp rax,rcx
 jne .floor_converted
 mov rdx,0xc3e0000000000000
 cmp rdi,rdx
 jne nebo_runtime_trap_arithmetic_domain
.floor_converted:
 cvtsi2sd xmm1,rax
 ucomisd xmm1,xmm0
 jbe .floor_done
 dec rax
.floor_done:
 ret

nebo_runtime_math_ceil:
 mov rax,rdi
 mov rcx,rax
 mov rdx,0x7ff0000000000000
 and rcx,rdx
 cmp rcx,rdx
 je nebo_runtime_trap_arithmetic_domain
 movq xmm0,rdi
 cvttsd2si rax,xmm0
 mov rcx,0x8000000000000000
 cmp rax,rcx
 jne .ceil_converted
 mov rdx,0xc3e0000000000000
 cmp rdi,rdx
 jne nebo_runtime_trap_arithmetic_domain
.ceil_converted:
 cvtsi2sd xmm1,rax
 ucomisd xmm1,xmm0
 jae .ceil_done
 inc rax
.ceil_done:
 ret

section .text.runtime_traps progbits alloc exec nowrite align=16
nebo_runtime_trap:
 add edi,128
 jmp nebo_runtime_exit

nebo_runtime_trap_overflow:
 mov edi,NEBO_RUNTIME_TRAP_INT_OVERFLOW
 jmp nebo_runtime_trap

nebo_runtime_trap_division_by_zero:
 mov edi,NEBO_RUNTIME_TRAP_DIVISION_BY_ZERO
 jmp nebo_runtime_trap

nebo_runtime_trap_arithmetic_domain:
 mov edi,NEBO_RUNTIME_TRAP_ARITHMETIC_DOMAIN
 jmp nebo_runtime_trap

nebo_runtime_trap_stack_budget:
 mov edi,NEBO_RUNTIME_TRAP_STACK_BUDGET
 jmp nebo_runtime_trap

section .text.runtime_scalar progbits alloc exec nowrite align=16

; G131 uncertainty carriers.  Construction checks every field before packing,
; so invalid input can never publish a partially initialized measurement.
; RDI=value, RSI=uncertainty, RDX=unit, RCX=quality, R8=confidence.
nebo_runtime_measurement_create:
 cmp rdi,NEBO_RUNTIME_MEASUREMENT_VALUE_MIN
 jl nebo_runtime_trap_overflow
 cmp rdi,NEBO_RUNTIME_MEASUREMENT_VALUE_MAX
 jg nebo_runtime_trap_overflow
 test rsi,rsi
 js nebo_runtime_trap_arithmetic_domain
 cmp rsi,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_MAX
 ja nebo_runtime_trap_overflow
 test rdx,rdx
 js nebo_runtime_trap_arithmetic_domain
 cmp rdx,NEBO_RUNTIME_MEASUREMENT_UNIT_MAX
 ja nebo_runtime_trap_arithmetic_domain
 test rcx,rcx
 js nebo_runtime_trap_arithmetic_domain
 cmp rcx,NEBO_RUNTIME_MEASUREMENT_PERCENT_MAX
 ja nebo_runtime_trap_arithmetic_domain
 test r8,r8
 js nebo_runtime_trap_arithmetic_domain
 cmp r8,NEBO_RUNTIME_MEASUREMENT_PERCENT_MAX
 ja nebo_runtime_trap_arithmetic_domain
 mov rax,rdi
 and rax,0x0fffffff
 shl rax,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 mov r9,rsi
 shl r9,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 or rax,r9
 mov r9,rdx
 shl r9,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 or rax,r9
 mov r9,rcx
 shl r9,NEBO_RUNTIME_MEASUREMENT_QUALITY_SHIFT
 or rax,r9
 or rax,r8
 ret

; Canonical Uncertain(value, uncertainty) and infix ± use dimensionless data
; with explicit default provenance quality/confidence, never a hidden epsilon.
nebo_runtime_uncertain_create:
 xor edx,edx
 mov ecx,100
 mov r8d,95
 jmp nebo_runtime_measurement_create

nebo_runtime_uncertain_value:
 mov rax,rdi
 sar rax,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 ret

nebo_runtime_uncertain_uncertainty:
 mov rax,rdi
 shr rax,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and eax,0xffff
 ret

nebo_runtime_uncertain_unit:
 mov rax,rdi
 shr rax,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and eax,0x3f
 ret

nebo_runtime_uncertain_quality:
 mov rax,rdi
 shr rax,NEBO_RUNTIME_MEASUREMENT_QUALITY_SHIFT
 and eax,0x7f
 ret

nebo_runtime_uncertain_confidence:
 mov rax,rdi
 and eax,0x7f
 ret

nebo_runtime_uncertain_separator_codepoint:
 mov eax,0xb1
 ret

; Intrinsic uncertainty defines the tolerance: |a.value-b.value| <= ua+ub.
; No process-global or target-dependent epsilon is read.
nebo_runtime_uncertain_approx_equal:
 mov r8,rdi
 shr r8,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and r8d,0x3f
 mov r9,rsi
 shr r9,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and r9d,0x3f
 cmp r8,r9
 jne .approx_false
 mov rax,rdi
 sar rax,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 mov rcx,rsi
 sar rcx,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 sub rax,rcx
 jns .approx_difference_ready
 neg rax
.approx_difference_ready:
 mov rdx,rdi
 shr rdx,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and edx,0xffff
 mov rcx,rsi
 shr rcx,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and ecx,0xffff
 add rdx,rcx
 cmp rax,rdx
 setbe al
 movzx eax,al
 ret
.approx_false:
 xor eax,eax
 ret

nebo_runtime_uncertain_not_approx_equal:
 sub rsp,8
 call nebo_runtime_uncertain_approx_equal
 add rsp,8
 xor eax,1
 ret

; Semantic equivalence deliberately has its own owner.  In the bounded
; measurement model it compares value, uncertainty and all provenance fields.
nebo_runtime_uncertain_equivalent:
 cmp rdi,rsi
 sete al
 movzx eax,al
 ret

; Mathematical convention: a divides b iff a is nonzero and b % a == 0.
; A zero divisor yields false rather than a machine division fault.
nebo_runtime_int_divides:
 test rdi,rdi
 jz .divides_false
 mov rax,0x8000000000000000
 cmp rsi,rax
 jne .divides_compute
 cmp rdi,-1
 je .divides_true
.divides_compute:
 mov rax,rsi
 cqo
 idiv rdi
 test rdx,rdx
 sete al
 movzx eax,al
 ret
.divides_true:
 mov eax,1
 ret
.divides_false:
 xor eax,eax
 ret

nebo_runtime_int_not_divides:
 sub rsp,8
 call nebo_runtime_int_divides
 add rsp,8
 xor eax,1
 ret

; A Measurement pair declares a proportionality model through its
; (value, uncertainty) coordinates.  Degenerate zero vectors are not models.
nebo_runtime_uncertain_proportional:
 mov r10,rdi
 shr r10,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and r10d,0x3f
 mov r11,rsi
 shr r11,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and r11d,0x3f
 cmp r10,r11
 jne .proportional_false
 mov rax,rdi
 sar rax,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 mov rdx,rdi
 shr rdx,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and edx,0xffff
 mov rcx,rsi
 sar rcx,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 mov r8,rsi
 shr r8,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and r8d,0xffff
 mov r9,rax
 or r9,rdx
 jz .proportional_false
 mov r9,rcx
 or r9,r8
 jz .proportional_false
 imul rax,r8
 imul rcx,rdx
 cmp rax,rcx
 sete al
 movzx eax,al
 ret
.proportional_false:
 xor eax,eax
 ret

; Shared propagation setup.  Returns summed value in RDI, uncertainties in
; RSI/RDX, unit in RDX after the caller consumes the uncertainty pair, and
; conservative minimum quality/confidence in RCX/R8.
nebo_runtime_uncertain_add_worst_case:
 sub rsp,8
 call nebo_runtime_uncertain_add_prepare
 add rsp,8
 add rsi,r9
 cmp rsi,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_MAX
 ja nebo_runtime_trap_overflow
 jmp nebo_runtime_measurement_create

nebo_runtime_uncertain_add_correlated:
 ; Full positive correlation is the explicit |u1|+|u2| model.
 jmp nebo_runtime_uncertain_add_worst_case

nebo_runtime_uncertain_add_interval:
 ; Symmetric interval addition has the same bound, under a distinct policy.
 jmp nebo_runtime_uncertain_add_worst_case

nebo_runtime_uncertain_add_independent:
 sub rsp,8
 call nebo_runtime_uncertain_add_prepare
 add rsp,8
 mov rax,rsi
 imul rax,rax
 mov r10,r9
 imul r10,r10
 add rax,r10
 jo nebo_runtime_trap_overflow
 cvtsi2sd xmm0,rax
 sqrtsd xmm0,xmm0
 cvttsd2si rsi,xmm0
 mov r10,rsi
 imul r10,r10
 cmp r10,rax
 jae .independent_rounded
 inc rsi
.independent_rounded:
 cmp rsi,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_MAX
 ja nebo_runtime_trap_overflow
 jmp nebo_runtime_measurement_create

; RDI/RAX are packed operands on entry.  Return field registers ready for the
; checked packer and preserve the second uncertainty in R9.
nebo_runtime_uncertain_add_prepare:
 mov r10,rdi
 mov r11,rsi
 mov rdi,r10
 sar rdi,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 mov rax,r11
 sar rax,NEBO_RUNTIME_MEASUREMENT_VALUE_SHIFT
 add rdi,rax
 jo nebo_runtime_trap_overflow
 mov rsi,r10
 shr rsi,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and esi,0xffff
 mov r9,r11
 shr r9,NEBO_RUNTIME_MEASUREMENT_UNCERTAINTY_SHIFT
 and r9d,0xffff
 mov rdx,r10
 shr rdx,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and edx,0x3f
 mov rax,r11
 shr rax,NEBO_RUNTIME_MEASUREMENT_UNIT_SHIFT
 and eax,0x3f
 cmp rdx,rax
 jne nebo_runtime_trap_arithmetic_domain
 mov rcx,r10
 shr rcx,NEBO_RUNTIME_MEASUREMENT_QUALITY_SHIFT
 and ecx,0x7f
 mov rax,r11
 shr rax,NEBO_RUNTIME_MEASUREMENT_QUALITY_SHIFT
 and eax,0x7f
 cmp rcx,rax
 cmova rcx,rax
 mov r8,r10
 and r8d,0x7f
 mov rax,r11
 and eax,0x7f
 cmp r8,rax
 cmova r8,rax
 ret

; G129 source quantities use one exact machine representation: ratios are
; basis points, angles are millidegrees, and temperatures are milli-Celsius.
; Every conversion is checked before the value becomes observable.
NEBOC_ABI_FUNCTION nebo_runtime_quantity_percent
 mov rax,rdi
 imul rax,100
 jo nebo_runtime_trap_overflow
 ret

NEBOC_ABI_FUNCTION nebo_runtime_quantity_per_mille
 mov rax,rdi
 imul rax,10
 jo nebo_runtime_trap_overflow
 ret

NEBOC_ABI_FUNCTION nebo_runtime_quantity_angle
 mov rax,rdi
 imul rax,1000
 jo nebo_runtime_trap_overflow
 ret

NEBOC_ABI_FUNCTION nebo_runtime_quantity_celsius
 mov rax,rdi
 imul rax,1000
 jo nebo_runtime_trap_overflow
 ret

NEBOC_ABI_FUNCTION nebo_runtime_quantity_fahrenheit
 mov rax,rdi
 sub rax,32
 jo nebo_runtime_trap_overflow
 imul rax,5000
 jo nebo_runtime_trap_overflow
 mov rcx,9
 cqo
 idiv rcx
 test rdx,rdx
 jnz nebo_runtime_trap_arithmetic_domain
 ret

; checked_divide(dividend, divisor) -> RAX=quotient or a deterministic trap.
NEBOC_ABI_FUNCTION nebo_runtime_checked_divide
 test rsi,rsi
 jz nebo_runtime_trap_division_by_zero
 mov rdx,0x8000000000000000
 cmp rdi,rdx
 jne .checked_divide_execute
 cmp rsi,-1
 je nebo_runtime_trap_overflow
.checked_divide_execute:
 mov rax,rdi
 mov rcx,rsi
 cqo
 idiv rcx
 ret

; checked_remainder follows signed truncation toward zero. INT_MIN % -1 is
; mathematically zero and must not execute the trapping x86-64 IDIV form.
NEBOC_ABI_FUNCTION nebo_runtime_checked_remainder
 test rsi,rsi
 jz nebo_runtime_trap_division_by_zero
 mov rdx,0x8000000000000000
 cmp rdi,rdx
 jne .checked_remainder_execute
 cmp rsi,-1
 jne .checked_remainder_execute
 xor eax,eax
 ret
.checked_remainder_execute:
 mov rax,rdi
 mov rcx,rsi
 cqo
 idiv rcx
 mov rax,rdx
 ret

; checked_power(base, exponent) -> RAX=result or a deterministic trap. The
; exponent is an Int in the public G122 profile and must be non-negative.
NEBOC_ABI_FUNCTION nebo_runtime_checked_power
 test rsi,rsi
 js nebo_runtime_trap_arithmetic_domain
 mov r8,1
 mov r9,rdi
 mov rcx,rsi
.checked_power_loop:
 test rcx,rcx
 jz .checked_power_success
 test cl,1
 jz .checked_power_after_result
 imul r8,r9
 jo nebo_runtime_trap_overflow
.checked_power_after_result:
 shr rcx,1
 jz .checked_power_success
 imul r9,r9
 jo nebo_runtime_trap_overflow
 jmp .checked_power_loop
.checked_power_success:
 mov rax,r8
 ret

; checked_float_power_int(base binary64 bits, exponent) -> RAX=result bits or
; deterministic arithmetic-domain trap. No implicit Int-to-Float conversion is
; exposed: the bridge is exact Float/Int and rejects NaN, infinity, zero to a
; negative exponent, exponent magnitude above one million, and non-finite
; results.
NEBOC_ABI_FUNCTION nebo_runtime_checked_float_power_int
 mov rax,rdi
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je nebo_runtime_trap_arithmetic_domain
 xor r9d,r9d
 mov r8,rsi
 test r8,r8
 jns .checked_float_power_magnitude
 mov r9d,1
 mov rax,0x8000000000000000
 cmp r8,rax
 je nebo_runtime_trap_arithmetic_domain
 neg r8
.checked_float_power_magnitude:
 cmp r8,1000000
 ja nebo_runtime_trap_arithmetic_domain
 test r9d,r9d
 jz .checked_float_power_prepare
 mov rax,rdi
 shl rax,1
 test rax,rax
 jz nebo_runtime_trap_arithmetic_domain
.checked_float_power_prepare:
 movq xmm1,rdi
 movq xmm0,[rel nebo_runtime_float_one]
.checked_float_power_loop:
 test r8,r8
 jz .checked_float_power_reciprocal
 test r8b,1
 jz .checked_float_power_after_result
 mulsd xmm0,xmm1
.checked_float_power_after_result:
 shr r8,1
 jz .checked_float_power_reciprocal
 mulsd xmm1,xmm1
 jmp .checked_float_power_loop
.checked_float_power_reciprocal:
 test r9d,r9d
 jz .checked_float_power_finite
 movq xmm2,[rel nebo_runtime_float_one]
 divsd xmm2,xmm0
 movapd xmm0,xmm2
.checked_float_power_finite:
 movq rax,xmm0
 mov rcx,rax
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 je nebo_runtime_trap_arithmetic_domain
 ret

; bytes_xor(left descriptor, right descriptor, out data, capacity, out
; descriptor) -> RAX=out descriptor. Every structural/domain check precedes
; the first output byte, so failure cannot publish a partial value.
NEBOC_ABI_FUNCTION nebo_runtime_bytes_xor
 test rdi,rdi
 jz nebo_runtime_trap_arithmetic_domain
 test rsi,rsi
 jz nebo_runtime_trap_arithmetic_domain
 test rdx,rdx
 jz nebo_runtime_trap_arithmetic_domain
 test r8,r8
 jz nebo_runtime_trap_arithmetic_domain
 mov r9,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 cmp r9,[rsi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 jne nebo_runtime_trap_arithmetic_domain
 cmp r9,rcx
 ja nebo_runtime_trap_arithmetic_domain
 cmp r9,4096
 ja nebo_runtime_trap_arithmetic_domain
 test r9,r9
 jz .bytes_xor_publish
 mov r10,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_DATA_OFFSET]
 mov r11,[rsi+NEBO_RUNTIME_BYTES_DESCRIPTOR_DATA_OFFSET]
 test r10,r10
 jz nebo_runtime_trap_arithmetic_domain
 test r11,r11
 jz nebo_runtime_trap_arithmetic_domain
 xor ecx,ecx
.bytes_xor_loop:
 cmp rcx,r9
 jae .bytes_xor_publish
 mov al,[r10+rcx]
 xor al,[r11+rcx]
 mov [rdx+rcx],al
 inc rcx
 jmp .bytes_xor_loop
.bytes_xor_publish:
 mov [r8+NEBO_RUNTIME_BYTES_DESCRIPTOR_DATA_OFFSET],rdx
 mov [r8+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET],r9
 mov dword [r8+NEBO_RUNTIME_BYTES_DESCRIPTOR_FLAGS_OFFSET],NEBO_RUNTIME_BYTES_FLAG_IMMUTABLE
 mov word [r8+NEBO_RUNTIME_BYTES_DESCRIPTOR_ELEMENT_WIDTH_OFFSET],NEBO_RUNTIME_BYTES_ELEMENT_WIDTH
 mov word [r8+NEBO_RUNTIME_BYTES_DESCRIPTOR_LIFETIME_OFFSET],0
 mov rax,r8
 ret


; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF005 public numeric-safety foundation helpers.
; signed i64 in RDI -> IEEE binary64 in XMM0, with language rounding isolated
; from ambient MXCSR and the complete caller MXCSR restored.
align 16
nebo_runtime_numeric_safety_int_to_float:
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 and eax,0xffff9fff
 mov [rsp+4],eax
 ldmxcsr [rsp+4]
 cvtsi2sd xmm0,rdi
 ldmxcsr [rsp]
 add rsp,16
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_finite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 setne al
 movzx eax,al
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_nan:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setnz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_infinite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_negative_zero:
 movq rdx,xmm0
 mov rax,0x8000000000000000
 cmp rdx,rax
 sete al
 movzx eax,al
 cld
 ret

; TEXT-CHAR-UNICODE-E-BYTES-PF005 public textual foundation helpers.
align 16
section .text.runtime_text progbits alloc exec nowrite align=16
nebo_runtime_textual_text_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret
align 16
nebo_runtime_textual_text_contract:
 mov eax,NEBO_RUNTIME_TEXT_ABI_VERSION
 mov edx,NEBO_TEXT_CHAR_BYTES_RUNTIME_TEXT_DESCRIPTOR_SIZE
 mov ecx,NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov r8d,NEBO_RUNTIME_TEXT_FLAGS_LITERAL
 cld
 ret
align 16
nebo_runtime_textual_text_codepoint_count:
 mov rcx,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 mov rsi,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_DATA_OFFSET]
 xor eax,eax
 test rcx,rcx
 jz ._count_done
._count_loop:
 mov dl,[rsi]
 and dl,0xc0
 cmp dl,0x80
 je ._continuation
 inc rax
._continuation:
 inc rsi
 dec rcx
 jnz ._count_loop
._count_done:
 cld
 ret
align 16
nebo_runtime_textual_char_codepoint:
 mov eax,edi
 cld
 ret
align 16
nebo_runtime_textual_bytes_empty:
 lea rax,[rel nebo_runtime_textual_empty_bytes_descriptor]
 cld
 ret
align 16
nebo_runtime_textual_bytes_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret

; Immutable Bytes descriptor and signed index -> zero-extended byte value.
; Use the same checked index trap as the native Slice access adapter.
align 16
nebo_runtime_textual_bytes_at:
 cmp rsi,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 jae nebo_runtime_trap_overflow
 mov rax,[rdi]
 movzx eax,byte [rax+rsi]
 ret

; RDI=ordered Int arguments, RSI=1 or 4, RDX=private four-byte storage,
; RCX=private descriptor. Validate the entire input before publishing storage.
align 16
nebo_runtime_textual_bytes_construct:
 cmp rsi,1
 je .validate
 cmp rsi,4
 jne nebo_runtime_trap_arithmetic_domain
.validate:
 xor r8d,r8d
.check:
 cmp qword [rdi+r8*8],255
 ja nebo_runtime_trap_arithmetic_domain
 inc r8
 cmp r8,rsi
 jb .check
 mov dword [rdx],0
 xor r8d,r8d
.copy:
 mov rax,[rdi+r8*8]
 mov [rdx+r8],al
 inc r8
 cmp r8,rsi
 jb .copy
 mov [rcx+NEBO_RUNTIME_BYTES_DESCRIPTOR_DATA_OFFSET],rdx
 mov [rcx+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET],rsi
 mov dword [rcx+NEBO_RUNTIME_BYTES_DESCRIPTOR_FLAGS_OFFSET],NEBO_RUNTIME_BYTES_FLAG_IMMUTABLE
 mov word [rcx+NEBO_RUNTIME_BYTES_DESCRIPTOR_ELEMENT_WIDTH_OFFSET],NEBO_RUNTIME_BYTES_ELEMENT_WIDTH
 mov word [rcx+NEBO_RUNTIME_BYTES_DESCRIPTOR_LIFETIME_OFFSET],0
 mov rax,rcx
 cld
 ret

; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 public runtime integration reuses the PF004 caller-owned primitives.

; RDI=slot, RSI=tag. Canonicalizes all bytes and leaves payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_store_zero_payload
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 ret

; RDI=slot, RSI=tag, RDX=zero-extended or full-width integer payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_integer
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 mov [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],rdx
 ret

; RDI=slot, RSI=tag, XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_float
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 movq [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],xmm0
 ret

; RDI=slot -> RAX=zero-extended tag.
NEBOC_ABI_FUNCTION neboc_runtime_load_tag
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 ret

; RDI=slot -> RAX=raw payload bits.
NEBOC_ABI_FUNCTION neboc_runtime_load_integer
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot -> XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_load_float
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot, RSI=expected tag -> RAX canonical Bool.
NEBOC_ABI_FUNCTION neboc_runtime_tag_test
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 cmp rax,rsi
 sete al
 movzx eax,al
 ret

; RDI=slot, RSI=success tag, RDX=fallback -> RAX payload or fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_integer
 mov rax,rdx
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; RDI=slot, RSI=success tag, XMM0=fallback -> XMM0 payload or unchanged fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_float
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; Option canonicality: tag 0/1, padding zero, and None payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_validate_option
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 test eax,eax
 jnz .good
 cmp qword [rdi+8],0
 jne .bad
.good:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Result canonicality: tag 0/1 and padding zero; both variants carry a payload.
NEBOC_ABI_FUNCTION neboc_runtime_validate_result
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Register-level SysV aggregate prototype for INTEGER/INTEGER values.
; RDI=tag, RSI=payload -> RAX=tag, RDX=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_integer_aggregate
 mov rax,rdi
 mov rdx,rsi
 ret

; Register-level SysV aggregate prototype for INTEGER/SSE values.
; RDI=tag, XMM0=payload -> RAX=tag, XMM0=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_sse_aggregate
 mov rax,rdi
 ret

; RDI/RSI = TextDescriptor*. EAX = 0/1.
nebo_runtime_text_equal:
 test rdi,rdi
 jz .not_equal
 test rsi,rsi
 jz .not_equal
 mov rax,[rdi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 cmp rax,[rsi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 jne .not_equal
 cmp word [rdi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .not_equal
 cmp word [rsi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .not_equal
 test rax,rax
 jz .equal
 mov rcx,rax
 mov rdi,[rdi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 test rdi,rdi
 jz .not_equal
 test rsi,rsi
 jz .not_equal
 cld
 repe cmpsb
 jne .not_equal
.equal:
 mov eax,1
 ret
.not_equal:
 xor eax,eax
 ret

; Initialize and bind the one process-wide deterministic headless runtime.
section .text.runtime_console progbits alloc exec nowrite align=16
nebo_runtime_console_ensure_initialized:
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 lea rax,[rel nebo_runtime_console_finalize]
 mov [rel nebo_runtime_console_finalize_hook],rax
%endif
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_STATE_OFFSET],NEBO_CONSOLE_CONTEXT_STATE_READY
 je .console_ready
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_STATE_OFFSET],NEBO_CONSOLE_CONTEXT_STATE_EMPTY
 jne .console_bad_state
 sub rsp,8
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rel nebo_runtime_console_slots]
 mov edx,NEBO_CONSOLE_MAX_ACTIVE
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz .console_init_done
 lea rax,[rel nebo_runtime_fake_clock]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_fake_platform]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_scheduler]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_domains]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_command_buffers]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_event_buffers]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET],rax
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET],NEBO_CONSOLE_MAX_ACTIVE
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY
 lea rax,[rel nebo_runtime_console_documents]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_document_nodes]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_document_text]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET],rax
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET],NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rel nebo_runtime_headless_storage]
 call nebo_console_runtime_headless_bind
.console_init_done:
 add rsp,8
 ret
.console_ready:
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET],NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
 jne .console_bad_state
 mov eax,NEBO_CONSOLE_STATUS_OK
 ret
.console_bad_state:
 mov eax,NEBO_CONSOLE_STATUS_BAD_STATE
 ret

; Initialize the process-wide MF046 InputRegistry/PendingRegistry runtime.
nebo_runtime_input_ensure_initialized:
    cmp qword [rel nebo_runtime_input_runtime+NEBO_INPUT_RUNTIME_FLAGS_OFFSET], NEBO_INPUT_RUNTIME_REQUIRED_FLAGS
    je .input_ready
    sub rsp, 8
    call nebo_runtime_console_ensure_initialized
    test eax, eax
    jnz .input_done
    lea rax, [rel nebo_runtime_input_registries]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_input_records]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_pending_registries]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_pending_records]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET], rax
    mov qword [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_CONSOLE_CAPACITY_OFFSET], NEBO_CONSOLE_MAX_ACTIVE
    mov qword [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_CAPACITY_OFFSET], NEBO_INPUT_DEFAULT_CAPACITY
    lea rdi, [rel nebo_runtime_input_runtime]
    lea rsi, [rel nebo_runtime_console_context]
    lea rdx, [rel nebo_runtime_input_storage]
    call nebo_input_runtime_init
.input_done:
    add rsp, 8
    ret
.input_ready:
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret

; Stable runtime contract 1: default Console logical get-or-create.
; Returns the immutable 64-bit ConsoleHandle in RAX.
nebo_runtime_contract_1:
 sub rsp,24
 call nebo_runtime_console_ensure_initialized
 test eax,eax
 jnz .contract_1_failed
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rsp]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz .contract_1_failed
 mov rax,[rsp]
 add rsp,24
 ret
.contract_1_failed:
 add rsp,24
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Public source `.console()` publication bridge.  The three typed entries keep
; the source receiver representation explicit, enqueue one retained-document
; command, run the cooperative domain, and return the stable default handle.
; RDI = TextDescriptor* / signed Int / canonical Bool. RAX = ConsoleHandle.
global nebo_runtime_textual_native_descriptor
; Adapt a public 24-byte Text into a native 32-byte borrowed descriptor.
; The encoding tag is validated; byte validity is guaranteed by the Text type.
section .text.runtime_text_descriptor progbits alloc exec nowrite align=16
nebo_runtime_textual_native_descriptor:
 test rdi,rdi
 jz .invalid
 cmp word [rdi+20],1
 jne .invalid
 mov rax,[rdi]
 mov [rsi],rax
 mov rax,[rdi+8]
 mov [rsi+8],rax
 mov qword [rsi+16],2
 mov [rsi+24],rdi
 mov rax,rsi
 ret
.invalid:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap

global nebo_runtime_textual_public_descriptor
global nebo_runtime_textual_checked_unwrap
; RDI checked Result, RSI typed fallback, EDX canonical Text/TextSplit type.
; Reuse the native inline result layout. Only successful Text values need
; projection to the public descriptor prefix; errors retain the fallback.
nebo_runtime_textual_checked_unwrap:
 test rdi,rdi
 jz .invalid
 mov rax,rsi
 cmp byte [rdi],1
 je .done
 cmp byte [rdi],0
 jne .invalid
 lea rax,[rdi+16]
 cmp edx,4
 je nebo_runtime_textual_public_descriptor
.done:
 ret
.invalid:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap
; RAX = native Text result in caller storage -> public 24-byte Text prefix.
; Data and byte length are preserved. The workspace is immutable and scoped
; to the current function; it is never marked as static storage.
nebo_runtime_textual_public_descriptor:
 test rax,rax
 jz .invalid
 mov dword [rax+16],5
 mov word [rax+20],1
 mov word [rax+22],0
 ret
.invalid:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_DESCRIPTOR
 jmp nebo_runtime_trap

nebo_runtime_console_publish_text:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 jmp nebo_runtime_console_publish_value

nebo_runtime_console_publish_int:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_INT
 jmp nebo_runtime_console_publish_value

nebo_runtime_console_publish_bool:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_BOOL

nebo_runtime_console_publish_value:
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 cmp qword [rel runtime_public_console_handle],0
 je .open
 cmp qword [rel runtime_public_console_document+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_OPEN
 jne runtime_public_console_failed
.open:
%endif
 push rbp
 mov rbp,rsp
 sub rsp,96
 mov [rsp+72],rdi
 mov [rsp+80],rsi
 call nebo_runtime_contract_1
 mov [rsp+64],rax
 mov rdi,rsp
 xor eax,eax
 mov ecx,NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
 cld
 rep stosq
 mov eax,[rsp+80]
 mov [rsp+NEBO_CONSOLE_COMMAND_KIND_OFFSET],eax
 mov rax,[rsp+72]
 mov [rsp+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET],rax
 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,[rsp+64]
 mov rdx,rsp
 call nebo_console_domain_send
 test eax,eax
 jnz .console_publish_failed
 lea rdi,[rel nebo_runtime_console_context]
 mov esi,8
 lea rdx,[rsp+88]
 call nebo_console_scheduler_run
 test eax,eax
 jnz .console_publish_failed
 mov rax,[rsp+64]
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 inc qword [rel nebo_runtime_publication_count]
 mov [rel nebo_runtime_last_console_handle],rax
 call runtime_public_console_commit_colors
 call runtime_public_console_sync
 mov rax,[rsp+64]
%endif
 leave
 ret
.console_publish_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

%ifdef NEBO_RUNTIME_PRACTICAL_IO
section .rodata
runtime_trace_environment: db 'NEBO_CONSOLE_TRACE=1',0
runtime_trace_environment_len equ $-runtime_trace_environment
runtime_live_trace_environment: db 'NEBO_CONSOLE_LIVE_TRACE=1',0
runtime_live_trace_environment_len equ $-runtime_live_trace_environment
runtime_math_trace_environment: db 'NEBO_MATH_TRACE=1',0
runtime_math_trace_environment_len equ $-runtime_math_trace_environment
runtime_hash_trace_environment: db 'NEBO_HASH_TRACE=1',0
runtime_hash_trace_environment_len equ $-runtime_hash_trace_environment
section .text
; Internal observation of the actual selected hash policy, constructor policy
; or hasher result. No expected seed/hash, native address or source text enters.
global nebo_runtime_hash_observe
nebo_runtime_hash_observe:
 sub rsp,56
 mov rax,0x314853484f42454e
 mov [rsp],rax
 mov [rsp+8],rdi
 mov [rsp+16],rsi
 mov [rsp+24],rdx
 lea rsi,[rel runtime_hash_trace_environment]
 mov edx,runtime_hash_trace_environment_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .done
 mov rsi,rsp
 mov edx,32
 mov qword [rsp+32],64
.write:
 dec qword [rsp+32]
 jz .failed
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .failed
 add rsi,rax
 sub rdx,rax
 jnz .write
.done:
 add rsp,56
 ret
.failed:
 add rsp,56
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Internal headless observation of an actual scalar owner result. The caller
; supplies operation, scalar type and raw result bits; no expected value enters
; the runtime. The output contains no addresses or source contents.
global nebo_runtime_math_observe
nebo_runtime_math_observe:
 sub rsp,40
 mov rax,0x3148544d4f42454e
 mov [rsp],rax
 mov [rsp+8],rdi
 mov [rsp+16],rsi
 mov [rsp+24],rdx
 lea rsi,[rel runtime_math_trace_environment]
 mov edx,runtime_math_trace_environment_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .done
 mov rsi,rsp
 mov edx,32
.write:
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .failed
 add rsi,rax
 sub rdx,rax
 jnz .write
.done:
 add rsp,40
 ret
.failed:
 add rsp,40
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Opt-in headless retained-document observation. Match one exact environment
; setting; never inspect credentials or infer anything from a fixture path.
nebo_runtime_trace_requested:
 lea rsi,[rel runtime_trace_environment]
 mov edx,runtime_trace_environment_len
 jmp nebo_runtime_trace_setting
global nebo_runtime_trace_setting
nebo_runtime_trace_setting:
 cld
 mov r10,rsi
 mov r11d,edx
 mov rdi,[rel nebo_runtime_process_stack]
 test rdi,rdi
 jz .no
 mov rax,[rdi]
 cmp rax,4096
 ja .no
 lea r8,[rdi+rax*8+16]
 mov r9d,4096
.next:
 mov rdi,[r8]
 test rdi,rdi
 jz .no
 mov rsi,r10
 mov ecx,r11d
 repe cmpsb
 je .yes
 add r8,8
 dec r9d
 jnz .next
.no:
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

; Emit NEBOTRC1, payload-node count, UTF-8 byte length, publication count,
; node-kind qwords, then the actual retained document text. No native pointers.
nebo_runtime_console_trace:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 sub rsp,16
 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,[rel nebo_runtime_last_console_handle]
 lea rdx,[rsp]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .done
 mov rbx,[rsp]
 mov rbx,[rbx+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
 test rbx,rbx
 jz .bad
 mov r12,[rbx+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 test r12,r12
 jz .bad
 cmp r12,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 ja .bad
 dec r12
 lea r8,[rel nebo_runtime_trace_buffer]
 mov rax,0x314352544f42454e
 mov [r8],rax
 mov [r8+8],r12
 mov rax,[rel nebo_runtime_publication_count]
 mov [r8+24],rax
 mov r9,[rbx+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
 add r9,NEBO_CONSOLE_NODE_HEADER_SIZE
 xor ecx,ecx
.kinds:
 cmp rcx,r12
 jae .text
 mov eax,[r9+NEBO_CONSOLE_NODE_KIND_OFFSET]
 mov [r8+rcx*8+32],rax
 add r9,NEBO_CONSOLE_NODE_HEADER_SIZE
 inc rcx
 jmp .kinds
.text:
 mov rdi,rbx
 lea rsi,[r8+r12*8+32]
 mov edx,NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
 lea rcx,[r8+16]
 call nebo_console_document_copy_plain_text
 test eax,eax
 jnz .done
 lea rsi,[rel nebo_runtime_trace_buffer]
 lea rdx,[r12*8+32]
 add rdx,[rsi+16]
.write:
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .bad
 add rsi,rax
 sub rdx,rax
 jnz .write
 call runtime_public_console_observe
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 add rsp,16
 pop r12
 pop rbx
 pop rbp
 ret
%endif

; Stable runtime contract 2: named Console logical creation from TextDescriptor.
; RDI = immutable UTF-8 TextDescriptor*, RAX = ConsoleHandle.
nebo_runtime_contract_2:
 sub rsp,24
 mov [rsp+8],rdi
 call nebo_runtime_console_ensure_initialized
 test eax,eax
 jnz .contract_2_failed
 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,[rsp+8]
 lea rdx,[rsp]
 call nebo_console_manager_named_create
 test eax,eax
 jnz .contract_2_failed
 mov rax,[rsp]
 add rsp,24
 ret
.contract_2_failed:
 add rsp,24
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Stable runtime contract 3: anonymous Text.console().scan().
; RDI=TextDescriptor*, RSI=BindingId, RDX=compiler PendingId, RCX=source order.
; Returns PendingHandle in RAX; Console/Input handles remain internal.
nebo_runtime_contract_3:
    push rbp
    mov rbp, rsp
    sub rsp, NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
    mov r8, rdi
    mov r9, rsi
    mov r10, rdx
    mov r11, rcx
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_SCAN_ROUTE_KIND_OFFSET], NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    mov dword [rsp+NEBO_SCAN_ROUTE_FLAGS_OFFSET], NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    mov [rsp+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET], r8
    mov [rsp+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], r9
    mov [rsp+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], r10
    mov [rsp+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET], r11
    call nebo_runtime_input_ensure_initialized
    test eax, eax
    jnz .contract_3_failed
    lea rdi, [rel nebo_runtime_input_runtime]
    mov rsi, rsp
    call nebo_console_scan_route
    test eax, eax
    jnz .contract_3_failed
    mov rax, [rsp+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    leave
    ret
.contract_3_failed:
    leave
    mov edi, NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
    jmp nebo_runtime_trap

%ifdef NEBO_RUNTIME_PRACTICAL_IO
; Typed ScanPlan live acquisition reuses the canonical route, editor, native
; event bridge and immutable submission. Parsing and binding stay in ScanPlan.
; prompt*, request id, security flags, destination[4096] -> status, RCX length.
; Status 1 is absence of a display; 8 is close/cancel; 0 is a copied value.
global nebo_runtime_scan_live_acquire
nebo_runtime_scan_live_acquire:
 push rbp
 mov rbp,rsp
 sub rsp,224
 mov [rsp+176],rdi
 mov [rsp+184],rsi
 mov [rsp+192],rdx
 mov [rsp+200],rcx
 mov qword [rsp+216],0
 mov rdi,[rel nebo_runtime_process_stack]
 call nebo_runtime_live_available
 test eax,eax
 jnz .acquire_done
 mov rdi,rsp
 xor eax,eax
 mov ecx,NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
 cld
 rep stosq
 mov dword [rsp+NEBO_SCAN_ROUTE_KIND_OFFSET],NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
 mov dword [rsp+NEBO_SCAN_ROUTE_FLAGS_OFFSET],NEBO_SCAN_ROUTE_REQUIRED_FLAGS
 mov rax,[rsp+176]
 mov [rsp+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET],rax
 mov rax,[rsp+184]
 test rax,rax
 jz .acquire_error
 mov [rsp+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET],rax
 mov [rsp+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET],rax
 mov [rsp+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET],rax
 call nebo_runtime_input_ensure_initialized
 test eax,eax
 jnz .acquire_error
 lea rdi,[rel nebo_runtime_input_runtime]
 mov rsi,rsp
 call nebo_console_scan_route
 test eax,eax
 jnz .acquire_error
 mov rdi,[rsp+192]
 call nebo_runtime_live_input_security
 lea rdi,[rsp+112]
 xor eax,eax
 mov ecx,NEBO_SUBMISSION_RESULT_QWORDS
 rep stosq
 mov rdi,[rel nebo_runtime_process_stack]
 lea rsi,[rel nebo_runtime_console_context]
 lea rdx,[rel nebo_runtime_input_runtime]
 mov rcx,rsp
 lea r8,[rsp+112]
 call nebo_runtime_live_scan_roundtrip
 mov [rsp+208],rax
 test eax,eax
 jnz .acquire_wipe
 mov rax,[rsp+112+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET]
 cmp rax,[rsp+184]
 jne .acquire_error
 mov rcx,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET]
 cmp rcx,4096
 ja .acquire_error
 mov [rsp+216],rcx
 mov rsi,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET]
 mov rdi,[rsp+200]
 cld
 rep movsb
.acquire_wipe:
 call nebo_runtime_live_input_wipe
 xor edi,edi
 call nebo_runtime_live_input_security
 mov rax,[rsp+208]
 mov rcx,[rsp+216]
.acquire_done:
 leave
 ret
.acquire_error:
 mov qword [rsp+208],NEBO_LIVE_STATUS_INPUT
 jmp .acquire_wipe

; Basic canonical Text Scan over stdin.  Prompt bytes are written to stdout,
; acquisition is bounded to ScanPlan's 4096-byte ceiling, and a stable runtime
; Text descriptor is returned only after canonical normalization/validation.
; RDI=prompt TextDescriptor*, RSI/ RDX/ RCX=nonzero compiler route identities.
nebo_runtime_scan_stdin_text:
 push rbp
 mov rbp,rsp
 sub rsp,32
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 test rsi,rsi
 jz .stdin_failed
 test rdx,rdx
 jz .stdin_failed
 test rcx,rcx
 jz .stdin_failed
 test rdi,rdi
 jz .stdin_failed
 cmp word [rdi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .stdin_failed
 mov rdx,[rdi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 test rdx,rdx
 jz .stdin_read
 cmp rdx,SCAN_MAX_INPUT_BYTES
 ja .stdin_failed
 mov rsi,[rdi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 test rsi,rsi
 jz .stdin_failed
.stdin_write:
 mov eax,1
 mov edi,1
 syscall
 test rax,rax
 js .stdin_write_retry
 add rsi,rax
 sub rdx,rax
 jnz .stdin_write
.stdin_read:
 xor eax,eax
 xor edi,edi
 lea rsi,[rel nebo_runtime_stdin_buffer]
 mov edx,SCAN_MAX_INPUT_BYTES
 syscall
 test rax,rax
 js .stdin_read_retry
 test rax,rax
 jz .stdin_failed
 lea rdi,[rel nebo_runtime_stdin_buffer]
 mov rsi,rax
 mov edx,SCAN_SOURCE_STDIN
 call nebo_runtime_scan_store_text
 leave
 ret
.stdin_write_retry:
 cmp rax,-4
 je .stdin_write
 jmp .stdin_failed
.stdin_read_retry:
 cmp rax,-4
 je .stdin_read
.stdin_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Console frontend acquisition.  The canonical route owns document/input/
; pending state; the live frontend only drives normalized events and returns
; the immutable submission result for ScanPlan validation and binding.
; RDI=ConsoleHandle, RSI=BindingId, RDX=PendingId, RCX=source order.
nebo_runtime_scan_console_handle:
 push rbp
 mov rbp,rsp
 sub rsp,208
 mov [rsp+176],rdi
 mov [rsp+184],rsi
 mov [rsp+192],rdx
 mov [rsp+200],rcx
 test rdi,rdi
 jz .console_scan_failed
 test rsi,rsi
 jz .console_scan_failed
 test rdx,rdx
 jz .console_scan_failed
 test rcx,rcx
 jz .console_scan_failed
 mov rdi,rsp
 xor eax,eax
 mov ecx,NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
 cld
 rep stosq
 mov dword [rsp+NEBO_SCAN_ROUTE_KIND_OFFSET],NEBO_SCAN_ROUTE_CONSOLE_INLINE
 mov dword [rsp+NEBO_SCAN_ROUTE_FLAGS_OFFSET],NEBO_SCAN_ROUTE_REQUIRED_FLAGS
 mov rax,[rsp+176]
 mov [rsp+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET],rax
 mov rax,[rsp+184]
 mov [rsp+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET],rax
 mov rax,[rsp+192]
 mov [rsp+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET],rax
 mov rax,[rsp+200]
 mov [rsp+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET],rax
 call nebo_runtime_input_ensure_initialized
 test eax,eax
 jnz .console_scan_failed
 lea rdi,[rel nebo_runtime_input_runtime]
 mov rsi,rsp
 call nebo_console_scan_route
 test eax,eax
 jnz .console_scan_failed
 lea rdi,[rsp+112]
 xor eax,eax
 mov ecx,NEBO_SUBMISSION_RESULT_QWORDS
 cld
 rep stosq
 mov rdi,[rel nebo_runtime_process_stack]
 lea rsi,[rel nebo_runtime_console_context]
 lea rdx,[rel nebo_runtime_input_runtime]
 mov rcx,rsp
 lea r8,[rsp+112]
 call nebo_runtime_live_scan_roundtrip
 cmp eax,NEBO_LIVE_STATUS_CANCELLED
 je .console_scan_cancelled
 test eax,eax
 jnz .console_scan_failed
 mov rax,[rsp+112+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET]
 cmp rax,[rsp+184]
 jne .console_scan_failed
 mov rax,[rsp+112+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET]
 cmp rax,[rsp+192]
 jne .console_scan_failed
 mov rdi,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET]
 mov rsi,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET]
 mov edx,SCAN_SOURCE_DEVICE
 call nebo_runtime_scan_store_text
 leave
 ret
.console_scan_cancelled:
 leave
 xor edi,edi
 jmp nebo_runtime_exit
.console_scan_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; data*, length, Scan source -> stable TextDescriptor*.  Slot publication is
; failure-atomic: the process-wide count advances only after every ScanPlan
; gate succeeds.
nebo_runtime_scan_store_text:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 cmp r13,SCAN_MAX_INPUT_BYTES
 ja .store_failed
 mov edi,SCAN_MIN_FEATURE_ID
 mov esi,SCAN_KIND_TEXT
 mov edx,SCAN_FLAG_OPTIONAL | SCAN_FLAG_ALLOW_EMPTY | SCAN_FLAG_CHOMP
 mov ecx,r13d
 mov r8d,1
 mov r9d,r14d
 call neboc_scan_feature_validate
 test eax,eax
 jnz .store_failed
 mov edi,r14d
 mov esi,SCAN_CAP_STDIN | SCAN_CAP_DEVICE
 call neboc_scan_source_validate
 test eax,eax
 jnz .store_failed
 mov rbx,[rel nebo_runtime_scan_result_count]
 cmp rbx,NEBO_RUNTIME_SCAN_RESULT_CAPACITY
 jae .store_failed
 mov rax,rbx
 imul rax,SCAN_MAX_INPUT_BYTES
 lea rdx,[rel nebo_runtime_scan_values]
 add rdx,rax
 mov rdi,r12
 mov rsi,r13
 mov ecx,SCAN_MAX_INPUT_BYTES
 mov r8d,SCAN_FLAG_OPTIONAL | SCAN_FLAG_ALLOW_EMPTY | SCAN_FLAG_CHOMP
 call neboc_scan_normalize_ascii
 test rax,rax
 js .store_failed
 mov r13,rax
 mov rax,rbx
 imul rax,SCAN_MAX_INPUT_BYTES
 lea r12,[rel nebo_runtime_scan_values]
 add r12,rax
 mov rdi,r12
 mov rsi,r13
 xor edx,edx
 mov ecx,SCAN_MAX_INPUT_BYTES
 mov r8d,SCAN_TEXT_NO_CONTROL
 call neboc_scan_validate_text
 test eax,eax
 jnz .store_failed
 mov rax,rbx
 imul rax,NEBO_RUNTIME_TEXT_DESCRIPTOR_SIZE
 lea rdx,[rel nebo_runtime_scan_descriptors]
 add rdx,rax
 mov [rdx+NEBO_RUNTIME_TEXT_DATA_OFFSET],r12
 mov [rdx+NEBO_RUNTIME_TEXT_LENGTH_OFFSET],r13
 mov dword [rdx+NEBO_RUNTIME_TEXT_FLAGS_OFFSET],0
 mov word [rdx+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov word [rdx+NEBO_RUNTIME_TEXT_LIFETIME_OFFSET],NEBO_RUNTIME_TEXT_LIFETIME_STATIC
 inc qword [rel nebo_runtime_scan_result_count]
 mov rax,rdx
 jmp .store_done
.store_failed:
 xor eax,eax
.store_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 test rax,rax
 jz .store_trap
 ret
.store_trap:
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
%endif

%include "runtime/console/handles/console_handle.asm"
%include "runtime/console/input/registry/input_registry.asm"
%include "runtime/console/pending/pending_registry.asm"
%include "runtime/console/input/routing/scan_routing.asm"
%include "runtime/console/input/editing/text_editor.asm"
%include "runtime/console/focus/focus_manager.asm"
%include "runtime/console/dependency-bridge/dependency_bridge.asm"
%include "runtime/console/input/submission/input_submission.asm"
%include "runtime/console/lifecycle/console_lifecycle.asm"
%include "runtime/console/queues/console_queue.asm"
%include "runtime/console/renderers/basic/basic_renderer.asm"
%include "runtime/console/document/console_document.asm"
%include "runtime/console/behavior/console_behavior.asm"
%include "runtime/console/renderer-registry/renderer_registry.asm"
%include "runtime/console/render/fake_glyph_provider.asm"
%include "runtime/console/layout/console_layout.asm"
%include "runtime/console/render/render_tree.asm"
%include "runtime/console/render/draw_command.asm"
%include "runtime/console/render/software_surface.asm"
%include "runtime/console/render/output_conformance.asm"
%include "runtime/console/platform/fake/fake_platform.asm"
%include "runtime/console/domain/console_domain.asm"
%include "runtime/console/manager/console_manager.asm"
%include "runtime/textual/text_query.asm"
%include "runtime/textual/text_transform.asm"
%include "runtime/textual/text_parse.asm"
%define NEBO_RUNTIME_CORE_EMBED 1
%include "runtime/textual/unicode.asm"
%undef NEBO_RUNTIME_CORE_EMBED
%include "runtime/functions/callable_runtime.inc"
%include "runtime/memory/ownership_effects.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

%ifdef NEBO_RUNTIME_PRACTICAL_IO
%include "runtime/console/document/public_console_bridge.inc"
%endif

%ifdef NEBO_RUNTIME_PRACTICAL_IO
%include "runtime/console/document/public_console_observation.inc"
%endif

%ifdef NEBO_RUNTIME_PRACTICAL_IO
%include "runtime/console/document/public_color_bridge.inc"
%endif

%ifdef NEBO_RUNTIME_PRACTICAL_IO
section .text.runtime_console_finalize progbits alloc exec nowrite align=16
nebo_runtime_console_finalize:
 sub rsp,8
 cmp qword [rel nebo_runtime_publication_count],0
 je .finalized
 call nebo_runtime_trace_requested
 test eax,eax
 jz .practical_live
 call nebo_runtime_console_trace
 test eax,eax
 jnz .finalize_failed
 jmp .finalized
.practical_live:
 call runtime_public_live_presentation
 mov rdi,[rel nebo_runtime_process_stack]
 lea rsi,[rel nebo_runtime_console_context]
 mov rdx,[rel nebo_runtime_last_console_handle]
 call nebo_runtime_live_finalize
 test eax,eax
 jnz .finalize_failed
 ; A live observer may request the same retained semantic document after the
 ; actual window/event lifecycle. Unlike NEBO_CONSOLE_TRACE this never skips
 ; the live backend, and contains no expected text or fixture identity.
 lea rsi,[rel runtime_live_trace_environment]
 mov edx,runtime_live_trace_environment_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .finalized
 call nebo_runtime_console_trace
 test eax,eax
 jnz .finalize_failed
.finalized:
 xor eax,eax
.finalize_failed:
 add rsp,8
 ret
%endif
