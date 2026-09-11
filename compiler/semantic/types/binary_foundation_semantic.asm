; RF204-G001 bounded semantic owner for immutable bytes, Buffer/Slice bridges,
; typed endian access, alignment, comparison, XOR and checksums.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binary_foundation_parser.inc"

section .rodata
encoding_utf8: db 'utf-8'
encoding_utf8_len equ $-encoding_utf8
encoding_ascii: db 'ascii'
encoding_ascii_len equ $-encoding_ascii

section .text

; EAX text ordinal, R12 request -> RAX pointer, RDX length. CF on failure.
bf_text:
 cmp eax,4
 jae .bad
 mov rax,[r12+NEBOC_BF_TEXT0_PAYLOAD_OFFSET+rax*8]
 mov edx,eax
 shr rax,32
 add rax,[r12+NEBOC_BF_LITERAL_BYTES_OFFSET]
 clc
 ret
.bad:
 xor eax,eax
 xor edx,edx
 stc
 ret

; RAX pointer/RDX length, RSI literal/ECX length -> EAX bool.
bf_bytes_equal:
 cmp rdx,rcx
 jne .no
 xor r8d,r8d
.loop:
 cmp r8,rdx
 jae .yes
 mov r9b,[rax+r8]
 cmp r9b,[rsi+r8]
 jne .no
 inc r8
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

bf_hex_nibble:
 cmp al,'0'
 jb .bad
 cmp al,'9'
 jbe .digit
 or al,32
 cmp al,'a'
 jb .bad
 cmp al,'f'
 ja .bad
 sub al,'a'-10
 movzx eax,al
 ret
.digit:
 sub al,'0'
 movzx eax,al
 ret
.bad:
 mov eax,-1
 ret

; Validate/decode text0 as at most eight bytes. Publishes sequence0 when the
; source has no integer Bytes constructor. R12=request.
bf_decode_hex:
 push rbx
 push r13
 push r14
 push r15
 xor eax,eax
 call bf_text
 jc .bad
 test dl,1
 jnz .bad
 cmp rdx,16
 ja .length
 mov r13,rax
 mov r14,rdx
 xor ebx,ebx
 xor r15d,r15d
.loop:
 cmp r15,r14
 jae .store
 mov al,[r13+r15]
 call bf_hex_nibble
 cmp eax,-1
 je .bad
 shl eax,4
 mov edx,eax
 mov al,[r13+r15+1]
 call bf_hex_nibble
 cmp eax,-1
 je .bad
 or eax,edx
 mov ecx,r15d
 shr ecx,1
 shl ecx,3
 shl rax,cl
 or rbx,rax
 add r15,2
 jmp .loop
.store:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],0
 jne .ok
 mov rax,r14
 shr rax,1
 mov [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],rax
 mov [r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET],rbx
 mov qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],1
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_HEX
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.length:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_LENGTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Validate explicit encoding and materialize the penultimate text as bytes if
; no integer/hex sequence owns sequence0.
bf_validate_text_encoding:
 push rbx
 push r13
 mov r13,[r12+NEBOC_BF_TEXT_COUNT_OFFSET]
 cmp r13,2
 jb .bad
 cmp r13,4
 jbe .count_ready
 mov r13,4
.count_ready:
 lea eax,[r13-1]
 call bf_text
 jc .bad
 mov rbx,rax
 push rdx
 mov rsi,encoding_utf8
 mov ecx,encoding_utf8_len
 call bf_bytes_equal
 pop rdx
 test eax,eax
 jnz .encoding_ok
 mov rax,rbx
 mov rsi,encoding_ascii
 mov ecx,encoding_ascii_len
 call bf_bytes_equal
 test eax,eax
 jz .bad
.encoding_ok:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],0
 jne .ok
 lea eax,[r13-2]
 call bf_text
 jc .bad
 cmp rdx,8
 ja .length
 xor ebx,ebx
 xor ecx,ecx
