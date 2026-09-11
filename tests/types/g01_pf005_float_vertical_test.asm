bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/types/foundation_scalar_descriptor.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "runtime/scalars/float/foundation_float_runtime.inc"

extern neboc_type_table_init
extern neboc_type_table_declare_builtins
extern neboc_type_table_declare_intrinsic_types
extern neboc_type_table_declare_foundation_float
extern neboc_type_table_freeze
extern neboc_type_table_get
extern neboc_foundation_scalar_descriptor_get
extern neboc_foundation_scalar_descriptor_validate_contract
extern neboc_foundation_float_materialize_literal
extern neboc_foundation_float_runtime_add
extern neboc_foundation_float_runtime_sub
extern neboc_foundation_float_runtime_mul
extern neboc_foundation_float_runtime_div
extern neboc_foundation_float_runtime_neg
extern neboc_foundation_float_runtime_classify
extern neboc_host_process_exit

section .rodata
long_literal: db '123456789012345678901234567890.625'
long_literal_len equ $-long_literal
literal_3_5: db '3.5'
literal_3_5_len equ $-literal_3_5
invalid_literal: db '1e2'
invalid_literal_len equ $-invalid_literal

section .bss align=16
type_table: resb NEBOC_TYPE_TABLE_SIZE
type_entries: resb NEBOC_TYPE_V02_MAX_COUNT*NEBOC_TYPE_ENTRY_SIZE
out_entry: resq 1
out_descriptor: resq 1
request: resb NEBOC_FLOAT_LOWERING_REQUEST_SIZE
out_bits_a: resq 1
out_bits_b: resq 1
out_class: resq 1
out_flags: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rsi,[rsp+16]
 xor ecx,ecx
.parse:
 movzx eax,byte [rsi]
 test al,al
 jz .parsed
 cmp al,'0'
 jb test_usage
 cmp al,'9'
 ja test_usage
 imul ecx,ecx,10
 sub eax,'0'
 add ecx,eax
 inc rsi
 jmp .parse
.parsed:
 cmp ecx,1
 jb test_usage
 cmp ecx,12
 ja test_usage
 call reset_all
 cmp ecx,1
 je scenario_1
 cmp ecx,2
 je scenario_2
 cmp ecx,3
 je scenario_3
 cmp ecx,4
 je scenario_4
 cmp ecx,5
 je scenario_5
 cmp ecx,6
 je scenario_6
 cmp ecx,7
 je scenario_7
 cmp ecx,8
 je scenario_8
 cmp ecx,9
 je scenario_9
 cmp ecx,10
 je scenario_10
 cmp ecx,11
 je scenario_11
 jmp scenario_12

; Float is the first non-renumbering v0.2 public TypeId.
scenario_1:
 call neboc_foundation_scalar_descriptor_validate_contract
 test eax,eax
 jnz test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 lea rsi,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_descriptor]
 cmp qword [rbx+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne test_fail
 mov rax,[rbx+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rax,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jz test_fail
 test rax,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_PENDING
 jnz test_fail
 cmp qword [rbx+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_BIT_WIDTH_OFFSET],64
 jne test_fail
 cmp qword [rbx+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rbx+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_ALIGNMENT_OFFSET],8
 jne test_fail
 jmp test_pass

scenario_2:
 lea rdi,[rel type_table]
 lea rsi,[rel type_entries]
 mov edx,NEBOC_TYPE_V02_MAX_COUNT
 call neboc_type_table_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel type_table]
 call neboc_type_table_declare_builtins
 test eax,eax
 jnz test_fail
 lea rdi,[rel type_table]
 call neboc_type_table_declare_intrinsic_types
 test eax,eax
 jnz test_fail
 lea rdi,[rel type_table]
 call neboc_type_table_declare_foundation_float
 test eax,eax
 jnz test_fail
 cmp qword [rel type_table+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_V02_MAX_COUNT
 jne test_fail
 lea rdi,[rel type_table]
 call neboc_type_table_freeze
 test eax,eax
 jnz test_fail
 cmp qword [rel type_table+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_FROZEN
 jne test_fail
 cmp qword [rel type_table+NEBOC_TYPE_TABLE_HASH_OFFSET],0
 je test_fail
 lea rdi,[rel type_table]
 mov esi,NEBOC_TYPE_ID_FLOAT
 lea rdx,[rel out_entry]
 call neboc_type_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_entry]
 cmp qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne test_fail
 cmp qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_FLOAT
 jne test_fail
 cmp qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 jne test_fail
 jmp test_pass

scenario_3:
 lea rdi,[rel long_literal]
 mov esi,long_literal_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],30
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],3
 jne test_fail
 cmp qword [rel out_bits_a],0
 je test_fail
 jmp test_pass

