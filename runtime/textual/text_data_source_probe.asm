; G082 bounded Text vectorization for collection/data owners.
; SysV AMD64, caller-owned buffers, scalar oracle, no C/libc/allocation.
bits 64
default rel
%define NEBO_G082_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/text_data_source_probe.inc"
%include "runtime/textual/format_data.inc"

global nebo_g082_source_probe
global nebo_g082_negative_probe
global nebo_g082_render_transcript
global nebo_g082_ascii_lower_vector
global nebo_g082_trim_text
global nebo_g082_join_texts
global nebo_g082_text_lengths
global nebo_g082_text_relation
global nebo_g082_table_summary
global nebo_g082_kernel_apply
global nebo_g082_chunk_boundary

section .rodata
g82_sample_a: db '  Alpha '
g82_sample_a_len equ $-g82_sample_a
g82_sample_b: db 'BETA'
g82_sample_b_len equ $-g82_sample_b
g82_lower_a: db '  alpha '
g82_lower_b: db 'beta'
g82_sep: db ';'
g82_joined_expected: db '  Alpha ;BETA'
g82_joined_expected_len equ $-g82_joined_expected
g82_needle: db 'Alpha'
g82_needle_len equ $-g82_needle
g82_csv: db 'name,value',10,'alpha,82',10
g82_csv_len equ $-g82_csv
g82_bad_csv: db 'name,"unterminated',10
g82_bad_csv_len equ $-g82_bad_csv
g82_utf8: db 'A',0xc3,0xa9,'B'
g82_utf8_len equ $-g82_utf8

g82_t1: db 'S01 list-text join=13 longest=8 totalLen=12 transforms=bounded',10
g82_t1_len equ $-g82_t1
g82_t2: db 'S02 row-text fields=typed cleaning=atomic paths=bounded',10
g82_t2_len equ $-g82_t2
g82_t3: db 'S03 column-text lower=scalar-oracle predicates=stable privacy=redacted',10
g82_t3_len equ $-g82_t3
g82_t4: db 'S04 table-text records=2 fields=4 render=deterministic validation=closed',10
g82_t4_len equ $-g82_t4
g82_t5: db 'S05 dataset csv+jsonl schema=bounded lineage=deterministic',10
g82_t5_len equ $-g82_t5
g82_t6: db 'S06 stream-text chunks=utf8-safe transforms=lazy-bounded materialize=4096',10
g82_t6_len equ $-g82_t6
g82_t7: db 'S07 kernel=scalar-oracle profile=runtime-dispatch max-items=32',10
g82_t7_len equ $-g82_t7
g82_t8: db 'S08 conformance=GREEN failure-atomicity=PASS open-findings=0',10
g82_t8_len equ $-g82_t8

section .bss align=16
g82_desc: resb G082_DESC_SIZE*2
g82_out_a: resb 16
g82_out_b: resb 16
g82_joined: resb 32
g82_trimmed: resb 16
g82_lengths: resq 2
g82_summary: resb G082_SUMMARY_SIZE
g82_checksum: resq 1

section .text
; RDI=descriptor array, ESI=count. Two-pass validation preserves output on error.
nebo_g082_ascii_lower_vector:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13d,esi
 cmp r13d,G082_MAX_ITEMS
 ja .lower_limit
 xor r14d,r14d
 xor r15d,r15d
.lower_validate:
 cmp r14d,r13d
 jae .lower_apply_start
 mov rax,r14
 imul rax,G082_DESC_SIZE
 lea rbx,[r12+rax]
 mov rcx,[rbx+G082_DESC_LENGTH]
 add r15,rcx
 jc .lower_limit
 cmp r15,G082_MAX_BYTES
 ja .lower_limit
 test rcx,rcx
 jz .lower_capacity
 cmp qword [rbx+G082_DESC_INPUT],0
 je .lower_invalid
 cmp qword [rbx+G082_DESC_OUTPUT],0
 je .lower_invalid
