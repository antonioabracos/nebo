; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F10 bounded test/conformance/fuzz plan admission.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/driver/cli/test_tooling.inc"
section .text
NEBOC_ABI_FUNCTION nebo_test_tooling_init
 test rdi,rdi
 jz .bad
 mov rsi,[rdi+NEBO_TEST_INIT_STATE]
 mov rdx,[rdi+NEBO_TEST_INIT_RECORDS]
 mov rcx,[rdi+NEBO_TEST_INIT_CAPACITY]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
 cmp rcx,NEBO_TEST_MAX_CASES
 ja .limit
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_TEST_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_TEST_MAGIC
 mov [rsi+NEBO_TEST_STATE_MAGIC],rax
 mov [rsi+NEBO_TEST_STATE_RECORDS],rdx
 mov rax,[r8+NEBO_TEST_INIT_CAPACITY]
 mov [rsi+NEBO_TEST_STATE_CAPACITY],rax
 xor eax,eax
 ret
.limit: mov eax,NEBO_TEST_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_TEST_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_test_tooling_admit
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_TEST_REQUEST_RESULT],0
 mov qword [rdi+NEBO_TEST_REQUEST_SEQUENCE],0
 mov rsi,[rdi+NEBO_TEST_REQUEST_STATE]
 test rsi,rsi
 jz .bad
 mov rax,NEBO_TEST_MAGIC
 cmp [rsi+NEBO_TEST_STATE_MAGIC],rax
 jne .bad
 mov rdx,[rdi+NEBO_TEST_REQUEST_KIND]
 test rdx,rdx
 jz .kind
 cmp rdx,NEBO_TEST_KIND_SNAPSHOT
 ja .kind
 cmp qword [rdi+NEBO_TEST_REQUEST_PATH_HASH],0
 je .bad
 cmp qword [rdi+NEBO_TEST_REQUEST_EXPECTED],1
 ja .diagnostic
 cmp qword [rdi+NEBO_TEST_REQUEST_FLAGS],NEBO_TEST_REQUIRED_FLAGS
 jne .traversal
 cmp rdx,NEBO_TEST_KIND_FUZZ
 jne .not_fuzz
 mov rax,[rdi+NEBO_TEST_REQUEST_FUZZ_CASES]
 test rax,rax
 jz .fuzz
 cmp rax,NEBO_TEST_MAX_FUZZ
 ja .fuzz
 jmp .not_snapshot
.not_fuzz:
 cmp qword [rdi+NEBO_TEST_REQUEST_FUZZ_CASES],0
 jne .bad
 cmp rdx,NEBO_TEST_KIND_SNAPSHOT
 jne .not_snapshot
 mov rax,[rdi+NEBO_TEST_REQUEST_SNAPSHOT_EXPECTED]
 cmp rax,[rdi+NEBO_TEST_REQUEST_SNAPSHOT_ACTUAL]
 jne .snapshot
.not_snapshot:
 mov rax,[rsi+NEBO_TEST_STATE_COUNT]
 cmp rax,[rsi+NEBO_TEST_STATE_CAPACITY]
 jae .limit
 imul rax,NEBO_TEST_RECORD_SIZE
 add rax,[rsi+NEBO_TEST_STATE_RECORDS]
 mov [rax+NEBO_TEST_RECORD_KIND],rdx
 mov rcx,[rdi+NEBO_TEST_REQUEST_PATH_HASH]
 mov [rax+NEBO_TEST_RECORD_PATH_HASH],rcx
 mov rcx,[rdi+NEBO_TEST_REQUEST_EXPECTED]
 mov [rax+NEBO_TEST_RECORD_EXPECTED],rcx
 mov rcx,[rdi+NEBO_TEST_REQUEST_FUZZ_CASES]
 mov [rax+NEBO_TEST_RECORD_FUZZ_CASES],rcx
 mov rcx,[rdi+NEBO_TEST_REQUEST_FLAGS]
 mov [rax+NEBO_TEST_RECORD_FLAGS],rcx
 inc qword [rsi+NEBO_TEST_STATE_SEQUENCE]
 mov rcx,[rsi+NEBO_TEST_STATE_SEQUENCE]
 mov [rax+NEBO_TEST_RECORD_SEQUENCE],rcx
 mov [rdi+NEBO_TEST_REQUEST_SEQUENCE],rcx
 inc qword [rsi+NEBO_TEST_STATE_COUNT]
 mov qword [rdi+NEBO_TEST_REQUEST_RESULT],1
 xor eax,eax
 ret
.kind: mov eax,NEBO_TEST_STATUS_KIND
 ret
.traversal: mov eax,NEBO_TEST_STATUS_TRAVERSAL
 ret
.diagnostic: mov eax,NEBO_TEST_STATUS_DIAGNOSTIC
 ret
.fuzz: mov eax,NEBO_TEST_STATUS_FUZZ_LIMIT
 ret
.snapshot: mov eax,NEBO_TEST_STATUS_SNAPSHOT_DRIFT
 ret
.limit: mov eax,NEBO_TEST_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_TEST_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
