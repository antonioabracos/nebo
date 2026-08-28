; C03-F02-A1 B02 strict target-manifest parser.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/target_manifest.inc"
%include "compiler/semantic/modules/entrypoint_resolver.inc"

extern neboc_target_path_validate_bytes

section .rodata
tm_header: db 'nebo-target-manifest 1'
tm_header_len equ $-tm_header
tm_default: db 'default '
tm_default_len equ $-tm_default
tm_target: db 'target '
tm_target_len equ $-tm_target
tm_executable: db 'executable'
tm_executable_len equ $-tm_executable
tm_library: db 'library'
tm_library_len equ $-tm_library
tm_test: db 'test'
tm_test_len equ $-tm_test
tm_example: db 'example'
tm_example_len equ $-tm_example

section .text

; neboc_target_manifest_parse(request*) -> status.
NEBOC_ABI_FUNCTION neboc_target_manifest_parse
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,104
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_argument
 test rbx,7
 jnz .invalid_argument
 mov qword [rbx+NEBOC_TARGET_MANIFEST_COUNT],0
 mov qword [rbx+NEBOC_TARGET_MANIFEST_DEFAULT_PTR],0
 mov qword [rbx+NEBOC_TARGET_MANIFEST_DEFAULT_LEN],0
 mov qword [rbx+NEBOC_TARGET_MANIFEST_SELECTED_INDEX],-1
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR],NEBOC_TARGET_MANIFEST_ERROR_NONE
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR_START],0
 mov qword [rbx+NEBOC_TARGET_MANIFEST_ERROR_END],0
 mov r13,[rbx+NEBOC_TARGET_MANIFEST_BYTES]
 mov r14,[rbx+NEBOC_TARGET_MANIFEST_LENGTH]
 mov r15,[rbx+NEBOC_TARGET_MANIFEST_RECORDS]
 test r13,r13
 jz .invalid_argument
 test r15,r15
 jz .invalid_argument
 test r15,7
 jnz .invalid_argument
 cmp qword [rbx+NEBOC_TARGET_MANIFEST_CAPACITY],NEBOC_TARGET_MANIFEST_MAX_TARGETS
 jb .invalid_argument
 test r14,r14
 jz .malformed_zero
 cmp r14,NEBOC_TARGET_MANIFEST_MAX_BYTES
 ja .limit_all
 cmp r14,tm_header_len+2
 jb .schema_all
 cmp byte [r13+r14-1],10
 jne .malformed_all

 ; Canonical byte surface: printable ASCII plus LF, no blank line and no
 ; trailing space. This rejects BOM, CR, NUL, comments and Unicode before any
 ; record is published.
 xor r12d,r12d
 mov ebp,1
.byte_scan:
 cmp r12,r14
 jae .header
 movzx eax,byte [r13+r12]
 cmp al,10
 je .byte_lf
 cmp al,0x20
 jb .malformed_at_cursor
 cmp al,0x7e
 ja .malformed_at_cursor
 xor ebp,ebp
 inc r12
 jmp .byte_scan
.byte_lf:
 test ebp,ebp
 jnz .malformed_at_cursor
 test r12,r12
 jz .malformed_at_cursor
 cmp byte [r13+r12-1],' '
 je .malformed_at_cursor
 mov ebp,1
 inc r12
 jmp .byte_scan

.header:
 lea rdi,[r13]
 lea rsi,[rel tm_header]
 mov edx,tm_header_len
 call .bytes_equal_fixed
 test eax,eax
 jz .schema_all
 cmp byte [r13+tm_header_len],10
 jne .schema_all
 mov r12,tm_header_len+1

 ; Optional singleton default line.
 mov rdi,r13
 add rdi,r12
 lea rsi,[rel tm_default]
 mov edx,tm_default_len
 mov rcx,r14
 sub rcx,r12
 call .prefix_equal
 test eax,eax
 jz .targets
 lea rbp,[r12+tm_default_len]
 mov rax,rbp
.default_end:
 cmp rax,r14
 jae .malformed_at_cursor
 cmp byte [r13+rax],10
 je .default_ready
 cmp byte [r13+rax],' '
 je .malformed_at_cursor
 inc rax
 jmp .default_end
