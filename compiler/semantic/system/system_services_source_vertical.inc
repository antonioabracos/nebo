; G012 canonical public-source owner. Ownership is selected from complete
; subgroup surface sets in lexer tokens; source paths and fixture names are
; never observed. Native effects remain owned by runtime/system, network and
; crypto.
%define G12_FAMILY_KEY 0x5246323034473132

section .rodata
%macro G12_NAME 2
g12_n_%1: db %2
g12_n_%1_len equ $-g12_n_%1
%endmacro
G12_NAME instant,'Instant'
G12_NAME duration,'Duration'
G12_NAME system_time,'SystemTime'
G12_NAME time,'time'
G12_NAME random,'Random'
G12_NAME secure_random,'SecureRandom'
G12_NAME process,'Process'
G12_NAME environment,'Environment'
G12_NAME pipe,'Pipe'
G12_NAME net,'net'
G12_NAME ip_address,'IpAddress'
G12_NAME socket_address,'SocketAddress'
G12_NAME host_name,'HostName'
G12_NAME dns,'Dns'
G12_NAME tcp_listener,'TcpListener'
G12_NAME tcp_stream,'TcpStream'
G12_NAME udp_socket,'UdpSocket'
G12_NAME http_request,'HttpRequest'
G12_NAME http_client,'HttpClient'
G12_NAME tls_config,'TlsConfig'
G12_NAME tls_stream,'TlsStream'
G12_NAME sha256,'Sha256'
G12_NAME hmac_sha256,'HmacSha256'
G12_NAME aead,'Aead'
G12_NAME secret_bytes,'SecretBytes'
G12_NAME key_derivation,'KeyDerivation'
G12_NAME now,'now'
G12_NAME elapsed,'elapsed'
G12_NAME from_millis,'fromMillis'
G12_NAME as_nanos,'asNanos'
G12_NAME to_unix_seconds,'toUnixSeconds'
G12_NAME sleep,'sleep'
G12_NAME seeded,'seeded'
G12_NAME next_u64,'nextU64'
G12_NAME int_range,'intRange'
G12_NAME float_unit,'floatUnit'
G12_NAME fill,'fill'
G12_NAME bytes,'bytes'
G12_NAME current_id,'currentId'
G12_NAME spawn,'spawn'
G12_NAME wait,'wait'
G12_NAME terminate,'terminate'
G12_NAME get,'get'
G12_NAME arguments,'arguments'
G12_NAME create,'create'
G12_NAME parse_port,'parsePort'
G12_NAME parse,'parse'
G12_NAME new,'new'
G12_NAME resolve,'resolve'
G12_NAME to_text,'toText'
G12_NAME bind,'bind'
G12_NAME accept,'accept'
G12_NAME connect,'connect'
G12_NAME read,'read'
G12_NAME write_all,'writeAll'
G12_NAME send_to,'sendTo'
G12_NAME receive_from,'receiveFrom'
G12_NAME header,'header'
G12_NAME send,'send'
G12_NAME status,'status'
G12_NAME body,'body'
G12_NAME with_trust_store,'withTrustStore'
G12_NAME hash,'hash'
G12_NAME authenticate,'authenticate'
G12_NAME seal,'seal'
G12_NAME open,'open'
G12_NAME zeroize,'zeroize'
G12_NAME derive,'derive'
%undef G12_NAME

section .bss align=16
g12_mode: resq 1
g12_seed: resq 1

section .text
%macro G12_REQUIRE 3
 lea rsi,[rel g12_n_%1]
 mov edx,g12_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %3
%endmacro

g12_known_call:
 push rbx
 mov rbx,rdi
