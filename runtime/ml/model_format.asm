bits 64
default rel
%define NEBO_MODEL_FORMAT_IMPLEMENTATION 1
%include "runtime/ml/model_format.inc"
%include "runtime/filesystem/file.inc"
%include "runtime/crypto/sha256.inc"

section .text
global nebo_nmf1_inspect
global nebo_nmf1_load
global nebo_nmf1_state_lookup
global nebo_nmf1_save

; rdi=bytes, rsi=length, rdx=Summary48. The summary is published only after
; the complete manifest and payload checksum have been validated.
nebo_nmf1_inspect:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,72
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .argument
 test r14,r14
 jz .argument
 cmp r13,NEBO_NMF1_HEADER_SIZE
 jb .size
 cmp r13,NEBO_NMF1_MAX_FILE_BYTES
 ja .limit
 cmp dword [r12],NEBO_NMF1_MAGIC
 jne .magic
 cmp word [r12+4],NEBO_NMF1_VERSION
 jne .version
 cmp word [r12+6],NEBO_NMF1_HEADER_SIZE
 jne .version
 mov eax,[r12+8]
 cmp rax,r13
 jne .size
 movzx eax,word [r12+12]
 cmp eax,NEBO_NMF1_MAX_NODES
 ja .limit
 movzx r15d,word [r12+14]
 test r15d,r15d
 jz .manifest
 cmp r15d,NEBO_NMF1_MAX_TENSORS
 ja .limit
 mov eax,[r12+16]
 test eax,eax
 jz .manifest
 cmp eax,NEBO_NMF1_MAX_ELEMENTS
 ja .limit
 cmp dword [r12+20],NEBO_NMF1_HEADER_SIZE
 jne .manifest
 mov eax,r15d
 imul eax,NEBO_NMF1_ENTRY_SIZE
 cmp eax,[r12+24]
 jne .manifest
 add eax,NEBO_NMF1_HEADER_SIZE
 jc .manifest
 cmp eax,[r12+28]
 jne .manifest
 cmp rax,r13
 ja .size
 mov [rsp],rax
 mov rcx,r13
 sub rcx,rax
 mov [rsp+8],rcx
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 mov qword [rsp+32],0
 xor ebp,ebp
.entry_loop:
 cmp ebp,r15d
 jae .entries_done
 mov eax,ebp
 imul eax,NEBO_NMF1_ENTRY_SIZE
 lea rdx,[r12+NEBO_NMF1_HEADER_SIZE+rax]
 mov rax,[rdx]
 test rax,rax
 jz .manifest
 cmp rax,[rsp+32]
 jbe .manifest
 mov [rsp+32],rax
 movzx eax,byte [rdx+8]
 cmp eax,NEBO_NMF1_DTYPE_F64
 je .dtype_f64
 cmp eax,NEBO_NMF1_DTYPE_I8
 jne .manifest
 mov r9d,1
 jmp .dtype_ready
.dtype_f64:
 mov r9d,8
.dtype_ready:
 movzx ecx,byte [rdx+9]
 test ecx,ecx
 jz .manifest
 cmp ecx,4
 ja .manifest
 cmp word [rdx+10],0
 jne .manifest
 mov r8d,[rdx+12]
 test r8d,r8d
 jz .manifest
 cmp r8d,NEBO_NMF1_MAX_ELEMENTS
 ja .limit
 mov r10d,1
 xor r11d,r11d
.dimension_loop:
 cmp r11d,ecx
 jae .dimension_tail
 mov eax,[rdx+16+r11*4]
 test eax,eax
 jz .manifest
 cmp eax,NEBO_NMF1_MAX_ELEMENTS
 ja .limit
 imul r10,rax
 cmp r10,NEBO_NMF1_MAX_ELEMENTS
 ja .limit
 inc r11d
 jmp .dimension_loop
.dimension_tail:
 cmp r11d,4
 jae .dimensions_done
 cmp dword [rdx+16+r11*4],0
 jne .manifest
 inc r11d
 jmp .dimension_tail
.dimensions_done:
 cmp r10,r8
 jne .manifest
 mov eax,[rdx+32]
 cmp rax,[rsp+24]
 jne .manifest
 mov ecx,r8d
 imul rcx,r9
 cmp ecx,[rdx+36]
 jne .manifest
 cmp qword [rdx+40],0
 jne .manifest
 add [rsp+24],rcx
 jc .manifest
 mov rax,[rsp+24]
 cmp rax,[rsp+8]
 ja .size
 add [rsp+16],r8
 mov rax,[rsp+16]
 cmp rax,NEBO_NMF1_MAX_ELEMENTS
 ja .limit
 inc ebp
 jmp .entry_loop
.entries_done:
 mov rax,[rsp+24]
 cmp rax,[rsp+8]
 jne .manifest
 mov eax,[r12+16]
 cmp rax,[rsp+16]
 jne .manifest
 lea rdi,[r12+NEBO_NMF1_HEADER_SIZE]
 mov rsi,r13
 sub rsi,NEBO_NMF1_HEADER_SIZE
 lea rdx,[rsp+40]
 call nebo_sha256_hash
 test eax,eax
 jnz .limit
 mov rax,[rsp+40]
 cmp rax,[r12+32]
 jne .checksum
 mov rax,[rsp+48]
 cmp rax,[r12+40]
 jne .checksum
 mov rax,[rsp+56]
 cmp rax,[r12+48]
 jne .checksum
 mov rax,[rsp+64]
 cmp rax,[r12+56]
 jne .checksum
 mov [r14+NEBO_NMF1_SUMMARY_FILE_BYTES],r13
 movzx eax,word [r12+12]
 mov [r14+NEBO_NMF1_SUMMARY_NODES],rax
 movzx eax,word [r12+14]
 mov [r14+NEBO_NMF1_SUMMARY_TENSORS],rax
 mov eax,[r12+16]
 mov [r14+NEBO_NMF1_SUMMARY_ELEMENTS],rax
 mov rax,[rsp]
 lea rax,[r12+rax]
 mov [r14+NEBO_NMF1_SUMMARY_DATA],rax
 mov rax,[rsp+8]
 mov [r14+NEBO_NMF1_SUMMARY_DATA_BYTES],rax
 xor eax,eax
 jmp .return
