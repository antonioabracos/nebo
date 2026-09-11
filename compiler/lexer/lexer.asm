; Nebo Assembly — complete Core v0.1 lexer
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry_generated.inc"
%include "compiler/lexer/operator_lexeme_trie.inc"
%include "compiler/lexer/operator_provenance.inc"
%include "compiler/tokens/unicode_alias_contract.inc"
%include "compiler/source/utf8/unicode_source_security.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
%include "compiler/parser/block_comment.inc"
%include "compiler/lexer/interpolation_tokens.inc"
extern neboc_token_keyword_kind
extern neboc_numeric_literal_contract_scan
extern neboc_char_literal_contract_scan

section .text
; lexer_scan(LexerRequest*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_lexer_scan
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,LEX_INTERP_STACK_SIZE
 mov qword [rsp+LEX_INTERP_DEPTH],0
 mov qword [rsp+LEX_INTERP_PENDING],0
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_LEXER_REQUEST_SOURCE_OFFSET]
 mov r14,[r12+NEBOC_LEXER_REQUEST_LENGTH_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],1
 jb .invalid
 mov qword [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],0
 mov qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 mov qword [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],0
 xor r15d,r15d
 xor ebx,ebx
 ; Strict UTF-8 is a source invariant, including bytes hidden inside Text and
 ; comments.  Security policy for valid scalars remains lexical-context aware:
 ; literal/comment content is preserved byte-for-byte, while source syntax is
 ; classified below without normalization.
 mov rdi,r13
 mov rsi,r14
 call lexer_validate_utf8_source
 test eax,eax
 jz .loop
 mov r11,rdx
 lea r15,[rdx+1]
 mov r10d,NEBOC_TOKEN_INVALID_IDENTIFIER
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_MALFORMED_UTF8
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 mov [rsp+160],r14
 jmp .emit

.loop:
 cmp r15,r14
 jae .emit_eof
 mov qword [rsp+8],0
 mov qword [rsp+160],0
 mov qword [rsp+168],0
 movzx eax,byte [r13+r15]
 cmp al,32
 je .skip_one
 cmp al,9
 je .skip_one
 cmp al,10
 je .skip_one
 cmp al,13
 je .skip_one
 cmp al,'r'
 jne .not_raw_text
 lea rax,[r15+1]
 cmp rax,r14
 jae .not_raw_text
 cmp byte [r13+r15+1],'"'
 je .raw_text
.not_raw_text:
 movzx eax,byte [r13+r15]
 cmp al,'0'
 jb .not_digit
 cmp al,'9'
 jbe .integer
.not_digit:
 cmp al,39
 je .char
 cmp al,'"'
 jne .not_text
 lea rax,[r15+3]
 cmp rax,r14
 ja .text
 cmp byte [r13+r15+1],'"'
 jne .text
 cmp byte [r13+r15+2],'"'
 je .multiline_text
 jmp .text
.not_text:
 ; G164 activates nested block comments before the G144 reservation table.
 ; The canonical scanner consumes trivia without producing semantic tokens.
 cmp al,'/'
 jne .not_active_block_comment
 lea rax,[r15+1]
 cmp rax,r14
 jae .not_active_block_comment
 cmp byte [r13+r15+1],'*'
 jne .not_active_block_comment
 mov [rsp],r15
 lea rdi,[r13+r15]
 mov rsi,r14
 sub rsi,r15
 lea rdx,[rsp+176]
 call neboc_block_comment_lexer
 test eax,eax
 jnz .active_block_comment_error
 add r15,[rsp+176+NEBOC_BLOCK_RESULT_CONSUMED_OFFSET]
 jmp .loop
.active_block_comment_error:
 mov r11,[rsp]
 mov r15,r14
 mov r10d,NEBOC_TOKEN_INVALID_BLOCK_COMMENT
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_UNTERMINATED_BLOCK_COMMENT
 cmp eax,NEBOC_COMMENT_STATUS_DEPTH
 jne .active_block_comment_emit
 mov qword [rsp+8],NEBOC_LEX_DIAG_BLOCK_COMMENT_DEPTH
.active_block_comment_emit:
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.not_active_block_comment:
 ; G145 REJECTED forms are classified before G144 RESERVED symbols so maximal
 ; munch selects `|>`, `<->`, `**`, `<>`, `=>` and the other terminal
 ; spellings as one diagnostic token.  Context checks below protect every
 ; active canonical substrate.
 call lexer_g145_rejected_at
 test eax,eax
 jz .not_g145_rejected
 mov r11,r15
 add r15,rcx
 mov r10d,NEBOC_TOKEN_REJECTED_FORM
 mov r9,rax
 shl r9,NEBOC_TOKEN_FLAG_REJECTED_ID_SHIFT
 or r9,NEBOC_TOKEN_FLAG_REJECTED|NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_REJECTED_FORM
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.not_g145_rejected:
 ; G144 reservations are source syntax, not executable operators.  Check the
 ; exact spelling before generic ASCII/Unicode classification, while Text,
 ; Char, raw Text and line-comment bodies remain owned by their lexical paths.
 call lexer_g144_reserved_at
 test eax,eax
 jz .not_g144_reserved
 mov r11,r15
 add r15,rcx
 mov r10d,NEBOC_TOKEN_RESERVED_SYMBOL
 mov r9,rax
 shl r9,NEBOC_TOKEN_FLAG_RESERVED_ID_SHIFT
 or r9,NEBOC_TOKEN_FLAG_RESERVED|NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_RESERVED_SYMBOL
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.not_g144_reserved:
 movzx eax,byte [r13+r15]
 cmp al,0x80
 jae .unicode_identifier
 cmp al,'A'
 jb .operators
 cmp al,'Z'
 jbe .identifier
 cmp al,'a'
 jb .underscore
 cmp al,'z'
 jbe .identifier
.underscore:
 cmp al,'_'
 jne .operators
 lea rax,[r15+1]
 cmp rax,r14
 jae .operators
 movzx eax,byte [r13+r15+1]
 cmp al,'0'
 jb .underscore_letter
 cmp al,'9'
 jbe .identifier
.underscore_letter:
 cmp al,'A'
 jb .underscore_lower
 cmp al,'Z'
 jbe .identifier
.underscore_lower:
 cmp al,'a'
 jb .underscore_repeat
 cmp al,'z'
 jbe .identifier
.underscore_repeat:
 cmp al,'_'
 je .identifier
 jmp .operators

.identifier:
 mov r11,r15
 mov [rsp],r11
 inc r15
.id_continue:
 cmp r15,r14
 jae .id_done
 movzx eax,byte [r13+r15]
 cmp al,'A'
 jb .id_digit
 cmp al,'Z'
 jbe .id_take
 cmp al,'a'
 jb .id_underscore
 cmp al,'z'
 jbe .id_take
.id_digit:
 cmp al,'0'
 jb .id_done
 cmp al,'9'
 jbe .id_take
.id_underscore:
 cmp al,'_'
 jne .id_done
.id_take:
 inc r15
 jmp .id_continue
.id_done:
 mov r11,[rsp]
 lea rdi,[r13+r11]
 mov rsi,r15
 sub rsi,r11
 call neboc_token_keyword_kind
 mov r11,[rsp]
 test eax,eax
 jnz .id_keyword
 mov r10d,NEBOC_TOKEN_IDENTIFIER
 xor r9d,r9d
 jmp .emit
.id_keyword:
 mov r10d,eax
 xor r9d,r9d
 cmp r10d,NEBOC_TOKEN_INFINITY
 je .id_math_infinity
 cmp r10d,NEBOC_TOKEN_PI
 je .id_math_pi
 cmp r10d,NEBOC_TOKEN_TAU
 je .id_math_tau
 cmp r10d,NEBOC_TOKEN_KW_FOR
 jb .emit
 cmp r10d,NEBOC_TOKEN_KW_DEFER
 ja .emit
 cmp r10d,NEBOC_TOKEN_KW_FOR
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_WHILE
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_LOOP
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_BREAK
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_CONTINUE
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_DO
 je .emit
 cmp r10d,NEBOC_TOKEN_KW_DEFER
 je .emit
 mov r9d,NEBOC_TOKEN_FLAG_DEFERRED
 jmp .emit
.id_math_infinity:
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_005
 mov [rsp+8],rax
 jmp .emit
.id_math_pi:
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_006
 mov [rsp+8],rax
 jmp .emit
.id_math_tau:
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_007
 mov [rsp+8],rax
 jmp .emit

.unicode_identifier:
 ; G131's exact U+00B1 constructor is classified before either mathematical
 ; atoms or identifier fallback.  A lookalike can therefore never inherit its
 ; domain gate through normalization.
 mov r11,r15
 lea rax,[r15+2]
 cmp rax,r14
 ja .unicode_math_three
 cmp byte [r13+r15],0xc2
 jne .unicode_math_two
 cmp byte [r13+r15+1],0xb1
 jne .unicode_math_two
 add r15,2
 mov r10d,NEBOC_TOKEN_PLUS_MINUS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_010
 mov [rsp+8],rax
 jmp .emit
.unicode_math_two:
 ; G134 U+00B7 is a distinct linear product atom.  U+00D7 remains the
 ; shared Set/Vector atom and is disambiguated by the semantic owner.
 cmp byte [r13+r15],0xc2
 jne .unicode_math_two_c3
 cmp byte [r13+r15+1],0xb7
 jne .unicode_math_three
 add r15,2
 mov r10d,NEBOC_TOKEN_LINEAR_DOT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_036
 mov [rsp+8],rax
 jmp .emit
.unicode_math_two_c3:
 ; G130 mathematical symbols are exact atoms.  No normalization or
 ; identifier fallback is permitted for these Registry spellings.
 cmp byte [r13+r15],0xc3
 jne .unicode_math_greek
 cmp byte [r13+r15+1],0x97
 jne .unicode_math_three
 add r15,2
 mov r10d,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_034
 mov [rsp+8],rax
 jmp .emit
.unicode_math_greek:
 cmp byte [r13+r15],0xce
 jne .unicode_math_greek_cf
 cmp byte [r13+r15+1],0x94
 jne .unicode_math_three
 add r15,2
 mov r10d,NEBOC_TOKEN_LAPLACIAN
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_057
 mov [rsp+8],rax
 jmp .emit
.unicode_math_greek_cf:
 cmp byte [r13+r15],0xcf
 jne .unicode_math_three
 cmp byte [r13+r15+1],0x80
 je .unicode_pi
 cmp byte [r13+r15+1],0x84
 jne .unicode_math_three
 add r15,2
 mov r10d,NEBOC_TOKEN_TAU
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_007
 mov [rsp+8],rax
 jmp .emit
.unicode_pi:
 add r15,2
 mov r10d,NEBOC_TOKEN_PI
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_006
 mov [rsp+8],rax
 jmp .emit
.unicode_math_three:
 ; G141 U+29FA DOUBLE PLUS is the exact Text-concatenation Registry atom.
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_g137_compound
 cmp byte [r13+r15],0xe2
 jne .unicode_g137_compound
 cmp byte [r13+r15+1],0xa7
 jne .unicode_g137_compound
 cmp byte [r13+r15+2],0xba
 jne .unicode_g137_compound
 add r15,3
 mov r10d,NEBOC_TOKEN_TEXT_CONCAT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_TEXT_PATTERN
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_074
 mov [rsp+8],rax
 jmp .emit
.unicode_g137_compound:
 ; G137 compound vector-calculus forms use maximal munch.  Match the complete
 ; U+2207 U+00B7/U+00D7 spelling before the single gradient atom.
 lea rax,[r15+5]
 cmp rax,r14
 ja .unicode_matrix_compound_done
 cmp byte [r13+r15],0xe2
 jne .unicode_matrix_compound_done
 cmp byte [r13+r15+1],0x88
 jne .unicode_matrix_compound_done
 cmp byte [r13+r15+2],0x87
 jne .unicode_matrix_compound_done
 cmp byte [r13+r15+3],0xc2
 je .unicode_divergence_tail
 cmp byte [r13+r15+3],0xc3
 jne .unicode_matrix_compound_done
 cmp byte [r13+r15+4],0x97
 jne .unicode_matrix_compound_done
 add r15,5
 mov r10d,NEBOC_TOKEN_CURL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_056
 mov [rsp+8],rax
 jmp .emit
.unicode_divergence_tail:
 cmp byte [r13+r15+4],0xb7
 jne .unicode_matrix_compound_done
 add r15,5
 mov r10d,NEBOC_TOKEN_DIVERGENCE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_055
 mov [rsp+8],rax
 jmp .emit
.unicode_matrix_compound_done:
 ; G135 has one two-code-point lexeme.  Match all five UTF-8 bytes before
 ; any single-code-point dispatch so `⁻¹` is one maximal-munch token.
 lea rax,[r15+5]
 cmp rax,r14
 ja .unicode_matrix_single
 cmp byte [r13+r15],0xe2
 jne .unicode_matrix_single
 cmp byte [r13+r15+1],0x81
 jne .unicode_matrix_single
 cmp byte [r13+r15+2],0xbb
 jne .unicode_matrix_single
 cmp byte [r13+r15+3],0xc2
 jne .unicode_matrix_single
 cmp byte [r13+r15+4],0xb9
 jne .unicode_matrix_single
 add r15,5
 mov r10d,NEBOC_TOKEN_MATRIX_INVERSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_043
 mov [rsp+8],rax
 jmp .emit
