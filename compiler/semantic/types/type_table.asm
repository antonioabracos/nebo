; Nebo Assembly — MF022 deterministic fundamental TypeTable
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"

section .text

; type_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_type_table_init
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 cmp rdx,NEBOC_TYPE_BUILTIN_COUNT
 jb .init_invalid
 mov [rdi+NEBOC_TYPE_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_TYPE_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 mov qword [rdi+NEBOC_TYPE_TABLE_HASH_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.init_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; type_table_declare_builtins(table*)
NEBOC_ABI_FUNCTION neboc_type_table_declare_builtins
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .builtins_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .builtins_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_BUILTIN_COUNT
 jb .builtins_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .builtins_invalid
 ; Void
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_VOID
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_VOID
 ; Bool
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BOOL
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_BOOL
 ; Int
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_INT
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_INT
 ; Text
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_TEXT
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_TEXT
 ; Console
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_CONSOLE
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_CONSOLE
 ; Pending<Text>
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_PENDING
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_TEXT
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC | NEBOC_TYPE_FLAG_PENDING
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUILTIN_COUNT
 xor eax,eax
 jmp .builtins_done
.builtins_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .builtins_done
.builtins_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.builtins_done:
 pop r12
 pop rbx
 cld
 ret


; type_table_declare_intrinsic_types(table*)
; Appends Color and Behavior<ForegroundColor> after the six MF022 built-ins.
NEBOC_ABI_FUNCTION neboc_type_table_declare_intrinsic_types
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .intrinsic_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .intrinsic_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUILTIN_COUNT
 jne .intrinsic_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_MAX_COUNT
 jb .intrinsic_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .intrinsic_invalid
 add rbx,NEBOC_TYPE_BUILTIN_COUNT * NEBOC_TYPE_ENTRY_SIZE
 ; Color palette value type.
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_COLOR
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC | NEBOC_TYPE_FLAG_INTRINSIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_COLOR
 ; Behavior<ForegroundColor> descriptor type.
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BEHAVIOR
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_COLOR
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC | NEBOC_TYPE_FLAG_BEHAVIOR | NEBOC_TYPE_FLAG_INTRINSIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_BEHAVIOR_FOREGROUND_COLOR
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_MAX_COUNT
 xor eax,eax
 jmp .intrinsic_done
.intrinsic_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .intrinsic_done
.intrinsic_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.intrinsic_done:
 pop r12
 pop rbx
 cld
 ret


; type_table_declare_foundation_float(table*)
; TIPOS-PRIMITIVOS-ESCALARES-PF005 appends the first v0.2 public scalar after the eight frozen entries.
NEBOC_ABI_FUNCTION neboc_type_table_declare_foundation_float
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .float_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .float_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_MAX_COUNT
 jne .float_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_V02_MAX_COUNT
 jb .float_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .float_invalid
 add rbx,NEBOC_TYPE_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_FLOAT
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_V02_MAX_COUNT
 xor eax,eax
 jmp .float_done
.float_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .float_done
.float_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.float_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_declare_text_char_bytes(table*)
; TEXT-CHAR-UNICODE-E-BYTES-PF005 appends Char and Bytes after the nine preserved entries.
NEBOC_ABI_FUNCTION neboc_type_table_declare_text_char_bytes
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .textual_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .textual_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_V02_MAX_COUNT
 jne .textual_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT
 jb .textual_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .textual_invalid
 add rbx,NEBOC_TYPE_V02_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_CHAR
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_CHAR
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BYTES
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_BYTES
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT
 xor eax,eax
 jmp .textual_done
.textual_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .textual_done
.textual_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.textual_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_declare_rf27_buffer(table*)
; TIPOS-PRIMITIVOS-ESCALARES-F08 appends Buffer after the frozen textual catalogue.  This is a
; semantic compound identity; its 16-byte layout lives in the Buffer vertical.
NEBOC_ABI_FUNCTION neboc_type_table_declare_buffer
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .buffer_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .buffer_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT
 jne .buffer_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_BUFFER_MAX_COUNT
 jb .buffer_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .buffer_invalid
 add rbx,NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BUFFER
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_BUFFER
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUFFER_MAX_COUNT
 xor eax,eax
 jmp .buffer_done
.buffer_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .buffer_done
.buffer_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.buffer_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_declare_rf27_slice(table*)
; F11 publishes the existing 40/8 lexical Slice shape as TypeId 13.
NEBOC_ABI_FUNCTION neboc_type_table_declare_slice
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .slice_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .slice_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUFFER_MAX_COUNT
 jne .slice_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_SLICE_MAX_COUNT
 jb .slice_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .slice_invalid
 add rbx,NEBOC_TYPE_BUFFER_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_SLICE
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_SLICE
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_SLICE_MAX_COUNT
 xor eax,eax
 jmp .slice_done
.slice_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .slice_done
.slice_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.slice_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_declare_ordering(table*) appends P02's closed Ordering scalar.
NEBOC_ABI_FUNCTION neboc_type_table_declare_ordering
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .ordering_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .ordering_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_SLICE_MAX_COUNT
 jne .ordering_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_P02_MAX_COUNT
 jb .ordering_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .ordering_invalid
 add rbx,NEBOC_TYPE_SLICE_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_ORDERING
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_FUNDAMENTAL
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_ORDERING
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_P02_MAX_COUNT
 xor eax,eax
 jmp .ordering_done
.ordering_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .ordering_done
.ordering_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.ordering_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_declare_typed_quantities(table*) appends G129's five exact
; semantic identities after Ordering.  This optional declaration keeps every
; earlier frozen TypeTable profile byte-stable.
NEBOC_ABI_FUNCTION neboc_type_table_declare_typed_quantities
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .quantities_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .quantities_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_P02_MAX_COUNT
 jne .quantities_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_CAPACITY_OFFSET],NEBOC_TYPE_QUANTITY_MAX_COUNT
 jb .quantities_limit
 mov rbx,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 test rbx,rbx
 jz .quantities_invalid
 add rbx,NEBOC_TYPE_P02_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_PERCENT
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_PERCENT
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_PER_MILLE
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_PER_MILLE
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BASIS_POINTS
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_BASIS_POINTS
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_ANGLE
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_ANGLE
 add rbx,NEBOC_TYPE_ENTRY_SIZE
 mov qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_TEMPERATURE
 mov qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],0
 mov qword [rbx+NEBOC_TYPE_ENTRY_FLAGS_OFFSET],NEBOC_TYPE_FLAG_SEMANTIC
 mov qword [rbx+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_TEMPERATURE
 mov qword [r12+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_QUANTITY_MAX_COUNT
 xor eax,eax
 jmp .quantities_done
.quantities_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .quantities_done
.quantities_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.quantities_done:
 pop r12
 pop rbx
 cld
 ret

; type_table_get(table*, type_id, out_entry_ptr*)
NEBOC_ABI_FUNCTION neboc_type_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_TYPE_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_TYPE_ENTRY_SIZE
 add rax,[rdi+NEBOC_TYPE_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; type_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_type_table_freeze
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .freeze_invalid
 cmp qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov r9,[r12+NEBOC_TYPE_TABLE_COUNT_OFFSET]
 cmp r9,NEBOC_TYPE_BUILTIN_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_V02_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_BUFFER_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_SLICE_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_P02_MAX_COUNT
 je .freeze_count_ok
 cmp r9,NEBOC_TYPE_QUANTITY_MAX_COUNT
 jne .freeze_invalid
.freeze_count_ok:
 mov rbx,NEBOC_TYPE_HASH_FNV1A32_OFFSET_BASIS
 xor r8d,r8d
.freeze_loop:
 cmp r8,r9
 jae .freeze_done_hash
 mov rax,r8
 imul rax,NEBOC_TYPE_ENTRY_SIZE
 add rax,[r12+NEBOC_TYPE_TABLE_DATA_OFFSET]
 xor ecx,ecx
.freeze_qword_loop:
 cmp ecx,NEBOC_TYPE_ENTRY_QWORDS
 jae .freeze_next
 mov rdx,[rax+rcx*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 shr rdx,32
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 inc ecx
 jmp .freeze_qword_loop
.freeze_next:
 inc r8
 jmp .freeze_loop
.freeze_done_hash:
 mov [r12+NEBOC_TYPE_TABLE_HASH_OFFSET],rbx
 mov qword [r12+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_FROZEN
 xor eax,eax
 jmp .freeze_done
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.freeze_done:
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
