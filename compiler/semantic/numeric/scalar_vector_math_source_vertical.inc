; Canonical public-source owner for scalar math, fixed-size vectors,
; descriptive statistics and explicit-PRNG distributions.
%define G14_FAMILY_KEY 0x5246323034473134

section .rodata
%macro G14_NAME 2
g14_n_%1: db %2
g14_n_%1_len equ $-g14_n_%1
%endmacro
G14_NAME max,'max'
G14_NAME min,'min'
G14_NAME abs,'abs'
G14_NAME clamp,'clamp'
G14_NAME sqrt,'sqrt'
G14_NAME pow,'pow'
G14_NAME hypot,'hypot'
G14_NAME sin,'sin'
G14_NAME cos,'cos'
G14_NAME tan,'tan'
G14_NAME atan2,'atan2'
G14_NAME exp,'exp'
G14_NAME log,'log'
G14_NAME log2,'log2'
G14_NAME floor,'floor'
G14_NAME ceil,'ceil'
G14_NAME round,'round'
G14_NAME is_nan,'isNaN'
G14_NAME is_infinite,'isInfinite'
G14_NAME is_finite,'isFinite'
G14_NAME approx_equals,'approxEquals'
G14_NAME vector_type,'Vector'
G14_NAME filled,'filled'
G14_NAME at,'at'
G14_NAME add,'add'
G14_NAME scale,'scale'
G14_NAME dot,'dot'
G14_NAME norm,'norm'
G14_NAME normalize,'normalize'
G14_NAME sum,'sum'
G14_NAME mean,'mean'
G14_NAME variance,'variance'
G14_NAME standard_deviation,'standardDeviation'
G14_NAME quantile,'quantile'
G14_NAME median,'median'
G14_NAME correlation,'correlation'
G14_NAME random_type,'Random'
G14_NAME seed,'seed'
G14_NAME uniform,'uniform'
G14_NAME normal,'normal'
G14_NAME bernoulli,'bernoulli'
G14_NAME categorical,'categorical'
G14_NAME shuffle,'shuffle'
G14_NAME sample,'sample'
%undef G14_NAME

section .bss align=16
g14_mode: resq 1
g14_seed: resq 1
g14_seed_seen: resq 1

section .text
%macro G14_REQUIRE 2
 lea rsi,[rel g14_n_%1]
 mov edx,g14_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; Dotted calls are accepted only when their operation atom belongs to G014.
g14_known_call:
 push rbx
 mov rbx,rdi
%macro G14_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g14_n_%1]
 mov edx,g14_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G14_KNOWN max
 G14_KNOWN min
 G14_KNOWN abs
 G14_KNOWN clamp
 G14_KNOWN sqrt
 G14_KNOWN pow
 G14_KNOWN hypot
 G14_KNOWN sin
 G14_KNOWN cos
 G14_KNOWN tan
 G14_KNOWN atan2
 G14_KNOWN exp
 G14_KNOWN log
 G14_KNOWN log2
 G14_KNOWN floor
 G14_KNOWN ceil
 G14_KNOWN round
 G14_KNOWN is_nan
 G14_KNOWN is_infinite
 G14_KNOWN is_finite
 G14_KNOWN approx_equals
 G14_KNOWN filled
 G14_KNOWN at
 G14_KNOWN add
 G14_KNOWN scale
 G14_KNOWN dot
 G14_KNOWN norm
 G14_KNOWN normalize
 G14_KNOWN sum
 G14_KNOWN mean
 G14_KNOWN variance
 G14_KNOWN standard_deviation
 G14_KNOWN quantile
 G14_KNOWN median
 G14_KNOWN correlation
 G14_KNOWN seed
 G14_KNOWN uniform
 G14_KNOWN normal
 G14_KNOWN bernoulli
 G14_KNOWN categorical
 G14_KNOWN shuffle
 G14_KNOWN sample
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G14_KNOWN

g14_select_mode:
 G14_REQUIRE random_type,.not_s06
 G14_REQUIRE uniform,.not_s06
 G14_REQUIRE normal,.not_s06
 G14_REQUIRE bernoulli,.not_s06
 G14_REQUIRE categorical,.not_s06
 G14_REQUIRE shuffle,.not_s06
 G14_REQUIRE sample,.not_s06
 mov eax,6
 ret
.not_s06:
 G14_REQUIRE sum,.not_s05
 G14_REQUIRE mean,.not_s05
 G14_REQUIRE variance,.not_s05
 G14_REQUIRE standard_deviation,.not_s05
 G14_REQUIRE quantile,.not_s05
 G14_REQUIRE median,.not_s05
 G14_REQUIRE correlation,.not_s05
 mov eax,5
 ret
.not_s05:
 G14_REQUIRE vector_type,.not_s04
 G14_REQUIRE filled,.not_s04
 G14_REQUIRE at,.not_s04
 G14_REQUIRE add,.not_s04
 G14_REQUIRE scale,.not_s04
 G14_REQUIRE dot,.not_s04
 G14_REQUIRE norm,.not_s04
 G14_REQUIRE normalize,.not_s04
 mov eax,4
 ret
.not_s04:
 G14_REQUIRE floor,.not_s03
 G14_REQUIRE ceil,.not_s03
 G14_REQUIRE round,.not_s03
 G14_REQUIRE is_nan,.not_s03
 G14_REQUIRE is_infinite,.not_s03
 G14_REQUIRE is_finite,.not_s03
 G14_REQUIRE approx_equals,.not_s03
 mov eax,3
 ret
.not_s03:
 G14_REQUIRE sin,.not_s02
 G14_REQUIRE cos,.not_s02
 G14_REQUIRE tan,.not_s02
 G14_REQUIRE atan2,.not_s02
 G14_REQUIRE exp,.not_s02
 G14_REQUIRE log,.not_s02
 G14_REQUIRE log2,.not_s02
 mov eax,2
 ret
.not_s02:
 G14_REQUIRE max,.not_s01
 G14_REQUIRE min,.not_s01
 G14_REQUIRE abs,.not_s01
 G14_REQUIRE clamp,.not_s01
 G14_REQUIRE sqrt,.not_s01
 G14_REQUIRE pow,.not_s01
 G14_REQUIRE hypot,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g14_scan_program:
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
 cmp qword [rel g14_seed_seen],0
 jne .next
 mov qword [rel g14_seed_seen],1
 mov [rel g14_seed],rdx
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
 call g14_known_call
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
 cmp qword [rel g14_seed],0
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

neboc_g014_source_parse:
 mov qword [rel g14_mode],0
 mov qword [rel g14_seed],0
 mov qword [rel g14_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g14_select_mode
 ; Scalar programs now require the complete typed statement owner in the
 ; driver. A failed scalar parse must never fall back to mode/seed emission.
 cmp eax,3
 jbe .syntax
 mov [rel g14_mode],rax
 call g14_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g14_mode]
 shl rax,32
 mov edi,dword [rel g14_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G14_FAMILY_KEY
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

%undef G14_REQUIRE
