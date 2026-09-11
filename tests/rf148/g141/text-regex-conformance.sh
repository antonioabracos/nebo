#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
rf148_sources=(
  compiler/parser/expression/text_pattern_operator_plan.asm
  compiler/runtime/text/checked_concat.asm
  compiler/runtime/pattern/compiled_pattern.asm
  compiler/runtime/pattern/match.asm
  compiler/runtime/pattern/non_match.asm
  compiler/semantic/pattern/unicode_boundaries.asm
  compiler/format/pattern_operator_metadata.asm
)
for rf148_source in "${rf148_sources[@]}"; do
  rf148_object="$rf148_tmp/${rf148_source//\//_}.o"
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_object" "$rf148_source"
done
cat > "$rf148_tmp/harness.asm" <<'ASM'
default rel
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/expression/operator_precedence.inc"
extern nebo_text_pattern_operator_plan, nebo_text_pattern_registry_lookup
extern nebo_text_concat_checked
extern nebo_pattern_compile, nebo_pattern_match, nebo_pattern_non_match
extern nebo_utf8_pattern_boundaries, nebo_pattern_operator_metadata
global _start
section .data
left db 'ab'
right db 'cd'
pattern db 'a.c'
bad_pattern db 'a*c'
text_match db 'xxabczz'
text_miss db 'xxaddzz'
unicode db 065h,0cch,081h,0f0h,09fh,098h,080h
invalid_utf8 db 0c0h,080h
section .bss
output_buffer resb 8
descriptor resq 4
capture resq 2
counts resq 2
metadata resq 5
section .text
_start:
    xor ebx, ebx
.plan_loop:
    mov edi, ebx
    mov esi, 1
    call nebo_text_pattern_operator_plan
    test edx, edx
    jnz fail
    lea ecx, [rbx+141001]
    cmp eax, ecx
    jne fail
    inc ebx
    cmp ebx, 3
    jb .plan_loop
    xor edi, edi
    xor esi, esi
    call nebo_text_pattern_operator_plan
    cmp edx, 1
    jne fail
    mov edi, 3
    mov esi, 1
    call nebo_text_pattern_operator_plan
    cmp edx, 2
    jne fail

    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_074
    mov esi, 1
    call nebo_text_pattern_registry_lookup
    test rax, rax
    jz fail
    cmp edx, NEBOC_TOKEN_TEXT_CONCAT
    jne fail
    cmp r9d, NEBOC_OPERATOR_BP_ADDITIVE
    jne fail
    cmp r10d, NEBOC_OPERATOR_PARSE_ASSOC_LEFT
    jne fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_075
    mov esi, 1
    call nebo_text_pattern_registry_lookup
    test rax, rax
    jz fail
    cmp edx, NEBOC_TOKEN_PATTERN_MATCH
    jne fail
    cmp r9d, NEBOC_OPERATOR_BP_EQUALITY
    jne fail
    cmp r10d, NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC
    jne fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_076
    mov esi, 1
    call nebo_text_pattern_registry_lookup
    test rax, rax
    jz fail
    cmp edx, NEBOC_TOKEN_PATTERN_NON_MATCH
    jne fail
    mov rdi, NEBOC_OPERATOR_ID_NSR_DOM_074
    xor esi, esi
    call nebo_text_pattern_registry_lookup
    test rax, rax
    jnz fail

    lea rdi, [left]
    mov esi, 2
    lea rdx, [right]
    mov ecx, 2
    lea r8, [output_buffer]
    mov r9d, 8
    call nebo_text_concat_checked
    test edx, edx
    jnz fail
    cmp rax, 4
    jne fail
    cmp dword [output_buffer], 064636261h
    jne fail
    mov dword [output_buffer], 011223344h
    lea rdi, [left]
    mov esi, 2
    lea rdx, [right]
    mov ecx, 2
    lea r8, [output_buffer]
    mov r9d, 3
    call nebo_text_concat_checked
    cmp edx, 3
    jne fail
    cmp dword [output_buffer], 011223344h
    jne fail

    lea rdi, [pattern]
    mov esi, 3
    mov edx, 1
    mov ecx, 100
    lea r8, [descriptor]
    call nebo_pattern_compile
    test eax, eax
    jnz fail
    lea rdi, [text_match]
    mov esi, 7
    lea rdx, [descriptor]
    lea rcx, [capture]
    call nebo_pattern_match
    test edx, edx
    jnz fail
    cmp eax, 1
    jne fail
    cmp qword [capture], 2
    jne fail
    cmp qword [capture+8], 3
    jne fail
    lea rdi, [text_match]
    mov esi, 7
    lea rdx, [descriptor]
    lea rcx, [capture]
    call nebo_pattern_non_match
    test edx, edx
    jnz fail
    test eax, eax
    jnz fail
    lea rdi, [text_miss]
    mov esi, 7
    lea rdx, [descriptor]
    lea rcx, [capture]
    call nebo_pattern_non_match
    test edx, edx
    jnz fail
    cmp eax, 1
    jne fail
    mov qword [descriptor+24], 2
    lea rdi, [text_match]
    mov esi, 7
    lea rdx, [descriptor]
    lea rcx, [capture]
    call nebo_pattern_match
    cmp edx, 2
    jne fail

    lea rdi, [bad_pattern]
    mov esi, 3
    mov edx, 1
    mov ecx, 100
    lea r8, [descriptor]
    mov rax, 01122334455667788h
    mov [descriptor], rax
    mov rax, 02233445566778899h
    mov [descriptor+8], rax
    call nebo_pattern_compile
    cmp eax, 3
    jne fail
    mov rax, 01122334455667788h
    cmp [descriptor], rax
    jne fail
    mov rax, 02233445566778899h
    cmp [descriptor+8], rax
    jne fail

    lea rdi, [unicode]
    mov esi, 7
    lea rdx, [counts]
    call nebo_utf8_pattern_boundaries
    test eax, eax
    jnz fail
    cmp qword [counts], 3
    jne fail
    cmp qword [counts+8], 2
    jne fail
    mov qword [counts], 99
    lea rdi, [invalid_utf8]
    mov esi, 2
    lea rdx, [counts]
    call nebo_utf8_pattern_boundaries
    cmp eax, 1
    jne fail
    cmp qword [counts], 99
    jne fail

    xor edi, edi
    lea rsi, [metadata]
    call nebo_pattern_operator_metadata
    test eax, eax
    jnz fail
    cmp qword [metadata+16], 130
    jne fail
    cmp qword [metadata+32], 74
    jne fail
    mov edi, 1
    lea rsi, [metadata]
    call nebo_pattern_operator_metadata
    test eax, eax
    jnz fail
    cmp qword [metadata+16], 110
    jne fail
    cmp qword [metadata+32], 75
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
printf '%s\n' 'RF148_G141_TEXT_REGEX_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_ROWS=PASS'
printf '%s\n' 'DOMAIN_GATING=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'UNICODE_BOUNDARIES=PASS'
printf '%s\n' 'SOURCE_SYNTAX_INTEGRATED=PASS'
