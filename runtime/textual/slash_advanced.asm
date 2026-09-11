; Advanced bounded Slash DSL owner for G065. The registry, parser, policies,
; conditional evaluator, security redaction, and five render targets are all
; selected from source bytes. There is no path/fixture dispatch and no ambient
; locale, clock, terminal, or environment dependency.
bits 64
default rel
%define NEBO_SLASH_ADVANCED_IMPLEMENTATION 1
%include "runtime/textual/slash_advanced.inc"

ADV_F_CONTENT equ 1
ADV_F_ARGUMENT equ 2
ADV_F_OPTIONAL_ARGUMENT equ 4
ADV_ROW_SIZE equ 24

ADV_FRAME_SUPPRESS equ 1
ADV_FRAME_TRANSPARENT equ 2
ADV_FRAME_PLURAL_ONE equ 4

section .rodata
%macro ADV_NAME 4
adv_name_%1: db %2
adv_name_%1_len equ $-adv_name_%1
%endmacro
ADV_NAME code,'code',1,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME diff,'diff',2,ADV_F_CONTENT
ADV_NAME added,'added',3,ADV_F_CONTENT
ADV_NAME removed,'removed',4,ADV_F_CONTENT
ADV_NAME line,'line',5,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME file,'file',6,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME diag,'diag',7,ADV_F_CONTENT
ADV_NAME hint,'hint',8,ADV_F_CONTENT
ADV_NAME note,'note',9,ADV_F_CONTENT
ADV_NAME source,'source',10,ADV_F_CONTENT
ADV_NAME cursor,'cursor',11,ADV_F_CONTENT
ADV_NAME expected,'expected',12,ADV_F_CONTENT
ADV_NAME received,'received',13,ADV_F_CONTENT
ADV_NAME fix,'fix',14,ADV_F_CONTENT
ADV_NAME explain,'explain',15,ADV_F_CONTENT
ADV_NAME because,'because',16,ADV_F_CONTENT
ADV_NAME metric,'metric',17,ADV_F_CONTENT
ADV_NAME progress,'progress',18,ADV_F_CONTENT
ADV_NAME bar,'bar',19,ADV_F_CONTENT
ADV_NAME spark,'spark',20,0
ADV_NAME badge,'badge',21,0
ADV_NAME status,'status',22,0
ADV_NAME md,'md',23,ADV_F_CONTENT
ADV_NAME h1,'h1',24,ADV_F_CONTENT
ADV_NAME h2,'h2',25,ADV_F_CONTENT
ADV_NAME link,'link',26,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME anchor,'anchor',27,0
ADV_NAME toc,'toc',28,0
ADV_NAME admonition,'admonition',29,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME example,'example',30,ADV_F_CONTENT
ADV_NAME definition,'definition',31,ADV_F_CONTENT
ADV_NAME panel,'panel',32,ADV_F_CONTENT
ADV_NAME card,'card',33,ADV_F_CONTENT
ADV_NAME grid,'grid',34,ADV_F_CONTENT
ADV_NAME plot,'plot',35,ADV_F_CONTENT
ADV_NAME dashboard,'dashboard',36,ADV_F_CONTENT
ADV_NAME plural,'plural',37,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME select,'select',38,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME number,'number',39,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME date,'date',40,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME currency,'currency',41,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME escape,'escape',42,ADV_F_CONTENT
ADV_NAME safe,'safe',43,ADV_F_CONTENT
ADV_NAME raw,'raw',44,ADV_F_CONTENT
ADV_NAME redact,'redact',45,ADV_F_CONTENT
ADV_NAME secret,'secret',46,ADV_F_CONTENT
ADV_NAME hash,'hash',47,ADV_F_CONTENT
ADV_NAME quote,'quote',48,ADV_F_CONTENT
ADV_NAME log,'log',49,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME timestamp,'timestamp',50,0
ADV_NAME level,'level',51,0
ADV_NAME scope,'scope',52,0
ADV_NAME event,'event',53,0
ADV_NAME trace_id,'trace-id',54,0
ADV_NAME if,'if',55,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME when,'when',56,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME unless,'unless',57,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_NAME empty,'empty',58,0
ADV_NAME none,'none',59,0
%undef ADV_NAME

%macro ADV_ROW 3
 dq adv_name_%1
 dd adv_name_%1_len,%3,%2,0
