; Nebo Assembly — MF034 explicit NASM/GNU ld ToolchainDescriptor v0
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_context.inc"
%include "compiler/toolchain/toolchain_descriptor.inc"
extern neboc_target_context_validate

%macro TC_ARG 4
 mov qword [%1+NEBOC_TOOLCHAIN_INVOCATION_ARGV_PTRS_OFFSET+(%2)*8],%3
 mov qword [%1+NEBOC_TOOLCHAIN_INVOCATION_ARGV_LENS_OFFSET+(%2)*8],%4
%endmacro

section .rodata
tc_dash_f: db '-f',0
tc_elf64: db 'elf64',0
tc_wall: db '-Wall',0
tc_werror: db '-Werror',0
tc_dash_o: db '-o',0
tc_dash_m: db '-m',0
tc_elf_x86_64: db 'elf_x86_64',0
tc_nostdlib: db '-nostdlib',0
tc_dash_z: db '-z',0
tc_noexecstack: db 'noexecstack',0
tc_build_id_none: db '--build-id=none',0
tc_discard_all: db '-x',0
tc_dash_e: db '-e',0
tc_start: db '_start',0

section .text
NEBOC_ABI_FUNCTION neboc_toolchain_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 test r13,r13
 jz .invalid_return
 test r12,r12
 jz .invalid
 cmp qword [rbx+NEBOC_TOOLCHAIN_STATE_OFFSET],NEBOC_TOOLCHAIN_STATE_EMPTY
 jne .invalid
 mov qword [r13+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_NONE
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 jne .target
 mov rdi,[r13+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_PTR_OFFSET]
 mov rsi,[r13+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_LEN_OFFSET]
 call tc_validate_path
 test eax,eax
 jnz .assembler
 mov rdi,[r13+NEBOC_TOOLCHAIN_REQUEST_LINKER_PTR_OFFSET]
 mov rsi,[r13+NEBOC_TOOLCHAIN_REQUEST_LINKER_LEN_OFFSET]
 call tc_validate_path
 test eax,eax
 jnz .linker
 cmp qword [r13+NEBOC_TOOLCHAIN_REQUEST_RUNNER_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_TOOLCHAIN_REQUEST_REMOVER_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_TOOLCHAIN_REQUEST_FLAGS_OFFSET],NEBOC_TOOLCHAIN_REQUIRED_FLAGS
 jne .invalid
 mov [rbx+NEBOC_TOOLCHAIN_TARGET_OFFSET],r12
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_PTR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_ASSEMBLER_PTR_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_LEN_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_ASSEMBLER_LEN_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_LINKER_PTR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_LINKER_PTR_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_LINKER_LEN_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_LINKER_LEN_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_RUNNER_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_RUNNER_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_REMOVER_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_REMOVER_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_CONTEXT_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_CONTEXT_OFFSET],rax
 mov qword [rbx+NEBOC_TOOLCHAIN_STATE_OFFSET],NEBOC_TOOLCHAIN_STATE_READY
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_NASM_MAJOR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_NASM_MAJOR_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_NASM_MINOR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_NASM_MINOR_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_LD_MAJOR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_LD_MAJOR_OFFSET],rax
 mov rax,[r13+NEBOC_TOOLCHAIN_REQUEST_LD_MINOR_OFFSET]
 mov [rbx+NEBOC_TOOLCHAIN_LD_MINOR_OFFSET],rax
 mov qword [rbx+NEBOC_TOOLCHAIN_FLAGS_OFFSET],NEBOC_TOOLCHAIN_REQUIRED_FLAGS
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_NONE
 mov qword [rbx+NEBOC_TOOLCHAIN_INVOCATION_COUNT_OFFSET],0
 xor eax,eax
 jmp .done