.default_ready:
 mov rsi,rax
 sub rsi,rbp
 lea rdi,[r13+rbp]
 call .validate_target_id
 test eax,eax
 jz .id_span_default
 lea rax,[r13+rbp]
 mov [rbx+NEBOC_TARGET_MANIFEST_DEFAULT_PTR],rax
 mov rax,rsi
 mov [rbx+NEBOC_TARGET_MANIFEST_DEFAULT_LEN],rax
 mov r12,rbp
 add r12,rsi
 inc r12

.targets:
 cmp r12,r14
 jae .malformed_at_cursor
 mov rax,[rbx+NEBOC_TARGET_MANIFEST_COUNT]
 cmp rax,NEBOC_TARGET_MANIFEST_MAX_TARGETS
 jae .limit_cursor
 mov rcx,[rbx+NEBOC_TARGET_MANIFEST_CAPACITY]
 cmp rax,rcx
 jae .limit_cursor
 mov [rsp],r12                         ; line start
 mov rdi,r13
 add rdi,r12
 lea rsi,[rel tm_target]
 mov edx,tm_target_len
 mov rcx,r14
 sub rcx,r12
 call .prefix_equal
 test eax,eax
 jz .field_cursor
 add r12,tm_target_len

 ; ID (space terminated).
 mov rbp,r12
.id_end:
 cmp r12,r14
 jae .malformed_at_cursor
 mov al,[r13+r12]
 cmp al,' '
 je .id_ready
 cmp al,10
 je .malformed_at_cursor
 inc r12
 jmp .id_end
.id_ready:
 lea rax,[r13+rbp]
 mov [rsp+8],rax
 mov rsi,r12
 sub rsi,rbp
 mov [rsp+16],rsi
 mov rdi,rax
 call .validate_target_id
 test eax,eax
 jz .id_span
 inc r12

 ; kind (space terminated).
 mov rbp,r12
.kind_end:
 cmp r12,r14
 jae .malformed_at_cursor
 mov al,[r13+r12]
 cmp al,' '
 je .kind_ready
 cmp al,10
 je .malformed_at_cursor
 inc r12
 jmp .kind_end
.kind_ready:
 lea rax,[r13+rbp]
 mov [rsp+24],rax
 mov rcx,r12
 sub rcx,rbp
 mov [rsp+32],rcx
 inc r12

 ; source path (space terminated).
 mov rbp,r12
.source_end:
 cmp r12,r14
 jae .malformed_at_cursor
 mov al,[r13+r12]
 cmp al,' '
 je .source_ready
 cmp al,10
 je .malformed_at_cursor
 inc r12
 jmp .source_end
.source_ready:
 lea rax,[r13+rbp]
 mov [rsp+40],rax
 mov rcx,r12
 sub rcx,rbp
 mov [rsp+48],rcx
 inc r12

 ; optional interface (space terminated).
 mov rbp,r12
.interface_end:
 cmp r12,r14
 jae .malformed_at_cursor
 mov al,[r13+r12]
 cmp al,' '
 je .interface_ready
 cmp al,10
 je .malformed_at_cursor
 inc r12
 jmp .interface_end
.interface_ready:
 lea rax,[r13+rbp]
 mov [rsp+56],rax
 mov rcx,r12
 sub rcx,rbp
 mov [rsp+64],rcx
 inc r12

 ; test reference (LF terminated, and therefore the final field).
 mov rbp,r12
.test_end:
 cmp r12,r14
 jae .malformed_at_cursor
 mov al,[r13+r12]
 cmp al,10
 je .test_ready
 cmp al,' '
 je .malformed_at_cursor
 inc r12
 jmp .test_end
.test_ready:
 lea rax,[r13+rbp]
 mov [rsp+72],rax
 mov rcx,r12
 sub rcx,rbp
 mov [rsp+80],rcx
 inc r12
 mov [rsp+88],r12

 ; Validate kind and its test-reference relation.
 mov rdi,[rsp+24]
 mov rsi,[rsp+32]
 lea rdx,[rel tm_executable]
 mov ecx,tm_executable_len
 call .bytes_equal
 test eax,eax
 jnz .kind_executable
 mov rdi,[rsp+24]
 mov rsi,[rsp+32]
 lea rdx,[rel tm_library]
 mov ecx,tm_library_len
 call .bytes_equal
 test eax,eax
 jnz .kind_library
 mov rdi,[rsp+24]
 mov rsi,[rsp+32]
 lea rdx,[rel tm_test]
 mov ecx,tm_test_len
 call .bytes_equal
 test eax,eax
 jnz .kind_test
 mov rdi,[rsp+24]
 mov rsi,[rsp+32]
 lea rdx,[rel tm_example]
 mov ecx,tm_example_len
 call .bytes_equal
 test eax,eax
 jnz .kind_example
 jmp .kind_span
