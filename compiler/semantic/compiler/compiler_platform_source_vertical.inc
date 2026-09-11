; G046 token-owned compiler-platform vertical.  Each bounded example must use
; exactly one subgroup marker and every public source-facing call for that
; subgroup.  The parser therefore rejects partial, reordered, foreign, or
; malformed programs before lowering.
%define G46_FAMILY_KEY 0x5246323034473436
%define G46_MIN_SEED 4601
%define G46_MAX_SEED 999999

section .rodata
%macro G46_NAME 2
g46_n_%1: db %2
g46_n_%1_len equ $-g46_n_%1
%endmacro
G46_NAME root,'CompilerPlatform46'
G46_NAME session_marker,'compilerSessionCase46'
G46_NAME ir_marker,'irTransformCase46'
G46_NAME specialize_marker,'specializationCase46'
G46_NAME jit_marker,'boundedJitCase46'
G46_NAME profile_marker,'profileGuidedCase46'
G46_NAME verify_marker,'verifiedPipelineCase46'
G46_NAME bootstrap_marker,'bootstrapTrustCase46'
G46_NAME Compiler,'Compiler'
G46_NAME compiler,'compiler'
G46_NAME Ast,'Ast'
G46_NAME Hir,'Hir'
G46_NAME Lir,'Lir'
G46_NAME Ir,'Ir'
G46_NAME pass,'pass'
G46_NAME Code,'Code'
G46_NAME specialization,'specialization'
G46_NAME Jit,'Jit'
G46_NAME jit,'jit'
G46_NAME compiled,'compiled'
G46_NAME Profile,'Profile'
G46_NAME profile,'profile'
G46_NAME AutoTuner,'AutoTuner'
G46_NAME tuner,'tuner'
G46_NAME pgo,'pgo'
G46_NAME OptimizationPass,'OptimizationPass'
G46_NAME pipeline,'pipeline'
G46_NAME Bootstrap,'Bootstrap'
G46_NAME bootstrap,'bootstrap'
G46_NAME new,'new'
G46_NAME addSource,'addSource'
G46_NAME parse,'parse'
G46_NAME check,'check'
G46_NAME lower,'lower'
G46_NAME emitAssembly,'emitAssembly'
G46_NAME emitObject,'emitObject'
G46_NAME link,'link'
G46_NAME report,'report'
G46_NAME visit,'visit'
G46_NAME rewrite,'rewrite'
G46_NAME transform,'transform'
G46_NAME validate,'validate'
G46_NAME diff,'diff'
G46_NAME requiredAnalyses,'requiredAnalyses'
G46_NAME preservedAnalyses,'preservedAnalyses'
G46_NAME specialize,'specialize'
G46_NAME constantFold,'constantFold'
G46_NAME propagateConstants,'propagateConstants'
G46_NAME inline,'inline'
G46_NAME eliminateDeadBranches,'eliminateDeadBranches'
G46_NAME unroll,'unroll'
G46_NAME cacheKey,'cacheKey'
G46_NAME compile,'compile'
G46_NAME call,'call'
G46_NAME address,'address'
G46_NAME invalidate,'invalidate'
G46_NAME codeCache,'codeCache'
G46_NAME setBudget,'setBudget'
G46_NAME collect,'collect'
G46_NAME securityReport,'securityReport'
G46_NAME hotFunctions,'hotFunctions'
G46_NAME branchProbabilities,'branchProbabilities'
G46_NAME callGraph,'callGraph'
G46_NAME optimizeWith,'optimizeWith'
G46_NAME select,'select'
G46_NAME validateCompatibility,'validateCompatibility'
G46_NAME verify,'verify'
G46_NAME fuzz,'fuzz'
G46_NAME add,'add'
G46_NAME run,'run'
G46_NAME bisectFailure,'bisectFailure'
G46_NAME determinismReport,'determinismReport'
G46_NAME stage0,'stage0'
G46_NAME stage1,'stage1'
G46_NAME stage2,'stage2'
G46_NAME compare,'compare'
G46_NAME selfCheck,'selfCheck'
G46_NAME divergenceReport,'divergenceReport'
G46_NAME trustManifest,'trustManifest'
%undef G46_NAME

section .bss align=16
g46_mode: resq 1
g46_seed: resq 1

section .text
g46_is_program:
 sub rsp,8
 lea rsi,[rel g46_n_root]
 mov edx,g46_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G46_MARKER 1
 lea rsi,[rel g46_n_%1]
 mov edx,g46_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G46_MARKER session_marker
 G46_MARKER ir_marker
 G46_MARKER specialize_marker
 G46_MARKER jit_marker
 G46_MARKER profile_marker
 G46_MARKER verify_marker
 G46_MARKER bootstrap_marker