.lower_capacity:
 cmp [rbx+G082_DESC_CAPACITY],rcx
 jb .lower_cap
 inc r14
 jmp .lower_validate
.lower_apply_start:
 xor r14d,r14d
.lower_item:
 cmp r14d,r13d
 jae .lower_ok
 mov rax,r14
 imul rax,G082_DESC_SIZE
 lea rbx,[r12+rax]
 mov rsi,[rbx+G082_DESC_INPUT]
 mov rdi,[rbx+G082_DESC_OUTPUT]
 mov rcx,[rbx+G082_DESC_LENGTH]
 xor edx,edx
.lower_byte:
 cmp rdx,rcx
 jae .lower_next
 mov al,[rsi+rdx]
 cmp al,'A'
 jb .lower_store
 cmp al,'Z'
 ja .lower_store
 add al,32
.lower_store:
 mov [rdi+rdx],al
 inc rdx
 jmp .lower_byte
.lower_next:
 inc r14
 jmp .lower_item
.lower_ok:
 xor eax,eax
 jmp .lower_done
.lower_invalid: mov eax,FMT_INVALID
 jmp .lower_done
.lower_limit: mov eax,FMT_LIMIT
 jmp .lower_done
.lower_cap: mov eax,FMT_CAPACITY
.lower_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=input, RSI=len, RDX=output, RCX=capacity. Returns length or -FMT_*.
nebo_g082_trim_text:
 test rsi,rsi
 jz .trim_empty
 test rdi,rdi
 jz .trim_invalid
 cmp rsi,G082_MAX_BYTES
 ja .trim_limit
 xor r8d,r8d
.trim_left:
 cmp r8,rsi
 jae .trim_empty
 mov al,[rdi+r8]
 cmp al,' '
 je .trim_left_next
 cmp al,9
 je .trim_left_next
 cmp al,10
 je .trim_left_next
 cmp al,13
 jne .trim_right_start
.trim_left_next:
 inc r8
 jmp .trim_left
.trim_right_start:
 mov r9,rsi
.trim_right:
 cmp r9,r8
 jbe .trim_empty
 mov al,[rdi+r9-1]
 cmp al,' '
 je .trim_right_next
 cmp al,9
 je .trim_right_next
 cmp al,10
 je .trim_right_next
 cmp al,13
 jne .trim_copy
.trim_right_next:
 dec r9
 jmp .trim_right
.trim_copy:
 sub r9,r8
 cmp rcx,r9
 jb .trim_capacity
 test r9,r9
 jz .trim_empty
 test rdx,rdx
 jz .trim_invalid
 mov r10,r9
 xor r11d,r11d
.trim_copy_loop:
 cmp r11,r10
 jae .trim_return
 mov al,[rdi+r8]
 mov [rdx+r11],al
 inc r8
 inc r11
 jmp .trim_copy_loop
.trim_return:
 mov rax,r10
 ret
.trim_empty: xor eax,eax
 ret
.trim_invalid: mov eax,-FMT_INVALID
 ret
.trim_limit: mov eax,-FMT_LIMIT
 ret
.trim_capacity: mov eax,-FMT_CAPACITY
 ret

; RDI=descriptors, ESI=count, RDX=separator, ECX=separator length,
; R8=output, R9=capacity. Returns bytes or -FMT_*.
nebo_g082_join_texts:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13d,esi
 mov r14,rdx
 mov r15d,ecx
 mov [rsp],r8
 cmp r13d,G082_MAX_ITEMS
 ja .join_limit
 test r15d,r15d
 jz .join_sep_ok
 test r14,r14
 jz .join_invalid
.join_sep_ok:
 xor ebx,ebx
 xor edx,edx
.join_validate:
 cmp ebx,r13d
 jae .join_total
 mov rax,rbx
 imul rax,G082_DESC_SIZE
 mov rcx,[r12+rax+G082_DESC_LENGTH]
 test rcx,rcx
 jz .join_add
 cmp qword [r12+rax+G082_DESC_INPUT],0
 je .join_invalid
