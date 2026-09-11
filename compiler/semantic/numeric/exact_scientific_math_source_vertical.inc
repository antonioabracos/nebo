; G035 token-owned bounded exact/scientific-math vertical. Statements are
; parsed one by one so extra statements, early returns, foreign receivers,
; malformed arity, duplicate ownership markers, and duplicate seeds fail
; before lowering.
%define G35_FAMILY_KEY 0x5246323034473335
%define G35_MIN_SEED 3501
%define G35_MAX_SEED 999999

section .rodata
%macro G35_NAME 2
g35_n_%1: db %2
g35_n_%1_len equ $-g35_n_%1
%endmacro
G35_NAME root,'ExactMath35'
G35_NAME bigint_marker,'bigIntCase35'
G35_NAME decimal_marker,'decimalCase35'
G35_NAME complex_marker,'complexCase35'
G35_NAME quantity_marker,'quantityCase35'
G35_NAME interval_marker,'intervalCase35'
G35_NAME symbolic_marker,'symbolicCase35'
G35_NAME BigInt,'BigInt'
G35_NAME BigDecimal,'BigDecimal'
G35_NAME Rational,'Rational'
G35_NAME Complex,'Complex'
G35_NAME Quaternion,'Quaternion'
G35_NAME Dimension,'Dimension'
G35_NAME Unit,'Unit'
G35_NAME Quantity,'Quantity'
G35_NAME Interval,'Interval'
G35_NAME Symbol,'Symbol'
G35_NAME Expression,'Expression'
G35_NAME big,'big'
G35_NAME decimal,'decimal'
G35_NAME rational,'rational'
G35_NAME exact,'exact'
G35_NAME complex,'complex'
G35_NAME quaternion,'quaternion'
G35_NAME quantity,'quantity'
G35_NAME interval,'interval'
G35_NAME expression,'expression'
G35_NAME zero,'zero'
G35_NAME from_int,'fromInt'
G35_NAME parse,'parse'
G35_NAME add,'add'
G35_NAME subtract,'subtract'
G35_NAME multiply,'multiply'
G35_NAME divide_rem,'divideAndRemainder'
G35_NAME gcd,'gcd'
G35_NAME bit_length,'bitLength'
G35_NAME from_text,'fromText'
G35_NAME scale,'scale'
G35_NAME quantize,'quantize'
G35_NAME divide,'divide'
G35_NAME of,'of'
G35_NAME reduce,'reduce'
G35_NAME to_decimal,'toDecimal'
G35_NAME to_float,'toFloat'
G35_NAME real,'real'
G35_NAME imaginary,'imaginary'
G35_NAME conjugate,'conjugate'
G35_NAME magnitude,'magnitude'
G35_NAME argument,'argument'
G35_NAME exp,'exp'
G35_NAME normalize,'normalize'
G35_NAME define,'define'
G35_NAME convert,'convert'
G35_NAME dimension,'dimension'
G35_NAME in_base,'inBaseUnits'
G35_NAME closed,'closed'
G35_NAME open,'open'
G35_NAME contains,'contains'
G35_NAME intersect,'intersect'
G35_NAME hull,'hull'
G35_NAME width,'width'
G35_NAME refine,'refine'
G35_NAME variable,'variable'
G35_NAME constant,'constant'
G35_NAME simplify,'simplify'
G35_NAME substitute,'substitute'
G35_NAME differentiate,'differentiate'
G35_NAME integrate,'integrate'
G35_NAME solve_for,'solveFor'
G35_NAME evaluate,'evaluate'
G35_NAME metre_suffix,'metre35'
%undef G35_NAME

section .bss align=16
g35_mode: resq 1
g35_seed: resq 1
g35_seed_seen: resq 1
g35_root_seen: resq 1
g35_seen_mask: resq 1

section .text
g35_is_program:
 sub rsp,8
 lea rsi,[rel g35_n_root]
 mov edx,g35_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G35_MARKER 1
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G35_MARKER bigint_marker
 G35_MARKER decimal_marker
 G35_MARKER complex_marker
 G35_MARKER quantity_marker
 G35_MARKER interval_marker
 G35_MARKER symbolic_marker
.no:
 xor eax,eax
 add rsp,8
 ret
.yes:
 mov eax,1
 add rsp,8
 ret
%undef G35_MARKER

g35_marker_at:
 push rbx
 sub rsp,16
 mov rbx,rdi