%endmacro
adv_registry:
ADV_ROW code,1,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW diff,2,ADV_F_CONTENT
ADV_ROW added,3,ADV_F_CONTENT
ADV_ROW removed,4,ADV_F_CONTENT
ADV_ROW line,5,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW file,6,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW diag,7,ADV_F_CONTENT
ADV_ROW hint,8,ADV_F_CONTENT
ADV_ROW note,9,ADV_F_CONTENT
ADV_ROW source,10,ADV_F_CONTENT
ADV_ROW cursor,11,ADV_F_CONTENT
ADV_ROW expected,12,ADV_F_CONTENT
ADV_ROW received,13,ADV_F_CONTENT
ADV_ROW fix,14,ADV_F_CONTENT
ADV_ROW explain,15,ADV_F_CONTENT
ADV_ROW because,16,ADV_F_CONTENT
ADV_ROW metric,17,ADV_F_CONTENT
ADV_ROW progress,18,ADV_F_CONTENT
ADV_ROW bar,19,ADV_F_CONTENT
ADV_ROW spark,20,0
ADV_ROW badge,21,0
ADV_ROW status,22,0
ADV_ROW md,23,ADV_F_CONTENT
ADV_ROW h1,24,ADV_F_CONTENT
ADV_ROW h2,25,ADV_F_CONTENT
ADV_ROW link,26,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW anchor,27,0
ADV_ROW toc,28,0
ADV_ROW admonition,29,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW example,30,ADV_F_CONTENT
ADV_ROW definition,31,ADV_F_CONTENT
ADV_ROW panel,32,ADV_F_CONTENT
ADV_ROW card,33,ADV_F_CONTENT
ADV_ROW grid,34,ADV_F_CONTENT
ADV_ROW plot,35,ADV_F_CONTENT
ADV_ROW dashboard,36,ADV_F_CONTENT
ADV_ROW plural,37,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW select,38,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW number,39,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW date,40,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW currency,41,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW escape,42,ADV_F_CONTENT
ADV_ROW safe,43,ADV_F_CONTENT
ADV_ROW raw,44,ADV_F_CONTENT
ADV_ROW redact,45,ADV_F_CONTENT
ADV_ROW secret,46,ADV_F_CONTENT
ADV_ROW hash,47,ADV_F_CONTENT
ADV_ROW quote,48,ADV_F_CONTENT
ADV_ROW log,49,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW timestamp,50,0
ADV_ROW level,51,0
ADV_ROW scope,52,0
ADV_ROW event,53,0
ADV_ROW trace_id,54,0
ADV_ROW if,55,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW when,56,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW unless,57,ADV_F_CONTENT|ADV_F_ARGUMENT
ADV_ROW empty,58,0
ADV_ROW none,59,0
%undef ADV_ROW

global neboc_slash_advanced_registry_count
neboc_slash_advanced_registry_count: dq 59

adv_nebo: db 'nebo'
adv_c: db 'c'
adv_info: db 'info'
adv_warn: db 'warn'
adv_error: db 'error'
adv_true: db 'true'
adv_false: db 'false'
adv_enabled: db 'enabled'
adv_disabled: db 'disabled'
adv_eur: db 'EUR'
adv_en_us: db 'en-US'
adv_pt_pt: db 'pt-PT'
adv_fr_fr: db 'fr-FR'

adv_plain_open: db '['
adv_plain_close: db ']'
adv_console_open: db '<'
adv_console_close: db '>'
adv_md_open: db '**'
adv_md_close: db '**'
adv_html_open: db '<span data-slash65="'
adv_html_open_len equ $-adv_html_open
adv_html_mid: db '">'
adv_html_close: db '</span>'
adv_ansi_open: db 27,'[1m['
adv_ansi_open_len equ $-adv_ansi_open
adv_ansi_close: db ']',27,'[0m'
adv_ansi_close_len equ $-adv_ansi_close
adv_arg_open: db '('
adv_arg_close: db ')'
adv_redacted: db '[redacted]'
adv_redacted_len equ $-adv_redacted
adv_hashed: db '[hash]'
adv_hashed_len equ $-adv_hashed
adv_html_doc_open: db '<div class="slash65">'
adv_html_doc_open_len equ $-adv_html_doc_open
adv_html_doc_close: db '</div>'
adv_html_doc_close_len equ $-adv_html_doc_close
adv_md_doc_open: db '<!-- slash65 -->'
adv_md_doc_open_len equ $-adv_md_doc_open
adv_md_doc_close: db '<!-- /slash65 -->'
adv_md_doc_close_len equ $-adv_md_doc_close
adv_amp: db '&amp;'
adv_lt: db '&lt;'
adv_gt: db '&gt;'

