%ifndef NEBOC_TOKEN_KIND_INC
%define NEBOC_TOKEN_KIND_INC 1

%define NEBOC_TOKEN_INVALID 0
%define NEBOC_TOKEN_EOF 1
%define NEBOC_TOKEN_IDENTIFIER 2
%define NEBOC_TOKEN_INTEGER 3
%define NEBOC_TOKEN_TEXT 4
%define NEBOC_TOKEN_FLOAT 5
%define NEBOC_TOKEN_CHAR 6

%define NEBOC_TOKEN_KW_START 10
%define NEBOC_TOKEN_KW_IF 11
%define NEBOC_TOKEN_KW_ELSE 12
%define NEBOC_TOKEN_KW_TRUE 13
%define NEBOC_TOKEN_KW_FALSE 14
%define NEBOC_TOKEN_KW_RETURN 15

%define NEBOC_TOKEN_KW_FOR 20
%define NEBOC_TOKEN_KW_WHEN 21
%define NEBOC_TOKEN_KW_WHILE 22
%define NEBOC_TOKEN_KW_SWITCH 23
%define NEBOC_TOKEN_KW_LOOP 24
%define NEBOC_TOKEN_KW_BREAK 25
%define NEBOC_TOKEN_KW_CONTINUE 26
%define NEBOC_TOKEN_KW_MODULE 27
%define NEBOC_TOKEN_KW_IMPORT 28
%define NEBOC_TOKEN_KW_EXPORT 29
%define NEBOC_TOKEN_KW_ASYNC 30
%define NEBOC_TOKEN_KW_AWAIT 31
%define NEBOC_TOKEN_KW_MATCH 32
%define NEBOC_TOKEN_KW_STRUCT 33
%define NEBOC_TOKEN_KW_ENUM 34
%define NEBOC_TOKEN_KW_INTERFACE 35
%define NEBOC_TOKEN_KW_CLASS 36
%define NEBOC_TOKEN_KW_GENERIC 37
%define NEBOC_TOKEN_KW_DO 38
%define NEBOC_TOKEN_KW_DEFER 39
; G155 keyword-registry schema v2 is an additive reservation.  Exact lowercase
; `doc` starts semantic documentation; `docs`, case variants and occurrences in
; trivia remain ordinary identifier/comment bytes.
%define NEBOC_TOKEN_KW_DOC 40
%define NEBOC_KEYWORD_REGISTRY_SCHEMA_VERSION 2

%define NEBOC_TOKEN_LPAREN 50
%define NEBOC_TOKEN_RPAREN 51
%define NEBOC_TOKEN_LBRACE 52
%define NEBOC_TOKEN_RBRACE 53
%define NEBOC_TOKEN_COMMA 54
%define NEBOC_TOKEN_SEMICOLON 55
%define NEBOC_TOKEN_DOT 56

%define NEBOC_TOKEN_PLUS 60
%define NEBOC_TOKEN_MINUS 61
%define NEBOC_TOKEN_STAR 62
%define NEBOC_TOKEN_SLASH 63
%define NEBOC_TOKEN_PERCENT 64
%define NEBOC_TOKEN_EQUAL_EQUAL 65
%define NEBOC_TOKEN_BANG_EQUAL 66
%define NEBOC_TOKEN_LESS 67
%define NEBOC_TOKEN_LESS_EQUAL 68
%define NEBOC_TOKEN_GREATER 69
%define NEBOC_TOKEN_GREATER_EQUAL 70
%define NEBOC_TOKEN_AND_AND 71
%define NEBOC_TOKEN_OR_OR 72
%define NEBOC_TOKEN_BANG 73