%macro G35_AT 1
 mov rdi,rbx
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G35_AT bigint_marker
 G35_AT decimal_marker
 G35_AT complex_marker
 G35_AT quantity_marker
 G35_AT interval_marker
 G35_AT symbolic_marker
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 add rsp,16
 pop rbx
 ret
%undef G35_AT

g35_marker_count:
 push rbx
 push r12
 sub rsp,8
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp r12,[rel ls_token_count]
 jae .done
 mov rdi,r12
 call g35_marker_at
 add ebx,eax
 inc r12
 jmp .scan
.done:
 mov eax,ebx
 add rsp,8
 pop r12
 pop rbx
 ret

g35_select_mode:
 sub rsp,8
%macro G35_SELECT 2
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %%next
 mov eax,%2
 add rsp,8
 ret
%%next:
%endmacro
 G35_SELECT bigint_marker,1
 G35_SELECT decimal_marker,2
 G35_SELECT complex_marker,3
 G35_SELECT quantity_marker,4
 G35_SELECT interval_marker,5
 G35_SELECT symbolic_marker,6
 xor eax,eax
 add rsp,8
 ret
%undef G35_SELECT

; RDI is a dot token. Public spellings remain receiver-owned.
g35_call_allowed:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g35_mode]
%macro G35_ALLOW 2
 lea rdi,[rbx-1]
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_%2]
 mov edx,g35_n_%2_len
 call ls_token_match
 test eax,eax
 jnz .yes
%%next:
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 jmp .no
.s1:
 G35_ALLOW BigInt,zero
 G35_ALLOW BigInt,from_int
 G35_ALLOW BigInt,parse
 G35_ALLOW big,add
 G35_ALLOW big,subtract
 G35_ALLOW big,multiply
 G35_ALLOW big,divide_rem
 G35_ALLOW big,gcd
 G35_ALLOW big,bit_length
 jmp .no
.s2:
 G35_ALLOW BigDecimal,from_text
 G35_ALLOW decimal,scale
 G35_ALLOW decimal,quantize
 G35_ALLOW decimal,divide
 G35_ALLOW Rational,of
 G35_ALLOW rational,reduce
 G35_ALLOW rational,to_decimal
 G35_ALLOW exact,to_float
 jmp .no
.s3:
 G35_ALLOW Complex,of
 G35_ALLOW complex,real
 G35_ALLOW complex,imaginary
 G35_ALLOW complex,conjugate
 G35_ALLOW complex,magnitude
 G35_ALLOW complex,argument
 G35_ALLOW complex,exp
 G35_ALLOW Quaternion,of
 G35_ALLOW quaternion,normalize
 jmp .no
.s4:
 G35_ALLOW Dimension,define
 G35_ALLOW Unit,define
 G35_ALLOW Quantity,of
 G35_ALLOW quantity,convert
 G35_ALLOW quantity,dimension
 G35_ALLOW quantity,in_base
 G35_ALLOW quantity,multiply
 G35_ALLOW quantity,divide
 jmp .no
.s5:
 G35_ALLOW Interval,closed
 G35_ALLOW Interval,open
 G35_ALLOW interval,contains
 G35_ALLOW interval,intersect
 G35_ALLOW interval,hull
 G35_ALLOW interval,add
 G35_ALLOW interval,multiply
 G35_ALLOW interval,width
 G35_ALLOW interval,refine
 jmp .no
.s6:
 G35_ALLOW Symbol,variable
 G35_ALLOW Symbol,constant
 G35_ALLOW Expression,of
 G35_ALLOW expression,simplify
 G35_ALLOW expression,substitute
 G35_ALLOW expression,differentiate
 G35_ALLOW expression,integrate
 G35_ALLOW expression,solve_for
 G35_ALLOW expression,evaluate
 jmp .no
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G35_ALLOW

; Validate exact source arity and require the statement terminator. RDI is dot.
g35_validate_call:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g35_mode]
 cmp r12,2
 jne .not_decimal_divide
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_divide]
 mov edx,g35_n_divide_len
 call ls_token_match
 test eax,eax
 jnz .two
.not_decimal_divide:
 cmp r12,4
 jne .not_quantity_special
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_define]
 mov edx,g35_n_define_len
 call ls_token_match
 test eax,eax
 jz .quantity_divide
 lea rdi,[rbx-1]
 lea rsi,[rel g35_n_Unit]
 mov edx,g35_n_Unit_len
 call ls_token_match
 test eax,eax
 jnz .four
 jmp .two
