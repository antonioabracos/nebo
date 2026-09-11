; Source values reach canonical RenderModel owners before bounded headless
; presentation. All text is rendered from authenticated live cells/nodes.
bits 64
default rel
%include "runtime/render_model.inc"
%include "compiler/semantic/data/data_contract.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_table_validate
extern neboc_column_get
extern neboc_tree_validate
extern neboc_tree_preorder
extern neboc_tree_height
extern neboc_tree_get
extern neboc_tree_validate_handle
extern neboc_format_int_to_base
extern nebo_render_tabular
extern nebo_render_dynamic
extern nebo_render_collection
extern neboc_text_builder_init
extern neboc_text_builder_append_char
extern nebo_runtime_console_publish_text
extern nebo_runtime_trap
global nebo_runtime_console_publish_structured
global nebo_runtime_console_view_count
global nebo_runtime_console_view_records
section .rodata
view_table: db 'Table['
view_tree: db 'Tree',10
view_separator: db ' | '
view_close: db ']',10
view_missing: db 'null'
view_true: db 'true'
view_false: db 'false'
view_field_separator: db ', '
view_field_colon: db ': '
section .bss align=16
nebo_runtime_console_view_count: resq 1
; Pointer-free semantic snapshots, in successful publication order.
nebo_runtime_console_view_records: resq 64*4
section .text
; rdi=typed native value; esi=canonical RenderModel type (15 Table,21 Tree).
; Return the ordinary stable Console handle after exactly one publication.
nebo_runtime_console_publish_structured:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,4528
 mov r12,rdi
 mov ebx,esi
 mov [rsp+104],rdx
 mov [rsp+112],rcx
 lea r13,[rsp+432]             ; private bounded UTF-8 output,4096 bytes
 xor r14d,r14d                 ; output byte count
 cmp qword [rel nebo_runtime_console_view_count],64
 jae .trap
 cmp ebx,NEBO_TYPE_TABLE
 je .table
 cmp ebx,NEBO_TYPE_OBJECT
 je .object
 cmp ebx,NEBO_TYPE_TREE
 jne .trap
.tree:
 call neboc_tree_validate
 test eax,eax
 jnz .trap
 mov rdi,r12
 lea rsi,[rsp+104]
 call neboc_tree_height
 test eax,eax
 jnz .trap
 mov rdi,r12
 lea rsi,[rsp+176]
 lea rdx,[rsp+112]
 call neboc_tree_preorder
 test eax,eax
 jnz .trap
 mov [rsp],r12
 mov qword [rsp+8],NEBO_TYPE_TREE
 mov rax,[rsp+112]
 mov [rsp+16],rax
 mov rax,[rsp+104]
 mov [rsp+24],rax
 mov qword [rsp+32],0
 mov qword [rsp+40],0
 mov rdi,rsp
 lea rsi,[rsp+48]
 call nebo_render_dynamic
 test eax,eax
 jnz .trap
 lea rsi,[rel view_tree]
 mov edx,5
 call view_append
 xor r15d,r15d
.tree_node:
 cmp r15,[rsp+112]
 jae .publish
 mov rsi,[rsp+r15*8+176]
 mov [rsp+120],rsi
 mov qword [rsp+128],0
 ; Follow authenticated native parent handles to determine indentation.
.tree_parent:
 mov rdi,r12
 mov rsi,[rsp+120]
 call neboc_tree_validate_handle
 test eax,eax
 jnz .trap
 mov eax,dword [rsp+120]
 mov rdx,[r12+NEBO_TREE_PARENTS]
 mov rax,[rdx+rax*8]
 cmp rax,NEBO_INVALID_HANDLE
 je .tree_indent
 mov [rsp+120],rax
 inc qword [rsp+128]
 cmp qword [rsp+128],NEBO_MAX_RENDER_DEPTH
 jae .trap
 jmp .tree_parent
.tree_indent:
 mov rax,[rsp+128]
 shl rax,1
 mov [rsp+136],rax
.space:
 cmp qword [rsp+136],0
 je .tree_value
 mov al,' '
 call view_char
 dec qword [rsp+136]
 jmp .space
.tree_value:
 mov rdi,r12
 mov rsi,[rsp+r15*8+176]
 lea rdx,[rsp+120]
 call neboc_tree_get
 test eax,eax
 jnz .trap
 mov rdi,[rsp+120]
 call view_int
 mov al,10
 call view_char
 inc r15
 jmp .tree_node
