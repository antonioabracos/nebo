; G060 bounded typed percent formatting. This owner has no varargs, performs
; literal-template compilation before binding, and commits output only after a
; complete measure/validation pass succeeds.
bits 64
default rel
%define NEBO_PERCENT_FORMAT_IMPLEMENTATION 1
%include "runtime/textual/percent_format.inc"
%include "runtime/textual/format_profiles.inc"
%include "runtime/textual/format_language.inc"

extern neboc_format_int_to_base
extern neboc_format_float_fixed
extern neboc_format_float_scientific
extern neboc_format_profile_text
extern neboc_format_structural_profile
extern neboc_format_profile_layout

section .rodata
pct_true: db 'true'
pct_true_len equ $-pct_true
pct_false: db 'false'
pct_false_len equ $-pct_false
pct_missing: db '<missing>'
pct_missing_len equ $-pct_missing
pct_type_text: db 'Text'
pct_type_text_len equ $-pct_type_text
pct_type_int: db 'Int'
pct_type_int_len equ $-pct_type_int
pct_type_float: db 'Float'
pct_type_float_len equ $-pct_type_float
pct_type_bool: db 'Bool'
pct_type_bool_len equ $-pct_type_bool
pct_type_structural: db 'Structural'
pct_type_structural_len equ $-pct_type_structural
%macro PCT_DIAG_NAME 1
pct_diag_%1: db 'NEBO-FORMAT-00','0'+%1
pct_diag_%1_len equ $-pct_diag_%1
%endmacro
PCT_DIAG_NAME 1
PCT_DIAG_NAME 2
PCT_DIAG_NAME 3
PCT_DIAG_NAME 4
PCT_DIAG_NAME 5
PCT_DIAG_NAME 6
PCT_DIAG_NAME 7
PCT_DIAG_NAME 8
%undef PCT_DIAG_NAME

section .text
global neboc_percent_compile_request
global neboc_percent_validate_request
global neboc_percent_render_request
global neboc_percent_validate_plan_request
global neboc_percent_render_plan_request
global neboc_percent_policy_validate
global neboc_percent_name_hash
global neboc_percent_diagnostic_name

; RDI diagnostic 1..8 -> RAX immutable identifier, RDX byte length.
neboc_percent_diagnostic_name:
 cmp edi,1
 je .diagnostic_1
 cmp edi,2
 je .diagnostic_2
 cmp edi,3
 je .diagnostic_3
 cmp edi,4
 je .diagnostic_4
 cmp edi,5
 je .diagnostic_5
 cmp edi,6
 je .diagnostic_6
 cmp edi,7
 je .diagnostic_7
 cmp edi,8
 je .diagnostic_8
.diagnostic_invalid:
 xor eax,eax
 xor edx,edx
 ret
%macro PCT_DIAG_RETURN 1
.diagnostic_%1:
 lea rax,[rel pct_diag_%1]
 mov edx,pct_diag_%1_len
 ret
%endmacro
 PCT_DIAG_RETURN 1
 PCT_DIAG_RETURN 2
 PCT_DIAG_RETURN 3
 PCT_DIAG_RETURN 4
 PCT_DIAG_RETURN 5
 PCT_DIAG_RETURN 6
 PCT_DIAG_RETURN 7
 PCT_DIAG_RETURN 8
%undef PCT_DIAG_RETURN

; RDI bytes, RSI length -> RAX stable FNV-1a key (zero is reserved).
neboc_percent_name_hash:
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx rdx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 test rax,rax
 jnz .return
 mov eax,1
.return:
 ret

; RDI policy -> EAX zero or NEBO-FORMAT-001. Contradictory addressing modes
; and unknown policy bits fail before template or output inspection.
neboc_percent_policy_validate:
 mov rax,rdi
 and rax,~PERCENT_POLICY_ALL
 jnz .bad
 mov rax,rdi
 and rax,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 cmp rax,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 je .bad
 xor eax,eax
 ret
.bad:
 mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 ret

; AL placeholder spelling -> EAX typed kind, zero when unsupported.
pct_map_type:
 cmp al,'s'
 je .text
 cmp al,'d'
 je .int
 cmp al,'f'
 je .float
 cmp al,'b'
 je .bool
 cmp al,'v'
 je .value
 cmp al,'T'
 je .typename
 cmp al,'q'
 je .quote
 cmp al,'j'
 je .json
 cmp al,'#'
 je .structural
 cmp al,'?'
 je .inspect
 cmp al,'x'
 je .hex
 cmp al,'o'
 je .octal
 cmp al,'e'
 je .scientific
 xor eax,eax
 ret
.text: mov eax,PERCENT_TYPE_TEXT
 ret
.int: mov eax,PERCENT_TYPE_INT
 ret
.float: mov eax,PERCENT_TYPE_FLOAT
 ret
.bool: mov eax,PERCENT_TYPE_BOOL
 ret
.value: mov eax,PERCENT_TYPE_VALUE
 ret
.typename: mov eax,PERCENT_TYPE_TYPENAME
 ret
.quote: mov eax,PERCENT_TYPE_QUOTE
 ret
.json: mov eax,PERCENT_TYPE_JSON
 ret
.structural: mov eax,PERCENT_TYPE_STRUCTURAL
 ret