.unicode_matrix_single:
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_quantity_start
 ; U+1D40 modifier-letter capital T is the exact Registry transpose atom.
 cmp byte [r13+r15],0xe1
 jne .unicode_matrix_e2
 cmp byte [r13+r15+1],0xb5
 jne .unicode_quantity_start
 cmp byte [r13+r15+2],0x80
 jne .unicode_quantity_start
 add r15,3
 mov r10d,NEBOC_TOKEN_MATRIX_TRANSPOSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_041
 mov [rsp+8],rax
 jmp .emit
.unicode_matrix_e2:
 cmp byte [r13+r15],0xe2
 jne .unicode_quantity_start
 cmp byte [r13+r15+1],0x8a
 je .unicode_set_relation
 cmp byte [r13+r15+1],0x96
 je .unicode_set_triangle
 cmp byte [r13+r15+1],0x89
 je .unicode_relation_equality
 cmp byte [r13+r15+1],0x9f
 je .unicode_linear_angle_or_orthogonal
 cmp byte [r13+r15+1],0xab
 je .unicode_probability_independence
 cmp byte [r13+r15+1],0x87
 je .unicode_formal_arrow
 cmp byte [r13+r15+1],0x86
 je .unicode_graph_short_arrow
 cmp byte [r13+r15+1],0x80
 je .unicode_matrix_punctuation
 cmp byte [r13+r15+1],0x88
 jne .unicode_math_delimiter
 mov al,[r13+r15+2]
 cmp al,0x82
 je .unicode_partial_derivative
 cmp al,0x80
 je .unicode_for_all
 cmp al,0x83
 je .unicode_exists
 cmp al,0x84
 je .unicode_not_exists
 cmp al,0x87
 je .unicode_gradient
 cmp al,0xa3
 je .unicode_divides
 cmp al,0xa4
 je .unicode_not_divides
 cmp al,0x9d
 je .unicode_proportional
 cmp al,0x9a
 je .unicode_square_root
 cmp al,0x9b
 je .unicode_cube_root
 cmp al,0x9c
 je .unicode_fourth_root
 cmp al,0x91
 je .unicode_reduction_sum
 cmp al,0x8f
 je .unicode_reduction_product
 cmp al,0xab
 je .unicode_integral_single
 cmp al,0xac
 je .unicode_integral_double
 cmp al,0xad
 je .unicode_integral_triple
 cmp al,0xae
 je .unicode_integral_contour
 cmp al,0x85
 je .unicode_empty_set
 cmp al,0x88
 je .unicode_set_membership
 cmp al,0x89
 je .unicode_set_non_membership
 cmp al,0x96
 je .unicode_set_difference
 cmp al,0xa9
 je .unicode_set_intersection
 cmp al,0xaa
 je .unicode_set_union
 cmp al,0x98
 je .unicode_linear_compose
 cmp al,0xa5
 je .unicode_linear_parallel
 cmp al,0xbc
 je .unicode_probability_distributed
 cmp al,0x9e
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_INFINITY
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_005
 mov [rsp+8],rax
 jmp .emit
.unicode_integral_single:
 add r15,3
 mov r10d,NEBOC_TOKEN_INTEGRAL_SINGLE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_049
 mov [rsp+8],rax
 jmp .emit
.unicode_integral_double:
 add r15,3
 mov r10d,NEBOC_TOKEN_INTEGRAL_DOUBLE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_050
 mov [rsp+8],rax
 jmp .emit
.unicode_integral_triple:
 add r15,3
 mov r10d,NEBOC_TOKEN_INTEGRAL_TRIPLE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_051
 mov [rsp+8],rax
 jmp .emit
.unicode_integral_contour:
 add r15,3
 mov r10d,NEBOC_TOKEN_INTEGRAL_CONTOUR
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_052
 mov [rsp+8],rax
 jmp .emit
.unicode_partial_derivative:
 add r15,3
 mov r10d,NEBOC_TOKEN_PARTIAL_DERIVATIVE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_053
 mov [rsp+8],rax
 jmp .emit
.unicode_gradient:
 add r15,3
 mov r10d,NEBOC_TOKEN_GRADIENT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_CALCULUS
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_054
 mov [rsp+8],rax
 jmp .emit
.unicode_probability_distributed:
 add r15,3
 mov r10d,NEBOC_TOKEN_DISTRIBUTED_AS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_PROBABILITY
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_058
 mov [rsp+8],rax
 jmp .emit
.unicode_probability_independence:
 cmp byte [r13+r15+2],0xab
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_INDEPENDENT_OF
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_PROBABILITY
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_059
 mov [rsp+8],rax
 jmp .emit
.unicode_formal_arrow:
 mov al,[r13+r15+2]
 cmp al,0x92
 je .unicode_logic_implies
 cmp al,0x94
 je .unicode_logic_iff
 cmp al,0xa2
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_GRAPH_ASYNC
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_GRAPH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_072
 mov [rsp+8],rax
 jmp .emit
.unicode_logic_iff:
 add r15,3
 mov r10d,NEBOC_TOKEN_LOGIC_IFF
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_065
 mov [rsp+8],rax
 jmp .emit
.unicode_graph_short_arrow:
 mov al,[r13+r15+2]
 cmp al,0x92
 je .unicode_graph_directed
 cmp al,0x94
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_GRAPH_BIDIRECTIONAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_GRAPH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_071
 mov [rsp+8],rax
 jmp .emit
.unicode_graph_directed:
 add r15,3
 mov r10d,NEBOC_TOKEN_GRAPH_DIRECTED
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_GRAPH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_070
 mov [rsp+8],rax
 jmp .emit
.unicode_logic_implies:
 add r15,3
 mov r10d,NEBOC_TOKEN_LOGIC_IMPLIES
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_064
 mov [rsp+8],rax
 jmp .emit
.unicode_for_all:
 add r15,3
 mov r10d,NEBOC_TOKEN_FOR_ALL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_061
 mov [rsp+8],rax
 jmp .emit
.unicode_exists:
 add r15,3
 mov r10d,NEBOC_TOKEN_EXISTS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_062
 mov [rsp+8],rax
 jmp .emit
.unicode_not_exists:
 add r15,3
 mov r10d,NEBOC_TOKEN_NOT_EXISTS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_063
 mov [rsp+8],rax
 jmp .emit
.unicode_matrix_punctuation:
 mov al,[r13+r15+2]
 cmp al,0xa0
 je .unicode_matrix_adjoint
 cmp al,0x96
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_NORM_DELIMITER
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_044
 mov [rsp+8],rax
 jmp .emit
.unicode_matrix_adjoint:
 add r15,3
 mov r10d,NEBOC_TOKEN_MATRIX_ADJOINT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_042
 mov [rsp+8],rax
 jmp .emit
.unicode_set_relation:
 mov al,[r13+r15+2]
 cmp al,0xa2
 je .unicode_proves
 cmp al,0xa8
 je .unicode_satisfies
 cmp al,0xbc
 je .unicode_logic_nand
 cmp al,0xbd
 je .unicode_logic_nor
 cmp al,0x95
 je .unicode_linear_direct_sum
 cmp al,0x97
 je .unicode_linear_tensor_product
 cmp al,0x99
 je .unicode_linear_hadamard
 cmp al,0x82
 je .unicode_set_proper_subset
 cmp al,0x83
 je .unicode_set_proper_superset
 cmp al,0x86
 je .unicode_set_subset
 cmp al,0x87
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_SUPERSET
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_032
 mov [rsp+8],rax
 jmp .emit
.unicode_proves:
 add r15,3
 mov r10d,NEBOC_TOKEN_PROVES
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_066
 mov [rsp+8],rax
 jmp .emit
.unicode_satisfies:
 add r15,3
 mov r10d,NEBOC_TOKEN_SATISFIES
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_067
 mov [rsp+8],rax
 jmp .emit
.unicode_logic_nand:
 add r15,3
 mov r10d,NEBOC_TOKEN_LOGIC_NAND
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_068
 mov [rsp+8],rax
 jmp .emit
.unicode_logic_nor:
 add r15,3
 mov r10d,NEBOC_TOKEN_LOGIC_NOR
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_069
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_hadamard:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_HADAMARD
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_038
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_tensor_product:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_039
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_direct_sum:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_040
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_compose:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_COMPOSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_046
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_parallel:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_PARALLEL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_048
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_angle_or_orthogonal:
 mov al,[r13+r15+2]
 cmp al,0x82
 je .unicode_linear_orthogonal
 cmp al,0xb6
 je .unicode_state_transition
 cmp al,0xa8
 je .unicode_linear_inner_open
 cmp al,0xa9
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_INNER_CLOSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_045
 mov [rsp+8],rax
 jmp .emit
.unicode_state_transition:
 add r15,3
 mov r10d,NEBOC_TOKEN_STATE_TRANSITION
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_GRAPH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_073
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_inner_open:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_INNER_OPEN
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_045
 mov [rsp+8],rax
 jmp .emit
.unicode_linear_orthogonal:
 add r15,3
 mov r10d,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_LINEAR
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_047
 mov [rsp+8],rax
 jmp .emit
.unicode_set_proper_subset:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_PROPER_SUBSET
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_031
 mov [rsp+8],rax
 jmp .emit
.unicode_set_proper_superset:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_PROPER_SUPERSET
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_033
 mov [rsp+8],rax
 jmp .emit
.unicode_set_subset:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_SUBSET
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_030
 mov [rsp+8],rax
 jmp .emit
.unicode_set_triangle:
 cmp byte [r13+r15+2],0xb3
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_SYMMETRIC_DIFFERENCE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_029
 mov [rsp+8],rax
 jmp .emit
.unicode_set_membership:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_MEMBERSHIP
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_024
 mov [rsp+8],rax
 jmp .emit
.unicode_set_non_membership:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_NON_MEMBERSHIP
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_025
 mov [rsp+8],rax
 jmp .emit
.unicode_set_union:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_UNION
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_026
 mov [rsp+8],rax
 jmp .emit
.unicode_set_intersection:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_INTERSECTION
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_027
 mov [rsp+8],rax
 jmp .emit
.unicode_set_difference:
 add r15,3
 mov r10d,NEBOC_TOKEN_SET_DIFFERENCE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_028
 mov [rsp+8],rax
 jmp .emit
.unicode_empty_set:
 add r15,3
 mov r10d,NEBOC_TOKEN_EMPTY_SET
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_SET
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_035
 mov [rsp+8],rax
 jmp .emit
.unicode_relation_equality:
 mov al,[r13+r15+2]
 cmp al,0x88
 je .unicode_approx_equal
 cmp al,0x89
 je .unicode_not_approx_equal
 cmp al,0xa1
 jne .unicode_math_delimiter
 add r15,3
 mov r10d,NEBOC_TOKEN_EQUIVALENT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_013
 mov [rsp+8],rax
 jmp .emit
.unicode_approx_equal:
 add r15,3
 mov r10d,NEBOC_TOKEN_APPROX_EQUAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_011
 mov [rsp+8],rax
 jmp .emit
.unicode_not_approx_equal:
 add r15,3
 mov r10d,NEBOC_TOKEN_NOT_APPROX_EQUAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_012
 mov [rsp+8],rax
 jmp .emit
.unicode_divides:
 add r15,3
 mov r10d,NEBOC_TOKEN_DIVIDES
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_014
 mov [rsp+8],rax
 jmp .emit
.unicode_not_divides:
 add r15,3
 mov r10d,NEBOC_TOKEN_NOT_DIVIDES
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_015
 mov [rsp+8],rax
 jmp .emit
.unicode_proportional:
 add r15,3
 mov r10d,NEBOC_TOKEN_PROPORTIONAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_RELATION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_018
 mov [rsp+8],rax
 jmp .emit
.unicode_square_root:
 add r15,3
 mov r10d,NEBOC_TOKEN_SQUARE_ROOT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_001
 mov [rsp+8],rax
 jmp .emit
.unicode_cube_root:
 add r15,3
 mov r10d,NEBOC_TOKEN_CUBE_ROOT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_002
 mov [rsp+8],rax
 jmp .emit
.unicode_fourth_root:
 add r15,3
 mov r10d,NEBOC_TOKEN_FOURTH_ROOT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_003
 mov [rsp+8],rax
 jmp .emit
.unicode_reduction_sum:
 add r15,3
 mov r10d,NEBOC_TOKEN_REDUCTION_SUM
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_REDUCTION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_008
 mov [rsp+8],rax
 jmp .emit
.unicode_reduction_product:
 add r15,3
 mov r10d,NEBOC_TOKEN_REDUCTION_PRODUCT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_REDUCTION
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_009
 mov [rsp+8],rax
 jmp .emit
