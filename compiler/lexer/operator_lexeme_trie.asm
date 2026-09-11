; Bounded maximal-munch recognizer for NSR-CORE-001..011 lexical atoms.
; It intentionally returns no match for P02 operators such as <= and >=.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/tokens/operator_registry_generated.inc"
%include "compiler/lexer/operator_lexeme_trie.inc"

section .text
; operator_lexeme_lookup(source, remaining)
;   EAX = recognized (0/1)
;   EDX = token kind, ECX = bytes consumed, R8D = atom index
;   R9D = stable Registry ID, R10D = current token flags
NEBOC_ABI_FUNCTION neboc_operator_lexeme_lookup
 NEBOC_OPERATOR_LEXEME_LOOKUP_BODY

section .note.GNU-stack noalloc noexec nowrite progbits
