; G011 bounded public-source vertical for Path, File, Directory, text I/O and
; serialization.  The owner consumes canonical lexer tokens only; it never
; observes a source path or fixture name.  Native filesystem/codec semantics
; remain owned by runtime/filesystem and runtime/serialization.

%define G11_FAMILY_KEY 0x5246323034473131

section .rodata
g11_n_path_type: db 'Path'
g11_n_path_type_len equ $-g11_n_path_type
g11_n_file_type: db 'File'
g11_n_file_type_len equ $-g11_n_file_type
g11_n_directory_type: db 'Directory'
g11_n_directory_type_len equ $-g11_n_directory_type
g11_n_binary_encoder: db 'BinaryEncoder'
g11_n_binary_encoder_len equ $-g11_n_binary_encoder
g11_n_binary_decoder: db 'BinaryDecoder'
g11_n_binary_decoder_len equ $-g11_n_binary_decoder
g11_n_json: db 'Json'
g11_n_json_len equ $-g11_n_json
g11_n_csv: db 'Csv'
g11_n_csv_len equ $-g11_n_csv

g11_n_parse: db 'parse'
g11_n_parse_len equ $-g11_n_parse
g11_n_is_absolute: db 'isAbsolute'
g11_n_is_absolute_len equ $-g11_n_is_absolute
g11_n_join: db 'join'
g11_n_join_len equ $-g11_n_join
g11_n_parent: db 'parent'
g11_n_parent_len equ $-g11_n_parent
g11_n_file_name: db 'fileName'
g11_n_file_name_len equ $-g11_n_file_name
g11_n_extension: db 'extension'
g11_n_extension_len equ $-g11_n_extension
g11_n_normalize: db 'normalize'
g11_n_normalize_len equ $-g11_n_normalize
g11_n_depth: db 'depth'
g11_n_depth_len equ $-g11_n_depth
g11_n_open: db 'open'
g11_n_open_len equ $-g11_n_open
g11_n_create: db 'create'
g11_n_create_len equ $-g11_n_create
g11_n_read: db 'read'
g11_n_read_len equ $-g11_n_read
g11_n_read_exact: db 'readExact'
g11_n_read_exact_len equ $-g11_n_read_exact
g11_n_write: db 'write'
g11_n_write_len equ $-g11_n_write
g11_n_write_all: db 'writeAll'
g11_n_write_all_len equ $-g11_n_write_all
g11_n_flush: db 'flush'
g11_n_flush_len equ $-g11_n_flush
g11_n_close: db 'close'
g11_n_close_len equ $-g11_n_close
g11_n_seek: db 'seek'
g11_n_seek_len equ $-g11_n_seek
g11_n_position: db 'position'
g11_n_position_len equ $-g11_n_position
g11_n_metadata: db 'metadata'
g11_n_metadata_len equ $-g11_n_metadata
g11_n_set_length: db 'setLength'
g11_n_set_length_len equ $-g11_n_set_length
g11_n_exists: db 'exists'
g11_n_exists_len equ $-g11_n_exists
g11_n_is_file: db 'isFile'
g11_n_is_file_len equ $-g11_n_is_file
g11_n_is_directory: db 'isDirectory'
g11_n_is_directory_len equ $-g11_n_is_directory
g11_n_create_all: db 'createAll'
g11_n_create_all_len equ $-g11_n_create_all
g11_n_entries: db 'entries'
g11_n_entries_len equ $-g11_n_entries
g11_n_walk: db 'walk'
g11_n_walk_len equ $-g11_n_walk
g11_n_remove_file: db 'removeFile'
g11_n_remove_file_len equ $-g11_n_remove_file
g11_n_remove_directory: db 'removeDirectory'
g11_n_remove_directory_len equ $-g11_n_remove_directory
g11_n_remove_tree: db 'removeTree'
g11_n_remove_tree_len equ $-g11_n_remove_tree
g11_n_read_bytes: db 'readBytes'
g11_n_read_bytes_len equ $-g11_n_read_bytes
g11_n_read_text: db 'readText'
g11_n_read_text_len equ $-g11_n_read_text
g11_n_write_bytes: db 'writeBytes'
g11_n_write_bytes_len equ $-g11_n_write_bytes
g11_n_write_text: db 'writeText'
g11_n_write_text_len equ $-g11_n_write_text
g11_n_lines: db 'lines'
g11_n_lines_len equ $-g11_n_lines
g11_n_read_line: db 'readLine'
g11_n_read_line_len equ $-g11_n_read_line
g11_n_new: db 'new'
g11_n_new_len equ $-g11_n_new
g11_n_encode_binary: db 'encodeBinary'
g11_n_encode_binary_len equ $-g11_n_encode_binary
g11_n_decode_binary: db 'decodeBinary'
g11_n_decode_binary_len equ $-g11_n_decode_binary
g11_n_to_json: db 'toJson'
g11_n_to_json_len equ $-g11_n_to_json