section .text
global neboc_slash_advanced_validate
global neboc_slash_advanced_render

; RDI name, RSI bytes -> EAX id (0 unknown), EDX flags.
adv_lookup:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 lea rbx,[rel adv_registry]
 mov ecx,59
.row:
 cmp r13d,[rbx+8]
 jne .next
 mov rdi,r12
 mov rsi,[rbx]
 mov r8,r13
.compare:
 test r8,r8
 jz .found
 mov al,[rdi]
 cmp al,[rsi]
 jne .next
 inc rdi
 inc rsi
 dec r8
 jmp .compare
.found:
 mov edx,[rbx+12]
 mov eax,[rbx+16]
 jmp .done
.next:
 add rbx,ADV_ROW_SIZE
 dec ecx
 jnz .row
 xor eax,eax
 xor edx,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI input, RSI bytes, R8 expected, R9 bytes -> EAX boolean.
adv_equals:
 cmp rsi,r9
 jne .no
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 je .yes
 mov al,[rdi+rcx]
 cmp al,[r8+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RDI argument, RSI bytes, EDX directive id -> EAX boolean.
adv_argument_valid:
 push rbx
 mov ebx,edx
 test rsi,rsi
 jz .no
 cmp rsi,MAX_SLASH_ARGUMENT
 ja .no
 cmp ebx,1
 je .code
 cmp ebx,5
 je .decimal
 cmp ebx,29
 je .admonition
 cmp ebx,37
 je .decimal
 cmp ebx,39
 je .locale
 cmp ebx,40
 je .locale
 cmp ebx,41
 je .currency
 cmp ebx,49
 je .log
 cmp ebx,55
 je .boolean
 cmp ebx,56
 je .enabled
 cmp ebx,57
 je .enabled
 ; File, link, select, and other named arguments use bounded visible ASCII.
 xor ecx,ecx
.visible:
 mov al,[rdi+rcx]
 cmp al,33
 jb .no
 cmp al,126
 ja .no
 cmp al,'('
 je .no
 cmp al,')'
 je .no
 cmp al,'{'
 je .no
 cmp al,'}'
 je .no
 cmp al,'"'
 je .no
 cmp al,39
 je .no
 cmp al,'<'
 je .no
 cmp al,'>'
 je .no
 cmp al,'&'
 je .no
 inc rcx
 cmp rcx,rsi
 jb .visible
 jmp .yes
.decimal:
 xor ecx,ecx
.digits:
 mov al,[rdi+rcx]
 cmp al,'0'
 jb .no
 cmp al,'9'
 ja .no
 inc rcx
 cmp rcx,rsi
 jb .digits
 jmp .yes
.code:
 lea r8,[rel adv_nebo]
 mov r9d,4
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_c]
 mov r9d,1
 jmp .one_equals
.admonition:
 lea r8,[rel adv_info]
 mov r9d,4
 jmp .one_equals
.currency:
 lea r8,[rel adv_eur]
 mov r9d,3
 jmp .one_equals
.boolean:
 lea r8,[rel adv_true]
 mov r9d,4
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_false]
 mov r9d,5
 jmp .one_equals
.enabled:
 lea r8,[rel adv_enabled]
 mov r9d,7
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_disabled]
 mov r9d,8
 jmp .one_equals
.log:
 lea r8,[rel adv_info]
 mov r9d,4
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_warn]
 mov r9d,4
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_error]
 mov r9d,5
 jmp .one_equals
.locale:
 lea r8,[rel adv_en_us]
 mov r9d,5
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_pt_pt]
 mov r9d,5
 call adv_equals
 test eax,eax
 jnz .yes
 lea r8,[rel adv_fr_fr]
 mov r9d,5
.one_equals:
 call adv_equals
 test eax,eax
 jz .no
.yes:
 mov eax,1
 pop rbx
 ret
.no:
 xor eax,eax
 pop rbx
 ret

; RDI source, RSI bytes, EDX policy, RCX SlashAdvancedError* -> EAX status.
neboc_slash_advanced_validate:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov r12,rdi
 mov r13,rsi
 mov [rbp-48],rcx
 mov [rbp-56],rdx
 xor ebx,ebx
 xor r14d,r14d
 xor r15d,r15d
 mov qword [rbp-64],0
 test r12,r12
 jz .invalid
 test r13,r13
 jz .syntax
 cmp r13,MAX_SLASH_INPUT
 ja .limit
 mov rax,[rbp-48]
 test rax,rax
 jz .scan
 mov qword [rax+SLASH_ADV_ERROR_CODE],0
 mov qword [rax+SLASH_ADV_ERROR_START],0
 mov qword [rax+SLASH_ADV_ERROR_END],0
