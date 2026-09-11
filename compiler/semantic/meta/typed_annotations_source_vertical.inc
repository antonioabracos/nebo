; G143 integrated source owner for typed annotations.  A complete source slice
; is lexed, parsed, checked against AnnotationRegistry, lowered into immutable
; metadata and finally observed through the ordinary native scalar backend.
%define G143_FAMILY_KEY 0x5246323047313433
%include "compiler/parser/meta/annotation_plan.inc"

section .rodata
%macro G143_NAME 2
g143_n_%1: db %2
g143_n_%1_len equ $-g143_n_%1
%endmacro
G143_NAME version,'version'
G143_NAME level,'level'
G143_NAME enabled,'enabled'
G143_NAME label,'label'
G143_NAME seed,'seed'
G143_NAME privacy,'privacy'
G143_NAME declaration,'declaration'
G143_NAME module,'module'
G143_NAME type,'type'
G143_NAME function,'function'
G143_NAME field,'field'
G143_NAME operator,'operator'
G143_NAME registryId,'registryId'
G143_NAME identity,'identity'
G143_NAME annotationVersion,'annotationVersion'
G143_NAME targetCode,'targetCode'
G143_NAME allowedTargetCount,'allowedTargetCount'
G143_NAME argumentCount,'argumentCount'
G143_NAME argumentMask,'argumentMask'
G143_NAME defaultsApplied,'defaultsApplied'
G143_NAME levelValue,'levelValue'
G143_NAME enabledValue,'enabledValue'
G143_NAME compileTimeDigest,'compileTimeDigest'
G143_NAME runtimeDigest,'runtimeDigest'
G143_NAME provenance,'provenance'
G143_NAME privacyLevel,'privacyLevel'
G143_NAME toolingCode,'toolingCode'
G143_NAME reflectionCode,'reflectionCode'
G143_NAME checksum,'checksum'
%undef G143_NAME

section .bss align=16
g143_scratch_start:
g143_annotation_ptr: resq 1
g143_annotation_len: resq 1
g143_version: resq 1
g143_level: resq 1
g143_enabled: resq 1
g143_label_hash: resq 1
g143_argument_mask: resq 1
g143_argument_count: resq 1
g143_target: resq 1
g143_target_name_hash: resq 1
g143_seed: resq 1
g143_privacy: resq 1
g143_plan: resb NEBO_ANNOTATION_PLAN_SIZE
g143_scratch_end:

section .text

g143_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_ANNOTATION
 je .yes
 inc rbx
 jmp .scan
.yes:
 mov eax,1
 pop rbx
 ret
.no:
 xor eax,eax
 pop rbx
 ret

g143_expect:
 sub rsp,8
 call ls_expect_kind
 test eax,eax
 jz .bad
 xor eax,eax
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,8
 ret

g143_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g143_expect

g143_expect_colon:
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 jmp g143_expect

; RDI bytes, RSI byte length -> RDX stable 32-bit FNV-1a hash.
g143_hash_bytes:
 mov eax,2166136261
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx r8d,byte [rdi+rcx]
 xor eax,r8d
 imul eax,eax,16777619
 inc rcx
 jmp .loop
.done:
 mov edx,eax
 ret

; RDI token index -> RDX lexeme hash, EAX=1 success.
g143_hash_token:
 push rbx
 sub rsp,16
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 mov rdi,[rel ls_source]
 add rdi,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[rsp]
 call g143_hash_bytes
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,16
 pop rbx
 ret

; Consume a bounded Text literal and publish the content hash.
g143_parse_text_hash:
 push rbx
 push r12
 sub rsp,8
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .type
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rbx,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp r9,r8
 jb .syntax
 sub r9,r8
 cmp r9,2
 jb .syntax
 cmp r9,258
 ja .type
 mov r12,[rel ls_source]
 add r12,r8
 cmp byte [r12],'"'
 jne .type
 cmp byte [r12+r9-1],'"'
 jne .type
 lea rdi,[r12+1]
 lea rsi,[r9-2]
 call g143_hash_bytes
 inc qword [rel ls_cursor]
 xor eax,eax
 jmp .done