.object:
 mov rdx,[rsp+112]
 test rdx,rdx
 jz .trap
 mov rax,[rsp+104]
 cmp rax,[rdx]
 jae .trap
 mov rax,[rdx+rax*8+8]
 mov qword [rsp],NEBO_TYPE_OBJECT
 mov [rsp+8],r12
 mov rcx,[rax+8]
 mov [rsp+16],rcx
 mov qword [rsp+24],0
 mov rdi,rsp
 lea rsi,[rsp+48]
 call nebo_render_collection
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,[rsp+104]
 mov rdx,[rsp+112]
 xor ecx,ecx
 call view_object
 mov al,10
 call view_char
 jmp .publish
.table:
 call neboc_table_validate
 test eax,eax
 jnz .trap
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov [rsp],rax
 mov qword [rsp+8],NEBO_TYPE_TABLE
 mov rax,[r12+NEBO_TABLE_ROW_COUNT]
 mov [rsp+16],rax
 mov rax,[r12+NEBO_TABLE_COLUMN_COUNT]
 mov [rsp+24],rax
 mov rax,[r12+NEBO_TABLE_SCHEMA]
 mov [rsp+32],rax
 mov qword [rsp+40],0
 mov rdi,rsp
 lea rsi,[rsp+48]
 call nebo_render_tabular
 test eax,eax
 jnz .trap
 lea rsi,[rel view_table]
 mov edx,6
 call view_append
 xor r15d,r15d
.header:
 cmp r15,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .header_done
 test r15,r15
 jz .name
 lea rsi,[rel view_separator]
 mov edx,3
 call view_append
.name:
 mov rax,[r12+NEBO_TABLE_SCHEMA]
 mov rdx,r15
 shl rdx,5
 lea rax,[rax+rdx+256]         ; public schema's retained Text descriptors
 mov rsi,[rax]
 mov rdx,[rax+8]
 cmp rdx,128
 ja .trap
 call view_append
 inc r15
 jmp .header
.header_done:
 lea rsi,[rel view_close]
 mov edx,2
 call view_append
 mov qword [rsp+104],0
.row:
 mov rax,[rsp+104]
 cmp rax,[r12+NEBO_TABLE_ROW_COUNT]
 jae .publish
 xor r15d,r15d
.column:
 cmp r15,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .row_done
 test r15,r15
 jz .cell
 lea rsi,[rel view_separator]
 mov edx,3
 call view_append
