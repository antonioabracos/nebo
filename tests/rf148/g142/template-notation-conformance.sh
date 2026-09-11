#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
rf148_sources=(
  compiler/parser/text/template_notation_plan.asm
  compiler/parser/text/template_context_plan.asm
  compiler/parser/text/interpolation_plan.asm
  compiler/semantic/types/format_semantic.asm
  compiler/parser/text/placeholder_plan.asm
  compiler/runtime/text/percent_escape.asm
  compiler/parser/text/slash_directive_plan.asm
  compiler/runtime/text/format_plan.asm
  compiler/format/template_metadata.asm
)
for rf148_source in "${rf148_sources[@]}"; do
  rf148_object="$rf148_tmp/${rf148_source//\//_}.o"
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_object" "$rf148_source"
done
cat > "$rf148_tmp/harness.asm" <<'ASM'
default rel
%include "compiler/tokens/operator_registry.inc"
%define NEBO_TEMPLATE_NOTATION_PLAN_IMPLEMENTATION 1
%include "compiler/parser/text/template_notation_plan.inc"
%undef NEBO_TEMPLATE_NOTATION_PLAN_IMPLEMENTATION
extern nebo_template_notation_registry_lookup
extern nebo_template_context_plan, nebo_interpolation_plan, nebo_placeholder_plan
extern nebo_percent_escape, nebo_slash_directive_plan
extern nebo_format_plan_evaluate_once, nebo_template_metadata
global _start
section .data
percent_text db 'rate%%ok'
bad_percent db 'bad%x'
directive db 'render1'
bad_directive db '1render'
nodes dq 0,0, 1,0, 0,0, 1,1
duplicate_nodes dq 1,0, 1,0
section .bss
plan resq 5
output_buffer resb 16
format_result resq 2
section .text
_start:
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_077
    mov esi, TEMPLATE_NOTATION_CONTEXT_INTERPOLATED_TEXT
    call nebo_template_notation_registry_lookup
    cmp eax, TEMPLATE_NOTATION_INTERPOLATION
    jne fail
    cmp edx, NEBOC_OPERATOR_FIXITY_CONTEXTUAL
    jne fail
    cmp r8d, 77
    jne fail
    test ecx, TEMPLATE_NOTATION_FLAG_EXACTLY_ONCE
    jz fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_078
    mov esi, TEMPLATE_NOTATION_CONTEXT_FORMAT_TEXT
    call nebo_template_notation_registry_lookup
    cmp eax, TEMPLATE_NOTATION_PERCENT
    jne fail
    cmp r8d, 78
    jne fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_079
    mov esi, TEMPLATE_NOTATION_CONTEXT_SLASH_TEXT
    call nebo_template_notation_registry_lookup
    cmp eax, TEMPLATE_NOTATION_SLASH
    jne fail
    cmp r8d, 79
    jne fail
    test ecx, TEMPLATE_NOTATION_FLAG_PLAIN_FALLBACK
    jz fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_077
    mov esi, TEMPLATE_NOTATION_CONTEXT_FORMAT_TEXT
    call nebo_template_notation_registry_lookup
    test eax, eax
    jnz fail
    test edx, edx
    jnz fail
    test ecx, ecx
    jnz fail
    test r8d, r8d
    jnz fail

    mov edi, 1
    mov esi, 1
    mov edx, 8
    mov ecx, 32
    call nebo_template_context_plan
    test edx, edx
    jnz fail
    cmp eax, 142002
    jne fail
    mov edi, 1
    xor esi, esi
    mov edx, 8
    mov ecx, 32
    call nebo_template_context_plan
    cmp edx, 1
    jne fail

    mov edi, 2
    mov esi, 4
    mov edx, 1
    lea rcx, [plan]
    call nebo_interpolation_plan
    test eax, eax
    jnz fail
    cmp qword [plan], 77
    jne fail
    mov qword [plan], 99
    mov edi, 1
    mov esi, 2
    xor edx, edx
    lea rcx, [plan]
    call nebo_interpolation_plan
    cmp eax, 3
    jne fail
    cmp qword [plan], 99
    jne fail

    mov edi, 's'
    mov esi, 1
    xor edx, edx
    lea rcx, [plan]
    call nebo_placeholder_plan
    test eax, eax
    jnz fail
    mov edi, 'd'
    mov esi, 1
    xor edx, edx
    lea rcx, [plan]
    call nebo_placeholder_plan
    cmp eax, 2
    jne fail

    lea rdi, [percent_text]
    mov esi, 8
    lea rdx, [output_buffer]
    mov ecx, 16
    call nebo_percent_escape
    test edx, edx
    jnz fail
    cmp rax, 7
    jne fail
    cmp dword [output_buffer], 065746172h
    jne fail
    cmp word [output_buffer+4], 06f25h
    jne fail
    cmp byte [output_buffer+6], 'k'
    jne fail
    mov rax, 01122334455667788h
    mov [output_buffer], rax
    lea rdi, [bad_percent]
    mov esi, 5
    lea rdx, [output_buffer]
    mov ecx, 16
    call nebo_percent_escape
    cmp edx, 2
    jne fail
    mov rax, [output_buffer]
    mov rdx, 01122334455667788h
    cmp rax, rdx
    jne fail

    lea rdi, [directive]
    mov esi, 7
    mov edx, 2
    mov ecx, 3
    mov r8d, 100
    lea r9, [plan]
    call nebo_slash_directive_plan
    test eax, eax
    jnz fail
    cmp qword [plan], 79
    jne fail
    lea rdi, [bad_directive]
    mov esi, 7
    xor edx, edx
    mov ecx, 1
    mov r8d, 10
    lea r9, [plan]
    call nebo_slash_directive_plan
    cmp eax, 1
    jne fail

    lea rdi, [nodes]
    mov esi, 4
    mov edx, 2
    mov ecx, 4
    lea r8, [format_result]
    call nebo_format_plan_evaluate_once
    test eax, eax
    jnz fail
    cmp qword [format_result], 3
    jne fail
    lea rdi, [duplicate_nodes]
    mov esi, 2
    mov edx, 1
    mov ecx, 2
    lea r8, [format_result]
    call nebo_format_plan_evaluate_once
    cmp eax, 3
    jne fail
    lea rdi, [nodes]
    mov esi, 4
    mov edx, 3
    mov ecx, 4
    lea r8, [format_result]
    call nebo_format_plan_evaluate_once
    cmp eax, 4
    jne fail

    mov edi, 2
    mov esi, 2
    xor edx, edx
    lea rcx, [plan]
    call nebo_template_metadata
    test eax, eax
    jnz fail
    xor edi, edi
    mov esi, 2
    xor edx, edx
    lea rcx, [plan]
    call nebo_template_metadata
    cmp eax, 2
    jne fail
    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, 1
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
mapfile -t rf148_objects < <(find "$rf148_tmp" -maxdepth 1 -type f -name '*.o' | sort)
ld -o "$rf148_tmp/conformance" "${rf148_objects[@]}"
"$rf148_tmp/conformance"
test -z "$(nm -u "$rf148_tmp/conformance")"
test -z "$(readelf -dW "$rf148_tmp/conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
printf '%s\n' 'RF148_G142_TEMPLATE_NOTATION_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_ROWS=PASS'
printf '%s\n' 'CONTEXT_ISOLATION=PASS'
printf '%s\n' 'FORMAT_PLAN_EXACTLY_ONCE=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'SOURCE_SYNTAX_INTEGRATED=PASS'