.argument: mov eax,NEBO_NMF1_E_ARGUMENT
 jmp .return
.limit: mov eax,NEBO_NMF1_E_LIMIT
 jmp .return
.magic: mov eax,NEBO_NMF1_E_MAGIC
 jmp .return
.version: mov eax,NEBO_NMF1_E_VERSION
 jmp .return
.size: mov eax,NEBO_NMF1_E_SIZE
 jmp .return
.checksum: mov eax,NEBO_NMF1_E_CHECKSUM
 jmp .return
.manifest: mov eax,NEBO_NMF1_E_MANIFEST
.return:
 add rsp,72
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=bytes, rsi=length, rdx=destination, rcx=capacity, r8=Summary48.
nebo_nmf1_load:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,56
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r15,rcx
 mov r14,r8
 test r14,r14
 jz .load_argument
 lea rdx,[rsp]
 call nebo_nmf1_inspect
 test eax,eax
 jnz .load_return
 mov rcx,[rsp+NEBO_NMF1_SUMMARY_DATA_BYTES]
 cmp r15,rcx
 jb .load_capacity
 test rcx,rcx
 jz .load_publish
 test rbx,rbx
 jz .load_argument
 mov rax,r12
 add rax,r13
 mov rdx,rbx
 add rdx,rcx
 jc .load_overlap
 cmp rbx,rax
 jae .load_copy
 cmp rdx,r12
 jbe .load_copy
 jmp .load_overlap
.load_copy:
 mov rdi,rbx
 mov rsi,[rsp+NEBO_NMF1_SUMMARY_DATA]
 rep movsb
.load_publish:
 mov rax,[rsp]
 mov [r14],rax
 mov rax,[rsp+8]
 mov [r14+8],rax
 mov rax,[rsp+16]
 mov [r14+16],rax
 mov rax,[rsp+24]
 mov [r14+24],rax
 mov [r14+32],rbx
 mov rax,[rsp+40]
 mov [r14+40],rax
 xor eax,eax
 jmp .load_return
.load_argument: mov eax,NEBO_NMF1_E_ARGUMENT
 jmp .load_return
.load_capacity: mov eax,NEBO_NMF1_E_CAPACITY
 jmp .load_return
.load_overlap: mov eax,NEBO_NMF1_E_OVERLAP
.load_return:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=bytes, rsi=length, rdx=state id, rcx=State48.
nebo_nmf1_state_lookup:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r14,rcx
 test r14,r14
 jz .state_argument
 lea rdx,[rsp]
 call nebo_nmf1_inspect
 test eax,eax
 jnz .state_return
 mov r15,[rsp+NEBO_NMF1_SUMMARY_TENSORS]
 xor ebp,ebp
.state_loop:
 cmp rbp,r15
 jae .state_missing
 mov rax,rbp
 imul rax,NEBO_NMF1_ENTRY_SIZE
 lea rdx,[r12+NEBO_NMF1_HEADER_SIZE+rax]
 cmp [rdx],rbx
 je .state_found
 inc rbp
 jmp .state_loop
.state_found:
 mov [r14+NEBO_NMF1_STATE_ID],rbx
 movzx eax,byte [rdx+8]
 mov [r14+NEBO_NMF1_STATE_DTYPE],rax
 movzx eax,byte [rdx+9]
 mov [r14+NEBO_NMF1_STATE_RANK],rax
 mov eax,[rdx+12]
 mov [r14+NEBO_NMF1_STATE_ELEMENTS],rax
 mov eax,[rdx+32]
 add rax,[rsp+NEBO_NMF1_SUMMARY_DATA]
 mov [r14+NEBO_NMF1_STATE_DATA],rax
 mov eax,[rdx+36]
 mov [r14+NEBO_NMF1_STATE_DATA_BYTES],rax
 xor eax,eax
 jmp .state_return
.state_argument: mov eax,NEBO_NMF1_E_ARGUMENT
 jmp .state_return
.state_missing: mov eax,NEBO_NMF1_E_NOT_FOUND
.state_return:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=literal File64 handle, rsi=canonical bytes, rdx=length.
nebo_nmf1_save:
 push rbx
 push r12
 push r13
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .save_argument
 mov rdi,r13
 mov rsi,rbx
 lea rdx,[rsp]
 call nebo_nmf1_inspect
 test eax,eax
 jnz .save_return
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call nebo_file_write_all
 test eax,eax
 jnz .save_io
 cmp rdx,rbx
 jne .save_io
 xor eax,eax
 jmp .save_return
.save_argument: mov eax,NEBO_NMF1_E_ARGUMENT
 jmp .save_return
.save_io: mov eax,NEBO_NMF1_E_IO
.save_return:
 add rsp,48
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