.cell:
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov rdi,[rax+r15*8]
 cmp qword [rdi+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .trap
 mov rsi,[rsp+104]
 lea rdx,[rsp+120]
 lea rcx,[rsp+128]
 call neboc_column_get
 test eax,eax
 jnz .trap
 cmp qword [rsp+128],0
 je .missing
 mov rdi,[rsp+120]
 call view_int
 jmp .next_column
.missing:
 lea rsi,[rel view_missing]
 mov edx,4
 call view_append
.next_column:
 inc r15
 jmp .column
.row_done:
 mov al,10
 call view_char
 inc qword [rsp+104]
 jmp .row
.publish:
 ; No document mutation has occurred before every shape/value is checked.
 mov [rsp+144],r13
 mov [rsp+152],r14
 mov dword [rsp+160],5
 mov word [rsp+164],1
 mov word [rsp+166],0
 mov qword [rsp+168],0
 lea rdi,[rsp+144]
 call nebo_runtime_console_publish_text
 mov rdx,[rel nebo_runtime_console_view_count]
 shl rdx,5
 lea rcx,[rel nebo_runtime_console_view_records]
 add rcx,rdx
 mov rdx,[rsp+48+NEBO_NODE_KIND_OFFSET]
 mov [rcx],rdx
 mov rdx,[rsp+48+NEBO_NODE_TYPE_OFFSET]
 mov [rcx+8],rdx
 mov rdx,[rsp+48+NEBO_NODE_COUNT_OFFSET]
 mov [rcx+16],rdx
 mov rdx,[rsp+48+NEBO_NODE_AUX_OFFSET]
 mov [rcx+24],rdx
 inc qword [rel nebo_runtime_console_view_count]
 add rsp,4528
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,46
 jmp nebo_runtime_trap
; Helpers preserve the live value, iterator and accumulated output length.
view_append:
 mov rax,r14
 add rax,rdx
 jc nebo_runtime_console_publish_structured.trap
 cmp rax,4096
 ja nebo_runtime_console_publish_structured.trap
 test rdx,rdx
 jz .done
 test rsi,rsi
 jz nebo_runtime_console_publish_structured.trap
 lea rdi,[r13+r14]
 mov rcx,rdx
 rep movsb
 mov r14,rax
.done:
 ret
view_char:
 cmp r14,4096
 jae nebo_runtime_console_publish_structured.trap
 mov [r13+r14],al
 inc r14
 ret
view_int:
 mov esi,10
 xor edx,edx
 lea rcx,[r13+r14]
 mov r8d,4096
 sub r8,r14
 call neboc_format_int_to_base
 test rax,rax
 js nebo_runtime_console_publish_structured.trap
 add r14,rax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits

section .text
; Internal recursive presentation, preserving the cumulative output owner in
; R13/R14. Native field metadata supplies exact offsets, widths and names.
view_object:
 push rbx
 push r12
 push r15
 sub rsp,80
 mov rbx,rdi
 mov [rsp],rdx
 mov [rsp+8],rcx
 cmp ecx,NEBO_MAX_RENDER_DEPTH
 jae .trap
 test rbx,rbx
 jz .trap
 cmp qword [rdx],8
 ja .trap
 cmp rsi,[rdx]
 jae .trap
 mov r12,[rdx+rsi*8+8]
 cmp qword [r12+8],8
 ja .trap
 mov rax,[r12+16]
 mov rsi,[rax]
 mov rdx,[rax+8]
 call view_append
 mov al,'{'
 call view_char
 xor r15d,r15d
.field:
 cmp r15,[r12+8]
 jae .finish
 test r15,r15
 jz .name
 lea rsi,[rel view_field_separator]
 mov edx,2
 call view_append
.name:
 imul rax,r15,24
 lea rax,[r12+rax+24]
 mov rdx,[rax+16]
 cmp rdx,[r12]
 ja .trap
 lea rcx,[rbx+rdx]
 mov [rsp+16],rcx
 mov rcx,[rax+8]
 mov [rsp+24],rcx
 mov rsi,[r12]
 sub rsi,rdx
 mov edx,8
 cmp ecx,1
 je .width
 mov edx,1
 cmp ecx,2
 je .width
 mov edx,4
 cmp ecx,3
 je .width
 mov edx,16
 cmp ecx,4
 je .width
 sub rcx,256
 mov rdx,[rsp]
 cmp rcx,[rdx]
 jae .trap
 mov rdx,[rdx+rcx*8+8]
 mov rdx,[rdx]
.width:
 cmp rsi,rdx
 jb .trap
 mov rax,[rax]
 mov rsi,[rax]
 mov rdx,[rax+8]
 call view_append
 lea rsi,[rel view_field_colon]
 mov edx,2
 call view_append
 mov rax,[rsp+16]
 mov rcx,[rsp+24]
 cmp ecx,1
 je .int
 cmp ecx,2
 je .bool
 cmp ecx,3
 je .char
 cmp ecx,4
 je .text
 mov rdi,rax
 lea rsi,[rcx-256]
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 inc rcx
 call view_object
 jmp .next
.int:
 mov rdi,[rax]
 call view_int
 jmp .next
.bool:
 cmp byte [rax],1
 ja .trap
 lea rsi,[rel view_false]
 mov edx,5
 cmp byte [rax],0
 je .bool_ready
 lea rsi,[rel view_true]
 mov edx,4
.bool_ready:
 call view_append
 jmp .next
.char:
 mov eax,[rax]
 mov [rsp+24],rax
 lea rdi,[rsp+32]
 lea rsi,[rsp+64]
 mov edx,4
 call neboc_text_builder_init
 test eax,eax
 jnz .trap
 lea rdi,[rsp+32]
 mov esi,[rsp+24]
 call neboc_text_builder_append_char
 test eax,eax
 jnz .trap
 lea rsi,[rsp+64]
 mov rdx,[rsp+40]
 call view_append
 jmp .next
.text:
 mov rsi,[rax]
 mov rdx,[rax+8]
 call view_append
.next:
 inc r15
 jmp .field
.finish:
 mov al,'}'
 call view_char
 add rsp,80
 pop r15
 pop r12
 pop rbx
 ret
.trap:
 mov edi,46
 jmp nebo_runtime_trap
