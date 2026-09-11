#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
work=$(mktemp -d /tmp/nebo-G143-conformance.XXXXXX)
trap 'find "$work" -depth -mindepth 1 -delete; rmdir "$work"' EXIT INT TERM HUP

for source in compiler/parser/meta/annotation_registry.asm compiler/lowering/meta/annotation_metadata.asm; do
  name=$(basename "$source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$work/$name.a.o" "$source"
  nasm -f elf64 -Wall -Werror -I./ -o "$work/$name.b.o" "$source"
  cmp -s "$work/$name.a.o" "$work/$name.b.o"
done

cat >"$work/harness.asm" <<'ASM'
bits 64
default rel
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/meta/annotation_plan.inc"
global _start
section .rodata
stable: db 'stable'
stable_len equ $-stable
module_info: db 'moduleInfo'
module_info_len equ $-module_info
audit: db 'audit'
audit_len equ $-audit
unknown: db 'unknown'
unknown_len equ $-unknown
section .bss align=16
plan: resb NEBO_ANNOTATION_PLAN_SIZE
section .text
_start:
    lea rdi,[rel stable]
    mov esi,stable_len
    mov edx,NEBO_ANNOTATION_TARGET_FUNCTION
    mov ecx,1
    lea r8,[rel plan]
    call nebo_annotation_registry_lookup
    test eax,eax
    jnz fail
    mov rax,NEBOC_OPERATOR_ID_NSR_DOM_080
    cmp [rel plan+NEBO_ANNOTATION_PLAN_REGISTRY_ID_OFFSET],rax
    jne fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_KIND_OFFSET],1
    jne fail
    test qword [rel plan+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET],NEBO_ANNOTATION_FLAG_RUNTIME
    jnz fail

    mov qword [rel plan],0x11223344
    lea rdi,[rel stable]
    mov esi,stable_len
    mov edx,NEBO_ANNOTATION_TARGET_FUNCTION
    mov ecx,2
    lea r8,[rel plan]
    call nebo_annotation_registry_lookup
    cmp eax,2
    jne fail
    cmp qword [rel plan],0x11223344
    jne fail

    lea rdi,[rel module_info]
    mov esi,module_info_len
    mov edx,NEBO_ANNOTATION_TARGET_FUNCTION
    mov ecx,1
    lea r8,[rel plan]
    call nebo_annotation_registry_lookup
    cmp eax,3
    jne fail
    lea rdi,[rel unknown]
    mov esi,unknown_len
    mov edx,NEBO_ANNOTATION_TARGET_FUNCTION
    mov ecx,1
    lea r8,[rel plan]
    call nebo_annotation_registry_lookup
    cmp eax,1
    jne fail

    lea rdi,[rel audit]
    mov esi,audit_len
    mov edx,NEBO_ANNOTATION_TARGET_FIELD
    mov ecx,1
    lea r8,[rel plan]
    call nebo_annotation_registry_lookup
    test eax,eax
    jnz fail
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_ARGUMENT_MASK_OFFSET],15
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET],4
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_LEVEL_OFFSET],9
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_ENABLED_OFFSET],1
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_LABEL_HASH_OFFSET],101
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_SEED_OFFSET],17
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET],3
    mov qword [rel plan+NEBO_ANNOTATION_PLAN_TARGET_NAME_HASH_OFFSET],103
    lea rdi,[rel plan]
    call nebo_annotation_metadata_lower
    test eax,eax
    jnz fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_COMPILE_DIGEST_OFFSET],0
    je fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_RUNTIME_DIGEST_OFFSET],0
    je fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_PROVENANCE_OFFSET],0
    je fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_REFLECTION_CODE_OFFSET],0
    jne fail
    cmp qword [rel plan+NEBO_ANNOTATION_PLAN_CHECKSUM_OFFSET],0
    je fail

    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM
nasm -f elf64 -Wall -Werror -I./ -o "$work/harness.o" "$work/harness.asm"
ld -m elf_x86_64 -o "$work/harness" "$work/harness.o" "$work/annotation_registry.a.o" "$work/annotation_metadata.a.o"
timeout 30 "$work/harness"

test "$(nm -g --defined-only "$work"/*.a.o | rg -c '[[:space:]]nebo_annotation_registry_lookup$')" -eq 1
test "$(nm -g --defined-only "$work"/*.a.o | rg -c '[[:space:]]nebo_annotation_metadata_lower$')" -eq 1
test "$(rg -c '^ dq annotation_' compiler/parser/meta/annotation_registry.asm)" -eq 8
test "$(rg -c '^%define NEBO_ANNOTATION_TARGET_(DECLARATION|MODULE|TYPE|FUNCTION|FIELD|OPERATOR) ' compiler/parser/meta/annotation_plan.inc)" -eq 6
if rg -n 'PRECEDENCE_ROW.*NEBOC_TOKEN_ANNOTATION' compiler/parser/expression; then
  exit 1
fi

printf '%s\n' 'RF148_G143_ANNOTATION_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_ROWS=PASS'
printf '%s\n' 'VERSION_TARGETS_FAIL_CLOSED=PASS'
printf '%s\n' 'TYPED_METADATA_LOWERING=PASS'
printf '%s\n' 'PRIVACY_REFLECTION_BOUNDARY=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'SOURCE_SYNTAX_INTEGRATED=PASS'
