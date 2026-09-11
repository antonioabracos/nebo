bits 64
default rel
%include "compiler/driver/cli/test_tooling.inc"
extern nebo_test_tooling_init,nebo_test_tooling_admit
section .bss
align 16
state resb NEBO_TEST_STATE_SIZE
records resb NEBO_TEST_RECORD_SIZE*4
init resb NEBO_TEST_INIT_SIZE
request resb NEBO_TEST_REQUEST_SIZE
section .text
prepare:
 lea rdi,[request]
 mov ecx,NEBO_TEST_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [request+NEBO_TEST_REQUEST_STATE],rax
 mov qword [request+NEBO_TEST_REQUEST_KIND],NEBO_TEST_KIND_TEST
 mov qword [request+NEBO_TEST_REQUEST_PATH_HASH],0x1234
 mov qword [request+NEBO_TEST_REQUEST_EXPECTED],1
 mov qword [request+NEBO_TEST_REQUEST_FLAGS],NEBO_TEST_REQUIRED_FLAGS
 ret
global _start
_start:
 lea rdi,[init]
 mov ecx,NEBO_TEST_INIT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[state]
 mov [init+NEBO_TEST_INIT_STATE],rax
 lea rax,[records]
 mov [init+NEBO_TEST_INIT_RECORDS],rax
 mov qword [init+NEBO_TEST_INIT_CAPACITY],4
 lea rdi,[init]
 call nebo_test_tooling_init
 test eax,eax
 jnz fail
 mov rax,NEBO_TEST_MAGIC
 cmp [state+NEBO_TEST_STATE_MAGIC],rax
 jne fail
 call prepare
 lea rdi,[request]
 call nebo_test_tooling_admit
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],1
 jne fail
 cmp qword [request+NEBO_TEST_REQUEST_SEQUENCE],1
 jne fail
 cmp qword [records+NEBO_TEST_RECORD_KIND],NEBO_TEST_KIND_TEST
 jne fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_FLAGS],NEBO_TEST_FLAG_LOCAL_PATH
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_TRAVERSAL
 jne fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],1
 jne fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_EXPECTED],2
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_DIAGNOSTIC
 jne fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_KIND],NEBO_TEST_KIND_FUZZ
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_FUZZ_LIMIT
 jne fail
 mov qword [request+NEBO_TEST_REQUEST_FUZZ_CASES],4097
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_FUZZ_LIMIT
 jne fail
 mov qword [request+NEBO_TEST_REQUEST_FUZZ_CASES],4096
 lea rdi,[request]
 call nebo_test_tooling_admit
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],2
 jne fail
 cmp qword [records+NEBO_TEST_RECORD_SIZE+NEBO_TEST_RECORD_FUZZ_CASES],4096
 jne fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_KIND],NEBO_TEST_KIND_SNAPSHOT
 mov qword [request+NEBO_TEST_REQUEST_SNAPSHOT_EXPECTED],0xaaa
 mov qword [request+NEBO_TEST_REQUEST_SNAPSHOT_ACTUAL],0xbbb
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_SNAPSHOT_DRIFT
 jne fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],2
 jne fail
 mov qword [request+NEBO_TEST_REQUEST_SNAPSHOT_ACTUAL],0xaaa
 lea rdi,[request]
 call nebo_test_tooling_admit
 test eax,eax
 jnz fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_KIND],NEBO_TEST_KIND_CONFORMANCE
 lea rdi,[request]
 call nebo_test_tooling_admit
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],4
 jne fail
 call prepare
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_LIMIT
 jne fail
 cmp qword [state+NEBO_TEST_STATE_COUNT],4
 jne fail
 call prepare
 mov qword [request+NEBO_TEST_REQUEST_KIND],0
 lea rdi,[request]
 call nebo_test_tooling_admit
 cmp eax,NEBO_TEST_STATUS_KIND
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
