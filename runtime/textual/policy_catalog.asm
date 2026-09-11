; G074 policy, supplemental-catalog, diagnostic, and editor integration owner.
bits 64
default rel
%define NEBO_G074_POLICY_CATALOG_IMPLEMENTATION 1
%include "runtime/textual/policy_catalog.inc"
%include "runtime/textual/percent_format.inc"
%include "compiler/lsp/render_policy_completion.inc"

section .rodata
g074_strict_prefix: db 'str'
g074_slash_prefix: db 'slash'

section .text
global nebo_g074_slash_policy_validate
global nebo_g074_catalog_counts_write
global nebo_g074_priority_state
global nebo_g074_diagnostic_write
global nebo_g074_source_probe
global nebo_g074_negative_probe

; RDI slash policy bits, RSI target kind.  Unknown and contradictory policy
; combinations fail without touching caller state.
nebo_g074_slash_policy_validate:
 mov rax,rdi
 and rax,~NEBO_G074_SLASH_ALL
 jnz .invalid
 cmp rsi,NEBO_G074_TARGET_TEXT
 jb .invalid
 cmp rsi,NEBO_G074_TARGET_UI
 ja .invalid
 mov rax,rdi
 and rax,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_DISABLE
 cmp rax,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_DISABLE
 je .conflict
 mov rax,rdi
 and rax,NEBO_G074_SLASH_STRICT | NEBO_G074_SLASH_UNKNOWN_TEXT
 cmp rax,NEBO_G074_SLASH_STRICT | NEBO_G074_SLASH_UNKNOWN_TEXT
 je .conflict
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_G074_INVALID
 ret
.conflict:
 mov eax,NEBO_G074_CONFLICT
 ret

; RDI caller qword buffer, RSI capacity.  The complete six-field historical
; inventory summary is validated before publication.
nebo_g074_catalog_counts_write:
 test rdi,rdi
 jz .catalog_invalid
 cmp rsi,NEBO_G074_CATALOG_FIELD_COUNT
 jb .catalog_capacity
 mov qword [rdi],NEBO_G074_CATALOG_PRIMARY_ROWS
 mov qword [rdi+8],NEBO_G074_CATALOG_PRIMARY_UNIQUE
 mov qword [rdi+16],NEBO_G074_CATALOG_PRIMARY_DUPLICATE
 mov qword [rdi+24],NEBO_G074_CATALOG_SUPPLEMENTAL_ROWS
 mov qword [rdi+32],NEBO_G074_CATALOG_PROOF_ROWS
 mov qword [rdi+40],NEBO_G074_CATALOG_PUBLIC_PROMOTIONS
 xor eax,eax
 ret
.catalog_invalid:
 mov eax,NEBO_G074_INVALID
 ret
.catalog_capacity:
 mov eax,NEBO_G074_CAPACITY
 ret

; RDI execution priority -> RAX explicit maturity state.
nebo_g074_priority_state:
 cmp rdi,NEBO_G074_PRIORITY_PUBLIC
 je .priority_public
 cmp rdi,NEBO_G074_PRIORITY_CONTRACT
 je .priority_contract
 cmp rdi,NEBO_G074_PRIORITY_DEFERRED
 je .priority_deferred
 xor eax,eax
 ret
.priority_public:
 mov eax,NEBO_G074_MATURITY_PUBLIC_BOUNDED
 ret
.priority_contract:
 mov eax,NEBO_G074_MATURITY_CONTRACT_ONLY
 ret
.priority_deferred:
 mov eax,NEBO_G074_MATURITY_DEFERRED
 ret

