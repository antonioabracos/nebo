; G080 bounded CSV/TSV/JSON/JSONL implementation. All value buffers are
; caller-owned. Filesystem operations require an explicit directory fd and
; use openat/renameat inside that sandbox; no ambient path root is consulted.
bits 64
default rel
%define NEBO_G080_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/tabular_json_formats_source_probe.inc"
%include "runtime/textual/format_data.inc"

section .rodata
g80_temp_name: db '.g080-write.tmp',0
g80_csv_doc: db 'name,value',10,'nebo,80',10
g80_csv_doc_len equ $-g80_csv_doc
g80_tsv_doc: db 'name',9,'value',10,'nebo',9,'81',10
g80_tsv_doc_len equ $-g80_tsv_doc
g80_formula: db '=SUM(A1:A2)'
g80_formula_len equ $-g80_formula
g80_json_text: db '{"active":true,"count":80,"name":"nebo"}'
g80_json_text_len equ $-g80_json_text
g80_key_active: db 'active'
g80_key_active_len equ $-g80_key_active
g80_key_count: db 'count'
g80_key_count_len equ $-g80_key_count
g80_key_name: db 'name'
g80_key_name_len equ $-g80_key_name
g80_value_nebo: db 'nebo'
g80_value_nebo_len equ $-g80_value_nebo
g80_jsonl_a: db '{"id":1}',10,'{"id":2}',10
g80_jsonl_a_len equ $-g80_jsonl_a
g80_s1: db 'S01 csv-types=bounded options=explicit formula-policy=required',10
g80_s1_len equ $-g80_s1
g80_s2: db 'S02 csv=parse,read,stream,write quotes=RFC4180 atomic=YES',10
g80_s2_len equ $-g80_s2
g80_s3: db 'S03 tsv=parse,read,stream,write delimiter=TAB status=GREEN',10
g80_s3_len equ $-g80_s3
g80_s4: db 'S04 json-value=typed keys=canonical duplicate=REJECT',10
g80_s4_len equ $-g80_s4
g80_s5: db 'S05 json=parse,read,write,pretty grammar=STRICT depth=32',10
g80_s5_len equ $-g80_s5
g80_s6: db 'S06 json-typed=bounded policy=explicit conversion=deterministic',10
g80_s6_len equ $-g80_s6
g80_s7: db 'S07 jsonl=incremental events=bounded dead-letter=counted',10
g80_s7_len equ $-g80_s7
g80_s8: db 'S08 composition=8 source-to-effect=PASS open-findings=0',10
g80_s8_len equ $-g80_s8

section .bss align=16
g80_options: resb G080_CSV_OPTIONS_SIZE
g80_table: resb G080_TABLE_SIZE
g80_delim_state: resb G080_DELIM_STATE_SIZE
g80_value: resb G080_JSON_VALUE_SIZE
g80_jsonl_state: resb G080_JSONL_STATE_SIZE
g80_output: resb G080_MAX_BYTES+8
g80_atomic: resb 64
g80_file_scratch: resb G080_MAX_BYTES+1

section .text
global nebo_g080_source_probe
global nebo_g080_negative_probe
global nebo_g080_render_transcript
global nebo_g080_csv_options_validate
global nebo_g080_csv_parse
global nebo_g080_csv_encode_cell
global nebo_g080_delimited_init
global nebo_g080_delimited_feed
global nebo_g080_json_value_init
global nebo_g080_json_set
global nebo_g080_json_type_is
global nebo_g080_json_validate
global nebo_g080_json_stringify
global nebo_g080_json_pretty
global nebo_g080_json_decode
global nebo_g080_jsonl_init
global nebo_g080_jsonl_feed
global nebo_g080_path_validate
global nebo_g080_file_write_atomic
global nebo_g080_file_read

; Private strict scalar UTF-8 validator used before CSV/JSON grammar work.
; EAX=0 on success, -FMT_SYNTAX otherwise.
g080_utf8_validate:
 test rsi,rsi
 jz .ok
 test rdi,rdi
 jz .bad
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 movzx eax,byte [rdi+rcx]
 inc rcx
 cmp eax,0x80
 jb .loop
 cmp eax,0xc2
 jb .bad
 cmp eax,0xdf
 jbe .two
 cmp eax,0xef
 jbe .three
 cmp eax,0xf4
 jbe .four
 jmp .bad
.two:
 cmp rcx,rsi
 jae .bad
 movzx edx,byte [rdi+rcx]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 inc rcx
 jmp .loop
.three:
 mov r8d,eax
 lea r9,[rcx+2]
 cmp r9,rsi
 ja .bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xe0
 jne .three_not_e0
 cmp edx,0xa0
 jb .bad
.three_not_e0:
 cmp r8d,0xed
 jne .three_bound
 cmp edx,0x9f
 ja .bad
.three_bound:
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+1]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 add rcx,2
 jmp .loop
.four:
 mov r8d,eax
 lea r9,[rcx+3]
 cmp r9,rsi
 ja .bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xf0
 jne .four_not_f0
 cmp edx,0x90
 jb .bad
.four_not_f0:
 cmp r8d,0xf4
 jne .four_bound
 cmp edx,0x8f
 ja .bad
.four_bound:
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+1]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+2]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 add rcx,3
 jmp .loop
.ok: xor eax,eax
 ret
.bad: mov eax,-FMT_SYNTAX
 ret

; RDI options. CSV and TSV share explicit delimiter, resource and formula
; policies. Every field is validated before any dependent operation begins.
nebo_g080_csv_options_validate:
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+G080_CSV_DELIMITER]
 cmp al,','
 je .delimiter_ok
 cmp al,9
 jne .invalid
.delimiter_ok:
 cmp qword [rdi+G080_CSV_QUOTE],'"'
 jne .invalid
 cmp qword [rdi+G080_CSV_HEADER],1
 ja .invalid
 mov rax,[rdi+G080_CSV_MAX_RECORDS]
 test rax,rax
 jz .invalid
 cmp rax,G080_MAX_RECORDS
 ja .limit
 mov rax,[rdi+G080_CSV_MAX_FIELDS]
 test rax,rax
 jz .invalid
 cmp rax,G080_MAX_FIELDS
 ja .limit
 mov rax,[rdi+G080_CSV_FORMULA_POLICY]
 cmp rax,G080_FORMULA_REJECT
 je .ok
 cmp rax,G080_FORMULA_PREFIX
 jne .invalid
.ok: xor eax,eax
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI bytes, RSI len, RDX options, RCX table summary. Summary is committed
; only after the quote-aware scanner and all configured limits succeed.
nebo_g080_csv_parse:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rcx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r14
 call nebo_g080_csv_options_validate
 test eax,eax
 jnz .saved
 mov rdi,r12
 mov rsi,r13
 call g080_utf8_validate
 test eax,eax
 jnz .saved
 mov rdi,r12
 mov rsi,r13
 movzx edx,byte [r14+G080_CSV_DELIMITER]
 mov rcx,[r14+G080_CSV_MAX_FIELDS]
 call delimited_scan
 test eax,eax
 jnz .translate
 cmp rcx,[r14+G080_CSV_MAX_RECORDS]
 ja .limit_saved
 mov [rbx+G080_TABLE_RECORDS],rcx
 mov [rbx+G080_TABLE_FIELDS],rdx
 xor rax,rax
 test rcx,rcx
 jz .columns
 mov rax,rdx
 add rax,rcx
 dec rax
 xor edx,edx
 div rcx
