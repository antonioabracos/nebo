bits 64
default rel
%define NEBO_CHECKPOINT_IMPLEMENTATION 1
%include "runtime/training/checkpoint.inc"
%include "runtime/crypto/sha256.inc"
%include "runtime/filesystem/file.inc"
section .text
global nebo_checkpoint_pack
global nebo_checkpoint_inspect
global nebo_checkpoint_restore
global nebo_checkpoint_save
global nebo_checkpoint_load
global nebo_checkpoint_compare
global nebo_checkpoint_rotate
global nebo_checkpoint_seed_all

; rdi=payload,rsi=length,rdx=step,rcx=seed,r8=output,r9=capacity.
nebo_checkpoint_pack:
 test rdi,rdi
 jz .pack_arg
 test r8,r8
 jz .pack_arg
 test rsi,rsi
 jz .pack_limit
 cmp rsi,NEBO_CHECKPOINT_MAX_BYTES-NEBO_CHECKPOINT_HEADER_SIZE
 ja .pack_limit
 mov rax,rsi
 add rax,NEBO_CHECKPOINT_HEADER_SIZE
 cmp r9,rax
 jb .pack_capacity
 mov r10,rdi
 add r10,rsi
 jc .pack_arg
 mov r11,r8
 add r11,rax
 jc .pack_arg
 cmp rdi,r11
 jae .pack_disjoint
 cmp r8,r10
 jb .pack_overlap
.pack_disjoint:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,rax
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call nebo_sha256_hash
 test eax,eax
 jnz .pack_hash_error
 mov dword [rbx],NEBO_CHECKPOINT_MAGIC
 mov word [rbx+4],NEBO_CHECKPOINT_VERSION
 mov word [rbx+6],NEBO_CHECKPOINT_HEADER_SIZE
 mov [rbx+8],ebp
 mov [rbx+12],r13d
 mov [rbx+16],r14
 mov [rbx+24],r15
 mov rax,[rsp]
 mov [rbx+32],rax
 mov rax,[rsp+8]
 mov [rbx+40],rax
 mov rax,[rsp+16]
 mov [rbx+48],rax
 mov rax,[rsp+24]
 mov [rbx+56],rax
 lea rdi,[rbx+NEBO_CHECKPOINT_HEADER_SIZE]
 mov rsi,r12
 mov rcx,r13
 rep movsb
 xor eax,eax
 jmp .pack_return
.pack_hash_error:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
.pack_return:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.pack_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 ret
.pack_limit:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
 ret
.pack_capacity:
 mov eax,NEBO_CHECKPOINT_E_CAPACITY
 ret
.pack_overlap:
 mov eax,NEBO_CHECKPOINT_E_OVERLAP
 ret

; rdi=bytes,rsi=length,rdx=Summary32(payload*,length,step,seed).
nebo_checkpoint_inspect:
 test rdi,rdi
 jz .inspect_arg
 test rdx,rdx
 jz .inspect_arg
 cmp rsi,NEBO_CHECKPOINT_HEADER_SIZE
 jb .inspect_size
 cmp rsi,NEBO_CHECKPOINT_MAX_BYTES
 ja .inspect_limit
 cmp dword [rdi],NEBO_CHECKPOINT_MAGIC
 jne .inspect_magic
 cmp word [rdi+4],NEBO_CHECKPOINT_VERSION
 jne .inspect_version
 cmp word [rdi+6],NEBO_CHECKPOINT_HEADER_SIZE
 jne .inspect_version
 mov eax,[rdi+8]
 cmp rax,rsi
 jne .inspect_size
 mov eax,[rdi+12]
 test rax,rax
 jz .inspect_limit
 add rax,NEBO_CHECKPOINT_HEADER_SIZE
 cmp rax,rsi
 jne .inspect_size
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 lea rdi,[r12+NEBO_CHECKPOINT_HEADER_SIZE]
 mov esi,[r12+12]
 lea rdx,[rsp]
 call nebo_sha256_hash
 test eax,eax
 jnz .inspect_hash_limit
 mov rax,[rsp]
 cmp rax,[r12+32]
 jne .inspect_checksum_stack
 mov rax,[rsp+8]
 cmp rax,[r12+40]
 jne .inspect_checksum_stack
 mov rax,[rsp+16]
 cmp rax,[r12+48]
 jne .inspect_checksum_stack
 mov rax,[rsp+24]
 cmp rax,[r12+56]
 jne .inspect_checksum_stack
 lea rax,[r12+NEBO_CHECKPOINT_HEADER_SIZE]
 mov [r14],rax
 mov eax,[r12+12]
 mov [r14+8],rax
 mov rax,[r12+16]
 mov [r14+16],rax
 mov rax,[r12+24]
 mov [r14+24],rax
 xor eax,eax
 jmp .inspect_return
.inspect_hash_limit:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
 jmp .inspect_return
.inspect_checksum_stack:
 mov eax,NEBO_CHECKPOINT_E_CHECKSUM
.inspect_return:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.inspect_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 ret
.inspect_limit:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
 ret
.inspect_magic:
 mov eax,NEBO_CHECKPOINT_E_MAGIC
 ret
.inspect_version:
 mov eax,NEBO_CHECKPOINT_E_VERSION
 ret
.inspect_size:
 mov eax,NEBO_CHECKPOINT_E_SIZE
 ret

