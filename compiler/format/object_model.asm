; OBJECT-MODEL-F04 bounded format-neutral ObjectModel with deterministic ELF64 image facts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_registry.inc"
%include "compiler/format/object_model.inc"

section .text
object_validate_model:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_OBJECT_FORMAT_OFFSET],NEBOC_FORMAT_ELF64
 jne .unsupported
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_model_new
 ; rdi=model rsi=target descriptor.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_TARGET_TRIPLE_OFFSET],1
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_OBJECT_OFFSET],NEBOC_FORMAT_ELF64
 jne .unsupported
 mov [rdi+NEBOC_OBJECT_TARGET_OFFSET],rsi
 mov qword [rdi+NEBOC_OBJECT_FORMAT_OFFSET],NEBOC_FORMAT_ELF64
 mov qword [rdi+NEBOC_OBJECT_SECTIONS_OFFSET],0
 mov qword [rdi+NEBOC_OBJECT_SYMBOLS_OFFSET],0
 mov qword [rdi+NEBOC_OBJECT_RELOCS_OFFSET],0
 mov rax,neboc_object_model_OBJECT_MAGIC
 mov [rdi+NEBOC_OBJECT_DIGEST_OFFSET],rax
 mov qword [rdi+NEBOC_OBJECT_MAX_SECTION_SIZE_OFFSET],0
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_writer_for_format
 ; rdi=writer rsi=model rdx=format.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBOC_FORMAT_ELF64
 jne .unsupported
 push rdi
 mov rdi,rsi
 call object_validate_model
 pop rdi
 test eax,eax
 jne .return
 mov [rdi+NEBOC_WRITER_MODEL_OFFSET],rsi
 mov [rdi+NEBOC_WRITER_FORMAT_OFFSET],rdx
 mov qword [rdi+NEBOC_WRITER_SEGMENTS_OFFSET],0
 xor eax,eax
.return:
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_writer_add_section
 ; rdi=writer rsi=section{name,flags,alignment,size}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WRITER_MODEL_OFFSET]
 test r8,r8
 jz .invalid
 mov rax,[r8+NEBOC_OBJECT_SECTIONS_OFFSET]
 cmp rax,NEBOC_OBJECT_MAX_SECTIONS
 jae .limit
 mov rcx,[rsi+16]
 test rcx,rcx
 jz .source
 mov rdx,rcx
 dec rdx
 test rcx,rdx
 jnz .source
 cmp rcx,4096
 ja .limit
 mov rdx,[rsi+24]
 cmp rdx,0x7fffffff
 ja .limit
 inc qword [r8+NEBOC_OBJECT_SECTIONS_OFFSET]
 cmp rdx,[r8+NEBOC_OBJECT_MAX_SECTION_SIZE_OFFSET]
 jbe .digest
 mov [r8+NEBOC_OBJECT_MAX_SECTION_SIZE_OFFSET],rdx