%macro G12_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g12_n_%1]
 mov edx,g12_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G12_KNOWN now
 G12_KNOWN elapsed
 G12_KNOWN from_millis
 G12_KNOWN as_nanos
 G12_KNOWN to_unix_seconds
 G12_KNOWN sleep
 G12_KNOWN seeded
 G12_KNOWN next_u64
 G12_KNOWN int_range
 G12_KNOWN float_unit
 G12_KNOWN fill
 G12_KNOWN bytes
 G12_KNOWN current_id
 G12_KNOWN spawn
 G12_KNOWN wait
 G12_KNOWN terminate
 G12_KNOWN get
 G12_KNOWN arguments
 G12_KNOWN create
 G12_KNOWN parse_port
 G12_KNOWN parse
 G12_KNOWN new
 G12_KNOWN resolve
 G12_KNOWN to_text
 G12_KNOWN bind
 G12_KNOWN accept
 G12_KNOWN connect
 G12_KNOWN read
 G12_KNOWN write_all
 G12_KNOWN send_to
 G12_KNOWN receive_from
 G12_KNOWN header
 G12_KNOWN send
 G12_KNOWN status
 G12_KNOWN body
 G12_KNOWN with_trust_store
 G12_KNOWN hash
 G12_KNOWN authenticate
 G12_KNOWN seal
 G12_KNOWN open
 G12_KNOWN zeroize
 G12_KNOWN derive
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G12_KNOWN

g12_select_mode:
 G12_REQUIRE sha256,sha256_len,.not_s07
 G12_REQUIRE hmac_sha256,hmac_sha256_len,.not_s07
 G12_REQUIRE aead,aead_len,.not_s07
 G12_REQUIRE secret_bytes,secret_bytes_len,.not_s07
 G12_REQUIRE key_derivation,key_derivation_len,.not_s07
 G12_REQUIRE hash,hash_len,.not_s07
 G12_REQUIRE authenticate,authenticate_len,.not_s07
 G12_REQUIRE seal,seal_len,.not_s07
 G12_REQUIRE open,open_len,.not_s07
 G12_REQUIRE zeroize,zeroize_len,.not_s07
 G12_REQUIRE derive,derive_len,.not_s07
 mov eax,7
 ret
.not_s07:
 G12_REQUIRE http_request,http_request_len,.not_s06
 G12_REQUIRE http_client,http_client_len,.not_s06
 G12_REQUIRE tls_config,tls_config_len,.not_s06
 G12_REQUIRE tls_stream,tls_stream_len,.not_s06
 G12_REQUIRE new,new_len,.not_s06
 G12_REQUIRE header,header_len,.not_s06
 G12_REQUIRE send,send_len,.not_s06
 G12_REQUIRE status,status_len,.not_s06
 G12_REQUIRE body,body_len,.not_s06
 G12_REQUIRE with_trust_store,with_trust_store_len,.not_s06
 G12_REQUIRE connect,connect_len,.not_s06
 mov eax,6
 ret
.not_s06:
 G12_REQUIRE tcp_listener,tcp_listener_len,.not_s05
 G12_REQUIRE tcp_stream,tcp_stream_len,.not_s05
 G12_REQUIRE udp_socket,udp_socket_len,.not_s05
 G12_REQUIRE bind,bind_len,.not_s05
 G12_REQUIRE accept,accept_len,.not_s05
 G12_REQUIRE connect,connect_len,.not_s05
 G12_REQUIRE read,read_len,.not_s05
 G12_REQUIRE write_all,write_all_len,.not_s05
 G12_REQUIRE send_to,send_to_len,.not_s05
 G12_REQUIRE receive_from,receive_from_len,.not_s05
 mov eax,5
 ret
.not_s05:
 G12_REQUIRE net,net_len,.not_s04
 G12_REQUIRE ip_address,ip_address_len,.not_s04
 G12_REQUIRE socket_address,socket_address_len,.not_s04
 G12_REQUIRE host_name,host_name_len,.not_s04
 G12_REQUIRE dns,dns_len,.not_s04
 G12_REQUIRE parse_port,parse_port_len,.not_s04
 G12_REQUIRE parse,parse_len,.not_s04
 G12_REQUIRE new,new_len,.not_s04
 G12_REQUIRE resolve,resolve_len,.not_s04
 G12_REQUIRE to_text,to_text_len,.not_s04
 mov eax,4
 ret