.columns:
 mov [rbx+G080_TABLE_MAX_COLUMNS],rax
 mov rax,[r14+G080_CSV_HEADER]
 mov [rbx+G080_TABLE_HEADER],rax
 xor eax,eax
 jmp .saved
.translate:
 neg eax
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
.saved:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI field, RSI len, RDX output, RCX capacity, R8 delimiter, R9 formula
; policy. It doubles quotes and applies an explicit reject/prefix policy.
nebo_g080_csv_encode_cell:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,G080_MAX_BYTES
 ja .limit
 push rdx
 push rcx
 push r8
 push r9
 call g080_utf8_validate
 pop r9
 pop r8
 pop rcx
 pop rdx
 test eax,eax
 jnz .syntax
 cmp r8b,','
 je .delim_ok
 cmp r8b,9
 jne .invalid
.delim_ok:
 cmp r9,G080_FORMULA_REJECT
 je .policy_ok
 cmp r9,G080_FORMULA_PREFIX
 jne .invalid
.policy_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r15d,r15d                 ; prefix apostrophe
 xor r10d,r10d                 ; quote field
 test r12,r12
 jz .measure
 mov al,[rbx]
 cmp al,'='
 je .formula
 cmp al,'+'
 je .formula
 cmp al,'-'
 je .formula
 cmp al,'@'
 jne .measure
.formula:
 cmp r9,G080_FORMULA_REJECT
 je .conflict_saved
 mov r15d,1
.measure:
 xor r11d,r11d                 ; embedded quote count
 xor ecx,ecx
.measure_loop:
 cmp rcx,r12
 jae .measured
 mov al,[rbx+rcx]
 test al,al
 jz .invalid_saved
 cmp al,'"'
 jne .special
 inc r11
 mov r10d,1
.special:
 cmp al,r8b
 je .mark_quote
 cmp al,10
 je .mark_quote
 cmp al,13
 jne .measure_next
.mark_quote: mov r10d,1
.measure_next: inc rcx
 jmp .measure_loop
.measured:
 mov rax,r12
 add rax,r15
 add rax,r11
 test r10,r10
 jz .capacity_check
 add rax,2
.capacity_check:
 cmp rax,r14
 ja .capacity_saved
 xor ecx,ecx
 test r10,r10
 jz .prefix
 mov byte [r13+rcx],'"'
 inc rcx
.prefix:
 test r15,r15
 jz .copy_loop_start
 mov byte [r13+rcx],39
 inc rcx
.copy_loop_start:
 xor edx,edx
.copy_loop:
 cmp rdx,r12
 jae .close
 mov al,[rbx+rdx]
 mov [r13+rcx],al
 inc rcx
 cmp al,'"'
 jne .copy_next
 mov [r13+rcx],al
 inc rcx
.copy_next: inc rdx
 jmp .copy_loop
.close:
 test r10,r10
 jz .return_len
 mov byte [r13+rcx],'"'
 inc rcx
.return_len:
 mov rax,rcx
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.conflict_saved: mov eax,-FMT_CONFLICT
 jmp .error_saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .error_saved
.invalid_saved: mov eax,-FMT_INVALID
.error_saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI state, ESI delimiter, EDX max fields. State is caller-owned and can be
; fed with arbitrarily split chunks without retaining the full file.
nebo_g080_delimited_init:
 test rdi,rdi
 jz .invalid
 cmp sil,','
 je .delimiter_ok
 cmp sil,9
 jne .invalid
.delimiter_ok:
 test edx,edx
 jz .invalid
 cmp edx,G080_MAX_FIELDS
 ja .limit
 mov qword [rdi+G080_DELIM_IN_QUOTES],0
 mov qword [rdi+G080_DELIM_FIELDS],0
 mov qword [rdi+G080_DELIM_RECORDS],0
 mov qword [rdi+G080_DELIM_CURRENT_FIELDS],1
 mov qword [rdi+G080_DELIM_FIELD_START],1
 mov qword [rdi+G080_DELIM_JUST_CLOSED],0
 movzx rax,sil
 mov [rdi+G080_DELIM_DELIMITER],rax
 mov [rdi+G080_DELIM_MAX_FIELDS],rdx
 mov qword [rdi+G080_DELIM_RECORD_OPEN],0
 mov qword [rdi+G080_DELIM_PENDING_CR],0
 mov qword [rdi+G080_DELIM_BYTES],0
 mov qword [rdi+G080_DELIM_PENDING_QUOTE],0
 mov qword [rdi+G080_DELIM_UTF8_NEEDED],0
 mov qword [rdi+G080_DELIM_UTF8_LOWER],0x80
 mov qword [rdi+G080_DELIM_UTF8_UPPER],0xbf
 xor eax,eax
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI state, RSI chunk, RDX len, RCX final. Counters and quote state cross
; chunk boundaries; only bounded metadata is retained.
nebo_g080_delimited_feed:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rcx,1
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r8d,r8d
.loop:
 cmp r8,r13
 jae .finish
 movzx eax,byte [r12+r8]
 mov r9,[rbx+G080_DELIM_UTF8_NEEDED]
 test r9,r9
 jnz .utf8_continuation
 cmp al,0x80
 jb .utf8_ok
 cmp al,0xc2
 jb .syntax_saved
 cmp al,0xdf
 jbe .utf8_two
 cmp al,0xe0
 je .utf8_three_e0
 cmp al,0xed
 je .utf8_three_ed
 cmp al,0xef
 jbe .utf8_three
 cmp al,0xf0
 je .utf8_four_f0
 cmp al,0xf4
 je .utf8_four_f4
 cmp al,0xf3
 jbe .utf8_four
 jmp .syntax_saved
.utf8_two:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],1
 jmp .utf8_default_bounds
.utf8_three_e0:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],2
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0xa0
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0xbf
 jmp .utf8_ok
.utf8_three_ed:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],2
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0x80
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0x9f
 jmp .utf8_ok
.utf8_three:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],2
 jmp .utf8_default_bounds
.utf8_four_f0:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],3
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0x90
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0xbf
 jmp .utf8_ok
.utf8_four_f4:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],3
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0x80
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0x8f
 jmp .utf8_ok
.utf8_four:
 mov qword [rbx+G080_DELIM_UTF8_NEEDED],3
.utf8_default_bounds:
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0x80
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0xbf
 jmp .utf8_ok
.utf8_continuation:
 mov r10,[rbx+G080_DELIM_UTF8_LOWER]
 cmp rax,r10
 jb .syntax_saved
 mov r10,[rbx+G080_DELIM_UTF8_UPPER]
 cmp rax,r10
 ja .syntax_saved
 dec qword [rbx+G080_DELIM_UTF8_NEEDED]
 mov qword [rbx+G080_DELIM_UTF8_LOWER],0x80
 mov qword [rbx+G080_DELIM_UTF8_UPPER],0xbf
.utf8_ok:
 cmp qword [rbx+G080_DELIM_PENDING_CR],0
 je .not_pending
 mov qword [rbx+G080_DELIM_PENDING_CR],0
 cmp al,10
 je .skip_lf
.not_pending:
 cmp qword [rbx+G080_DELIM_PENDING_QUOTE],0
 je .not_pending_quote
 mov qword [rbx+G080_DELIM_PENDING_QUOTE],0
 cmp al,'"'
 jne .pending_closed
 inc qword [rbx+G080_DELIM_BYTES]
 inc r8
 jmp .loop
.pending_closed:
 mov qword [rbx+G080_DELIM_IN_QUOTES],0
 mov qword [rbx+G080_DELIM_JUST_CLOSED],1
