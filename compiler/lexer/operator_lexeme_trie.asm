; Bounded maximal-munch recognizer for NSR-CORE-001..011 lexical atoms.
; It intentionally returns no match for P02 operators such as <= and >=.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/tokens/operator_registry_generated.inc"

%macro ATOM_MATCH 5
 mov eax,1
 mov edx,%1
 mov ecx,%2
 mov r8d,%3
 mov r9d,%4
 mov r10d,%5
 ret
%endmacro

section .text
; operator_lexeme_lookup(source, remaining)
;   EAX = recognized (0/1)
;   EDX = token kind, ECX = bytes consumed, R8D = atom index
;   R9D = stable Registry ID, R10D = current token flags
NEBOC_ABI_FUNCTION neboc_operator_lexeme_lookup
 test rdi,rdi
 jz .miss
 test rsi,rsi
 jz .miss
 movzx eax,byte [rdi]
 cmp al,'.'
 je .dot
 cmp al,'('
 je .lparen
 cmp al,')'
 je .rparen
 cmp al,'{'
 je .lbrace
 cmp al,'}'
 je .rbrace
 cmp al,'['
 je .lbracket
 cmp al,']'
 je .rbracket
 cmp al,'<'
 je .less
 cmp al,'>'
 je .greater
 cmp al,','
 je .comma
 cmp al,';'
 je .semicolon
 cmp al,':'
 je .colon
 cmp al,'-'
 je .arrow
 cmp al,'_'
 je .underscore
 cmp al,'/'
 je .line_comment
 jmp .miss

.less:
 cmp rsi,2
 jb .less_match
 cmp byte [rdi+1],'='
 je .miss
.less_match:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_LESS,1,NEBOC_OPERATOR_ATOM_LESS,NEBOC_OPERATOR_REGISTRY_ANGLES,NEBOC_TOKEN_FLAG_NONE
.greater:
 cmp rsi,2
 jb .greater_match
 cmp byte [rdi+1],'='
 je .miss
.greater_match:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_GREATER,1,NEBOC_OPERATOR_ATOM_GREATER,NEBOC_OPERATOR_REGISTRY_ANGLES,NEBOC_TOKEN_FLAG_NONE
.arrow:
 cmp rsi,2
 jb .miss
 cmp byte [rdi+1],'>'
 jne .miss
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_ARROW,2,NEBOC_OPERATOR_ATOM_ARROW,NEBOC_OPERATOR_REGISTRY_ARROW,NEBOC_TOKEN_FLAG_RESERVED
.line_comment:
 cmp rsi,2
 jb .miss
 cmp byte [rdi+1],'/'
 jne .miss
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_LINE_COMMENT,2,NEBOC_OPERATOR_ATOM_LINE_COMMENT,NEBOC_OPERATOR_REGISTRY_LINE_COMMENT,NEBOC_TOKEN_FLAG_NONE
.dot:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_DOT,1,NEBOC_OPERATOR_ATOM_DOT,NEBOC_OPERATOR_REGISTRY_DOT,NEBOC_TOKEN_FLAG_NONE
.lparen:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_LPAREN,1,NEBOC_OPERATOR_ATOM_LPAREN,NEBOC_OPERATOR_REGISTRY_PARENS,NEBOC_TOKEN_FLAG_NONE
.rparen:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_RPAREN,1,NEBOC_OPERATOR_ATOM_RPAREN,NEBOC_OPERATOR_REGISTRY_PARENS,NEBOC_TOKEN_FLAG_NONE
.lbrace:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_LBRACE,1,NEBOC_OPERATOR_ATOM_LBRACE,NEBOC_OPERATOR_REGISTRY_BRACES,NEBOC_TOKEN_FLAG_NONE
.rbrace:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_RBRACE,1,NEBOC_OPERATOR_ATOM_RBRACE,NEBOC_OPERATOR_REGISTRY_BRACES,NEBOC_TOKEN_FLAG_NONE
.lbracket:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_LBRACKET,1,NEBOC_OPERATOR_ATOM_LBRACKET,NEBOC_OPERATOR_REGISTRY_BRACKETS,NEBOC_TOKEN_FLAG_RESERVED
.rbracket:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_RBRACKET,1,NEBOC_OPERATOR_ATOM_RBRACKET,NEBOC_OPERATOR_REGISTRY_BRACKETS,NEBOC_TOKEN_FLAG_RESERVED
.comma:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_COMMA,1,NEBOC_OPERATOR_ATOM_COMMA,NEBOC_OPERATOR_REGISTRY_COMMA,NEBOC_TOKEN_FLAG_NONE
.semicolon:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_SEMICOLON,1,NEBOC_OPERATOR_ATOM_SEMICOLON,NEBOC_OPERATOR_REGISTRY_SEMICOLON,NEBOC_TOKEN_FLAG_NONE
.colon:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_COLON,1,NEBOC_OPERATOR_ATOM_COLON,NEBOC_OPERATOR_REGISTRY_COLON,NEBOC_TOKEN_FLAG_RESERVED
.underscore:
 ATOM_MATCH NEBOC_OPERATOR_TOKEN_UNDERSCORE,1,NEBOC_OPERATOR_ATOM_UNDERSCORE,NEBOC_OPERATOR_REGISTRY_UNDERSCORE,NEBOC_TOKEN_FLAG_NONE
.miss:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