.inspect: mov eax,PERCENT_TYPE_INSPECT
 ret
.hex: mov eax,PERCENT_TYPE_HEX
 ret
.octal: mov eax,PERCENT_TYPE_OCTAL
 ret
.scientific: mov eax,PERCENT_TYPE_SCIENTIFIC
 ret

; RDI PercentRequest -> EAX zero or stable diagnostic. Nodes are emitted only
; into caller scratch; the template remains immutable.
neboc_percent_compile_request:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 test rdi,rdi
 jz .unknown_direct
 mov rbx,rdi
 mov qword [rbx+PERCENT_REQUEST_NODE_COUNT],0
 mov qword [rbx+PERCENT_REQUEST_WRITTEN],0
 mov qword [rbx+PERCENT_REQUEST_DIAGNOSTIC],0
 mov rdi,[rbx+PERCENT_REQUEST_POLICY]
 call neboc_percent_policy_validate
 test eax,eax
 jnz .fail
 mov r12,[rbx+PERCENT_REQUEST_TEMPLATE]
 mov r13,[rbx+PERCENT_REQUEST_TEMPLATE_LEN]
 mov r14,[rbx+PERCENT_REQUEST_NODES]
 mov r15,[rbx+PERCENT_REQUEST_NODE_CAP]
 cmp r13,PERCENT_MAX_TEMPLATE
 ja .output_limit
 cmp r15,PERCENT_MAX_NODES
 ja .output_limit
 test r13,r13
 jz .empty
 test r12,r12
 jz .unknown
 test r14,r14
 jz .output_limit
 test r15,r15
 jz .output_limit
 mov qword [rsp],0                 ; cursor
 mov qword [rsp+8],0               ; literal start
 mov qword [rsp+16],0              ; node count
 mov qword [rsp+24],0              ; next sequential index
.scan:
 mov r8,[rsp]
 cmp r8,r13
 jae .finish
 cmp byte [r12+r8],'%'
 je .percent
 inc qword [rsp]
 jmp .scan
.percent:
 ; Emit bytes preceding the percent as one immutable literal node.
 mov r9,[rsp+8]
 cmp r8,r9
 je .percent_start
 mov rcx,r8
 sub rcx,r9
 call .emit_literal
 test eax,eax
 jnz .fail
.percent_start:
 mov r8,[rsp]
 mov [rsp+32],r8                    ; placeholder start
 inc r8
 cmp r8,r13
 jae .unknown
 cmp byte [r12+r8],'%'
 jne .placeholder
 ; %% is a literal percent and consumes no argument.
 mov [rsp+40],r8
 mov qword [rsp+48],1
 call .emit_literal_saved
 test eax,eax
 jnz .fail
 add qword [rsp],2
 mov rax,[rsp]
 mov [rsp+8],rax
 jmp .scan
.placeholder:
 mov qword [rsp+40],0               ; width
 mov qword [rsp+48],-1              ; precision: absent
 mov qword [rsp+56],0               ; flags
 mov qword [rsp+64],PERCENT_ADDRESS_SEQUENTIAL
 mov rax,[rsp+24]
 mov [rsp+72],rax                   ; key
 cmp byte [r12+r8],'{'
 je .named
 ; Optional flags before width.
.flags:
 cmp r8,r13
 jae .unknown
 mov al,[r12+r8]
 cmp al,'-'
 jne .flag_zero
 or qword [rsp+56],PERCENT_FLAG_LEFT
 inc r8
 jmp .flags
.flag_zero:
 cmp al,'0'
 jne .flag_sign
 ; A leading zero is a flag, not a positional index.
 lea rax,[r8+1]
 cmp rax,r13
 jae .zero_flag
 cmp byte [r12+r8+1],'$'
 je .digits
.zero_flag:
 or qword [rsp+56],PERCENT_FLAG_ZERO
 inc r8
 jmp .flags
.flag_sign:
 cmp al,'+'
 jne .digits
 or qword [rsp+56],PERCENT_FLAG_SIGN
 inc r8
 jmp .flags
.digits:
 xor r9d,r9d
 xor r10d,r10d
.digit_loop:
 cmp r8,r13
 jae .after_digits
 movzx eax,byte [r12+r8]
 sub eax,'0'
 cmp eax,9
 ja .after_digits
 imul r9,r9,10
 add r9,rax
 cmp r9,PERCENT_MAX_WIDTH
 ja .width_precision
 inc r8
 inc r10d
 jmp .digit_loop
.after_digits:
 test r10d,r10d
 jz .precision
 cmp r8,r13
 jae .unknown
 cmp byte [r12+r8],'$'
 jne .store_width
 test r9,r9
 jz .positional
 cmp r9,PERCENT_MAX_ARGS
 ja .positional
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_NAMED_ONLY
 jnz .unknown
 mov qword [rsp+64],PERCENT_ADDRESS_POSITIONAL
 dec r9
 mov [rsp+72],r9
 inc r8
 jmp .precision
.store_width:
 mov [rsp+40],r9
.precision:
 cmp r8,r13
 jae .unknown
 cmp byte [r12+r8],'.'
 jne .type
 inc r8
 cmp r8,r13
 jae .width_precision
 xor r9d,r9d
 xor r10d,r10d
