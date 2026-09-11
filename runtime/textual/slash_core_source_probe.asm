; Source-to-effect bridge for the generic Slash DSL core. Mode selects a
; semantic subgroup template; all parsing/rendering remains source-byte driven.
bits 64
default rel
%define NEBO_SLASH_CORE_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/slash_core_source_probe.inc"
%include "runtime/textual/slash_dsl.inc"
%include "runtime/textual/slash_advanced.inc"

section .rodata
slash_core_s1: db '//literal /title{Parser}'
slash_core_s1_len equ $-slash_core_s1
slash_core_s2: db '/br/line/hr/title{Atlas}/subtitle{Map}/section{One}/subsection{Two}/p{Text}/quote{Quoted}/indent{Depth}/outdent/space/page'
slash_core_s2_len equ $-slash_core_s2
slash_core_s3: db '/ok{A}/success{B}/warn{C}/error{D}/fail{E}/info{F}/debug{G}/trace{H}/todo{I}/blocked{J}/green{K}/yellow{L}/red{M}'
slash_core_s3_len equ $-slash_core_s3
slash_core_s4: db '/bold{A}/italic{B}/underline{C}/dim{D}/blink{E}/code{F}/kbd{G}/mark{H}/muted{I}/strong{J}/em{K}/blue{L}/cyan{M}/magenta{N}/gray{O}/color(teal){P}/bg(navy){Q}'
slash_core_s4_len equ $-slash_core_s4
slash_core_s5: db '/list{/item{A}}/ol{/item{B}}/ul{/item{C}}/check{D}/cross{E}/task(done){F}/task(open){G}'
slash_core_s5_len equ $-slash_core_s5
slash_core_s6: db '/table{/thead{/row{/cell{H}}}/row{/cell{V}}/col{Name}/align(left){V}}'
slash_core_s6_len equ $-slash_core_s6
slash_core_s7: db '/tree{/branch{/node{N}/leaf{L}}}/json{a=1}/yaml{a: 1}/map{k:v}/object{Thing}'
slash_core_s7_len equ $-slash_core_s7
slash_core_s8: db '/bold{/ok{Parity}}'
slash_core_s8_len equ $-slash_core_s8
slash_core_s9: db '/section{/ok{/bold{Bounded}}}/list{/task(done){Closed}}'
slash_core_s9_len equ $-slash_core_s9
slash_core_s10: db '/code(nebo){let x=7}/code(c){int x=9;}/diff{delta}/added{new}/removed{old}/line(17){line}/file(src/main.no){file}'
slash_core_s10_len equ $-slash_core_s10
slash_core_s11: db '/diag{D}/hint{H}/note{N}/source{S}/cursor{C}/expected{E}/received{R}/fix{F}/explain{X}/because{B}'
slash_core_s11_len equ $-slash_core_s11
slash_core_s12: db '/metric{name=%s value=%d}/progress{%f}/bar{%d}/spark/badge/status'
slash_core_s12_len equ $-slash_core_s12
slash_core_s13: db '/md{Doc}/h1{One}/h2{Two}/link(https://nebo.dev){Nebo}/anchor/toc/admonition(info){Read}/example{Ex}/definition{Def}'
slash_core_s13_len equ $-slash_core_s13
slash_core_s14: db '/panel{P}/card{C}/grid{G}/plot{L}/dashboard{D}'
slash_core_s14_len equ $-slash_core_s14
slash_core_s15: db '/plural(1){one{unit}other{units}}/select(admin){Admin}/number(pt-PT){1234}/date(fr-FR){2026-09-02}/currency(EUR){42}'
slash_core_s15_len equ $-slash_core_s15
slash_core_s16: db '/escape{<&>}/safe{safe}/raw{raw<&>}/redact{private}/secret{token}/hash{payload}/quote{quoted}'
slash_core_s16_len equ $-slash_core_s16
slash_core_s17: db '/log(info){I}/log(warn){W}/log(error){E}/timestamp/level/scope/event/trace-id/if(true){yes}/if(false){no}/when(enabled){on}/unless(enabled){off}/empty/none'
slash_core_s17_len equ $-slash_core_s17
slash_core_s18: db '/future{kept}/safe{/if(true){bounded}}'
slash_core_s18_len equ $-slash_core_s18

slash_bad_unknown: db '/while{x}'
slash_bad_unknown_len equ $-slash_bad_unknown
slash_bad_unbalanced: db '/title{x'
slash_bad_unbalanced_len equ $-slash_bad_unbalanced
slash_bad_argument: db '/task(maybe){x}'
slash_bad_argument_len equ $-slash_bad_argument
slash_bad_content: db '/title'
slash_bad_content_len equ $-slash_bad_content