.kind_executable:
 mov qword [rsp+96],NEBOC_TARGET_KIND_EXECUTABLE
 jmp .non_test_ref
.kind_library:
 mov qword [rsp+96],NEBOC_TARGET_KIND_LIBRARY
 jmp .non_test_ref
.kind_example:
 mov qword [rsp+96],NEBOC_TARGET_KIND_EXAMPLE
.non_test_ref:
 cmp qword [rsp+80],1
 jne .test_span
 mov rax,[rsp+72]
 cmp byte [rax],'-'
 jne .test_span
 mov qword [rsp+72],0
 mov qword [rsp+80],0
 jmp .validate_paths
.kind_test:
 mov qword [rsp+96],NEBOC_TARGET_KIND_TEST
 mov rdi,[rsp+72]
 mov rsi,[rsp+80]
 cmp rsi,1
 jne .test_validate
 cmp byte [rdi],'-'
 je .test_empty_span
.test_validate:
 call .validate_test_id
 test eax,eax
 jz .test_span

.validate_paths:
 mov rdi,[rsp+40]
 mov rsi,[rsp+48]
 mov edx,1
 call neboc_target_path_validate_bytes
 test eax,eax
 jz .source_path_ready
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .path_limit_span_source
 mov rdi,[rsp+40]
 mov rsi,[rsp+48]
 call .path_has_escape
 test eax,eax
 jnz .path_escape_span_source
 jmp .path_span_source
.source_path_ready:
 mov rsi,[rsp+64]
 cmp rsi,1
 jne .interface_path
 mov rax,[rsp+56]
 cmp byte [rax],'-'
 jne .interface_path
 mov qword [rsp+56],0
 mov qword [rsp+64],0
 jmp .order
.interface_path:
 mov rdi,[rsp+56]
 mov edx,2
 call neboc_target_path_validate_bytes
 test eax,eax
 jz .order
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .path_limit_span_interface
 mov rdi,[rsp+56]
 mov rsi,[rsp+64]
 call .path_has_escape
 test eax,eax
 jnz .path_escape_span_interface
 jmp .path_span_interface

.order:
 mov rax,[rbx+NEBOC_TARGET_MANIFEST_COUNT]
 test rax,rax
 jz .publish_record
 dec rax
 imul rax,NEBOC_TARGET_RECORD_SIZE
 add rax,r15
 mov rdi,[rsp+8]
 mov rsi,[rsp+16]
 mov rdx,[rax+NEBOC_TARGET_RECORD_ID_PTR]
 mov rcx,[rax+NEBOC_TARGET_RECORD_ID_LEN]
 call .id_strictly_greater
 test eax,eax
 jz .order_span

.publish_record:
 mov rax,[rbx+NEBOC_TARGET_MANIFEST_COUNT]
 imul rax,NEBOC_TARGET_RECORD_SIZE
 add rax,r15
 mov rdx,[rsp+8]
 mov [rax+NEBOC_TARGET_RECORD_ID_PTR],rdx
 mov rdx,[rsp+16]
 mov [rax+NEBOC_TARGET_RECORD_ID_LEN],rdx
 mov rdi,[rsp+8]
 mov rsi,[rsp+16]
 call .fnv1a64
 mov rbp,rax
 mov rax,[rbx+NEBOC_TARGET_MANIFEST_COUNT]
 imul rax,NEBOC_TARGET_RECORD_SIZE
 add rax,r15
 mov [rax+NEBOC_TARGET_RECORD_ID_HASH],rbp
 mov rdx,[rsp+96]
 mov [rax+NEBOC_TARGET_RECORD_KIND],rdx
 mov rdx,[rsp+40]
 mov [rax+NEBOC_TARGET_RECORD_SOURCE_PTR],rdx
 mov rdx,[rsp+48]
 mov [rax+NEBOC_TARGET_RECORD_SOURCE_LEN],rdx
 mov rdx,[rsp+56]
 mov [rax+NEBOC_TARGET_RECORD_INTERFACE_PTR],rdx
 mov rdx,[rsp+64]
 mov [rax+NEBOC_TARGET_RECORD_INTERFACE_LEN],rdx
 mov rdx,[rsp+72]
 mov [rax+NEBOC_TARGET_RECORD_TEST_PTR],rdx
 mov rdx,[rsp+80]
 mov [rax+NEBOC_TARGET_RECORD_TEST_LEN],rdx
 inc qword [rbx+NEBOC_TARGET_MANIFEST_COUNT]
 mov r12,[rsp+88]
 cmp r12,r14
 jb .targets

 cmp qword [rbx+NEBOC_TARGET_MANIFEST_COUNT],0
 je .malformed_all
 xor eax,eax
 jmp .done