; RDI code 1..6, RSI start, RDX end, RCX caller 24-byte destination.
; Validate first so every failure leaves the destination byte-identical.
nebo_g074_diagnostic_write:
 test rcx,rcx
 jz .diagnostic_invalid
 test rdi,rdi
 jz .diagnostic_invalid
 cmp rdi,NEBO_G074_DIAG_SOURCE_CONTRACT
 ja .diagnostic_invalid
 cmp rsi,rdx
 ja .diagnostic_invalid
 cmp rdx,NEBO_G074_MAX_SOURCE_SPAN
 ja .diagnostic_limit
 mov rax,0x7400
 add rax,rdi
 mov [rcx+NEBO_G074_DIAG_CODE],rax
 mov [rcx+NEBO_G074_DIAG_START],rsi
 mov [rcx+NEBO_G074_DIAG_END],rdx
 xor eax,eax
 ret
.diagnostic_invalid:
 mov eax,NEBO_G074_INVALID
 ret
.diagnostic_limit:
 mov eax,NEBO_G074_LIMIT
 ret

; RDI subgroup mode 1..7, RSI source-derived seed.  Success returns the
; observed seed byte; all checks below cross a real runtime/editor owner.
nebo_g074_source_probe:
 push rbx
 push r12
 sub rsp,104
 mov r12,rsi
 cmp rdi,1
 je .s01
 cmp rdi,2
 je .s02
 cmp rdi,3
 je .s03
 cmp rdi,4
 je .s04
 cmp rdi,5
 je .s05
 cmp rdi,6
 je .s06
 cmp rdi,7
 je .s07
 jmp .fail
.s01:
 xor edi,edi
 call neboc_percent_policy_validate
 test eax,eax
 jnz .fail
 mov edi,PERCENT_POLICY_LOOSE
 call neboc_percent_policy_validate
 test eax,eax
 jnz .fail
 mov edi,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 call neboc_percent_policy_validate
 test eax,eax
 jz .fail
 jmp .success
.s02:
 mov edi,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_FALLBACK_PLAIN
 mov esi,NEBO_G074_TARGET_TERMINAL
 call nebo_g074_slash_policy_validate
 test eax,eax
 jnz .fail
 mov edi,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_DISABLE
 mov esi,NEBO_G074_TARGET_TEXT
 call nebo_g074_slash_policy_validate
 cmp eax,NEBO_G074_CONFLICT
 jne .fail
 jmp .success
.s03:
 lea rdi,[rsp]
 mov esi,NEBO_G074_CATALOG_FIELD_COUNT
 call nebo_g074_catalog_counts_write
 test eax,eax
 jnz .fail
 cmp qword [rsp],NEBO_G074_CATALOG_PRIMARY_ROWS
 jne .fail
 cmp qword [rsp+24],NEBO_G074_CATALOG_SUPPLEMENTAL_ROWS
 jne .fail
 cmp qword [rsp+40],NEBO_G074_CATALOG_PUBLIC_PROMOTIONS
 jne .fail
 jmp .success
.s04:
 mov edi,NEBO_G074_PRIORITY_PUBLIC
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_PUBLIC_BOUNDED
 jne .fail
 mov edi,NEBO_G074_PRIORITY_DEFERRED
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_DEFERRED
 jne .fail
 jmp .success
.s05:
 lea rdi,[rel g074_strict_prefix]
 mov esi,3
 lea rdx,[rsp]
 mov ecx,8
 call neboc_render_policy_complete
 cmp eax,2
 jne .fail
 cmp qword [rsp],1
 jne .fail
 cmp qword [rsp+8],14
 jne .fail
 mov edi,14
 lea rsi,[rsp+32]
 call neboc_render_policy_completion_resolve
 test eax,eax
 jnz .fail
 cmp qword [rsp+32+NEBOC_G074_COMPLETION_MATURITY],NEBOC_G074_MATURITY_PUBLIC_BOUNDED
 jne .fail
 jmp .success
.s06:
 mov edi,NEBO_G074_DIAG_DEFERRED_CAPABILITY
 mov esi,7
 mov edx,19
 lea rcx,[rsp]
 call nebo_g074_diagnostic_write
 test eax,eax
 jnz .fail
 cmp qword [rsp+NEBO_G074_DIAG_CODE],0x7404
 jne .fail
 jmp .success