.no:
 xor eax,eax
 add rsp,8
 ret
.yes:
 mov eax,1
 add rsp,8
 ret
%undef G46_MARKER

g46_marker_at:
 push rbx
 sub rsp,16
 mov rbx,rdi
%macro G46_AT 1
 mov rdi,rbx
 lea rsi,[rel g46_n_%1]
 mov edx,g46_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G46_AT session_marker
 G46_AT ir_marker
 G46_AT specialize_marker
 G46_AT jit_marker
 G46_AT profile_marker
 G46_AT verify_marker
 G46_AT bootstrap_marker
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 add rsp,16
 pop rbx
 ret
%undef G46_AT

g46_marker_count:
 push rbx
 push r12
 sub rsp,8
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp r12,[rel ls_token_count]
 jae .done
 mov rdi,r12
 call g46_marker_at
 add ebx,eax
 inc r12
 jmp .scan
.done:
 mov eax,ebx
 add rsp,8
 pop r12
 pop rbx
 ret

g46_select_mode:
 sub rsp,8
%macro G46_SELECT 2
 lea rsi,[rel g46_n_%1]
 mov edx,g46_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %%next
 mov eax,%2
 add rsp,8
 ret
%%next:
%endmacro
 G46_SELECT session_marker,1
 G46_SELECT ir_marker,2
 G46_SELECT specialize_marker,3
 G46_SELECT jit_marker,4
 G46_SELECT profile_marker,5
 G46_SELECT verify_marker,6
 G46_SELECT bootstrap_marker,7
 xor eax,eax
 add rsp,8
 ret
%undef G46_SELECT

; RDI=name, ESI=length.  Consume "name;" at the shared cursor.
g46_expect_atom_statement:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov ebx,esi
 mov rdi,[rel ls_cursor]
 mov rsi,r12
 mov edx,ebx
 call ls_token_match
 test eax,eax
 jz .bad
 mov rdi,[rel ls_cursor]
 inc rdi
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .bad
 add qword [rel ls_cursor],2
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; RDI=receiver, ESI=receiver length, RDX=method, ECX=method length,
; R8D=argument count.  Arguments are bounded single tokens in this source
; profile; nested expression semantics remain owned by their normal parser.
g46_expect_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,[rel ls_cursor]
 mov r12,rdi
 mov r13d,esi
 mov r14,rdx
 mov r15d,ecx
 mov [rsp],r8
 mov rdi,rbx
 mov rsi,r12
 mov edx,r13d
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 lea rdi,[rbx+2]
 mov rsi,r14
 mov edx,r15d
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 add rbx,4
 xor r9d,r9d
 cmp qword [rsp],0
 je .close
.argument:
 mov rdi,rbx
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_COMMA
 je .bad
 cmp eax,NEBOC_TOKEN_LPAREN
 je .bad
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .bad
 inc rbx
 inc r9
 cmp r9,[rsp]
 jae .close
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 inc rbx
 jmp .argument
.close:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 inc rbx
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .bad
 inc rbx
 mov [rel ls_cursor],rbx
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g46_expect_selected_marker:
 sub rsp,8
 mov rax,[rel g46_mode]
 cmp rax,1
 je .s1
 cmp rax,2
 je .s2
 cmp rax,3
 je .s3
 cmp rax,4
 je .s4
 cmp rax,5
 je .s5
 cmp rax,6
 je .s6
 cmp rax,7
 jne .bad
 lea rdi,[rel g46_n_bootstrap_marker]
 mov esi,g46_n_bootstrap_marker_len
 jmp .consume
.s1: lea rdi,[rel g46_n_session_marker]
 mov esi,g46_n_session_marker_len
 jmp .consume
.s2: lea rdi,[rel g46_n_ir_marker]
 mov esi,g46_n_ir_marker_len
 jmp .consume
.s3: lea rdi,[rel g46_n_specialize_marker]
 mov esi,g46_n_specialize_marker_len
 jmp .consume
.s4: lea rdi,[rel g46_n_jit_marker]
 mov esi,g46_n_jit_marker_len
 jmp .consume
.s5: lea rdi,[rel g46_n_profile_marker]
 mov esi,g46_n_profile_marker_len
 jmp .consume
.s6: lea rdi,[rel g46_n_verify_marker]
 mov esi,g46_n_verify_marker_len
.consume:
 call g46_expect_atom_statement
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret

g46_parse_calls:
 sub rsp,8
