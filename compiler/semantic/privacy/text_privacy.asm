; Compiler-facing semantic validation shares the runtime's frozen zone ABI.
bits 64
default rel
%include "compiler/semantic/privacy/text_privacy.inc"
extern neboc_trust_zone_valid
extern neboc_privacy_label_valid
extern neboc_privacy_join
extern neboc_sink_policy_accepts
global neboc_semantic_privacy_validate_zone
global neboc_semantic_privacy_validate_label
global neboc_semantic_privacy_join
global neboc_semantic_privacy_sink_accepts
section .text
align 16
neboc_semantic_privacy_validate_zone:
 call neboc_trust_zone_valid
 xor ecx,ecx
 test eax,eax
 setz cl
 mov eax,ecx
 ret
align 16
neboc_semantic_privacy_validate_label:
 call neboc_privacy_label_valid
 xor ecx,ecx
 test eax,eax
 setz cl
 mov eax,ecx
 ret
align 16
neboc_semantic_privacy_join:
 jmp neboc_privacy_join
align 16
neboc_semantic_privacy_sink_accepts:
 jmp neboc_sink_policy_accepts
section .note.GNU-stack noalloc noexec nowrite progbits