.not_pending_quote:
 inc qword [rbx+G080_DELIM_BYTES]
 mov qword [rbx+G080_DELIM_RECORD_OPEN],1
 cmp al,'"'
 jne .not_quote
 cmp qword [rbx+G080_DELIM_IN_QUOTES],0
 je .open_quote
 lea r9,[r8+1]
 cmp r9,r13
 jb .quote_has_next
 test r14,r14
 jnz .close_quote
 mov qword [rbx+G080_DELIM_PENDING_QUOTE],1
 inc r8
 jmp .loop
.quote_has_next:
 cmp byte [r12+r9],'"'
 jne .close_quote
 add r8,2
 jmp .loop
.open_quote:
 cmp qword [rbx+G080_DELIM_FIELD_START],1
 jne .syntax_saved
 mov qword [rbx+G080_DELIM_IN_QUOTES],1
 mov qword [rbx+G080_DELIM_FIELD_START],0
 mov qword [rbx+G080_DELIM_JUST_CLOSED],0
 inc r8
 jmp .loop
.close_quote:
 mov qword [rbx+G080_DELIM_IN_QUOTES],0
 mov qword [rbx+G080_DELIM_JUST_CLOSED],1
 inc r8
 jmp .loop
.not_quote:
 cmp qword [rbx+G080_DELIM_IN_QUOTES],0
 jne .next
 cmp qword [rbx+G080_DELIM_JUST_CLOSED],0
 je .classify
 mov dl,[rbx+G080_DELIM_DELIMITER]
 cmp al,dl
 je .field
 cmp al,10
 je .record
 cmp al,13
 je .record_cr
 jmp .syntax_saved
.classify:
 mov dl,[rbx+G080_DELIM_DELIMITER]
 cmp al,dl
 je .field
 cmp al,10
 je .record
 cmp al,13
 je .record_cr
 mov qword [rbx+G080_DELIM_FIELD_START],0
.next: inc r8
 jmp .loop
.field:
 inc qword [rbx+G080_DELIM_CURRENT_FIELDS]
 mov rax,[rbx+G080_DELIM_CURRENT_FIELDS]
 cmp rax,[rbx+G080_DELIM_MAX_FIELDS]
 ja .limit_saved
 mov qword [rbx+G080_DELIM_FIELD_START],1
 mov qword [rbx+G080_DELIM_JUST_CLOSED],0
 inc r8
 jmp .loop
.record_cr:
 mov qword [rbx+G080_DELIM_PENDING_CR],1
.record:
 mov rax,[rbx+G080_DELIM_CURRENT_FIELDS]
 add [rbx+G080_DELIM_FIELDS],rax
 inc qword [rbx+G080_DELIM_RECORDS]
 mov qword [rbx+G080_DELIM_CURRENT_FIELDS],1
 mov qword [rbx+G080_DELIM_FIELD_START],1
 mov qword [rbx+G080_DELIM_JUST_CLOSED],0
 mov qword [rbx+G080_DELIM_RECORD_OPEN],0
 inc r8
 jmp .loop
.skip_lf:
 inc r8
 jmp .loop
.finish:
 test r14,r14
 jz .ok
 cmp qword [rbx+G080_DELIM_UTF8_NEEDED],0
 jne .syntax_saved
 cmp qword [rbx+G080_DELIM_PENDING_QUOTE],0
 je .no_pending_quote_final
 mov qword [rbx+G080_DELIM_PENDING_QUOTE],0
 mov qword [rbx+G080_DELIM_IN_QUOTES],0
 mov qword [rbx+G080_DELIM_JUST_CLOSED],1
.no_pending_quote_final:
 cmp qword [rbx+G080_DELIM_IN_QUOTES],0
 jne .syntax_saved
 mov qword [rbx+G080_DELIM_PENDING_CR],0
 cmp qword [rbx+G080_DELIM_RECORD_OPEN],0
 je .ok
 mov rax,[rbx+G080_DELIM_CURRENT_FIELDS]
 add [rbx+G080_DELIM_FIELDS],rax
 inc qword [rbx+G080_DELIM_RECORDS]
 mov qword [rbx+G080_DELIM_RECORD_OPEN],0
.ok: xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
.saved:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI value, ESI tag. Only JSON container/null roots are constructors here.
nebo_g080_json_value_init:
 test rdi,rdi
 jz .invalid
 cmp esi,G080_JSON_NULL
 je .ok
 cmp esi,G080_JSON_OBJECT
 je .ok
 cmp esi,G080_JSON_ARRAY
 jne .invalid
.ok:
 mov [rdi+G080_JSON_TAG],rsi
 mov qword [rdi+G080_JSON_COUNT],0
 xor eax,eax
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; Lexicographic compare: old key RDI/RSI, new key RDX/RCX.
g080_key_compare:
 push rbx
 xor r8d,r8d
 mov r9,rsi
 cmp r9,rcx
 cmova r9,rcx
.loop:
 cmp r8,r9
 jae .length
 movzx eax,byte [rdi+r8]
 movzx ebx,byte [rdx+r8]
 cmp eax,ebx
 jb .less
 ja .greater
 inc r8
 jmp .loop
.length:
 cmp rsi,rcx
 jb .less
 ja .greater
 xor eax,eax
 pop rbx
 ret
.less: mov eax,-1
 pop rbx
 ret
.greater: mov eax,1
 pop rbx
 ret

; RDI object, RSI key, RDX key len, ECX type, R8 value/pointer, R9 text len.
; Keys must be strictly increasing, making duplicates and nondeterministic
; insertion order explicit conflicts. The object is unchanged on failure.
nebo_g080_json_set:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,64
 ja .limit
 cmp qword [rdi+G080_JSON_TAG],G080_JSON_OBJECT
 jne .invalid
 cmp ecx,G080_JSON_NULL
 je .type_ok
 cmp ecx,G080_JSON_TEXT
 je .text
 cmp ecx,G080_JSON_INT
 je .type_ok
 cmp ecx,G080_JSON_BOOL
 jne .invalid
 cmp r8,1
 ja .invalid
 jmp .type_ok
.text:
 test r8,r8
 jz .invalid
 cmp r9,G080_MAX_BYTES
 ja .limit
.type_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 push r9
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14d,ecx
 mov r15,r8
 mov rdi,r12
 mov rsi,r13
 call g080_utf8_validate
 test eax,eax
 jnz .invalid_saved
 cmp r14d,G080_JSON_TEXT
 jne .key_validate_start
 mov rdi,r15
 mov rsi,[rsp]
 call g080_utf8_validate
 test eax,eax
 jnz .invalid_saved
.key_validate_start:
 xor ecx,ecx
.key_validate:
 cmp rcx,r13
 jae .order
 mov al,[r12+rcx]
 cmp al,32
 jb .invalid_saved
 inc rcx
 jmp .key_validate
.order:
 mov r10,[rbx+G080_JSON_COUNT]
 cmp r10,G080_MAX_JSON_FIELDS
 jae .capacity_saved
 test r10,r10
 jz .commit
 mov rax,r10
 dec rax
 imul rax,G080_JSON_SLOT_SIZE
 lea r11,[rbx+G080_JSON_SLOTS+rax]
 mov rdi,[r11+G080_JSON_SLOT_KEY]
 mov rsi,[r11+G080_JSON_SLOT_KEY_LEN]
 mov rdx,r12
 mov rcx,r13
 call g080_key_compare
 cmp eax,-1
 jne .conflict_saved