.unicode_math_delimiter:
 cmp byte [r13+r15+1],0x8c
 jne .unicode_quantity_start
 mov al,[r13+r15+2]
 cmp al,0x8a
 je .unicode_floor_open
 cmp al,0x8b
 je .unicode_floor_close
 cmp al,0x88
 je .unicode_ceil_open
 cmp al,0x89
 jne .unicode_quantity_start
 add r15,3
 mov r10d,NEBOC_TOKEN_CEIL_CLOSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_017
 mov [rsp+8],rax
 jmp .emit
.unicode_floor_open:
 add r15,3
 mov r10d,NEBOC_TOKEN_FLOOR_OPEN
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_016
 mov [rsp+8],rax
 jmp .emit
.unicode_floor_close:
 add r15,3
 mov r10d,NEBOC_TOKEN_FLOOR_CLOSE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_016
 mov [rsp+8],rax
 jmp .emit
.unicode_ceil_open:
 add r15,3
 mov r10d,NEBOC_TOKEN_CEIL_OPEN
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_MATH
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_017
 mov [rsp+8],rax
 jmp .emit
.unicode_quantity_start:
 ; G129 exact quantity suffixes are source atoms, never normalized Unicode
 ; identifiers.  Temperature spellings consume the following ASCII unit as
 ; part of the same token and preserve one contiguous byte span.
 mov r11,r15
 lea rax,[r15+2]
 cmp rax,r14
 ja .unicode_quantity_three
 cmp byte [r13+r15],0xc2
 jne .unicode_quantity_three
 cmp byte [r13+r15+1],0xb0
 jne .unicode_quantity_three
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_degree
 cmp byte [r13+r15+2],'C'
 je .unicode_celsius
 cmp byte [r13+r15+2],'F'
 je .unicode_fahrenheit
.unicode_degree:
 add r15,2
 mov r10d,NEBOC_TOKEN_DEGREE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_QUANTITY
 mov qword [rsp+8],0
 jmp .emit
.unicode_celsius:
 add r15,3
 mov r10d,NEBOC_TOKEN_CELSIUS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_QUANTITY
 mov qword [rsp+8],0
 jmp .emit
.unicode_fahrenheit:
 add r15,3
 mov r10d,NEBOC_TOKEN_FAHRENHEIT
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_QUANTITY
 mov qword [rsp+8],0
 jmp .emit
.unicode_quantity_three:
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_alias_start
 cmp byte [r13+r15],0xe2
 jne .unicode_alias_start
 cmp byte [r13+r15+1],0x80
 jne .unicode_alias_start
 cmp byte [r13+r15+2],0xb0
 je .unicode_per_mille
 cmp byte [r13+r15+2],0xb1
 jne .unicode_alias_start
 add r15,3
 mov r10d,NEBOC_TOKEN_BASIS_POINTS
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_QUANTITY
 mov qword [rsp+8],0
 jmp .emit
.unicode_per_mille:
 add r15,3
 mov r10d,NEBOC_TOKEN_PER_MILLE
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_QUANTITY
 mov qword [rsp+8],0
 jmp .emit
.unicode_alias_start:
 ; P03 aliases are exact UTF-8 spellings and retain their source spans while
 ; lowering to the already-existing ASCII semantic token kind.
 mov r11,r15
 lea rax,[r15+2]
 cmp rax,r14
 ja .unicode_arithmetic_three
 cmp byte [r13+r15],0xc2
 jne .unicode_divide
 cmp byte [r13+r15+1],0xac
 jne .unicode_divide
 add r15,2
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_NOT_ID
 jmp .emit
.unicode_divide:
 cmp byte [r13+r15],0xc3
 jne .unicode_arithmetic_three
 cmp byte [r13+r15+1],0xb7
 jne .unicode_arithmetic_three
 add r15,2
 mov r10d,NEBOC_UNICODE_ALIAS_DIVIDE_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_DIVIDE_ID
 jmp .emit
.unicode_arithmetic_three:
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_range
 cmp byte [r13+r15],0xe2
 jne .unicode_range
 cmp byte [r13+r15+1],0x8a
 jne .unicode_relational_or_arithmetic
 cmp byte [r13+r15+2],0xbb
 je .unicode_xor
.unicode_relational_or_arithmetic:
 cmp byte [r13+r15+1],0x89
 jne .unicode_arithmetic_minus
 cmp byte [r13+r15+2],0xa0
 je .unicode_not_equal
 cmp byte [r13+r15+2],0xa4
 je .unicode_less_equal
 cmp byte [r13+r15+2],0xa5
 je .unicode_greater_equal
.unicode_arithmetic_minus:
 cmp byte [r13+r15],0xe2
 jne .unicode_range
 cmp byte [r13+r15+1],0x88
 jne .unicode_range
 cmp byte [r13+r15+2],0xa7
 je .unicode_and
 cmp byte [r13+r15+2],0xa8
 je .unicode_or
 cmp byte [r13+r15+2],0x92
 jne .unicode_range
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_MINUS_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_MINUS_ID
 jmp .emit
.unicode_and:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_AND_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_AND_ID
 jmp .emit
.unicode_or:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_OR_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_OR_ID
 jmp .emit
.unicode_less_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_LESS_EQUAL_ID
 jmp .emit
.unicode_greater_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_GREATER_EQUAL_ID
 jmp .emit
.unicode_not_equal:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_EQUAL_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_NOT_EQUAL_ID
 jmp .emit
.unicode_xor:
 add r15,3
 mov r10d,NEBOC_UNICODE_ALIAS_XOR_TOKEN
 mov r9d,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 mov qword [rsp+8],NEBOC_UNICODE_ALIAS_XOR_ID
 jmp .emit
.unicode_range:
 ; U+2026 remains the sole range atom; no normalization or three-dot alias.
 lea rax,[r15+3]
 cmp rax,r14
 ja .unicode_generic
 cmp byte [r13+r15],0xe2
 jne .unicode_generic
 cmp byte [r13+r15+1],0x80
 jne .unicode_generic
 cmp byte [r13+r15+2],0xa6
 je .range_ellipsis