.digest:
 mov rax,[rsi]
 xor rax,[rsi+8]
 xor rax,rcx
 xor rax,rdx
 rol rax,13
 xor [r8+NEBOC_OBJECT_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_writer_add_symbol
 ; rsi=symbol{name,scope,type,value,section_index}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi]
 test r8,r8
 jz .invalid
 cmp qword [r8+NEBOC_OBJECT_SYMBOLS_OFFSET],NEBOC_OBJECT_MAX_SYMBOLS
 jae .limit
 mov rax,[rsi+32]
 cmp rax,[r8+NEBOC_OBJECT_SECTIONS_OFFSET]
 jae .source
 inc qword [r8+NEBOC_OBJECT_SYMBOLS_OFFSET]
 mov rax,[rsi]
 xor rax,[rsi+24]
 rol rax,17
 xor [r8+NEBOC_OBJECT_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_writer_add_relocation
 ; rsi=relocation{kind,offset,section_index,symbol_index}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi]
 test r8,r8
 jz .invalid
 cmp qword [r8+NEBOC_OBJECT_RELOCS_OFFSET],NEBOC_OBJECT_MAX_RELOCS
 jae .limit
 mov rax,[rsi]
 test rax,rax
 jz .source
 cmp rax,2
 ja .source
 mov rax,[rsi+16]
 cmp rax,[r8+NEBOC_OBJECT_SECTIONS_OFFSET]
 jae .source
 mov rax,[rsi+24]
 cmp rax,[r8+NEBOC_OBJECT_SYMBOLS_OFFSET]
 jae .source
 inc qword [r8+NEBOC_OBJECT_RELOCS_OFFSET]
 mov rax,[rsi]
 xor rax,[rsi+8]
 rol rax,23
 xor [r8+NEBOC_OBJECT_DIGEST_OFFSET],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_writer_emit
 ; Bounded failure-atomic memory image: rsi=buffer rdx=capacity rcx=written.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 cmp rdx,NEBOC_OBJECT_IMAGE_SIZE
 jb .limit
 mov r8,[rdi]
 test r8,r8
 jz .invalid
 mov rax,neboc_object_model_OBJECT_MAGIC
 mov [rsi],rax
 mov rax,[r8+NEBOC_OBJECT_FORMAT_OFFSET]
 mov [rsi+8],rax
 mov rax,[r8+NEBOC_OBJECT_SECTIONS_OFFSET]
 mov [rsi+16],rax
 mov rax,[r8+NEBOC_OBJECT_SYMBOLS_OFFSET]
 mov [rsi+24],rax
 mov rax,[r8+NEBOC_OBJECT_RELOCS_OFFSET]
 mov [rsi+32],rax
 mov rax,[r8+NEBOC_OBJECT_DIGEST_OFFSET]
 mov [rsi+40],rax
 mov rax,[r8+NEBOC_OBJECT_MAX_SECTION_SIZE_OFFSET]
 mov [rsi+48],rax
 mov qword [rsi+56],1
 mov qword [rcx],NEBOC_OBJECT_IMAGE_SIZE
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_executable_writer_for_target
 ; Same writer shell; only x86_64 ELF64 descriptor is accepted.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_TARGET_TRIPLE_OFFSET],1
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_EXECUTABLE_OFFSET],NEBOC_FORMAT_ELF64
 jne .unsupported
 mov [rdi+NEBOC_WRITER_MODEL_OFFSET],rsi
 mov qword [rdi+NEBOC_WRITER_FORMAT_OFFSET],NEBOC_FORMAT_ELF64
 mov qword [rdi+NEBOC_WRITER_SEGMENTS_OFFSET],0
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_executable_writer_add_segment
 ; rsi=segment{flags,alignment,file_size,memory_size}. Reject RWX and truncation.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_WRITER_SEGMENTS_OFFSET],16
 jae .limit
 mov rax,[rsi]
 and rax,7
 cmp rax,7
 je .source
 mov rcx,[rsi+8]
 test rcx,rcx
 jz .source
 mov rax,rcx
 dec rax
 test rax,rcx
 jnz .source
 cmp rcx,0x200000
 ja .limit
 mov rax,[rsi+16]
 cmp rax,[rsi+24]
 ja .source
 inc qword [rdi+NEBOC_WRITER_SEGMENTS_OFFSET]
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_inspector_open
 ; rdi=inspector rsi=image rdx=size.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBOC_OBJECT_IMAGE_SIZE
 jb .source
 mov rax,neboc_object_model_OBJECT_MAGIC
 cmp [rsi],rax
 jne .source
 mov [rdi+NEBOC_INSPECTOR_IMAGE_OFFSET],rsi
 mov [rdi+NEBOC_INSPECTOR_SIZE_OFFSET],rdx
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_inspector_validate
 test rdi,rdi
 jz .invalid
 mov rsi,[rdi]
 test rsi,rsi
 jz .invalid
 mov rax,neboc_object_model_OBJECT_MAGIC
 cmp [rsi],rax
 jne .source
 cmp qword [rsi+8],NEBOC_FORMAT_ELF64
 jne .source
 cmp qword [rsi+16],NEBOC_OBJECT_MAX_SECTIONS
 ja .source
 cmp qword [rsi+24],NEBOC_OBJECT_MAX_SYMBOLS
 ja .source
 cmp qword [rsi+32],NEBOC_OBJECT_MAX_RELOCS
 ja .source
 cmp qword [rsi+56],1
 jne .source
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_object_inspector_normalized_digest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rdx,[rdi]
 test rdx,rdx
 jz .invalid
 mov rax,[rdx+8]
 rol rax,7
 xor rax,[rdx+16]
 rol rax,11
 xor rax,[rdx+24]
 rol rax,13
 xor rax,[rdx+32]
 rol rax,17
 xor rax,[rdx+40]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_object_report
 ; rdi=inspector rsi=out{format,sections,symbols,relocs,digest,size}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rsi
 call neboc_object_inspector_validate
 pop rsi
 test eax,eax
 jne .return
 mov rdx,[rdi]
 mov rax,[rdx+8]
 mov [rsi],rax
 mov rax,[rdx+16]
 mov [rsi+8],rax
 mov rax,[rdx+24]
 mov [rsi+16],rax
 mov rax,[rdx+32]
 mov [rsi+24],rax
 mov rax,[rdx+40]
 mov [rsi+32],rax
 mov rax,[rdi+8]
 mov [rsi+40],rax
 xor eax,eax
.return:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
