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
global neboc_text_copy
global neboc_text_clone
global neboc_text_borrow
global neboc_text_drop
global neboc_text_freeze
global neboc_text_storage_class
global neboc_text_builder_init
global neboc_text_builder_with_capacity
global neboc_text_builder_append
global neboc_text_builder_append_text
global neboc_text_builder_append_char
global neboc_text_builder_reserve
global neboc_text_builder_clear
global neboc_text_builder_freeze
global neboc_text_error_diagnostic
global neboc_text_limit_check
global neboc_text_runtime_contract

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
 and r11,~NEBO_TEXT_FLAG_STATIC
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

; rdi=source descriptor, rsi=out descriptor.  Only static and borrowed Text
; have a bounded shallow-copy contract.  OwnedText requires clone or move.
; The destination is untouched on every failure.
align 16
neboc_text_copy:
 test rdi,rdi
 jz .copy_null
 test rsi,rsi
 jz .copy_null
 cmp qword [rdi+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 je .copy_policy
 movdqu xmm0,[rdi]
 movdqu xmm1,[rdi+16]
 movdqu [rsi],xmm0
 movdqu [rsi+16],xmm1
 xor eax,eax
 ret
.copy_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.copy_policy:
 mov eax,NEBO_TEXT_ERROR_POLICY
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

; rdi=source descriptor, rsi=out descriptor.  A whole-value borrow is the
; bounded view [0, byteLength), tied to its source through the aux slot.
align 16
neboc_text_borrow:
 test rdi,rdi
 jz .borrow_null
 mov rdx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov rcx,rsi
 xor esi,esi
 jmp neboc_text_view
.borrow_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=owned descriptor. Drop is idempotent and clears all observable fields.
align 16
neboc_text_drop:
 test rdi,rdi
 jz .drop_null
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_STATIC
 jnz .drop_noop
 cmp qword [rdi+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 jne .drop_noop
 pxor xmm0,xmm0
 movdqu [rdi],xmm0
 movdqu [rdi+16],xmm0
.drop_noop:
 xor eax,eax
 ret
.drop_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; Text.freeze is the internal spelling for transferring a TextBuilder into an
; immutable descriptor.  It is intentionally the same operation as the
; builder receiver spelling below.
align 16
neboc_text_freeze:
 jmp neboc_text_builder_freeze

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

align 16
neboc_text_builder_with_capacity:
 cmp rdx,NEBO_TEXT_LIMIT_BUILDER_BYTES
 ja .with_capacity_limit
 jmp neboc_text_builder_init
.with_capacity_limit:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
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

; rdi=builder, rsi=immutable Text descriptor.
align 16
neboc_text_builder_append_text:
 test rsi,rsi
 jz .append_text_null
 mov rdx,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 mov rsi,[rsi+NEBO_TEXT_DATA_OFFSET]
 jmp neboc_text_builder_append
.append_text_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=builder, esi=Unicode scalar.  Encode into a local four-byte staging
; buffer, then use the same failure-atomic append path as Text.
align 16
neboc_text_builder_append_char:
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov edi,esi
 call neboc_char_validate
 test eax,eax
 jnz .append_char_done
 cmp edi,0x7f
 ja .append_char_two
 mov [rsp],dil
 mov edx,1
 jmp .append_char_commit
.append_char_two:
 cmp edi,0x7ff
 ja .append_char_three
 mov eax,edi
 shr eax,6
 or al,0xc0
 mov [rsp],al
 mov eax,edi
 and al,0x3f
 or al,0x80
 mov [rsp+1],al
 mov edx,2
 jmp .append_char_commit
.append_char_three:
 cmp edi,0xffff
 ja .append_char_four
 mov eax,edi
 shr eax,12
 or al,0xe0
 mov [rsp],al
 mov eax,edi
 shr eax,6
 and al,0x3f
 or al,0x80
 mov [rsp+1],al
 mov eax,edi
 and al,0x3f
 or al,0x80
 mov [rsp+2],al
 mov edx,3
 jmp .append_char_commit
.append_char_four:
 mov eax,edi
 shr eax,18
 or al,0xf0
 mov [rsp],al
 mov eax,edi
 shr eax,12
 and al,0x3f
 or al,0x80
 mov [rsp+1],al
 mov eax,edi
 shr eax,6
 and al,0x3f
 or al,0x80
 mov [rsp+2],al
 mov eax,edi
 and al,0x3f
 or al,0x80
 mov [rsp+3],al
 mov edx,4
.append_char_commit:
 mov rdi,rbx
 mov rsi,rsp
 call neboc_text_builder_append
.append_char_done:
 add rsp,16
 pop rbx
 ret

; rdi=builder, rsi=required total capacity.  The bounded no-libc profile does
; not allocate: reserve succeeds only when the caller-provided storage already
; satisfies the request, and never changes logical length.
align 16
neboc_text_builder_reserve:
 test rdi,rdi
 jz .reserve_null
 cmp rsi,NEBO_TEXT_LIMIT_BUILDER_BYTES
 ja .reserve_capacity
 cmp rsi,[rdi+NEBO_BUILDER_CAPACITY_OFFSET]
 ja .reserve_capacity
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 ret
.reserve_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.reserve_capacity:
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_ERROR_CAPACITY
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; Logical clear does not promise physical scrubbing; privacy-sensitive wiping
; is a separate policy surface.  Capacity and data ownership remain intact.
align 16
neboc_text_builder_clear:
 test rdi,rdi
 jz .clear_null
 mov qword [rdi+NEBO_BUILDER_LENGTH_OFFSET],0
 mov qword [rdi+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 ret
.clear_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=builder, rsi=out immutable descriptor.  Commit the descriptor only after
; validating the complete builder, then clear the builder to remove its mutable
; alias.  No allocation or libc ownership is hidden here.
align 16
neboc_text_builder_freeze:
 test rdi,rdi
 jz .freeze_null
 test rsi,rsi
 jz .freeze_null
 ; Reject any overlap between the output descriptor and the builder record.
 mov r10,rdi
 add r10,NEBO_BUILDER_SIZE
 jc .freeze_null
 mov r11,rsi
 add r11,NEBO_TEXT_DESCRIPTOR_SIZE
 jc .freeze_null
 cmp rsi,r10
 jae .freeze_builder_disjoint
 cmp rdi,r11
 jb .freeze_null
.freeze_builder_disjoint:
 mov r8,[rdi+NEBO_BUILDER_LENGTH_OFFSET]
 cmp r8,[rdi+NEBO_BUILDER_CAPACITY_OFFSET]
 ja .freeze_capacity
 mov r9,[rdi+NEBO_BUILDER_DATA_OFFSET]
 test r8,r8
 jz .freeze_data_disjoint
 test r9,r9
 jz .freeze_null
.freeze_data_disjoint:
 ; The immutable descriptor must also be disjoint from the complete mutable
 ; storage capacity, otherwise committing it would corrupt the frozen bytes.
 mov r10,r9
 add r10,[rdi+NEBO_BUILDER_CAPACITY_OFFSET]
 jc .freeze_capacity
 cmp rsi,r10
 jae .freeze_commit
 cmp r9,r11
 jb .freeze_null
.freeze_commit:
 mov [rsi+NEBO_TEXT_DATA_OFFSET],r9
 mov [rsi+NEBO_TEXT_LENGTH_OFFSET],r8
 mov qword [rsi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [rsi+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 pxor xmm0,xmm0
 movdqu [rdi],xmm0
 movdqu [rdi+16],xmm0
 xor eax,eax
 ret
.freeze_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.freeze_capacity:
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
 ja .diag_extended
 lea eax,[rdi+NEBO_DIAG_TEXT_NULL-1]
.diag_done:
 ret
.diag_extended:
 cmp edi,NEBO_TEXT_ERROR_INVALID_BYTE_INDEX
 je .diag_byte_index
 cmp edi,NEBO_TEXT_ERROR_INVALID_RANGE
 je .diag_range
 cmp edi,NEBO_TEXT_ERROR_EMPTY_SEPARATOR
 je .diag_separator
 cmp edi,NEBO_TEXT_PARSE_ERROR_EMPTY_INPUT
 jb .diag_done
 cmp edi,NEBO_TEXT_PARSE_ERROR_UNSUPPORTED_FORMAT
 ja .diag_done
 mov eax,edi
 sub eax,NEBO_TEXT_PARSE_ERROR_EMPTY_INPUT
 add eax,NEBO_DIAG_TEXT_PARSE_EMPTY_INPUT
 ret
.diag_byte_index:
 mov eax,NEBO_DIAG_TEXT_INVALID_BYTE_INDEX
 ret
.diag_range:
 mov eax,NEBO_DIAG_TEXT_INVALID_RANGE
 ret
.diag_separator:
 mov eax,NEBO_DIAG_TEXT_EMPTY_SEPARATOR
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

; TextRuntimeContract: EAX=ABI version, EDX=owned descriptor bytes,
; ECX=UTF-8 encoding id, R8D=feature mask, R9=MAX_TEXT_BYTES.
align 16
neboc_text_runtime_contract:
 mov eax,NEBO_TEXT_ABI_VERSION
 mov edx,NEBO_TEXT_DESCRIPTOR_SIZE
 mov ecx,NEBO_TEXT_ENCODING_UTF8
 mov r8d,NEBO_TEXT_RUNTIME_FEATURES
 mov r9,MAX_TEXT_BYTES
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
