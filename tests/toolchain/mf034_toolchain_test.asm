; Nebo Assembly — MF034 Format/Runtime/Toolchain scenarios
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/format/elf64/format_adapter.inc"
%include "compiler/toolchain/toolchain_descriptor.inc"
%include "compiler/codegen/runtime/runtime_lowering.inc"
%include "runtime/core/runtime_core.inc"

extern neboc_data_layout_init_first_target
extern neboc_target_context_init
extern neboc_assembly_writer_init
extern neboc_assembly_writer_append_bytes
extern neboc_arch_backend_init
extern neboc_arch_backend_begin_module
extern neboc_arch_backend_begin_function
extern neboc_arch_backend_end_module
extern neboc_abi_adapter_init
extern neboc_abi_signature_init
extern neboc_abi_adapter_begin_function
extern neboc_abi_adapter_emit_return
extern neboc_format_adapter_init
extern neboc_format_adapter_validate
extern neboc_format_adapter_emit_entry_prelude
extern neboc_toolchain_init
extern neboc_toolchain_probe_version_text
extern neboc_toolchain_build_assembler_invocation
extern neboc_toolchain_build_linker_invocation
extern neboc_toolchain_execute
extern neboc_runtime_lowering_init
extern neboc_runtime_lowering_emit_default_console
extern neboc_runtime_lowering_emit_named_console
extern neboc_runtime_lowering_emit_anonymous_scan
extern nebo_runtime_abi_version
extern nebo_runtime_text_equal
extern neboc_host_process_exit

global _start
%define OUTPUT_CAPACITY 32768

section .rodata
assembler_path: db '/usr/bin/nasm',0
linker_path: db '/usr/bin/ld',0
asm_path: db 'build/tmp/module.asm',0
obj_path: db 'build/tmp/module.o',0
runtime_path: db 'build/tmp/runtime_core.o',0
exe_path: db 'build/tmp/program',0
space_path: db 'build/tmp dir/input file.asm',0
space_obj: db 'build/tmp dir/output file.o',0
inject_path: db '-Ievil',0
nasm_version: db 'NASM version 2.16.01'
ld_version: db 'GNU ld (GNU Binutils) 2.42'
fake_stderr: db 'simulated tool failure'
format_needle_start: db 'global _start',10
format_needle_start_end:
format_needle_start_bridge: db 'extern nebo_runtime_start',10
format_needle_start_bridge_end:
format_needle_entry: db '_start:',10,'    lea rdi, [rel nebo_fn_1]',10,'    mov rsi, rsp',10,'    call nebo_runtime_start',10
format_needle_entry_end:
function_body: db '    xor eax, eax',10,'    ret',10
function_body_end:
expected_default: incbin "tests/toolchain/goldens/008-default-console.asm"
expected_default_end:
expected_named: incbin "tests/toolchain/goldens/009-named-console.asm"
expected_named_end:
expected_scan: incbin "tests/toolchain/goldens/010-anonymous-scan.asm"
expected_scan_end:
text_a_bytes: db 'Nebo'
text_b_bytes: db 'Nebo'
text_c_bytes: db 'Neba'

section .data align=8
text_a: dq text_a_bytes,4
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_b: dq text_b_bytes,4
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_c: dq text_c_bytes,4
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=16
layout: resb NEBOC_DATA_LAYOUT_SIZE
context: resb NEBOC_TARGET_CONTEXT_SIZE
target_request: resb NEBOC_TARGET_REQUEST_SIZE
writer: resb NEBOC_ASSEMBLY_WRITER_SIZE
backend: resb NEBOC_ARCH_BACKEND_SIZE
format: resb NEBOC_FORMAT_ADAPTER_SIZE
adapter: resb NEBOC_ABI_ADAPTER_SIZE
abi_request: resb NEBOC_ABI_REQUEST_SIZE
signature: resb NEBOC_ABI_SIGNATURE_SIZE
runtime_lowering: resb NEBOC_RUNTIME_LOWERING_SIZE
output: resb OUTPUT_CAPACITY
saved_output: resb OUTPUT_CAPACITY
saved_length: resq 1
saved_hash: resq 1
tool_request: resb NEBOC_TOOLCHAIN_REQUEST_SIZE
toolchain: resb NEBOC_TOOLCHAIN_SIZE
invocation: resb NEBOC_TOOLCHAIN_INVOCATION_SIZE
result: resb NEBOC_TOOLCHAIN_RESULT_SIZE
fake_context: resq 6
version_pair: resq 2

