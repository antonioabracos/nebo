; PLUGINS-FFI-E-EXTENSIBILIDADE-F07 bounded, redacted probabilistic-report CLI surface.
%ifndef NEBO_PROBABILISTIC_REPORT_CLI_INC
%define NEBO_PROBABILISTIC_REPORT_CLI_INC 1

%define NEBO_PROB_REPORT_SIZE 64
%define NEBO_PROB_REPORT_VERSION 1
%define NEBO_PROB_REPORT_REDACTED 1

section .rodata
cli_report_heading: db 'probabilistic-report v1',10,'model='
cli_report_heading_end:
cli_inference: db 'inference='
cli_inference_end:
cli_seed: db 'seed='
cli_seed_end:
cli_diagnostics: db 'diagnostics='
cli_diagnostics_end:
cli_provenance: db 'provenance='
cli_provenance_end:
cli_privacy: db 'privacy=redacted',10
cli_privacy_end:
cli_report_error: db 'NG37_F0702: invalid, unredacted or corrupt probabilistic report artifact',10
cli_report_error_end:
cli_hex_digits: db '0123456789abcdef'

section .bss
cli_hex_buffer: resb 19

section .text
; Validate a fixed, little-endian NBPRB001 record already read into cli_source.
; Bytes 0..55 are authenticated by the FNV-1a digest stored at byte 56.
cli_probabilistic_report:
 push rbx
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],NEBO_PROB_REPORT_SIZE
 jne .invalid
 lea rbx,[rel cli_source]
 cmp dword [rbx],0x5250424e       ; NBPR
 jne .invalid
 cmp dword [rbx+4],0x31303042     ; B001
 jne .invalid
 cmp qword [rbx+8],NEBO_PROB_REPORT_VERSION
 jne .invalid
 cmp qword [rbx+16],NEBO_PROB_REPORT_REDACTED
 jne .invalid
 cmp qword [rbx+24],0
 je .invalid
 cmp qword [rbx+32],0
 je .invalid
 cmp qword [rbx+48],2
 ja .invalid
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.digest:
 movzx edx,byte [rbx+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 cmp rcx,56
 jb .digest
 cmp rax,[rbx+56]
 jne .invalid
 lea rdi,[rel cli_report_heading]
 mov esi,cli_report_heading_end-cli_report_heading
 call cli_write_stdout
 mov rdi,[rbx+24]
 call cli_write_hex_line
 lea rdi,[rel cli_inference]
 mov esi,cli_inference_end-cli_inference
 call cli_write_stdout
 mov rdi,[rbx+32]
 call cli_write_hex_line
 lea rdi,[rel cli_seed]
 mov esi,cli_seed_end-cli_seed
 call cli_write_stdout
 mov rdi,[rbx+40]
 call cli_write_hex_line
 lea rdi,[rel cli_diagnostics]
 mov esi,cli_diagnostics_end-cli_diagnostics
 call cli_write_stdout
 mov rdi,[rbx+48]
 call cli_write_hex_line
 lea rdi,[rel cli_provenance]
 mov esi,cli_provenance_end-cli_provenance
 call cli_write_stdout
 mov rdi,[rbx+56]
 call cli_write_hex_line
 lea rdi,[rel cli_privacy]
 mov esi,cli_privacy_end-cli_privacy
 call cli_write_stdout
 xor eax,eax
 pop rbx
 ret
.invalid:
 lea rdi,[rel cli_report_error]
 mov esi,cli_report_error_end-cli_report_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 pop rbx
 ret

; rdi=value; write exactly 0x + 16 lowercase digits + newline.
cli_write_hex_line:
 lea r8,[rel cli_hex_buffer]
 mov byte [r8],'0'
 mov byte [r8+1],'x'
 mov ecx,16
 mov edx,2
 mov r9,rdi
 lea r10,[rel cli_hex_digits]
.hex:
 mov rax,r9
 shr rax,60
 mov al,[r10+rax]
 mov [r8+rdx],al
 shl r9,4
 inc rdx
 dec rcx
 jnz .hex
 mov byte [r8+18],10
 mov rdi,r8
 mov esi,19
 jmp cli_write_stdout

%endif