.precision_digits:
 cmp r8,r13
 jae .precision_done
 movzx eax,byte [r12+r8]
 sub eax,'0'
 cmp eax,9
 ja .precision_done
 imul r9,r9,10
 add r9,rax
 cmp r9,PERCENT_MAX_PRECISION
 ja .width_precision
 inc r8
 inc r10d
 jmp .precision_digits
.precision_done:
 test r10d,r10d
 jz .width_precision
 mov [rsp+48],r9
.type:
 cmp r8,r13
 jae .unknown
 mov al,[r12+r8]
 cmp al,'p'
 je .unknown
 call pct_map_type
 test eax,eax
 jz .unknown_policy
 mov [rsp+80],rax
 inc r8
 cmp qword [rsp+64],PERCENT_ADDRESS_SEQUENTIAL
 jne .emit_placeholder
 inc qword [rsp+24]
 jmp .emit_placeholder
.named:
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_POSITIONAL_ONLY
 jnz .unknown
 mov qword [rsp+64],PERCENT_ADDRESS_NAMED
 add r8,1
 mov r9,r8                          ; name start
.name_scan:
 cmp r8,r13
 jae .unknown
 mov al,[r12+r8]
 cmp al,':'
 je .name_end
 cmp al,'_'
 je .name_next
 cmp al,'0'
 jb .name_alpha
 cmp al,'9'
 jbe .name_next
.name_alpha:
 cmp al,'A'
 jb .unknown
 cmp al,'Z'
 jbe .name_next
 cmp al,'a'
 jb .unknown
 cmp al,'z'
 ja .unknown
.name_next:
 inc r8
 jmp .name_scan
.name_end:
 cmp r8,r9
 je .unknown
 mov rdi,r12
 add rdi,r9
 mov rsi,r8
 sub rsi,r9
 mov [rsp+88],r8
 call neboc_percent_name_hash
 mov [rsp+72],rax
 mov r8,[rsp+88]
 inc r8
 cmp r8,r13
 jae .unknown
 mov al,[r12+r8]
 cmp al,'p'
 je .unknown
 call pct_map_type
 test eax,eax
 jz .unknown
 mov [rsp+80],rax
 inc r8
 cmp r8,r13
 jae .unknown
 cmp byte [r12+r8],'}'
 jne .unknown
 inc r8
.emit_placeholder:
 ; Named-only also excludes implicit sequential addressing. Checking only
 ; an explicit N$ prefix left ordinary %d accidentally positional.
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_NAMED_ONLY
 jz .address_allowed
 cmp qword [rsp+64],PERCENT_ADDRESS_NAMED
 jne .unknown
.address_allowed:
 mov [rsp],r8
 mov rax,[rsp+16]
 cmp rax,r15
 jae .output_limit
 imul rdx,rax,PERCENT_NODE_SIZE
 add rdx,r14
 mov qword [rdx+PERCENT_NODE_KIND],PERCENT_NODE_PLACEHOLDER
 mov rcx,[rsp+32]
 lea rax,[r12+rcx]
 mov [rdx+PERCENT_NODE_DATA],rax
 mov rax,r8
 sub rax,rcx
 mov [rdx+PERCENT_NODE_LENGTH],rax
 mov rax,[rsp+80]
 mov [rdx+PERCENT_NODE_TYPE],rax
 mov rax,[rsp+64]
 mov [rdx+PERCENT_NODE_ADDRESS],rax
 mov rax,[rsp+72]
 mov [rdx+PERCENT_NODE_KEY],rax
 mov rax,[rsp+40]
 mov [rdx+PERCENT_NODE_WIDTH],rax
 mov rax,[rsp+48]
 mov [rdx+PERCENT_NODE_PRECISION],rax
 mov rax,[rsp+56]
 mov [rdx+PERCENT_NODE_FLAGS],rax
 inc qword [rsp+16]
 mov rax,[rsp]
 mov [rsp+8],rax
 jmp .scan
.unknown_policy:
 ; Unknown-literal is an explicit migration policy. It is never the default
 ; and never permits the security-rejected %p spelling.
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_UNKNOWN_LITERAL
 jz .unknown
 inc r8
 mov r9,[rsp+32]
 mov [rsp+40],r9
 mov rax,r8
 sub rax,r9
 mov [rsp+48],rax
 call .emit_literal_saved
 test eax,eax
 jnz .fail
 mov [rsp],r8
 mov [rsp+8],r8
 jmp .scan
.finish:
 mov r9,[rsp+8]
 cmp r9,r13
 je .compiled
 mov rcx,r13
 sub rcx,r9
 call .emit_literal
 test eax,eax
 jnz .fail
.compiled:
 mov rax,[rsp+16]
 mov [rbx+PERCENT_REQUEST_NODE_COUNT],rax
.empty:
 xor eax,eax
 jmp .done
.emit_literal:
 ; R9 template offset, RCX length.
 mov [rsp+48],r9
 mov [rsp+56],rcx