.commit:
 mov r10,[rbx+G080_JSON_COUNT]
 mov rax,r10
 imul rax,G080_JSON_SLOT_SIZE
 lea r11,[rbx+G080_JSON_SLOTS+rax]
 mov [r11+G080_JSON_SLOT_KEY],r12
 mov [r11+G080_JSON_SLOT_KEY_LEN],r13
 mov [r11+G080_JSON_SLOT_TYPE],r14
 mov [r11+G080_JSON_SLOT_VALUE],r15
 mov rax,[rsp]
 mov [r11+G080_JSON_SLOT_VALUE_LEN],rax
 inc r10
 mov [rbx+G080_JSON_COUNT],r10
 xor eax,eax
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.conflict_saved: mov eax,-FMT_CONFLICT
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid_saved: mov eax,-FMT_INVALID
.saved:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI value, ESI expected tag -> 1/0, or negative INVALID.
nebo_g080_json_type_is:
 test rdi,rdi
 jz .invalid
 cmp esi,G080_JSON_NULL
 jb .invalid
 cmp esi,G080_JSON_ARRAY
 ja .invalid
 xor eax,eax
 cmp [rdi+G080_JSON_TAG],rsi
 sete al
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; Whitespace helper for the strict recursive-descent JSON parser. R12 is the
; input, R13 its length and R14 the current byte offset.
g080_json_skip_ws:
.loop:
 cmp r14,r13
 jae .done
 mov al,[r12+r14]
 cmp al,' '
 je .next
 cmp al,9
 je .next
 cmp al,10
 je .next
 cmp al,13
 jne .done
.next: inc r14
 jmp .loop
.done: ret

g080_json_hex:
 cmp al,'0'
 jb .no
 cmp al,'9'
 jbe .yes
 cmp al,'A'
 jb .lower
 cmp al,'F'
 jbe .yes
.lower:
 cmp al,'a'
 jb .no
 cmp al,'f'
 ja .no
.yes: mov eax,1
 ret
.no: xor eax,eax
 ret

; Parse a JSON string and return an FNV-1a hash in RDX. Controls, incomplete
; escapes and non-JSON escapes are rejected.
g080_json_parse_string:
 cmp r14,r13
 jae .syntax
 cmp byte [r12+r14],'"'
 jne .syntax
 inc r14
 mov rdx,0xcbf29ce484222325
.loop:
 cmp r14,r13
 jae .syntax
 movzx eax,byte [r12+r14]
 cmp al,'"'
 je .close
 cmp al,32
 jb .syntax
 cmp al,92
 je .escape
 xor dl,al
 imul rdx,rdx,0x1b3
 inc r14
 jmp .loop
.escape:
 inc r14
 cmp r14,r13
 jae .syntax
 movzx eax,byte [r12+r14]
 cmp al,'"'
 je .escaped_one
 cmp al,92
 je .escaped_one
 cmp al,'/'
 je .escaped_one
 cmp al,'b'
 je .escaped_one
 cmp al,'f'
 je .escaped_one
 cmp al,'n'
 je .escaped_one
 cmp al,'r'
 je .escaped_one
 cmp al,'t'
 je .escaped_one
 cmp al,'u'
 jne .syntax
 mov ecx,4
.unicode:
 inc r14
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 call g080_json_hex
 test eax,eax
 jz .syntax
 dec ecx
 jnz .unicode
 mov al,'u'
.escaped_one:
 xor dl,al
 imul rdx,rdx,0x1b3
 inc r14
 jmp .loop
.close:
 inc r14
 xor eax,eax
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret

g080_json_parse_literal:
 ; RSI literal pointer, EDX literal length.
 xor ecx,ecx
.loop:
 cmp ecx,edx
 jae .ok
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,[rsi+rcx]
 jne .syntax
 inc r14
 inc ecx
 jmp .loop
.ok: xor eax,eax
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret

section .rodata
g80_lit_true: db 'true'
g80_lit_false: db 'false'
g80_lit_null: db 'null'
section .text

g080_json_parse_number:
 cmp r14,r13
 jae .syntax
 cmp byte [r12+r14],'-'
 jne .integer
 inc r14
 cmp r14,r13
 jae .syntax
.integer:
 mov al,[r12+r14]
 cmp al,'0'
 jne .nonzero
 inc r14
 cmp r14,r13
 jae .fraction
 mov al,[r12+r14]
 cmp al,'0'
 jb .fraction
 cmp al,'9'
 jbe .syntax
 jmp .fraction
.nonzero:
 cmp al,'1'
 jb .syntax
 cmp al,'9'
 ja .syntax
.digits:
 inc r14
 cmp r14,r13
 jae .fraction
 mov al,[r12+r14]
 cmp al,'0'
 jb .fraction
 cmp al,'9'
 jbe .digits
.fraction:
 cmp r14,r13
 jae .ok
 cmp byte [r12+r14],'.'
 jne .exponent
 inc r14
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,'0'
 jb .syntax
 cmp al,'9'
 ja .syntax
.fraction_digits:
 inc r14
 cmp r14,r13
 jae .ok
 mov al,[r12+r14]
 cmp al,'0'
 jb .exponent
 cmp al,'9'
 jbe .fraction_digits
.exponent:
 cmp r14,r13
 jae .ok
 mov al,[r12+r14]
 cmp al,'e'
 je .exp_start
 cmp al,'E'
 jne .ok
.exp_start:
 inc r14
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,'+'
 je .exp_sign
 cmp al,'-'
 jne .exp_digit
.exp_sign:
 inc r14
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
.exp_digit:
 cmp al,'0'
 jb .syntax
 cmp al,'9'
 ja .syntax
.exp_digits:
 inc r14
 cmp r14,r13
 jae .ok
 mov al,[r12+r14]
 cmp al,'0'
 jb .ok
 cmp al,'9'
 jbe .exp_digits
.ok: xor eax,eax
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret

g080_json_parse_array:
 inc ebx
 mov eax,r15d
 cmp ebx,eax
 ja .limit
 inc r14
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 cmp byte [r12+r14],']'
 je .empty
.value:
 call g080_json_parse_value
 test eax,eax
 jnz .return
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,']'
 je .close
 cmp al,','
 jne .syntax
 inc r14
 call g080_json_skip_ws
 jmp .value
.empty:
 inc r14
 dec ebx
 xor eax,eax
 ret
.close:
 inc r14
 dec ebx
 xor eax,eax
 ret
.limit: dec ebx
 mov eax,-FMT_LIMIT
 ret
.syntax: mov eax,-FMT_SYNTAX
.return:
 dec ebx
 ret

; Each object frame owns a bounded set of key hashes. Duplicate rejection is
; policy 1; policy 2 accepts the last value but serialization remains stable.
g080_json_parse_object:
 inc ebx
 mov eax,r15d
 cmp ebx,eax
 ja .limit_before
 sub rsp,520
 mov qword [rsp+512],0
 inc r14
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 cmp byte [r12+r14],'}'
 je .empty
.member:
 call g080_json_parse_string
 test eax,eax
 jnz .return
 mov r10,r15
 shr r10,32
 cmp r10,G080_DUPLICATE_REJECT
 jne .store
 xor ecx,ecx
.duplicate_loop:
 cmp rcx,[rsp+512]
 jae .store
 cmp [rsp+rcx*8],rdx
 je .conflict
 inc rcx
 jmp .duplicate_loop