.unicode_generic:
 mov r11,r15
 mov [rsp],r11
 lea rdi,[r13+r15]
 mov rsi,r14
 sub rsi,r15
 lea rdx,[rsp+32]
 call neboc_unicode_operator_scan
 test eax,eax
 jnz .unicode_malformed
 mov rax,[rsp+32+NEBOC_UNICODE_SCAN_BYTE_LENGTH_OFFSET]
 add r15,rax
 mov rdi,[rsp+32+NEBOC_UNICODE_SCAN_CODEPOINT_OFFSET]
 lea rsi,[rsp+64]
 call neboc_unicode_confusable_policy
 cmp qword [rsp+64+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 je .unicode_policy_error
 mov rdi,[rsp+32+NEBOC_UNICODE_SCAN_CODEPOINT_OFFSET]
 lea rsi,[rsp+64]
 call neboc_unicode_bidi_policy
 cmp qword [rsp+64+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_BIDI
 je .unicode_policy_error
 mov rdi,[rsp+32+NEBOC_UNICODE_SCAN_CODEPOINT_OFFSET]
 lea rsi,[rsp+64]
 call neboc_unicode_invisible_policy
 cmp qword [rsp+64+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_INVISIBLE
 je .unicode_policy_error
 cmp qword [rsp+64+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_COMBINING
 je .unicode_policy_error
 jmp .unicode_done
.unicode_policy_error:
 mov rax,[rsp+64+NEBOC_UNICODE_POLICY_DIAGNOSTIC_OFFSET]
 mov [rsp+8],rax
 jmp .unicode_done
.unicode_malformed:
 inc r15
 mov qword [rsp+8],NEBOC_UNICODE_DIAG_MALFORMED_UTF8
.unicode_done:
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_INVALID_IDENTIFIER
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 cmp qword [rsp+8],0
 jne .unicode_diag_ready
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_CHARACTER
.unicode_diag_ready:
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.integer:
 mov r11,r15
 mov [rsp],r11
 ; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF005 public vertical integration. Candidate spellings containing an
 ; approved/invalid base prefix, separator, or suffix are validated by the
 ; bounded PF002 contract scanner. Ordinary decimal and strict Float spellings
 ; continue through the certified v0.1/tipos_primitivos_escalares paths below.
 lea rdi,[r13+r11]
 mov rsi,r14
 sub rsi,r11
 call lexer_candidate_length
 test rax,rax
 jz .legacy_decimal_or_float
 mov [rsp+168],rax
 lea rdi,[rsp+32]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov r11,[rsp]
 lea rax,[r13+r11]
 mov [rsp+32+NEBOC_NUMERIC_SOURCE_OFFSET],rax
 mov rax,[rsp+168]
 mov [rsp+32+NEBOC_NUMERIC_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rsp+32+NEBOC_NUMERIC_SOURCE_ID_OFFSET],rax
 mov [rsp+32+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],r11
 lea rdi,[rsp+32]
 call neboc_numeric_literal_contract_scan
 mov r11,[rsp]
 mov r15,r11
 add r15,[rsp+168]
 test eax,eax
 jnz ._numeric_error
 mov r10d,NEBOC_TOKEN_INTEGER
 mov r9,[rsp+32+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 and r9,-257
 mov rax,[rsp+32+NEBOC_NUMERIC_VALUE_OFFSET]
 mov [rsp+8],rax
 test r9,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 jz .emit
 mov rdi,r12
 mov rsi,rbx
 call lexer_minus_is_unary
 test eax,eax
 jz ._intmin_not_unary
 ; Canonicalize the unary-minus INT64_MIN path into one signed integer token.
 ; This preserves the existing Int codegen contract and prevents a second NEG.
 dec rbx
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r11,[rax+NEBOC_TOKEN_START_OFFSET]
 jmp .emit
._intmin_not_unary:
 mov qword [rsp+32+NEBOC_NUMERIC_ERROR_CODE_OFFSET],NEBOC_NUMERIC_DIAG_OVERFLOW
 mov rax,[rsp]
 mov [rsp+32+NEBOC_NUMERIC_ERROR_START_OFFSET],rax
 mov rdx,rax
 add rdx,[rsp+168]
 mov [rsp+32+NEBOC_NUMERIC_ERROR_END_OFFSET],rdx
._numeric_error:
 mov r10d,NEBOC_TOKEN_INVALID_NUMERIC_LITERAL
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov rax,[rsp+32+NEBOC_NUMERIC_ERROR_CODE_OFFSET]
 mov [rsp+8],rax
 mov rax,[rsp]
 add rax,[rsp+168]
 mov [rsp+160],rax
 mov r11,[rsp+32+NEBOC_NUMERIC_ERROR_START_OFFSET]
 mov r15,[rsp+32+NEBOC_NUMERIC_ERROR_END_OFFSET]
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.legacy_decimal_or_float:
 mov r11,[rsp]
 ; TIPOS-PRIMITIVOS-ESCALARES-PF003 strict decimal profile: [0-9]+ '.' [0-9]+.
 ; Pre-scan digits before Int accumulation so a very large integral component
 ; can still be classified as Float without producing an Int-overflow token.
 mov rax,r15
.number_digit_scan:
 cmp rax,r14
 jae .number_digits_done
 movzx ecx,byte [r13+rax]
 cmp cl,'0'
 jb .number_digits_done
 cmp cl,'9'
 ja .number_digits_done
 inc rax
 jmp .number_digit_scan
.number_digits_done:
 mov [rsp+24],rax
 cmp rax,r14
 jae .integer_accumulation_start
 cmp byte [r13+rax],'.'
 jne .integer_accumulation_start
 lea rdx,[rax+1]
 cmp rdx,r14
 jae .integer_accumulation_start
 movzx ecx,byte [r13+rdx]
 cmp cl,'0'
 jb .integer_accumulation_start
 cmp cl,'9'
 ja .integer_accumulation_start
 ; Payload packs decimal digit counts: high32=integer, low32=fraction.
 mov rcx,rax
 sub rcx,r11
 inc rax
 mov r15,rax
.float_fraction_scan:
 cmp r15,r14
 jae .float_done
 movzx edx,byte [r13+r15]
 cmp dl,'0'
 jb .float_done
 cmp dl,'9'
 ja .float_done
 inc r15
 jmp .float_fraction_scan
.float_done:
 mov rdx,r15
 sub rdx,rax
 shl rcx,32
 or rcx,rdx
 mov [rsp+8],rcx
 mov r10d,NEBOC_TOKEN_FLOAT
 xor r9d,r9d
 mov r11,[rsp]
 jmp .emit
.integer_accumulation_start:
 mov r15,r11
 xor eax,eax
.integer_loop:
 cmp r15,r14
 jae .integer_done
 movzx ecx,byte [r13+r15]
 cmp cl,'0'
 jb .integer_done
 cmp cl,'9'
 ja .integer_done
 sub ecx,'0'
 mov rdx,922337203685477580
 cmp rax,rdx
 ja .integer_overflow_consume
 jne .integer_accumulate
 cmp ecx,8
 ja .integer_overflow_consume
.integer_accumulate:
 imul rax,rax,10
 add rax,rcx
 inc r15
 jmp .integer_loop
.integer_done:
 mov [rsp+8],rax
 mov rdx,0x8000000000000000
 cmp rax,rdx
 jne .integer_regular
 test rbx,rbx
 jz .integer_overflow_emit
 mov rcx,rbx
 dec rcx
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [rcx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .integer_overflow_emit
 mov r10d,NEBOC_TOKEN_INTEGER
 mov r9d,NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE
 mov r11,[rsp]
 jmp .emit
.integer_regular:
 mov r10d,NEBOC_TOKEN_INTEGER
 xor r9d,r9d
 mov r11,[rsp]
 jmp .emit
.integer_overflow_consume:
 inc r15
.integer_overflow_more:
 cmp r15,r14
 jae .integer_overflow_emit
 movzx ecx,byte [r13+r15]
 cmp cl,'0'
 jb .integer_overflow_emit
 cmp cl,'9'
 ja .integer_overflow_emit
 inc r15
 jmp .integer_overflow_more
.integer_overflow_emit:
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_INT_OVERFLOW
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INT_OVERFLOW
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.char:
 mov r11,r15
 mov [rsp],r11
 lea rdi,[r13+r11]
 mov rsi,r14
 sub rsi,r11
 call lexer_char_candidate_length
 test rax,rax
 jz .operators
 mov [rsp+24],rax
 lea rdi,[rsp+32]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov r11,[rsp]
 lea rax,[r13+r11]
 mov [rsp+32+NEBOC_CHAR_SOURCE_OFFSET],rax
 mov rax,[rsp+24]
 mov [rsp+32+NEBOC_CHAR_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rsp+32+NEBOC_CHAR_SOURCE_ID_OFFSET],rax
 mov [rsp+32+NEBOC_CHAR_ABSOLUTE_START_OFFSET],r11
 lea rdi,[rsp+32]
 call neboc_char_literal_contract_scan
 mov r11,[rsp]
 mov r15,r11
 add r15,[rsp+24]
 test eax,eax
 jnz .char_error
 mov r10d,NEBOC_TOKEN_CHAR
 mov r9,[rsp+32+NEBOC_CHAR_TOKEN_FLAGS_OFFSET]
 and r9,~neboc_text_char_unicode_e_bytes_TOKEN_FLAG_SYNTAX_ONLY
 or r9,NEBOC_TOKEN_FLAG_CHAR_DECODED
 mov rax,[rsp+32+NEBOC_CHAR_SCALAR_OFFSET]
 mov [rsp+8],rax
 jmp .emit
.char_error:
 mov r10d,NEBOC_TOKEN_INVALID_CHAR_LITERAL
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov rax,[rsp+32+NEBOC_CHAR_DIAGNOSTIC_OFFSET]
 mov [rsp+8],rax
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit

.text:
 mov r11,r15
 mov [rsp],r11
 inc r15
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 test rax,rax
 jz .limit
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 ja .limit
 mov [rsp+16],rcx
.text_loop:
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 cmp al,'"'
 je .text_done
 cmp al,10
 je .text_unterminated
 cmp al,13
 je .text_unterminated
 cmp al,92
 je .text_escape
 cmp al,'$'
 jne .text_ordinary_byte
 lea rcx,[r15+1]
 cmp rcx,r14
 jae .text_ordinary_byte
 cmp byte [r13+rcx],'{'
 je .interpolation_begin
.text_ordinary_byte:
 mov dl,al
 inc r15
 jmp .text_append
.text_escape:
 inc r15
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 inc r15
 cmp al,'n'
 je .escape_n
 cmp al,'r'
 je .escape_r
 cmp al,'t'
 je .escape_t
 cmp al,92
 je .escape_slash
 cmp al,'"'
 je .escape_quote
 cmp al,'$'
 je .escape_interpolation_start
 jmp .text_invalid_escape
.escape_n:
 mov dl,10
 jmp .text_append
.escape_r:
 mov dl,13
 jmp .text_append
.escape_t:
 mov dl,9
 jmp .text_append
.escape_slash:
 mov dl,92
 jmp .text_append
.escape_quote:
 mov dl,'"'
 jmp .text_append
.escape_interpolation_start:
 ; `\${` is the sole dollar escape.  Decode the dollar here and let the
 ; following `{` remain literal text; a bare `\$` stays an invalid escape.
 cmp r15,r14
 jae .text_invalid_escape
 cmp byte [r13+r15],'{'
 jne .text_invalid_escape
 mov dl,'$'
.text_append:
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 jae .text_limit
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 mov [rax+rcx],dl
 inc rcx
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rcx
 jmp .text_loop
.text_done:
 cmp qword [rsp+LEX_INTERP_DEPTH],0
 je .text_plain_done
 LEX_INTERP_TOP r8
 cmp qword [r8+LEX_INTERP_STATE],3
 je .interpolation_tail
.text_plain_done:
 inc r15
 mov rax,[rsp+16]
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 sub rcx,rax
 mov edx,0xffffffff
 cmp rax,rdx
 ja .text_limit
 cmp rcx,rdx
 ja .text_limit
 shl rax,32
 mov edx,ecx
 or rax,rdx
 mov [rsp+8],rax
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_TEXT
 mov r9d,NEBOC_TOKEN_FLAG_TEXT_DECODED
 jmp .emit
.raw_text:
 mov r11,r15
 mov [rsp],r11
 mov qword [rsp+24],NEBOC_TOKEN_FLAG_TEXT_RAW
 lea rax,[r15+4]
 cmp rax,r14
 ja .raw_single_open
 cmp byte [r13+r15+1],'"'
 jne .raw_single_open
 cmp byte [r13+r15+2],'"'
 jne .raw_single_open
 cmp byte [r13+r15+3],'"'
 jne .raw_single_open
 or qword [rsp+24],NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 add r15,4
 jmp .advanced_text_pool
.raw_single_open:
 add r15,2
 jmp .advanced_text_pool

.multiline_text:
 mov r11,r15
 mov [rsp],r11
 mov qword [rsp+24],NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 add r15,3
.advanced_text_pool:
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 test rax,rax
 jz .limit
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 ja .limit
 mov [rsp+16],rcx
 test qword [rsp+24],NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 jnz .advanced_multiline_loop
.advanced_single_loop:
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 cmp al,'"'
 je .advanced_single_done
 cmp al,10
 je .text_unterminated
 cmp al,13
 je .text_unterminated
 mov dl,al
 inc r15
 jmp .advanced_text_append
.advanced_multiline_loop:
 cmp r15,r14
 jae .text_unterminated
 movzx eax,byte [r13+r15]
 cmp al,'"'
 jne .advanced_multiline_byte
 lea rax,[r15+3]
 cmp rax,r14
 ja .advanced_multiline_byte
 cmp byte [r13+r15+1],'"'
 jne .advanced_multiline_byte
 cmp byte [r13+r15+2],'"'
 je .advanced_multiline_done
.advanced_multiline_byte:
 mov dl,[r13+r15]
 inc r15
.advanced_text_append:
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET]
 jae .text_limit
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET]
 mov [rax+rcx],dl
 inc rcx
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rcx
 test qword [rsp+24],NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 jnz .advanced_multiline_loop
 jmp .advanced_single_loop
.advanced_single_done:
 inc r15
 jmp .advanced_text_done
.advanced_multiline_done:
 add r15,3
.advanced_text_done:
 mov rax,[rsp+16]
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 sub rcx,rax
 mov edx,0xffffffff
 cmp rax,rdx
 ja .text_limit
 cmp rcx,rdx
 ja .text_limit
 shl rax,32
 mov edx,ecx
 or rax,rdx
 mov [rsp+8],rax
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_TEXT
 mov r9,[rsp+24]
 or r9,NEBOC_TOKEN_FLAG_TEXT_DECODED
 test r9,NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 jz .emit
 test r9,NEBOC_TOKEN_FLAG_TEXT_RAW
 jnz .emit
 test rbx,rbx
 jz .emit
 mov rax,rbx
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .emit
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r11
 jne .emit
 or r9,NEBOC_TOKEN_FLAG_TEXT_TAGGED
 jmp .emit
.text_invalid_escape:
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
.text_invalid_scan:
 cmp r15,r14
 jae .text_invalid_emit
 mov al,[r13+r15]
 cmp al,10
 je .text_invalid_emit
 cmp al,13
 je .text_invalid_emit
 inc r15
 cmp al,'"'
 jne .text_invalid_scan
.text_invalid_emit:
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_INVALID_ESCAPE
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_ESCAPE
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.text_unterminated:
 cmp qword [rsp+LEX_INTERP_DEPTH],0
 jne .interpolation_unterminated
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
 mov r11,[rsp]
 mov r10d,NEBOC_TOKEN_UNTERMINATED_TEXT
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_UNTERMINATED_TEXT
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
.text_limit:
 mov rax,[rsp+16]
 mov [r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],rax
 jmp .limit

.operators:
 mov r11,r15
 lea rdi,[r13+r15]
 mov rsi,r14
 sub rsi,r15
 call neboc_lexer_operator_lexeme_lookup
 test eax,eax
 jz .operators_legacy
 cmp r8d,NEBOC_OPERATOR_ATOM_LINE_COMMENT
 je .registry_line_comment
 add r15,rcx
 mov r9d,r10d
 mov r10d,edx
 jmp .emit
.registry_line_comment:
 add r15,rcx
 jmp .line_comment_loop
.operators_legacy:
 movzx eax,byte [r13+r15]
 inc r15
 cmp al,'/'
 je .slash
 cmp al,'('
 je .k_lparen
 cmp al,')'
 je .k_rparen
 cmp al,'{'
 je .k_lbrace
 cmp al,'}'
 je .k_rbrace
 cmp al,','
 je .k_comma
 cmp al,';'
 je .k_semicolon
 cmp al,'.'
 je .dot
 cmp al,'+'
 je .k_plus
 cmp al,'-'
 je .minus
 cmp al,'*'
 je .k_star
 cmp al,'%'
 je .k_percent
 cmp al,'@'
 je .annotation
 cmp al,'^'
 je .k_caret
 cmp al,'?'
 je .question
 cmp al,'='
 je .equal
 cmp al,'!'
 je .bang
 cmp al,'<'
 je .less
 cmp al,'>'
 je .greater
 cmp al,'&'
 je .and
 cmp al,'|'
 je .or
 cmp al,':'
 je .k_colon
 cmp al,'['
 je .k_lbracket
 cmp al,']'
 je .k_rbracket
 jmp .invalid_char
.slash:
 cmp r15,r14
 jae .k_slash
 cmp byte [r13+r15],'/'
 je .line_comment
 jmp .k_slash
.line_comment:
 inc r15
.line_comment_loop:
 cmp r15,r14
 jae .loop
 mov al,[r13+r15]
 cmp al,10
 je .loop
 cmp al,13
 je .loop
 inc r15
 jmp .line_comment_loop
.minus:
 cmp r15,r14
 jae .k_minus
 cmp byte [r13+r15],'>'
 jne .k_minus
 inc r15
 mov r10d,NEBOC_OPERATOR_TOKEN_ARROW
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.equal:
 cmp r15,r14
 jae .k_equal
 cmp byte [r13+r15],'~'
 je .pattern_match
 cmp byte [r13+r15],'='
 jne .k_equal
 inc r15
 mov r10d,NEBOC_TOKEN_EQUAL_EQUAL
 xor r9d,r9d
 jmp .emit
.pattern_match:
 inc r15
 mov r10d,NEBOC_TOKEN_PATTERN_MATCH
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_TEXT_PATTERN
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_075
 mov [rsp+8],rax
 jmp .emit
.bang:
 cmp r15,r14
 jae .k_bang
 cmp byte [r13+r15],'~'
 je .pattern_non_match
 cmp byte [r13+r15],'='
 jne .k_bang
 inc r15
 mov r10d,NEBOC_TOKEN_BANG_EQUAL
 xor r9d,r9d
 jmp .emit
.pattern_non_match:
 inc r15
 mov r10d,NEBOC_TOKEN_PATTERN_NON_MATCH
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_TEXT_PATTERN
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_076
 mov [rsp+8],rax
 jmp .emit
.annotation:
 mov r10d,NEBOC_TOKEN_ANNOTATION
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_METADATA
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_080
 mov [rsp+8],rax
 jmp .emit
.less:
 cmp r15,r14
 jae .k_less
 lea rax,[r15+3]
 cmp rax,r14
 ja .less_not_range
 cmp byte [r13+r15],0xe2
 jne .less_not_range
 cmp byte [r13+r15+1],0x80
 jne .less_not_range
 cmp byte [r13+r15+2],0xa6
 jne .less_not_range
 add r15,3
 cmp r15,r14
 jae .range_exclusive_start
 cmp byte [r13+r15],'<'
 jne .range_exclusive_start
 inc r15
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE
 xor r9d,r9d
 jmp .emit
.range_exclusive_start:
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 xor r9d,r9d
 jmp .emit
.less_not_range:
 cmp byte [r13+r15],'='
 jne .k_less
 lea rax,[r15+1]
 cmp rax,r14
 jae .less_equal
 cmp byte [r13+r15+1],'>'
 jne .less_equal
 add r15,2
 mov r10d,NEBOC_TOKEN_SPACESHIP
 xor r9d,r9d
 jmp .emit
.less_equal:
 inc r15
 mov r10d,NEBOC_TOKEN_LESS_EQUAL
 xor r9d,r9d
 jmp .emit
.greater:
 cmp r15,r14
 jae .k_greater
 cmp byte [r13+r15],'='
 jne .k_greater
 inc r15
 mov r10d,NEBOC_TOKEN_GREATER_EQUAL
 xor r9d,r9d
 jmp .emit
.and:
 cmp r15,r14
 jae .invalid_char
 cmp byte [r13+r15],'&'
 jne .invalid_char
 inc r15
 mov r10d,NEBOC_TOKEN_AND_AND
 xor r9d,r9d
 jmp .emit
.or:
 cmp r15,r14
 jae .k_probability_conditional
 cmp byte [r13+r15],'|'
 jne .k_probability_conditional
 inc r15
 mov r10d,NEBOC_TOKEN_OR_OR
 xor r9d,r9d
 jmp .emit
.k_probability_conditional:
 mov r10d,NEBOC_TOKEN_PROBABILITY_CONDITIONAL
 mov r9d,NEBOC_TOKEN_FLAG_TYPED_PROBABILITY
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_060
 mov [rsp+8],rax
 jmp .emit
.range_ellipsis:
 mov r11,r15
 add r15,3
 cmp r15,r14
 jae .range_inclusive
 cmp byte [r13+r15],'<'
 jne .range_inclusive
 inc r15
 mov r10d,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 xor r9d,r9d
 jmp .emit
.range_inclusive:
 mov r10d,NEBOC_TOKEN_RANGE_INCLUSIVE
 xor r9d,r9d
 jmp .emit
.question:
 cmp r15,r14
 jae .k_question
 cmp byte [r13+r15],'?'
 je .question_coalesce
 cmp byte [r13+r15],'.'
 jne .k_question
 inc r15
 mov r10d,NEBOC_TOKEN_OPTIONAL_CHAIN
 xor r9d,r9d
 jmp .emit
.question_coalesce:
 inc r15
 cmp r15,r14
 jae .question_plain_coalesce
 cmp byte [r13+r15],'='
 jne .question_plain_coalesce
 inc r15
 mov r10d,NEBOC_TOKEN_OPTION_ASSIGN
 xor r9d,r9d
 jmp .emit
.question_plain_coalesce:
 mov r10d,NEBOC_TOKEN_COALESCE
 xor r9d,r9d
 jmp .emit
.dot:
 cmp r15,r14
 jae .k_dot
 cmp byte [r13+r15],'.'
 jne .k_dot
 inc r15
 mov r10d,NEBOC_TOKEN_LATERAL_FLOW
 xor r9d,r9d
 jmp .emit
%macro SIMPLE_KIND 2
.%1:
 mov r10d,%2
 xor r9d,r9d
 jmp .emit
%endmacro
SIMPLE_KIND k_lparen,NEBOC_OPERATOR_TOKEN_LPAREN
SIMPLE_KIND k_rparen,NEBOC_OPERATOR_TOKEN_RPAREN
SIMPLE_KIND k_lbrace,NEBOC_OPERATOR_TOKEN_LBRACE
SIMPLE_KIND k_rbrace,NEBOC_OPERATOR_TOKEN_RBRACE
SIMPLE_KIND k_comma,NEBOC_OPERATOR_TOKEN_COMMA
SIMPLE_KIND k_semicolon,NEBOC_OPERATOR_TOKEN_SEMICOLON
SIMPLE_KIND k_dot,NEBOC_OPERATOR_TOKEN_DOT
SIMPLE_KIND k_plus,NEBOC_TOKEN_PLUS
SIMPLE_KIND k_minus,NEBOC_TOKEN_MINUS
SIMPLE_KIND k_star,NEBOC_TOKEN_STAR
SIMPLE_KIND k_slash,NEBOC_TOKEN_SLASH
SIMPLE_KIND k_percent,NEBOC_TOKEN_PERCENT
SIMPLE_KIND k_caret,NEBOC_TOKEN_CARET
SIMPLE_KIND k_question,NEBOC_TOKEN_QUESTION
SIMPLE_KIND k_bang,NEBOC_TOKEN_BANG
SIMPLE_KIND k_less,NEBOC_OPERATOR_TOKEN_LESS
SIMPLE_KIND k_greater,NEBOC_OPERATOR_TOKEN_GREATER
.k_equal:
 mov r10d,NEBOC_TOKEN_RESERVED_EQUAL
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_colon:
 mov r10d,NEBOC_OPERATOR_TOKEN_COLON
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_lbracket:
 mov r10d,NEBOC_OPERATOR_TOKEN_LBRACKET
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.k_rbracket:
 mov r10d,NEBOC_OPERATOR_TOKEN_RBRACKET
 mov r9d,NEBOC_TOKEN_FLAG_RESERVED
 jmp .emit
.invalid_char:
 mov r10d,NEBOC_TOKEN_INVALID_CHARACTER
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_INVALID_CHARACTER
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
.emit:
 cmp qword [rsp+LEX_INTERP_DEPTH],0
 je .emit_interpolation_ready
 LEX_INTERP_TOP r8
 mov rcx,r15
 sub rcx,[r8+LEX_INTERP_QUOTE]
 dec rcx
 cmp rcx,4096
 ja .limit
 cmp qword [r8+LEX_INTERP_STATE],2
 jne .emit_interpolation_ready
 cmp r10d,NEBOC_TOKEN_LBRACE
 jne .emit_interpolation_close
 inc qword [r8+LEX_INTERP_BRACES]
 cmp qword [r8+LEX_INTERP_BRACES],LEX_INTERP_MAX_DEPTH
 ja .limit
 jmp .emit_interpolation_ready
.emit_interpolation_close:
 cmp r10d,NEBOC_TOKEN_RBRACE
 jne .emit_interpolation_ready
 dec qword [r8+LEX_INTERP_BRACES]
 jnz .emit_interpolation_ready
 mov r10d,NEBOC_TOKEN_INTERPOLATION_CLOSE
 mov qword [r8+LEX_INTERP_STATE],3
 mov qword [rsp+LEX_INTERP_PENDING],2
.emit_interpolation_ready:
 cmp rbx,[r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET]
 jae .limit
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov [rax+NEBOC_TOKEN_KIND_OFFSET],r10
 mov [rax+NEBOC_TOKEN_FLAGS_OFFSET],r9
 mov rdx,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rax+NEBOC_TOKEN_SOURCE_ID_OFFSET],rdx
 mov [rax+NEBOC_TOKEN_START_OFFSET],r11
 mov [rax+NEBOC_TOKEN_END_OFFSET],r15
 mov rdx,[rsp+8]
 mov [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 inc rbx
 mov [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rbx
 mov rdx,[rsp+160]
 test rdx,rdx
 cmovnz r15,rdx
 cmp qword [rsp+LEX_INTERP_PENDING],1
 je .interpolation_open
 cmp qword [rsp+LEX_INTERP_PENDING],2
 je .interpolation_resume_text
 jmp .loop
.skip_one:
 inc r15
 jmp .loop
.emit_eof:
 cmp qword [rsp+LEX_INTERP_DEPTH],0
 jne .interpolation_unterminated
 mov r11,r14
 mov r15,r14
 mov r10d,NEBOC_TOKEN_EOF
 xor r9d,r9d
 mov qword [rsp+8],0
 cmp rbx,[r12+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET]
 jae .limit
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov [rax+NEBOC_TOKEN_KIND_OFFSET],r10
 mov [rax+NEBOC_TOKEN_FLAGS_OFFSET],r9
 mov rdx,[r12+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET]
 mov [rax+NEBOC_TOKEN_SOURCE_ID_OFFSET],rdx
 mov [rax+NEBOC_TOKEN_START_OFFSET],r11
 mov [rax+NEBOC_TOKEN_END_OFFSET],r15
 mov qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],0
 inc rbx
 mov [r12+NEBOC_LEXER_REQUEST_COUNT_OFFSET],rbx
 mov eax,NEBOC_STATUS_OK
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,LEX_INTERP_STACK_SIZE
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

LEX_INTERPOLATION_BODY

; Validate every source byte before context-sensitive tokenization.  On
; failure, RDX is the first invalid byte offset and no caller-owned output has
; been mutated.  Valid scalar bytes are never rewritten.
lexer_validate_utf8_source:
 push rbx
 push r12
 push r13
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 xor ebx,ebx
.scan:
 cmp rbx,r13
 jae .valid
 movzx eax,byte [r12+rbx]
 test al,0x80
 jz .ascii
 lea rdi,[r12+rbx]
 mov rsi,r13
 sub rsi,rbx
 lea rdx,[rsp]
 call neboc_unicode_operator_scan
 test eax,eax
 jnz .invalid_source
 add rbx,[rsp+NEBOC_UNICODE_SCAN_BYTE_LENGTH_OFFSET]
 jmp .scan
.ascii:
 inc rbx
 jmp .scan
.valid:
 xor eax,eax
 xor edx,edx
 jmp .validate_done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 mov rdx,rbx
.validate_done:
 add rsp,32
 pop r13
 pop r12
 pop rbx
 ret

; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF005 candidate detector.
; source*, remaining -> RAX candidate length or zero for ordinary decimal/Float.
lexer_candidate_length:
 push rbx
 push r12
 push r13
 xor ebx,ebx
 xor r12d,r12d
 test rdi,rdi
 jz .candidate_none
 test rsi,rsi
 jz .candidate_none
 cmp rsi,2
 jb .candidate_loop
 cmp byte [rdi],'0'
 jne .candidate_loop
 movzx eax,byte [rdi+1]
 cmp al,'A'
 jb .candidate_prefix_lower
 cmp al,'Z'
 jbe .candidate_trigger_prefix
.candidate_prefix_lower:
 cmp al,'a'
 jb .candidate_loop
 cmp al,'z'
 jbe .candidate_trigger_prefix
 jmp .candidate_loop
.candidate_trigger_prefix:
 mov r12d,1
.candidate_loop:
 cmp rbx,rsi
 jae .candidate_done
 movzx eax,byte [rdi+rbx]
 cmp al,'0'
 jb .candidate_alpha_upper
 cmp al,'9'
 jbe .candidate_take
.candidate_alpha_upper:
 cmp al,'A'
 jb .candidate_alpha_lower
 cmp al,'Z'
 jbe .candidate_alpha
.candidate_alpha_lower:
 cmp al,'a'
 jb .candidate_underscore
 cmp al,'z'
 jbe .candidate_alpha
.candidate_underscore:
 cmp al,'_'
 je .candidate_trigger_take
 cmp al,'.'
 jne .candidate_done
 test r12d,r12d
 jz .candidate_done
 lea rax,[rbx+1]
 cmp rax,rsi
 jae .candidate_done
 movzx edx,byte [rdi+rax]
 cmp dl,'0'
 jb .candidate_done
 cmp dl,'9'
 ja .candidate_done
 inc rbx
 jmp .candidate_done
.candidate_alpha:
 ; Preserve the certified tipos_primitivos_escalares tokenization of decimal exponent-like spellings
 ; such as `1e2`: the exponent feature remains deferred, so the legacy lexer
 ; must continue producing INTEGER + IDENTIFIER rather than a literais_numericos_bases_e_representacao suffix error.
 ; Based literals (for example 0xE2) already have r12d set and still use literais_numericos_bases_e_representacao.
 cmp al,'e'
 je .candidate_maybe_legacy_exponent
 cmp al,'E'
 jne .candidate_mark_alpha
.candidate_maybe_legacy_exponent:
 test r12d,r12d
 jnz .candidate_mark_alpha
 test rbx,rbx
 jz .candidate_mark_alpha
 jmp .candidate_none
.candidate_mark_alpha:
 mov r12d,1
 jmp .candidate_take
.candidate_trigger_take:
 mov r12d,1
.candidate_take:
 inc rbx
 jmp .candidate_loop
.candidate_done:
 test r12d,r12d
 jz .candidate_none
 mov rax,rbx
 jmp .candidate_ret
.candidate_none:
 xor eax,eax
.candidate_ret:
 pop r13
 pop r12
 pop rbx
 ret

; request*, emitted_token_count -> EAX 1 when the immediately preceding minus
; is in a syntactically unary position, otherwise zero.
lexer_minus_is_unary:
 test rdi,rdi
 jz .minus_no
 test rsi,rsi
 jz .minus_no
 mov rax,rsi
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .minus_no
 cmp rsi,1
 je .minus_yes
 sub rax,NEBOC_TOKEN_SIZE
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_LPAREN
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LBRACE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_COMMA
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_SEMICOLON
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_PLUS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_MINUS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_STAR
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_SLASH
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_PERCENT
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_CARET
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_INCLUSIVE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LESS
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_GREATER
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_AND_AND
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_OR_OR
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_KW_RETURN
 je .minus_yes
 cmp rcx,NEBOC_TOKEN_RESERVED_EQUAL
 je .minus_yes
.minus_no:
 xor eax,eax
 ret
.minus_yes:
 mov eax,1
 ret

; source*, remaining -> complete Char candidate length. The closing quote is
; consumed even across a physical newline so the decoder can emit its precise
; diagnostic. An unterminated candidate consumes the remaining source.
lexer_char_candidate_length:
 test rdi,rdi
 jz .none
 test rsi,rsi
 jz .none
 cmp byte [rdi],39
 jne .none
 mov eax,1
 xor edx,edx
.loop:
 cmp rax,rsi
 jae .remaining
 mov cl,[rdi+rax]
 test edx,edx
 jnz .escaped
 cmp cl,92
 je .escape
 cmp cl,39
 je .closed
 inc rax
 jmp .loop
.escape:
 mov edx,1
 inc rax
 jmp .loop
.escaped:
 xor edx,edx
 inc rax
 jmp .loop
.closed:
 inc rax
 ret
.remaining:
 mov rax,rsi
 ret
.none:
 xor eax,eax
 ret

; G145 exact/contextual REJECTED recognizer.  Returns EAX=NSR-REJ ordinal
; (1..26), ECX=byte length, or zero/no match.  This is a syntax classifier,
; never an operator implementation: recognized forms terminate before parser,
; resolution and lowering.  Canonical uses are protected by bounded context
; checks instead of normalization or compatibility mode.
lexer_g145_rejected_at:
 xor eax,eax
 xor ecx,ecx
 cmp r15,r14
 jae .done
 movzx edx,byte [r13+r15]
 cmp dl,'|'
 je .pipe
 cmp dl,'<'
 je .less
 cmp dl,'*'
 je .star
 cmp dl,'^'
 je .caret
 cmp dl,'+'
 je .plus
 cmp dl,'-'
 je .minus
 cmp dl,'?'
 je .question
 cmp dl,':'
 je .colon
 cmp dl,','
 je .comma
 cmp dl,'='
 je .equal
 cmp dl,'!'
 je .bang
 cmp dl,'/'
 je .slash
 cmp dl,'.'
 je .dot
 cmp dl,'%'
 je .percent
 cmp dl,'a'
 je .word_and
 cmp dl,'o'
 je .word_or_or_operator
 cmp dl,'n'
 je .word_not
 cmp dl,0xc2
 je .unicode_two
 cmp dl,0xe2
 je .unicode_e2
 cmp dl,0xef
 je .unicode_fullwidth
 jmp .none

.pipe:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'>'
 jne .none
 mov eax,1
 mov ecx,2
 jmp .done

.less:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'>'
 je .legacy_not_equal
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'-'
 jne .none
 cmp byte [r13+r15+2],'>'
 jne .none
 mov eax,2
 mov ecx,3
 jmp .done
.legacy_not_equal:
 ; `Type<>` is an empty generic argument list whose arity diagnostic belongs
 ; to the type parser.  The rejected legacy not-equal form remains active in
 ; expression context (for example `5 <> 6`).
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .none
 mov eax,12
 mov ecx,2
 jmp .done

.star:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'*'
 jne .none
 mov eax,3
 mov ecx,2
 jmp .done

.caret:
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .caret_rhs
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .none
.caret_rhs:
 lea r8,[r15+1]
 call .next_nonspace
 cmp r8,r14
 jae .none
 cmp byte [r13+r8],'t'
 je .caret_rejected
 cmp byte [r13+r8],'f'
 jne .none
.caret_rejected:
 mov eax,4
 mov ecx,1
 jmp .done

.plus:
 lea r8,[r15+2]
 cmp r8,r14
 ja .plus_text
 cmp byte [r13+r15+1],'+'
 jne .plus_text
 mov eax,5
 mov ecx,2
 jmp .done
.plus_text:
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_TEXT
 jne .none
 lea r8,[r15+1]
 call .next_nonspace
 call .byte_starts_number
 test edx,edx
 jz .none
 mov eax,23
 mov ecx,1
 jmp .done

.minus:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'-'
 je .decrement
 cmp byte [r13+r15+1],'>'
 jne .none
 ; `ptr->field`-shaped adjacency is not the spaced callable/match separator.
 mov edi,1
 call .previous_token_ptr
 test rax,rax
 jz .none
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r15
 jne .none
 lea r8,[r15+2]
 call .byte_starts_identifier
 test edx,edx
 jz .none
 mov eax,18
 mov ecx,2
 jmp .done
.decrement:
 mov eax,6
 mov ecx,2
 jmp .done

.question:
 lea r8,[r15+2]
 cmp r8,r14
 ja .single_question
 cmp byte [r13+r15+1],':'
 jne .single_question
 mov eax,8
 mov ecx,2
 jmp .done
.single_question:
 ; A Boolean condition followed by a separated value is the unsupported
 ; C-style ternary marker.  Canonical postfix Option `?` remains unaffected.
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .ternary_rhs
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .none
.ternary_rhs:
 lea r8,[r15+1]
 call .next_nonspace
 call .byte_starts_value
 test edx,edx
 jz .none
 mov eax,7
 mov ecx,1
 jmp .done

.colon:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'='
 jne .none
 mov eax,9
 mov ecx,2
 jmp .done

.comma:
 ; A comma outside any open parenthesized argument/Tuple context cannot be a
 ; separator and is therefore the rejected discarding comma operator.
 call .inside_parentheses
 test edx,edx
 jnz .none
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .none
 lea r8,[r15+1]
 call .next_nonspace
 call .byte_starts_value
 test edx,edx
 jz .none
 mov eax,10
 mov ecx,1
 jmp .done

.equal:
 lea r8,[r15+2]
 cmp r8,r14
 ja .single_equal
 cmp byte [r13+r15+1],'>'
 jne .single_equal
 mov eax,16
 mov ecx,2
 jmp .done
.single_equal:
 ; Literal-to-literal single equals has no assignment target and therefore
 ; expresses the rejected equality spelling.  Identifier assignment remains
 ; owned by the canonical parser path.
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 je .equality_rhs
 cmp eax,NEBOC_TOKEN_FLOAT
 je .equality_rhs
 cmp eax,NEBOC_TOKEN_TEXT
 je .equality_rhs
 cmp eax,NEBOC_TOKEN_CHAR
 je .equality_rhs
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .equality_rhs
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .none
.equality_rhs:
 lea r8,[r15+1]
 call .next_nonspace
 call .byte_starts_value
 test edx,edx
 jz .none
 mov eax,11
 mov ecx,1
 jmp .done

.bang:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'!'
 jne .none
 mov eax,14
 mov ecx,2
 jmp .done

.slash:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'/'
 jne .none
 ; Only the compact expression `lhs//rhs` is division intent.  Spaced `//`
 ; and every comment body remain line-comment trivia.
 mov edi,1
 call .previous_token_ptr
 test rax,rax
 jz .none
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r15
 jne .none
 lea r8,[r15+2]
 call .byte_starts_number
 test edx,edx
 jz .none
 mov eax,15
 mov ecx,2
 jmp .done

.dot:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'.'
 jne .none
 cmp byte [r13+r15+2],'.'
 je .none                         ; G144 owns exact `...`
 mov edi,1
 call .previous_token_ptr
 test rax,rax
 jz .none
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .none
 cmp [rax+NEBOC_TOKEN_END_OFFSET],r15
 jne .none
 lea r8,[r15+2]
 call .byte_starts_number
 test edx,edx
 jz .none
 mov eax,17
 mov ecx,2
 jmp .done

.percent:
 lea r8,[r15+2]
 cmp r8,r14
 ja .implicit_percent
 cmp byte [r13+r15+1],'%'
 jne .implicit_percent
 mov eax,26
 mov ecx,2
 jmp .done
.implicit_percent:
 ; Number + Number% is the prohibited guessed increase operation.  Other
 ; postfix Percent and remainder contexts continue into their active owners.
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .none
 mov edi,2
 call .previous_kind
 cmp eax,NEBOC_TOKEN_PLUS
 jne .none
 mov edi,3
 call .previous_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .none
 mov eax,19
 mov ecx,1
 jmp .done

.word_and:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'n'
 jne .none
 cmp byte [r13+r15+2],'d'
 jne .none
 mov ecx,3
 jmp .logical_word

.word_or_or_operator:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 ; Distinguish exact `or` from the permanent `operator` declaration keyword.
 cmp byte [r13+r15+1],'p'
 je .word_operator
 cmp byte [r13+r15+1],'r'
 jne .none
 jmp .word_or
.word_operator:
 lea r8,[r15+8]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+2],'e'
 jne .none
 cmp byte [r13+r15+3],'r'
 jne .none
 cmp byte [r13+r15+4],'a'
 jne .none
 cmp byte [r13+r15+5],'t'
 jne .none
 cmp byte [r13+r15+6],'o'
 jne .none
 cmp byte [r13+r15+7],'r'
 jne .none
 lea r8,[r15+8]
 call .identifier_boundary
 test edx,edx
 jz .none
 mov eax,24
 mov ecx,8
 jmp .done
.word_or:
 mov ecx,2
 jmp .logical_word

.word_not:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],'o'
 jne .none
 cmp byte [r13+r15+2],'t'
 jne .none
 lea r8,[r15+3]
 call .identifier_boundary
 test edx,edx
 jz .none
 lea r8,[r15+3]
 call .next_nonspace
 call .byte_starts_value
 test edx,edx
 jz .none
 mov eax,13
 mov ecx,3
 jmp .done

.logical_word:
 mov r10,rcx
 lea r8,[r15+rcx]
 call .identifier_boundary
 test edx,edx
 jz .none
 mov edi,1
 call .previous_kind
 call .kind_ends_expression
 test edx,edx
 jz .none
 lea r8,[r15+r10]
 call .next_nonspace
 call .byte_starts_value
 test edx,edx
 jz .none
 mov eax,13
 mov rcx,r10
 jmp .done

.unicode_two:
 lea r8,[r15+2]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],0xb1
 jne .none
 ; `±` retains its active Uncertain constructor except when the resulting
 ; value is immediately projected as a Tuple through `.first`/`.second`.
 lea r8,[r15+2]
 call .ahead_has_tuple_projection
 test edx,edx
 jz .none
 mov eax,22
 mov ecx,2
 jmp .done

.unicode_e2:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],0x89
 je .unicode_approx
 cmp byte [r13+r15+1],0x88
 jne .none
 cmp byte [r13+r15+2],0xab
 jne .none
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_RESERVED_EQUAL
 jne .none
 mov eax,21
 mov ecx,3
 jmp .done
