; MODELO-CANONICO-DE-TEXT-LITERAIS-ABI-OWNERSHIP-ERROS-E-MEMORIA canonical bounded Text/Char/Bytes runtime.
bits 64
default rel
%include "runtime/textual/text_core.inc"

global neboc_text_type_id
global neboc_char_type_id
global neboc_bytes_type_id
global neboc_char_validate
global neboc_text_validate_descriptor
global neboc_text_view
global neboc_text_clone
global neboc_text_drop
global neboc_text_storage_class
global neboc_text_builder_init
global neboc_text_builder_append
global neboc_text_error_diagnostic
global neboc_text_limit_check

section .text
align 16
neboc_text_type_id:
 mov eax,nebo_text_core_TYPE_TEXT
 ret

align 16
neboc_char_type_id:
 mov eax,nebo_text_core_TYPE_CHAR
 ret

align 16
neboc_bytes_type_id:
 mov eax,nebo_text_core_TYPE_BYTES
 ret

; edi = Unicode scalar candidate. eax = typed status.
align 16
neboc_char_validate:
 cmp edi,0x10ffff
 ja .invalid
 cmp edi,0xd800
 jb .ok
 cmp edi,0xdfff
 jbe .invalid
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_TEXT_ERROR_INVALID_CHAR
 ret

; rdi = descriptor. Empty Text permits a null data pointer; non-empty Text does not.
align 16
neboc_text_validate_descriptor:
 test rdi,rdi
 jz .null
 mov rax,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 test rax,~NEBO_TEXT_FLAG_MASK
 jnz .flags
 cmp qword [rdi+NEBO_TEXT_LENGTH_OFFSET],0
 je .valid
 cmp qword [rdi+NEBO_TEXT_DATA_OFFSET],0
 je .null
.valid:
 xor eax,eax
 ret
.null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.flags:
 mov eax,NEBO_TEXT_ERROR_INVALID_FLAGS
 ret

; rdi=source descriptor, rsi=start byte, rdx=length, rcx=out descriptor.
; The output is committed only after every bound and pointer check succeeds.
align 16
neboc_text_view:
 test rdi,rdi
 jz .view_null
 test rcx,rcx
 jz .view_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rsi,r8
 ja .view_bounds
 mov r9,rsi
 add r9,rdx
 jc .view_bounds
 cmp r9,r8
 ja .view_bounds
 mov r10,[rdi+NEBO_TEXT_DATA_OFFSET]
 test rdx,rdx
 jz .view_commit
 test r10,r10
 jz .view_null
.view_commit:
 add r10,rsi
 mov r11,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r10
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],rdx
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],r11
 mov [rcx+NEBO_TEXT_VIEW_SOURCE_OFFSET],rdi
 xor eax,eax
 ret
.view_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.view_bounds:
 mov eax,NEBO_TEXT_ERROR_BOUNDS
 ret

; rdi=source descriptor, rsi=destination bytes, rdx=capacity, rcx=out descriptor.
align 16
neboc_text_clone:
 test rdi,rdi
 jz .clone_null
 test rcx,rcx
 jz .clone_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r8,rdx
 ja .clone_capacity
 mov r11,rsi
 test r8,r8
 jz .clone_commit
 test rsi,rsi
 jz .clone_null
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 test r9,r9
 jz .clone_null
 push rdi
 mov rdi,rsi
 mov rsi,r9
 mov r10,rcx
 mov rcx,r8
 rep movsb
 mov rcx,r10
 pop rdi
.clone_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r11
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],r8
 mov r9,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 and r9,NEBO_TEXT_FLAG_VALID_UTF8 | NEBO_TEXT_FLAG_ASCII
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],r9
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.clone_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.clone_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; rdi=owned descriptor. Drop is idempotent and clears all observable fields.
align 16
neboc_text_drop:
 test rdi,rdi
 jz .drop_null
 pxor xmm0,xmm0
 movdqu [rdi],xmm0
 movdqu [rdi+16],xmm0
 xor eax,eax
 ret
.drop_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

align 16
neboc_text_storage_class:
 test rdi,rdi
 jz .storage_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_STATIC
 jnz .storage_static
 cmp qword [rdi+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 je .storage_owned
 mov eax,NEBO_TEXT_STORAGE_BORROWED
 ret
.storage_static:
 mov eax,NEBO_TEXT_STORAGE_STATIC
 ret
.storage_owned:
 mov eax,NEBO_TEXT_STORAGE_OWNED
 ret
.storage_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=builder, rsi=caller buffer, rdx=capacity.
align 16
neboc_text_builder_init:
 test rdi,rdi
 jz .builder_null
 test rdx,rdx
 jz .builder_commit
 test rsi,rsi
 jz .builder_null
.builder_commit:
 mov [rdi+NEBO_BUILDER_DATA_OFFSET],rsi
 mov qword [rdi+NEBO_BUILDER_LENGTH_OFFSET],0
 mov [rdi+NEBO_BUILDER_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 ret
.builder_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=builder, rsi=input bytes, rdx=input length. No partial append on failure.
align 16
neboc_text_builder_append:
 test rdi,rdi
 jz .append_null
 mov r8,[rdi+NEBO_BUILDER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .append_capacity
 cmp r9,[rdi+NEBO_BUILDER_CAPACITY_OFFSET]
 ja .append_capacity
 test rdx,rdx
 jz .append_commit
 test rsi,rsi
 jz .append_null
 mov r10,[rdi+NEBO_BUILDER_DATA_OFFSET]
 test r10,r10
 jz .append_null
 add r10,r8
 mov rcx,rdx
 mov r11,rdi
 mov rdi,r10
 rep movsb
 mov rdi,r11
.append_commit:
 mov [rdi+NEBO_BUILDER_LENGTH_OFFSET],r9
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 ret
.append_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.append_capacity:
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_ERROR_CAPACITY
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; edi=typed Text status, eax=stable diagnostic id or zero for success/unknown.
align 16
neboc_text_error_diagnostic:
 xor eax,eax
 test edi,edi
 jz .diag_done
 cmp edi,NEBO_TEXT_ERROR_POLICY
 ja .diag_done
 lea eax,[rdi+NEBO_DIAG_TEXT_NULL-1]
.diag_done:
 ret

; rdi=requested Text bytes, rsi=requested builder bytes.
align 16
neboc_text_limit_check:
 cmp rdi,NEBO_TEXT_LIMIT_BYTES
 ja .limit
 cmp rsi,NEBO_TEXT_LIMIT_BUILDER_BYTES
 ja .limit
 xor eax,eax
 ret
.limit:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