.s07:
 lea rdi,[rsp]
 mov esi,NEBO_G074_CATALOG_FIELD_COUNT
 call nebo_g074_catalog_counts_write
 test eax,eax
 jnz .fail
 mov edi,NEBO_G074_PRIORITY_CONTRACT
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_CONTRACT_ONLY
 jne .fail
 lea rdi,[rel g074_slash_prefix]
 mov esi,5
 lea rdx,[rsp+48]
 mov ecx,2
 call neboc_render_policy_complete
 cmp eax,1
 jne .fail
 cmp qword [rsp+48],16
 jne .fail
 mov edi,NEBO_G074_DIAG_SOURCE_CONTRACT
 mov esi,2
 mov edx,31
 lea rcx,[rsp+64]
 call nebo_g074_diagnostic_write
 test eax,eax
 jnz .fail
.success:
 mov rax,r12
 and eax,255
 jmp .done
.fail:
 mov eax,1
.done:
 add rsp,104
 pop r12
 pop rbx
 ret

; RDI adversarial case 1..6 -> zero only when the expected rejection and
; failure-atomicity invariant are both observed.
nebo_g074_negative_probe:
 sub rsp,72
 mov dword [rsp],0x5a5a5a5a
 mov dword [rsp+4],0x5a5a5a5a
 mov dword [rsp+8],0x5a5a5a5a
 mov dword [rsp+12],0x5a5a5a5a
 mov dword [rsp+16],0x5a5a5a5a
 mov dword [rsp+20],0x5a5a5a5a
 cmp rdi,1
 je .negative_percent
 cmp rdi,2
 je .negative_slash
 cmp rdi,3
 je .negative_catalog
 cmp rdi,4
 je .negative_completion
 cmp rdi,5
 je .negative_diagnostic
 cmp rdi,6
 je .negative_priority
 jmp .negative_fail
.negative_percent:
 mov edi,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 call neboc_percent_policy_validate
 test eax,eax
 jz .negative_fail
 jmp .negative_good
.negative_slash:
 mov edi,NEBO_G074_SLASH_STRICT | NEBO_G074_SLASH_UNKNOWN_TEXT
 mov esi,NEBO_G074_TARGET_TEXT
 call nebo_g074_slash_policy_validate
 cmp eax,NEBO_G074_CONFLICT
 jne .negative_fail
 jmp .negative_good
.negative_catalog:
 lea rdi,[rsp]
 mov esi,NEBO_G074_CATALOG_FIELD_COUNT-1
 call nebo_g074_catalog_counts_write
 cmp eax,NEBO_G074_CAPACITY
 jne .negative_fail
 cmp dword [rsp],0x5a5a5a5a
 jne .negative_fail
 cmp dword [rsp+4],0x5a5a5a5a
 jne .negative_fail
 jmp .negative_good
.negative_completion:
 lea rdi,[rel g074_strict_prefix]
 mov esi,3
 lea rdx,[rsp]
 mov ecx,1
 call neboc_render_policy_complete
 cmp rax,-NEBOC_G074_COMPLETION_CAPACITY
 jne .negative_fail
 cmp dword [rsp],0x5a5a5a5a
 jne .negative_fail
 cmp dword [rsp+4],0x5a5a5a5a
 jne .negative_fail
 jmp .negative_good
.negative_diagnostic:
 mov edi,NEBO_G074_DIAG_UNKNOWN_POLICY
 mov esi,9
 mov edx,2
 lea rcx,[rsp]
 call nebo_g074_diagnostic_write
 cmp eax,NEBO_G074_INVALID
 jne .negative_fail
 cmp dword [rsp],0x5a5a5a5a
 jne .negative_fail
 cmp dword [rsp+4],0x5a5a5a5a
 jne .negative_fail
 jmp .negative_good
.negative_priority:
 mov edi,4
 call nebo_g074_priority_state
 test eax,eax
 jnz .negative_fail
.negative_good:
 xor eax,eax
 add rsp,72
 ret
.negative_fail:
 mov eax,1
 add rsp,72
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