%define NEBOC_TOKEN_RESERVED_EQUAL 80
%define NEBOC_TOKEN_RESERVED_COLON 81
%define NEBOC_TOKEN_RESERVED_ARROW 82
%define NEBOC_TOKEN_RESERVED_LBRACKET 83
%define NEBOC_TOKEN_RESERVED_RBRACKET 84
%define NEBOC_TOKEN_INVALID_CHARACTER 90
%define NEBOC_TOKEN_INVALID_IDENTIFIER 91
%define NEBOC_TOKEN_INT_OVERFLOW 92
%define NEBOC_TOKEN_INVALID_ESCAPE 93
%define NEBOC_TOKEN_UNTERMINATED_TEXT 94
%define NEBOC_TOKEN_INVALID_BLOCK_COMMENT 95
%define NEBOC_TOKEN_UNSUPPORTED_BLOCK_COMMENT NEBOC_TOKEN_INVALID_BLOCK_COMMENT
%define NEBOC_TOKEN_INVALID_NUMERIC_LITERAL 96
%define NEBOC_TOKEN_INVALID_CHAR_LITERAL 97
; P02 caret is power-only. There is no caret XOR interpretation.
%define NEBOC_TOKEN_CARET 98
%define NEBOC_TOKEN_XOR 99
%define NEBOC_TOKEN_SPACESHIP 100
%define NEBOC_TOKEN_QUESTION 101
%define NEBOC_TOKEN_COALESCE 102
%define NEBOC_TOKEN_OPTIONAL_CHAIN 103
%define NEBOC_TOKEN_OPTION_ASSIGN 104
%define NEBOC_TOKEN_RANGE_INCLUSIVE 105
%define NEBOC_TOKEN_RANGE_EXCLUSIVE_END 106
%define NEBOC_TOKEN_RANGE_EXCLUSIVE_START 107
%define NEBOC_TOKEN_RANGE_EXCLUSIVE 108
%define NEBOC_TOKEN_LATERAL_FLOW 109
; G129 typed-quantity postfix forms.  The five source tokens retain exact
; spelling; POSTFIX_PERCENT is an AST-only semantic token which keeps the
; existing infix remainder token stable.
%define NEBOC_TOKEN_DEGREE 110
%define NEBOC_TOKEN_PER_MILLE 111
%define NEBOC_TOKEN_BASIS_POINTS 112
%define NEBOC_TOKEN_CELSIUS 113
%define NEBOC_TOKEN_FAHRENHEIT 114
%define NEBOC_TOKEN_POSTFIX_PERCENT 115
; G130 typed-mathematics atoms.  POSTFIX_FACTORIAL is AST-only so the
; established prefix logical-not token remains stable.
%define NEBOC_TOKEN_SQUARE_ROOT 116
%define NEBOC_TOKEN_CUBE_ROOT 117
%define NEBOC_TOKEN_FOURTH_ROOT 118
%define NEBOC_TOKEN_POSTFIX_FACTORIAL 119
%define NEBOC_TOKEN_INFINITY 120
%define NEBOC_TOKEN_PI 121
%define NEBOC_TOKEN_TAU 122
%define NEBOC_TOKEN_FLOOR_OPEN 123
%define NEBOC_TOKEN_FLOOR_CLOSE 124
%define NEBOC_TOKEN_CEIL_OPEN 125
%define NEBOC_TOKEN_CEIL_CLOSE 126
; G131 typed uncertainty and mathematical-relation operators.  Each exact
; Unicode spelling keeps a distinct token so semantics never infer meaning
; from normalized identifier text.
%define NEBOC_TOKEN_PLUS_MINUS 127
%define NEBOC_TOKEN_APPROX_EQUAL 128
%define NEBOC_TOKEN_NOT_APPROX_EQUAL 129
%define NEBOC_TOKEN_EQUIVALENT 130
%define NEBOC_TOKEN_DIVIDES 131
%define NEBOC_TOKEN_NOT_DIVIDES 132
%define NEBOC_TOKEN_PROPORTIONAL 133
; G132 finite-domain reduction binders.  These retain the exact Registry
; spelling and binder fixity instead of being normalized to identifiers.
%define NEBOC_TOKEN_REDUCTION_SUM 134
%define NEBOC_TOKEN_REDUCTION_PRODUCT 135
; G133 exact Set/collection operators.  Distinct token identities preserve
; Registry provenance and allow type-directed reuse of U+00D7 by later
; vector profiles without changing its lexical atom.
%define NEBOC_TOKEN_SET_MEMBERSHIP 136
%define NEBOC_TOKEN_SET_NON_MEMBERSHIP 137
%define NEBOC_TOKEN_SET_UNION 138
%define NEBOC_TOKEN_SET_INTERSECTION 139
%define NEBOC_TOKEN_SET_DIFFERENCE 140
%define NEBOC_TOKEN_SET_SYMMETRIC_DIFFERENCE 141
%define NEBOC_TOKEN_SET_SUBSET 142
%define NEBOC_TOKEN_SET_PROPER_SUBSET 143
%define NEBOC_TOKEN_SET_SUPERSET 144
%define NEBOC_TOKEN_SET_PROPER_SUPERSET 145
%define NEBOC_TOKEN_SET_CARTESIAN_PRODUCT 146
%define NEBOC_TOKEN_EMPTY_SET 147
; G134 linear-algebra products, composition and exact geometric relations.
; U+00D7 deliberately keeps the G133 lexical token above: the semantic owner
; distinguishes Set Cartesian product from Vector3 cross product by type.
%define NEBOC_TOKEN_LINEAR_DOT 148
%define NEBOC_TOKEN_LINEAR_HADAMARD 149
%define NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT 150
%define NEBOC_TOKEN_LINEAR_DIRECT_SUM 151
%define NEBOC_TOKEN_LINEAR_COMPOSE 152
%define NEBOC_TOKEN_LINEAR_ORTHOGONAL 153
%define NEBOC_TOKEN_LINEAR_PARALLEL 154
; G135 matrix postfix and delimited linear-algebra forms.  The inverse token
; covers the complete two-code-point spelling U+207B U+00B9, so neither
; superscript can acquire an independent meaning through partial matching.
%define NEBOC_TOKEN_MATRIX_TRANSPOSE 155
%define NEBOC_TOKEN_MATRIX_ADJOINT 156
%define NEBOC_TOKEN_MATRIX_INVERSE 157
%define NEBOC_TOKEN_LINEAR_NORM_DELIMITER 158
%define NEBOC_TOKEN_LINEAR_INNER_OPEN 159
%define NEBOC_TOKEN_LINEAR_INNER_CLOSE 160
; G136 exact calculus binders.  Each Unicode spelling keeps its own token and
; Registry identity; portable named APIs converge only in the semantic owner.
%define NEBOC_TOKEN_INTEGRAL_SINGLE 161
%define NEBOC_TOKEN_INTEGRAL_DOUBLE 162
%define NEBOC_TOKEN_INTEGRAL_TRIPLE 163
%define NEBOC_TOKEN_INTEGRAL_CONTOUR 164
; G137 differential and vector-calculus forms.  Divergence and curl are
; compound maximal-munch tokens rather than a gradient followed by a product.
%define NEBOC_TOKEN_PARTIAL_DERIVATIVE 165
%define NEBOC_TOKEN_GRADIENT 166
%define NEBOC_TOKEN_DIVERGENCE 167
%define NEBOC_TOKEN_CURL 168
%define NEBOC_TOKEN_LAPLACIAN 169
; G138 typed probability notation.  The ASCII vertical bar is contextual and
; only receives semantics inside the dedicated P(...) probability grammar.
%define NEBOC_TOKEN_DISTRIBUTED_AS 170
%define NEBOC_TOKEN_INDEPENDENT_OF 171
%define NEBOC_TOKEN_PROBABILITY_CONDITIONAL 172
; G139 formal-logic domain tokens.  Proof relations remain dedicated grammar
; tokens; their presence here records exact Registry identity, not Pratt
; activation outside the formal profile.
%define NEBOC_TOKEN_FOR_ALL 173
%define NEBOC_TOKEN_EXISTS 174
%define NEBOC_TOKEN_NOT_EXISTS 175
%define NEBOC_TOKEN_LOGIC_IMPLIES 176
%define NEBOC_TOKEN_LOGIC_IFF 177
%define NEBOC_TOKEN_PROVES 178
%define NEBOC_TOKEN_SATISFIES 179
%define NEBOC_TOKEN_LOGIC_NAND 180
%define NEBOC_TOKEN_LOGIC_NOR 181
; G140 graph/workflow/statechart arrows.  These remain distinct from the
; reserved ASCII `->` token and retain their exact Unicode Registry identity.
%define NEBOC_TOKEN_GRAPH_DIRECTED 182
%define NEBOC_TOKEN_GRAPH_BIDIRECTIONAL 183
%define NEBOC_TOKEN_GRAPH_ASYNC 184
%define NEBOC_TOKEN_STATE_TRANSITION 185
; G141 Text/Pattern operators.  The three tokens retain Registry provenance;
; type resolution, domain admission and bounded execution remain separate.
%define NEBOC_TOKEN_TEXT_CONCAT 186
%define NEBOC_TOKEN_PATTERN_MATCH 187
%define NEBOC_TOKEN_PATTERN_NON_MATCH 188
; G143 declaration metadata prefix.  It has no expression precedence and is
; accepted only after the typed AnnotationRegistry admits the full grammar.
%define NEBOC_TOKEN_ANNOTATION 189
; G144 source-facing reservation token.  The exact NSR-RES ordinal is carried
; in the reserved-id flag field; the token never enters expression precedence.
%define NEBOC_TOKEN_RESERVED_SYMBOL 190
; G145 source-facing rejected-form token.  It is diagnostic-only and never
; participates in precedence, resolution, lowering or executable dispatch.
%define NEBOC_TOKEN_REJECTED_FORM 191
; Native interpolated Text preserves chunks and ordinary expression tokens.
%define NEBOC_TOKEN_INTERPOLATION_HEAD 192
%define NEBOC_TOKEN_INTERPOLATION_OPEN 193
%define NEBOC_TOKEN_INTERPOLATION_CLOSE 194
%define NEBOC_TOKEN_INTERPOLATION_TAIL 195
%define NEBOC_TOKEN_INTERPOLATION_MIDDLE 196