.scan:
 cmp rbx,r13
 jae .finish
 mov al,[r12+rbx]
 cmp al,'/'
 je .slash
 cmp al,'{'
 je .open_bare
 cmp al,'}'
 je .close
 inc rbx
 jmp .scan
.open_bare:
 inc r14
 cmp r14,MAX_SLASH_DEPTH
 ja .limit
 cmp r14,[rbp-64]
 jbe .bare_next
 mov [rbp-64],r14
.bare_next:
 inc rbx
 jmp .scan
.close:
 test r14,r14
 jz .syntax
 dec r14
 inc rbx
 jmp .scan
.slash:
 lea rax,[rbx+1]
 cmp rax,r13
 jae .syntax
 cmp byte [r12+rbx+1],47
 je .escape_two
 lea r10,[rbx+1]
 mov r11,r10
.name:
 cmp r11,r13
 jae .name_done
 mov al,[r12+r11]
 cmp al,'A'
 jb .lower
 cmp al,'Z'
 jbe .name_next
.lower:
 cmp al,'a'
 jb .hyphen
 cmp al,'z'
 jbe .name_next
.hyphen:
 cmp al,'-'
 je .name_punct
 cmp al,'0'
 jb .name_done
 cmp al,'9'
 ja .name_done
.name_punct:
 cmp r11,r10
 je .syntax
.name_next:
 inc r11
 jmp .name
.name_done:
 cmp r11,r10
 je .syntax
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 call adv_lookup
 mov [rbp-68],eax
 mov [rbp-72],edx
 test eax,eax
 jnz .known
 mov eax,[rbp-56]
 test eax,SLASH_ADV_POLICY_UNKNOWN_TEXT
 jz .unknown
 mov dword [rbp-72],ADV_F_CONTENT|ADV_F_OPTIONAL_ARGUMENT
.known:
 inc r15
 cmp r15,MAX_SLASH_NODES
 ja .limit
 mov rbx,r11
 mov edx,[rbp-72]
 test edx,ADV_F_ARGUMENT
 jnz .required_arg
 test edx,ADV_F_OPTIONAL_ARGUMENT
 jz .no_arg
 cmp rbx,r13
 jae .no_arg
 cmp byte [r12+rbx],'('
 jne .no_arg
 jmp .parse_arg
.required_arg:
 cmp rbx,r13
 jae .argument
 cmp byte [r12+rbx],'('
 jne .argument
.parse_arg:
 lea r10,[rbx+1]
 mov r11,r10
.arg_scan:
 cmp r11,r13
 jae .syntax
 cmp byte [r12+r11],')'
 je .arg_done
 inc r11
 mov rax,r11
 sub rax,r10
 cmp rax,MAX_SLASH_ARGUMENT
 ja .limit
 jmp .arg_scan
.arg_done:
 cmp dword [rbp-68],0
 je .arg_accepted
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 mov edx,[rbp-68]
 call adv_argument_valid
 test eax,eax
 jz .argument
.arg_accepted:
 lea rbx,[r11+1]
.no_arg:
 cmp dword [rbp-68],44
 jne .content
 mov eax,[rbp-56]
 test eax,SLASH_ADV_POLICY_ALLOW_RAW
 jz .policy
.content:
 mov edx,[rbp-72]
 test edx,ADV_F_CONTENT
 jz .without_content
 cmp rbx,r13
 jae .syntax
 cmp byte [r12+rbx],'{'
 jne .syntax
 inc r14
 cmp r14,MAX_SLASH_DEPTH
 ja .limit
 cmp r14,[rbp-64]
 jbe .content_next
 mov [rbp-64],r14
.content_next:
 inc rbx
 jmp .scan
.without_content:
 cmp rbx,r13
 jae .scan
 cmp byte [r12+rbx],'('
 je .argument
 cmp byte [r12+rbx],'{'
 je .syntax
 jmp .scan
.escape_two:
 add rbx,2
 jmp .scan
.finish:
 test r14,r14
 jnz .syntax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,SLASH_ADV_E_INVALID
 jmp .record
.limit:
 mov eax,SLASH_ADV_E_LIMIT
 jmp .record