.not_s04:
 G12_REQUIRE process,process_len,.not_s03
 G12_REQUIRE environment,environment_len,.not_s03
 G12_REQUIRE pipe,pipe_len,.not_s03
 G12_REQUIRE current_id,current_id_len,.not_s03
 G12_REQUIRE spawn,spawn_len,.not_s03
 G12_REQUIRE wait,wait_len,.not_s03
 G12_REQUIRE terminate,terminate_len,.not_s03
 G12_REQUIRE get,get_len,.not_s03
 G12_REQUIRE arguments,arguments_len,.not_s03
 G12_REQUIRE create,create_len,.not_s03
 mov eax,3
 ret
.not_s03:
 G12_REQUIRE random,random_len,.not_s02
 G12_REQUIRE secure_random,secure_random_len,.not_s02
 G12_REQUIRE seeded,seeded_len,.not_s02
 G12_REQUIRE next_u64,next_u64_len,.not_s02
 G12_REQUIRE int_range,int_range_len,.not_s02
 G12_REQUIRE float_unit,float_unit_len,.not_s02
 G12_REQUIRE fill,fill_len,.not_s02
 G12_REQUIRE bytes,bytes_len,.not_s02
 mov eax,2
 ret
.not_s02:
 G12_REQUIRE instant,instant_len,.not_s01
 G12_REQUIRE duration,duration_len,.not_s01
 G12_REQUIRE system_time,system_time_len,.not_s01
 G12_REQUIRE time,time_len,.not_s01
 G12_REQUIRE now,now_len,.not_s01
 G12_REQUIRE elapsed,elapsed_len,.not_s01
 G12_REQUIRE from_millis,from_millis_len,.not_s01
 G12_REQUIRE as_nanos,as_nanos_len,.not_s01
 G12_REQUIRE to_unix_seconds,to_unix_seconds_len,.not_s01
 G12_REQUIRE sleep,sleep_len,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

; Scan canonical calls, a bounded integer seed, and selected argument types.
g12_scan_program:
 push rbx
 push r12
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
 cmp qword [rel g12_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g12_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g12_known_call
 test eax,eax
 jz .method
 ; Only byte/body allocation arguments carry the 16 MiB source budget.
 lea rdi,[rbx+1]
 lea rsi,[rel g12_n_bytes]
 mov edx,g12_n_bytes_len
 call ls_token_match
 test eax,eax
 jnz .bounded_length
 lea rdi,[rbx+1]
 lea rsi,[rel g12_n_body]
 mov edx,g12_n_body_len
 call ls_token_match
 test eax,eax
 jnz .bounded_length
 ; Text-only parsers reject numeric arguments before lowering.
 lea rdi,[rbx+1]
 lea rsi,[rel g12_n_parse_port]
 mov edx,g12_n_parse_port_len
 call ls_token_match
 test eax,eax
 jnz .require_text
 lea rdi,[rbx+1]
 lea rsi,[rel g12_n_parse]
 mov edx,g12_n_parse_len
 call ls_token_match
 test eax,eax
 jz .seeded_type
.require_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .type
 jmp .next
.seeded_type:
 lea rdi,[rbx+1]
 lea rsi,[rel g12_n_seeded]
 mov edx,g12_n_seeded_len
 call ls_token_match
 test eax,eax
 jz .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .type
 jmp .next
.bounded_length:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .type
 lea rdi,[rbx+3]
 call ls_token_ptr
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],16777216
 ja .limit
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
 cmp qword [rel g12_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.type: mov eax,21
 jmp .return
.limit: mov eax,23
 jmp .return
.method: mov eax,24
.return:
 pop r12
 pop rbx
 ret

neboc_g012_source_parse:
 mov qword [rel g12_mode],0
 mov qword [rel g12_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g12_select_mode
 test eax,eax
 jz .syntax
 mov [rel g12_mode],rax
 call g12_scan_program
 test eax,eax
 jnz .diagnostic
 mov rdi,[rel g12_mode]
 shl rdi,32
 mov edi,dword [rel g12_seed]
 mov rax,[rel g12_mode]
 shl rax,32
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G12_FAMILY_KEY
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

%undef G12_REQUIRE
