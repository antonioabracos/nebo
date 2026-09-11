%ifndef NEBOC_OPERATOR_LEXEME_TRIE_INC
%define NEBOC_OPERATOR_LEXEME_TRIE_INC 1

; Shared generated recognizer body.  The standalone Registry API and the live
; lexer instantiate this exact body so token recognition cannot drift.
%macro NEBOC_OPERATOR_ATOM_MATCH 5
 mov eax,1
 mov edx,%1
 mov ecx,%2
 mov r8d,%3
 mov r9d,%4
 mov r10d,%5
 ret
%endmacro

%macro NEBOC_OPERATOR_LEXEME_LOOKUP_BODY 0
 test rdi,rdi
 jz %%miss
 test rsi,rsi
 jz %%miss
 movzx eax,byte [rdi]
 cmp al,'.'
 je %%dot
 cmp al,'('
 je %%lparen
 cmp al,')'
 je %%rparen
 cmp al,'{'
 je %%lbrace
 cmp al,'}'
 je %%rbrace
 cmp al,'['
 je %%lbracket
 cmp al,']'
 je %%rbracket
 cmp al,'<'
 je %%less
 cmp al,'>'
 je %%greater
 cmp al,','
 je %%comma
 cmp al,';'
 je %%semicolon
 cmp al,':'
 je %%colon
 cmp al,'-'
 je %%arrow
 cmp al,'_'
 je %%underscore
 cmp al,'/'
 je %%line_comment
 jmp %%miss

%%dot:
 cmp rsi,2
 jb %%dot_match
 cmp byte [rdi+1],'.'
 je %%miss
%%dot_match:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_DOT,1,NEBOC_OPERATOR_ATOM_DOT,NEBOC_OPERATOR_REGISTRY_DOT,NEBOC_TOKEN_FLAG_NONE
%%less:
 cmp rsi,2
 jb %%less_match
 cmp byte [rdi+1],'='
 je %%miss
 ; `<…` and `<…<` are longer current operators owned by the Unicode-aware
 ; scanner. Do not let the generated structural `<` atom shadow them.
 cmp rsi,4
 jb %%less_match
 cmp byte [rdi+1],0xe2
 jne %%less_match
 cmp byte [rdi+2],0x80
 jne %%less_match
 cmp byte [rdi+3],0xa6
 je %%miss
%%less_match:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_LESS,1,NEBOC_OPERATOR_ATOM_LESS,NEBOC_OPERATOR_REGISTRY_ANGLES,NEBOC_TOKEN_FLAG_NONE
%%greater:
 cmp rsi,2
 jb %%greater_match
 cmp byte [rdi+1],'='
 je %%miss
%%greater_match:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_GREATER,1,NEBOC_OPERATOR_ATOM_GREATER,NEBOC_OPERATOR_REGISTRY_ANGLES,NEBOC_TOKEN_FLAG_NONE
%%arrow:
 cmp rsi,2
 jb %%miss
 cmp byte [rdi+1],'>'
 jne %%miss
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_ARROW,2,NEBOC_OPERATOR_ATOM_ARROW,NEBOC_OPERATOR_REGISTRY_ARROW,NEBOC_TOKEN_FLAG_RESERVED
%%line_comment:
 cmp rsi,2
 jb %%miss
 cmp byte [rdi+1],'/'
 jne %%miss
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_LINE_COMMENT,2,NEBOC_OPERATOR_ATOM_LINE_COMMENT,NEBOC_OPERATOR_REGISTRY_LINE_COMMENT,NEBOC_TOKEN_FLAG_NONE
%%lparen:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_LPAREN,1,NEBOC_OPERATOR_ATOM_LPAREN,NEBOC_OPERATOR_REGISTRY_PARENS,NEBOC_TOKEN_FLAG_NONE
%%rparen:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_RPAREN,1,NEBOC_OPERATOR_ATOM_RPAREN,NEBOC_OPERATOR_REGISTRY_PARENS,NEBOC_TOKEN_FLAG_NONE
%%lbrace:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_LBRACE,1,NEBOC_OPERATOR_ATOM_LBRACE,NEBOC_OPERATOR_REGISTRY_BRACES,NEBOC_TOKEN_FLAG_NONE
%%rbrace:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_RBRACE,1,NEBOC_OPERATOR_ATOM_RBRACE,NEBOC_OPERATOR_REGISTRY_BRACES,NEBOC_TOKEN_FLAG_NONE
%%lbracket:
 ; Brackets are CORE delimiters for Array/type syntax.  The live lexer owns
 ; the separate contextual `expr[index]` reservation before this fallback.
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_LBRACKET,1,NEBOC_OPERATOR_ATOM_LBRACKET,NEBOC_OPERATOR_REGISTRY_BRACKETS,NEBOC_TOKEN_FLAG_NONE
%%rbracket:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_RBRACKET,1,NEBOC_OPERATOR_ATOM_RBRACKET,NEBOC_OPERATOR_REGISTRY_BRACKETS,NEBOC_TOKEN_FLAG_NONE
%%comma:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_COMMA,1,NEBOC_OPERATOR_ATOM_COMMA,NEBOC_OPERATOR_REGISTRY_COMMA,NEBOC_TOKEN_FLAG_NONE
%%semicolon:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_SEMICOLON,1,NEBOC_OPERATOR_ATOM_SEMICOLON,NEBOC_OPERATOR_REGISTRY_SEMICOLON,NEBOC_TOKEN_FLAG_NONE
%%colon:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_COLON,1,NEBOC_OPERATOR_ATOM_COLON,NEBOC_OPERATOR_REGISTRY_COLON,NEBOC_TOKEN_FLAG_RESERVED
%%underscore:
 NEBOC_OPERATOR_ATOM_MATCH NEBOC_OPERATOR_TOKEN_UNDERSCORE,1,NEBOC_OPERATOR_ATOM_UNDERSCORE,NEBOC_OPERATOR_REGISTRY_UNDERSCORE,NEBOC_TOKEN_FLAG_NONE
%%miss:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 ret
%endmacro

%endif