.syntax:
 mov eax,SLASH_ADV_E_SYNTAX
 jmp .record
.unknown:
 mov eax,SLASH_ADV_E_UNKNOWN
 jmp .record
.argument:
 mov eax,SLASH_ADV_E_ARGUMENT
 jmp .record
.policy:
 mov eax,SLASH_ADV_E_POLICY
.record:
 mov rcx,[rbp-48]
 test rcx,rcx
 jz .done
 mov [rcx+SLASH_ADV_ERROR_CODE],rax
 mov [rcx+SLASH_ADV_ERROR_START],rbx
 lea rdx,[rbx+1]
 cmp rdx,r13
 cmova rdx,r13
 mov [rcx+SLASH_ADV_ERROR_END],rdx
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

; Render implementation deliberately follows validation. It preserves source
; content, makes directive semantics visible without color, suppresses secrets
; and false conditional branches, and escapes HTML sinks even for /raw.
; RDI source, RSI bytes, EDX target, ECX policy, R8 output-or-null, R9 capacity.
adv_render_pass:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,520
 mov r12,rdi
 mov r13,rsi
 mov [rbp-48],rdx
 mov [rbp-56],rcx
 mov [rbp-64],r8
 mov [rbp-72],r9
 mov qword [rbp-80],0       ; frame depth
 mov qword [rbp-88],0       ; suppression depth
 xor ebx,ebx
 xor r14d,r14d
 cmp edx,SLASH_ADV_TARGET_HTML
 jne .prefix_md
 lea rdi,[rel adv_html_doc_open]
 mov esi,adv_html_doc_open_len
 call .emit_seq
 jmp .scan
.prefix_md:
 cmp edx,SLASH_ADV_TARGET_MARKDOWN
 jne .scan
 lea rdi,[rel adv_md_doc_open]
 mov esi,adv_md_doc_open_len
 call .emit_seq
.scan:
 cmp rbx,r13
 jae .suffix
 ; Recognize bare plural arms only immediately inside /plural.
 cmp qword [rbp-80],0
 je .scan_byte
 mov rcx,[rbp-80]
 dec rcx
 shl rcx,4
 lea rax,[rbp-176]
 sub rax,rcx
 cmp qword [rax],37
 jne .scan_byte
 lea rax,[rbx+4]
 cmp rax,r13
 ja .plural_other
 cmp byte [r12+rbx],'o'
 jne .plural_other
 cmp byte [r12+rbx+1],'n'
 jne .plural_other
 cmp byte [r12+rbx+2],'e'
 jne .plural_other
 cmp byte [r12+rbx+3],'{'
 jne .plural_other
 mov edi,100
 mov esi,ADV_FRAME_PLURAL_ONE
 call .push_plural_arm
 add rbx,4
 jmp .scan
.plural_other:
 lea rax,[rbx+6]
 cmp rax,r13
 ja .scan_byte
 cmp byte [r12+rbx],'o'
 jne .scan_byte
 cmp byte [r12+rbx+1],'t'
 jne .scan_byte
 cmp byte [r12+rbx+2],'h'
 jne .scan_byte
 cmp byte [r12+rbx+3],'e'
 jne .scan_byte
 cmp byte [r12+rbx+4],'r'
 jne .scan_byte
 cmp byte [r12+rbx+5],'{'
 jne .scan_byte
 mov edi,101
 xor esi,esi
 call .push_plural_arm
 add rbx,6
 jmp .scan
.scan_byte:
 mov al,[r12+rbx]
 cmp al,'/'
 je .slash
 cmp al,'}'
 je .close
 cmp al,'{'
 je .bare_open
 cmp qword [rbp-88],0
 jne .ordinary_next
 mov dil,al
 call .emit_ordinary
.ordinary_next:
 inc rbx
 jmp .scan
.bare_open:
 mov edi,102
 xor esi,esi
 call .push_frame
 inc rbx
 jmp .scan
.slash:
 cmp byte [r12+rbx+1],47
 jne .directive
 cmp qword [rbp-88],0
 jne .escaped_next
 mov edi,'/'
 call .emit_ordinary
.escaped_next:
 add rbx,2
 jmp .scan
.directive:
 lea r10,[rbx+1]
 mov r11,r10
.name:
 cmp r11,r13
 jae .name_done
 mov al,[r12+r11]
 cmp al,'A'
 jb .lower
 cmp al,'Z'
 jbe .name_next
.lower:
 cmp al,'a'
 jb .hyphen
 cmp al,'z'
 jbe .name_next