.quantity_divide:
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_divide]
 mov edx,g35_n_divide_len
 call ls_token_match
 test eax,eax
 jnz .one
.not_quantity_special:
 cmp r12,3
 jne .common
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_of]
 mov edx,g35_n_of_len
 call ls_token_match
 test eax,eax
 jz .common
 lea rdi,[rbx-1]
 lea rsi,[rel g35_n_Quaternion]
 mov edx,g35_n_Quaternion_len
 call ls_token_match
 test eax,eax
 jnz .four
 jmp .two
.common:
%macro G35_SIG 2
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G35_SIG zero,.zero
 G35_SIG bit_length,.zero
 G35_SIG scale,.zero
 G35_SIG reduce,.zero
 G35_SIG real,.zero
 G35_SIG imaginary,.zero
 G35_SIG conjugate,.zero
 G35_SIG magnitude,.zero
 G35_SIG argument,.zero
 G35_SIG exp,.zero
 G35_SIG normalize,.zero
 G35_SIG dimension,.zero
 G35_SIG in_base,.zero
 G35_SIG width,.zero
 G35_SIG from_int,.one
 G35_SIG add,.one
 G35_SIG subtract,.one
 G35_SIG multiply,.one
 G35_SIG divide_rem,.one
 G35_SIG gcd,.one
 G35_SIG to_decimal,.one
 G35_SIG to_float,.one
 G35_SIG convert,.one
 G35_SIG contains,.one
 G35_SIG intersect,.one
 G35_SIG hull,.one
 G35_SIG refine,.one
 G35_SIG constant,.one
 G35_SIG simplify,.one
 G35_SIG differentiate,.one
 G35_SIG parse,.two
 G35_SIG from_text,.two
 G35_SIG quantize,.two
 G35_SIG of,.two
 G35_SIG closed,.two
 G35_SIG open,.two
 G35_SIG variable,.two
 G35_SIG substitute,.two
 G35_SIG integrate,.two
 G35_SIG solve_for,.two
 G35_SIG evaluate,.two
 jmp .bad
.zero:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 sete al
 movzx eax,al
 jmp .done
.one:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 sete al
 movzx eax,al
 jmp .done
.two:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+7]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 sete al
 movzx eax,al
 jmp .done
.four:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
%macro G35_ARG_COMMA 2
 lea rdi,[rbx+%1]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+%2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
%endmacro
 G35_ARG_COMMA 3,4
 G35_ARG_COMMA 5,6
 G35_ARG_COMMA 7,8
 lea rdi,[rbx+9]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+10]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+11]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 sete al
 movzx eax,al
 jmp .done
%undef G35_ARG_COMMA
.bad:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G35_SIG

g35_mark_call:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g35_mode]
%macro G35_SEEN 2
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g35_seen_mask],%2
 jmp .done
%%next:
%endmacro
%macro G35_PAIR_SEEN 3
 lea rdi,[rbx-1]
 lea rsi,[rel g35_n_%1]
 mov edx,g35_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_%2]
 mov edx,g35_n_%2_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g35_seen_mask],%3
 jmp .done
%%next:
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 jmp .done
.s1:
 G35_SEEN zero,1
 G35_SEEN from_int,2
 G35_SEEN parse,4
 G35_SEEN add,8
 G35_SEEN subtract,16
 G35_SEEN multiply,32
 G35_SEEN divide_rem,64
 G35_SEEN gcd,128
 G35_SEEN bit_length,256
 jmp .done
.s2:
 G35_SEEN from_text,1
 G35_SEEN scale,2
 G35_SEEN quantize,4
 G35_SEEN divide,8
 G35_SEEN of,16
 G35_SEEN reduce,32
 G35_SEEN to_decimal,64
 G35_SEEN to_float,128
 jmp .done
.s3:
 G35_PAIR_SEEN Complex,of,1
 G35_SEEN real,2
 G35_SEEN imaginary,4
 G35_SEEN conjugate,8
 G35_SEEN magnitude,16
 G35_SEEN argument,32
 G35_SEEN exp,64
 G35_PAIR_SEEN Quaternion,of,128
 G35_SEEN normalize,256
 jmp .done
.s4:
 G35_PAIR_SEEN Dimension,define,1
 G35_PAIR_SEEN Unit,define,2
 G35_PAIR_SEEN Quantity,of,4
 G35_SEEN convert,8
 G35_SEEN dimension,16
 G35_SEEN in_base,32
 G35_SEEN multiply,64
 G35_SEEN divide,128
 jmp .done
