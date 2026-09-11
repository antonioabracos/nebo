; G025 canonical public-source owner for effects, authority, privacy,
; observability, provenance and explainable audit.
%define G25_FAMILY_KEY 0x5246323034473235

section .rodata
%macro G25_NAME 2
g25_n_%1: db %2
g25_n_%1_len equ $-g25_n_%1
%endmacro
G25_NAME effects,'effects'
G25_NAME effect,'effect'
G25_NAME console_write,'console_write'
G25_NAME file_read,'fileRead'
G25_NAME file_write,'fileWrite'
G25_NAME network,'network'
G25_NAME process,'process'
G25_NAME random,'random'
G25_NAME function,'function'
G25_NAME file_capability,'FileCapability'
G25_NAME network_capability,'NetworkCapability'
G25_NAME process_capability,'ProcessCapability'
G25_NAME capabilities,'capabilities'
G25_NAME for_root,'forRoot'
G25_NAME for_hosts,'forHosts'
G25_NAME for_programs,'forPrograms'
G25_NAME capability,'capability'
G25_NAME attenuate,'attenuate'
G25_NAME scope,'scope'
G25_NAME context,'context'
G25_NAME require,'require'
G25_NAME policy_type,'Policy'
G25_NAME permit,'permit'
G25_NAME allow,'allow'
G25_NAME deny,'deny'
G25_NAME budget,'budget'
G25_NAME trust,'trust'
G25_NAME evaluate,'evaluate'
G25_NAME explain,'explain'
G25_NAME sensitive_type,'Sensitive'
G25_NAME new,'new'
G25_NAME reveal,'reveal'
G25_NAME redact,'redact'
G25_NAME privacy_policy,'PrivacyPolicy'
G25_NAME allow_purpose,'allowPurpose'
G25_NAME privacy,'privacy'
G25_NAME check_flow,'checkFlow'
G25_NAME audit,'audit'
G25_NAME log_type,'Log'
G25_NAME event,'event'
G25_NAME log,'log'
G25_NAME level,'level'
G25_NAME metrics,'Metrics'
G25_NAME counter,'counter'
G25_NAME add,'add'
G25_NAME histogram,'histogram'
G25_NAME trace,'Trace'
G25_NAME span,'span'
G25_NAME attribute,'attribute'
G25_NAME end,'end'
G25_NAME quality,'Quality'
G25_NAME lineage,'lineage'
G25_NAME provenance_type,'Provenance'
G25_NAME source,'source'
G25_NAME provenance,'provenance'
G25_NAME transform,'transform'
G25_NAME artifact,'artifact'
G25_NAME attach_provenance,'attachProvenance'
G25_NAME lineage_type,'Lineage'
G25_NAME parents,'parents'
G25_NAME report,'report'
G25_NAME audit_type,'Audit'
G25_NAME record,'record'
G25_NAME query,'query'
G25_NAME verify_chain,'verifyChain'
G25_NAME runtime_type,'Runtime'
G25_NAME explain_last_error,'explainLastError'
G25_NAME explain_access,'explainAccess'
G25_NAME compiler_type,'Compiler'
G25_NAME explain_effects,'explainEffects'
%undef G25_NAME

section .bss align=16
g25_mode: resq 1
g25_seed: resq 1

section .text
%macro G25_REQUIRE 2
 lea rsi,[rel g25_n_%1]
 mov edx,g25_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g25_known_call:
 push rbx
 mov rbx,rdi
%macro G25_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g25_n_%1]
 mov edx,g25_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G25_KNOWN effects
 G25_KNOWN for_root
 G25_KNOWN for_hosts
 G25_KNOWN for_programs
 G25_KNOWN attenuate
 G25_KNOWN scope
 G25_KNOWN require
 G25_KNOWN permit
 G25_KNOWN allow
 G25_KNOWN deny
 G25_KNOWN budget
 G25_KNOWN trust
 G25_KNOWN evaluate
 G25_KNOWN explain
 G25_KNOWN new
 G25_KNOWN reveal
 G25_KNOWN redact
 G25_KNOWN allow_purpose
 G25_KNOWN check_flow
 G25_KNOWN audit
 G25_KNOWN event
 G25_KNOWN level
 G25_KNOWN counter
 G25_KNOWN add
 G25_KNOWN histogram
 G25_KNOWN span
 G25_KNOWN attribute
 G25_KNOWN end
 G25_KNOWN lineage
 G25_KNOWN source
 G25_KNOWN transform
 G25_KNOWN attach_provenance
 G25_KNOWN parents
 G25_KNOWN report
 G25_KNOWN record
 G25_KNOWN query
 G25_KNOWN verify_chain
 G25_KNOWN explain_last_error
 G25_KNOWN explain_access
 G25_KNOWN explain_effects
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G25_KNOWN

