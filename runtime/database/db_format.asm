; MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-F01 bounded NEBODB01 v1 header and catalog identity contract.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/database/db_format.inc"

section .text
NEBOC_ABI_FUNCTION nebo_db_fnv1a64
 test rdi,rdi
 jz .invalid
 mov rax,0xcbf29ce484222325
 mov rdx,0x100000001b3
 xor rcx,rcx
.loop:
 cmp rcx,rsi
 jae .done
 movzx r8,byte [rdi+rcx]
 xor rax,r8
 imul rax,rdx
 inc rcx
 jmp .loop
.done:
 ret
.invalid:
 xor eax,eax
 ret

NEBOC_ABI_FUNCTION nebo_db_header_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_DB_MAX_PAGES
 ja .limit
 push rbx
 mov rbx,rdi
 mov rax,NEBO_DB_MAGIC
 mov [rbx+NEBO_DB_HEADER_MAGIC],rax
 mov dword [rbx+NEBO_DB_HEADER_VERSION],NEBO_DB_VERSION
 mov dword [rbx+NEBO_DB_HEADER_FEATURES],0
 mov qword [rbx+NEBO_DB_HEADER_PAGE_SIZE],NEBO_DB_PAGE_SIZE
 mov [rbx+NEBO_DB_HEADER_PAGE_COUNT],rsi
 mov [rbx+NEBO_DB_HEADER_SCHEMA_VERSION],rdx
 mov [rbx+NEBO_DB_HEADER_SCHEMA_HASH],rcx
 mov rdi,rbx
 mov esi,NEBO_DB_HEADER_CHECKSUM_INPUT_SIZE
 call nebo_db_fnv1a64
 mov [rbx+NEBO_DB_HEADER_CHECKSUM],rax
 pop rbx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_STATUS_INVALID
 ret
.limit:
 mov eax,NEBO_DB_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_db_header_validate
 test rdi,rdi
 jz .invalid
 mov rax,NEBO_DB_MAGIC
 cmp [rdi+NEBO_DB_HEADER_MAGIC],rax
 jne .invalid
 cmp dword [rdi+NEBO_DB_HEADER_VERSION],NEBO_DB_VERSION
 jne .version
 cmp dword [rdi+NEBO_DB_HEADER_FEATURES],0
 jne .feature
 cmp qword [rdi+NEBO_DB_HEADER_PAGE_SIZE],NEBO_DB_PAGE_SIZE
 jne .page_size
 mov rax,[rdi+NEBO_DB_HEADER_PAGE_COUNT]
 test rax,rax
 jz .limit
 cmp rax,NEBO_DB_MAX_PAGES
 ja .limit
 push rbx
 mov rbx,rdi
 mov rdi,rbx
 mov esi,NEBO_DB_HEADER_CHECKSUM_INPUT_SIZE
 call nebo_db_fnv1a64
 cmp rax,[rbx+NEBO_DB_HEADER_CHECKSUM]
 pop rbx
 jne .checksum
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_STATUS_INVALID
 ret
.version:
 mov eax,NEBO_DB_STATUS_VERSION
 ret
.feature:
 mov eax,NEBO_DB_STATUS_FEATURE
 ret
.page_size:
 mov eax,NEBO_DB_STATUS_PAGE_SIZE
 ret
.limit:
 mov eax,NEBO_DB_STATUS_LIMIT
 ret
.checksum:
 mov eax,NEBO_DB_STATUS_CHECKSUM
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