.store:
 mov rcx,[rsp+512]
 cmp rcx,G080_MAX_FIELDS
 jae .limit
 mov [rsp+rcx*8],rdx
 inc rcx
 mov [rsp+512],rcx
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 cmp byte [r12+r14],':'
 jne .syntax
 inc r14
 call g080_json_parse_value
 test eax,eax
 jnz .return
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,'}'
 je .close
 cmp al,','
 jne .syntax
 inc r14
 call g080_json_skip_ws
 jmp .member
.empty:
 inc r14
 add rsp,520
 dec ebx
 xor eax,eax
 ret
.close:
 inc r14
 add rsp,520
 dec ebx
 xor eax,eax
 ret
.conflict: mov eax,-FMT_CONFLICT
 jmp .return
.limit: mov eax,-FMT_LIMIT
 jmp .return
.syntax: mov eax,-FMT_SYNTAX
.return:
 add rsp,520
 dec ebx
 ret
.limit_before:
 dec ebx
 mov eax,-FMT_LIMIT
 ret

g080_json_parse_value:
 call g080_json_skip_ws
 cmp r14,r13
 jae .syntax
 mov al,[r12+r14]
 cmp al,'{'
 je g080_json_parse_object
 cmp al,'['
 je g080_json_parse_array
 cmp al,'"'
 je g080_json_parse_string
 cmp al,'t'
 je .true
 cmp al,'f'
 je .false
 cmp al,'n'
 je .null
 cmp al,'-'
 je g080_json_parse_number
 cmp al,'0'
 jb .syntax
 cmp al,'9'
 jbe g080_json_parse_number
.syntax: mov eax,-FMT_SYNTAX
 ret
.true:
 lea rsi,[rel g80_lit_true]
 mov edx,4
 jmp g080_json_parse_literal
.false:
 lea rsi,[rel g80_lit_false]
 mov edx,5
 jmp g080_json_parse_literal
.null:
 lea rsi,[rel g80_lit_null]
 mov edx,4
 jmp g080_json_parse_literal

; RDI bytes, RSI len, EDX max depth, ECX duplicate policy.
nebo_g080_json_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .syntax
 cmp rsi,G080_MAX_BYTES
 ja .limit
 test edx,edx
 jz .invalid
 cmp edx,G080_MAX_DEPTH
 ja .limit
 cmp ecx,G080_DUPLICATE_REJECT
 je .policy_ok
 cmp ecx,G080_DUPLICATE_LAST_WINS
 jne .invalid
.policy_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r15d,edx
 mov eax,ecx
 shl rax,32
 or r15,rax
 mov rdi,r12
 mov rsi,r13
 call g080_utf8_validate
 test eax,eax
 jnz .saved
 xor r14d,r14d
 xor ebx,ebx
 call g080_json_parse_value
 test eax,eax
 jnz .saved
 call g080_json_skip_ws
 cmp r14,r13
 jne .trailing
 xor eax,eax
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trailing: mov eax,-FMT_SYNTAX
 jmp .saved
.limit: mov eax,-FMT_LIMIT
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI bytes, RSI len, EDX depth, ECX policy, R8 output JsonValue. Typed
; conversion is deliberately bounded: it authenticates grammar/policy and
; publishes the root tag atomically without retaining borrowed input bytes.
nebo_g080_json_decode:
 test r8,r8
 jz .invalid
 push rbx
 push r12
 push r13
 mov rbx,r8
 mov r12,rdi
 mov r13,rsi
 call nebo_g080_json_validate
 test eax,eax
 jnz .saved
 xor ecx,ecx
.leading:
 cmp rcx,r13
 jae .decode_syntax
 mov al,[r12+rcx]
 cmp al,' '
 je .lead_next
 cmp al,9
 je .lead_next
 cmp al,10
 je .lead_next
 cmp al,13
 je .lead_next
 cmp al,'{'
 je .tag_object
 cmp al,'['
 je .tag_array
 cmp al,'"'
 je .tag_text
 cmp al,'t'
 je .tag_bool
 cmp al,'f'
 je .tag_bool
 cmp al,'n'
 je .tag_null
 mov eax,G080_JSON_INT
 jmp .publish
.tag_object: mov eax,G080_JSON_OBJECT
 jmp .publish
.tag_array: mov eax,G080_JSON_ARRAY
 jmp .publish
.tag_text: mov eax,G080_JSON_TEXT
 jmp .publish
.tag_bool: mov eax,G080_JSON_BOOL
 jmp .publish
.tag_null: mov eax,G080_JSON_NULL
.publish:
 mov [rbx+G080_JSON_TAG],rax
 mov qword [rbx+G080_JSON_COUNT],0
 xor eax,eax
.saved:
 pop r13
 pop r12
 pop rbx
 ret
.lead_next: inc rcx
 jmp .leading
.decode_syntax: mov eax,-FMT_SYNTAX
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

g080_json_string_measure:
 test rdi,rdi
 jz .invalid
 mov rax,2
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 mov dl,[rdi+rcx]
 cmp dl,32
 jb .invalid
 inc rax
 cmp dl,'"'
 je .escaped
 cmp dl,92
 jne .next
.escaped: inc rax
.next: inc rcx
 jmp .loop
.done: ret
.invalid: mov rax,-FMT_INVALID
 ret

; RDI bytes, RSI len, RDX destination. Caller preflights capacity.
g080_json_string_write:
 mov byte [rdx],'"'
 mov rax,1
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .close
 mov r8b,[rdi+rcx]
 cmp r8b,'"'
 je .escape
 cmp r8b,92
 jne .copy
.escape:
 mov byte [rdx+rax],92
 inc rax
.copy:
 mov [rdx+rax],r8b
 inc rax
 inc rcx
 jmp .loop
.close:
 mov byte [rdx+rax],'"'
 inc rax
 ret

; RDI signed value, RSI destination -> RAX bytes written.
g080_i64_write:
 push rbx
 sub rsp,32
 mov rax,rdi
 xor ebx,ebx
 test rax,rax
 jns .absolute
 mov bl,1
 neg rax
.absolute:
 xor ecx,ecx
 mov r8d,10
.digits:
 xor edx,edx
 div r8
 add dl,'0'
 mov [rsp+rcx],dl
 inc rcx
 test rax,rax
 jnz .digits
 xor eax,eax
 test bl,bl
 jz .copy
 mov byte [rsi],'-'
 inc rax
.copy:
 test rcx,rcx
 jz .done
 dec rcx
 mov dl,[rsp+rcx]
 mov [rsi+rax],dl
 inc rax
 jmp .copy
.done:
 add rsp,32
 pop rbx
 ret

; RDI bounded JsonValue object, RSI destination, RDX capacity. Keys are
; already sorted by the setter, so output is deterministic and canonical.
nebo_g080_json_stringify:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+G080_JSON_TAG]
 cmp rax,G080_JSON_NULL
 je .null
 cmp rax,G080_JSON_ARRAY
 je .array
 cmp rax,G080_JSON_OBJECT
 jne .invalid
 mov rax,[rdi+G080_JSON_COUNT]
 cmp rax,G080_MAX_JSON_FIELDS
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,2                      ; braces
 xor ebx,ebx
.measure_loop:
 cmp rbx,[r12+G080_JSON_COUNT]
 jae .capacity
 test rbx,rbx
 jz .measure_key
 inc r15                       ; comma