section .text
_start:
 mov rax,[rsp]
 cmp rax,1
 je test_pass
 cmp rax,2
 jne test_usage
 mov rdi,[rsp+16]
 call parse_scenario
 cmp eax,1
 jb test_usage
 cmp eax,14
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
 cmp eax,9
 je scenario_9
 cmp eax,10
 je scenario_10
 cmp eax,11
 je scenario_11
 cmp eax,12
 je scenario_12
 cmp eax,13
 je scenario_13
 jmp scenario_14

; FORMAT-CONTRACT-009
scenario_1:
 call reset_all
 call build_format_module
 test eax,eax
 jnz test_fail
 lea rdi,[rel format]
 call neboc_format_adapter_validate
 test eax,eax
 jnz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel format_needle_start]
 mov ecx,format_needle_start_end-format_needle_start
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel format_needle_start_bridge]
 mov ecx,format_needle_start_bridge_end-format_needle_start_bridge
 call writer_contains
 test eax,eax
 jz test_fail
 lea rdi,[rel writer]
 lea rdx,[rel format_needle_entry]
 mov ecx,format_needle_entry_end-format_needle_entry
 call writer_contains
 test eax,eax
 jz test_fail
 jmp test_pass

; FORMAT-CONTRACT-010 / Runtime core no C contract
scenario_2:
 cmp qword [rel nebo_runtime_abi_version],NEBO_RUNTIME_ABI_VERSION_V0
 jne test_fail
 lea rdi,[rel text_a]
 lea rsi,[rel text_b]
 call nebo_runtime_text_equal
 cmp eax,1
 jne test_fail
 lea rdi,[rel text_a]
 lea rsi,[rel text_c]
 call nebo_runtime_text_equal
 test eax,eax
 jnz test_fail
 jmp test_pass

