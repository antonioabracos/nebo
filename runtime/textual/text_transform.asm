; TRANSFORMACAO-SLICING-SUBSTITUICAO-SPLIT-JOIN-E-PADDING bounded caller-owned Text transforms.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
global neboc_text_trim_ascii
global neboc_text_case_ascii
global neboc_text_slice_bytes
global neboc_text_take_drop
global neboc_text_normalize_newlines
global neboc_text_replace_once_byte
global neboc_text_replace_all_byte
global neboc_text_split_byte
global neboc_text_join_byte
global neboc_text_pad_ascii
global nebo_runtime_textual_text_concat
global nebo_runtime_textual_text_trim
global nebo_runtime_textual_text_trim_start
global nebo_runtime_textual_text_trim_end
global nebo_runtime_textual_text_lower
global nebo_runtime_textual_text_upper
global nebo_runtime_textual_text_byte_slice
global nebo_runtime_textual_text_take_bytes
global nebo_runtime_textual_text_drop_bytes
global nebo_runtime_textual_text_normalize_newlines
global nebo_runtime_textual_text_normalize_whitespace
global nebo_runtime_textual_text_replace_once
global nebo_runtime_textual_text_replace_all
global nebo_runtime_textual_text_split
global nebo_runtime_textual_text_join
global nebo_runtime_textual_text_split_join
global nebo_runtime_textual_text_pad_start
global nebo_runtime_textual_text_pad_end
section .text
%macro IS_SPACE 2
 cmp %1,' '
 je %2
 cmp %1,9
 je %2
 cmp %1,10
 je %2
 cmp %1,13
 je %2
%endmacro

; rdi=input descriptor, rsi=out view descriptor.
align 16
neboc_text_trim_ascii:
 test rdi,rdi
 jz .trim_null
 test rsi,rsi
 jz .trim_null
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov rdx,r9
 xor ecx,ecx
.trim_left:
 cmp rcx,r9
 jae .trim_commit
 mov al,[r8+rcx]
 IS_SPACE al,.trim_left_next
 jmp .trim_right_setup
.trim_left_next:
 inc rcx
 jmp .trim_left
.trim_right_setup:
.trim_right:
 cmp rdx,rcx
 jbe .trim_commit
 mov al,[r8+rdx-1]
 IS_SPACE al,.trim_right_next
 jmp .trim_commit
.trim_right_next:
 dec rdx
 jmp .trim_right
.trim_commit:
 sub rdx,rcx
 add r8,rcx
 mov [rsi+NEBO_TEXT_DATA_OFFSET],r8
 mov [rsi+NEBO_TEXT_LENGTH_OFFSET],rdx
 mov r8,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rsi+NEBO_TEXT_FLAGS_OFFSET],r8
 mov [rsi+NEBO_TEXT_AUX_OFFSET],rdi
 xor eax,eax
 ret
.trim_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=input, rsi=out bytes, rdx=capacity, rcx=case mode, r8=out descriptor.
align 16
neboc_text_case_ascii:
 test rdi,rdi
 jz .case_null
 test r8,r8
 jz .case_null
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r9,rdx
 ja .case_capacity
 test r9,r9
 jz .case_commit
 test rsi,rsi
 jz .case_null
 mov r10,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor edx,edx
.case_loop:
 mov al,[r10+rdx]
 test rcx,rcx
 jnz .case_upper
 cmp al,'A'
 jb .case_store
 cmp al,'Z'
 ja .case_store
 add al,32
 jmp .case_store
.case_upper:
 cmp al,'a'
 jb .case_store
 cmp al,'z'
 ja .case_store
 sub al,32
.case_store:
 mov [rsi+rdx],al
 inc rdx
 cmp rdx,r9
 jb .case_loop