.hyphen:
 cmp al,'-'
 je .name_next
 cmp al,'0'
 jb .name_done
 cmp al,'9'
 ja .name_done
.name_next:
 inc r11
 jmp .name
.name_done:
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 mov [rbp-96],rdi
 mov [rbp-104],rsi
 call adv_lookup
 mov [rbp-112],rax
 mov [rbp-120],rdx
 mov qword [rbp-128],0
 mov qword [rbp-136],0
 mov rbx,r11
 test edx,ADV_F_ARGUMENT|ADV_F_OPTIONAL_ARGUMENT
 jz .after_arg
 cmp rbx,r13
 jae .after_arg
 cmp byte [r12+rbx],'('
 jne .after_arg
 inc rbx
 lea rax,[r12+rbx]
 mov [rbp-128],rax
.arg_scan:
 cmp byte [r12+rbx],')'
 je .arg_end
 inc rbx
 jmp .arg_scan
.arg_end:
 lea rax,[r12+rbx]
 sub rax,[rbp-128]
 mov [rbp-136],rax
 inc rbx
.after_arg:
 cmp qword [rbp-112],0
 jne .known
 ; unknownSlashAsText preserves the full spelling and braces.
 cmp qword [rbp-88],0
 jne .unknown_open
 mov edi,'/'
 call .emit_ordinary
 mov rdi,[rbp-96]
 mov rsi,[rbp-104]
 call .emit_ordinary_seq
 cmp qword [rbp-128],0
 je .unknown_open
 mov edi,'('
 call .emit_ordinary
 mov rdi,[rbp-128]
 mov rsi,[rbp-136]
 call .emit_ordinary_seq
 mov edi,')'
 call .emit_ordinary
.unknown_open:
 mov edi,'{'
 call .emit_ordinary
 mov edi,0
 mov esi,0
 call .push_frame
 inc rbx
 jmp .scan
.known:
 mov eax,[rbp-112]
 mov dword [rbp-140],0
 cmp eax,42
 jb .not_transparent
 cmp eax,44
 ja .not_transparent
 or dword [rbp-140],ADV_FRAME_TRANSPARENT
.not_transparent:
 cmp eax,37
 jne .not_plural
 mov rdi,[rbp-128]
 mov rsi,[rbp-136]
 cmp rsi,1
 jne .not_plural
 cmp byte [rdi],'1'
 jne .not_plural
 or dword [rbp-140],ADV_FRAME_PLURAL_ONE
.not_plural:
 mov esi,[rbp-140]
 cmp eax,45
 jb .conditional
 cmp eax,47
 ja .conditional
 or esi,ADV_FRAME_SUPPRESS
 cmp qword [rbp-88],0
 jne .conditional
 cmp eax,47
 je .hash_marker
 lea rdi,[rel adv_redacted]
 mov edx,adv_redacted_len
 jmp .marker
.hash_marker:
 lea rdi,[rel adv_hashed]
 mov edx,adv_hashed_len
.marker:
 push rsi
 mov rsi,rdx
 call .emit_seq
 pop rsi
.conditional:
 cmp eax,55
 jne .when
 cmp qword [rbp-136],5
 jne .when
 mov rdi,[rbp-128]
 cmp dword [rdi],'fals'
 jne .when
 cmp byte [rdi+4],'e'
 jne .when
 or esi,ADV_FRAME_SUPPRESS
.when:
 cmp eax,56
 jne .unless
 cmp qword [rbp-136],8
 jne .unless
 mov rdi,[rbp-128]
 cmp dword [rdi],'disa'
 jne .unless
 cmp dword [rdi+4],'bled'
 jne .unless
 or esi,ADV_FRAME_SUPPRESS
.unless:
 cmp eax,57
 jne .content_or_control
 cmp qword [rbp-136],7
 jne .content_or_control
 mov rdi,[rbp-128]
 cmp dword [rdi],'enab'
 jne .content_or_control
 cmp dword [rdi+3],'bled'
 jne .content_or_control
 or esi,ADV_FRAME_SUPPRESS
.content_or_control:
 mov [rbp-144],esi
 mov edx,[rbp-120]
 test edx,ADV_F_CONTENT
 jz .control
 mov edi,[rbp-112]
 call .open_known
 mov edi,[rbp-112]
 mov esi,[rbp-144]
 call .push_frame
 mov esi,[rbp-144]
 test esi,ADV_FRAME_SUPPRESS
 jz .content_advance
 inc qword [rbp-88]