; FORMAT-DETERMINISM-011
scenario_3:
 call reset_all
 call build_format_module
 test eax,eax
 jnz test_fail
 mov rax,[rel writer+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rel saved_length],rax
 mov rax,[rel writer+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 mov [rel saved_hash],rax
 mov rcx,[rel saved_length]
 lea rsi,[rel output]
 lea rdi,[rel saved_output]
 cld
 rep movsb
 call reset_codegen
 call build_format_module
 test eax,eax
 jnz test_fail
 mov rax,[rel writer+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 cmp rax,[rel saved_length]
 jne test_fail
 mov rax,[rel writer+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 cmp rax,[rel saved_hash]
 jne test_fail
 mov rcx,[rel saved_length]
 lea rsi,[rel output]
 lea rdi,[rel saved_output]
 repe cmpsb
 jne test_fail
 jmp test_pass

; TOOLCHAIN-CONTRACT-001
scenario_4:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 lea rdi,[rel toolchain]
 mov esi,NEBOC_TOOLCHAIN_KIND_ASSEMBLER
 lea rdx,[rel nasm_version]
 mov ecx,20
 lea r8,[rel version_pair]
 call neboc_toolchain_probe_version_text
 test eax,eax
 jnz test_fail
 cmp qword [rel version_pair],2
 jne test_fail
 cmp qword [rel version_pair+8],16
 jne test_fail
 jmp test_pass

; TOOLCHAIN-CONTRACT-002
scenario_5:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 lea rdi,[rel toolchain]
 mov esi,NEBOC_TOOLCHAIN_KIND_LINKER
 lea rdx,[rel ld_version]
 mov ecx,26
 lea r8,[rel version_pair]
 call neboc_toolchain_probe_version_text
 test eax,eax
 jnz test_fail
 cmp qword [rel version_pair],2
 jne test_fail
 cmp qword [rel version_pair+8],42
 jne test_fail
 jmp test_pass

; TOOLCHAIN-NEG-003
scenario_6:
 call reset_all
 call init_target
 test eax,eax
 jnz test_fail
 lea rdi,[rel tool_request]
 call fill_tool_request
 mov qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_PTR_OFFSET],0
 mov qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_LEN_OFFSET],0
 lea rdi,[rel toolchain]
 lea rsi,[rel context]
 lea rdx,[rel tool_request]
 call neboc_toolchain_init
 cmp eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jne test_fail
 cmp qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_ASSEMBLER_MISSING
 jne test_fail
 jmp test_pass

; TOOLCHAIN-NEG-004
scenario_7:
 call reset_all
 call init_target
 test eax,eax
 jnz test_fail
 lea rdi,[rel tool_request]
 call fill_tool_request
 mov qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_LINKER_PTR_OFFSET],0
 mov qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_LINKER_LEN_OFFSET],0
 lea rdi,[rel toolchain]
 lea rsi,[rel context]
 lea rdx,[rel tool_request]
 call neboc_toolchain_init
 cmp eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jne test_fail
 cmp qword [rel tool_request+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_LINKER_MISSING
 jne test_fail
 jmp test_pass

; TOOLCHAIN-NEG-005
scenario_8:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 mov qword [rel fake_context],1
 lea rdi,[rel toolchain]
 lea rsi,[rel asm_path]
 mov edx,20
 lea rcx,[rel obj_path]
 mov r8d,18
 lea r9,[rel invocation]
 call neboc_toolchain_build_assembler_invocation
 test eax,eax
 jnz test_fail
 lea rdi,[rel toolchain]
 lea rsi,[rel invocation]
 lea rdx,[rel result]
 call neboc_toolchain_execute
 cmp eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jne test_fail
 cmp qword [rel result+NEBOC_TOOLCHAIN_RESULT_STDERR_LEN_OFFSET],22
 jne test_fail
 cmp qword [rel result+NEBOC_TOOLCHAIN_RESULT_CLEANUP_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel fake_context+16],1
 jne test_fail
 jmp test_pass

; TOOLCHAIN-NEG-006
scenario_9:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 mov qword [rel fake_context],1
 lea rdi,[rel toolchain]
 lea rsi,[rel obj_path]
 mov edx,18
 lea rcx,[rel runtime_path]
 mov r8d,24
 lea r9,[rel exe_path]
 lea rax,[rel invocation]
 push rax
 push 17
 call neboc_toolchain_build_linker_invocation
 add rsp,16
 test eax,eax
 jnz test_fail
 cmp qword [rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGC_OFFSET],15
 jne test_fail
 cmp qword [rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_LENS_OFFSET+7*8],2
 jne test_fail
 mov rax,[rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_PTRS_OFFSET+7*8]
 cmp word [rax],0x782d
 jne test_fail
 cmp qword [rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_LENS_OFFSET+14*8],13
 jne test_fail
 mov rax,[rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_PTRS_OFFSET+14*8]
 mov rdx,0x6365732d63672d2d
 cmp qword [rax],rdx
 jne test_fail
 cmp dword [rax+8],0x6e6f6974
 jne test_fail
 cmp word [rax+12],0x73
 jne test_fail
 lea rdi,[rel toolchain]
 lea rsi,[rel invocation]
 lea rdx,[rel result]
 call neboc_toolchain_execute
 cmp eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jne test_fail
 cmp qword [rel result+NEBOC_TOOLCHAIN_RESULT_CLEANUP_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel fake_context+16],1
 jne test_fail
 jmp test_pass

; TOOLCHAIN-SECURITY-007
scenario_10:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 lea rdi,[rel toolchain]
 lea rsi,[rel space_path]
 mov edx,28
 lea rcx,[rel space_obj]
 mov r8d,27
 lea r9,[rel invocation]
 call neboc_toolchain_build_assembler_invocation
 test eax,eax
 jnz test_fail
 cmp qword [rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_LENS_OFFSET+7*8],28
 jne test_fail
 mov rax,[rel invocation+NEBOC_TOOLCHAIN_INVOCATION_ARGV_PTRS_OFFSET+7*8]
 lea rdx,[rel space_path]
 cmp rax,rdx
 jne test_fail
 lea rdi,[rel toolchain]
 lea rsi,[rel invocation]
 lea rdx,[rel result]
 call neboc_toolchain_execute
 test eax,eax
 jnz test_fail
 cmp qword [rel fake_context+24],8
 jne test_fail
 jmp test_pass

; TOOLCHAIN-SECURITY-008
scenario_11:
 call reset_all
 call init_toolchain
 test eax,eax
 jnz test_fail
 lea rdi,[rel toolchain]
 lea rsi,[rel inject_path]
 mov edx,6
 lea rcx,[rel obj_path]
 mov r8d,18
 lea r9,[rel invocation]
 call neboc_toolchain_build_assembler_invocation
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 cmp qword [rel fake_context+8],0
 jne test_fail
 jmp test_pass

scenario_12:
 mov edi,1
 lea rsi,[rel expected_default]
 mov edx,expected_default_end-expected_default
 call build_runtime_case
 test eax,eax
 jnz test_fail
 jmp test_pass
scenario_13:
 mov edi,2
 lea rsi,[rel expected_named]
 mov edx,expected_named_end-expected_named
 call build_runtime_case
 test eax,eax
 jnz test_fail
 jmp test_pass
scenario_14:
 mov edi,3
 lea rsi,[rel expected_scan]
 mov edx,expected_scan_end-expected_scan
 call build_runtime_case
 test eax,eax
 jnz test_fail
 jmp test_pass

build_format_module:
 push rbx
 call init_codegen_base
 test eax,eax
 jnz .done
 lea rdi,[rel format]
 lea rsi,[rel context]
 lea rdx,[rel backend]
 lea rcx,[rel writer]
 call neboc_format_adapter_init
 test eax,eax
 jnz .done
 lea rdi,[rel format]
 mov esi,1
 call neboc_format_adapter_emit_entry_prelude
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .done
 lea rdi,[rel writer]
 lea rsi,[rel function_body]
 mov edx,function_body_end-function_body
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
.done:
 pop rbx
 ret

; EDI mode, RSI expected ptr, EDX expected length
build_runtime_case:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 call reset_all
 call init_codegen_base
 test eax,eax
 jnz .bad
 lea rdi,[rel abi_request]
 call fill_abi_request
 lea rdi,[rel adapter]
 lea rsi,[rel context]
 lea rdx,[rel backend]
 lea rcx,[rel abi_request]
 call neboc_abi_adapter_init
 test eax,eax
 jnz .bad
 lea rdi,[rel signature]
 mov esi,1
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 mov r9d,1
 call neboc_abi_signature_init
 test eax,eax
 jnz .bad
 lea rdi,[rel backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel adapter]
 lea rsi,[rel signature]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel runtime_lowering]
 lea rsi,[rel adapter]
 call neboc_runtime_lowering_init
 test eax,eax
 jnz .bad
 cmp ebx,1
 je .default
 cmp ebx,2
 je .named
 lea rdi,[rel runtime_lowering]
 mov esi,9
 call neboc_runtime_lowering_emit_anonymous_scan
 jmp .after
