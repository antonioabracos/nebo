bits 64
default rel
%include "compiler/semantic/system/filesystem_contract.inc"
%include "runtime/core/runtime_core.inc"
extern nebo_path_parse
extern nebo_path_join
extern nebo_path_is_absolute
extern nebo_path_filename
extern nebo_file_capability_init
extern nebo_file_read_text
extern nebo_file_write_text
extern nebo_runtime_trap
global nebo_runtime_filesystem_public
section .rodata
fs_current_root: db '.',0
section .text
; op, caller-owned 4384-byte frame. The File convenience profile grants only
; the current execution directory, uses native openat2 beneath/no-symlink
; resolution and closes both the file and the root descriptor on every path.
; Path is a nominal immutable 48-byte native descriptor, never an ambient fd.
nebo_runtime_filesystem_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rsi
 mov r12,rdi
 mov qword [rbx+48],-1
 cmp edi,1
 je .parse_text
 cmp edi,2
 je .absolute
 cmp edi,3
 je .filename
 cmp edi,4
 je .normalize
 cmp edi,5
 je .join
 cmp edi,10
 je .read
 cmp edi,11
 je .write
 jmp .bad
.parse_text:
 mov rax,[rbx]
 mov rdi,[rax]
 mov rsi,[rax+8]
 jmp .parse
.normalize:
 mov rax,[rbx]
 mov rdi,[rax+NEBO_PATH_DATA]
 mov rsi,[rax+NEBO_PATH_LENGTH]
.parse:
 lea rdx,[rbx+256]
 mov ecx,4096
 call nebo_path_parse
 jmp .path_result
.join:
 mov rax,[rbx]
 mov rdi,[rax+NEBO_PATH_DATA]
 mov rsi,[rax+NEBO_PATH_LENGTH]
 mov rax,[rbx+8]
 mov rdx,[rax+NEBO_PATH_DATA]
 mov rcx,[rax+NEBO_PATH_LENGTH]
 lea r8,[rbx+256]
 mov r9d,4096
 call nebo_path_join
.path_result:
 test eax,eax
 jnz .bad
 lea rax,[rbx+256]
 mov [rbx+128+NEBO_PATH_DATA],rax
 mov [rbx+128+NEBO_PATH_LENGTH],rdx
 mov [rbx+128+NEBO_PATH_COMPONENTS],rcx
 mov [rbx+128+NEBO_PATH_FLAGS],r8
 mov qword [rbx+128+NEBO_PATH_ROOT_ID],0
 mov byte [rax+rdx],0
 mov r8,14695981039346656037
 mov r9,1099511628211
 xor ecx,ecx
.path_hash:
 cmp rcx,rdx
 jae .path_hashed
 movzx esi,byte [rax+rcx]
 xor r8,rsi
 imul r8,r9
 inc rcx
 jmp .path_hash
.path_hashed:
 mov [rbx+128+NEBO_PATH_HASH],r8
 lea rax,[rbx+128]
 jmp .done
.absolute:
 mov rax,[rbx]
 mov rdi,[rax+NEBO_PATH_DATA]
 mov rsi,[rax+NEBO_PATH_LENGTH]
 call nebo_path_is_absolute
 jmp .done
.filename:
 mov rax,[rbx]
 mov r13,[rax+NEBO_PATH_DATA]
 mov rdi,r13
 mov rsi,[rax+NEBO_PATH_LENGTH]
 call nebo_path_filename
 test rax,rax
 js .empty_text
 lea rsi,[r13+rax]
 mov r14,rdx
 lea rdi,[rbx+256]
 mov rcx,rdx
 rep movsb
 jmp .text_result
.empty_text:
 xor r14d,r14d
 jmp .text_result
.read:
 cmp qword [rbx+8],1
 jne .bad
 mov r14,[rbx+16]
 test r14,r14
 jle .bad
 cmp r14,4096
 ja .bad
 mov r15d,NEBO_FILE_CAP_READ | NEBO_FILE_CAP_TRAVERSE
 jmp .open_root
.write:
 cmp qword [rbx+16],1
 jne .bad
 cmp qword [rbx+32],2
 ja .bad
 mov rax,[rbx+8]
 mov r14,[rax+8]
 cmp r14,4096
 ja .bad
 mov r15d,NEBO_FILE_CAP_WRITE | NEBO_FILE_CAP_CREATE | NEBO_FILE_CAP_TRAVERSE
 cmp qword [rbx+32],2
 jne .open_root
 or r15d,NEBO_FILE_CAP_DELETE
.open_root:
 mov rax,[rbx]
 test qword [rax+NEBO_PATH_FLAGS],NEBO_PATH_FLAG_ABSOLUTE
 jnz .bad
 mov eax,257
 mov edi,-100
 lea rsi,[rel fs_current_root]
 mov edx,0x90000 ; O_DIRECTORY | O_CLOEXEC, read-only root descriptor
 xor r10d,r10d
 syscall
 test rax,rax
 js .bad
 mov [rbx+48],rax
 lea rdi,[rbx+64]
 mov rsi,rax
 mov edx,1
 mov rcx,r15
 mov r8d,1
 mov r9d,4097
 call nebo_file_capability_init
 test eax,eax
 jnz .bad
 mov rax,[rbx]
 lea rdi,[rbx+64]
 mov rsi,[rax+NEBO_PATH_DATA]
 mov rdx,[rax+NEBO_PATH_LENGTH]
 cmp r12,11
 je .perform_write
 lea rcx,[rbx+256]
 mov r8,r14
 call nebo_file_read_text
 test eax,eax
 jnz .bad
 mov r14,rdx
 call .close_root
.text_result:
 lea rax,[rbx+256]
 mov [rbx+128],rax
 mov [rbx+136],r14
 mov qword [rbx+144],0
 mov word [rbx+148],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 lea rax,[rbx+128]
 jmp .done
.perform_write:
 mov rax,[rbx+8]
 mov rcx,[rax]
 mov r8,[rax+8]
 mov r9,[rbx+32]
 call nebo_file_write_text
 test eax,eax
 jnz .bad
 mov r14,rdx
 call .close_root
 mov rax,r14
 jmp .done
.close_root:
 mov rdi,[rbx+48]
 test rdi,rdi
 js .closed
 mov eax,3
 syscall
 mov qword [rbx+48],-1
.closed:
 ret
.bad:
 call .close_root
 mov edi,NEBO_RUNTIME_TRAP_CONTRACT_ASSERTION
 call nebo_runtime_trap
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
