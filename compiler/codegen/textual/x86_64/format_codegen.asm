bits 64
default rel
%include "compiler/codegen/textual/x86_64/format_codegen.inc"
section .text
extern neboc_format_plan_write
global neboc_format_codegen_emit
; Canonical codegen bridge; preserves the runtime atomic-write contract.
neboc_format_codegen_emit:
    jmp neboc_format_plan_write