.default:
 lea rdi,[rel runtime_lowering]
 call neboc_runtime_lowering_emit_default_console
 jmp .after
.named:
 lea rdi,[rel runtime_lowering]
 mov esi,7
 call neboc_runtime_lowering_emit_named_console
.after:
 test eax,eax
 jnz .bad
 cmp qword [rel runtime_lowering+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET],1
 jne .bad
 cmp qword [rel adapter+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],1
 jne .bad
 lea rdi,[rel adapter]
 xor esi,esi
 call neboc_abi_adapter_emit_return
 test eax,eax
 jnz .bad
 lea rdi,[rel backend]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz .bad
 lea rdi,[rel writer]
 mov rdx,r12
 mov rcx,r13
 call writer_contains
 xor eax,1
 jmp .done
.bad:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

init_codegen_base:
 push rbx
 call init_target
 test eax,eax
 jnz .done
 lea rdi,[rel writer]
 lea rsi,[rel output]
 mov edx,OUTPUT_CAPACITY
 call neboc_assembly_writer_init
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 lea rsi,[rel context]
 xor edx,edx
 lea rcx,[rel writer]
 call neboc_arch_backend_init
 test eax,eax
 jnz .done
 lea rdi,[rel backend]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
.done:
 pop rbx
 ret

init_target:
 push rbx
 lea rdi,[rel layout]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .done
 lea rdi,[rel target_request]
 call fill_target_request
 lea rdi,[rel context]
 lea rsi,[rel layout]
 lea rdx,[rel target_request]
 call neboc_target_context_init