.type:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; EDI argument bit. EAX=0 when new, 28 on duplicate.
g143_begin_argument:
 mov rax,[rel g143_argument_mask]
 test rax,rdi
 jnz .duplicate
 or rax,rdi
 mov [rel g143_argument_mask],rax
 inc qword [rel g143_argument_count]
 xor eax,eax
 ret
.duplicate:
 mov eax,28
 ret

g143_parse_named_arguments:
 push rbx
 sub rsp,16
 mov edi,NEBOC_TOKEN_LPAREN
 call g143_expect
 test eax,eax
 jnz .done
.next:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .close
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .type
 mov rbx,[rel ls_cursor]
 lea rsi,[rel g143_n_version]
 mov edx,g143_n_version_len
 mov rdi,rbx
 call ls_token_match
 test eax,eax
 jnz .version
 lea rsi,[rel g143_n_level]
 mov edx,g143_n_level_len
 mov rdi,rbx
 call ls_token_match
 test eax,eax
 jnz .level
 lea rsi,[rel g143_n_enabled]
 mov edx,g143_n_enabled_len
 mov rdi,rbx
 call ls_token_match
 test eax,eax
 jnz .enabled
 lea rsi,[rel g143_n_label]
 mov edx,g143_n_label_len
 mov rdi,rbx
 call ls_token_match
 test eax,eax
 jnz .label
 jmp .type
.version:
 mov edi,NEBO_ANNOTATION_ARG_VERSION
 call g143_begin_argument
 test eax,eax
 jnz .done
 inc qword [rel ls_cursor]
 call g143_expect_colon
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .type
 mov [rel g143_version],rdx
 jmp .separator
.level:
 mov edi,NEBO_ANNOTATION_ARG_LEVEL
 call g143_begin_argument
 test eax,eax
 jnz .done
 inc qword [rel ls_cursor]
 call g143_expect_colon
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .type
 mov [rel g143_level],rdx
 jmp .separator
.enabled:
 mov edi,NEBO_ANNOTATION_ARG_ENABLED
 call g143_begin_argument
 test eax,eax
 jnz .done
 inc qword [rel ls_cursor]
 call g143_expect_colon
 test eax,eax
 jnz .done
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .enabled_true
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .type
 mov qword [rel g143_enabled],0
 jmp .enabled_take
.enabled_true:
 mov qword [rel g143_enabled],1
.enabled_take:
 inc qword [rel ls_cursor]
 jmp .separator
.label:
 mov edi,NEBO_ANNOTATION_ARG_LABEL
 call g143_begin_argument
 test eax,eax
 jnz .done
 inc qword [rel ls_cursor]
 call g143_expect_colon
 test eax,eax
 jnz .done
 call g143_parse_text_hash
 test eax,eax
 jnz .done
 mov [rel g143_label_hash],rdx
.separator:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .require_close
 inc qword [rel ls_cursor]
 jmp .next
.require_close:
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .syntax
.close:
 inc qword [rel ls_cursor]
 xor eax,eax
 jmp .done
.type:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,16
 pop rbx
 ret

; Select one declaration target, consume its declared name and bounded seed /
; privacy payload.  The target name contributes to provenance but not routing.
g143_parse_target:
 push rbx
 sub rsp,16
 mov rbx,[rel ls_cursor]
%macro G143_TARGET 2
 mov rdi,rbx
 lea rsi,[rel g143_n_%1]
 mov edx,g143_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .target_%1