section .bss align=16
slash_core_out_a: resb 8192
slash_core_out_b: resb 8192
slash_core_stats: resb SLASH_PARSE_SIZE
slash_core_error: resb SLASH_ERROR_SIZE
slash_core_adv_error: resb SLASH_ADV_ERROR_SIZE

section .text
global nebo_slash_core_source_probe
global nebo_slash_core_negative_probe
global nebo_slash_core_render_transcript
global nebo_slash_core_template

; EDI mode -> RAX source pointer, RDX bytes; zero pointer for unknown mode.
nebo_slash_core_template:
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 cmp edi,6
 je .m6
 cmp edi,7
 je .m7
 cmp edi,8
 je .m8
 cmp edi,9
 je .m9
 cmp edi,10
 je .m10
 cmp edi,11
 je .m11
 cmp edi,12
 je .m12
 cmp edi,13
 je .m13
 cmp edi,14
 je .m14
 cmp edi,15
 je .m15
 cmp edi,16
 je .m16
 cmp edi,17
 je .m17
 cmp edi,18
 je .m18
 xor eax,eax
 xor edx,edx
 ret
.m1: lea rax,[rel slash_core_s1]
 mov edx,slash_core_s1_len
 ret
.m2: lea rax,[rel slash_core_s2]
 mov edx,slash_core_s2_len
 ret
.m3: lea rax,[rel slash_core_s3]
 mov edx,slash_core_s3_len
 ret
.m4: lea rax,[rel slash_core_s4]
 mov edx,slash_core_s4_len
 ret
.m5: lea rax,[rel slash_core_s5]
 mov edx,slash_core_s5_len
 ret
.m6: lea rax,[rel slash_core_s6]
 mov edx,slash_core_s6_len
 ret
.m7: lea rax,[rel slash_core_s7]
 mov edx,slash_core_s7_len
 ret
.m8: lea rax,[rel slash_core_s8]
 mov edx,slash_core_s8_len
 ret
.m9: lea rax,[rel slash_core_s9]
 mov edx,slash_core_s9_len
 ret
.m10: lea rax,[rel slash_core_s10]
 mov edx,slash_core_s10_len
 ret
.m11: lea rax,[rel slash_core_s11]
 mov edx,slash_core_s11_len
 ret
.m12: lea rax,[rel slash_core_s12]
 mov edx,slash_core_s12_len
 ret
.m13: lea rax,[rel slash_core_s13]
 mov edx,slash_core_s13_len
 ret
.m14: lea rax,[rel slash_core_s14]
 mov edx,slash_core_s14_len
 ret
.m15: lea rax,[rel slash_core_s15]
 mov edx,slash_core_s15_len
 ret
.m16: lea rax,[rel slash_core_s16]
 mov edx,slash_core_s16_len
 ret
.m17: lea rax,[rel slash_core_s17]
 mov edx,slash_core_s17_len
 ret
.m18: lea rax,[rel slash_core_s18]
 mov edx,slash_core_s18_len
 ret

; EDI mode, ESI seed -> EAX seed on complete parser/renderer evidence.
nebo_slash_core_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,esi
 mov r12d,edi
 call nebo_slash_core_template
 test rax,rax
 jz .unavailable
 mov r13,rax
 cmp r12d,10
 jae .advanced_validate
 mov rdi,rax
 mov esi,edx
 lea rdx,[rel slash_core_stats]
 lea rcx,[rel slash_core_error]
 call neboc_slash_parse
 test eax,eax
 jnz .return
 cmp qword [rel slash_core_stats+SLASH_PARSE_DIRECTIVES],0
 je .invalid
 cmp qword [rel slash_core_stats+SLASH_PARSE_MAX_DEPTH],SLASH_MAX_DEPTH
 ja .invalid
 cmp r12d,8
 jne .plain
 mov r12d,SLASH_TARGET_PLAIN
.target_loop:
 mov edi,8
 call nebo_slash_core_template
 mov rdi,rax
 mov esi,edx
 mov edx,r12d
 lea rcx,[rel slash_core_out_a]
 mov r8d,8192
 call neboc_slash_render
 test rax,rax
 js .return
 inc r12d
 cmp r12d,SLASH_TARGET_CONSOLE+1
 jb .target_loop
 jmp .success
.plain:
 mov edi,r12d
 call nebo_slash_core_template
 mov rdi,rax
 mov esi,edx
 mov edx,SLASH_TARGET_PLAIN
 lea rcx,[rel slash_core_out_a]
 mov r8d,8192
 call neboc_slash_render
 test rax,rax
 js .return
 jmp .success