.done:
 pop rbx
 ret

init_toolchain:
 push rbx
 call init_target
 test eax,eax
 jnz .done
 lea rdi,[rel tool_request]
 call fill_tool_request
 lea rdi,[rel toolchain]
 lea rsi,[rel context]
 lea rdx,[rel tool_request]
 call neboc_toolchain_init
.done:
 pop rbx
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

fill_abi_request:
 push rdi
 mov ecx,NEBOC_ABI_REQUEST_QWORDS
 call zero_region
 pop rdi
 mov qword [rdi+NEBOC_ABI_REQUEST_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 mov qword [rdi+NEBOC_ABI_REQUEST_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 mov qword [rdi+NEBOC_ABI_REQUEST_TARGET_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rdi+NEBOC_ABI_REQUEST_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 mov qword [rdi+NEBOC_ABI_REQUEST_FLAGS_OFFSET],NEBOC_ABI_REQUEST_REQUIRED_FLAGS
 ret

fill_tool_request:
 push rdi
 mov ecx,NEBOC_TOOLCHAIN_REQUEST_QWORDS
 call zero_region
 pop rdi
 lea rax,[rel assembler_path]
 mov [rdi+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_PTR_OFFSET],rax
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_LEN_OFFSET],13
 lea rax,[rel linker_path]
 mov [rdi+NEBOC_TOOLCHAIN_REQUEST_LINKER_PTR_OFFSET],rax
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_LINKER_LEN_OFFSET],11
 lea rax,[rel fake_runner]
 mov [rdi+NEBOC_TOOLCHAIN_REQUEST_RUNNER_OFFSET],rax
 lea rax,[rel fake_remover]
 mov [rdi+NEBOC_TOOLCHAIN_REQUEST_REMOVER_OFFSET],rax
 lea rax,[rel fake_context]
 mov [rdi+NEBOC_TOOLCHAIN_REQUEST_CONTEXT_OFFSET],rax
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_NASM_MAJOR_OFFSET],2
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_NASM_MINOR_OFFSET],16
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_LD_MAJOR_OFFSET],2
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_LD_MINOR_OFFSET],42
 mov qword [rdi+NEBOC_TOOLCHAIN_REQUEST_FLAGS_OFFSET],NEBOC_TOOLCHAIN_REQUIRED_FLAGS
 ret

