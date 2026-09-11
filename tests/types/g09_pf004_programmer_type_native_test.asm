; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PF004 native layout, padding, tag and copy-only runtime tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/aggregates/programmer_type_layout.inc"
%include "runtime/aggregates/programmer_type_runtime.inc"
extern neboc_programmer_type_layout
extern neboc_programmer_type_copy
extern neboc_programmer_type_zero
extern neboc_programmer_type_tag_validate
extern neboc_host_process_exit

section .data align=16
sizes: dq 8,8,8,8,8,8,8,8
aligns: dq 8,8,8,8,8,8,8,8
source: db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24

section .bss align=16
request: resb neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_REQUEST_SIZE
offsets: resq 8
target: resb 32

section .text
global _start
clear_request:
 lea rdi,[rel request]
 mov ecx,neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+NEBOC_LAYOUT_FLAGS_OFFSET],NEBOC_LAYOUT_FLAGS_REQUIRED
 lea rax,[rel sizes]
 mov [rel request+NEBOC_LAYOUT_SIZES_PTR_OFFSET],rax
 lea rax,[rel aligns]
 mov [rel request+NEBOC_LAYOUT_ALIGNS_PTR_OFFSET],rax
 lea rax,[rel offsets]
 mov [rel request+NEBOC_LAYOUT_OFFSETS_PTR_OFFSET],rax
 ret
run_layout:
 lea rdi,[rel request]
 call neboc_programmer_type_layout
 ret
_start:
 mov r13d,1
 ; Box<Int>: size 8, alignment 8, field 0.
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],1
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel offsets],0
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],8
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],8
 jne .fail
 inc r13d
 ; Two Int fields are declaration ordered.
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],2
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel offsets],0
 jne .fail
 cmp qword [rel offsets+8],8
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],16
 jne .fail
 inc r13d
 ; Char, Int, Bool exposes deterministic padding.
 mov qword [rel sizes],4
 mov qword [rel sizes+8],8
 mov qword [rel sizes+16],1
 mov qword [rel aligns],4
 mov qword [rel aligns+8],8
 mov qword [rel aligns+16],1
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],3
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel offsets],0
 jne .fail
 cmp qword [rel offsets+8],8
 jne .fail
 cmp qword [rel offsets+16],16
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],24
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],8
 jne .fail
 inc r13d
 ; Three Bool fields remain compact.
 mov qword [rel sizes],1
 mov qword [rel sizes+8],1
 mov qword [rel sizes+16],1
 mov qword [rel aligns],1
 mov qword [rel aligns+8],1
 mov qword [rel aligns+16],1
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],3
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel offsets+16],2
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],3
 jne .fail
 inc r13d
 ; Empty and oversized products reject.
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],2
 jne .fail
 inc r13d
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],9
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 ; Non-power-of-two alignment rejects.
 mov qword [rel sizes],8
 mov qword [rel aligns],3
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_PRODUCT
 mov qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_MEMBER_COUNT_OFFSET],1
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],3
 jne .fail
 inc r13d
 ; Mandatory representation flags reject hidden policies.
 mov qword [rel request+NEBOC_LAYOUT_FLAGS_OFFSET],7
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],4
 jne .fail
 inc r13d
 ; Unit-only sum: u32 tag at 0, reserved zeros, payload slot 8, size 8.
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_SUM
 mov qword [rel request+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET],2
 mov qword [rel request+NEBOC_LAYOUT_PAYLOAD_ALIGN_OFFSET],1
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel request+NEBOC_LAYOUT_TAG_OFFSET],0
 jne .fail
 cmp qword [rel request+NEBOC_LAYOUT_TAG_WIDTH_OFFSET],4
 jne .fail
 cmp qword [rel request+NEBOC_LAYOUT_PAYLOAD_OFFSET],8
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],8
 jne .fail
 inc r13d
 ; Int payload sum occupies 16 bytes.
 call clear_request
 mov qword [rel request+NEBOC_LAYOUT_KIND_OFFSET],NEBOC_LAYOUT_SUM
 mov qword [rel request+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET],8
 mov qword [rel request+NEBOC_LAYOUT_PAYLOAD_SIZE_OFFSET],8
 mov qword [rel request+NEBOC_LAYOUT_PAYLOAD_ALIGN_OFFSET],8
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],16
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_ALIGN_OFFSET],8
 jne .fail
 inc r13d
 ; Sixteen-byte payload still uses the frozen eight-byte payload alignment.
 mov qword [rel request+NEBOC_LAYOUT_PAYLOAD_SIZE_OFFSET],16
 call run_layout
 test eax,eax
 jnz .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_SIZE_OFFSET],24
 jne .fail
 inc r13d
 ; Sum variant count and payload alignment bounds.
 mov qword [rel request+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET],1
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 mov qword [rel request+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET],9
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 mov qword [rel request+NEBOC_LAYOUT_VARIANT_COUNT_OFFSET],2
 mov qword [rel request+NEBOC_LAYOUT_PAYLOAD_ALIGN_OFFSET],16
 call run_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel request+neboc_structs_enums_variants_e_tipos_do_programador_LAYOUT_DIAGNOSTIC_OFFSET],3
 jne .fail
 inc r13d
 ; Exact bounded copy.
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov edx,24
 call neboc_programmer_type_copy
 test eax,eax
 jnz .fail
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov ecx,24
 repe cmpsb
 jne .fail
 inc r13d
 ; Zeroing makes padding deterministic.
 lea rdi,[rel target+4]
 mov esi,4
 call neboc_programmer_type_zero
 test eax,eax
 jnz .fail
 cmp dword [rel target+4],0
 jne .fail
 inc r13d
 ; Valid and invalid sum tags.
 xor edi,edi
 mov esi,2
 call neboc_programmer_type_tag_validate
 test eax,eax
 jnz .fail
 mov edi,1
 mov esi,2
 call neboc_programmer_type_tag_validate
 test eax,eax
 jnz .fail
 inc r13d
 mov edi,2
 mov esi,2
 call neboc_programmer_type_tag_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 inc r13d
 ; Helper bounds and null guards.
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov edx,129
 call neboc_programmer_type_copy
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail
 xor edi,edi
 lea rsi,[rel source]
 mov edx,1
 call neboc_programmer_type_copy
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 inc r13d
 xor edi,edi
 call neboc_programmer_type_layout
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