.emit_literal_saved:
 ; CALL contributes one return-address qword to the compile frame offsets.
 mov rax,[rsp+24]
 cmp rax,r15
 jae .emit_limit
 imul rdx,rax,PERCENT_NODE_SIZE
 add rdx,r14
 mov qword [rdx+PERCENT_NODE_KIND],PERCENT_NODE_LITERAL
 mov r9,[rsp+48]
 lea rax,[r12+r9]
 mov [rdx+PERCENT_NODE_DATA],rax
 mov rax,[rsp+56]
 mov [rdx+PERCENT_NODE_LENGTH],rax
 mov qword [rdx+PERCENT_NODE_TYPE],0
 mov qword [rdx+PERCENT_NODE_ADDRESS],0
 mov qword [rdx+PERCENT_NODE_KEY],0
 mov qword [rdx+PERCENT_NODE_WIDTH],0
 mov qword [rdx+PERCENT_NODE_PRECISION],-1
 mov qword [rdx+PERCENT_NODE_FLAGS],0
 inc qword [rsp+24]
 xor eax,eax
 ret
.emit_limit:
 mov eax,PERCENT_DIAG_OUTPUT_LIMIT
 ret
.unknown: mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jmp .fail
.positional: mov eax,PERCENT_DIAG_POSITIONAL_INDEX
 jmp .fail
.width_precision: mov eax,PERCENT_DIAG_WIDTH_PRECISION
 jmp .fail
.output_limit: mov eax,PERCENT_DIAG_OUTPUT_LIMIT
.fail:
 mov [rbx+PERCENT_REQUEST_DIAGNOSTIC],rax
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.unknown_direct:
 mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 ret

; Copy RSI/RDX to RDI with RCX capacity. Returns length or -diag8.
pct_copy_text:
 cmp rdx,rcx
 ja .limit
 test rdx,rdx
 jz .zero
 test rsi,rsi
 jz .limit
 mov rax,rdx
 mov rcx,rdx
 rep movsb
 ret
.zero: xor eax,eax
 ret
.limit: mov rax,-PERCENT_DIAG_OUTPUT_LIMIT
 ret

; RDI node, RSI argument, RDX temporary output, RCX capacity, R8 policy.
; RAX byte length or negative stable diagnostic.
pct_format_argument:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,192
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rax,[r12+PERCENT_NODE_TYPE]
 mov [rsp],rax
 cmp rax,PERCENT_TYPE_TYPENAME
 je .typename
 cmp rax,PERCENT_TYPE_VALUE
 je .value
 cmp rax,PERCENT_TYPE_STRUCTURAL
 je .structural
 cmp rax,PERCENT_TYPE_INSPECT
 je .inspect
 cmp rax,PERCENT_TYPE_TEXT
 je .text
 cmp rax,PERCENT_TYPE_QUOTE
 je .quote
 cmp rax,PERCENT_TYPE_JSON
 je .json
 cmp rax,PERCENT_TYPE_BOOL
 je .bool
 cmp rax,PERCENT_TYPE_INT
 je .decimal
 cmp rax,PERCENT_TYPE_HEX
 je .hex
 cmp rax,PERCENT_TYPE_OCTAL
 je .octal
 cmp rax,PERCENT_TYPE_FLOAT
 je .fixed
 cmp rax,PERCENT_TYPE_SCIENTIFIC
 je .scientific
 cmp rax,PERCENT_TYPE_BINARY
 je .binary
 jmp .type_mismatch
.typename:
 mov rax,[r13+PERCENT_ARG_KIND]
 cmp rax,PERCENT_ARG_TEXT
 je .name_text
 cmp rax,PERCENT_ARG_INT
 je .name_int
 cmp rax,PERCENT_ARG_FLOAT
 je .name_float
 cmp rax,PERCENT_ARG_BOOL
 je .name_bool
 cmp rax,PERCENT_ARG_STRUCTURAL
 je .name_structural
 jmp .type_mismatch
.name_text: lea rsi,[rel pct_type_text]
 mov edx,pct_type_text_len
 jmp .copy
.name_int: lea rsi,[rel pct_type_int]
 mov edx,pct_type_int_len
 jmp .copy
.name_float: lea rsi,[rel pct_type_float]
 mov edx,pct_type_float_len
 jmp .copy
.name_bool: lea rsi,[rel pct_type_bool]
 mov edx,pct_type_bool_len
 jmp .copy
.name_structural: lea rsi,[rel pct_type_structural]
 mov edx,pct_type_structural_len
 jmp .copy
.value:
 mov rax,[r13+PERCENT_ARG_KIND]
 cmp rax,PERCENT_ARG_TEXT
 je .text_exact
 cmp rax,PERCENT_ARG_INT
 je .decimal_exact
 cmp rax,PERCENT_ARG_FLOAT
 je .fixed_exact
 cmp rax,PERCENT_ARG_BOOL
 je .bool_exact
 cmp rax,PERCENT_ARG_STRUCTURAL
 je .text_exact
 jmp .type_mismatch
.text:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 je .text_exact
 test rbx,PERCENT_POLICY_ALLOW_COERCE
 jz .coercion
 jmp .value
.text_exact:
 test qword [r12+PERCENT_NODE_FLAGS],PERCENT_FLAG_CENTER
 jnz .center_text
 mov rsi,[r13+PERCENT_ARG_DATA]
 mov rdx,[r13+PERCENT_ARG_LENGTH]
.copy:
 mov rdi,r14
 mov rcx,r15
 call pct_copy_text
 jmp .decorate