.s5:
 G35_SEEN closed,1
 G35_SEEN open,2
 G35_SEEN contains,4
 G35_SEEN intersect,8
 G35_SEEN hull,16
 G35_SEEN add,32
 G35_SEEN multiply,64
 G35_SEEN width,128
 G35_SEEN refine,256
 jmp .done
.s6:
 G35_PAIR_SEEN Symbol,variable,1
 G35_PAIR_SEEN Symbol,constant,2
 G35_PAIR_SEEN Expression,of,4
 G35_SEEN simplify,8
 G35_SEEN substitute,16
 G35_SEEN differentiate,32
 G35_SEEN integrate,64
 G35_SEEN solve_for,128
 G35_SEEN evaluate,256
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G35_PAIR_SEEN
%undef G35_SEEN

g35_seek_after_semicolon:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 lea r12,[rdi+14]
.scan:
 cmp rbx,r12
 jae .bad
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .found
 inc rbx
 jmp .scan
.found:
 lea rax,[rbx+1]
 add rsp,8
 pop r12
 pop rbx
 ret
.bad:
 xor eax,eax
 add rsp,8
 pop r12
 pop rbx
 ret

g35_scan_program:
 push rbx
 push r12
 mov rbx,[rel ls_cursor]
.statement:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .complete
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 mov rdi,rbx
 lea rsi,[rel g35_n_root]
 mov edx,g35_n_root_len
 call ls_token_match
 test eax,eax
 jnz .root
 mov rdi,rbx
 call g35_marker_at
 test eax,eax
 jnz .marker
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 je .integer
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .unsupported
 lea r12,[rbx+1]
 mov rdi,r12
 call g35_call_allowed
 test eax,eax
 jz .unsupported
 mov rdi,r12
 call g35_validate_call
 test eax,eax
 jz .unsupported
 mov rdi,r12
 call g35_mark_call
 mov rdi,rbx
 call g35_seek_after_semicolon
 test rax,rax
 jz .syntax
 mov rbx,rax
 jmp .statement
.root:
 cmp qword [rel g35_root_seen],0
 jne .unsupported
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .unsupported
 mov qword [rel g35_root_seen],1
 add rbx,2
 jmp .statement
.marker:
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .unsupported
 add rbx,2
 jmp .statement
.integer:
 cmp qword [rel g35_mode],4
 jne .seed
 lea rdi,[rbx+1]
 lea rsi,[rel g35_n_metre_suffix]
 mov edx,g35_n_metre_suffix_len
 call ls_token_match
 test eax,eax
 jz .seed
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .unsupported
 test qword [rel g35_seen_mask],256
 jnz .unsupported
 or qword [rel g35_seen_mask],256
 add rbx,3
 jmp .statement
.seed:
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .unsupported
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G35_MIN_SEED
 jb .unsupported
 cmp rdx,G35_MAX_SEED
 ja .unsupported
 cmp qword [rel g35_seed_seen],0
 jne .unsupported
 mov qword [rel g35_seed_seen],1
 mov [rel g35_seed],rdx
 add rbx,2
 jmp .statement
.complete:
 cmp qword [rel g35_root_seen],1
 jne .unsupported
 cmp qword [rel g35_seed_seen],1
 jne .unsupported
 mov rax,[rel g35_mode]
 cmp rax,2
 je .expect_eight
 cmp qword [rel g35_seen_mask],0x1ff
 jne .unsupported
 xor eax,eax
 jmp .done
.expect_eight:
 cmp qword [rel g35_seen_mask],0xff
 jne .unsupported
 xor eax,eax
 jmp .done
.syntax:
 mov eax,20
 jmp .done
.unsupported:
 mov eax,24
.done:
 pop r12
 pop rbx
 ret

neboc_g035_source_parse:
 sub rsp,8
 mov qword [rel g35_mode],0
 mov qword [rel g35_seed],0
 mov qword [rel g35_seed_seen],0
 mov qword [rel g35_root_seen],0
 mov qword [rel g35_seen_mask],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g35_marker_count
 cmp eax,1
 jne .unsupported
 call g35_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g35_mode],rax
 call g35_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g35_mode]
 shl rax,32
 mov edi,dword [rel g35_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G35_FAMILY_KEY
 call ls_success
 add rsp,8
 ret
.syntax:
 mov edi,20
 call ls_error
 add rsp,8
 ret
.unsupported:
 mov edi,24
 call ls_error
 add rsp,8
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 add rsp,8
 ret
