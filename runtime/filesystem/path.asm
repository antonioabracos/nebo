bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"

section .text

global nebo_path_parse
global nebo_path_normalize
global nebo_path_join
global nebo_path_is_absolute
global nebo_path_parent
global nebo_path_filename
global nebo_path_extension

; parse uses the canonical normalized representation supplied by the caller.
; rdi=input, rsi=input length, rdx=output, rcx=capacity
; eax=status, rdx=output length, rcx=component count, r8=flags.
nebo_path_parse:
 jmp nebo_path_normalize

nebo_path_normalize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 test r13,r13
 jz .invalid
 cmp r13,NEBO_PATH_MAX_BYTES
 ja .limit
 cmp r15,r13
 jb .limit
 xor ebx,ebx                 ; normalized output length
 xor r10d,r10d               ; input cursor
 xor r11d,r11d               ; component count
 mov r9d,NEBO_PATH_FLAG_NORMALIZED
 cmp byte [r12],'/'
 jne .component_loop
 or r9d,NEBO_PATH_FLAG_ABSOLUTE
 mov byte [r14],'/'
 mov ebx,1
.component_loop:
 cmp r10,r13
 jae .finish
.skip_slashes:
 cmp r10,r13
 jae .finish
 cmp byte [r12+r10],0
 je .invalid
 cmp byte [r12+r10],'/'
 jne .component_start
 inc r10
 jmp .skip_slashes
.component_start:
 mov r8,r10                  ; component start
.scan_component:
 cmp r10,r13
 jae .component_ready
 mov al,[r12+r10]
 test al,al
 jz .invalid
 cmp al,'/'
 je .component_ready
 inc r10
 jmp .scan_component
.component_ready:
 mov rax,r10
 sub rax,r8                  ; component length
 cmp rax,NEBO_PATH_MAX_COMPONENT_BYTES
 ja .limit
 cmp rax,1
 jne .maybe_parent
 cmp byte [r12+r8],'.'
 je .component_loop
.maybe_parent:
 cmp rax,2
 jne .append_component
 cmp byte [r12+r8],'.'
 jne .append_component
 cmp byte [r12+r8+1],'.'
 jne .append_component
 or r9d,NEBO_PATH_FLAG_HAS_PARENT
 test r11,r11
 jz .escape
 dec r11
 mov rdx,rbx
.rewind_component:
 test rdx,rdx
 jz .rewind_done
 cmp byte [r14+rdx-1],'/'
 je .rewind_slash
 dec rdx
 jmp .rewind_component
.rewind_slash:
 dec rdx                     ; remove separator too
.rewind_done:
 test r9d,NEBO_PATH_FLAG_ABSOLUTE
 jz .rewind_set
 test rdx,rdx
 jnz .rewind_set
 mov edx,1                   ; retain root slash
.rewind_set:
 mov rbx,rdx
 jmp .component_loop
.append_component:
 cmp r11,NEBO_PATH_MAX_COMPONENTS
 jae .limit
 test r11,r11
 jz .copy_component
 cmp rbx,r15
 jae .limit
 mov byte [r14+rbx],'/'
 inc rbx
.copy_component:
 lea rdx,[rbx+rax]
 cmp rdx,r15
 ja .limit
 lea rdi,[r12+r8]
 lea rsi,[r14+rbx]
 xor ecx,ecx
.copy_loop:
 cmp rcx,rax
 jae .copied
 mov dl,[rdi+rcx]
 mov [rsi+rcx],dl
 inc rcx
 jmp .copy_loop
.copied:
 add rbx,rax
 inc r11
 jmp .component_loop
.finish:
 test r11,r11
 jnz .success
 test r9d,NEBO_PATH_FLAG_ABSOLUTE
 jnz .success
 cmp r15,1
 jb .limit
 mov byte [r14],'.'
 mov ebx,1
.success:
 xor eax,eax
 mov rdx,rbx
 mov rcx,r11
 mov r8,r9
 jmp .return
.invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .error_return
.escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jmp .error_return
.limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.error_return:
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=base, rsi=base length, rdx=child, rcx=child length,
; r8=output, r9=capacity. Child must be relative.
nebo_path_join:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .join_invalid
 test r14,r14
 jz .join_invalid
 test rbx,rbx
 jz .join_invalid
 test r15,r15
 jz .join_invalid
 cmp byte [r14],'/'
 je .join_escape
 mov rax,r13
 add rax,r15
 jc .join_limit
 inc rax
 cmp rax,r9
 ja .join_limit
 cmp rax,NEBO_PATH_MAX_BYTES
 ja .join_limit
 xor ecx,ecx
.copy_base:
 cmp rcx,r13
 jae .base_done
 mov dl,[r12+rcx]
 test dl,dl
 jz .join_invalid
 mov [rbx+rcx],dl
 inc rcx
 jmp .copy_base
.base_done:
 test r13,r13
 jz .copy_child_setup
 cmp byte [rbx+r13-1],'/'
 je .copy_child_setup
 mov byte [rbx+r13],'/'
 inc r13
.copy_child_setup:
 lea rdi,[rbx+r13]
 xor ecx,ecx
.copy_child:
 cmp rcx,r15
 jae .join_normalize
 mov dl,[r14+rcx]
 test dl,dl
 jz .join_invalid
 mov [rdi+rcx],dl
 inc rcx
 jmp .copy_child
.join_normalize:
 lea rsi,[r13+r15]
 mov rdi,rbx
 mov rdx,rbx
 mov rcx,r9
 call nebo_path_normalize
 jmp .join_return
.join_invalid:
 mov eax,NEBO_FILE_ERROR_INVALID_PATH
 jmp .join_error
.join_escape:
 mov eax,NEBO_FILE_ERROR_PATH_ESCAPE
 jmp .join_error
.join_limit:
 mov eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
.join_error:
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
.join_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=path, rsi=len -> eax Bool
nebo_path_is_absolute:
 xor eax,eax
 test rdi,rdi
 jz .abs_return
 test rsi,rsi
 jz .abs_return
 cmp byte [rdi],'/'
 sete al
.abs_return:
 ret

; Normalized path helpers. Range result is rax=offset or -1, rdx=length.
nebo_path_parent:
 mov rax,-1
 xor edx,edx
 test rdi,rdi
 jz .parent_return
 test rsi,rsi
 jz .parent_return
 mov rcx,rsi
 cmp rcx,1
 je .parent_return
.parent_scan:
 dec rcx
 cmp byte [rdi+rcx],'/'
 je .parent_found
 test rcx,rcx
 jnz .parent_scan
 ret
.parent_found:
 xor eax,eax
 mov rdx,rcx
 test rcx,rcx
 jnz .parent_return
 mov edx,1
.parent_return:
 ret

nebo_path_filename:
 mov rax,-1
 xor edx,edx
 test rdi,rdi
 jz .filename_return
 test rsi,rsi
 jz .filename_return
 cmp rsi,1
 jne .filename_scan_setup
 cmp byte [rdi],'/'
 je .filename_return
.filename_scan_setup:
 mov rcx,rsi
.filename_scan:
 test rcx,rcx
 jz .filename_whole
 dec rcx
 cmp byte [rdi+rcx],'/'
 jne .filename_scan
 lea rax,[rcx+1]
 mov rdx,rsi
 sub rdx,rax
 ret
.filename_whole:
 xor eax,eax
 mov rdx,rsi
.filename_return:
 ret

nebo_path_extension:
 push rbx
 mov rbx,rdi
 call nebo_path_filename
 cmp rax,-1
 je .ext_none
 mov rcx,rax                 ; filename start
 lea r8,[rax+rdx]            ; one past filename
 mov r9,r8
.ext_scan:
 cmp r9,rcx
 jbe .ext_none
 dec r9
 cmp byte [rbx+r9],'.'
 jne .ext_scan
 cmp r9,rcx                  ; leading dot is not an extension
 je .ext_none
 lea rax,[r9+1]
 mov rdx,r8
 sub rdx,rax
 pop rbx
 ret
.ext_none:
 mov rax,-1
 xor edx,edx
 pop rbx
 ret