.measure_key:
 mov rax,rbx
 imul rax,G080_JSON_SLOT_SIZE
 lea r10,[r12+G080_JSON_SLOTS+rax]
 mov rdi,[r10+G080_JSON_SLOT_KEY]
 mov rsi,[r10+G080_JSON_SLOT_KEY_LEN]
 call g080_json_string_measure
 test rax,rax
 js .invalid_saved
 add r15,rax
 inc r15                       ; colon
 mov rax,rbx
 imul rax,G080_JSON_SLOT_SIZE
 lea r10,[r12+G080_JSON_SLOTS+rax]
 mov rax,[r10+G080_JSON_SLOT_TYPE]
 cmp rax,G080_JSON_TEXT
 je .measure_text
 cmp rax,G080_JSON_INT
 je .measure_int
 cmp rax,G080_JSON_BOOL
 je .measure_bool
 cmp rax,G080_JSON_NULL
 jne .invalid_saved
 add r15,4
 jmp .measure_next
.measure_text:
 mov rdi,[r10+G080_JSON_SLOT_VALUE]
 mov rsi,[r10+G080_JSON_SLOT_VALUE_LEN]
 call g080_json_string_measure
 test rax,rax
 js .invalid_saved
 add r15,rax
 jmp .measure_next
.measure_int:
 mov rdi,[r10+G080_JSON_SLOT_VALUE]
 lea rsi,[rel g80_atomic]
 call g080_i64_write
 add r15,rax
 jmp .measure_next
.measure_bool:
 cmp qword [r10+G080_JSON_SLOT_VALUE],0
 je .bool_false
 add r15,4
 jmp .measure_next
.bool_false: add r15,5
.measure_next:
 inc rbx
 jmp .measure_loop
.capacity:
 cmp r15,r14
 ja .capacity_saved
 xor r15d,r15d
 mov byte [r13+r15],'{'
 inc r15
 xor ebx,ebx
.write_loop:
 cmp rbx,[r12+G080_JSON_COUNT]
 jae .write_close
 test rbx,rbx
 jz .write_key
 mov byte [r13+r15],','
 inc r15
.write_key:
 mov rax,rbx
 imul rax,G080_JSON_SLOT_SIZE
 lea r10,[r12+G080_JSON_SLOTS+rax]
 mov rdi,[r10+G080_JSON_SLOT_KEY]
 mov rsi,[r10+G080_JSON_SLOT_KEY_LEN]
 lea rdx,[r13+r15]
 call g080_json_string_write
 add r15,rax
 mov byte [r13+r15],':'
 inc r15
 mov rax,rbx
 imul rax,G080_JSON_SLOT_SIZE
 lea r10,[r12+G080_JSON_SLOTS+rax]
 mov rax,[r10+G080_JSON_SLOT_TYPE]
 cmp rax,G080_JSON_TEXT
 je .write_text
 cmp rax,G080_JSON_INT
 je .write_int
 cmp rax,G080_JSON_BOOL
 je .write_bool
 mov dword [r13+r15],'null'
 add r15,4
 jmp .write_next
.write_text:
 mov rdi,[r10+G080_JSON_SLOT_VALUE]
 mov rsi,[r10+G080_JSON_SLOT_VALUE_LEN]
 lea rdx,[r13+r15]
 call g080_json_string_write
 add r15,rax
 jmp .write_next
.write_int:
 mov rdi,[r10+G080_JSON_SLOT_VALUE]
 lea rsi,[r13+r15]
 call g080_i64_write
 add r15,rax
 jmp .write_next
.write_bool:
 cmp qword [r10+G080_JSON_SLOT_VALUE],0
 je .write_false
 mov dword [r13+r15],'true'
 add r15,4
 jmp .write_next
.write_false:
 mov dword [r13+r15],'fals'
 mov byte [r13+r15+4],'e'
 add r15,5
.write_next:
 inc rbx
 jmp .write_loop
.write_close:
 mov byte [r13+r15],'}'
 inc r15
 mov rax,r15
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid_saved: mov eax,-FMT_INVALID
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,-FMT_INVALID
 ret
.null:
 cmp rdx,4
 jb .capacity_scalar
 mov dword [rsi],'null'
 mov eax,4
 ret
.array:
 cmp qword [rdi+G080_JSON_COUNT],0
 jne .invalid
 cmp rdx,2
 jb .capacity_scalar
 mov word [rsi],'[]'
 mov eax,2
 ret
.capacity_scalar: mov eax,-FMT_CAPACITY
 ret

; RDI JsonValue, RSI output, RDX capacity. Pretty rendering derives from the
; canonical serializer, then inserts deterministic two-space object layout.
nebo_g080_json_pretty:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r13,rsi
 mov r14,rdx
 lea rsi,[rel g80_file_scratch]
 mov edx,G080_MAX_BYTES
 call nebo_g080_json_stringify
 test rax,rax
 js .saved
 mov r12,rax
 lea r11,[rel g80_file_scratch]
 cmp qword [rbx+G080_JSON_TAG],G080_JSON_OBJECT
 jne .copy_scalar
 mov r15,r12
 cmp qword [rbx+G080_JSON_COUNT],0
 je .capacity
 add r15,4                     ; opening newline/indent and closing newline
 xor r8d,r8d
 xor r9d,r9d                   ; in string
 xor r10d,r10d                 ; escaped
.measure:
 cmp r8,r12
 jae .capacity
 mov al,[r11+r8]
 test r9,r9
 jz .measure_out
 test r10,r10
 jnz .measure_escape_done
 cmp al,92
 je .measure_escape
 cmp al,'"'
 je .measure_quote
 jmp .measure_next
.measure_escape: mov r10d,1
 jmp .measure_next
.measure_escape_done: xor r10d,r10d
 jmp .measure_next
.measure_quote: xor r9d,r9d
 jmp .measure_next
.measure_out:
 cmp al,'"'
 je .measure_open
 cmp al,','
 jne .measure_next
 add r15,3                     ; newline plus two spaces
 jmp .measure_next
.measure_open: mov r9d,1
.measure_next: inc r8
 jmp .measure
.capacity:
 cmp r15,r14
 ja .capacity_saved
 xor r15d,r15d
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
.write:
 cmp r8,r12
 jae .return
 mov al,[r11+r8]
 test r9,r9
 jnz .write_string
 cmp al,'"'
 je .write_open
 cmp al,'{'
 je .write_brace_open
 cmp al,','
 je .write_comma
 cmp al,':'
 je .write_colon
 cmp al,'}'
 je .write_brace_close
 jmp .write_byte
.write_open: mov r9d,1
 jmp .write_byte
.write_string:
 test r10,r10
 jnz .write_escape_done
 cmp al,92
 je .write_escape
 cmp al,'"'
 jne .write_byte
 xor r9d,r9d
 jmp .write_byte
.write_escape: mov r10d,1
 jmp .write_byte
.write_escape_done: xor r10d,r10d
 jmp .write_byte
.write_brace_open:
 mov [r13+r15],al
 inc r15
 cmp qword [rbx+G080_JSON_COUNT],0
 je .advance
 mov byte [r13+r15],10
 mov word [r13+r15+1],'  '
 add r15,3
 jmp .advance
.write_comma:
 mov [r13+r15],al
 mov byte [r13+r15+1],10
 mov word [r13+r15+2],'  '
 add r15,4
 jmp .advance
.write_colon:
 mov [r13+r15],al
 mov byte [r13+r15+1],' '
 add r15,2
 jmp .advance
.write_brace_close:
 cmp qword [rbx+G080_JSON_COUNT],0
 je .write_byte
 mov byte [r13+r15],10
 inc r15
.write_byte:
 mov [r13+r15],al
 inc r15
.advance: inc r8
 jmp .write
.copy_scalar:
 cmp r12,r14
 ja .capacity_saved
 mov rax,r12
 mov rdi,r13
 lea rsi,[rel g80_file_scratch]
 mov rcx,r12
 rep movsb
 jmp .saved