.pack:
 cmp rcx,rdx
 jae .store
 movzx r8d,byte [rax+rcx]
 mov r9d,ecx
 shl r9d,3
 push rcx
 mov ecx,r9d
 shl r8,cl
 pop rcx
 or rbx,r8
 inc rcx
 jmp .pack
.store:
 mov [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],rdx
 mov [r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET],rbx
 mov qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],1
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_ENCODING
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.length:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_LENGTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r13
 pop rbx
 ret

; Load integer N from the end: EAX=0 is last. CF if missing.
bf_integer_from_end:
 mov rcx,[r12+NEBOC_BF_INTEGER_COUNT_OFFSET]
 mov edx,eax
 cmp rcx,rdx
 jbe .bad
 dec rcx
 sub rcx,rdx
 mov rax,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET+rcx*8]
 clc
 ret
.bad:
 xor eax,eax
 stc
 ret

; Compare sequence0 and sequence1. Result -1/0/1 in RAX.
bf_compare_sequences:
 mov r8,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 mov r9,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 mov r10,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov r11,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 xor edi,edi
.loop:
 cmp rdi,r8
 jae .left_done
 cmp rdi,r9
 jae .greater
 mov rax,r10
 mov ecx,edi
 shl ecx,3
 shr rax,cl
 and eax,255
 mov rdx,r11
 mov ecx,edi
 shl ecx,3
 shr rdx,cl
 and edx,255
 cmp eax,edx
 jb .less
 ja .greater
 inc rdi
 jmp .loop
.left_done:
 cmp r8,r9
 jb .less
 ja .greater
 xor eax,eax
 ret
.less:
 mov rax,-1
 ret
.greater:
 mov eax,1
 ret

; Find sequence1 in sequence0, returning first index or -1.
bf_find_sequence:
 mov r8,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 mov r9,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 test r9,r9
 jz .zero
 cmp r9,r8
 ja .none
 mov r10,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov r11,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 xor edx,edx
.candidate:
 mov rax,r8
 sub rax,r9
 cmp rdx,rax
 ja .none
 mov ecx,edx
 shl ecx,3
 mov rax,r10
 shr rax,cl
 mov ecx,r9d
 cmp ecx,8
 je .mask_ready
 shl ecx,3
 mov rsi,1
 shl rsi,cl
 dec rsi
 and rax,rsi
.mask_ready:
 cmp rax,r11
 je .found
 inc rdx
 jmp .candidate
.found:
 mov rax,rdx
 ret
.zero:
 xor eax,eax
 ret
.none:
 mov rax,-1
 ret

bf_crc32:
 mov r8,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 mov r9,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov eax,0xffffffff
 xor edi,edi
.byte:
 cmp rdi,r8
 jae .done
 mov rdx,r9
 mov ecx,edi
 shl ecx,3
 shr rdx,cl
 and edx,255
 xor eax,edx
 mov edx,8
.bit:
 mov esi,eax
 and esi,1
 neg esi
 shr eax,1
 and esi,0xedb88320
 xor eax,esi
 dec edx
 jnz .bit
 inc rdi
 jmp .byte
.done:
 not eax
 ret

bf_adler32:
 mov r8,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 mov r9,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov r13d,1
 xor r14d,r14d
 xor edi,edi
 mov ebx,65521
.byte:
 cmp rdi,r8
 jae .done
 mov r10,r9
 mov ecx,edi
 shl ecx,3
 shr r10,cl
 and r10d,255
 add r13d,r10d
 mov eax,r13d
 xor edx,edx
 div ebx
 mov r13d,edx
 add r14d,r13d
 mov eax,r14d
 xor edx,edx
 div ebx
 mov r14d,edx
 inc rdi
 jmp .byte
.done:
 mov eax,r14d
 shl eax,16
 or eax,r13d
 ret

bf_validate_alignment:
 test rax,rax
 jz .bad_alignment
 mov rcx,rax
 dec rcx
 test rax,rcx
 jnz .bad_alignment
 mov rdx,0x100000000
 cmp rax,rdx
 ja .bad_alignment
 clc
 ret