%define NEBOC_TOKEN_FLAG_NONE 0
%define NEBOC_TOKEN_FLAG_DEFERRED 1
%define NEBOC_TOKEN_FLAG_RESERVED 2
%define NEBOC_TOKEN_FLAG_ERROR 4
%define NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE 8
%define NEBOC_TOKEN_FLAG_TEXT_DECODED 16

; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF002/PF003 provisional numeric-literal provenance contract. These flags
; are consumed by the isolated scanner, parser goldens and semantic/IR model.
; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF005 promotes these provenance flags into the public lexer while preserving
; the same bit assignments and clearing literais_numericos_bases_e_representacao_SYNTAX_ONLY on accepted tokens.
%define NEBOC_TOKEN_FLAG_INT_BASE_BINARY 32
%define NEBOC_TOKEN_FLAG_INT_BASE_OCTAL 64
%define NEBOC_TOKEN_FLAG_INT_BASE_HEX 96
%define NEBOC_TOKEN_FLAG_INT_BASE_MASK 96
%define NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR 128
%define neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY 256
%define NEBOC_TOKEN_FLAG_CHAR_DECODED 512
; Exact source spelling provenance; semantic token kinds remain unchanged.
%define NEBOC_TOKEN_FLAG_UNICODE_ALIAS 1024
; G063 advanced Text literal provenance.  All forms retain the canonical Text
; token kind while the parser can distinguish raw, multiline and tagged input.
%define NEBOC_TOKEN_FLAG_TEXT_RAW 2048
%define NEBOC_TOKEN_FLAG_TEXT_MULTILINE 4096
%define NEBOC_TOKEN_FLAG_TEXT_TAGGED 8192
%define NEBOC_TOKEN_FLAG_TYPED_QUANTITY 16384
%define NEBOC_TOKEN_FLAG_TYPED_MATH 32768
%define NEBOC_TOKEN_FLAG_TYPED_RELATION 65536
%define NEBOC_TOKEN_FLAG_TYPED_REDUCTION 131072
%define NEBOC_TOKEN_FLAG_TYPED_SET 262144
%define NEBOC_TOKEN_FLAG_TYPED_LINEAR 524288
%define NEBOC_TOKEN_FLAG_TYPED_MATRIX_POSTFIX 1048576
%define NEBOC_TOKEN_FLAG_TYPED_CALCULUS 2097152
%define NEBOC_TOKEN_FLAG_TYPED_PROBABILITY 4194304
%define NEBOC_TOKEN_FLAG_TYPED_FORMAL_LOGIC 8388608
%define NEBOC_TOKEN_FLAG_TYPED_GRAPH 16777216
%define NEBOC_TOKEN_FLAG_TYPED_TEXT_PATTERN 33554432
%define NEBOC_TOKEN_FLAG_TYPED_METADATA 67108864
%define NEBOC_TOKEN_FLAG_RESERVED_ID_SHIFT 32
%define NEBOC_TOKEN_FLAG_RESERVED_ID_MASK 0x000000ff00000000
%define NEBOC_TOKEN_FLAG_REJECTED 134217728
%define NEBOC_TOKEN_FLAG_REJECTED_ID_SHIFT 40
%define NEBOC_TOKEN_FLAG_REJECTED_ID_MASK 0x0000ff0000000000

%endif