.content_advance:
 inc rbx
 jmp .scan
.control:
 mov eax,[rbp-112]
 cmp eax,58
 je .scan
 cmp eax,59
 je .scan
 mov edi,eax
 call .open_known
 mov edi,[rbp-112]
 call .close_known
 jmp .scan
.close:
 mov rcx,[rbp-80]
 dec rcx
 mov [rbp-80],rcx
 shl rcx,4
 lea rax,[rbp-176]
 sub rax,rcx
 mov edi,[rax]
 mov esi,[rax+8]
 test esi,ADV_FRAME_SUPPRESS
 jz .close_visible
 dec qword [rbp-88]
 jmp .close_next
.close_visible:
 cmp edi,0
 jne .close_known_frame
 cmp qword [rbp-88],0
 jne .close_next
 mov edi,'}'
 call .emit_ordinary
 jmp .close_next
.close_known_frame:
 cmp edi,100
 jae .close_next
 test esi,ADV_FRAME_TRANSPARENT
 jnz .close_next
 cmp qword [rbp-88],0
 jne .close_next
 call .close_known
.close_next:
 inc rbx
 jmp .scan
.suffix:
 cmp qword [rbp-48],SLASH_ADV_TARGET_HTML
 jne .suffix_md
 lea rdi,[rel adv_html_doc_close]
 mov esi,adv_html_doc_close_len
 call .emit_seq
 jmp .done
.suffix_md:
 cmp qword [rbp-48],SLASH_ADV_TARGET_MARKDOWN
 jne .done
 lea rdi,[rel adv_md_doc_close]
 mov esi,adv_md_doc_close_len
 call .emit_seq
.done:
 mov rax,r14
 add rsp,520
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

; EDI pseudo id, ESI desired arm bit. Parent frame holds selected-arm bit.
.push_plural_arm:
 push rdi
 mov rcx,[rbp-80]
 dec rcx
 shl rcx,4
 lea rax,[rbp-176]
 sub rax,rcx
 mov eax,[rax+8]
 and eax,ADV_FRAME_PLURAL_ONE
 and esi,ADV_FRAME_PLURAL_ONE
 cmp eax,esi
 je .arm_selected
 mov esi,ADV_FRAME_SUPPRESS
 inc qword [rbp-88]
.arm_selected:
 pop rdi
 jmp .push_frame

; EDI id, ESI frame flags.
.push_frame:
 mov rcx,[rbp-80]
 shl rcx,4
 lea rax,[rbp-176]
 sub rax,rcx
 mov [rax],rdi
 mov [rax+8],rsi
 inc qword [rbp-80]
 ret

; EDI id, ESI frame flags; name/argument locals describe current directive.
.open_known:
 cmp qword [rbp-88],0
 jne .open_ret
 test esi,ADV_FRAME_SUPPRESS
 jnz .open_ret
 test esi,ADV_FRAME_TRANSPARENT
 jnz .open_ret
 mov eax,[rbp-48]
 cmp eax,SLASH_ADV_TARGET_HTML
 je .open_html
 cmp eax,SLASH_ADV_TARGET_MARKDOWN
 je .open_md
 cmp eax,SLASH_ADV_TARGET_ANSI
 je .open_ansi
 cmp eax,SLASH_ADV_TARGET_CONSOLE
 je .open_console
 lea rdi,[rel adv_plain_open]
 mov esi,1
 call .emit_seq
 jmp .open_name
.open_console:
 lea rdi,[rel adv_console_open]
 mov esi,1
 call .emit_seq
 jmp .open_name
.open_md:
 lea rdi,[rel adv_md_open]
 mov esi,2
 call .emit_seq
 jmp .open_name
.open_ansi:
 lea rdi,[rel adv_ansi_open]
 mov esi,adv_ansi_open_len
 call .emit_seq
 jmp .open_name
.open_html:
 lea rdi,[rel adv_html_open]
 mov esi,adv_html_open_len
 call .emit_seq
.open_name:
 mov rdi,[rbp-96]
 mov rsi,[rbp-104]
 call .emit_seq
 cmp qword [rbp-128],0
 je .open_end
 lea rdi,[rel adv_arg_open]
 mov esi,1
 call .emit_seq
 mov rdi,[rbp-128]
 mov rsi,[rbp-136]
 call .emit_seq
 lea rdi,[rel adv_arg_close]
 mov esi,1
 call .emit_seq