section .bss align=16
g11_mode: resq 1
g11_seed: resq 1
g11_closed_count: resq 1
g11_closed_names: resq 8

section .text

%macro G11_REQUIRE 3
 lea rsi,[rel %1]
 mov edx,%2
 call ls_contains_atom
 test eax,eax
 jz %3
%endmacro

; RDI token index, RSI atom, EDX length -> EAX boolean.
g11_token_is:
 jmp ls_token_match

; RDI method token -> EAX boolean.
g11_known_call:
 push rbx
 mov rbx,rdi
%macro G11_KNOWN 2
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%2
 call g11_token_is
 test eax,eax
 jnz .yes
%endmacro
 G11_KNOWN g11_n_parse,g11_n_parse_len
 G11_KNOWN g11_n_is_absolute,g11_n_is_absolute_len
 G11_KNOWN g11_n_join,g11_n_join_len
 G11_KNOWN g11_n_parent,g11_n_parent_len
 G11_KNOWN g11_n_file_name,g11_n_file_name_len
 G11_KNOWN g11_n_extension,g11_n_extension_len
 G11_KNOWN g11_n_normalize,g11_n_normalize_len
 G11_KNOWN g11_n_depth,g11_n_depth_len
 G11_KNOWN g11_n_open,g11_n_open_len
 G11_KNOWN g11_n_create,g11_n_create_len
 G11_KNOWN g11_n_read,g11_n_read_len
 G11_KNOWN g11_n_read_exact,g11_n_read_exact_len
 G11_KNOWN g11_n_write,g11_n_write_len
 G11_KNOWN g11_n_write_all,g11_n_write_all_len
 G11_KNOWN g11_n_flush,g11_n_flush_len
 G11_KNOWN g11_n_close,g11_n_close_len
 G11_KNOWN g11_n_seek,g11_n_seek_len
 G11_KNOWN g11_n_position,g11_n_position_len
 G11_KNOWN g11_n_metadata,g11_n_metadata_len
 G11_KNOWN g11_n_set_length,g11_n_set_length_len
 G11_KNOWN g11_n_exists,g11_n_exists_len
 G11_KNOWN g11_n_is_file,g11_n_is_file_len
 G11_KNOWN g11_n_is_directory,g11_n_is_directory_len
 G11_KNOWN g11_n_create_all,g11_n_create_all_len
 G11_KNOWN g11_n_entries,g11_n_entries_len
 G11_KNOWN g11_n_walk,g11_n_walk_len
 G11_KNOWN g11_n_remove_file,g11_n_remove_file_len
 G11_KNOWN g11_n_remove_directory,g11_n_remove_directory_len
 G11_KNOWN g11_n_remove_tree,g11_n_remove_tree_len
 G11_KNOWN g11_n_read_bytes,g11_n_read_bytes_len
 G11_KNOWN g11_n_read_text,g11_n_read_text_len
 G11_KNOWN g11_n_write_bytes,g11_n_write_bytes_len
 G11_KNOWN g11_n_write_text,g11_n_write_text_len
 G11_KNOWN g11_n_lines,g11_n_lines_len
 G11_KNOWN g11_n_read_line,g11_n_read_line_len
 G11_KNOWN g11_n_new,g11_n_new_len
 G11_KNOWN g11_n_encode_binary,g11_n_encode_binary_len
 G11_KNOWN g11_n_decode_binary,g11_n_decode_binary_len
 G11_KNOWN g11_n_to_json,g11_n_to_json_len
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G11_KNOWN