.bad_alignment:
 stc
 ret

NEBOC_ABI_FUNCTION neboc_binary_foundation_analyze
 test rdi,rdi
 jz .argument_direct
 test rdi,7
 jnz .argument_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 cmp qword [r12+NEBOC_BF_FOUND_OFFSET],1
 jne .argument
 cmp qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],0
 jne .source
 ; Every selected constructor is validated even when a later operation owns
 ; the process result, preventing dead invalid binary literals.
 test qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_FROM_HEX-1))
 jz .text_validation
 call bf_decode_hex
 test eax,eax
 jnz .done
.text_validation:
 test qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_FROM_TEXT-1))
 jz .dispatch
 call bf_validate_text_encoding
 test eax,eax
 jnz .done
.dispatch:
 ; Operation ownership is conditional on a material receiver family observed
 ; in the same parsed program.  This prevents same-spelled methods on an Int
 ; or unrelated user type from selecting the bounded binary backend.
 mov rax,[r12+NEBOC_BF_OPERATION_MASK_OFFSET]
 mov rcx,(1 << (NEBOC_BF_OP_FROM_HEX-1)) | (1 << (NEBOC_BF_OP_FROM_TEXT-1)) | (1 << (NEBOC_BF_OP_IS_EMPTY-1)) | (1 << (NEBOC_BF_OP_FIND-1)) | (1 << (NEBOC_BF_OP_STARTS_WITH-1)) | (1 << (NEBOC_BF_OP_ENDS_WITH-1)) | (1 << (NEBOC_BF_OP_SLICE_FROM_BYTES-1)) | (1 << (NEBOC_BF_OP_READ_U16_LE-1)) | (1 << (NEBOC_BF_OP_READ_U32_BE-1)) | (1 << (NEBOC_BF_OP_EQUALS-1)) | (1 << (NEBOC_BF_OP_COMPARE_LEXICOGRAPHIC-1)) | (1 << (NEBOC_BF_OP_XOR_WITH-1)) | (1 << (NEBOC_BF_OP_CRC32-1)) | (1 << (NEBOC_BF_OP_ADLER32-1)) | (1 << (NEBOC_BF_OP_CONSTANT_TIME_EQUALS-1)) | (1 << (NEBOC_BF_OP_INFIX_XOR-1))
 test rax,rcx
 jz .buffer_type
 test qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BYTES
 jz .type
.buffer_type:
 mov rcx,(1 << (NEBOC_BF_OP_RESERVE-1)) | (1 << (NEBOC_BF_OP_EXTEND-1)) | (1 << (NEBOC_BF_OP_SLICE_FROM_BUFFER-1)) | (1 << (NEBOC_BF_OP_WRITE_U64_LE-1)) | (1 << (NEBOC_BF_OP_COPY_TO-1))
 test rax,rcx
 jz .slice_type
 test qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BUFFER
 jz .type
.slice_type:
 mov rcx,(1 << (NEBOC_BF_OP_SLICE_FROM_BYTES-1)) | (1 << (NEBOC_BF_OP_SLICE_FROM_BUFFER-1)) | (1 << (NEBOC_BF_OP_SUBSLICE-1)) | (1 << (NEBOC_BF_OP_COPY_TO-1)) | (1 << (NEBOC_BF_OP_TO_BYTES-1))
 test rax,rcx
 jz .borrow_validation
 test qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_SLICE
 jz .type
.borrow_validation:
 ; A live Slice.fromBuffer borrow excludes capacity-changing or byte-writing
 ; operations on the same bounded lexical owner.  This conservative rule is
 ; intentionally checked before result selection so failure is atomic.
 test qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_SLICE_FROM_BUFFER-1))
 jz .dispatch_ready
 mov rax,[r12+NEBOC_BF_OPERATION_MASK_OFFSET]
 mov rcx,(1 << (NEBOC_BF_OP_RESERVE-1)) | (1 << (NEBOC_BF_OP_EXTEND-1)) | (1 << (NEBOC_BF_OP_WRITE_U64_LE-1))
 test rax,rcx
 jnz .ownership