.unicode_approx:
 cmp byte [r13+r15+2],0x88
 jne .none
 mov edi,1
 call .previous_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .none
 lea r8,[r15+3]
 call .next_nonspace
 call .byte_starts_number
 test edx,edx
 jz .none
 mov eax,20
 mov ecx,3
 jmp .done

.unicode_fullwidth:
 lea r8,[r15+3]
 cmp r8,r14
 ja .none
 cmp byte [r13+r15+1],0xbc
 jne .none
 cmp byte [r13+r15+2],0x8b       ; U+FF0B FULLWIDTH PLUS SIGN
 jne .none
 mov eax,25
 mov ecx,3
 jmp .done

; EAX=kind for the EDI-th previous committed token, or zero.
.previous_kind:
 call .previous_token_ptr
 test rax,rax
 jz .previous_kind_done
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
.previous_kind_done:
 ret

; RAX=pointer for the EDI-th previous committed token, or zero.
.previous_token_ptr:
 xor eax,eax
 test edi,edi
 jz .previous_token_done
 mov r8,rbx
 cmp r8,rdi
 jb .previous_token_done
 sub r8,rdi
 imul r8,NEBOC_TOKEN_SIZE
 add r8,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov rax,r8
.previous_token_done:
 ret

; Advance R8 over ASCII source whitespace.
.next_nonspace:
.next_nonspace_loop:
 cmp r8,r14
 jae .next_nonspace_done
 mov dl,[r13+r8]
 cmp dl,32
 je .next_nonspace_take
 cmp dl,9
 je .next_nonspace_take
 cmp dl,10
 je .next_nonspace_take
 cmp dl,13
 jne .next_nonspace_done
