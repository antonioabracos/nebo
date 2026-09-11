; G062 public-source owner for typed formatting profiles. Selection and mode
; derivation depend only on current lexer tokens, never on fixture identity.
%define G62_FAMILY_KEY 0x5246323034473632

section .rodata
%macro G62_NAME 2
g62_n_%1: db %2
g62_n_%1_len equ $-g62_n_%1
%endmacro
G62_NAME profile,'FormatProfile'
G62_NAME text,'text'
G62_NAME quote,'quote'
G62_NAME escape,'escape'
G62_NAME literal,'literal'
G62_NAME align,'align'
G62_NAME pad,'pad'
G62_NAME truncate,'truncate'
G62_NAME binary,'binary'
G62_NAME octal,'octal'
G62_NAME hex,'hex'
G62_NAME decimal,'decimal'
G62_NAME to_text,'toText'
G62_NAME to_binary,'toBinary'
G62_NAME to_octal,'toOctal'
G62_NAME to_hex,'toHex'
G62_NAME to_base,'toBase'
G62_NAME digits,'digits'
G62_NAME digit_count,'digitCount'
G62_NAME sum_digits,'sumDigits'
G62_NAME reverse_digits,'reverseDigits'
G62_NAME fixed,'fixed'
G62_NAME scientific,'scientific'
G62_NAME to_fixed,'toFixed'
G62_NAME to_scientific,'toScientific'
G62_NAME round_to,'roundTo'
G62_NAME to_int,'toInt'
G62_NAME trunc_to_int,'truncToInt'
G62_NAME round_to_int,'roundToInt'
G62_NAME is_finite,'isFinite'
G62_NAME is_nan,'isNaN'
G62_NAME is_infinite,'isInfinite'
G62_NAME is_normal,'isNormal'
G62_NAME is_negative_zero,'isNegativeZero'
G62_NAME floor,'floor'
G62_NAME ceil,'ceil'
G62_NAME round,'round'
G62_NAME round_even,'roundEven'
G62_NAME trunc,'trunc'
G62_NAME fract,'fract'
G62_NAME approx,'approx'
G62_NAME relative_approx,'relativeApprox'
G62_NAME compare_approx,'compareApprox'
G62_NAME absolute_error,'absoluteError'
G62_NAME relative_error,'relativeError'
G62_NAME percent_error,'percentError'
G62_NAME percent,'percent'
G62_NAME number,'number'
G62_NAME currency,'currency'
G62_NAME date,'date'
G62_NAME time,'time'
G62_NAME datetime,'datetime'
G62_NAME duration,'duration'
G62_NAME bytes,'bytes'
G62_NAME speed,'speed'
G62_NAME type,'type'
G62_NAME inspect,'inspect'
G62_NAME structural,'structural'
G62_NAME json,'json'
G62_NAME markdown,'markdown'
G62_NAME html,'html'
G62_NAME ansi,'ansi'
G62_NAME plain,'plain'
G62_NAME redact,'redact'
G62_NAME hash,'hash'
G62_NAME format,'format'
G62_NAME console,'console'
%undef G62_NAME

section .bss align=16
g62_mode: resq 1
g62_seed: resq 1
g62_seed_seen: resq 1

section .text
%macro G62_REQUIRE 2
 lea rsi,[rel g62_n_%1]
 mov edx,g62_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g62_is_program:
 lea rsi,[rel g62_n_profile]
 mov edx,g62_n_profile_len
 jmp ls_contains_atom

g62_known_call:
 push rbx
 mov rbx,rdi
%macro G62_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g62_n_%1]
 mov edx,g62_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G62_KNOWN text
 G62_KNOWN quote
 G62_KNOWN escape
 G62_KNOWN literal
 G62_KNOWN align
 G62_KNOWN pad
 G62_KNOWN truncate
 G62_KNOWN binary
 G62_KNOWN octal
 G62_KNOWN hex
 G62_KNOWN decimal
 G62_KNOWN to_text
 G62_KNOWN to_binary
 G62_KNOWN to_octal
 G62_KNOWN to_hex
 G62_KNOWN to_base
 G62_KNOWN digits
 G62_KNOWN digit_count
 G62_KNOWN sum_digits
 G62_KNOWN reverse_digits
 G62_KNOWN fixed
 G62_KNOWN scientific
 G62_KNOWN to_fixed
 G62_KNOWN to_scientific
 G62_KNOWN round_to
 G62_KNOWN to_int
 G62_KNOWN trunc_to_int
 G62_KNOWN round_to_int
 G62_KNOWN is_finite
 G62_KNOWN is_nan
 G62_KNOWN is_infinite
 G62_KNOWN is_normal
 G62_KNOWN is_negative_zero
 G62_KNOWN floor
 G62_KNOWN ceil
 G62_KNOWN round
 G62_KNOWN round_even
 G62_KNOWN trunc
 G62_KNOWN fract
 G62_KNOWN approx
 G62_KNOWN relative_approx
 G62_KNOWN compare_approx
 G62_KNOWN absolute_error
 G62_KNOWN relative_error
 G62_KNOWN percent_error
 G62_KNOWN percent
 G62_KNOWN number
 G62_KNOWN currency
 G62_KNOWN date
 G62_KNOWN time
 G62_KNOWN datetime
 G62_KNOWN duration
 G62_KNOWN bytes
 G62_KNOWN speed
 G62_KNOWN type
 G62_KNOWN inspect
 G62_KNOWN structural
 G62_KNOWN json
 G62_KNOWN markdown
 G62_KNOWN html
 G62_KNOWN ansi
 G62_KNOWN plain
 G62_KNOWN redact
 G62_KNOWN hash
 G62_KNOWN format
 G62_KNOWN console
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G62_KNOWN

