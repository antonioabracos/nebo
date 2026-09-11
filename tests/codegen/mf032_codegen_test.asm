; Nebo Assembly — MF032 Architecture Backend / AssemblyWriter scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/diagnostics/codegen_diagnostics.inc"

extern neboc_data_layout_init_first_target
extern neboc_target_context_init
extern neboc_assembly_writer_init
extern neboc_assembly_writer_validate
extern neboc_arch_backend_init
extern neboc_arch_backend_validate
extern neboc_arch_backend_begin_module
extern neboc_arch_backend_begin_function
extern neboc_arch_backend_emit_int_literal
extern neboc_arch_backend_emit_text_bytes
extern neboc_arch_backend_emit_plan
extern neboc_arch_backend_end_module
extern neboc_codegen_diagnostic_name
extern neboc_host_process_exit

global _start

%define OUTPUT_CAPACITY 8192
%define SMALL_CAPACITY 16
%define OPERATION_CAPACITY 6

section .rodata
expected_empty: incbin "tests/codegen/goldens/001-empty-start.asm"
expected_empty_end:
expected_int: incbin "tests/codegen/goldens/002-int-literal.asm"
expected_int_end:
expected_text: incbin "tests/codegen/goldens/007-text-data.asm"
expected_text_end:
expected_security: incbin "tests/codegen/goldens/012-source-text-safe.asm"
expected_security_end:
expected_plan: incbin "tests/codegen/goldens/plan-lowering.asm"
expected_plan_end:
text_hello: db 'Hello'
text_stable: db 'stable'
source_injection: db 'global pwned',10,'pwned: syscall',10
expected_unresolved: db 'unresolved-node-before-codegen'
label_fn_7: db 'nebo_fn_7'
label_int_3: db 'nebo_int_3'
label_text_5: db 'nebo_text_5'

section .bss align=16
layout_a: resb NEBOC_DATA_LAYOUT_SIZE
context_a: resb NEBOC_TARGET_CONTEXT_SIZE
target_request_a: resb NEBOC_TARGET_REQUEST_SIZE
writer_a: resb NEBOC_ASSEMBLY_WRITER_SIZE
backend_a: resb NEBOC_ARCH_BACKEND_SIZE
output_a: resb OUTPUT_CAPACITY

layout_b: resb NEBOC_DATA_LAYOUT_SIZE
context_b: resb NEBOC_TARGET_CONTEXT_SIZE
target_request_b: resb NEBOC_TARGET_REQUEST_SIZE
writer_b: resb NEBOC_ASSEMBLY_WRITER_SIZE
backend_b: resb NEBOC_ARCH_BACKEND_SIZE
output_b: resb OUTPUT_CAPACITY

small_writer: resb NEBOC_ASSEMBLY_WRITER_SIZE
small_backend: resb NEBOC_ARCH_BACKEND_SIZE
small_output: resb SMALL_CAPACITY

lowering_table: resb NEBOC_LOWERING_TABLE_SIZE
lowering_plan: resb NEBOC_FUNCTION_PLAN_SIZE
lowering_operations: resb NEBOC_LOWERING_OPERATION_SIZE*OPERATION_CAPACITY

diag_ptr: resq 1
diag_len: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,1
 je test_pass
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 cmp eax,1
 je scenario_1
 cmp eax,2
 je scenario_2
 cmp eax,3
 je scenario_3
 cmp eax,4
 je scenario_4
 cmp eax,5
 je scenario_5
 cmp eax,6
 je scenario_6
 cmp eax,7
 je scenario_7
 cmp eax,8
 je scenario_8
 jmp scenario_9