.next_nonspace_take:
 inc r8
 jmp .next_nonspace_loop
.next_nonspace_done:
 ret

; EDX=1 when R8 begins an ASCII identifier.
.byte_starts_identifier:
 xor edx,edx
 cmp r8,r14
 jae .byte_identifier_done
 mov al,[r13+r8]
 cmp al,'A'
 jb .byte_identifier_lower
 cmp al,'Z'
 jbe .byte_identifier_yes
.byte_identifier_lower:
 cmp al,'a'
 jb .byte_identifier_under
 cmp al,'z'
 jbe .byte_identifier_yes
.byte_identifier_under:
 cmp al,'_'
 jne .byte_identifier_done
.byte_identifier_yes:
 mov edx,1
.byte_identifier_done:
 ret

; EDX=1 when R8 begins a decimal numeric value.
.byte_starts_number:
 xor edx,edx
 cmp r8,r14
 jae .byte_number_done
 movzx eax,byte [r13+r8]
 sub eax,'0'
 cmp eax,9
 ja .byte_number_done
 mov edx,1
.byte_number_done:
 ret

; EDX=1 for a bounded expression-start byte.
.byte_starts_value:
 call .byte_starts_number
 test edx,edx
 jnz .byte_value_done
 call .byte_starts_identifier
 test edx,edx
 jnz .byte_value_done
 cmp r8,r14
 jae .byte_value_done
 mov al,[r13+r8]
 cmp al,'"'
 je .byte_value_yes
 cmp al,39
 je .byte_value_yes
 cmp al,'('
 jne .byte_value_done