%macro G46_CALL 3
 lea rdi,[rel g46_n_%1]
 mov esi,g46_n_%1_len
 lea rdx,[rel g46_n_%2]
 mov ecx,g46_n_%2_len
 mov r8d,%3
 call g46_expect_call
 test eax,eax
 jz .bad
%endmacro
 mov rax,[rel g46_mode]
 cmp rax,1
 je .s1
 cmp rax,2
 je .s2
 cmp rax,3
 je .s3
 cmp rax,4
 je .s4
 cmp rax,5
 je .s5
 cmp rax,6
 je .s6
 cmp rax,7
 je .s7
 jmp .bad
.s1:
 G46_CALL Compiler,new,2
 G46_CALL compiler,addSource,2
 G46_CALL compiler,parse,1
 G46_CALL compiler,check,1
 G46_CALL compiler,lower,1
 G46_CALL compiler,emitAssembly,2
 G46_CALL compiler,emitObject,2
 G46_CALL compiler,link,2
 G46_CALL compiler,report,0
 jmp .ok
.s2:
 G46_CALL Ast,visit,1
 G46_CALL Ast,rewrite,1
 G46_CALL Hir,visit,1
 G46_CALL Hir,transform,1
 G46_CALL Lir,transform,1
 G46_CALL Ir,validate,0
 G46_CALL Ir,diff,1
 G46_CALL pass,requiredAnalyses,0
 G46_CALL pass,preservedAnalyses,0
 jmp .ok
.s3:
 G46_CALL Code,specialize,2
 G46_CALL Code,constantFold,1
 G46_CALL Code,propagateConstants,1
 G46_CALL Code,inline,2
 G46_CALL Code,eliminateDeadBranches,0
 G46_CALL Code,unroll,3
 G46_CALL specialization,cacheKey,0
 G46_CALL specialization,report,0
 jmp .ok
.s4:
 G46_CALL Jit,new,3
 G46_CALL jit,compile,2
 G46_CALL compiled,call,1
 G46_CALL compiled,address,0
 G46_CALL jit,invalidate,1
 G46_CALL jit,codeCache,0
 G46_CALL jit,setBudget,3
 G46_CALL jit,collect,0
 G46_CALL jit,securityReport,0
 jmp .ok
.s5:
 G46_CALL Profile,collect,3
 G46_CALL profile,hotFunctions,0
 G46_CALL profile,branchProbabilities,0
 G46_CALL profile,callGraph,0
 G46_CALL Compiler,optimizeWith,1
 G46_CALL AutoTuner,new,3
 G46_CALL tuner,select,2
 G46_CALL profile,validateCompatibility,1
 G46_CALL pgo,report,0
 jmp .ok
.s6:
 G46_CALL OptimizationPass,new,2
 G46_CALL pass,verify,2
 G46_CALL pass,fuzz,2
 G46_CALL pipeline,add,1
 G46_CALL pipeline,run,1
 G46_CALL pipeline,bisectFailure,1
 G46_CALL pipeline,determinismReport,0
 jmp .ok
.s7:
 G46_CALL Bootstrap,stage0,1
 G46_CALL Bootstrap,stage1,1
 G46_CALL Bootstrap,stage2,1
 G46_CALL Bootstrap,compare,2
 G46_CALL Compiler,selfCheck,1
 G46_CALL bootstrap,divergenceReport,0
 G46_CALL bootstrap,trustManifest,0
.ok:
 mov eax,1
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret
%undef G46_CALL

neboc_g046_source_parse:
 sub rsp,8
 mov qword [rel g46_mode],0
 mov qword [rel g46_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g46_marker_count
 cmp eax,1
 jne .unsupported
 call g46_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g46_mode],rax
 lea rdi,[rel g46_n_root]
 mov esi,g46_n_root_len
 call g46_expect_atom_statement
 test eax,eax
 jz .unsupported
 call g46_expect_selected_marker
 test eax,eax
 jz .unsupported
 call g46_parse_calls
 test eax,eax
 jz .unsupported
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .unsupported
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G46_MIN_SEED
 jb .unsupported
 cmp rdx,G46_MAX_SEED
 ja .unsupported
 mov [rel g46_seed],rdx
 mov rdi,[rel ls_cursor]
 inc rdi
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .unsupported
 inc qword [rel ls_cursor]
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rax,[rel g46_mode]
 shl rax,32
 mov edi,dword [rel g46_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G46_FAMILY_KEY
 call ls_success
 add rsp,8
 ret
.syntax:
 mov edi,20
 call ls_error
 add rsp,8
 ret
.unsupported:
 mov edi,24
 call ls_error
 add rsp,8
 ret