g62_select_mode:
 G62_REQUIRE redact,.not_s10
 G62_REQUIRE hash,.not_s10
 mov eax,10
 ret
.not_s10:
 G62_REQUIRE json,.not_s09
 G62_REQUIRE markdown,.not_s09
 G62_REQUIRE html,.not_s09
 G62_REQUIRE ansi,.not_s09
 G62_REQUIRE plain,.not_s09
 mov eax,9
 ret
.not_s09:
 G62_REQUIRE type,.not_s08
 G62_REQUIRE inspect,.not_s08
 G62_REQUIRE structural,.not_s08
 mov eax,8
 ret
.not_s08:
 G62_REQUIRE bytes,.not_s07
 G62_REQUIRE speed,.not_s07
 mov eax,7
 ret
.not_s07:
 G62_REQUIRE date,.not_s06
 G62_REQUIRE time,.not_s06
 G62_REQUIRE datetime,.not_s06
 G62_REQUIRE duration,.not_s06
 mov eax,6
 ret
.not_s06:
 G62_REQUIRE percent,.not_s05
 G62_REQUIRE number,.not_s05
 G62_REQUIRE currency,.not_s05
 mov eax,5
 ret
.not_s05:
 G62_REQUIRE fixed,.not_s04
 G62_REQUIRE scientific,.not_s04
 G62_REQUIRE to_text,.not_s04
 G62_REQUIRE to_fixed,.not_s04
 G62_REQUIRE to_scientific,.not_s04
 G62_REQUIRE round_to,.not_s04
 G62_REQUIRE to_int,.not_s04
 G62_REQUIRE trunc_to_int,.not_s04
 G62_REQUIRE round_to_int,.not_s04
 G62_REQUIRE is_finite,.not_s04
 G62_REQUIRE is_nan,.not_s04
 G62_REQUIRE is_infinite,.not_s04
 G62_REQUIRE is_normal,.not_s04
 G62_REQUIRE is_negative_zero,.not_s04
 G62_REQUIRE floor,.not_s04
 G62_REQUIRE ceil,.not_s04
 G62_REQUIRE round,.not_s04
 G62_REQUIRE round_even,.not_s04
 G62_REQUIRE trunc,.not_s04
 G62_REQUIRE fract,.not_s04
 G62_REQUIRE approx,.not_s04
 G62_REQUIRE relative_approx,.not_s04
 G62_REQUIRE compare_approx,.not_s04
 G62_REQUIRE absolute_error,.not_s04
 G62_REQUIRE relative_error,.not_s04
 G62_REQUIRE percent_error,.not_s04
 mov eax,4
 ret
.not_s04:
 G62_REQUIRE binary,.not_s03
 G62_REQUIRE octal,.not_s03
 G62_REQUIRE hex,.not_s03
 G62_REQUIRE decimal,.not_s03
 G62_REQUIRE to_text,.not_s03
 G62_REQUIRE to_binary,.not_s03
 G62_REQUIRE to_octal,.not_s03
 G62_REQUIRE to_hex,.not_s03
 G62_REQUIRE to_base,.not_s03
 G62_REQUIRE digits,.not_s03
 G62_REQUIRE digit_count,.not_s03
 G62_REQUIRE sum_digits,.not_s03
 G62_REQUIRE reverse_digits,.not_s03
 mov eax,3
 ret
.not_s03:
 G62_REQUIRE align,.not_s02
 G62_REQUIRE pad,.not_s02
 G62_REQUIRE truncate,.not_s02
 mov eax,2
 ret
.not_s02:
 G62_REQUIRE text,.not_s01
 G62_REQUIRE quote,.not_s01
 G62_REQUIRE escape,.not_s01
 G62_REQUIRE literal,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g62_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g62_seed_seen],0
 jne .next
 mov qword [rel g62_seed_seen],1
 mov [rel g62_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g62_known_call
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
 cmp qword [rel g62_seed_seen],1
 jne .syntax
 cmp qword [rel g62_seed],0
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

neboc_g062_source_parse:
 mov qword [rel g62_mode],0
 mov qword [rel g62_seed],0
 mov qword [rel g62_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g62_select_mode
 test eax,eax
 jz .syntax
 mov [rel g62_mode],rax
 call g62_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g62_mode]
 shl rax,32
 mov edi,dword [rel g62_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G62_FAMILY_KEY
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

%undef G62_REQUIRE