.byte_value_yes:
 mov edx,1
.byte_value_done:
 ret

; EDX=1 when R8 is EOF or not an identifier-continuation byte.
.identifier_boundary:
 mov edx,1
 cmp r8,r14
 jae .identifier_boundary_done
 mov al,[r13+r8]
 cmp al,'A'
 jb .identifier_boundary_lower
 cmp al,'Z'
 jbe .identifier_boundary_no
.identifier_boundary_lower:
 cmp al,'a'
 jb .identifier_boundary_digit
 cmp al,'z'
 jbe .identifier_boundary_no
.identifier_boundary_digit:
 cmp al,'0'
 jb .identifier_boundary_under
 cmp al,'9'
 jbe .identifier_boundary_no
.identifier_boundary_under:
 cmp al,'_'
 jne .identifier_boundary_done
.identifier_boundary_no:
 xor edx,edx
.identifier_boundary_done:
 ret

; EDX=1 for token kinds that can terminate the rejected expression shapes.
.kind_ends_expression:
 xor edx,edx
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_INTEGER
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_FLOAT
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_TEXT
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_CHAR
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_KW_FALSE
 je .kind_expression_yes
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .kind_expression_done
.kind_expression_yes:
 mov edx,1
.kind_expression_done:
 ret

; EDX=1 when the current token is nested in an unmatched parenthesis, bracket,
; record-literal brace, or identifier-introduced generic argument list. Commas
; in those constructs remain separators; a block brace does not hide the
; rejected discarding-comma form.
.inside_parentheses:
 xor edx,edx
 mov r8,rbx
 xor r9d,r9d
.inside_paren_loop:
 test r8,r8
 jz .inside_paren_done
 dec r8
 mov r10,r8
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
	mov r11,[r10+NEBOC_TOKEN_KIND_OFFSET]
	cmp r11,NEBOC_TOKEN_RPAREN
	je .inside_paren_right
	cmp r11,NEBOC_TOKEN_RESERVED_RBRACKET
	je .inside_paren_right
	cmp r11,NEBOC_TOKEN_RBRACE
	je .inside_paren_right
	cmp r11,NEBOC_TOKEN_GREATER
	je .inside_paren_right
	jmp .inside_paren_left
.inside_paren_right:
	inc r9d
	jmp .inside_paren_loop
.inside_paren_left:
	cmp r11,NEBOC_TOKEN_LPAREN
	je .inside_paren_open
	cmp r11,NEBOC_TOKEN_RESERVED_LBRACKET
	je .inside_paren_open
	cmp r11,NEBOC_TOKEN_LBRACE
	je .inside_brace_open
	cmp r11,NEBOC_TOKEN_LESS
	je .inside_angle_open
	jmp .inside_paren_stop
.inside_paren_open:
 test r9d,r9d
 jz .inside_paren_yes
 dec r9d
 jmp .inside_paren_loop
.inside_brace_open:
 test r9d,r9d
 jnz .inside_paren_close_nested
 ; A record literal is introduced by a type/value identifier immediately
 ; before `{`; a function/control block is not a comma-separator context.
 test r8,r8
 jz .inside_paren_done
 mov r10,r8
 dec r10
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .inside_paren_yes
 jmp .inside_paren_done
.inside_angle_open:
 test r9d,r9d
 jnz .inside_paren_close_nested
 ; Generic type arguments are introduced by an identifier immediately before
 ; `<`; an ordinary comparison does not create a comma-separator context.
 test r8,r8
 jz .inside_paren_done
 mov r10,r8
 dec r10
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .inside_paren_yes
 jmp .inside_paren_done
.inside_paren_close_nested:
 dec r9d
 jmp .inside_paren_loop
.inside_paren_stop:
 cmp r11,NEBOC_TOKEN_SEMICOLON
 jne .inside_paren_loop
 jmp .inside_paren_done
.inside_paren_yes:
 mov edx,1
.inside_paren_done:
 ret

; EDX=1 if the bounded remainder contains `).first` or `).second` before the
; next semicolon.  This distinguishes Tuple reinterpretation from valid
; Uncertain observers without inspecting filenames or whole fixtures.
.ahead_has_tuple_projection:
 xor edx,edx
 mov r9,r8
 mov r10d,96
.ahead_projection_loop:
 cmp r9,r14
 jae .ahead_projection_done
 test r10d,r10d
 jz .ahead_projection_done
 cmp byte [r13+r9],';'
 je .ahead_projection_done
 cmp byte [r13+r9],'.'
 jne .ahead_projection_next
 lea r11,[r9+6]
 cmp r11,r14
 ja .ahead_second
 cmp byte [r13+r9+1],'f'
 jne .ahead_second
 cmp byte [r13+r9+2],'i'
 jne .ahead_second
 cmp byte [r13+r9+3],'r'
 jne .ahead_second
 cmp byte [r13+r9+4],'s'
 jne .ahead_second
 cmp byte [r13+r9+5],'t'
 je .ahead_projection_yes
.ahead_second:
 lea r11,[r9+7]
 cmp r11,r14
 ja .ahead_projection_next
 cmp byte [r13+r9+1],'s'
 jne .ahead_projection_next
 cmp byte [r13+r9+2],'e'
 jne .ahead_projection_next
 cmp byte [r13+r9+3],'c'
 jne .ahead_projection_next
 cmp byte [r13+r9+4],'o'
 jne .ahead_projection_next
 cmp byte [r13+r9+5],'n'
 jne .ahead_projection_next
 cmp byte [r13+r9+6],'d'
 je .ahead_projection_yes
.ahead_projection_next:
 inc r9
 dec r10d
 jmp .ahead_projection_loop
.ahead_projection_yes:
 mov edx,1
.ahead_projection_done:
 ret

.none:
 xor eax,eax
 xor ecx,ecx
.done:
 ret

; Internal live-lexer instantiation of the generated Registry recognizer.
; Keeping the body shared with operator_lexeme_trie.asm prevents drift while
; avoiding a new link dependency for every bounded lexer test.
;
; G144 exact RESERVED recognizer.  R13/R14/R15 are the live source, length and
; cursor; R12/RBX are the request and number of already committed tokens.
; Returns EAX=NSR-RES ordinal (1..23), ECX=byte length, or zero/no match.
; The recognizer runs only at token boundaries after literal dispatch, so it
; cannot inspect or normalize bytes inside Text/Char literals.
lexer_g144_reserved_at:
 xor eax,eax
 xor ecx,ecx
 cmp r15,r14
 jae .done
 movzx edx,byte [r13+r15]
 cmp dl,'<'
 je .less
 cmp dl,'>'
 je .greater
 cmp dl,'.'
 je .dot
 cmp dl,':'
 je .colon
 cmp dl,'#'
 je .hash
 cmp dl,'$'
 je .dollar
 cmp dl,96
 je .backtick
 cmp dl,'/'
 je .slash
 cmp dl,'&'
 je .ampersand
 cmp dl,'|'
 je .pipe
 cmp dl,'~'
 je .tilde
 cmp dl,'*'
 je .star
 cmp dl,'['
 je .index
 cmp dl,0xce
 je .lambda
 cmp dl,0xe2
 je .unicode_e2
 jmp .done

.less:
 lea r8,[r15+1]
 cmp r8,r14
 jae .done
 mov dl,[r13+r15+1]
 cmp dl,'.'
 jne .less_shift
 mov eax,1
 mov ecx,2
 lea r8,[r15+2]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+2],'>'
 jne .done
 mov eax,2
 mov ecx,3
 jmp .done
.less_shift:
 cmp dl,'<'
 jne .none
 mov eax,13
 mov ecx,2
 jmp .done

.greater:
 lea r8,[r15+1]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],'>'
 jne .none
 ; Two adjacent core `>` delimiters close nested generic types.  Count the
 ; unmatched core `<` delimiters already emitted in this statement before
 ; classifying the same bytes as the reserved shift-right spelling.
 xor r8d,r8d
 xor r9d,r9d
.greater_context_loop:
 cmp r8,rbx
 jae .greater_context_done
 mov r10,r8
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r10,[r10+NEBOC_TOKEN_KIND_OFFSET]
 cmp r10,NEBOC_OPERATOR_TOKEN_LESS
 jne .greater_context_close
 inc r9
 jmp .greater_context_next
.greater_context_close:
 cmp r10,NEBOC_OPERATOR_TOKEN_GREATER
 jne .greater_context_next
 test r9,r9
 jz .greater_context_next
 dec r9
.greater_context_next:
 inc r8
 jmp .greater_context_loop
.greater_context_done:
 cmp r9,2
 jae .none
 mov eax,14
 mov ecx,2
 jmp .done

.dot:
 lea r8,[r15+2]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],'.'
 jne .none
 cmp byte [r13+r15+2],'.'
 jne .none
 mov eax,3
 mov ecx,3
 jmp .done

.colon:
 lea r8,[r15+1]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],':'
 jne .numeric_slice
 mov eax,4
 mov ecx,2
 jmp .done
.numeric_slice:
 ; A numeric slice begins after a committed integer token. The final digit
 ; of an identifier (field7:18 or width2:8) is not a numeric left operand.
 test rbx,rbx
 jz .none
 lea r8,[rbx-1]
 imul r8,NEBOC_TOKEN_SIZE
 add r8,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [r8+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .none
 cmp [r8+NEBOC_TOKEN_END_OFFSET],r15
 jne .none
 movzx r8d,byte [r13+r15+1]
 sub r8d,'0'
 cmp r8d,9
 ja .none
 mov eax,16
 mov ecx,1
 jmp .done

.hash:
 mov eax,5
 mov ecx,1
 lea r8,[r15+7]
 cmp r8,r14
 ja .done
 mov r8d,1
.hex_loop:
 cmp r8d,7
 jae .hex_boundary
 lea r9,[r13+r15]
 movzx edx,byte [r9+r8]
 cmp dl,'0'
 jb .done
 cmp dl,'9'
 jbe .hex_next
 or dl,0x20
 cmp dl,'a'
 jb .done
 cmp dl,'f'
 ja .done
.hex_next:
 inc r8d
 jmp .hex_loop
.hex_boundary:
 lea r8,[r15+7]
 cmp r8,r14
 jae .color
 movzx edx,byte [r13+r8]
 cmp dl,'0'
 jb .color
 cmp dl,'9'
 jbe .done
 cmp dl,'A'
 jb .color
 cmp dl,'Z'
 jbe .done
 cmp dl,'a'
 jb .color
 cmp dl,'z'
 jbe .done
 cmp dl,'_'
 je .done
.color:
 mov eax,6
 mov ecx,7
 jmp .done

.dollar:
 mov eax,7
 mov ecx,1
 jmp .done

.backtick:
 lea r8,[r15+1]
.backtick_scan:
 cmp r8,r14
 jae .backtick_rest
 cmp byte [r13+r8],96
 je .backtick_closed
 inc r8
 jmp .backtick_scan
.backtick_closed:
 inc r8
 mov rcx,r8
 sub rcx,r15
 mov eax,8
 jmp .done
.backtick_rest:
 mov rcx,r14
 sub rcx,r15
 mov eax,8
 jmp .done

.slash:
 lea r8,[r15+1]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],'*'
 jne .none
 lea r8,[r15+2]
.block_scan:
 cmp r8,r14
 jae .block_rest
 cmp byte [r13+r8],'*'
 jne .block_next
 lea r9,[r8+1]
 cmp r9,r14
 jae .block_rest
 cmp byte [r13+r8+1],'/'
 je .block_closed
.block_next:
 inc r8
 jmp .block_scan
.block_closed:
 add r8,2
 mov rcx,r8
 sub rcx,r15
 mov eax,9
 jmp .done
.block_rest:
 mov rcx,r14
 sub rcx,r15
 mov eax,9
 jmp .done

.ampersand:
 ; Logical AND is already active and owns its exact two-byte spelling.
 lea r8,[r15+1]
 cmp r8,r14
 jae .amp_context
 cmp byte [r13+r15+1],'&'
 je .none
.amp_context:
 call .is_prefix_context
 test edx,edx
 jz .amp_general
 lea r8,[r15+1]
 cmp r8,r14
 jae .amp_general
 movzx r8d,byte [r13+r15+1]
 cmp r8b,'A'
 jb .amp_lower
 cmp r8b,'Z'
 jbe .amp_prefix