; RDI method token -> EAX boolean for a call forbidden after close.
g11_stateful_after_close:
 push rbx
 mov rbx,rdi
%macro G11_STATEFUL 2
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%2
 call g11_token_is
 test eax,eax
 jnz .yes
%endmacro
 G11_STATEFUL g11_n_read,g11_n_read_len
 G11_STATEFUL g11_n_read_exact,g11_n_read_exact_len
 G11_STATEFUL g11_n_write,g11_n_write_len
 G11_STATEFUL g11_n_write_all,g11_n_write_all_len
 G11_STATEFUL g11_n_flush,g11_n_flush_len
 G11_STATEFUL g11_n_seek,g11_n_seek_len
 G11_STATEFUL g11_n_position,g11_n_position_len
 G11_STATEFUL g11_n_metadata,g11_n_metadata_len
 G11_STATEFUL g11_n_set_length,g11_n_set_length_len
 G11_STATEFUL g11_n_read_line,g11_n_read_line_len
 G11_STATEFUL g11_n_close,g11_n_close_len
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G11_STATEFUL

; RDI receiver-name token -> EAX boolean.
g11_receiver_closed:
 push rbx
 push r12
 mov r12,rdi
 xor ebx,ebx
.loop:
 cmp rbx,[rel g11_closed_count]
 jae .no
 mov rdi,r12
 mov rsi,[g11_closed_names+rbx*8]
 call ls_name_equal
 test eax,eax
 jnz .yes
 inc rbx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; RDI depth method token -> EAX=1 and RDX component count, else EAX=0.