.advanced_validate:
 mov rdi,r13
 mov esi,edx
 xor edx,edx
 cmp r12d,16
 jne .advanced_unknown
 mov edx,SLASH_ADV_POLICY_ALLOW_RAW
.advanced_unknown:
 cmp r12d,18
 jne .advanced_validate_call
 mov edx,SLASH_ADV_POLICY_UNKNOWN_TEXT
.advanced_validate_call:
 lea rcx,[rel slash_core_adv_error]
 call neboc_slash_advanced_validate
 test eax,eax
 jnz .return
 cmp r12d,18
 jne .advanced_plain
 mov r13d,SLASH_ADV_TARGET_PLAIN
.advanced_target_loop:
 mov edi,18
 call nebo_slash_core_template
 mov rdi,rax
 mov esi,edx
 mov edx,r13d
 mov ecx,SLASH_ADV_POLICY_UNKNOWN_TEXT
 lea r8,[rel slash_core_out_a]
 mov r9d,8192
 call neboc_slash_advanced_render
 test rax,rax
 js .return
 inc r13d
 cmp r13d,SLASH_ADV_TARGET_CONSOLE+1
 jb .advanced_target_loop
 jmp .success
.advanced_plain:
 mov edi,r12d
 call nebo_slash_core_template
 mov rdi,rax
 mov esi,edx
 mov edx,SLASH_ADV_TARGET_PLAIN
 xor ecx,ecx
 cmp r12d,16
 jne .advanced_render_call
 mov ecx,SLASH_ADV_POLICY_ALLOW_RAW
.advanced_render_call:
 lea r8,[rel slash_core_out_a]
 mov r9d,8192
 call neboc_slash_advanced_render
 test rax,rax
 js .return
.success:
 mov eax,ebx
 jmp .return
.unavailable:
 mov eax,SLASH_E_TARGET
 jmp .return
.invalid:
 mov eax,SLASH_E_INVALID
.return:
 pop r13
 pop r12
 pop rbx
 ret

; EDI case -> positive typed error status.
nebo_slash_core_negative_probe:
 cmp edi,1
 je .unknown
 cmp edi,2
 je .unbalanced
 cmp edi,3
 je .argument
 cmp edi,4
 je .content
 cmp edi,5
 je .capacity
 cmp edi,6
 je .target
 mov eax,SLASH_E_TARGET
 ret
.unknown:
 lea rdi,[rel slash_bad_unknown]
 mov esi,slash_bad_unknown_len
 jmp .validate
.unbalanced:
 lea rdi,[rel slash_bad_unbalanced]
 mov esi,slash_bad_unbalanced_len
 jmp .validate
.argument:
 lea rdi,[rel slash_bad_argument]
 mov esi,slash_bad_argument_len
 jmp .validate
.content:
 lea rdi,[rel slash_bad_content]
 mov esi,slash_bad_content_len
.validate:
 call neboc_slash_validate
 ret
.capacity:
 lea rdi,[rel slash_core_s9]
 mov esi,slash_core_s9_len
 mov edx,SLASH_TARGET_PLAIN
 lea rcx,[rel slash_core_out_a]
 mov r8d,1
 call neboc_slash_render
 neg eax
 ret
.target:
 lea rdi,[rel slash_core_s9]
 mov esi,slash_core_s9_len
 mov edx,99
 lea rcx,[rel slash_core_out_a]
 mov r8d,8192
 call neboc_slash_render
 neg eax
 ret

; EDI mode, ESI target, RDX output, RCX capacity -> RAX bytes/error.
nebo_slash_core_render_transcript:
 push r12
 push r13
 push r14
 push r15
 mov r14d,edi
 mov r12,rsi
 mov r13,rdx
 mov r15,rcx
 call nebo_slash_core_template
 test rax,rax
 jz .bad
 mov rdi,rax
 mov esi,edx
 cmp r14d,10
 jae .advanced
 mov edx,r12d
 mov r8,r15
 mov rcx,r13
 call neboc_slash_render
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.advanced:
 mov edx,r12d
 xor ecx,ecx
 cmp r14d,16
 jne .transcript_unknown
 mov ecx,SLASH_ADV_POLICY_ALLOW_RAW
.transcript_unknown:
 cmp r14d,18
 jne .transcript_call
 mov ecx,SLASH_ADV_POLICY_UNKNOWN_TEXT
.transcript_call:
 mov r8,r13
 mov r9,r15
 call neboc_slash_advanced_render
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov rax,-SLASH_E_TARGET
 pop r15
 pop r14
 pop r13
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