.case_commit:
 mov [r8+NEBO_TEXT_DATA_OFFSET],rsi
 mov [r8+NEBO_TEXT_LENGTH_OFFSET],r9
 mov r10,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 and r10,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [r8+NEBO_TEXT_FLAGS_OFFSET],r10
 mov qword [r8+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.case_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.case_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; rdi=input, rsi=start byte, rdx=end byte exclusive, rcx=out view.
align 16
neboc_text_slice_bytes:
 test rdi,rdi
 jz .slice_null
 test rcx,rcx
 jz .slice_null
 cmp rsi,rdx
 ja .slice_bounds
 cmp rdx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 ja .slice_bounds
 ; A Text view may not begin or end in the middle of a UTF-8 sequence. Bytes
 ; remain byte-addressable because they do not carry VALID_UTF8.
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .slice_boundaries_ok
 test rsi,rsi
 jz .slice_end_boundary
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov al,[r8+rsi]
 and al,0xc0
 cmp al,0x80
 je .slice_utf8
.slice_end_boundary:
 cmp rdx,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 je .slice_boundaries_ok
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov al,[r8+rdx]
 and al,0xc0
 cmp al,0x80
 je .slice_utf8
.slice_boundaries_ok:
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 add r8,rsi
 sub rdx,rsi
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r8
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],rdx
 mov r8,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],r8
 mov [rcx+NEBO_TEXT_AUX_OFFSET],rdi
 xor eax,eax
 ret
.slice_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.slice_bounds:
 mov eax,NEBO_TEXT_ERROR_BOUNDS
 ret
.slice_utf8:
 mov eax,NEBO_TEXT_ERROR_INVALID_BYTE_INDEX
 ret

; rdi=input, rsi=count, rdx=mode TAKE/DROP, rcx=out view. Count saturates at length.
align 16
neboc_text_take_drop:
 test rdi,rdi
 jz .take_null
 test rcx,rcx
 jz .take_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rsi,r8
 cmova rsi,r8
 test qword [rdi+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .take_boundary_ok
 test rsi,rsi
 jz .take_boundary_ok
 cmp rsi,r8
 je .take_boundary_ok
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov al,[r9+rsi]
 and al,0xc0
 cmp al,0x80
 je .take_utf8
.take_boundary_ok:
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 test rdx,rdx
 jnz .drop_mode
 mov r8,rsi
 jmp .take_commit
.drop_mode:
 add r9,rsi
 sub r8,rsi
.take_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],r9
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],r8
 mov r9,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],r9
 mov [rcx+NEBO_TEXT_AUX_OFFSET],rdi
 xor eax,eax
 ret
.take_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.take_utf8:
 mov eax,NEBO_TEXT_ERROR_INVALID_BYTE_INDEX
 ret

; rdi=input, rsi=out bytes, rdx=capacity, rcx=out descriptor. CRLF/CR -> LF.
align 16
neboc_text_normalize_newlines:
 test rdi,rdi
 jz .newline_null
 test rcx,rcx
 jz .newline_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r8,rdx
 ja .newline_capacity
 mov r9,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor r10d,r10d
 xor r11d,r11d
.newline_loop:
 cmp r10,r8
 jae .newline_commit
 mov al,[r9+r10]
 inc r10
 cmp al,13
 jne .newline_write
 mov al,10
 cmp r10,r8
 jae .newline_write
 cmp byte [r9+r10],10
 jne .newline_write
 inc r10
.newline_write:
 mov [rsi+r11],al
 inc r11
 jmp .newline_loop