; rdi current, rsi current length, rdx previous, rcx previous length.
.id_strictly_greater:
 push rbx
 xor r8d,r8d
 mov rax,rsi
 cmp rax,rcx
 cmova rax,rcx
.id_cmp_loop:
 cmp r8,rax
 jae .id_prefix
 mov bl,[rdi+r8]
 cmp bl,[rdx+r8]
 ja .id_yes
 jb .id_no
 inc r8
 jmp .id_cmp_loop
.id_prefix:
 cmp rsi,rcx
 ja .id_yes
.id_no:
 xor eax,eax
 pop rbx
 ret
.id_yes:
 mov eax,1
 pop rbx
 ret

; rdi bytes, rsi length.
.validate_target_id:
 test rsi,rsi
 jz .validator_no
 cmp rsi,NEBOC_TARGET_ID_MAX_BYTES
 ja .validator_no
 xor ecx,ecx
 mov r8d,1
.target_id_loop:
 cmp rcx,rsi
 jae .target_id_end
 movzx eax,byte [rdi+rcx]
 cmp al,'a'
 jb .target_id_not_lower
 cmp al,'z'
 jbe .target_id_lower
.target_id_not_lower:
 test r8d,r8d
 jnz .validator_no
 cmp al,'0'
 jb .target_id_hyphen
 cmp al,'9'
 jbe .target_id_next
.target_id_hyphen:
 cmp al,'-'
 jne .validator_no
 mov r8d,1
 inc rcx
 jmp .target_id_loop
.target_id_lower:
 xor r8d,r8d
.target_id_next:
 inc rcx
 jmp .target_id_loop
.target_id_end:
 test r8d,r8d
 jnz .validator_no
 mov eax,1
 ret

.validate_test_id:
 test rsi,rsi
 jz .validator_no
 cmp rsi,NEBOC_TARGET_TEST_ID_MAX_BYTES
 ja .validator_no
 movzx eax,byte [rdi]
 cmp al,'a'
 jb .validator_no
 cmp al,'z'
 ja .validator_no
 mov ecx,1
.test_id_loop:
 cmp rcx,rsi
 jae .validator_yes
 movzx eax,byte [rdi+rcx]
 cmp al,'a'
 jb .test_not_lower
 cmp al,'z'
 jbe .test_id_next
.test_not_lower:
 cmp al,'0'
 jb .test_underscore
 cmp al,'9'
 jbe .test_id_next
.test_underscore:
 cmp al,'_'
 jne .validator_no
.test_id_next:
 inc rcx
 jmp .test_id_loop
.validator_yes:
 mov eax,1
 ret

; rdi path bytes, rsi length -> 1 only for an absolute, dot or dotdot
; component. Other noncanonical spellings remain PATH_MALFORMED.
.path_has_escape:
 test rsi,rsi
 jz .path_no_escape
 cmp byte [rdi],'/'
 jne .path_escape_scan_init
.path_escape_yes:
 mov eax,1
 ret
.path_escape_scan_init:
 xor ecx,ecx
 xor r8d,r8d
.path_escape_scan:
 cmp rcx,rsi
 jae .path_escape_final
 cmp byte [rdi+rcx],'/'
 je .path_escape_component
 inc rcx
 jmp .path_escape_scan
.path_escape_component:
 mov rax,rcx
 sub rax,r8
 sub rsp,8
 call .path_component_is_escape
 add rsp,8
 test eax,eax
 jnz .path_escape_yes
 lea r8,[rcx+1]
 inc rcx
 jmp .path_escape_scan
.path_escape_final:
 mov rax,rsi
 sub rax,r8