; rdi=bytes,rsi=length,rdx=destination,rcx=capacity,r8=Summary32.
nebo_checkpoint_restore:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r15,rcx
 mov r14,r8
 test r14,r14
 jz .restore_arg
 lea rdx,[rsp]
 call nebo_checkpoint_inspect
 test eax,eax
 jnz .restore_return
 mov rcx,[rsp+8]
 cmp r15,rcx
 jb .restore_capacity
 test rbx,rbx
 jz .restore_arg
 mov rax,r12
 add rax,r13
 mov rdx,rbx
 add rdx,rcx
 jc .restore_arg
 cmp rbx,rax
 jae .restore_copy
 cmp rdx,r12
 jbe .restore_copy
 mov eax,NEBO_CHECKPOINT_E_OVERLAP
 jmp .restore_return
.restore_copy:
 mov rdi,rbx
 mov rsi,[rsp]
 rep movsb
 mov [r14],rbx
 mov rax,[rsp+8]
 mov [r14+8],rax
 mov rax,[rsp+16]
 mov [r14+16],rax
 mov rax,[rsp+24]
 mov [r14+24],rax
 xor eax,eax
 jmp .restore_return
.restore_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 jmp .restore_return
.restore_capacity:
 mov eax,NEBO_CHECKPOINT_E_CAPACITY
.restore_return:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=literal File64,rsi=canonical bytes,rdx=length.
nebo_checkpoint_save:
 push rbx
 push r12
 push r13
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .save_arg
 mov rdi,r13
 mov rsi,rbx
 lea rdx,[rsp]
 call nebo_checkpoint_inspect
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
 mov rdi,r12
 call nebo_file_flush
 test eax,eax
 jnz .save_io
 xor eax,eax
 jmp .save_return
.save_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 jmp .save_return
.save_io:
 mov eax,NEBO_CHECKPOINT_E_IO
.save_return:
 add rsp,32
 pop r13
 pop r12
 pop rbx
 ret

; rdi=literal File64,rsi=buffer,rdx=exact length,rcx=Summary32.
nebo_checkpoint_load:
 push rbx
 push r12
 push r13
 push r14
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r14,rcx
 test r12,r12
 jz .load_arg
 test r13,r13
 jz .load_arg
 test r14,r14
 jz .load_arg
 cmp rbx,NEBO_CHECKPOINT_HEADER_SIZE
 jb .load_limit
 cmp rbx,NEBO_CHECKPOINT_MAX_BYTES
 ja .load_limit
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call nebo_file_read_exact
 test eax,eax
 jnz .load_io
 cmp rdx,rbx
 jne .load_io
 mov rdi,r13
 mov rsi,rbx
 mov rdx,r14
 call nebo_checkpoint_inspect
 jmp .load_return
.load_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 jmp .load_return
.load_limit:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
 jmp .load_return
.load_io:
 mov eax,NEBO_CHECKPOINT_E_IO
.load_return:
 pop rbp
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=a,rsi=a_length,rdx=b,rcx=b_length,r8=*equal.
nebo_checkpoint_compare:
 test rdi,rdi
 jz .compare_arg
 test rdx,rdx
 jz .compare_arg
 test r8,r8
 jz .compare_arg
 xor r9d,r9d
 cmp rsi,rcx
 jne .compare_publish
 xor eax,eax
.compare_loop:
 cmp rax,rsi
 jae .compare_equal
 mov r10b,[rdi+rax]
 cmp r10b,[rdx+rax]
 jne .compare_publish
 inc rax
 jmp .compare_loop
.compare_equal:
 mov r9d,1
.compare_publish:
 mov [r8],r9
 xor eax,eax
 ret
.compare_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 ret

; rdi=*slot,rsi=slot_count in 1..8.
nebo_checkpoint_rotate:
 test rdi,rdi
 jz .rotate_arg
 test rsi,rsi
 jz .rotate_limit
 cmp rsi,NEBO_CHECKPOINT_MAX_ROTATIONS
 ja .rotate_limit
 mov rax,[rdi]
 cmp rax,rsi
 jae .rotate_arg
 inc rax
 xor edx,edx
 div rsi
 mov [rdi],rdx
 xor eax,eax
 ret
.rotate_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 ret
.rotate_limit:
 mov eax,NEBO_CHECKPOINT_E_LIMIT
 ret

; rdi=seed,rsi=*dataset_seed,rdx=*sampler_seed.
nebo_checkpoint_seed_all:
 test rdi,rdi
 jz .seed_arg
 test rsi,rsi
 jz .seed_arg
 test rdx,rdx
 jz .seed_arg
 mov rax,rdi
 mov rcx,0x9e3779b97f4a7c15
 add rax,rcx
 mov r8,rax
 shr r8,30
 xor rax,r8
 mov rcx,0xbf58476d1ce4e5b9
 imul rax,rcx
 mov r8,rax
 shr r8,27
 xor rax,r8
 mov rcx,0x94d049bb133111eb
 imul rax,rcx
 mov r8,rax
 shr r8,31
 xor rax,r8
 mov [rsi],rax
 mov rcx,0x9e3779b97f4a7c15
 add rax,rcx
 mov r8,rax
 shr r8,30
 xor rax,r8
 mov rcx,0xbf58476d1ce4e5b9
 imul rax,rcx
 mov r8,rax
 shr r8,27
 xor rax,r8
 mov rcx,0x94d049bb133111eb
 imul rax,rcx
 mov r8,rax
 shr r8,31
 xor rax,r8
 mov [rdx],rax
 xor eax,eax
 ret
.seed_arg:
 mov eax,NEBO_CHECKPOINT_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
