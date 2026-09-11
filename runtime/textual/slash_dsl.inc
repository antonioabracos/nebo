%ifndef NEBO_SLASH_DSL_INC
%define NEBO_SLASH_DSL_INC 1

; Bounded public Slash DSL ABI. All pointers are borrowed for the duration of
; a call; the parser and renderers never allocate and never retain input.
SLASH_OK                 equ 0
SLASH_E_INVALID          equ 1
SLASH_E_LIMIT            equ 2
SLASH_E_SYNTAX           equ 3
SLASH_E_UNKNOWN          equ 4
SLASH_E_CAPACITY         equ 5
SLASH_E_TARGET           equ 6

SLASH_TARGET_PLAIN       equ 1
SLASH_TARGET_ANSI        equ 2
SLASH_TARGET_MARKDOWN    equ 3
SLASH_TARGET_HTML        equ 4
SLASH_TARGET_CONSOLE     equ 5

SLASH_MAX_INPUT          equ 4096
SLASH_MAX_TOKENS         equ 256
SLASH_MAX_DEPTH          equ 16
SLASH_MAX_ARGUMENT       equ 32

; SlashToken: immutable lexical observation.
SLASH_TOKEN_KIND         equ 0
SLASH_TOKEN_START        equ 8
SLASH_TOKEN_END          equ 16
SLASH_TOKEN_DIRECTIVE    equ 24
SLASH_TOKEN_SIZE         equ 32

SLASH_TOKEN_CONTENT      equ 1
SLASH_TOKEN_DIRECTIVE_K  equ 2
SLASH_TOKEN_ESCAPE       equ 3

; SlashDirective: typed directive and its source spans.
SLASH_DIRECTIVE_ID       equ 0
SLASH_DIRECTIVE_START    equ 8
SLASH_DIRECTIVE_END      equ 16
SLASH_DIRECTIVE_ARGUMENT equ 24
SLASH_DIRECTIVE_CONTENT  equ 32
SLASH_DIRECTIVE_SIZE     equ 40

; SlashArgument: optional, borrowed argument slice.
SLASH_ARGUMENT_PRESENT   equ 0
SLASH_ARGUMENT_DATA      equ 8
SLASH_ARGUMENT_LENGTH    equ 16
SLASH_ARGUMENT_SIZE      equ 24

; SlashContent: nested, borrowed source slice materialized as RenderPlan input.
SLASH_CONTENT_DATA       equ 0
SLASH_CONTENT_LENGTH     equ 8
SLASH_CONTENT_DEPTH      equ 16
SLASH_CONTENT_SIZE       equ 24

; Aggregate parser observation used by bounded clients and tests.
SLASH_PARSE_TOKENS       equ 0
SLASH_PARSE_DIRECTIVES   equ 8
SLASH_PARSE_MAX_DEPTH    equ 16
SLASH_PARSE_ESCAPES      equ 24
SLASH_PARSE_FIRST_ID     equ 32
SLASH_PARSE_SIZE         equ 40

; Typed diagnostic with half-open byte span.
SLASH_ERROR_CODE         equ 0
SLASH_ERROR_START        equ 8
SLASH_ERROR_END          equ 16
SLASH_ERROR_SIZE         equ 24

%ifndef NEBO_SLASH_DSL_IMPLEMENTATION
 extern neboc_slash_parse
 extern neboc_slash_validate
 extern neboc_slash_render
 extern neboc_slash_render_plain
 extern neboc_slash_render_ansi
 extern neboc_slash_render_markdown
 extern neboc_slash_render_html
 extern neboc_slash_render_console
%endif

%endif