.path_component_is_escape:
 cmp rax,1
 jne .path_component_dotdot
 cmp byte [rdi+r8],'.'
 je .path_escape_yes
 jmp .path_no_escape
.path_component_dotdot:
 cmp rax,2
 jne .path_no_escape
 cmp byte [rdi+r8],'.'
 jne .path_no_escape
 cmp byte [rdi+r8+1],'.'
 je .path_escape_yes
.path_no_escape:
 xor eax,eax
 ret
.validator_no:
 xor eax,eax
 ret

; rdi/len and rdx/literal len rcx.
.bytes_equal:
 cmp rsi,rcx
 jne .validator_no
 xor r8d,r8d
.bytes_equal_loop:
 cmp r8,rcx
 jae .validator_yes
 mov al,[rdi+r8]
 cmp al,[rdx+r8]
 jne .validator_no
 inc r8
 jmp .bytes_equal_loop

; rdi bytes, rsi fixed literal, edx fixed length.
.bytes_equal_fixed:
 xor ecx,ecx
.fixed_loop:
 cmp rcx,rdx
 jae .validator_yes
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jne .validator_no
 inc rcx
 jmp .fixed_loop

; rdi bytes, rsi prefix, edx prefix length, rcx available.
.prefix_equal:
 cmp rcx,rdx
 jb .validator_no
 jmp .bytes_equal_fixed

.fnv1a64:
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.fnv_loop:
 cmp rcx,rsi
 jae .fnv_done
 movzx edx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .fnv_loop
.fnv_done:
 ret

.malformed_zero:
 xor r8d,r8d
 mov r9d,1
 jmp .malformed_span
.malformed_all:
 xor r8d,r8d
 mov r9,r14
 jmp .malformed_span
.malformed_at_cursor:
 mov r8,r12
 lea r9,[r12+1]
.malformed_span:
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_MALFORMED
 jmp .source_error
.schema_all:
 xor r8d,r8d
 mov r9,tm_header_len
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_SCHEMA
 jmp .source_error
.field_cursor:
 mov r8,[rsp]
 mov r9,r12
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_FIELD
 jmp .source_error
.id_span_default:
 mov r8,rbp
 mov r9,rbp
 add r9,rsi
 test rsi,rsi
 jnz .id_default_malformed
 dec r8
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_ID_MISSING
 jmp .source_error
.id_default_malformed:
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_ID
 jmp .source_error
.id_span:
 mov r8,rbp
 mov r9,r12
 cmp r12,rbp
 jne .id_malformed
 dec r8
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_ID_MISSING
 jmp .source_error
.id_malformed:
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_ID
 jmp .source_error
.kind_span:
 mov r8,[rsp+24]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+32]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_KIND
 jmp .source_error
.path_span_source:
 mov r8,[rsp+40]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+48]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_PATH
 jmp .source_error
.path_span_interface:
 mov r8,[rsp+56]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+64]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_PATH
 jmp .source_error
.path_escape_span_source:
 mov r8,[rsp+40]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+48]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_PATH_ESCAPE
 jmp .source_error
.path_escape_span_interface:
 mov r8,[rsp+56]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+64]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_PATH_ESCAPE
 jmp .source_error
.path_limit_span_source:
 mov r8,[rsp+40]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+48]
 jmp .limit_error
.path_limit_span_interface:
 mov r8,[rsp+56]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+64]
 jmp .limit_error
.test_span:
 mov r8,[rsp+72]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+80]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_TEST
 jmp .source_error
.test_empty_span:
 mov r8,[rsp+72]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+80]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_TEST_EMPTY
 jmp .source_error
.order_span:
 mov r8,[rsp+8]
 sub r8,r13
 mov r9,r8
 add r9,[rsp+16]
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_DUPLICATE_OR_ORDER
 jmp .source_error
.limit_all:
 xor r8d,r8d
 mov r9,r14
 jmp .limit_error
.limit_cursor:
 mov r8,r12
 lea r9,[r12+1]
.limit_error:
 mov edx,NEBOC_TARGET_MANIFEST_ERROR_LIMIT
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR],rdx
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR_START],r8
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR_END],r9
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.source_error:
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR],rdx
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR_START],r8
 mov [rbx+NEBOC_TARGET_MANIFEST_ERROR_END],r9
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,104
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
