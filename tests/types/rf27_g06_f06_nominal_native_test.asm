; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F06 identity, A0 enum layout, pass/return and active drop vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/nominal_types.inc"
%include "compiler/lowering/aggregates/nominal_plan.inc"

extern neboc_nominal_analyze
extern neboc_nominal_lower
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_NOM_REQUEST_SIZE
variants: resb NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_SIZE
plan: resb NEBOC_NOM_PLAN_SIZE

section .text
global _start

reset_request:
 lea rdi,[rel request]
 mov ecx,NEBOC_NOM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel variants]
 mov ecx,NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,NEBOC_NOM_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel variants]
 mov [rel request+NEBOC_NOM_VARIANTS_OFFSET],rax
 mov qword [rel request+NEBOC_NOM_VARIANT_CAPACITY_OFFSET],NEBOC_NOM_MAX_VARIANTS
 mov qword [rel request+NEBOC_NOM_FOUND_OFFSET],1
 mov qword [rel request+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_PARSED | NEBOC_NOM_FLAG_ABI_A0
 ret

analyze:
 lea rdi,[rel request]
 jmp neboc_nominal_analyze

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_nominal_lower

enum_two:
 mov qword [rel request+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 mov qword [rel request+NEBOC_NOM_TYPE_KEY_OFFSET],0x1234
 mov qword [rel request+NEBOC_NOM_VARIANT_COUNT_OFFSET],2
 mov qword [rel variants+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET],0x1111
 mov qword [rel variants+NEBOC_NOM_VARIANT_SIZE+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET],0x2222
 ret

_start:
 ; V01 alias identity is exactly its canonical underlying TypeKey.
 call reset_request
 mov qword [rel request+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ALIAS
 mov qword [rel request+NEBOC_NOM_TYPE_KEY_OFFSET],0x9999
 mov qword [rel request+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],42
 call analyze
 test eax,eax
 jnz .fail1
 cmp qword [rel request+NEBOC_NOM_TYPE_KEY_OFFSET],NEBOC_NOM_TYPE_INT
 jne .fail1
 cmp qword [rel request+NEBOC_NOM_SIZE_OFFSET],8
 jne .fail1

 ; V02 newtype is nominally distinct while preserving Int representation.
 call reset_request
 mov qword [rel request+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_NEWTYPE
 mov qword [rel request+NEBOC_NOM_TYPE_KEY_OFFSET],0x9999
 mov qword [rel request+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],41
 call analyze
 test eax,eax
 jnz .fail2
 cmp qword [rel request+NEBOC_NOM_TYPE_KEY_OFFSET],NEBOC_NOM_TYPE_INT
 je .fail2
 cmp qword [rel request+NEBOC_NOM_SIZE_OFFSET],8
 jne .fail2

 ; V03 unit enum: u32 declaration-order tag, size/align four.
 call reset_request
 call enum_two
 mov qword [rel request+NEBOC_NOM_ACTIVE_TAG_OFFSET],1
 mov qword [rel request+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_PARSED | NEBOC_NOM_FLAG_ABI_A0 | NEBOC_NOM_FLAG_OP_DISCRIMINANT
 call analyze
 test eax,eax
 jnz .fail3
 cmp qword [rel request+NEBOC_NOM_SIZE_OFFSET],4
 jne .fail3
 cmp qword [rel request+NEBOC_NOM_ALIGN_OFFSET],4
 jne .fail3
 cmp qword [rel request+NEBOC_NOM_RESULT_OFFSET],1
 jne .fail3

 ; V04 Int payload starts at eight and yields a 16-byte register value.
 call reset_request
 call enum_two
 mov qword [rel variants+NEBOC_NOM_VARIANT_SIZE+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_ACTIVE_TAG_OFFSET],1
 mov qword [rel request+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_INT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],43
 call analyze
 test eax,eax
 jnz .fail4
 cmp qword [rel request+NEBOC_NOM_PAYLOAD_OFFSET_OFFSET],8
 jne .fail4
 cmp qword [rel request+NEBOC_NOM_SIZE_OFFSET],16
 jne .fail4
 cmp qword [rel request+NEBOC_NOM_PASS_CLASS_OFFSET],NEBOC_NOM_PASS_REGISTERS
 jne .fail4

 ; V05 Text active payload alone owns one drop; inactive unit owns none.
 call reset_request
 call enum_two
 mov qword [rel variants+NEBOC_NOM_VARIANT_SIZE+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_TEXT
 mov qword [rel request+NEBOC_NOM_ACTIVE_TAG_OFFSET],1
 mov qword [rel request+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],NEBOC_NOM_TYPE_TEXT
 mov qword [rel request+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_TEXT
 call analyze
 test eax,eax
 jnz .fail5
 cmp qword [rel request+NEBOC_NOM_DROP_COUNT_OFFSET],1
 jne .fail5
 cmp qword [rel request+NEBOC_NOM_SIZE_OFFSET],24
 jne .fail5
 cmp qword [rel request+NEBOC_NOM_PASS_CLASS_OFFSET],NEBOC_NOM_PASS_MEMORY
 jne .fail5

 ; V06 lowering is pointerless, A0-versioned and hash-authenticated.
 call lower
 test eax,eax
 jnz .fail6
 mov rax,NEBOC_NOM_PLAN_MAGIC
 cmp [rel plan+NEBOC_NOM_PLAN_MAGIC_OFFSET],rax
 jne .fail6
 cmp qword [rel plan+NEBOC_NOM_PLAN_VERSION_OFFSET],NEBOC_NOM_PLAN_VERSION_A0
 jne .fail6
 cmp qword [rel plan+NEBOC_NOM_PLAN_HASH_OFFSET],0
 je .fail6

 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail2: mov edi,2
 jmp neboc_host_process_exit
.fail3: mov edi,3
 jmp neboc_host_process_exit
.fail4: mov edi,4
 jmp neboc_host_process_exit
.fail5: mov edi,5
 jmp neboc_host_process_exit
.fail6: mov edi,6
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