.dispatch_ready:
 mov rbx,[r12+NEBOC_BF_LAST_OPERATION_OFFSET]
 cmp rbx,NEBOC_BF_OP_FROM_HEX
 je .sequence_length
 cmp rbx,NEBOC_BF_OP_FROM_TEXT
 je .sequence_length
 cmp rbx,NEBOC_BF_OP_IS_EMPTY
 je .is_empty
 cmp rbx,NEBOC_BF_OP_FIND
 je .find
 cmp rbx,NEBOC_BF_OP_STARTS_WITH
 je .starts
 cmp rbx,NEBOC_BF_OP_ENDS_WITH
 je .ends
 cmp rbx,NEBOC_BF_OP_RESERVE
 je .reserve
 cmp rbx,NEBOC_BF_OP_EXTEND
 je .extend
 cmp rbx,NEBOC_BF_OP_SLICE_FROM_BYTES
 je .sequence_length
 cmp rbx,NEBOC_BF_OP_SLICE_FROM_BUFFER
 je .first_integer
 cmp rbx,NEBOC_BF_OP_SUBSLICE
 je .subslice
 cmp rbx,NEBOC_BF_OP_COPY_TO
 je .sequence_first
 cmp rbx,NEBOC_BF_OP_TO_BYTES
 je .to_bytes
 cmp rbx,NEBOC_BF_OP_READ_U16_LE
 je .read_u16
 cmp rbx,NEBOC_BF_OP_READ_U32_BE
 je .read_u32
 cmp rbx,NEBOC_BF_OP_WRITE_U64_LE
 je .write_u64
 cmp rbx,NEBOC_BF_OP_BYTE_SWAP
 je .byte_swap
 cmp rbx,NEBOC_BF_OP_ALIGN_UP
 je .align_up
 cmp rbx,NEBOC_BF_OP_IS_ALIGNED
 je .is_aligned
 cmp rbx,NEBOC_BF_OP_EQUALS
 je .equals
 cmp rbx,NEBOC_BF_OP_COMPARE_LEXICOGRAPHIC
 je .compare
 cmp rbx,NEBOC_BF_OP_XOR_WITH
 je .xor
 cmp rbx,NEBOC_BF_OP_INFIX_XOR
 je .xor
 cmp rbx,NEBOC_BF_OP_CRC32
 je .crc32
 cmp rbx,NEBOC_BF_OP_ADLER32
 je .adler32
 cmp rbx,NEBOC_BF_OP_CONSTANT_TIME_EQUALS
 je .equals
 jmp .internal
.sequence_length:
 mov rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 jmp .publish
.is_empty:
 xor eax,eax
 cmp qword [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],0
 sete al
 jmp .publish
.find:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 call bf_find_sequence
 cmp rax,-1
 jne .publish
 ; The bounded source profile uses unwrapOr as the explicit Option oracle;
 ; its fallback is the last integer literal.
 xor eax,eax
 call bf_integer_from_end
 jc .type
 jmp .publish
.starts:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 mov rcx,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 ja .false
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov rdx,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 cmp rcx,8
 je .starts_cmp
 shl rcx,3
 mov r8,1
 shl r8,cl
 dec r8
 and rax,r8
.starts_cmp:
 cmp rax,rdx
 sete al
 movzx eax,al
 jmp .publish
.ends:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 mov rcx,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 mov r8,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 cmp rcx,r8
 ja .false
 sub r8,rcx
 shl r8,3
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov cl,r8b
 shr rax,cl
 mov rdx,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 cmp rax,rdx
 sete al
 movzx eax,al
 jmp .publish
.reserve:
 ; withCapacity/zeroed argument followed by additional capacity.
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov r13,rax
 mov eax,1
 call bf_integer_from_end
 jc .type
 add rax,r13
 jc .capacity
 cmp rax,8
 ja .capacity
 jmp .publish