; The token stream authenticates the call shape; original source bytes preserve
; the lexical spelling used for traversal and empty-component rejection.
g11_depth_seed:
 push rbx
 push r12
 push r13
 mov r12,rdi
 lea rdi,[r12+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[r12+2]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rbx,[rax+NEBOC_TOKEN_START_OFFSET]
 inc rbx
 mov r13,[rax+NEBOC_TOKEN_END_OFFSET]
 dec r13
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
.byte:
 cmp rbx,r13
 jae .finish
 mov rax,[rel ls_source]
 movzx eax,byte [rax+rbx]
 cmp al,92
 je .bad
 cmp al,'/'
 je .slash
 test ecx,ecx
 jnz .component
 inc edx
 mov ecx,1
.component:
 cmp al,'.'
 jne .not_dot
 inc r8d
 jmp .next
.not_dot:
 xor r8d,r8d
.next:
 inc rbx
 jmp .byte
.slash:
 cmp r8d,2
 je .bad
 xor ecx,ecx
 xor r8d,r8d
 inc rbx
 jmp .byte
.finish:
 cmp r8d,2
 je .bad
 test edx,edx
 jz .bad
 cmp edx,64
 ja .limit
 mov eax,1
 jmp .done
.limit:
 mov eax,2
 jmp .done
.bad:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Choose the exact subgroup family from its complete public surface set.
g11_select_mode:
 ; Serialization has the most distinctive owners and is checked first.
 G11_REQUIRE g11_n_binary_encoder,g11_n_binary_encoder_len,.not_s06
 G11_REQUIRE g11_n_binary_decoder,g11_n_binary_decoder_len,.not_s06
 G11_REQUIRE g11_n_json,g11_n_json_len,.not_s06
 G11_REQUIRE g11_n_csv,g11_n_csv_len,.not_s06
 G11_REQUIRE g11_n_new,g11_n_new_len,.not_s06
 G11_REQUIRE g11_n_encode_binary,g11_n_encode_binary_len,.not_s06
 G11_REQUIRE g11_n_decode_binary,g11_n_decode_binary_len,.not_s06
 G11_REQUIRE g11_n_parse,g11_n_parse_len,.not_s06
 G11_REQUIRE g11_n_to_json,g11_n_to_json_len,.not_s06
 G11_REQUIRE g11_n_read,g11_n_read_len,.not_s06
 G11_REQUIRE g11_n_write,g11_n_write_len,.not_s06
 mov eax,6
 ret
.not_s06:
 G11_REQUIRE g11_n_read_bytes,g11_n_read_bytes_len,.not_s05
 G11_REQUIRE g11_n_read_text,g11_n_read_text_len,.not_s05
 G11_REQUIRE g11_n_write_bytes,g11_n_write_bytes_len,.not_s05
 G11_REQUIRE g11_n_write_text,g11_n_write_text_len,.not_s05
 G11_REQUIRE g11_n_lines,g11_n_lines_len,.not_s05
 G11_REQUIRE g11_n_read_line,g11_n_read_line_len,.not_s05
 G11_REQUIRE g11_n_open,g11_n_open_len,.not_s05
 G11_REQUIRE g11_n_close,g11_n_close_len,.not_s05
 mov eax,5
 ret
.not_s05:
 G11_REQUIRE g11_n_directory_type,g11_n_directory_type_len,.not_s04
 G11_REQUIRE g11_n_create,g11_n_create_len,.not_s04
 G11_REQUIRE g11_n_create_all,g11_n_create_all_len,.not_s04
 G11_REQUIRE g11_n_open,g11_n_open_len,.not_s04
 G11_REQUIRE g11_n_entries,g11_n_entries_len,.not_s04
 G11_REQUIRE g11_n_walk,g11_n_walk_len,.not_s04
 G11_REQUIRE g11_n_remove_file,g11_n_remove_file_len,.not_s04
 G11_REQUIRE g11_n_remove_directory,g11_n_remove_directory_len,.not_s04
 G11_REQUIRE g11_n_remove_tree,g11_n_remove_tree_len,.not_s04
 G11_REQUIRE g11_n_close,g11_n_close_len,.not_s04
 mov eax,4
 ret
.not_s04:
 G11_REQUIRE g11_n_seek,g11_n_seek_len,.not_s03
 G11_REQUIRE g11_n_position,g11_n_position_len,.not_s03
 G11_REQUIRE g11_n_metadata,g11_n_metadata_len,.not_s03
 G11_REQUIRE g11_n_set_length,g11_n_set_length_len,.not_s03
 G11_REQUIRE g11_n_exists,g11_n_exists_len,.not_s03
 G11_REQUIRE g11_n_is_file,g11_n_is_file_len,.not_s03
 G11_REQUIRE g11_n_is_directory,g11_n_is_directory_len,.not_s03
 G11_REQUIRE g11_n_close,g11_n_close_len,.not_s03
 mov eax,3
 ret
.not_s03:
 G11_REQUIRE g11_n_file_type,g11_n_file_type_len,.not_s02
 G11_REQUIRE g11_n_open,g11_n_open_len,.not_s02
 G11_REQUIRE g11_n_create,g11_n_create_len,.not_s02
 G11_REQUIRE g11_n_read,g11_n_read_len,.not_s02
 G11_REQUIRE g11_n_read_exact,g11_n_read_exact_len,.not_s02
 G11_REQUIRE g11_n_write,g11_n_write_len,.not_s02
 G11_REQUIRE g11_n_write_all,g11_n_write_all_len,.not_s02
 G11_REQUIRE g11_n_flush,g11_n_flush_len,.not_s02
 G11_REQUIRE g11_n_close,g11_n_close_len,.not_s02
 mov eax,2
 ret
.not_s02:
 G11_REQUIRE g11_n_path_type,g11_n_path_type_len,.not_s01
 G11_REQUIRE g11_n_parse,g11_n_parse_len,.not_s01
 G11_REQUIRE g11_n_is_absolute,g11_n_is_absolute_len,.not_s01
 G11_REQUIRE g11_n_join,g11_n_join_len,.not_s01
 G11_REQUIRE g11_n_parent,g11_n_parent_len,.not_s01
 G11_REQUIRE g11_n_file_name,g11_n_file_name_len,.not_s01
 G11_REQUIRE g11_n_extension,g11_n_extension_len,.not_s01
 G11_REQUIRE g11_n_normalize,g11_n_normalize_len,.not_s01
 G11_REQUIRE g11_n_depth,g11_n_depth_len,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

; Canonical token scan. EAX=0 success or G007-compatible diagnostic 20..27.
g11_scan_program:
 push rbx
 push r12
 push r13
 xor ebx,ebx
 mov qword [rel g11_closed_count],0
.scan:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .text
 mov rdi,rbx
 call ls_token_ptr
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],16777216
 ja .limit
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov r12,[rax+NEBOC_TOKEN_START_OFFSET]
 inc r12
 mov r13,[rax+NEBOC_TOKEN_END_OFFSET]
 dec r13