.open_end:
 mov eax,[rbp-48]
 cmp eax,SLASH_ADV_TARGET_HTML
 jne .not_html_end
 lea rdi,[rel adv_html_mid]
 mov esi,2
 call .emit_seq
 jmp .open_ret
.not_html_end:
 cmp eax,SLASH_ADV_TARGET_MARKDOWN
 jne .not_md_end
 lea rdi,[rel adv_md_close]
 mov esi,2
 call .emit_seq
 jmp .open_ret
.not_md_end:
 cmp eax,SLASH_ADV_TARGET_ANSI
 jne .plain_end
 lea rdi,[rel adv_ansi_close]
 mov esi,adv_ansi_close_len
 call .emit_seq
 jmp .open_ret
.plain_end:
 cmp eax,SLASH_ADV_TARGET_CONSOLE
 jne .plain_bracket
 lea rdi,[rel adv_console_close]
 mov esi,1
 call .emit_seq
 jmp .open_ret
.plain_bracket:
 lea rdi,[rel adv_plain_close]
 mov esi,1
 call .emit_seq
.open_ret:
 ret

; EDI id; only HTML uses a structural close wrapper.
.close_known:
 cmp qword [rbp-48],SLASH_ADV_TARGET_HTML
 jne .close_ret
 lea rdi,[rel adv_html_close]
 mov esi,7
 call .emit_seq
.close_ret:
 ret

.emit_ordinary:
 cmp qword [rbp-48],SLASH_ADV_TARGET_HTML
 jne .emit_byte
 cmp dil,'&'
 je .ordinary_amp
 cmp dil,'<'
 je .ordinary_lt
 cmp dil,'>'
 je .ordinary_gt
 jmp .emit_byte
.ordinary_amp:
 lea rdi,[rel adv_amp]
 mov esi,5
 jmp .emit_seq
.ordinary_lt:
 lea rdi,[rel adv_lt]
 mov esi,4
 jmp .emit_seq
.ordinary_gt:
 lea rdi,[rel adv_gt]
 mov esi,4
 jmp .emit_seq

.emit_ordinary_seq:
 test rsi,rsi
 jz .ordinary_seq_done
 push rbx
 xor ebx,ebx
.ordinary_seq_loop:
 push rdi
 push rsi
 mov dil,[rdi+rbx]
 call .emit_ordinary
 pop rsi
 pop rdi
 inc rbx
 cmp rbx,rsi
 jb .ordinary_seq_loop
 pop rbx
.ordinary_seq_done:
 ret

.emit_byte:
 mov rax,[rbp-64]
 test rax,rax
 jz .byte_count
 mov [rax+r14],dil
.byte_count:
 inc r14
 ret

.emit_seq:
 test rsi,rsi
 jz .seq_done
 mov rax,[rbp-64]
 test rax,rax
 jz .seq_count
 lea rax,[rax+r14]
 xor ecx,ecx
.copy:
 mov dl,[rdi+rcx]
 mov [rax+rcx],dl
 inc rcx
 cmp rcx,rsi
 jb .copy
.seq_count:
 add r14,rsi
.seq_done:
 ret

; RDI source, RSI bytes, EDX target, ECX policy, R8 output, R9 capacity.
; Returns committed bytes or negative typed error. Measurement precedes writes.
neboc_slash_advanced_render:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 mov r15d,ecx
 mov rbx,r8
 mov [rbp-48],r9
 cmp r14d,SLASH_ADV_TARGET_PLAIN
 jb .target
 cmp r14d,SLASH_ADV_TARGET_CONSOLE
 ja .target
 lea rcx,[rbp-80]
 mov edx,r15d
 call neboc_slash_advanced_validate
 test eax,eax
 jnz .negative
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 mov ecx,r15d
 xor r8d,r8d
 xor r9d,r9d
 call adv_render_pass
 cmp rax,[rbp-48]
 ja .capacity
 test rax,rax
 jz .write
 test rbx,rbx
 jz .invalid
.write:
 mov [rbp-56],rax
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 mov ecx,r15d
 mov r8,rbx
 mov r9,[rbp-48]
 call adv_render_pass
 cmp rax,[rbp-56]
 jne .invalid
 jmp .done
.negative:
 neg eax
 cdqe
 jmp .done
.target:
 mov rax,-SLASH_ADV_E_TARGET
 jmp .done
.capacity:
 mov rax,-SLASH_ADV_E_CAPACITY
 jmp .done
.invalid:
 mov rax,-SLASH_ADV_E_INVALID
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
