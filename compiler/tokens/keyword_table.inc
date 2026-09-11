; Canonical live Nebo keyword spellings.  The lexer classifier and runtime
; identifier predicate include this one table so keyword grammar cannot drift.
kw_start: db 'start'
kw_start_len equ $-kw_start
kw_if: db 'if'
kw_if_len equ $-kw_if
kw_else: db 'else'
kw_else_len equ $-kw_else
kw_true: db 'true'
kw_true_len equ $-kw_true
kw_false: db 'false'
kw_false_len equ $-kw_false
kw_return: db 'return'
kw_return_len equ $-kw_return
kw_for: db 'for'
kw_for_len equ $-kw_for
kw_when: db 'when'
kw_when_len equ $-kw_when
kw_while: db 'while'
kw_while_len equ $-kw_while
kw_switch: db 'switch'
kw_switch_len equ $-kw_switch
kw_loop: db 'loop'
kw_loop_len equ $-kw_loop
kw_break: db 'break'
kw_break_len equ $-kw_break
kw_continue: db 'continue'
kw_continue_len equ $-kw_continue
kw_module: db 'module'
kw_module_len equ $-kw_module
kw_import: db 'import'
kw_import_len equ $-kw_import
kw_export: db 'export'
kw_export_len equ $-kw_export
kw_async: db 'async'
kw_async_len equ $-kw_async
kw_await: db 'await'
kw_await_len equ $-kw_await
kw_match: db 'match'
kw_match_len equ $-kw_match
kw_struct: db 'struct'
kw_struct_len equ $-kw_struct
kw_enum: db 'enum'
kw_enum_len equ $-kw_enum
kw_interface: db 'interface'
kw_interface_len equ $-kw_interface
kw_class: db 'class'
kw_class_len equ $-kw_class
kw_generic: db 'generic'
kw_generic_len equ $-kw_generic
kw_do: db 'do'
kw_do_len equ $-kw_do
kw_defer: db 'defer'
kw_defer_len equ $-kw_defer
kw_doc: db 'doc'
kw_doc_len equ $-kw_doc
kw_xor: db 'xor'
kw_xor_len equ $-kw_xor
kw_inf: db 'inf'
kw_inf_len equ $-kw_inf
kw_pi_ascii: db 'PI'
kw_pi_ascii_len equ $-kw_pi_ascii
kw_tau_ascii: db 'TAU'
kw_tau_ascii_len equ $-kw_tau_ascii
align 8
keyword_table:
 dq kw_start, kw_start_len, NEBOC_TOKEN_KW_START
 dq kw_if, kw_if_len, NEBOC_TOKEN_KW_IF
 dq kw_else, kw_else_len, NEBOC_TOKEN_KW_ELSE
 dq kw_true, kw_true_len, NEBOC_TOKEN_KW_TRUE
 dq kw_false, kw_false_len, NEBOC_TOKEN_KW_FALSE
 dq kw_return, kw_return_len, NEBOC_TOKEN_KW_RETURN
 dq kw_for, kw_for_len, NEBOC_TOKEN_KW_FOR
 dq kw_when, kw_when_len, NEBOC_TOKEN_KW_WHEN
 dq kw_while, kw_while_len, NEBOC_TOKEN_KW_WHILE
 dq kw_switch, kw_switch_len, NEBOC_TOKEN_KW_SWITCH
 dq kw_loop, kw_loop_len, NEBOC_TOKEN_KW_LOOP
 dq kw_break, kw_break_len, NEBOC_TOKEN_KW_BREAK
 dq kw_continue, kw_continue_len, NEBOC_TOKEN_KW_CONTINUE
 dq kw_module, kw_module_len, NEBOC_TOKEN_KW_MODULE
 dq kw_import, kw_import_len, NEBOC_TOKEN_KW_IMPORT
 dq kw_export, kw_export_len, NEBOC_TOKEN_KW_EXPORT
 dq kw_async, kw_async_len, NEBOC_TOKEN_KW_ASYNC
 dq kw_await, kw_await_len, NEBOC_TOKEN_KW_AWAIT
 dq kw_match, kw_match_len, NEBOC_TOKEN_KW_MATCH
 dq kw_struct, kw_struct_len, NEBOC_TOKEN_KW_STRUCT
 dq kw_enum, kw_enum_len, NEBOC_TOKEN_KW_ENUM
 dq kw_interface, kw_interface_len, NEBOC_TOKEN_KW_INTERFACE
 dq kw_class, kw_class_len, NEBOC_TOKEN_KW_CLASS
 dq kw_generic, kw_generic_len, NEBOC_TOKEN_KW_GENERIC
 dq kw_do, kw_do_len, NEBOC_TOKEN_KW_DO
 dq kw_defer, kw_defer_len, NEBOC_TOKEN_KW_DEFER
 dq kw_doc, kw_doc_len, NEBOC_TOKEN_KW_DOC
 dq kw_xor, kw_xor_len, NEBOC_TOKEN_XOR
 dq kw_inf, kw_inf_len, NEBOC_TOKEN_INFINITY
 dq kw_pi_ascii, kw_pi_ascii_len, NEBOC_TOKEN_PI
 dq kw_tau_ascii, kw_tau_ascii_len, NEBOC_TOKEN_TAU
%define KEYWORD_COUNT 31