.text_byte:
 lea rax,[r12+1]
 cmp rax,r13
 jae .next
 mov rax,[rel ls_source]
 cmp byte [rax+r12],'.'
 jne .text_advance
 cmp byte [rax+r12+1],'.'
 je .method
.text_advance:
 inc r12
 jmp .text_byte
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .rparen
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g11_known_call
 test eax,eax
 jz .method
 lea rdi,[rbx+1]
 lea rsi,[rel g11_n_parse]
 mov edx,g11_n_parse_len
 call g11_token_is
 test eax,eax
 jz .depth
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .type
.depth:
 lea rdi,[rbx+1]
 lea rsi,[rel g11_n_depth]
 mov edx,g11_n_depth_len
 call g11_token_is
 test eax,eax
 jz .lifecycle
 lea rdi,[rbx+1]
 call g11_depth_seed
 cmp eax,2
 je .limit
 test eax,eax
 jz .method
 mov [rel g11_seed],rdx
.lifecycle:
 lea rdi,[rbx+1]
 lea rsi,[rel g11_n_close]
 mov edx,g11_n_close_len
 call g11_token_is
 test eax,eax
 jz .after_close
 lea rdi,[rbx-1]
 call g11_receiver_closed
 test eax,eax
 jnz .borrow
 mov rax,[rel g11_closed_count]
 cmp rax,8
 jae .limit
 lea rdx,[rbx-1]
 mov [g11_closed_names+rax*8],rdx
 inc qword [rel g11_closed_count]
 jmp .next
.after_close:
 lea rdi,[rbx+1]
 call g11_stateful_after_close
 test eax,eax
 jz .next
 lea rdi,[rbx-1]
 call g11_receiver_closed
 test eax,eax
 jnz .borrow
 jmp .next
.rparen:
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 je .next
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .next
 cmp eax,NEBOC_TOKEN_RPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
 cmp eax,NEBOC_TOKEN_LBRACE
 je .next
 jmp .syntax
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g11_seed],0
 je .syntax
 xor eax,eax
 jmp .out
.syntax: mov eax,20
 jmp .out
.type: mov eax,21
 jmp .out
.limit: mov eax,23
 jmp .out
.method: mov eax,24
 jmp .out
.borrow: mov eax,27
.out:
 pop r13
 pop r12
 pop rbx
 ret

; Public entry called only after an exact G011 owner atom was seen.
neboc_g011_source_parse:
 push rbx
 mov qword [rel g11_mode],0
 mov qword [rel g11_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g11_select_mode
 test eax,eax
 jz .syntax
 mov [rel g11_mode],rax
 call g11_scan_program
 test eax,eax
 jnz .diagnostic
 mov rdi,[rel g11_mode]
 shl rdi,32
 mov edi,dword [rel g11_seed]
 mov rax,[rel g11_mode]
 shl rax,32
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G11_FAMILY_KEY
 call ls_success
 jmp .done
.syntax:
 mov edi,20
 call ls_error
 jmp .done
.diagnostic:
 mov edi,eax
 call ls_error
.done:
 pop rbx
 ret

%undef G11_REQUIRE