.amp_lower:
 cmp r8b,'a'
 jb .amp_digit
 cmp r8b,'z'
 jbe .amp_prefix
.amp_digit:
 cmp r8b,'0'
 jb .amp_under
 cmp r8b,'9'
 jbe .amp_prefix
.amp_under:
 cmp r8b,'_'
 jne .amp_general
.amp_prefix:
 mov eax,17
 mov ecx,1
 jmp .done
.amp_general:
 mov eax,10
 mov ecx,1
 jmp .done

.pipe:
 ; Logical OR is an already-active two-byte core spelling and must retain the
 ; existing operator-trie owner before considering the reserved single pipe.
 lea r8,[r15+1]
 cmp r8,r14
 jae .pipe_context
 cmp byte [r13+r15+1],'|'
 je .none
.pipe_context:
 call .in_probability_context
 test edx,edx
 jnz .none
 lea r8,[r15+1]
 cmp r8,r14
 jae .pipe_general
 xor r9d,r9d
.bar_scan:
 cmp r8,r14
 jae .pipe_general
 movzx edx,byte [r13+r8]
 cmp dl,'|'
 je .bar_close
 cmp dl,'A'
 jb .bar_lower
 cmp dl,'Z'
 jbe .bar_take
.bar_lower:
 cmp dl,'a'
 jb .bar_digit
 cmp dl,'z'
 jbe .bar_take
.bar_digit:
 cmp dl,'0'
 jb .bar_under
 cmp dl,'9'
 jbe .bar_take
.bar_under:
 cmp dl,'_'
 jne .pipe_general
.bar_take:
 inc r9d
 inc r8
 jmp .bar_scan
.bar_close:
 test r9d,r9d
 jz .pipe_general
 inc r8
 mov rcx,r8
 sub rcx,r15
 mov eax,21
 jmp .done
.pipe_general:
 mov eax,11
 mov ecx,1
 jmp .done

.tilde:
 mov eax,12
 mov ecx,1
 jmp .done

.star:
 call .is_prefix_context
 test edx,edx
 jz .none
 lea r8,[r15+1]
 cmp r8,r14
 jae .none
 movzx r8d,byte [r13+r15+1]
 cmp r8b,'A'
 jb .star_lower
 cmp r8b,'Z'
 jbe .star_prefix
.star_lower:
 cmp r8b,'a'
 jb .star_under
 cmp r8b,'z'
 jbe .star_prefix
.star_under:
 cmp r8b,'_'
 jne .none
.star_prefix:
 mov eax,18
 mov ecx,1
 jmp .done

.index:
 ; Any suffix bracket after an expression-ending token is the protected
 ; expr[index] shape; a leading `[` still belongs to Array/type grammar.
 test rbx,rbx
 jz .none
 mov r8,rbx
 dec r8
 imul r8,NEBOC_TOKEN_SIZE
 add r8,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r8,[r8+NEBOC_TOKEN_KIND_OFFSET]
 cmp r8,NEBOC_TOKEN_IDENTIFIER
 je .index_match
 cmp r8,NEBOC_TOKEN_INTEGER
 je .index_match
 cmp r8,NEBOC_TOKEN_RPAREN
 je .index_match
 cmp r8,NEBOC_TOKEN_RESERVED_RBRACKET
 jne .none
.index_match:
 ; Public 1.0.1 compatibility: defer the literal-index suffix to the typed
 ; Array owner. Recognition is not general indexing activation. Nonliteral
 ; indices and slicing retain NSR-RES-015/016; semantic admission requires
 ; an immutable Array<Int,4> receiver. No source bytes are rewritten.
 lea r8,[r15+1]
.compat_space:
 cmp r8,r14
 jae .index_reserved
 movzx r9d,byte [r13+r8]
 cmp r9b,' '
 je .compat_space_next
 cmp r9b,9
 je .compat_space_next
 cmp r9b,10
 je .compat_space_next
 cmp r9b,13
 je .compat_space_next
 cmp r9b,'/'
 jne .compat_digit_start
 lea r9,[r8+1]
 cmp r9,r14
 jae .index_reserved
 cmp byte [r13+r9],'/'
 jne .index_reserved
.compat_leading_comment:
 inc r8
 cmp r8,r14
 jae .index_reserved
 cmp byte [r13+r8],10
 jne .compat_leading_comment
 jmp .compat_space_next
.compat_space_next:
 inc r8
 jmp .compat_space
.compat_digit_start:
 cmp r9b,'0'
 jb .index_reserved
 cmp r9b,'9'
 ja .index_reserved
.compat_digits:
 inc r8
 cmp r8,r14
 jae .index_reserved
 movzx r9d,byte [r13+r8]
 cmp r9b,'0'
 jb .compat_close_space
 cmp r9b,'9'
 jbe .compat_digits
 cmp r9b,'_'
 je .compat_digits
 cmp r9b,'a'
 jb .compat_upper
 cmp r9b,'f'
 jbe .compat_digits
 cmp r9b,'x'
 je .compat_digits
 cmp r9b,'o'
 je .compat_digits
.compat_upper:
 cmp r9b,'A'
 jb .compat_close_space
 cmp r9b,'F'
 jbe .compat_digits
 cmp r9b,'X'
 je .compat_digits
 cmp r9b,'O'
 je .compat_digits
.compat_close_space:
 cmp r9b,']'
 je .none
 cmp r9b,' '
 je .compat_close_next
 cmp r9b,9
 je .compat_close_next
 cmp r9b,10
 je .compat_close_next
 cmp r9b,13
 je .compat_close_next
 cmp r9b,'/'
 jne .index_reserved
 lea r9,[r8+1]
 cmp r9,r14
 jae .index_reserved
 cmp byte [r13+r9],'/'
 jne .index_reserved
.compat_trailing_comment:
 inc r8
 cmp r8,r14
 jae .index_reserved
 cmp byte [r13+r8],10
 jne .compat_trailing_comment
.compat_close_next:
 inc r8
 cmp r8,r14
 jae .index_reserved
 movzx r9d,byte [r13+r8]
 jmp .compat_close_space
.index_reserved:
 mov eax,15
 mov ecx,1
 jmp .done

.lambda:
 lea r8,[r15+1]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],0xbb
 jne .none
 mov eax,19
 mov ecx,2
 jmp .done

.unicode_e2:
 lea r8,[r15+2]
 cmp r8,r14
 jae .done
 cmp byte [r13+r15+1],0x86
 je .mapsto
 cmp byte [r13+r15+1],0x89
 je .definition
 cmp byte [r13+r15+1],0x88
 je .proof
 jmp .none
.mapsto:
 cmp byte [r13+r15+2],0xa6
 jne .none
 mov eax,20
 mov ecx,3
 jmp .done
.definition:
 cmp byte [r13+r15+2],0x94
 jne .none
 mov eax,22
 mov ecx,3
 jmp .done
.proof:
 mov dl,[r13+r15+2]
 cmp dl,0xb4
 je .proof_match
 cmp dl,0xb5
 jne .none
.proof_match:
 mov eax,23
 mov ecx,3
 jmp .done

; EDX=1 when the current token begins an expression prefix position.
.is_prefix_context:
 mov edx,1
 test rbx,rbx
 jz .prefix_done
 mov r8,rbx
 dec r8
 imul r8,NEBOC_TOKEN_SIZE
 add r8,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r8,[r8+NEBOC_TOKEN_KIND_OFFSET]
 cmp r8,NEBOC_TOKEN_LPAREN
 je .prefix_done
 cmp r8,NEBOC_TOKEN_LBRACE
 je .prefix_done
 cmp r8,NEBOC_TOKEN_COMMA
 je .prefix_done
 cmp r8,NEBOC_TOKEN_SEMICOLON
 je .prefix_done
 cmp r8,NEBOC_TOKEN_RESERVED_EQUAL
 je .prefix_done
 cmp r8,NEBOC_TOKEN_KW_RETURN
 je .prefix_done
 xor edx,edx
.prefix_done:
 ret

; EDX=1 only inside the currently-open exact P(...) probability grammar.
.in_probability_context:
 xor edx,edx
 ; A preceding probability-domain token is sufficient context for the bounded
 ; G138 lexer stream (and for domain chains) even when no P(...) call is open.
 test rbx,rbx
 jz .prob_scan
 mov r8,rbx
 dec r8
 imul r8,NEBOC_TOKEN_SIZE
 add r8,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 test qword [r8+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_TYPED_PROBABILITY
 jnz .prob_yes
.prob_scan:
 mov r8,rbx
 xor r9d,r9d
.prob_back:
 test r8,r8
 jz .prob_done
 dec r8
 mov r10,r8
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 mov r11,[r10+NEBOC_TOKEN_KIND_OFFSET]
 cmp r11,NEBOC_TOKEN_RPAREN
 jne .prob_left
 inc r9d
 jmp .prob_back
.prob_left:
 cmp r11,NEBOC_TOKEN_LPAREN
 jne .prob_back
 test r9d,r9d
 jz .prob_owner
 dec r9d
 jmp .prob_back
.prob_owner:
 test r8,r8
 jz .prob_done
 dec r8
 mov r10,r8
 imul r10,NEBOC_TOKEN_SIZE
 add r10,[r12+NEBOC_LEXER_REQUEST_TOKENS_OFFSET]
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .prob_done
 mov r11,[r10+NEBOC_TOKEN_END_OFFSET]
 sub r11,[r10+NEBOC_TOKEN_START_OFFSET]
 cmp r11,1
 jne .prob_done
 mov r11,[r10+NEBOC_TOKEN_START_OFFSET]
 cmp byte [r13+r11],'P'
 jne .prob_done
.prob_yes:
 mov edx,1
.prob_done:
 ret

.none:
 xor eax,eax
 xor ecx,ecx
.done:
 ret

align 16
neboc_lexer_operator_lexeme_lookup:
 cld
 NEBOC_OPERATOR_LEXEME_LOOKUP_BODY

; operator_lexeme_provenance(source, remaining, source_id, start, output)
; returns a status and publishes one complete record only after exact lookup.
NEBOC_ABI_FUNCTION neboc_operator_lexeme_provenance
 test rdi,rdi
 jz .provenance_invalid
 test rsi,rsi
 jz .provenance_invalid
 test r8,r8
 jz .provenance_invalid
 cmp rsi,NEBOC_OPERATOR_PROVENANCE_MAX_SOURCE_BYTES
 ja .provenance_invalid
 cmp rcx,NEBOC_OPERATOR_PROVENANCE_MAX_SOURCE_BYTES
 ja .provenance_invalid
 mov rax,NEBOC_OPERATOR_PROVENANCE_MAX_SOURCE_BYTES
 sub rax,rcx
 cmp rsi,rax
 ja .provenance_invalid
 push rbx
 push r12
 push r13
 mov rbx,r8
 mov r12,rdx
 mov r13,rcx
 call neboc_lexer_operator_lexeme_lookup
 test eax,eax
 jz .provenance_missing
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_REGISTRY_ID_OFFSET],r9
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_ATOM_INDEX_OFFSET],r8
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_SOURCE_ID_OFFSET],r12
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_START_OFFSET],r13
 mov rax,r13
 add rax,rcx
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_END_OFFSET],rax
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_BYTE_LENGTH_OFFSET],rcx
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_CODEPOINT_COUNT_OFFSET],rcx
 mov edx,NEBOC_OPERATOR_PROVENANCE_FLAG_ASCII_CANONICAL
 cmp r8d,NEBOC_OPERATOR_ATOM_DOT
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_LBRACKET
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_RBRACKET
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_LESS
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_GREATER
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_COLON
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_ARROW
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_UNDERSCORE
 je .provenance_contextual
 cmp r8d,NEBOC_OPERATOR_ATOM_LINE_COMMENT
 jne .provenance_store_flags
 or edx,NEBOC_OPERATOR_PROVENANCE_FLAG_SKIPPED
 jmp .provenance_store_flags
.provenance_contextual:
 or edx,NEBOC_OPERATOR_PROVENANCE_FLAG_CONTEXTUAL
.provenance_store_flags:
 mov [rbx+NEBOC_OPERATOR_PROVENANCE_FLAGS_OFFSET],rdx
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.provenance_missing:
 pop r13
 pop r12
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.provenance_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits

; The live lexer owns the strict scanner and syntax-security policies in the
; same object so every compiler and lexer harness executes one implementation
; without an optional link edge.  The standalone translation units remain
; available for isolated deterministic-policy compilation.
%include "compiler/source/utf8/unicode_operator_scanner.asm"
%include "compiler/source/utf8/unicode_normalization_policy.asm"
%include "compiler/source/utf8/unicode_confusable_policy.asm"
%include "compiler/source/utf8/unicode_bidi_policy.asm"
%include "compiler/source/utf8/unicode_invisible_policy.asm"
%include "compiler/diagnostics/unicode_operator_security.asm"
%include "compiler/parser/block_comment_lexer.asm"