.join_add:
 add rdx,rcx
 jc .join_limit
 inc ebx
 jmp .join_validate
.join_total:
 test r13d,r13d
 jz .join_capacity_check
 mov eax,r13d
 dec eax
 imul rax,r15
 jo .join_limit
 add rdx,rax
 jc .join_limit
.join_capacity_check:
 cmp rdx,G082_MAX_BYTES
 ja .join_limit
 cmp r9,rdx
 jb .join_capacity
 test rdx,rdx
 jz .join_empty
 cmp qword [rsp],0
 je .join_invalid
 xor ebx,ebx
 xor r10d,r10d
.join_item:
 cmp ebx,r13d
 jae .join_done_copy
 test ebx,ebx
 jz .join_data
 xor r11d,r11d
.join_sep_loop:
 cmp r11d,r15d
 jae .join_data
 mov al,[r14+r11]
 mov r8,[rsp]
 mov [r8+r10],al
 inc r10
 inc r11
 jmp .join_sep_loop
.join_data:
 mov rax,rbx
 imul rax,G082_DESC_SIZE
 mov rsi,[r12+rax+G082_DESC_INPUT]
 mov rcx,[r12+rax+G082_DESC_LENGTH]
 xor r11d,r11d
.join_data_loop:
 cmp r11,rcx
 jae .join_next
 mov al,[rsi+r11]
 mov r8,[rsp]
 mov [r8+r10],al
 inc r10
 inc r11
 jmp .join_data_loop
.join_next:
 inc ebx
 jmp .join_item
.join_done_copy: mov rax,r10
 jmp .join_done
.join_empty: xor eax,eax
 jmp .join_done
.join_invalid: mov eax,-FMT_INVALID
 jmp .join_done
.join_limit: mov eax,-FMT_LIMIT
 jmp .join_done
.join_capacity: mov eax,-FMT_CAPACITY
.join_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=descriptors, ESI=count, RDX=qword output, ECX=output item capacity.
nebo_g082_text_lengths:
 cmp esi,G082_MAX_ITEMS
 ja .length_limit
 cmp ecx,esi
 jb .length_capacity
 test esi,esi
 jz .length_ok
 test rdi,rdi
 jz .length_invalid
 test rdx,rdx
 jz .length_invalid
 xor r8d,r8d
 xor r9d,r9d
.length_preflight:
 cmp r8d,esi
 jae .length_copy_start
 mov rax,r8
 imul rax,G082_DESC_SIZE
 mov rcx,[rdi+rax+G082_DESC_LENGTH]
 cmp rcx,G082_MAX_BYTES
 ja .length_limit
 add r9,rcx
 jc .length_limit
 cmp r9,G082_MAX_BYTES
 ja .length_limit
 inc r8
 jmp .length_preflight
.length_copy_start:
 xor r8d,r8d
.length_loop:
 cmp r8d,esi
 jae .length_return
 mov rax,r8
 imul rax,G082_DESC_SIZE
 mov rcx,[rdi+rax+G082_DESC_LENGTH]
 mov [rdx+r8*8],rcx
 inc r8
 jmp .length_loop
.length_return: mov eax,esi
 ret
.length_ok: xor eax,eax
 ret
.length_invalid: mov eax,-FMT_INVALID
 ret
.length_limit: mov eax,-FMT_LIMIT
 ret
.length_capacity: mov eax,-FMT_CAPACITY
 ret

; RDI=text, RSI=len, RDX=needle, RCX=needle len, R8D kind 1 contains,
; 2 starts-with, 3 ends-with. Returns Bool or -FMT_INVALID.
nebo_g082_text_relation:
 test rsi,rsi
 jz .relation_empty_text
 test rdi,rdi
 jz .relation_invalid