.newline_commit:
 mov [rcx+NEBO_TEXT_DATA_OFFSET],rsi
 mov [rcx+NEBO_TEXT_LENGTH_OFFSET],r11
 mov r8,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 and r8,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [rcx+NEBO_TEXT_FLAGS_OFFSET],r8
 mov qword [rcx+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.newline_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.newline_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; rdi=input, sil=old byte, dl=new byte, rcx=out bytes, r8=capacity, r9=out descriptor.
align 16
neboc_text_replace_once_byte:
 xor r10d,r10d
 jmp replace_byte
align 16
neboc_text_replace_all_byte:
 mov r10d,2
replace_byte:
 test rdi,rdi
 jz .replace_null
 test r9,r9
 jz .replace_null
 mov r11,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp r11,r8
 ja .replace_capacity
 test r11,r11
 jz .replace_commit
 test rcx,rcx
 jz .replace_null
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 xor edi,edi
.replace_loop:
 mov al,[r8+rdi]
 cmp al,sil
 jne .replace_store
 cmp r10d,1
 je .replace_store
.replace_use_new:
 mov al,dl
 test r10d,r10d
 jnz .replace_store
 mov r10d,1
.replace_store:
 mov [rcx+rdi],al
 inc rdi
 cmp rdi,r11
 jb .replace_loop
.replace_commit:
 mov [r9+NEBO_TEXT_DATA_OFFSET],rcx
 mov [r9+NEBO_TEXT_LENGTH_OFFSET],r11
 mov qword [r9+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [r9+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 ret
.replace_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.replace_capacity:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; rdi=input, sil=delimiter, rdx=out item array, rcx=item capacity. rax=item count/error.
align 16
neboc_text_split_byte:
 test rdi,rdi
 jz .split_null
 test rdx,rdx
 jz .split_null
 mov r8,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov rax,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,1
 xor r10d,r10d
.split_count:
 cmp r10,r8
 jae .split_capacity_check
 cmp byte [rax+r10],sil
 jne .split_count_next
 inc r9
.split_count_next:
 inc r10
 jmp .split_count
.split_capacity_check:
 cmp r9,rcx
 ja .split_capacity
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.split_fill:
 cmp r11,r8
 jae .split_final
 cmp byte [rax+r11],sil
 jne .split_fill_next
 mov rdi,r10
 shl rdi,4
 lea rcx,[rax+r9]
 mov [rdx+rdi+NEBO_SPLIT_ITEM_DATA_OFFSET],rcx
 mov rcx,r11
 sub rcx,r9
 mov [rdx+rdi+NEBO_SPLIT_ITEM_LENGTH_OFFSET],rcx
 inc r10
 lea r9,[r11+1]
.split_fill_next:
 inc r11
 jmp .split_fill
.split_final:
 mov rdi,r10
 shl rdi,4
 lea rcx,[rax+r9]
 mov [rdx+rdi+NEBO_SPLIT_ITEM_DATA_OFFSET],rcx
 sub r8,r9
 mov [rdx+rdi+NEBO_SPLIT_ITEM_LENGTH_OFFSET],r8
 lea rax,[r10+1]
 ret
.split_null:
 mov rax,-NEBO_TEXT_ERROR_NULL
 ret
.split_capacity:
 mov rax,-NEBO_TEXT_ERROR_CAPACITY
 ret

; rdi=item array, rsi=count, dl=delimiter, rcx=out bytes, r8=capacity, r9=out descriptor.
align 16
neboc_text_join_byte:
 test rdi,rdi
 jz .join_null
 test r9,r9
 jz .join_null
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 xor eax,eax
 xor ebx,ebx
.join_size:
 cmp rbx,r13
 jae .join_delimiters
 mov r10,rbx
 shl r10,4
 add rax,[r12+r10+NEBO_SPLIT_ITEM_LENGTH_OFFSET]
 jc .join_capacity_saved
 inc rbx
 jmp .join_size
.join_delimiters:
 test r13,r13
 jz .join_capacity_check
 lea r10,[r13-1]
 add rax,r10
 jc .join_capacity_saved
.join_capacity_check:
 cmp rax,r8
 ja .join_capacity_saved
 xor ebx,ebx
 xor r11d,r11d
.join_items:
 cmp rbx,r13
 jae .join_commit
 test rbx,rbx
 jz .join_copy
 mov [r14+r11],dl
 inc r11
.join_copy:
 mov r10,rbx
 shl r10,4
 mov rsi,[r12+r10+NEBO_SPLIT_ITEM_DATA_OFFSET]
 mov rcx,[r12+r10+NEBO_SPLIT_ITEM_LENGTH_OFFSET]
 lea rdi,[r14+r11]
 add r11,rcx
 rep movsb
 inc rbx
 jmp .join_items
.join_commit:
 mov [r9+NEBO_TEXT_DATA_OFFSET],r14
 mov [r9+NEBO_TEXT_LENGTH_OFFSET],r11
 mov qword [r9+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [r9+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.join_capacity_saved:
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.join_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret

; rdi=input, rsi=target length, dl=fill, rcx=LEFT/RIGHT, r8=initialized builder.
align 16
neboc_text_pad_ascii:
 test rdi,rdi
 jz .pad_null
 test r8,r8
 jz .pad_null
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 cmp rsi,r9
 cmovb rsi,r9
 cmp rsi,[r8+NEBO_BUILDER_CAPACITY_OFFSET]
 ja .pad_capacity
 mov r10,[r8+NEBO_BUILDER_DATA_OFFSET]
 test rsi,rsi
 jz .pad_zero
 test r10,r10
 jz .pad_null
 push rbx
 mov rbx,rsi
 mov r11,rsi
 sub r11,r9
 test rcx,rcx
 jnz .pad_copy_input
 xor eax,eax
.pad_left_loop:
 cmp rax,r11
 jae .pad_copy_input
 mov [r10+rax],dl
 inc rax
 jmp .pad_left_loop
.pad_copy_input:
 xor eax,eax
 test rcx,rcx
 cmovz rax,r11
 mov rsi,[rdi+NEBO_TEXT_DATA_OFFSET]
 lea rdi,[r10+rax]
 mov rcx,r9
 rep movsb
 test rax,rax
 jnz .pad_commit
 mov rax,r9
.pad_right_loop:
 cmp rax,rbx
 jae .pad_commit
 mov [r10+rax],dl
 inc rax
 jmp .pad_right_loop
.pad_commit:
 mov [r8+NEBO_BUILDER_LENGTH_OFFSET],rbx
 mov qword [r8+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 pop rbx
 ret
.pad_zero:
 mov qword [r8+NEBO_BUILDER_LENGTH_OFFSET],0
 mov qword [r8+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_OK
 xor eax,eax
 ret
.pad_null:
 mov eax,NEBO_TEXT_ERROR_NULL
 ret
.pad_capacity:
 mov qword [r8+NEBO_BUILDER_STATUS_OFFSET],NEBO_TEXT_ERROR_CAPACITY
 mov eax,NEBO_TEXT_ERROR_CAPACITY
 ret

; Public G055 wrappers use caller-owned workspaces emitted by the compiler.
; They return the canonical output descriptor in RAX. A violated checked
; contract traps before descriptor commit; normal source validation prevents
; those paths for the literal-bounded public profile.
align 16
nebo_runtime_textual_text_trim:
 push rbx
 mov rbx,rsi
 call neboc_text_trim_ascii
 test eax,eax
 jnz text_transform_trap
 mov rax,rbx
 pop rbx
 ret

; rdi=input, rsi=out view descriptor.
align 16
nebo_runtime_textual_text_trim_start:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 xor ecx,ecx
.trim_start_loop:
 cmp rcx,r9
 jae .trim_start_commit
 mov al,[r8+rcx]
 IS_SPACE al,.trim_start_next
 jmp .trim_start_commit
.trim_start_next:
 inc rcx
 jmp .trim_start_loop
.trim_start_commit:
 add r8,rcx
 sub r9,rcx
 mov [rsi+NEBO_TEXT_DATA_OFFSET],r8
 mov [rsi+NEBO_TEXT_LENGTH_OFFSET],r9
 mov rax,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rsi+NEBO_TEXT_FLAGS_OFFSET],rax
 mov [rsi+NEBO_TEXT_AUX_OFFSET],rdi
 mov rax,rsi
 ret

align 16
nebo_runtime_textual_text_trim_end:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 mov r8,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r9,[rdi+NEBO_TEXT_LENGTH_OFFSET]
.trim_end_loop:
 test r9,r9
 jz .trim_end_commit
 mov al,[r8+r9-1]
 IS_SPACE al,.trim_end_next
 jmp .trim_end_commit
.trim_end_next:
 dec r9
 jmp .trim_end_loop
.trim_end_commit:
 mov [rsi+NEBO_TEXT_DATA_OFFSET],r8
 mov [rsi+NEBO_TEXT_LENGTH_OFFSET],r9
 mov rax,[rdi+NEBO_TEXT_FLAGS_OFFSET]
 mov [rsi+NEBO_TEXT_FLAGS_OFFSET],rax
 mov [rsi+NEBO_TEXT_AUX_OFFSET],rdi
 mov rax,rsi
 ret

; rdi=left, rsi=right, rdx=out bytes, rcx=capacity, r8=out descriptor.
align 16
nebo_runtime_textual_text_concat:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 test r8,r8
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+NEBO_TEXT_LENGTH_OFFSET]
 add rax,[r13+NEBO_TEXT_LENGTH_OFFSET]
 jc .concat_trap
 cmp rax,rcx
 ja .concat_trap
 test rax,rax
 jz .concat_commit
 test r14,r14
 jz .concat_trap
 mov rdi,r14
 mov rsi,[r12+NEBO_TEXT_DATA_OFFSET]
 mov rcx,[r12+NEBO_TEXT_LENGTH_OFFSET]
 rep movsb
 mov rsi,[r13+NEBO_TEXT_DATA_OFFSET]
 mov rcx,[r13+NEBO_TEXT_LENGTH_OFFSET]
 rep movsb
.concat_commit:
 mov [r8+NEBO_TEXT_DATA_OFFSET],r14
 mov [r8+NEBO_TEXT_LENGTH_OFFSET],rax
 mov rcx,[r12+NEBO_TEXT_FLAGS_OFFSET]
 and rcx,[r13+NEBO_TEXT_FLAGS_OFFSET]
 and rcx,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [r8+NEBO_TEXT_FLAGS_OFFSET],rcx
 mov qword [r8+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,r8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.concat_trap:
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

; rdi=input, rsi=out bytes, rdx=capacity, rcx=out descriptor.
align 16
nebo_runtime_textual_text_lower:
 mov r8,rcx
 xor ecx,ecx
 push r8
 call neboc_text_case_ascii
 pop r8
 test eax,eax
 jnz text_transform_trap
 mov rax,r8
 ret
align 16
nebo_runtime_textual_text_upper:
 mov r8,rcx
 mov ecx,NEBO_CASE_UPPER
 push r8
 call neboc_text_case_ascii
 pop r8
 test eax,eax
 jnz text_transform_trap
 mov rax,r8
 ret

; Views preserve the source lifetime in AUX.
align 16
nebo_runtime_textual_text_byte_slice:
 push rcx
 call neboc_text_slice_bytes
 pop rcx
 test eax,eax
 jnz text_transform_trap
 mov rax,rcx
 ret
align 16
nebo_runtime_textual_text_take_bytes:
 mov rcx,rdx
 xor edx,edx
 push rcx
 call neboc_text_take_drop
 pop rcx
 test eax,eax
 jnz text_transform_trap
 mov rax,rcx
 ret
align 16
nebo_runtime_textual_text_drop_bytes:
 mov rcx,rdx
 mov edx,NEBO_DROP
 push rcx
 call neboc_text_take_drop
 pop rcx
 test eax,eax
 jnz text_transform_trap
 mov rax,rcx
 ret

align 16
nebo_runtime_textual_text_normalize_newlines:
 push rcx
 call neboc_text_normalize_newlines
 pop rcx
 test eax,eax
 jnz text_transform_trap
 mov rax,rcx
 ret

; Collapse ASCII whitespace runs to one space and trim both ends.
; rdi=input, rsi=out bytes, rdx=capacity, rcx=out descriptor.
align 16
nebo_runtime_textual_text_normalize_whitespace:
 test rdi,rdi
 jz text_transform_trap
 test rcx,rcx
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov r8,[r12+NEBO_TEXT_DATA_OFFSET]
 mov r9,[r12+NEBO_TEXT_LENGTH_OFFSET]
 cmp r9,rdx
 ja .whitespace_trap
 xor r10d,r10d
 xor r11d,r11d
 xor ebx,ebx
.whitespace_loop:
 cmp r10,r9
 jae .whitespace_commit
 mov al,[r8+r10]
 inc r10
 cmp al,' '
 je .whitespace_pending
 cmp al,9
 je .whitespace_pending
 cmp al,10
 je .whitespace_pending
 cmp al,13
 je .whitespace_pending
 test ebx,ebx
 jz .whitespace_store
 test r11,r11
 jz .whitespace_store
 mov byte [r13+r11],' '
 inc r11
.whitespace_store:
 mov [r13+r11],al
 inc r11
 xor ebx,ebx
 jmp .whitespace_loop
.whitespace_pending:
 mov ebx,1
 jmp .whitespace_loop
.whitespace_commit:
 mov [r14+NEBO_TEXT_DATA_OFFSET],r13
 mov [r14+NEBO_TEXT_LENGTH_OFFSET],r11
 mov rax,[r12+NEBO_TEXT_FLAGS_OFFSET]
 and rax,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [r14+NEBO_TEXT_FLAGS_OFFSET],rax
 mov qword [r14+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,r14
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.whitespace_trap:
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

; rdi=input, rsi=literal separator, rdx=caller item array, rcx=item capacity,
; r8=TextSplit plan descriptor. Items are borrowed Text byte ranges.
align 16
nebo_runtime_textual_text_split:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 test rdx,rdx
 jz text_transform_trap
 test r8,r8
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r13,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r14,[rsi+NEBO_TEXT_DATA_OFFSET]
 mov r15,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test r15,r15
 jz .split_text_trap
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov [rsp+16],r8
 mov [rsp+24],rdi
 xor ebx,ebx
 mov r10,1
.split_text_count:
 cmp rbx,r13
 jae .split_text_capacity
 mov rax,rbx
 add rax,r15
 jc .split_text_capacity
 cmp rax,r13
 ja .split_text_count_next
 xor ecx,ecx
.split_text_count_compare:
 cmp rcx,r15
 jae .split_text_count_match
 lea rdx,[r12+rbx]
 mov al,[rdx+rcx]
 cmp al,[r14+rcx]
 jne .split_text_count_next
 inc rcx
 jmp .split_text_count_compare
.split_text_count_match:
 inc r10
 add rbx,r15
 jmp .split_text_count
.split_text_count_next:
 inc rbx
 jmp .split_text_count
.split_text_capacity:
 cmp r10,[rsp+8]
 ja .split_text_trap
 xor ebx,ebx
 xor r9d,r9d
 xor r11d,r11d
.split_text_fill:
 cmp rbx,r13
 jae .split_text_final
 mov rax,rbx
 add rax,r15
 jc .split_text_final
 cmp rax,r13
 ja .split_text_fill_next
 xor ecx,ecx
.split_text_fill_compare:
 cmp rcx,r15
 jae .split_text_fill_match
 lea rdx,[r12+rbx]
 mov al,[rdx+rcx]
 cmp al,[r14+rcx]
 jne .split_text_fill_next
 inc rcx
 jmp .split_text_fill_compare
.split_text_fill_match:
 mov rdx,[rsp]
 mov rax,r9
 shl rax,4
 lea rcx,[r12+r11]
 mov [rdx+rax+NEBO_SPLIT_ITEM_DATA_OFFSET],rcx
 mov rcx,rbx
 sub rcx,r11
 mov [rdx+rax+NEBO_SPLIT_ITEM_LENGTH_OFFSET],rcx
 inc r9
 add rbx,r15
 mov r11,rbx
 jmp .split_text_fill
.split_text_fill_next:
 inc rbx
 jmp .split_text_fill
.split_text_final:
 mov rdx,[rsp]
 mov rax,r9
 shl rax,4
 lea rcx,[r12+r11]
 mov [rdx+rax+NEBO_SPLIT_ITEM_DATA_OFFSET],rcx
 mov rcx,r13
 sub rcx,r11
 mov [rdx+rax+NEBO_SPLIT_ITEM_LENGTH_OFFSET],rcx
 inc r9
 mov r8,[rsp+16]
 mov [r8+NEBO_TEXT_DATA_OFFSET],rdx
 mov [r8+NEBO_TEXT_LENGTH_OFFSET],r9
 mov qword [r8+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov rax,[rsp+24]
 mov [r8+NEBO_TEXT_AUX_OFFSET],rax
 mov rax,r8
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.split_text_trap:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

; rdi=TextSplit plan, rsi=separator, rdx=out bytes, rcx=capacity,
; r8=out Text descriptor.
align 16
nebo_runtime_textual_text_join:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 test r8,r8
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r13,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r14,rsi
 mov r15,rdx
 mov [rsp],rcx
 mov [rsp+8],r8
 xor eax,eax
 xor ebx,ebx
.join_text_size:
 cmp rbx,r13
 jae .join_text_separators
 mov r10,rbx
 shl r10,4
 add rax,[r12+r10+NEBO_SPLIT_ITEM_LENGTH_OFFSET]
 jc .join_text_trap
 inc rbx
 jmp .join_text_size
.join_text_separators:
 cmp r13,1
 jbe .join_text_capacity
 mov r10,r13
 dec r10
 imul r10,[r14+NEBO_TEXT_LENGTH_OFFSET]
 jo .join_text_trap
 add rax,r10
 jc .join_text_trap
.join_text_capacity:
 cmp rax,[rsp]
 ja .join_text_trap
 xor ebx,ebx
 xor r11d,r11d
.join_text_items:
 cmp rbx,r13
 jae .join_text_commit
 test rbx,rbx
 jz .join_text_item
 mov rsi,[r14+NEBO_TEXT_DATA_OFFSET]
 mov rcx,[r14+NEBO_TEXT_LENGTH_OFFSET]
 lea rdi,[r15+r11]
 add r11,rcx
 rep movsb
.join_text_item:
 mov r10,rbx
 shl r10,4
 mov rsi,[r12+r10+NEBO_SPLIT_ITEM_DATA_OFFSET]
 mov rcx,[r12+r10+NEBO_SPLIT_ITEM_LENGTH_OFFSET]
 lea rdi,[r15+r11]
 add r11,rcx
 rep movsb
 inc rbx
 jmp .join_text_items
.join_text_commit:
 mov r8,[rsp+8]
 mov [r8+NEBO_TEXT_DATA_OFFSET],r15
 mov [r8+NEBO_TEXT_LENGTH_OFFSET],r11
 mov qword [r8+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [r8+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,r8
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.join_text_trap:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

; Literal Text pattern replacement. Signature for once/all/split+join:
; rdi=input, rsi=old/split, rdx=new/join, rcx=out bytes,
; r8=capacity, r9=out descriptor. The mode is pushed by each entry.
align 16
nebo_runtime_textual_text_replace_once:
 xor r10d,r10d
 jmp text_replace_pattern_entry
align 16
nebo_runtime_textual_text_replace_all:
 mov r10d,1
 jmp text_replace_pattern_entry
align 16
nebo_runtime_textual_text_split_join:
 mov r10d,1
text_replace_pattern_entry:
 test rdi,rdi
 jz text_transform_trap
 test rsi,rsi
 jz text_transform_trap
 test rdx,rdx
 jz text_transform_trap
 test r9,r9
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,[rdi+NEBO_TEXT_DATA_OFFSET]
 mov r13,[rdi+NEBO_TEXT_LENGTH_OFFSET]
 mov r14,[rsi+NEBO_TEXT_DATA_OFFSET]
 mov r15,[rsi+NEBO_TEXT_LENGTH_OFFSET]
 test r15,r15
 jz .pattern_trap
 mov rax,[rdx+NEBO_TEXT_DATA_OFFSET]
 mov [rsp],rax
 mov rax,[rdx+NEBO_TEXT_LENGTH_OFFSET]
 mov [rsp+8],rax
 mov [rsp+16],rcx
 mov [rsp+24],r8
 mov [rsp+32],r9
 mov [rsp+40],r10
 xor ebx,ebx
 xor r10d,r10d
.pattern_count_loop:
 cmp rbx,r13
 jae .pattern_size
 mov rax,rbx
 add rax,r15
 jc .pattern_size
 cmp rax,r13
 ja .pattern_count_next
 xor ecx,ecx
.pattern_count_compare:
 cmp rcx,r15
 jae .pattern_count_match
 lea rdx,[r12+rbx]
 mov al,[rdx+rcx]
 cmp al,[r14+rcx]
 jne .pattern_count_next
 inc rcx
 jmp .pattern_count_compare
.pattern_count_match:
 inc r10
 add rbx,r15
 cmp qword [rsp+40],0
 jne .pattern_count_loop
 jmp .pattern_size
.pattern_count_next:
 inc rbx
 jmp .pattern_count_loop
.pattern_size:
 mov rax,[rsp+8]
 cmp rax,r15
 jb .pattern_shrink
 sub rax,r15
 imul rax,r10
 jo .pattern_trap
 add rax,r13
 jc .pattern_trap
 jmp .pattern_capacity
.pattern_shrink:
 mov rcx,r15
 sub rcx,rax
 imul rcx,r10
 jo .pattern_trap
 mov rax,r13
 sub rax,rcx
 jc .pattern_trap
.pattern_capacity:
 cmp rax,[rsp+24]
 ja .pattern_trap
 mov [rsp+48],rax
 xor ebx,ebx
 xor r11d,r11d
 xor r10d,r10d
.pattern_copy_loop:
 cmp rbx,r13
 jae .pattern_commit
 mov rax,rbx
 add rax,r15
 jc .pattern_copy_byte
 cmp rax,r13
 ja .pattern_copy_byte
 cmp qword [rsp+40],0
 jne .pattern_copy_compare_begin
 test r10,r10
 jnz .pattern_copy_byte
.pattern_copy_compare_begin:
 xor ecx,ecx
.pattern_copy_compare:
 cmp rcx,r15
 jae .pattern_copy_match
 lea rdx,[r12+rbx]
 mov al,[rdx+rcx]
 cmp al,[r14+rcx]
 jne .pattern_copy_byte
 inc rcx
 jmp .pattern_copy_compare
.pattern_copy_match:
.pattern_emit_new:
 xor ecx,ecx
.pattern_new_loop:
 cmp rcx,[rsp+8]
 jae .pattern_new_done
 mov rax,[rsp]
 mov al,[rax+rcx]
 mov rdx,[rsp+16]
 mov [rdx+r11],al
 inc rcx
 inc r11
 jmp .pattern_new_loop
.pattern_new_done:
 inc r10
 add rbx,r15
 jmp .pattern_copy_loop
.pattern_copy_byte:
 mov al,[r12+rbx]
 mov rdx,[rsp+16]
 mov [rdx+r11],al
 inc rbx
 inc r11
 jmp .pattern_copy_loop
.pattern_commit:
 mov r9,[rsp+32]
 mov rax,[rsp+16]
 mov [r9+NEBO_TEXT_DATA_OFFSET],rax
 mov [r9+NEBO_TEXT_LENGTH_OFFSET],r11
 mov qword [r9+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 mov qword [r9+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,r9
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.pattern_trap:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

; rdi=input, rsi=target byte width, rdx=fill Text, rcx=out bytes,
; r8=capacity, r9=out descriptor. Direction in r10d (0 start, 1 end).
align 16
nebo_runtime_textual_text_pad_start:
 xor r10d,r10d
 jmp text_pad_pattern
align 16
nebo_runtime_textual_text_pad_end:
 mov r10d,1
text_pad_pattern:
 test rdi,rdi
 jz text_transform_trap
 test rdx,rdx
 jz text_transform_trap
 test r9,r9
 jz text_transform_trap
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rdx
 mov r14,rcx
 mov r15,r9
 mov rbx,[r12+NEBO_TEXT_LENGTH_OFFSET]
 cmp rsi,rbx
 cmovb rsi,rbx
 cmp rsi,r8
 ja .pad_pattern_trap
 mov rax,[r13+NEBO_TEXT_LENGTH_OFFSET]
 test rax,rax
 jz .pad_pattern_trap
 mov [rsp],rsi
 mov [rsp+8],r10
 test rsi,rsi
 jz .pad_pattern_commit
 test r14,r14
 jz .pad_pattern_trap
 mov r11,rsi
 sub r11,rbx
 ; Byte-width padding still returns Text: a partial repetition may end only on
 ; a UTF-8 codepoint boundary. This prevents a multi-byte fill from silently
 ; manufacturing an invalid Text descriptor.
 test qword [r12+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .pad_pattern_trap
 test qword [r13+NEBO_TEXT_FLAGS_OFFSET],NEBO_TEXT_FLAG_VALID_UTF8
 jz .pad_pattern_trap
 mov rax,r11
 xor edx,edx
 div qword [r13+NEBO_TEXT_LENGTH_OFFSET]
 test rdx,rdx
 jz .pad_pattern_boundary_ok
 mov rax,[r13+NEBO_TEXT_DATA_OFFSET]
 mov al,[rax+rdx]
 and al,0xc0
 cmp al,0x80
 je .pad_pattern_trap
.pad_pattern_boundary_ok:
 xor ecx,ecx
 cmp qword [rsp+8],0
 jne .pad_pattern_input
.pad_pattern_fill_left:
 cmp rcx,r11
 jae .pad_pattern_input
 mov rax,rcx
 xor edx,edx
 div qword [r13+NEBO_TEXT_LENGTH_OFFSET]
 mov rax,[r13+NEBO_TEXT_DATA_OFFSET]
 mov al,[rax+rdx]
 mov [r14+rcx],al
 inc rcx
 jmp .pad_pattern_fill_left
.pad_pattern_input:
 xor eax,eax
 cmp qword [rsp+8],0
 jne .pad_pattern_copy
 mov rax,r11
.pad_pattern_copy:
 mov rdi,r14
 add rdi,rax
 mov rsi,[r12+NEBO_TEXT_DATA_OFFSET]
 mov rcx,rbx
 rep movsb
 cmp qword [rsp+8],0
 je .pad_pattern_commit
 mov rcx,rbx
.pad_pattern_fill_right:
 cmp rcx,[rsp]
 jae .pad_pattern_commit
 mov rax,rcx
 sub rax,rbx
 xor edx,edx
 div qword [r13+NEBO_TEXT_LENGTH_OFFSET]
 mov rax,[r13+NEBO_TEXT_DATA_OFFSET]
 mov al,[rax+rdx]
 mov [r14+rcx],al
 inc rcx
 jmp .pad_pattern_fill_right
.pad_pattern_commit:
 mov [r15+NEBO_TEXT_DATA_OFFSET],r14
 mov rax,[rsp]
 mov [r15+NEBO_TEXT_LENGTH_OFFSET],rax
 mov rax,[r12+NEBO_TEXT_FLAGS_OFFSET]
 and rax,[r13+NEBO_TEXT_FLAGS_OFFSET]
 and rax,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8
 mov [r15+NEBO_TEXT_FLAGS_OFFSET],rax
 mov qword [r15+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 mov rax,r15
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.pad_pattern_trap:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 jmp text_transform_trap

text_transform_trap:
 mov edi,1
 mov eax,60
 syscall
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