%endmacro
 G143_TARGET declaration,NEBO_ANNOTATION_TARGET_DECLARATION
 G143_TARGET module,NEBO_ANNOTATION_TARGET_MODULE
 G143_TARGET type,NEBO_ANNOTATION_TARGET_TYPE
 G143_TARGET function,NEBO_ANNOTATION_TARGET_FUNCTION
 G143_TARGET field,NEBO_ANNOTATION_TARGET_FIELD
 G143_TARGET operator,NEBO_ANNOTATION_TARGET_OPERATOR
 jmp .type_error
%macro G143_TARGET_LABEL 2
.target_%1:
 mov qword [rel g143_target],%2
 jmp .target_selected
%endmacro
 G143_TARGET_LABEL declaration,NEBO_ANNOTATION_TARGET_DECLARATION
 G143_TARGET_LABEL module,NEBO_ANNOTATION_TARGET_MODULE
 G143_TARGET_LABEL type,NEBO_ANNOTATION_TARGET_TYPE
 G143_TARGET_LABEL function,NEBO_ANNOTATION_TARGET_FUNCTION
 G143_TARGET_LABEL field,NEBO_ANNOTATION_TARGET_FIELD
 G143_TARGET_LABEL operator,NEBO_ANNOTATION_TARGET_OPERATOR
.target_selected:
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call g143_hash_token
 test eax,eax
 jz .syntax
 mov [rel g143_target_name_hash],rdx
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g143_expect
 test eax,eax
 jnz .done
 lea rsi,[rel g143_n_seed]
 mov edx,g143_n_seed_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 call g143_expect_colon
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .type_error
 mov [rel g143_seed],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .target_close
 inc qword [rel ls_cursor]
 lea rsi,[rel g143_n_privacy]
 mov edx,g143_n_privacy_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 call g143_expect_colon
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .type_error
 mov [rel g143_privacy],rdx
.target_close:
 mov edi,NEBOC_TOKEN_RPAREN
 call g143_expect
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.type_error:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,16
 pop rbx
 ret
%undef G143_TARGET
%undef G143_TARGET_LABEL

g143_lookup_and_lower:
 sub rsp,8
 mov rdi,[rel g143_annotation_ptr]
 mov rsi,[rel g143_annotation_len]
 mov rdx,[rel g143_target]
 mov rcx,[rel g143_version]
 lea r8,[rel g143_plan]
 call nebo_annotation_registry_lookup
 test eax,eax
 jnz .domain
 mov rax,[rel g143_argument_mask]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_ARGUMENT_MASK_OFFSET],rax
 mov rax,[rel g143_argument_count]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET],rax
 mov rax,[rel g143_level]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_LEVEL_OFFSET],rax
 mov rax,[rel g143_enabled]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_ENABLED_OFFSET],rax
 mov rax,[rel g143_label_hash]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_LABEL_HASH_OFFSET],rax
 mov rax,[rel g143_seed]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_SEED_OFFSET],rax
 mov rax,[rel g143_privacy]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET],rax
 mov rax,[rel g143_target_name_hash]
 mov [rel g143_plan+NEBO_ANNOTATION_PLAN_TARGET_NAME_HASH_OFFSET],rax
 lea rdi,[rel g143_plan]
 call nebo_annotation_metadata_lower
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,8
 ret

g143_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call g143_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g143_expect
.done:
 add rsp,8
 ret

g143_parse_observer:
 push rbx
 sub rsp,16
 mov edi,NEBOC_TOKEN_DOT
 call g143_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rbx,[rel ls_cursor]
%macro G143_OBSERVER 2
 mov rdi,rbx
 lea rsi,[rel g143_n_%1]
 mov edx,g143_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G143_OBSERVER registryId,registry
 G143_OBSERVER identity,identity_value
 G143_OBSERVER annotationVersion,version_value
 G143_OBSERVER targetCode,target_code
 G143_OBSERVER allowedTargetCount,allowed_count
 G143_OBSERVER argumentCount,argument_count
 G143_OBSERVER argumentMask,argument_mask
 G143_OBSERVER defaultsApplied,defaults
 G143_OBSERVER levelValue,level_value
 G143_OBSERVER enabledValue,enabled_value
 G143_OBSERVER compileTimeDigest,compile_digest
 G143_OBSERVER runtimeDigest,runtime_digest
 G143_OBSERVER provenance,provenance_value
 G143_OBSERVER privacyLevel,privacy_value
 G143_OBSERVER toolingCode,tooling_value
 G143_OBSERVER reflectionCode,reflection_value
 G143_OBSERVER checksum,checksum_value
 jmp .type