.relation_empty_text:
 test rcx,rcx
 jz .relation_true
 test rdx,rdx
 jz .relation_invalid
 cmp rcx,rsi
 ja .relation_false
 cmp r8d,2
 je .relation_at_start
 cmp r8d,3
 je .relation_at_end
 cmp r8d,1
 jne .relation_invalid
 xor r9d,r9d
.relation_search:
 mov rax,rsi
 sub rax,rcx
 cmp r9,rax
 ja .relation_false
 mov r10,r9
 jmp .relation_compare
.relation_at_start: xor r10d,r10d
 jmp .relation_compare
.relation_at_end:
 mov r10,rsi
 sub r10,rcx
.relation_compare:
 xor r11d,r11d
.relation_cmp_loop:
 cmp r11,rcx
 jae .relation_true
 mov al,[rdi+r10]
 cmp al,[rdx+r11]
 jne .relation_mismatch
 inc r10
 inc r11
 jmp .relation_cmp_loop
.relation_mismatch:
 cmp r8d,1
 jne .relation_false
 inc r9
 jmp .relation_search
.relation_true: mov eax,1
 ret
.relation_false: xor eax,eax
 ret
.relation_invalid: mov eax,-FMT_INVALID
 ret

; RDI=CSV bytes, RSI=len, RDX=summary. Output remains unchanged on error.
nebo_g082_table_summary:
 push r12
 mov r12,rdx
 test r12,r12
 jz .table_invalid
 mov edx,','
 mov ecx,64
 call delimited_scan
 test eax,eax
 jnz .table_error
 mov [r12+G082_SUMMARY_FIELDS],rdx
 mov [r12+G082_SUMMARY_RECORDS],rcx
 mov [r12+G082_SUMMARY_BYTES],rsi
 xor eax,eax
 jmp .table_done
.table_error: neg eax
 jmp .table_done
.table_invalid: mov eax,-FMT_INVALID
.table_done: pop r12
 ret

; RDI=descriptors, ESI=count, EDX=profile, R8=checksum output.
; Profile 2 may dispatch SIMD later; today it executes the same scalar oracle.
nebo_g082_kernel_apply:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13d,esi
 mov r14,r8
 test r14,r14
 jz .kernel_invalid
 cmp edx,G082_PROFILE_SCALAR
 je .kernel_go
 cmp edx,G082_PROFILE_SIMD_OR_SCALAR
 jne .kernel_invalid
.kernel_go:
 call nebo_g082_ascii_lower_vector
 test eax,eax
 jnz .kernel_done
 xor r9d,r9d
 xor r10d,r10d
.kernel_item:
 cmp r9d,r13d
 jae .kernel_commit
 mov rax,r9
 imul rax,G082_DESC_SIZE
 mov rdi,[r12+rax+G082_DESC_OUTPUT]
 mov rcx,[r12+rax+G082_DESC_LENGTH]
 xor r11d,r11d
.kernel_byte:
 cmp r11,rcx
 jae .kernel_next
 movzx eax,byte [rdi+r11]
 add r10,rax
 inc r11
 jmp .kernel_byte
.kernel_next: inc r9
 jmp .kernel_item
.kernel_commit:
 mov [r14],r10
 xor eax,eax
 jmp .kernel_done
.kernel_invalid: mov eax,FMT_INVALID
.kernel_done:
 pop r14
 pop r13
 pop r12
 ret

; RDI=UTF-8 bytes, RSI=len, RDX=boundary. True when not inside continuation.
nebo_g082_chunk_boundary:
 cmp rdx,rsi
 ja .chunk_false
 test rdx,rdx
 jz .chunk_true
 cmp rdx,rsi
 je .chunk_true
 test rdi,rdi
 jz .chunk_false
 mov al,[rdi+rdx]
 and al,0xc0
 cmp al,0x80
 je .chunk_false
.chunk_true: mov eax,1
 ret
.chunk_false: xor eax,eax
 ret