.target:
 mov qword [r13+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_TARGET_MISMATCH
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.assembler:
 mov qword [r13+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_ASSEMBLER_MISSING
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_ASSEMBLER_MISSING
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.linker:
 mov qword [r13+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_LINKER_MISSING
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_LINKER_MISSING
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.invalid:
 mov qword [r13+NEBOC_TOOLCHAIN_REQUEST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_BAD_REQUEST
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_BAD_REQUEST
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_toolchain_validate
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_TOOLCHAIN_STATE_OFFSET],NEBOC_TOOLCHAIN_STATE_READY
 jne .invalid
 cmp qword [rbx+NEBOC_TOOLCHAIN_FLAGS_OFFSET],NEBOC_TOOLCHAIN_REQUIRED_FLAGS
 jne .invalid
 cmp qword [rbx+NEBOC_TOOLCHAIN_RUNNER_OFFSET],0
 je .invalid
 cmp qword [rbx+NEBOC_TOOLCHAIN_REMOVER_OFFSET],0
 je .invalid
 mov rdi,[rbx+NEBOC_TOOLCHAIN_TARGET_OFFSET]
 test rdi,rdi
 jz .invalid
 call neboc_target_context_validate
 test eax,eax
 jnz .invalid
 mov rdi,[rbx+NEBOC_TOOLCHAIN_ASSEMBLER_PTR_OFFSET]
 mov rsi,[rbx+NEBOC_TOOLCHAIN_ASSEMBLER_LEN_OFFSET]
 call tc_validate_path
 test eax,eax
 jnz .invalid
 mov rdi,[rbx+NEBOC_TOOLCHAIN_LINKER_PTR_OFFSET]
 mov rsi,[rbx+NEBOC_TOOLCHAIN_LINKER_LEN_OFFSET]
 call tc_validate_path
 test eax,eax
 jnz .invalid
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_NONE
 xor eax,eax
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 pop rbx
 ret

; probe_version_text(descriptor*, kind, text*, length, out_pair*)
NEBOC_ABI_FUNCTION neboc_toolchain_probe_version_text
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 test rbx,rbx
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 xor r9d,r9d
.find_digit:
 cmp r9,r14
 jae .bad_version
 movzx eax,byte [r13+r9]
 cmp al,'0'
 jb .next
 cmp al,'9'
 jbe .major_start
.next:
 inc r9
 jmp .find_digit
.major_start:
 xor r10d,r10d
.major_loop:
 cmp r9,r14
 jae .bad_version
 movzx eax,byte [r13+r9]
 cmp al,'.'
 je .minor_start
 cmp al,'0'
 jb .bad_version
 cmp al,'9'
 ja .bad_version
 imul r10,r10,10
 sub eax,'0'
 add r10,rax
 inc r9
 jmp .major_loop
.minor_start:
 inc r9
 xor r11d,r11d
 xor ecx,ecx
.minor_loop:
 cmp r9,r14
 jae .minor_done
 movzx eax,byte [r13+r9]
 cmp al,'0'
 jb .minor_done
 cmp al,'9'
 ja .minor_done
 imul r11,r11,10
 sub eax,'0'
 add r11,rax
 inc r9
 inc ecx
 jmp .minor_loop
.minor_done:
 test ecx,ecx
 jz .bad_version
 mov [r15],r10
 mov [r15+8],r11
 cmp r12,NEBOC_TOOLCHAIN_KIND_ASSEMBLER
 je .check_nasm
 cmp r12,NEBOC_TOOLCHAIN_KIND_LINKER
 jne .invalid
 mov rax,[rbx+NEBOC_TOOLCHAIN_LD_MAJOR_OFFSET]
 mov rdx,[rbx+NEBOC_TOOLCHAIN_LD_MINOR_OFFSET]
 jmp .compare
.check_nasm:
 mov rax,[rbx+NEBOC_TOOLCHAIN_NASM_MAJOR_OFFSET]
 mov rdx,[rbx+NEBOC_TOOLCHAIN_NASM_MINOR_OFFSET]
.compare:
 cmp r10,rax
 ja .ok
 jb .bad_version
 cmp r11,rdx
 jb .bad_version
.ok:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_NONE
 xor eax,eax
 jmp .done
.bad_version:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_VERSION_INCOMPATIBLE
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; build_assembler_invocation(desc*, asm_ptr, asm_len, obj_ptr, obj_len, invocation*)
NEBOC_ABI_FUNCTION neboc_toolchain_build_assembler_invocation
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 test r9,r9
 jz .invalid
 mov rdi,rbx
 call neboc_toolchain_validate
 test eax,eax
 jnz .invalid
 mov rdi,r12
 mov rsi,r13
 call tc_validate_path
 test eax,eax
 jnz .path
 mov rdi,r14
 mov rsi,r15
 call tc_validate_output_path
 test eax,eax
 jnz .path
 mov r10,[rsp]
 mov rdi,r10
 mov ecx,NEBOC_TOOLCHAIN_INVOCATION_QWORDS
 xor eax,eax
 rep stosq
 mov qword [r10+NEBOC_TOOLCHAIN_INVOCATION_KIND_OFFSET],NEBOC_TOOLCHAIN_KIND_ASSEMBLER
 mov qword [r10+NEBOC_TOOLCHAIN_INVOCATION_ARGC_OFFSET],8
 mov rax,[rbx+NEBOC_TOOLCHAIN_ASSEMBLER_PTR_OFFSET]
 mov rdx,[rbx+NEBOC_TOOLCHAIN_ASSEMBLER_LEN_OFFSET]
 TC_ARG r10,0,rax,rdx
 lea rax,[rel tc_dash_f]
 TC_ARG r10,1,rax,2
 lea rax,[rel tc_elf64]
 TC_ARG r10,2,rax,5
 lea rax,[rel tc_wall]
 TC_ARG r10,3,rax,5
 lea rax,[rel tc_werror]
 TC_ARG r10,4,rax,7
 lea rax,[rel tc_dash_o]
 TC_ARG r10,5,rax,2
 TC_ARG r10,6,r14,r15
 TC_ARG r10,7,r12,r13
 mov [r10+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_PTR_OFFSET],r14
 mov [r10+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_LEN_OFFSET],r15
 mov qword [r10+NEBOC_TOOLCHAIN_INVOCATION_STATE_OFFSET],NEBOC_TOOLCHAIN_INVOCATION_STATE_READY
 inc qword [rbx+NEBOC_TOOLCHAIN_INVOCATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.path:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_PATH_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; build_linker_invocation(desc*, object_ptr, object_len, runtime_ptr, runtime_len, executable_ptr, executable_len, invocation*)
NEBOC_ABI_FUNCTION neboc_toolchain_build_linker_invocation
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 mov rax,[rsp+80]
 mov [rsp+8],rax
 mov rax,[rsp+88]
 mov [rsp+16],rax
 test rax,rax
 jz .invalid
 mov rdi,rbx
 call neboc_toolchain_validate
 test eax,eax
 jnz .invalid
 mov rdi,r12
 mov rsi,r13
 call tc_validate_path
 test eax,eax
 jnz .path
 mov rdi,r14
 mov rsi,r15
 call tc_validate_path
 test eax,eax
 jnz .path
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call tc_validate_output_path
 test eax,eax
 jnz .path
 mov r11,[rsp+16]
 mov rdi,r11
 mov ecx,NEBOC_TOOLCHAIN_INVOCATION_QWORDS
 xor eax,eax
 rep stosq
 mov qword [r11+NEBOC_TOOLCHAIN_INVOCATION_KIND_OFFSET],NEBOC_TOOLCHAIN_KIND_LINKER
 mov qword [r11+NEBOC_TOOLCHAIN_INVOCATION_ARGC_OFFSET],14
 mov rax,[rbx+NEBOC_TOOLCHAIN_LINKER_PTR_OFFSET]
 mov rdx,[rbx+NEBOC_TOOLCHAIN_LINKER_LEN_OFFSET]
 TC_ARG r11,0,rax,rdx
 lea rax,[rel tc_dash_m]
 TC_ARG r11,1,rax,2
 lea rax,[rel tc_elf_x86_64]
 TC_ARG r11,2,rax,10
 lea rax,[rel tc_nostdlib]
 TC_ARG r11,3,rax,9
 lea rax,[rel tc_dash_z]
 TC_ARG r11,4,rax,2
 lea rax,[rel tc_noexecstack]
 TC_ARG r11,5,rax,11
 lea rax,[rel tc_build_id_none]
 TC_ARG r11,6,rax,15
 lea rax,[rel tc_discard_all]
 TC_ARG r11,7,rax,2
 lea rax,[rel tc_dash_e]
 TC_ARG r11,8,rax,2
 lea rax,[rel tc_start]
 TC_ARG r11,9,rax,6
 lea rax,[rel tc_dash_o]
 TC_ARG r11,10,rax,2
 mov rax,[rsp]
 mov rdx,[rsp+8]
 TC_ARG r11,11,rax,rdx
 TC_ARG r11,12,r12,r13
 TC_ARG r11,13,r14,r15
 mov rax,[rsp]
 mov [r11+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_PTR_OFFSET],rax
 mov rax,[rsp+8]
 mov [r11+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_LEN_OFFSET],rax
 mov qword [r11+NEBOC_TOOLCHAIN_INVOCATION_STATE_OFFSET],NEBOC_TOOLCHAIN_INVOCATION_STATE_READY
 inc qword [rbx+NEBOC_TOOLCHAIN_INVOCATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.path:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_PATH_INVALID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; execute(desc*, invocation*, result*) via structured callback, never shell text.
NEBOC_ABI_FUNCTION neboc_toolchain_execute
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r13,rsi
 mov r14,rdx
 test rbx,rbx
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rdi,rbx
 call neboc_toolchain_validate
 test eax,eax
 jnz .invalid
 cmp qword [r13+NEBOC_TOOLCHAIN_INVOCATION_STATE_OFFSET],NEBOC_TOOLCHAIN_INVOCATION_STATE_READY
 jne .invalid
 mov rax,[r13+NEBOC_TOOLCHAIN_INVOCATION_ARGC_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_TOOLCHAIN_MAX_ARGS
 ja .invalid
 mov rdi,[r13+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_PTR_OFFSET]
 mov rsi,[r13+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_LEN_OFFSET]
 call tc_validate_output_path
 test eax,eax
 jnz .invalid
 mov rdi,r14
 mov ecx,NEBOC_TOOLCHAIN_RESULT_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rbx+NEBOC_TOOLCHAIN_RUNNER_OFFSET]
 mov rdi,[rbx+NEBOC_TOOLCHAIN_CONTEXT_OFFSET]
 lea rsi,[r13+NEBOC_TOOLCHAIN_INVOCATION_ARGV_PTRS_OFFSET]
 lea rdx,[r13+NEBOC_TOOLCHAIN_INVOCATION_ARGV_LENS_OFFSET]
 mov rcx,[r13+NEBOC_TOOLCHAIN_INVOCATION_ARGC_OFFSET]
 mov r8,r14
 call rax
 test eax,eax
 jnz .runner_failed
 cmp qword [r14+NEBOC_TOOLCHAIN_RESULT_EXIT_CODE_OFFSET],0
 jne .process_failed
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_NONE
 xor eax,eax
 jmp .done
.runner_failed:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_RUNNER_FAILED
 jmp .cleanup
.process_failed:
 mov qword [rbx+NEBOC_TOOLCHAIN_LAST_ERROR_OFFSET],NEBOC_TOOLCHAIN_ERROR_PROCESS_FAILED
.cleanup:
 mov rax,[rbx+NEBOC_TOOLCHAIN_REMOVER_OFFSET]
 mov rdi,[rbx+NEBOC_TOOLCHAIN_CONTEXT_OFFSET]
 mov rsi,[r13+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_PTR_OFFSET]
 mov rdx,[r13+NEBOC_TOOLCHAIN_INVOCATION_OUTPUT_LEN_OFFSET]
 call rax
 inc qword [r14+NEBOC_TOOLCHAIN_RESULT_CLEANUP_COUNT_OFFSET]
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret


; Output paths are also single argv atoms, but may not escape their selected
; directory through a component equal to "..". Internal input paths keep the
; compatibility contract of tc_validate_path (for example build/bin/../obj/...).
tc_validate_output_path:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 call tc_validate_path
 test eax,eax
 jnz .bad
 xor ecx,ecx
 xor edx,edx
.scan:
 cmp rcx,r12
 jae .final_component
 cmp byte [rbx+rcx],'/'
 je .component
 inc rcx
 jmp .scan
.component:
 mov r8,rcx
 sub r8,rdx
 cmp r8,2
 jne .next_component
 cmp byte [rbx+rdx],'.'
 jne .next_component
 cmp byte [rbx+rdx+1],'.'
 je .bad
.next_component:
 inc rcx
 mov rdx,rcx
 jmp .scan
.final_component:
 mov r8,r12
 sub r8,rdx
 cmp r8,2
 jne .ok
 cmp byte [rbx+rdx],'.'
 jne .ok
 cmp byte [rbx+rdx+1],'.'
 je .bad
.ok:
 xor eax,eax
 add rsp,8
 pop r12
 pop rbx
 ret
.bad:
 mov eax,1
 add rsp,8
 pop r12
 pop rbx
 ret

; Path is a single argv atom: spaces accepted, leading '-' and embedded NUL/CR/LF rejected.
tc_validate_path:
 test rdi,rdi
 jz .bad
 test rsi,rsi
 jz .bad
 cmp rsi,NEBOC_TOOLCHAIN_MAX_PATH
 ja .bad
 cmp byte [rdi],'-'
 je .bad
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 mov al,[rdi+rcx]
 test al,al
 jz .bad
 cmp al,10
 je .bad
 cmp al,13
 je .bad
 inc rcx
 jmp .loop
.ok:
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