scenario_4:
 mov rax,0x3ff8000000000000       ; 1.5
 movq xmm0,rax
 mov rax,0x4004000000000000       ; 2.5
 movq xmm1,rax
 call neboc_foundation_float_runtime_add
 movq rax,xmm0
 mov rdx,0x4010000000000000       ; 4.0
 cmp rax,rdx
 jne test_fail
 jmp test_pass

scenario_5:
 mov rax,0x4020000000000000       ; 8.0
 movq xmm0,rax
 mov rax,0x4008000000000000       ; 3.0
 movq xmm1,rax
 call neboc_foundation_float_runtime_sub
 movq rax,xmm0
 mov rdx,0x4014000000000000       ; 5.0
 cmp rax,rdx
 jne test_fail
 jmp test_pass

scenario_6:
 mov rax,0x4000000000000000       ; 2.0
 movq xmm0,rax
 mov rax,0x4010000000000000       ; 4.0
 movq xmm1,rax
 call neboc_foundation_float_runtime_mul
 movq rax,xmm0
 mov rdx,0x4020000000000000       ; 8.0
 cmp rax,rdx
 jne test_fail
 jmp test_pass

scenario_7:
 mov rax,0x4022000000000000       ; 9.0
 movq xmm0,rax
 mov rax,0x4008000000000000       ; 3.0
 movq xmm1,rax
 call neboc_foundation_float_runtime_div
 movq rax,xmm0
 mov rdx,0x4008000000000000       ; 3.0
 cmp rax,rdx
 jne test_fail
 jmp test_pass

scenario_8:
 mov rax,0x3ff0000000000000       ; 1.0
 movq xmm0,rax
 pxor xmm1,xmm1
 call neboc_foundation_float_runtime_div
 movq rdi,xmm0
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_INFINITY
 jne test_fail
 jmp test_pass

scenario_9:
 pxor xmm0,xmm0
 pxor xmm1,xmm1
 call neboc_foundation_float_runtime_div
 movq rdi,xmm0
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_NAN
 jne test_fail
 jmp test_pass

scenario_10:
 pxor xmm0,xmm0
 call neboc_foundation_float_runtime_neg
 movq rax,xmm0
 mov rdx,0x8000000000000000
 cmp rax,rdx
 jne test_fail
 jmp test_pass

scenario_11:
 lea rdi,[rel invalid_literal]
 mov esi,invalid_literal_len
 lea rdx,[rel out_bits_a]
 call setup_request
 lea rdi,[rel request]
 call neboc_foundation_float_materialize_literal
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_INVALID_SHAPE
 jne test_fail
 cmp qword [rel out_bits_a],0
 jne test_fail
 jmp test_pass

scenario_12:
 lea rdi,[rel literal_3_5]
 mov esi,literal_3_5_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 call reset_request_only
 lea rdi,[rel literal_3_5]
 mov esi,literal_3_5_len
 lea rdx,[rel out_bits_b]
 call setup_request
 call expect_materialize_ok
 mov rax,[rel out_bits_a]
 cmp rax,[rel out_bits_b]
 jne test_fail
 xor edi,edi
 call neboc_type_table_declare_foundation_float
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 xor edi,edi
 call neboc_foundation_float_materialize_literal
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 jmp test_pass

setup_request:
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rdi
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rsi
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rdx
 ret

expect_materialize_ok:
 sub rsp,8
 lea rdi,[rel request]
 call neboc_foundation_float_materialize_literal
 add rsp,8
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_NONE
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_FLAGS_OFFSET],NEBOC_FLOAT_LOWERING_REQUIRED_FLAGS
 jne test_fail
 ret

reset_request_only:
 lea rdi,[rel request]
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ret

reset_all:
 push rcx
 lea rdi,[rel type_table]
 mov ecx,NEBOC_TYPE_TABLE_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel type_entries]
 mov ecx,(NEBOC_TYPE_V02_MAX_COUNT*NEBOC_TYPE_ENTRY_SIZE)/8
 xor eax,eax
 rep stosq
 call reset_request_only
 mov qword [rel out_entry],0
 mov qword [rel out_descriptor],0
 mov qword [rel out_bits_a],0
 mov qword [rel out_bits_b],0
 mov qword [rel out_class],0
 mov qword [rel out_flags],0
 pop rcx
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
test_fail:
 mov edi,1
 call neboc_host_process_exit
test_usage:
 mov edi,64
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