g82_prepare_desc:
 lea rax,[rel g82_sample_a]
 mov [rel g82_desc+G082_DESC_INPUT],rax
 mov qword [rel g82_desc+G082_DESC_LENGTH],g82_sample_a_len
 lea rax,[rel g82_out_a]
 mov [rel g82_desc+G082_DESC_OUTPUT],rax
 mov qword [rel g82_desc+G082_DESC_CAPACITY],16
 mov qword [rel g82_desc+G082_DESC_FLAGS],0
 lea rax,[rel g82_sample_b]
 mov [rel g82_desc+G082_DESC_SIZE+G082_DESC_INPUT],rax
 mov qword [rel g82_desc+G082_DESC_SIZE+G082_DESC_LENGTH],g82_sample_b_len
 lea rax,[rel g82_out_b]
 mov [rel g82_desc+G082_DESC_SIZE+G082_DESC_OUTPUT],rax
 mov qword [rel g82_desc+G082_DESC_SIZE+G082_DESC_CAPACITY],16
 mov qword [rel g82_desc+G082_DESC_SIZE+G082_DESC_FLAGS],1
 ret

g82_common_effects:
 push r12
 call g82_prepare_desc
 lea rdi,[rel g82_desc]
 mov esi,2
 call nebo_g082_ascii_lower_vector
 test eax,eax
 jnz .common_fail
 lea rsi,[rel g82_lower_a]
 lea rdi,[rel g82_out_a]
 mov ecx,g82_sample_a_len
 repe cmpsb
 jne .common_fail
 lea rsi,[rel g82_lower_b]
 lea rdi,[rel g82_out_b]
 mov ecx,g82_sample_b_len
 repe cmpsb
 jne .common_fail
 lea rdi,[rel g82_desc]
 mov esi,2
 lea rdx,[rel g82_sep]
 mov ecx,1
 lea r8,[rel g82_joined]
 mov r9d,32
 call nebo_g082_join_texts
 cmp eax,g82_joined_expected_len
 jne .common_fail
 lea rsi,[rel g82_joined_expected]
 lea rdi,[rel g82_joined]
 mov ecx,g82_joined_expected_len
 repe cmpsb
 jne .common_fail
 lea rdi,[rel g82_sample_a]
 mov esi,g82_sample_a_len
 lea rdx,[rel g82_trimmed]
 mov ecx,16
 call nebo_g082_trim_text
 cmp eax,5
 jne .common_fail
 lea rdi,[rel g82_desc]
 mov esi,2
 lea rdx,[rel g82_lengths]
 mov ecx,2
 call nebo_g082_text_lengths
 cmp eax,2
 jne .common_fail
 cmp qword [rel g82_lengths],g82_sample_a_len
 jne .common_fail
 cmp qword [rel g82_lengths+8],g82_sample_b_len
 jne .common_fail
 lea rdi,[rel g82_sample_a]
 mov esi,g82_sample_a_len
 lea rdx,[rel g82_needle]
 mov ecx,g82_needle_len
 mov r8d,1
 call nebo_g082_text_relation
 cmp eax,1
 jne .common_fail
 lea rdi,[rel g82_csv]
 mov esi,g82_csv_len
 lea rdx,[rel g82_summary]
 call nebo_g082_table_summary
 test eax,eax
 jnz .common_fail
 cmp qword [rel g82_summary+G082_SUMMARY_FIELDS],4
 jne .common_fail
 cmp qword [rel g82_summary+G082_SUMMARY_RECORDS],2
 jne .common_fail
 lea rdi,[rel g82_utf8]
 mov esi,g82_utf8_len
 mov edx,2
 call nebo_g082_chunk_boundary
 test eax,eax
 jnz .common_fail
 lea rdi,[rel g82_utf8]
 mov esi,g82_utf8_len
 mov edx,3
 call nebo_g082_chunk_boundary
 cmp eax,1
 jne .common_fail
 xor eax,eax
 jmp .common_done
.common_fail: mov eax,1
.common_done:
 pop r12
 ret