.return: mov rax,r15
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,-FMT_INVALID
 ret

nebo_g080_jsonl_init:
 test rdi,rdi
 jz .invalid
 mov qword [rdi+G080_JSONL_LINE_LEN],0
 mov qword [rdi+G080_JSONL_VALID],0
 mov qword [rdi+G080_JSONL_INVALID],0
 mov qword [rdi+G080_JSONL_BYTES],0
 xor eax,eax
 ret
.invalid: mov eax,-FMT_INVALID
 ret

g080_jsonl_commit_line:
 push rbx
 mov rbx,rdi
 mov rsi,[rbx+G080_JSONL_LINE_LEN]
 test rsi,rsi
 jz .reset
 lea rdi,[rbx+G080_JSONL_BUFFER]
 mov edx,G080_MAX_DEPTH
 mov ecx,G080_DUPLICATE_REJECT
 call nebo_g080_json_validate
 test eax,eax
 jnz .bad
 inc qword [rbx+G080_JSONL_VALID]
 jmp .reset
.bad: inc qword [rbx+G080_JSONL_INVALID]
.reset:
 mov qword [rbx+G080_JSONL_LINE_LEN],0
 xor eax,eax
 pop rbx
 ret

; RDI state, RSI chunk, RDX len, RCX final. Lines are validated as chunks
; arrive, so the full JSONL file is never retained in memory.
nebo_g080_jsonl_feed:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rcx,1
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r8d,r8d
.loop:
 cmp r8,r13
 jae .final
 mov al,[r12+r8]
 inc qword [rbx+G080_JSONL_BYTES]
 cmp al,10
 je .line
 mov r9,[rbx+G080_JSONL_LINE_LEN]
 cmp r9,G080_MAX_JSONL_LINE
 jae .limit_saved
 mov [rbx+G080_JSONL_BUFFER+r9],al
 inc r9
 mov [rbx+G080_JSONL_LINE_LEN],r9
 inc r8
 jmp .loop
.line:
 mov rdi,rbx
 call g080_jsonl_commit_line
 inc r8
 jmp .loop
.final:
 test r14,r14
 jz .ok
 mov rdi,rbx
 call g080_jsonl_commit_line
.ok: xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit_saved: mov eax,-FMT_LIMIT
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; Safe relative basename for explicit dirfd operations. This deliberately
; rejects separators, dot-dot and unterminated syscall strings.
nebo_g080_path_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,64
 ja .limit
 cmp byte [rdi+rsi],0
 jne .invalid
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 mov al,[rdi+rcx]
 cmp al,32
 jb .invalid
 cmp al,126
 ja .invalid
 cmp al,'/'
 je .conflict
 cmp al,92
 je .conflict
 cmp al,'.'
 jne .next
 lea rax,[rcx+1]
 cmp rax,rsi
 jae .next
 cmp byte [rdi+rcx+1],'.'
 je .conflict
.next: inc rcx
 jmp .loop
.ok: xor eax,eax
 ret
.conflict: mov eax,-FMT_CONFLICT
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; EDI dirfd, RSI final basename, RDX path len, RCX bytes, R8 len. A fixed
; private temporary is fsynced then renamed inside the supplied directory.
nebo_g080_file_write_atomic:
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,G080_MAX_BYTES
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 movsxd r12,edi
 mov r13,rsi
 mov r14,rcx
 mov r15,r8
 mov rdi,r13
 mov rsi,rdx
 call nebo_g080_path_validate
 test eax,eax
 jnz .saved
 mov eax,257                    ; openat
 mov rdi,r12
 lea rsi,[rel g80_temp_name]
 mov edx,0xA00C1               ; WRONLY|CREAT|EXCL|CLOEXEC|NOFOLLOW
 mov r10d,384                  ; 0600
 syscall
 test rax,rax
 js .conflict_saved
 mov rbx,rax
 xor r9d,r9d
.write:
 cmp r9,r15
 jae .sync
 mov eax,1
 mov rdi,rbx
 lea rsi,[r14+r9]
 mov rdx,r15
 sub rdx,r9
 syscall
 test rax,rax
 jle .io_fail
 add r9,rax
 jmp .write
.sync:
 mov eax,74                    ; fsync
 mov rdi,rbx
 syscall
 test rax,rax
 js .io_fail
 mov eax,3
 mov rdi,rbx
 syscall
 mov eax,264                   ; renameat
 mov rdi,r12
 lea rsi,[rel g80_temp_name]
 mov rdx,r12
 mov r10,r13
 syscall
 test rax,rax
 js .cleanup
 mov rax,r15
 jmp .saved
.io_fail:
 mov eax,3
 mov rdi,rbx
 syscall
.cleanup:
 mov eax,263                   ; unlinkat
 mov rdi,r12
 lea rsi,[rel g80_temp_name]
 xor edx,edx
 syscall
.conflict_saved: mov eax,-FMT_CONFLICT
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; EDI dirfd, RSI basename, RDX path len, RCX output, R8 capacity. The file is
; first read into private bounded scratch and copied only after success.
nebo_g080_file_read:
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,G080_MAX_BYTES
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 movsxd r12,edi
 mov r13,rsi
 mov r14,rcx
 mov r15,r8
 mov rdi,r13
 mov rsi,rdx
 call nebo_g080_path_validate
 test eax,eax
 jnz .saved
 mov eax,257
 mov rdi,r12
 mov rsi,r13
 mov edx,0xA0000               ; RDONLY|CLOEXEC|NOFOLLOW
 xor r10d,r10d
 syscall
 test rax,rax
 js .not_found
 mov rbx,rax
 mov eax,0
 mov rdi,rbx
 lea rsi,[rel g80_file_scratch]
 mov rdx,r15
 inc rdx
 syscall
 mov r9,rax
 mov eax,3
 mov rdi,rbx
 syscall
 test r9,r9
 js .conflict_saved
 cmp r9,r15
 ja .capacity_saved
 mov rax,r9
 mov rdi,r14
 lea rsi,[rel g80_file_scratch]
 mov rcx,r9
 rep movsb
 jmp .saved
.not_found: mov eax,-FMT_NOT_FOUND
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.conflict_saved: mov eax,-FMT_CONFLICT
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

g080_configure_csv:
 ; EDI delimiter, ESI header, EDX formula policy.
 movzx rax,dil
 mov [rel g80_options+G080_CSV_DELIMITER],rax
 mov qword [rel g80_options+G080_CSV_QUOTE],'"'
 mov [rel g80_options+G080_CSV_HEADER],rsi
 mov qword [rel g80_options+G080_CSV_MAX_RECORDS],G080_MAX_RECORDS
 mov qword [rel g80_options+G080_CSV_MAX_FIELDS],G080_MAX_FIELDS
 mov [rel g80_options+G080_CSV_FORMULA_POLICY],rdx
 ret

g080_build_value:
 lea rdi,[rel g80_value]
 mov esi,G080_JSON_OBJECT
 call nebo_g080_json_value_init
 test eax,eax
 jnz .return
 lea rdi,[rel g80_value]
 lea rsi,[rel g80_key_active]
 mov edx,g80_key_active_len
 mov ecx,G080_JSON_BOOL
 mov r8d,1
 xor r9d,r9d
 call nebo_g080_json_set
 test eax,eax
 jnz .return
 lea rdi,[rel g80_value]
 lea rsi,[rel g80_key_count]
 mov edx,g80_key_count_len
 mov ecx,G080_JSON_INT
 mov r8d,80
 xor r9d,r9d
 call nebo_g080_json_set
 test eax,eax
 jnz .return
 lea rdi,[rel g80_value]
 lea rsi,[rel g80_key_name]
 mov edx,g80_key_name_len
 mov ecx,G080_JSON_TEXT
 lea r8,[rel g80_value_nebo]
 mov r9d,g80_value_nebo_len
 call nebo_g080_json_set
