; RF166-G159 native contract, policy, bounds, and failure-atomicity checks.
bits 64
default rel
%include "compiler/docs/docs.inc"
global _start
extern neboc_docs_graph
extern neboc_docs_render
extern neboc_docs_search
extern neboc_docs_links
extern neboc_docs_views
extern neboc_docs_cli
extern neboc_docs_archive

%define SENTINEL 0xa5a5a5a5a5a5a5a5

%macro TEST_OK 3
 lea rdi,[rel %2]
 lea rsi,[rel result]
 call %1
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCS_RESULT_OPERATION_OFFSET],%3
 jne fail
 cmp qword [rel result+NEBOC_DOCS_RESULT_CLASS_OFFSET],%3
 jne fail
%endmacro

%macro TEST_FAIL 4
 mov rax,SENTINEL
 mov [rel result],rax
 lea rdi,[rel %2]
 lea rsi,[rel result]
 call %1
 cmp eax,%3
 jne fail
 mov rax,SENTINEL
 cmp [rel result],rax
 jne fail
%endmacro

section .text
_start:
 TEST_OK neboc_docs_graph,graph_ok,NEBOC_DOCS_OP_GRAPH
 TEST_OK neboc_docs_render,render_ok,NEBOC_DOCS_OP_RENDER
 TEST_OK neboc_docs_search,search_ok,NEBOC_DOCS_OP_SEARCH
 TEST_OK neboc_docs_links,links_ok,NEBOC_DOCS_OP_LINKS
 TEST_OK neboc_docs_views,views_ok,NEBOC_DOCS_OP_VIEWS
 TEST_OK neboc_docs_cli,cli_ok,NEBOC_DOCS_OP_CLI
 TEST_OK neboc_docs_archive,archive_ok,NEBOC_DOCS_OP_ARCHIVE

 TEST_FAIL neboc_docs_graph,graph_bad,NEBOC_DOCS_STATUS_CONTRACT,0
 TEST_FAIL neboc_docs_render,render_bad,NEBOC_DOCS_STATUS_MISMATCH,0
 TEST_FAIL neboc_docs_search,search_bad,NEBOC_DOCS_STATUS_LIMIT,0
 TEST_FAIL neboc_docs_links,links_bad,NEBOC_DOCS_STATUS_MISMATCH,0
 TEST_FAIL neboc_docs_views,views_bad,NEBOC_DOCS_STATUS_POLICY,0
 TEST_FAIL neboc_docs_cli,cli_bad,NEBOC_DOCS_STATUS_POLICY,0
 TEST_FAIL neboc_docs_archive,archive_bad,NEBOC_DOCS_STATUS_MISMATCH,0
 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall

section .rodata
align 8
graph_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_GRAPH,0x101,8,8,1,8
 dq 0,0,0,0,0,0,NEBOC_DOCS_FLAG_PUBLIC_ONLY|NEBOC_DOCS_FLAG_PATHS_REDACTED,0
 dq 0,0,0,0,1,0x34365f363878,8,0
 dq 8,0,0,0,0,0,0,0
graph_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_GRAPH,0x101,8,8,1,8
 dq 1,0,0,0,0,0,NEBOC_DOCS_FLAG_PUBLIC_ONLY,0
 times 16 dq 0
render_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_RENDER,0x101,8,8,1,8
 dq 0,0x201,0x202,0x203,19,19,NEBOC_DOCS_FLAG_OFFLINE_HTML,0
 times 16 dq 0
render_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_RENDER,0x101,8,8,1,8
 dq 0,0x201,0x202,0x203,19,18,NEBOC_DOCS_FLAG_OFFLINE_HTML,0
 times 16 dq 0
search_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_SEARCH,0x101,8,8,1,8
 dq 0,0x301,0,0,0,0,0,16
 dq 0x302,2,0,0,1,0x34365f363878,8,0
 times 8 dq 0
search_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_SEARCH,0x101,8,8,1,8
 dq 0,0x301,0,0,0,0,0,16
 dq 0x302,17,0,0,1,0x34365f363878,8,0
 times 8 dq 0
links_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_LINKS,0x101,8,8,1,8
 dq 0,0,0,0,0,0,NEBOC_DOCS_FLAG_PATHS_REDACTED,0
 dq 0,0,3,3,1,0x34365f363878,8,0
 times 8 dq 0
links_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_LINKS,0x101,8,8,1,8
 dq 0,0,0,0,0,0,NEBOC_DOCS_FLAG_PATHS_REDACTED,0
 dq 0,0,3,2,1,0x34365f363878,8,0
 times 8 dq 0
views_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_VIEWS,0x101,8,8,1,8
 dq 0,0,0,0,0,0,0,0
 dq 0,0,0,0,1,0x34365f363878,8,0
 times 8 dq 0
views_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_VIEWS,0x101,8,8,1,8
 dq 0,0,0,0,0,0,0,0
 dq 0,0,0,0,2,0x34365f363878,8,0
 times 8 dq 0
cli_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_CLI,0x101,8,8,1,8
 dq 0,0x601,0,0,1,1,NEBOC_DOCS_FLAG_OFFLINE_HTML,0
 dq 0,0,0,0,1,0x34365f363878,8,0
 dq 8,NEBOC_DOCS_COMMAND_BUILD,0,0,0,0,0,0
cli_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_CLI,0x101,8,8,1,8
 dq 0,0x601,0,0,5,5,0,0
 dq 0,0,0,0,1,0x34365f363878,8,0
 dq 8,NEBOC_DOCS_COMMAND_SERVE,0,0,0,0,0,0
archive_ok:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_ARCHIVE,0x101,8,8,1,8
 dq 0,0x701,0x701,0,0,0,NEBOC_DOCS_FLAG_ARCHIVE|NEBOC_DOCS_FLAG_INCREMENTAL,0
 dq 0,0,0,0,1,0x34365f363878,8,2
 dq 8,NEBOC_DOCS_COMMAND_RESTORE,0x702,0x702,0,0,0,0
archive_bad:
 dq NEBOC_DOCS_MAGIC,1,NEBOC_DOCS_OP_ARCHIVE,0x101,8,8,1,8
 dq 0,0x701,0x700,0,0,0,NEBOC_DOCS_FLAG_ARCHIVE,0
 dq 0,0,0,0,1,0x34365f363878,8,2
 dq 8,NEBOC_DOCS_COMMAND_RESTORE,0x702,0x703,0,0,0,0

section .bss
align 8
result: resb NEBOC_DOCS_RESULT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