; NEBO-CODEGEN-GOLDEN-001 — empty start module has canonical Assembly.
scenario_1:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer_a]
 lea rsi,[rel expected_empty]
 mov edx,expected_empty_end-expected_empty
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-GOLDEN-002 — signed Int literal is emitted as dq.
scenario_2:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 call begin_function_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 mov edx,42
 call neboc_arch_backend_emit_int_literal
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer_a]
 lea rsi,[rel expected_int]
 mov edx,expected_int_end-expected_int
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-GOLDEN-007 — Text is serialized as numeric bytes.
scenario_3:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 call begin_function_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 lea rdx,[rel text_hello]
 mov ecx,5
 call neboc_arch_backend_emit_text_bytes
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer_a]
 lea rsi,[rel expected_text]
 mov edx,expected_text_end-expected_text
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-NEG-011 — unresolved nodes block emission before byte zero.
scenario_4:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 mov edx,1
 call neboc_arch_backend_begin_module
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel backend_a+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_UNRESOLVED_NODE
 jne test_fail
 cmp qword [rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],0
 jne test_fail
 cmp qword [rel backend_a+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_READY
 jne test_fail
 mov edi,NEBOC_CODEGEN_ERROR_UNRESOLVED_NODE
 lea rsi,[rel expected_unresolved]
 mov edx,NEBOC_CODEGEN_DIAG_UNRESOLVED_NODE_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-SECURITY-012 — source text cannot become raw assembler.
scenario_5:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 call begin_function_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,7
 lea rdx,[rel source_injection]
 mov ecx,28
 call neboc_arch_backend_emit_text_bytes
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer_a]
 lea rsi,[rel expected_security]
 mov edx,expected_security_end-expected_security
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CODEGEN-DETERMINISM-013 — independent runs keep labels and hash stable.
scenario_6:
 call reset_all
 xor edx,edx
 call init_codegen_a
 test eax,eax
 jnz test_fail
 xor edx,edx
 call init_codegen_b
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call build_deterministic_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_b]
 call build_deterministic_module
 test eax,eax
 jnz test_fail
 mov rax,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 cmp rax,[rel writer_b+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 jne test_fail
 mov rax,[rel writer_a+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 test rax,rax
 jz test_fail
 cmp rax,[rel writer_b+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 jne test_fail
 mov rax,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET]
 test rax,rax
 jz test_fail
 cmp rax,[rel writer_b+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET]
 jne test_fail
 mov rcx,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 lea rsi,[rel output_a]
 lea rdi,[rel output_b]
 repe cmpsb
 jne test_fail
 lea rdi,[rel output_a]
 mov rsi,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 lea rdx,[rel label_fn_7]
 mov ecx,9
 call contains_bytes
 test eax,eax
 jz test_fail
 lea rdi,[rel output_a]
 mov rsi,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 lea rdx,[rel label_int_3]
 mov ecx,10
 call contains_bytes
 test eax,eax
 jz test_fail
 lea rdi,[rel output_a]
 mov rsi,[rel writer_a+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 lea rdx,[rel label_text_5]
 mov ecx,11
 call contains_bytes
 test eax,eax
 jz test_fail
 inc qword [rel writer_a+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET]
 lea rdi,[rel writer_a]
 call neboc_assembly_writer_validate
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne test_fail
 cmp qword [rel writer_a+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_HASH_MISMATCH
 jne test_fail
 jmp test_pass

; Infrastructure — the backend consumes one frozen MF030 lowering plan.
scenario_7:
 call reset_all
 call setup_fake_lowering
 test eax,eax
 jnz test_fail
 lea rdx,[rel lowering_table]
 call init_codegen_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 mov esi,1
 call neboc_arch_backend_emit_plan
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer_a]
 lea rsi,[rel expected_plan]
 mov edx,expected_plan_end-expected_plan
 call compare_output
 test eax,eax
 jnz test_fail
 jmp test_pass

; Infrastructure — a mutated/unsupported TargetContext cannot select backend.
scenario_8:
 call reset_all
 call init_target_a
 test eax,eax
 jnz test_fail
 mov qword [rel context_a+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],2
 lea rdi,[rel writer_a]
 lea rsi,[rel output_a]
 mov edx,OUTPUT_CAPACITY
 call neboc_assembly_writer_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel backend_a]
 lea rsi,[rel context_a]
 xor edx,edx
 lea rcx,[rel writer_a]
 call neboc_arch_backend_init
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne test_fail
 cmp qword [rel backend_a+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_TARGET_MISMATCH
 jne test_fail
 cmp qword [rel backend_a+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_EMPTY
 jne test_fail
 jmp test_pass

; Infrastructure — writer limit failure is transactional.
scenario_9:
 call reset_all
 call init_target_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel small_writer]
 lea rsi,[rel small_output]
 mov edx,SMALL_CAPACITY
 call neboc_assembly_writer_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel small_backend]
 lea rsi,[rel context_a]
 xor edx,edx
 lea rcx,[rel small_writer]
 call neboc_arch_backend_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel small_backend]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel small_backend+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jne test_fail
 cmp qword [rel small_writer+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],0
 jne test_fail
 cmp qword [rel small_backend+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_READY
 jne test_fail
 jmp test_pass

; RDX carries optional frozen lowering table pointer.
init_codegen_a:
 push rdx
 call init_target_a
 pop rdx
 test eax,eax
 jnz .done
 push rdx
 lea rdi,[rel writer_a]
 lea rsi,[rel output_a]
 mov edx,OUTPUT_CAPACITY
 call neboc_assembly_writer_init
 pop rdx
 test eax,eax
 jnz .done
 sub rsp,8
 lea rdi,[rel backend_a]
 lea rsi,[rel context_a]
 lea rcx,[rel writer_a]
 call neboc_arch_backend_init
 add rsp,8
.done:
 ret

init_codegen_b:
 push rdx
 call init_target_b
 pop rdx
 test eax,eax
 jnz .done
 push rdx
 lea rdi,[rel writer_b]
 lea rsi,[rel output_b]
 mov edx,OUTPUT_CAPACITY
 call neboc_assembly_writer_init
 pop rdx
 test eax,eax
 jnz .done
 sub rsp,8
 lea rdi,[rel backend_b]
 lea rsi,[rel context_b]
 lea rcx,[rel writer_b]
 call neboc_arch_backend_init
 add rsp,8
.done:
 ret

init_target_a:
 sub rsp,8
 lea rdi,[rel layout_a]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .done
 lea rdi,[rel target_request_a]
 call fill_target_request
 lea rdi,[rel context_a]
 lea rsi,[rel layout_a]
 lea rdx,[rel target_request_a]
 call neboc_target_context_init
.done:
 add rsp,8
 ret

init_target_b:
 sub rsp,8
 lea rdi,[rel layout_b]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .done
 lea rdi,[rel target_request_b]
 call fill_target_request
 lea rdi,[rel context_b]
 lea rsi,[rel layout_b]
 lea rdx,[rel target_request_b]
 call neboc_target_context_init
.done:
 add rsp,8
 ret

fill_target_request:
 push rdi
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 pop rdi
 mov qword [rdi+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [rdi+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 mov qword [rdi+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rdi+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [rdi+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 mov qword [rdi+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 mov qword [rdi+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],NEBOC_TARGET_COMPONENT_REQUIRED_MASK
 ret

begin_function_a:
 sub rsp,8
 lea rdi,[rel backend_a]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz .done
 lea rdi,[rel backend_a]
 mov esi,1
 call neboc_arch_backend_begin_function
.done:
 add rsp,8
 ret

; RDI = backend pointer.
build_deterministic_module:
 push rbx
 mov rbx,rdi
 mov rdi,rbx
 mov esi,2
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov esi,7
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov esi,3
 mov rdx,-17
 call neboc_arch_backend_emit_int_literal
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov esi,5
 lea rdx,[rel text_stable]
 mov ecx,6
 call neboc_arch_backend_emit_text_bytes
 test eax,eax
 jnz .done
 mov rdi,rbx
 call neboc_arch_backend_end_module
.done:
 pop rbx
 ret

setup_fake_lowering:
 lea rdi,[rel lowering_table]
 mov ecx,NEBOC_LOWERING_TABLE_QWORDS
 call zero_region
 lea rdi,[rel lowering_plan]
 mov ecx,NEBOC_FUNCTION_PLAN_QWORDS
 call zero_region
 lea rdi,[rel lowering_operations]
 mov ecx,NEBOC_LOWERING_OPERATION_QWORDS*OPERATION_CAPACITY
 call zero_region
 lea rax,[rel lowering_plan]
 mov [rel lowering_table+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET],rax
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET],1
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_PLAN_CAPACITY_OFFSET],1
 lea rax,[rel lowering_operations]
 mov [rel lowering_table+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET],rax
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET],OPERATION_CAPACITY
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_OPERATION_CAPACITY_OFFSET],OPERATION_CAPACITY
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_HASH_OFFSET],1
 mov qword [rel lowering_table+NEBOC_LOWERING_TABLE_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_ID_OFFSET],1
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET],7
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_SOURCE_ORDER_OFFSET],1
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_FIRST_OPERATION_ID_OFFSET],1
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET],OPERATION_CAPACITY
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET],1
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_STATE_OFFSET],NEBOC_FUNCTION_PLAN_STATE_FROZEN
 mov qword [rel lowering_plan+NEBOC_FUNCTION_PLAN_HASH_OFFSET],1
 xor ecx,ecx