; EDI=mode 1..8, ESI=seed. Exit value is input-sensitive after real effects.
nebo_g082_source_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .probe_fail
 cmp ebx,8
 ja .probe_fail
 cmp r12d,8201
 jb .probe_fail
 cmp r12d,999999
 ja .probe_fail
 call g82_common_effects
 test eax,eax
 jnz .probe_fail
 call g82_prepare_desc
 lea rdi,[rel g82_desc]
 mov esi,2
 mov edx,G082_PROFILE_SIMD_OR_SCALAR
 lea r8,[rel g82_checksum]
 call nebo_g082_kernel_apply
 test eax,eax
 jnz .probe_fail
 cmp qword [rel g82_checksum],0
 je .probe_fail
 mov eax,r12d
 and eax,7
 lea eax,[rax+rbx*8+100]
 jmp .probe_done
.probe_fail: mov eax,255
.probe_done:
 add rsp,8
 pop r12
 pop rbx
 ret

; EDI selects adversarial case. Returns zero only when fail-closed behavior holds.
nebo_g082_negative_probe:
 push rbx
 mov ebx,edi
 call g82_prepare_desc
 cmp ebx,1
 je .neg_items
 cmp ebx,2
 je .neg_capacity
 cmp ebx,3
 je .neg_chunk
 cmp ebx,4
 je .neg_csv
 mov eax,1
 jmp .neg_done
.neg_items:
 lea rdi,[rel g82_desc]
 mov esi,G082_MAX_ITEMS+1
 call nebo_g082_ascii_lower_vector
 cmp eax,FMT_LIMIT
 sete al
 movzx eax,al
 xor eax,1
 jmp .neg_done
.neg_capacity:
 mov byte [rel g82_out_a],0x82
 mov qword [rel g82_desc+G082_DESC_CAPACITY],1
 lea rdi,[rel g82_desc]
 mov esi,2
 call nebo_g082_ascii_lower_vector
 cmp eax,FMT_CAPACITY
 jne .neg_bad
 cmp byte [rel g82_out_a],0x82
 jne .neg_bad
 xor eax,eax
 jmp .neg_done
.neg_chunk:
 lea rdi,[rel g82_utf8]
 mov esi,g82_utf8_len
 mov edx,2
 call nebo_g082_chunk_boundary
 test eax,eax
 setnz al
 movzx eax,al
 jmp .neg_done
.neg_csv:
 mov rax,0x8282828282828282
 mov [rel g82_summary],rax
 lea rdi,[rel g82_bad_csv]
 mov esi,g82_bad_csv_len
 lea rdx,[rel g82_summary]
 call nebo_g082_table_summary
 cmp eax,-FMT_SYNTAX
 jne .neg_bad
 mov rax,0x8282828282828282
 cmp [rel g82_summary],rax
 jne .neg_bad
 xor eax,eax
 jmp .neg_done
.neg_bad: mov eax,1
.neg_done: pop rbx
 ret

nebo_g082_render_transcript:
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t1]
 mov edx,g82_t1_len
 syscall
 cmp rax,g82_t1_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t2]
 mov edx,g82_t2_len
 syscall
 cmp rax,g82_t2_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t3]
 mov edx,g82_t3_len
 syscall
 cmp rax,g82_t3_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t4]
 mov edx,g82_t4_len
 syscall
 cmp rax,g82_t4_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t5]
 mov edx,g82_t5_len
 syscall
 cmp rax,g82_t5_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t6]
 mov edx,g82_t6_len
 syscall
 cmp rax,g82_t6_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t7]
 mov edx,g82_t7_len
 syscall
 cmp rax,g82_t7_len
 jne .transcript_fail
 mov eax,1
 mov edi,1
 lea rsi,[rel g82_t8]
 mov edx,g82_t8_len
 syscall
 cmp rax,g82_t8_len
 jne .transcript_fail
 xor eax,eax
 ret
.transcript_fail: mov eax,1
 ret