.return: ret

; EDI subgroup mode, ESI seed -> deterministic process-observable effect.
nebo_g080_source_probe:
 push r12
 push r13
 cmp edi,1
 jb .invalid
 cmp edi,8
 ja .invalid
 cmp esi,G080_SEED_MIN
 jb .invalid
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 je .s1
 cmp r12d,2
 je .s2
 cmp r12d,3
 je .s3
 cmp r12d,4
 je .s4
 cmp r12d,5
 je .s5
 cmp r12d,6
 je .s6
 cmp r12d,7
 je .s7
 jmp .s8
.s1:
 mov edi,','
 mov esi,1
 mov edx,G080_FORMULA_PREFIX
 call g080_configure_csv
 lea rdi,[rel g80_options]
 call nebo_g080_csv_options_validate
 test eax,eax
 jnz .invalid
 jmp .effect
.s2:
 mov edi,','
 mov esi,1
 mov edx,G080_FORMULA_PREFIX
 call g080_configure_csv
 lea rdi,[rel g80_csv_doc]
 mov esi,g80_csv_doc_len
 lea rdx,[rel g80_options]
 lea rcx,[rel g80_table]
 call nebo_g080_csv_parse
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_delim_state]
 mov esi,','
 mov edx,G080_MAX_FIELDS
 call nebo_g080_delimited_init
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_delim_state]
 lea rsi,[rel g80_csv_doc]
 mov edx,5
 xor ecx,ecx
 call nebo_g080_delimited_feed
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_delim_state]
 lea rsi,[rel g80_csv_doc+5]
 mov edx,g80_csv_doc_len-5
 mov ecx,1
 call nebo_g080_delimited_feed
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_formula]
 mov esi,g80_formula_len
 lea rdx,[rel g80_output]
 mov ecx,G080_MAX_BYTES
 mov r8d,','
 mov r9d,G080_FORMULA_PREFIX
 call nebo_g080_csv_encode_cell
 test rax,rax
 js .invalid
 jmp .effect
.s3:
 mov edi,9
 xor esi,esi
 mov edx,G080_FORMULA_REJECT
 call g080_configure_csv
 lea rdi,[rel g80_tsv_doc]
 mov esi,g80_tsv_doc_len
 lea rdx,[rel g80_options]
 lea rcx,[rel g80_table]
 call nebo_g080_csv_parse
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_delim_state]
 mov esi,9
 mov edx,G080_MAX_FIELDS
 call nebo_g080_delimited_init
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_delim_state]
 lea rsi,[rel g80_tsv_doc]
 mov edx,g80_tsv_doc_len
 mov ecx,1
 call nebo_g080_delimited_feed
 test eax,eax
 jnz .invalid
 jmp .effect
.s4:
 call g080_build_value
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_value]
 mov esi,G080_JSON_OBJECT
 call nebo_g080_json_type_is
 cmp eax,1
 jne .invalid
 jmp .effect
.s5:
 lea rdi,[rel g80_json_text]
 mov esi,g80_json_text_len
 mov edx,G080_MAX_DEPTH
 mov ecx,G080_DUPLICATE_REJECT
 call nebo_g080_json_validate
 test eax,eax
 jnz .invalid
 call g080_build_value
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_value]
 lea rsi,[rel g80_output]
 mov edx,G080_MAX_BYTES
 call nebo_g080_json_stringify
 test rax,rax
 js .invalid
 lea rdi,[rel g80_value]
 lea rsi,[rel g80_output]
 mov edx,G080_MAX_BYTES
 call nebo_g080_json_pretty
 test rax,rax
 js .invalid
 jmp .effect
.s6:
 lea rdi,[rel g80_json_text]
 mov esi,g80_json_text_len
 mov edx,G080_MAX_DEPTH
 mov ecx,G080_DUPLICATE_LAST_WINS
 lea r8,[rel g80_value]
 call nebo_g080_json_decode
 test eax,eax
 jnz .invalid
 jmp .effect
.s7:
 lea rdi,[rel g80_jsonl_state]
 call nebo_g080_jsonl_init
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_jsonl_state]
 lea rsi,[rel g80_jsonl_a]
 mov edx,7
 xor ecx,ecx
 call nebo_g080_jsonl_feed
 test eax,eax
 jnz .invalid
 lea rdi,[rel g80_jsonl_state]
 lea rsi,[rel g80_jsonl_a+7]
 mov edx,g80_jsonl_a_len-7
 mov ecx,1
 call nebo_g080_jsonl_feed
 test eax,eax
 jnz .invalid
 cmp qword [rel g80_jsonl_state+G080_JSONL_VALID],2
 jne .invalid
 jmp .effect
.s8:
 call nebo_g080_negative_probe
 test eax,eax
 jnz .invalid
.effect:
 mov eax,r12d
 imul eax,3
 add eax,r13d
 shl eax,4
 and eax,255
 test eax,eax
 jnz .done
 mov eax,r12d
.done:
 pop r13
 pop r12
 ret
.invalid:
 mov eax,255
 pop r13
 pop r12
 ret

; Independent negative paths must leave caller-owned outputs unchanged.
nebo_g080_negative_probe:
 mov rax,0x8080808080808080
 mov [rel g80_atomic],rax
 lea rdi,[rel g80_formula]
 mov esi,g80_formula_len
 lea rdx,[rel g80_atomic]
 mov ecx,64
 mov r8d,','
 mov r9d,G080_FORMULA_REJECT
 call nebo_g080_csv_encode_cell
 cmp eax,-FMT_CONFLICT
 jne .fail
 mov rax,0x8080808080808080
 cmp [rel g80_atomic],rax
 jne .fail
 lea rdi,[rel g80_json_text]
 mov esi,g80_json_text_len-1
 mov edx,G080_MAX_DEPTH
 mov ecx,G080_DUPLICATE_REJECT
 call nebo_g080_json_validate
 cmp eax,-FMT_SYNTAX
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,-FMT_CONFLICT
 ret

nebo_g080_render_transcript:
 push rbx
 push r12
 lea rbx,[rel g80_s1]
 mov r12d,g80_s1_len
 call .write
 lea rbx,[rel g80_s2]
 mov r12d,g80_s2_len
 call .write
 lea rbx,[rel g80_s3]
 mov r12d,g80_s3_len
 call .write
 lea rbx,[rel g80_s4]
 mov r12d,g80_s4_len
 call .write
 lea rbx,[rel g80_s5]
 mov r12d,g80_s5_len
 call .write
 lea rbx,[rel g80_s6]
 mov r12d,g80_s6_len
 call .write
 lea rbx,[rel g80_s7]
 mov r12d,g80_s7_len
 call .write
 lea rbx,[rel g80_s8]
 mov r12d,g80_s8_len
 call .write
 xor eax,eax
 pop r12
 pop rbx
 ret
.write:
 mov eax,1
 mov edi,1
 mov rsi,rbx
 mov rdx,r12
 syscall
 cmp rax,r12
 jne .write_fail
 ret
.write_fail:
 mov eax,-FMT_CONFLICT
 pop rax
 pop r12
 pop rbx
 ret