.operation_loop:
 cmp ecx,OPERATION_CAPACITY
 jae .done
 mov rax,rcx
 imul rax,NEBOC_LOWERING_OPERATION_SIZE
 lea rdi,[rel lowering_operations]
 add rdi,rax
 lea rax,[rcx+1]
 mov [rdi+NEBOC_LOWERING_OPERATION_ID_OFFSET],rax
 mov qword [rdi+NEBOC_LOWERING_OPERATION_PLAN_ID_OFFSET],1
 mov [rdi+NEBOC_LOWERING_OPERATION_KIND_OFFSET],rax
 mov [rdi+NEBOC_LOWERING_OPERATION_SOURCE_ORDER_OFFSET],rax
 mov qword [rdi+NEBOC_LOWERING_OPERATION_HASH_OFFSET],1
 inc ecx
 jmp .operation_loop
.done:
 xor eax,eax
 ret

compare_output:
 cmp qword [rdi+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_SEALED
 jne .bad
 cmp [rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rdx
 jne .bad
 cmp qword [rdi+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET],0
 je .bad
 mov rcx,rdx
 mov rdi,[rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 xchg rdi,rsi
 ; RDI expected, RSI actual after xchg; byte equality is symmetric.
 repe cmpsb
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

expect_diag:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov edi,ebx
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_codegen_diagnostic_name
 test eax,eax
 jnz .bad
 cmp [rel diag_len],r13
 jne .bad
 mov rdi,[rel diag_ptr]
 mov rsi,r12
 mov rcx,r13
 repe cmpsb
 jne .bad
 xor eax,eax
 pop r13
 pop r12
 pop rbx
 ret
.bad:
 mov eax,1
 pop r13
 pop r12
 pop rbx
 ret

; contains_bytes(haystack*, haystack_len, needle*, needle_len) -> EAX 1/0
contains_bytes:
 test rcx,rcx
 jz .found
 cmp rsi,rcx
 jb .not_found
 xor r8d,r8d
.outer:
 mov rax,rsi
 sub rax,rcx
 cmp r8,rax
 ja .not_found
 xor r9d,r9d
.inner:
 cmp r9,rcx
 jae .found
 mov r10,r8
 add r10,r9
 mov al,[rdi+r10]
 cmp al,[rdx+r9]
 jne .next
 inc r9
 jmp .inner
.next:
 inc r8
 jmp .outer
.found:
 mov eax,1
 ret
.not_found:
 xor eax,eax
 ret

reset_all:
 lea rdi,[rel layout_a]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel context_a]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel target_request_a]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel writer_a]
 mov ecx,NEBOC_ASSEMBLY_WRITER_QWORDS
 call zero_region
 lea rdi,[rel backend_a]
 mov ecx,NEBOC_ARCH_BACKEND_QWORDS
 call zero_region
 lea rdi,[rel output_a]
 mov ecx,OUTPUT_CAPACITY/8
 call zero_region
 lea rdi,[rel layout_b]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel context_b]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel target_request_b]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel writer_b]
 mov ecx,NEBOC_ASSEMBLY_WRITER_QWORDS
 call zero_region
 lea rdi,[rel backend_b]
 mov ecx,NEBOC_ARCH_BACKEND_QWORDS
 call zero_region
 lea rdi,[rel output_b]
 mov ecx,OUTPUT_CAPACITY/8
 call zero_region
 lea rdi,[rel small_writer]
 mov ecx,NEBOC_ASSEMBLY_WRITER_QWORDS
 call zero_region
 lea rdi,[rel small_backend]
 mov ecx,NEBOC_ARCH_BACKEND_QWORDS
 call zero_region
 lea rdi,[rel small_output]
 mov ecx,SMALL_CAPACITY/8
 call zero_region
 mov qword [rel diag_ptr],0
 mov qword [rel diag_len],0
 ret

zero_region:
 xor eax,eax
.loop:
 test ecx,ecx
 jz .done
 mov [rdi],rax
 add rdi,8
 dec ecx
 jmp .loop
.done:
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
 hlt

test_fail:
 mov edi,1
 call neboc_host_process_exit
 hlt

test_usage:
 mov edi,2
 call neboc_host_process_exit
 hlt

section .note.GNU-stack noalloc noexec nowrite progbits