.center_text:
 ; The native profile receives the original immutable argument and a
 ; distinct output buffer, retaining its alias and capacity checks.
 mov qword [rsp+96+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_ALIGN
 mov rax,[r13+PERCENT_ARG_DATA]
 mov [rsp+96+FORMAT_LAYOUT_DATA],rax
 mov rax,[r13+PERCENT_ARG_LENGTH]
 mov [rsp+96+FORMAT_LAYOUT_LENGTH],rax
 mov rax,[r12+PERCENT_NODE_WIDTH]
 mov [rsp+96+FORMAT_LAYOUT_WIDTH],rax
 mov qword [rsp+96+FORMAT_LAYOUT_FILL],' '
 mov qword [rsp+96+FORMAT_LAYOUT_SIDE],FORMAT_PROFILE_SIDE_CENTER
 mov [rsp+96+FORMAT_LAYOUT_OUTPUT],r14
 mov [rsp+96+FORMAT_LAYOUT_CAPACITY],r15
 lea rdi,[rsp+96]
 call neboc_format_profile_layout
 test rax,rax
 js .profile_error
 jmp .done
.quote:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 jne .type_mismatch
 mov edi,FORMAT_PROFILE_QUOTE
 jmp .profile_text
.json:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 jne .type_mismatch
 mov edi,FORMAT_PROFILE_JSON
.profile_text:
 mov rsi,[r13+PERCENT_ARG_DATA]
 mov rdx,[r13+PERCENT_ARG_LENGTH]
 mov rcx,r14
 mov r8,r15
 mov r9d,FORMAT_PROFILE_POLICY_ROOT
 call neboc_format_profile_text
 test rax,rax
 js .profile_error
 jmp .decorate
.bool:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_BOOL
 jne .type_mismatch
.bool_exact:
 cmp qword [r13+PERCENT_ARG_DATA],0
 je .bool_false
 lea rsi,[rel pct_true]
 mov edx,pct_true_len
 jmp .copy
.bool_false:
 lea rsi,[rel pct_false]
 mov edx,pct_false_len
 jmp .copy
.decimal:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_INT
 jne .type_mismatch
.decimal_exact:
 mov esi,10
 jmp .base
.hex:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_INT
 jne .type_mismatch
 mov esi,16
 jmp .base
.octal:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_INT
 jne .type_mismatch
 mov esi,8
 jmp .base
.binary:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_INT
 jne .type_mismatch
 mov esi,2
.base:
 mov rdi,[r13+PERCENT_ARG_DATA]
 xor edx,edx
 mov rcx,r14
 mov r8,r15
 call neboc_format_int_to_base
 test rax,rax
 js .profile_error
 jmp .sign
.fixed:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_FLOAT
 jne .type_mismatch
.fixed_exact:
 movq xmm0,[r13+PERCENT_ARG_DATA]
 mov rdi,[r12+PERCENT_NODE_PRECISION]
 cmp rdi,-1
 jne .fixed_precision
 mov edi,6
.fixed_precision:
 mov rsi,r14
 mov rdx,r15
 call neboc_format_float_fixed
 test rax,rax
 js .profile_error
 jmp .sign
.scientific:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_FLOAT
 jne .type_mismatch
 movq xmm0,[r13+PERCENT_ARG_DATA]
 mov rdi,[r12+PERCENT_NODE_PRECISION]
 cmp rdi,-1
 jne .scientific_precision
 mov edi,6
.scientific_precision:
 mov rsi,r14
 mov rdx,r15
 call neboc_format_float_scientific
 test rax,rax
 js .profile_error
 jmp .sign
.structural:
 mov qword [rsp+32+FORMAT_STRUCTURAL_PROFILE],FORMAT_PROFILE_STRUCTURAL
 jmp .struct_common
.inspect:
 mov qword [rsp+32+FORMAT_STRUCTURAL_PROFILE],FORMAT_PROFILE_INSPECT
.struct_common:
 cmp qword [r13+PERCENT_ARG_KIND],PERCENT_ARG_STRUCTURAL
 je .struct_existing
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,[rsp+32+FORMAT_STRUCTURAL_PROFILE]
 call pct_format_scalar_structure
 test rax,rax
 js .profile_error
 jmp .decorate
.struct_existing:
 lea rax,[rel pct_type_structural]
 mov [rsp+32+FORMAT_STRUCTURAL_TYPE],rax
 mov qword [rsp+32+FORMAT_STRUCTURAL_TYPE_LENGTH],pct_type_structural_len
 mov rax,[r13+PERCENT_ARG_DATA]
 mov [rsp+32+FORMAT_STRUCTURAL_VALUE],rax
 mov rax,[r13+PERCENT_ARG_LENGTH]
 mov [rsp+32+FORMAT_STRUCTURAL_VALUE_LENGTH],rax
 mov qword [rsp+32+FORMAT_STRUCTURAL_DEPTH],1
 mov [rsp+32+FORMAT_STRUCTURAL_OUTPUT],r14
 mov [rsp+32+FORMAT_STRUCTURAL_CAPACITY],r15
 lea rdi,[rsp+32]
 call neboc_format_structural_profile
 test rax,rax
 js .profile_error
 jmp .decorate
.sign:
 test qword [r12+PERCENT_NODE_FLAGS],PERCENT_FLAG_SIGN
 jz .decorate
 cmp byte [r14],'-'
 je .decorate
 cmp rax,r15
 jae .output_limit
 mov rcx,rax
.sign_shift:
 test rcx,rcx
 jz .sign_write
 mov dl,[r14+rcx-1]
 mov [r14+rcx],dl
 dec rcx
 jmp .sign_shift
.sign_write:
 mov byte [r14],'+'
 inc rax
.decorate:
 test rax,rax
 js .done
 mov rcx,[r12+PERCENT_NODE_WIDTH]
 cmp rcx,rax
 jbe .done
 cmp rcx,r15
 ja .output_limit
 mov rdx,rcx
 sub rdx,rax                       ; pad count
 test qword [r12+PERCENT_NODE_FLAGS],PERCENT_FLAG_LEFT
 jnz .pad_right
 ; Right alignment moves the result back, then fills the prefix. For signed
 ; zero padding, keep the sign first and place zeros after it.
 test qword [r12+PERCENT_NODE_FLAGS],PERCENT_FLAG_ZERO
 jz .move_right
 cmp byte [r14],'-'
 je .zero_signed
 cmp byte [r14],'+'
 je .zero_signed
.move_right:
 lea r10,[r14+rdx]
 mov r8,rax
.move_loop:
 test r8,r8
 jz .fill_left
 mov r9b,[r14+r8-1]
 mov [r10+r8-1],r9b
 dec r8
 jmp .move_loop
.fill_left:
 mov r8,rdx
 mov r9b,' '
 test qword [r12+PERCENT_NODE_FLAGS],PERCENT_FLAG_ZERO
 jz .fill_left_loop
 mov r9b,'0'
.fill_left_loop:
 test r8,r8
 jz .width_done
 mov [r14+r8-1],r9b
 dec r8
 jmp .fill_left_loop
.zero_signed:
 ; Shift bytes after the sign, preserving it in column zero.
 lea r10,[r14+rdx]
 mov r8,rax
 dec r8
.zero_signed_move:
 test r8,r8
 jz .zero_signed_fill
 mov r9b,[r14+r8]
 mov [r10+r8],r9b
 dec r8
 jmp .zero_signed_move
.zero_signed_fill:
 mov r8,rdx
.zero_signed_fill_loop:
 test r8,r8
 jz .width_done
 mov byte [r14+r8],'0'
 dec r8
 jmp .zero_signed_fill_loop
.pad_right:
 mov r8,rax
.pad_right_loop:
 cmp r8,rcx
 jae .width_done
 mov byte [r14+r8],' '
 inc r8
 jmp .pad_right_loop
.width_done:
 mov rax,rcx
 jmp .done
.profile_error:
 ; Shared profile limit/capacity failures map to the G060 output limit.
 mov rax,-PERCENT_DIAG_OUTPUT_LIMIT
 jmp .done
.coercion: mov rax,-PERCENT_DIAG_COERCION_FORBIDDEN
 jmp .done
.type_mismatch: mov rax,-PERCENT_DIAG_TYPE_MISMATCH
 jmp .done
.output_limit: mov rax,-PERCENT_DIAG_OUTPUT_LIMIT
.done:
 add rsp,192
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI request, ESI write flag -> EAX diagnostic, RDX measured bytes.
pct_walk_request:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,12352
 mov rbx,rdi
 mov [rsp],rsi                       ; write flag
 mov qword [rsp+8],0                 ; total
 mov qword [rsp+16],0                ; consumed bitset
 mov r12,[rbx+PERCENT_REQUEST_NODES]
 mov r13,[rbx+PERCENT_REQUEST_NODE_COUNT]
 mov r14,[rbx+PERCENT_REQUEST_ARGS]
 mov r15,[rbx+PERCENT_REQUEST_ARG_COUNT]
 cmp r13,PERCENT_MAX_NODES
 ja .output_limit
 cmp r15,PERCENT_MAX_ARGS
 ja .arity
 test r15,r15
 jz .duplicates_done
 test r14,r14
 jz .arity
 ; Named argument keys must be unique. Zero means unnamed.
 xor r8d,r8d
.dup_outer:
 cmp r8,r15
 jae .duplicates_done
 mov rax,r8
 shl rax,5
 mov r9,[r14+rax+PERCENT_ARG_NAME_HASH]
 test r9,r9
 jz .dup_next
 lea r10,[r8+1]
.dup_inner:
 cmp r10,r15
 jae .dup_next
 mov rax,r10
 shl rax,5
 cmp r9,[r14+rax+PERCENT_ARG_NAME_HASH]
 je .named
 inc r10
 jmp .dup_inner
.dup_next:
 inc r8
 jmp .dup_outer
.duplicates_done:
 xor ecx,ecx                         ; node index
.node:
 cmp rcx,r13
 jae .extra_check
 imul rax,rcx,PERCENT_NODE_SIZE
 lea r11,[r12+rax]
 mov [rsp+24],rcx
 mov [rsp+32],r11
 cmp qword [r11+PERCENT_NODE_KIND],PERCENT_NODE_LITERAL
 je .literal
 cmp qword [r11+PERCENT_NODE_KIND],PERCENT_NODE_PLACEHOLDER
 jne .unknown
 mov rax,[r11+PERCENT_NODE_ADDRESS]
 cmp rax,PERCENT_ADDRESS_NAMED
 je .resolve_named
 mov r9,[r11+PERCENT_NODE_KEY]
 cmp r9,r15
 jae .resolve_missing_index
 jmp .resolved_index
.resolve_named:
 mov r9,[r11+PERCENT_NODE_KEY]
 xor r10d,r10d
.named_loop:
 cmp r10,r15
 jae .named_missing
 mov rax,r10
 shl rax,5
 cmp r9,[r14+rax+PERCENT_ARG_NAME_HASH]
 je .named_found
 inc r10
 jmp .named_loop
.named_found:
 mov r9,r10
.resolved_index:
 bts qword [rsp+16],r9
 mov rax,r9
 shl rax,5
 lea rsi,[r14+rax]
 lea rdx,[rsp+128]
 mov ecx,12224
 mov rdi,[rsp+32]
 mov r8,[rbx+PERCENT_REQUEST_POLICY]
 call pct_format_argument
 test rax,rax
 js .negative_diag
 jmp .append_temp
.resolve_missing_index:
 cmp qword [r11+PERCENT_NODE_ADDRESS],PERCENT_ADDRESS_POSITIONAL
 je .positional
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_ALLOW_MISSING
 jz .arity
 jmp .missing_text
.named_missing:
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_ALLOW_MISSING
 jz .named
.missing_text:
 lea rsi,[rel pct_missing]
 mov edx,pct_missing_len
 lea rdi,[rsp+128]
 mov ecx,12224
 call pct_copy_text
.append_temp:
 mov rdx,rax
 lea rsi,[rsp+128]
 jmp .append
.literal:
 mov rsi,[r11+PERCENT_NODE_DATA]
 mov rdx,[r11+PERCENT_NODE_LENGTH]
.append:
 mov rax,[rsp+8]
 add rax,rdx
 jc .output_limit
 cmp rax,PERCENT_MAX_OUTPUT
 ja .output_limit
 cmp qword [rsp],0
 je .append_measured
 mov rdi,[rbx+PERCENT_REQUEST_OUTPUT]
 add rdi,[rsp+8]
 mov rcx,rdx
 rep movsb
.append_measured:
 mov [rsp+8],rax
 mov rcx,[rsp+24]
 inc rcx
 jmp .node
.extra_check:
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_ALLOW_EXTRA
 jnz .ok
 test r15,r15
 jz .ok
 cmp r15,64
 je .mask_all
 mov rax,1
 mov ecx,r15d
 shl rax,cl
 dec rax
 jmp .mask_compare
.mask_all:
 mov rax,-1
.mask_compare:
 cmp rax,[rsp+16]
 jne .arity
.ok:
 xor eax,eax
 mov rdx,[rsp+8]
 jmp .done
.negative_diag:
 neg eax
 xor edx,edx
 jmp .done
.unknown: mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jmp .error
.arity: mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .error
.named: mov eax,PERCENT_DIAG_NAMED_ARGUMENT
 jmp .error
.positional: mov eax,PERCENT_DIAG_POSITIONAL_INDEX
 jmp .error
.output_limit: mov eax,PERCENT_DIAG_OUTPUT_LIMIT
.error:
 xor edx,edx
.done:
 add rsp,12352
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI request -> EAX diagnostic. WRITTEN receives the required byte count;
; validation never touches OUTPUT.
neboc_percent_validate_request:
 xor esi,esi
 jmp percent_validate_common
; Compiler-owned immutable nodes have already passed literal compilation.
; Actual argument values/types, output size and policy are still validated.
neboc_percent_validate_plan_request:
 mov esi,1
percent_validate_common:
 push rbx
 sub rsp,16
 test rdi,rdi
 jz .invalid
 mov rbx,rdi
 test esi,esi
 jnz .compiled
 call neboc_percent_compile_request
 test eax,eax
 jnz .store
.compiled:
 mov rdi,[rbx+PERCENT_REQUEST_POLICY]
 call neboc_percent_policy_validate
 test eax,eax
 jnz .store
 mov rdi,rbx
 xor esi,esi
 call pct_walk_request
 test eax,eax
 jnz .store
 mov [rbx+PERCENT_REQUEST_WRITTEN],rdx
 xor eax,eax
 jmp .done
.store:
 mov [rbx+PERCENT_REQUEST_DIAGNOSTIC],rax
 jmp .done
.invalid:
 mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
.done:
 add rsp,16
 pop rbx
 ret

; RDI request -> EAX diagnostic. The output is untouched on every error.
neboc_percent_render_request:
 xor edx,edx
 jmp percent_render_common
neboc_percent_render_plan_request:
 mov edx,1
percent_render_common:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov [rsp],rdx
 test rdi,rdi
 jz .invalid
 mov rbx,rdi
 cmp qword [rsp],0
 jne .validate_plan
 call neboc_percent_validate_request
 jmp .validated
.validate_plan:
 call neboc_percent_validate_plan_request
.validated:
 test eax,eax
 jnz .done
 test qword [rbx+PERCENT_REQUEST_POLICY],PERCENT_POLICY_VALIDATE_ONLY
 jnz .success
 mov r12,[rbx+PERCENT_REQUEST_WRITTEN]
 cmp r12,[rbx+PERCENT_REQUEST_CAPACITY]
 ja .limit
 test r12,r12
 jz .success
 mov r13,[rbx+PERCENT_REQUEST_OUTPUT]
 test r13,r13
 jz .limit
 lea rdx,[r13+r12]
 cmp rdx,r13
 jb .limit
 ; Output may not overlap template, node scratch, argument records or textual
 ; argument storage; this preserves whole-request failure atomicity.
 mov rsi,[rbx+PERCENT_REQUEST_TEMPLATE]
 mov rcx,[rbx+PERCENT_REQUEST_TEMPLATE_LEN]
 call .overlap
 test eax,eax
 jnz .limit
 mov rsi,[rbx+PERCENT_REQUEST_NODES]
 mov rcx,[rbx+PERCENT_REQUEST_NODE_COUNT]
 imul rcx,rcx,PERCENT_NODE_SIZE
 call .overlap
 test eax,eax
 jnz .limit
 mov rsi,[rbx+PERCENT_REQUEST_ARGS]
 mov rcx,[rbx+PERCENT_REQUEST_ARG_COUNT]
 imul rcx,rcx,PERCENT_ARG_SIZE
 call .overlap
 test eax,eax
 jnz .limit
 xor r8d,r8d
.arg_overlap:
 cmp r8,[rbx+PERCENT_REQUEST_ARG_COUNT]
 jae .write
 mov rax,r8
 shl rax,5
 mov r9,[rbx+PERCENT_REQUEST_ARGS]
 add r9,rax
 mov rax,[r9+PERCENT_ARG_KIND]
 cmp rax,PERCENT_ARG_TEXT
 je .arg_slice
 cmp rax,PERCENT_ARG_STRUCTURAL
 jne .arg_next
.arg_slice:
 mov rsi,[r9+PERCENT_ARG_DATA]
 mov rcx,[r9+PERCENT_ARG_LENGTH]
 call .overlap
 test eax,eax
 jnz .limit
.arg_next:
 inc r8
 jmp .arg_overlap
.write:
 mov rdi,rbx
 mov esi,1
 call pct_walk_request
 test eax,eax
 jnz .store
 cmp rdx,r12
 jne .limit
.success:
 mov qword [rbx+PERCENT_REQUEST_DIAGNOSTIC],0
 xor eax,eax
 jmp .done
.overlap:
 test rcx,rcx
 jz .no_overlap
 test rsi,rsi
 jz .yes_overlap
 lea rax,[rsi+rcx]
 cmp rax,rsi
 jb .yes_overlap
 cmp r13,rax
 jae .no_overlap
 lea rax,[r13+r12]
 cmp rax,rsi
 ja .yes_overlap
.no_overlap:
 xor eax,eax
 ret
.yes_overlap:
 mov eax,1
 ret
.limit:
 mov eax,PERCENT_DIAG_OUTPUT_LIMIT
.store:
 mov [rbx+PERCENT_REQUEST_DIAGNOSTIC],rax
 jmp .done
.invalid:
 mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
; Scalar structure/inspection reuses typed scalar rendering followed by the
; canonical structural profile. Text is quoted/escaped, never reinterpreted.
; node, argument, destination, capacity, profile -> bytes or negative error.
pct_format_scalar_structure:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8352
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov rdi,rsp
 xor eax,eax
 mov ecx,20
 rep stosq
 mov rax,[r12+PERCENT_ARG_KIND]
 lea rbx,[rel pct_type_text]
 mov edx,pct_type_text_len
 mov qword [rsp+80+PERCENT_NODE_TYPE],PERCENT_TYPE_QUOTE
 cmp eax,PERCENT_ARG_TEXT
 je .typed
 mov qword [rsp+80+PERCENT_NODE_TYPE],PERCENT_TYPE_VALUE
 lea rbx,[rel pct_type_int]
 mov edx,pct_type_int_len
 cmp eax,PERCENT_ARG_INT
 je .typed
 lea rbx,[rel pct_type_float]
 mov edx,pct_type_float_len
 cmp eax,PERCENT_ARG_FLOAT
 je .typed
 lea rbx,[rel pct_type_bool]
 mov edx,pct_type_bool_len
 cmp eax,PERCENT_ARG_BOOL
 jne .invalid
.typed:
 mov [rsp+FORMAT_STRUCTURAL_TYPE],rbx
 mov [rsp+FORMAT_STRUCTURAL_TYPE_LENGTH],rdx
 mov qword [rsp+80+PERCENT_NODE_PRECISION],-1
 lea rdi,[rsp+80]
 mov rsi,r12
 lea rdx,[rsp+160]
 mov ecx,8192
 xor r8d,r8d
 call pct_format_argument
 test rax,rax
 js .done
 mov [rsp+FORMAT_STRUCTURAL_VALUE_LENGTH],rax
 lea rax,[rsp+160]
 mov [rsp+FORMAT_STRUCTURAL_VALUE],rax
 mov [rsp+FORMAT_STRUCTURAL_PROFILE],r15
 mov qword [rsp+FORMAT_STRUCTURAL_DEPTH],1
 mov [rsp+FORMAT_STRUCTURAL_OUTPUT],r13
 mov [rsp+FORMAT_STRUCTURAL_CAPACITY],r14
 mov rdi,rsp
 call neboc_format_structural_profile
 jmp .done
.invalid:
 mov rax,-FORMAT_E_INVALID
.done:
 add rsp,8352
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
