; Nebo Assembly — deterministic NASM Intel text writer v0
;
; The writer owns no memory. Callers provide one fixed output buffer. Appends are
; checked and transactional at call granularity. Source Text is never accepted as
; raw Assembly by this layer; the Architecture Backend serializes source bytes as
; numeric db operands before calling the trusted append primitive.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/hash/fnv1a.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"

extern neboc_hash_fnv1a32

section .rodata
minus_byte: db '-'

section .text

; assembly_writer_init(writer*, output_buffer*, capacity)
NEBOC_ABI_FUNCTION neboc_assembly_writer_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_ASSEMBLY_WRITER_MAX_OUTPUT_BYTES
 ja .limit
 cmp qword [rdi+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_EMPTY
 jne .invalid
 mov [rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET],rsi
 mov [rdi+NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET],0
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_NONE
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_FLAGS_OFFSET],NEBOC_ASSEMBLY_WRITER_REQUIRED_FLAGS
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_RESERVED_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_LIMIT
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid:
 test rdi,rdi
 jz .invalid_return
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_ARGUMENT
.invalid_return:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; assembly_writer_validate(writer*)
; A sealed writer recomputes its canonical output hash and rejects tampering.
NEBOC_ABI_FUNCTION neboc_assembly_writer_validate
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 mov rax,[rbx+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 test rax,rax
 jz .invalid
 mov r12,[rbx+NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET]
 test r12,r12
 jz .invalid
 cmp r12,NEBOC_ASSEMBLY_WRITER_MAX_OUTPUT_BYTES
 ja .limit
 mov r13,[rbx+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 cmp r13,r12
 ja .limit
 cmp qword [rbx+NEBOC_ASSEMBLY_WRITER_FLAGS_OFFSET],NEBOC_ASSEMBLY_WRITER_REQUIRED_FLAGS
 jne .invalid
 mov rax,[rbx+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET]
 cmp rax,NEBOC_ASSEMBLY_WRITER_STATE_READY
 je .ready
 cmp rax,NEBOC_ASSEMBLY_WRITER_STATE_SEALED
 jne .state
 mov qword [rsp],0
 mov rdi,[rbx+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .invalid
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 jne .hash
 mov rdi,[rbx+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 mov rsi,r13
 call writer_count_lines
 cmp rax,[rbx+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET]
 jne .hash
 jmp .ok
.ready:
 cmp qword [rbx+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET],0
 jne .hash
 cmp qword [rbx+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET],0
 jne .hash
.ok:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_NONE
 xor eax,eax
 jmp .done
.state:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.hash:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_HASH_MISMATCH
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.limit:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 test rbx,rbx
 jz .invalid_return
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; assembly_writer_append_bytes(writer*, trusted_bytes*, length)
NEBOC_ABI_FUNCTION neboc_assembly_writer_append_bytes
 test rdi,rdi
 jz .invalid_return
 cmp qword [rdi+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .state
 test rdx,rdx
 jz .ok
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET]
 ja .limit
 mov r10,[rdi+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 test r10,r10
 jz .invalid
 add r10,r8
 jc .limit
 push rdi
 mov rdi,r10
 mov rcx,rdx
 cld
 rep movsb
 pop rdi
 mov [rdi+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],r9
.ok:
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_NONE
 xor eax,eax
 ret
.state:
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.limit:
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov qword [rdi+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; assembly_writer_append_u64_decimal(writer*, value)
NEBOC_ABI_FUNCTION neboc_assembly_writer_append_u64_decimal
 push rbx
 push r12
 push r13
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 lea r13,[rsp+32]
 mov rax,r12
 test rax,rax
 jnz .digits
 dec r13
 mov byte [r13],'0'
 jmp .append
.digits:
 mov ecx,10
.loop:
 xor edx,edx
 div rcx
 add dl,'0'
 dec r13
 mov [r13],dl
 test rax,rax
 jnz .loop
.append:
 lea rdx,[rsp+32]
 sub rdx,r13
 mov rdi,rbx
 mov rsi,r13
 call neboc_assembly_writer_append_bytes
 add rsp,32
 pop r13
 pop r12
 pop rbx
 ret

; assembly_writer_append_i64_decimal(writer*, signed_value)
NEBOC_ABI_FUNCTION neboc_assembly_writer_append_i64_decimal
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 test r12,r12
 jns .magnitude
 mov rdi,rbx
 lea rsi,[rel minus_byte]
 mov edx,1
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 neg r12
.magnitude:
 mov rdi,rbx
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
.done:
 pop r13
 pop r12
 pop rbx
 ret

; assembly_writer_finalize(writer*)
NEBOC_ABI_FUNCTION neboc_assembly_writer_finalize
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .state
 mov rdi,rbx
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .done
 mov qword [rsp],0
 mov rdi,[rbx+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 mov rsi,[rbx+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .hash
 mov rax,[rsp]
 mov [rbx+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET],rax
 mov rdi,[rbx+NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
 mov rsi,[rbx+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 call writer_count_lines
 mov [rbx+NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET],rax
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_SEALED
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_NONE
 xor eax,eax
 jmp .done
.state:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.hash:
 mov qword [rbx+NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET],NEBOC_ASSEMBLY_WRITER_ERROR_HASH_MISMATCH
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret


; writer_count_lines(buffer*, length) -> RAX
; Counts canonical LF-terminated Assembly lines. This is a local leaf helper.
writer_count_lines:
 xor eax,eax
 xor ecx,ecx
.line_loop:
 cmp rcx,rsi
 jae .line_done
 cmp byte [rdi+rcx],10
 jne .line_next
 inc rax
.line_next:
 inc rcx
 jmp .line_loop
.line_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