.registry:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_REGISTRY_ID_OFFSET]
 and edx,0xff
 jmp .consume
.identity_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_KIND_OFFSET]
 jmp .consume
.version_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_VERSION_OFFSET]
 jmp .consume
.target_code:
 mov rax,[rel g143_plan+NEBO_ANNOTATION_PLAN_TARGET_OFFSET]
 xor edx,edx
.target_shift:
 inc edx
 shr rax,1
 jnz .target_shift
 jmp .consume
.allowed_count:
 mov rax,[rel g143_plan+NEBO_ANNOTATION_PLAN_ALLOWED_TARGETS_OFFSET]
 xor edx,edx
.count_loop:
 test rax,rax
 jz .consume
 mov rcx,rax
 and rcx,1
 add rdx,rcx
 shr rax,1
 jmp .count_loop
.argument_count:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET]
 jmp .consume
.argument_mask:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_ARGUMENT_MASK_OFFSET]
 jmp .consume
.defaults:
 mov edx,4
 sub rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_ARGUMENT_COUNT_OFFSET]
 jmp .consume
.level_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_LEVEL_OFFSET]
 jmp .consume
.enabled_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_ENABLED_OFFSET]
 jmp .consume
.compile_digest:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_COMPILE_DIGEST_OFFSET]
 jmp .consume
.runtime_digest:
 mov rax,[rel g143_plan+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET]
 test rax,NEBO_ANNOTATION_FLAG_RUNTIME
 jz .type
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_RUNTIME_DIGEST_OFFSET]
 jmp .consume
.provenance_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_PROVENANCE_OFFSET]
 jmp .consume
.privacy_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_PRIVACY_OFFSET]
 jmp .consume
.tooling_value:
 mov rax,[rel g143_plan+NEBO_ANNOTATION_PLAN_FLAGS_OFFSET]
 test rax,NEBO_ANNOTATION_FLAG_TOOLING
 jz .type
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_TOOLING_CODE_OFFSET]
 jmp .consume
.reflection_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_REFLECTION_CODE_OFFSET]
 jmp .consume
.checksum_value:
 mov rdx,[rel g143_plan+NEBO_ANNOTATION_PLAN_CHECKSUM_OFFSET]
.consume:
 mov [rsp],rdx
 inc qword [rel ls_cursor]
 call g143_empty_call
 mov rdx,[rsp]
 jmp .done
.type:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,16
 pop rbx
 ret
%undef G143_OBSERVER

g143_parse_program:
 push rbx
 sub rsp,16
 lea rdi,[rel g143_scratch_start]
 mov ecx,(g143_scratch_end-g143_scratch_start)/8
 xor eax,eax
 rep stosq
 mov qword [rel g143_version],1
 mov qword [rel g143_level],1
 mov qword [rel g143_enabled],1
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_ANNOTATION
 call g143_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rel g143_annotation_len],rdx
 mov rdx,[rel ls_source]
 add rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rel g143_annotation_ptr],rdx
 inc qword [rel ls_cursor]
 call g143_parse_named_arguments
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 call g143_parse_target
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 call g143_lookup_and_lower
 test eax,eax
 jnz .semantic
 call g143_parse_observer
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G143_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 mov r8,rax
 call .record_error_token
 mov edi,r8d
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
.record_error_token:
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .record
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .record
 dec rcx
.record:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 ret
.done:
 add rsp,16
 pop rbx
 ret