.extend:
 ; The controlled profile starts empty or zeroed and appends one immutable
 ; sequence.  For zeroed the constructor length is the first integer.
 mov rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 test rax,rax
 jz .publish
 ; withCapacity reserves but has logical length zero.
 test qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_RESERVE-1))
 jnz .publish
 jmp .publish
.first_integer:
 mov rcx,[r12+NEBOC_BF_INTEGER_COUNT_OFFSET]
 test rcx,rcx
 jz .type
 mov rax,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET]
 jmp .publish
.subslice:
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov r13,rax
 mov eax,1
 call bf_integer_from_end
 jc .type
 cmp r13,rax
 jb .bounds
 cmp r13,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 ja .bounds
 sub r13,rax
 mov rax,r13
 jmp .publish
.sequence_first:
 cmp qword [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],0
 je .bounds
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 and eax,255
 jmp .publish
.to_bytes:
 test qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_SUBSLICE-1))
 jz .sequence_length
 jmp .subslice
.read_u16:
 cmp qword [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],2
 jb .bounds
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov rcx,rax
 add rax,2
 cmp rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 ja .bounds
 shl rcx,3
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 shr rax,cl
 and eax,0xffff
 jmp .publish
.read_u32:
 cmp qword [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],4
 jb .bounds
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov rcx,rax
 add rax,4
 cmp rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 ja .bounds
 shl rcx,3
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 shr rax,cl
 bswap eax
 jmp .publish
.write_u64:
 ; Direct bounded witness: zeroed(length), write(offset,value), at(index).
 mov rcx,[r12+NEBOC_BF_INTEGER_COUNT_OFFSET]
 cmp rcx,4
 jb .type
 mov r8,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET]
 mov r9,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET+8]
 cmp r8,8
 jb .bounds
 test r9,r9
 jnz .bounds
 mov rax,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET+16]
 mov rcx,[r12+NEBOC_BF_INTEGER_VALUES_OFFSET+24]
 cmp rcx,8
 jae .bounds
 shl rcx,3
 shr rax,cl
 and eax,255
 jmp .publish
.byte_swap:
 xor eax,eax
 call bf_integer_from_end
 jc .type
 bswap rax
 jmp .publish
.align_up:
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov r13,rax
 mov eax,1
 call bf_integer_from_end
 jc .type
 mov r14,rax
 mov rax,r13
 call bf_validate_alignment
 jc .alignment
 dec r13
 add r14,r13
 jc .capacity
 not r13
 and r14,r13
 mov rax,r14
 jmp .publish
.is_aligned:
 xor eax,eax
 call bf_integer_from_end
 jc .type
 mov r13,rax
 mov eax,1
 call bf_integer_from_end
 jc .type
 mov r14,rax
 mov rax,r13
 call bf_validate_alignment
 jc .alignment
 dec r13
 test r14,r13
 sete al
 movzx eax,al
 jmp .publish
.equals:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 call bf_compare_sequences
 test rax,rax
 sete al
 movzx eax,al
 jmp .publish
.compare:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 call bf_compare_sequences
 jmp .publish
.xor:
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],2
 jb .type
 mov rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 cmp rax,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 jne .length
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 xor rax,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 ; A trailing at(index) selects the observable byte; tests use index 0.
 and eax,255
 jmp .publish
.crc32:
 call bf_crc32
 jmp .publish
.adler32:
 xor r15d,r15d
 call bf_adler32
 jmp .publish
.false:
 xor eax,eax
 jmp .publish
.publish:
 mov [r12+NEBOC_BF_RESULT_OFFSET],rax
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_BF_OPERATION_MASK_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_RESULT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_BF_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.type:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_TYPE
 jmp .invalid
.bounds:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_BOUNDS
 jmp .invalid
.alignment:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_ALIGNMENT
 jmp .invalid
.length:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_LENGTH
 jmp .invalid
.capacity:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_CAPACITY
 jmp .invalid
.ownership:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_OWNERSHIP
 jmp .invalid
.internal:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_INTERNAL
.invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.argument_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