; context, argv_ptrs, argv_lens, argc, result
fake_runner:
 inc qword [rdi+8]
 mov [rdi+24],rcx
 cmp qword [rdi],1
 jne .success
 mov qword [r8+NEBOC_TOOLCHAIN_RESULT_EXIT_CODE_OFFSET],1
 lea rax,[rel fake_stderr]
 mov [r8+NEBOC_TOOLCHAIN_RESULT_STDERR_PTR_OFFSET],rax
 mov qword [r8+NEBOC_TOOLCHAIN_RESULT_STDERR_LEN_OFFSET],22
 xor eax,eax
 ret
.success:
 mov qword [r8+NEBOC_TOOLCHAIN_RESULT_EXIT_CODE_OFFSET],0
 xor eax,eax
 ret
fake_remover:
 inc qword [rdi+16]
 xor eax,eax
 ret

writer_contains:
 mov rsi,[rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov rdi,[rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
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

parse_scenario:
 xor eax,eax
 movzx ecx,byte [rdi]
 cmp cl,'0'
 jb .bad
 cmp cl,'9'
 ja .bad
 sub ecx,'0'
 mov eax,ecx
 movzx ecx,byte [rdi+1]
 test cl,cl
 jz .done
 cmp cl,'0'
 jb .bad
 cmp cl,'9'
 ja .bad
 imul eax,eax,10
 sub ecx,'0'
 add eax,ecx
 cmp byte [rdi+2],0
 jne .bad
.done:
 ret
.bad:
 xor eax,eax
 ret

reset_all:
 sub rsp,8
 call reset_codegen
 lea rdi,[rel saved_output]
 mov ecx,OUTPUT_CAPACITY/8
 call zero_region
 mov qword [rel saved_length],0
 mov qword [rel saved_hash],0
 lea rdi,[rel tool_request]
 mov ecx,NEBOC_TOOLCHAIN_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel toolchain]
 mov ecx,NEBOC_TOOLCHAIN_QWORDS
 call zero_region
 lea rdi,[rel invocation]
 mov ecx,NEBOC_TOOLCHAIN_INVOCATION_QWORDS
 call zero_region
 lea rdi,[rel result]
 mov ecx,NEBOC_TOOLCHAIN_RESULT_QWORDS
 call zero_region
 lea rdi,[rel fake_context]
 mov ecx,6
 call zero_region
 lea rdi,[rel version_pair]
 mov ecx,2
 call zero_region
 add rsp,8
 ret
reset_codegen:
 sub rsp,8
 lea rdi,[rel layout]
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
 call zero_region
 lea rdi,[rel context]
 mov ecx,NEBOC_TARGET_CONTEXT_QWORDS
 call zero_region
 lea rdi,[rel target_request]
 mov ecx,NEBOC_TARGET_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel writer]
 mov ecx,NEBOC_ASSEMBLY_WRITER_QWORDS
 call zero_region
 lea rdi,[rel backend]
 mov ecx,NEBOC_ARCH_BACKEND_QWORDS
 call zero_region
 lea rdi,[rel format]
 mov ecx,NEBOC_FORMAT_ADAPTER_QWORDS
 call zero_region
 lea rdi,[rel adapter]
 mov ecx,NEBOC_ABI_ADAPTER_QWORDS
 call zero_region
 lea rdi,[rel abi_request]
 mov ecx,NEBOC_ABI_REQUEST_QWORDS
 call zero_region
 lea rdi,[rel signature]
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
 call zero_region
 lea rdi,[rel runtime_lowering]
 mov ecx,NEBOC_RUNTIME_LOWERING_QWORDS
 call zero_region
 lea rdi,[rel output]
 mov ecx,OUTPUT_CAPACITY/8
 call zero_region
 add rsp,8
 ret
zero_region:
 xor eax,eax
 cld
 rep stosq
 ret

test_usage:
 mov edi,2
 jmp neboc_host_process_exit
test_fail:
 mov edi,1
 jmp neboc_host_process_exit
test_pass:
 xor edi,edi
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