g25_select_mode:
 G25_REQUIRE audit_type,.not_s07
 G25_REQUIRE record,.not_s07
 G25_REQUIRE audit,.not_s07
 G25_REQUIRE query,.not_s07
 G25_REQUIRE verify_chain,.not_s07
 G25_REQUIRE runtime_type,.not_s07
 G25_REQUIRE explain_last_error,.not_s07
 G25_REQUIRE policy_type,.not_s07
 G25_REQUIRE explain_access,.not_s07
 G25_REQUIRE compiler_type,.not_s07
 G25_REQUIRE explain_effects,.not_s07
 mov eax,7
 ret
.not_s07:
 G25_REQUIRE quality,.not_s06
 G25_REQUIRE lineage,.not_s06
 G25_REQUIRE provenance_type,.not_s06
 G25_REQUIRE source,.not_s06
 G25_REQUIRE provenance,.not_s06
 G25_REQUIRE transform,.not_s06
 G25_REQUIRE artifact,.not_s06
 G25_REQUIRE attach_provenance,.not_s06
 G25_REQUIRE lineage_type,.not_s06
 G25_REQUIRE parents,.not_s06
 G25_REQUIRE require,.not_s06
 G25_REQUIRE report,.not_s06
 mov eax,6
 ret
.not_s06:
 G25_REQUIRE log_type,.not_s05
 G25_REQUIRE event,.not_s05
 G25_REQUIRE log,.not_s05
 G25_REQUIRE level,.not_s05
 G25_REQUIRE metrics,.not_s05
 G25_REQUIRE counter,.not_s05
 G25_REQUIRE add,.not_s05
 G25_REQUIRE histogram,.not_s05
 G25_REQUIRE trace,.not_s05
 G25_REQUIRE span,.not_s05
 G25_REQUIRE attribute,.not_s05
 G25_REQUIRE end,.not_s05
 mov eax,5
 ret
.not_s05:
 G25_REQUIRE sensitive_type,.not_s04
 G25_REQUIRE new,.not_s04
 G25_REQUIRE reveal,.not_s04
 G25_REQUIRE redact,.not_s04
 G25_REQUIRE privacy_policy,.not_s04
 G25_REQUIRE allow_purpose,.not_s04
 G25_REQUIRE privacy,.not_s04
 G25_REQUIRE check_flow,.not_s04
 G25_REQUIRE audit,.not_s04
 mov eax,4
 ret
.not_s04:
 G25_REQUIRE policy_type,.not_s03
 G25_REQUIRE permit,.not_s03
 G25_REQUIRE allow,.not_s03
 G25_REQUIRE deny,.not_s03
 G25_REQUIRE budget,.not_s03
 G25_REQUIRE trust,.not_s03
 G25_REQUIRE evaluate,.not_s03
 G25_REQUIRE explain,.not_s03
 mov eax,3
 ret
.not_s03:
 G25_REQUIRE file_capability,.not_s02
 G25_REQUIRE network_capability,.not_s02
 G25_REQUIRE process_capability,.not_s02
 G25_REQUIRE capabilities,.not_s02
 G25_REQUIRE for_root,.not_s02
 G25_REQUIRE for_hosts,.not_s02
 G25_REQUIRE for_programs,.not_s02
 G25_REQUIRE capability,.not_s02
 G25_REQUIRE attenuate,.not_s02
 G25_REQUIRE scope,.not_s02
 G25_REQUIRE context,.not_s02
 G25_REQUIRE require,.not_s02
 mov eax,2
 ret
.not_s02:
 G25_REQUIRE effects,.not_s01
 G25_REQUIRE console_write,.not_s01
 G25_REQUIRE effect,.not_s01
 G25_REQUIRE file_read,.not_s01
 G25_REQUIRE file_write,.not_s01
 G25_REQUIRE network,.not_s01
 G25_REQUIRE process,.not_s01
 G25_REQUIRE random,.not_s01
 G25_REQUIRE function,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g25_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g25_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g25_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g25_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g25_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g025_source_parse:
 mov qword [rel g25_mode],0
 mov qword [rel g25_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g25_select_mode
 test eax,eax
 jz .syntax
 mov [rel g25_mode],rax
 call g25_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g25_mode]
 shl rax,32
 mov edi,dword [rel g25_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G25_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G25_REQUIRE
