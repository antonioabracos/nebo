bits 64
default rel
%define NEBO_INFERENCE_IMPLEMENTATION 1
%include "runtime/ml/inference.inc"

section .text
global nebo_inference_run
global nebo_inference_run_into
global nebo_inference_warmup
global nebo_inference_batch
global nebo_inference_memory_plan
global nebo_inference_profile

; rdi=session, rsi=input, rdx=output, rcx=elements. Single-sample shorthand.
nebo_inference_run:
 mov r8,rcx
 mov r9,rcx
 mov ecx,1
 jmp inference_execute

; rdi=session, rsi=input, rdx=output, rcx=batch, r8=elements, r9=capacity.
nebo_inference_run_into:
 jmp inference_execute

; Same explicit ABI as runInto; batch must be within the session plan.
nebo_inference_batch:
 jmp inference_execute

inference_execute:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 call inference_validate_session
 test eax,eax
 jnz .return
 test r13,r13
 jz .argument
 test r14,r14
 jz .argument
 test r15,r15
 jz .shape
 cmp r15,[r12+NEBO_INFERENCE_SESSION_BATCH_LIMIT]
 ja .limit
 mov rax,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 imul rax,r15
 cmp rax,rbp
 jne .shape
 cmp rbx,rbp
 jb .capacity
 mov rax,rbp
 shl rax,3
 jc .limit
 mov [rsp],rax
 ; Input/output may alias exactly, but partial alias is refused.
 cmp r13,r14
 je .io_overlap_done
 mov rdi,r13
 mov rsi,rax
 mov rdx,r14
 mov rcx,rax
 call ranges_overlap
 test eax,eax
 jnz .overlap
.io_overlap_done:
 mov rdi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 mov rsi,[rsp]
 mov rdx,r13
 mov rcx,[rsp]
 call ranges_overlap
 test eax,eax
 jnz .overlap
 mov rdi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 mov rsi,[rsp]
 mov rdx,r14
 mov rcx,[rsp]
 call ranges_overlap
 test eax,eax
 jnz .overlap
 ; Preflight operation parameters and all alias relationships.
 xor ecx,ecx
.preflight_ops:
 cmp rcx,[r12+NEBO_INFERENCE_SESSION_OP_COUNT]
 jae .counter_preflight
 mov rax,rcx
 imul rax,NEBO_INFERENCE_OP_SIZE
 add rax,[r12+NEBO_INFERENCE_SESSION_OPS]
 mov [rsp+8],rax
 cmp qword [rax],NEBO_INFERENCE_OP_SCALE_BIAS
 jne .preflight_next
 mov rbx,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 shl rbx,3
 mov rdi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 mov rsi,[rsp]
 mov rdx,[rax+8]
 mov rcx,rbx
 call ranges_overlap
 test eax,eax
 jnz .overlap
 mov rax,[rsp+8]
 mov rdi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 mov rsi,[rsp]
 mov rdx,[rax+16]
 mov rcx,rbx
 call ranges_overlap
 test eax,eax
 jnz .overlap
 mov rax,[rsp+8]
 mov rdi,r14
 mov rsi,[rsp]
 mov rdx,[rax+8]
 mov rcx,rbx
 call ranges_overlap
 test eax,eax
 jnz .overlap
 mov rax,[rsp+8]
 mov rdi,r14
 mov rsi,[rsp]
 mov rdx,[rax+16]
 mov rcx,rbx
 call ranges_overlap
 test eax,eax
 jnz .overlap
 mov rax,[rsp+8]
 xor ecx,ecx
.parameter_finite:
 cmp rcx,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 jae .preflight_restore
 mov rdx,[rax+8]
 mov rdx,[rdx+rcx*8]
 call is_nonfinite
 test eax,eax
 jnz .nonfinite
 mov rax,[rsp+8]
 mov rdx,[rax+16]
 mov rdx,[rdx+rcx*8]
 call is_nonfinite
 test eax,eax
 jnz .nonfinite
 mov rax,[rsp+8]
 inc rcx
 jmp .parameter_finite
.preflight_restore:
 mov rax,[rsp+8]
.preflight_next:
 mov rcx,rax
 sub rcx,[r12+NEBO_INFERENCE_SESSION_OPS]
 shr rcx,5
 inc rcx
 jmp .preflight_ops
.counter_preflight:
 cmp qword [r12+NEBO_INFERENCE_SESSION_RUNS],-1
 je .limit
 mov rax,[r12+NEBO_INFERENCE_SESSION_SAMPLES]
 add rax,r15
 jc .limit
 mov rax,[r12+NEBO_INFERENCE_SESSION_ELEMENTS]
 add rax,rbp
 jc .limit
 mov rax,[r12+NEBO_INFERENCE_SESSION_BYTES_READ]
 add rax,[rsp]
 jc .limit
 mov rax,[r12+NEBO_INFERENCE_SESSION_BYTES_WRITTEN]
 add rax,[rsp]
 jc .limit
 ; Validate and copy input into private workspace.
 mov rdi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 xor ecx,ecx
.input_copy:
 cmp rcx,rbp
 jae .execute_ops
 mov rdx,[r13+rcx*8]
 call is_nonfinite
 test eax,eax
 jnz .nonfinite
 mov rdx,[r13+rcx*8]
 mov [rdi+rcx*8],rdx
 inc rcx
 jmp .input_copy
.execute_ops:
 xor r11d,r11d
.operation_loop:
 cmp r11,[r12+NEBO_INFERENCE_SESSION_OP_COUNT]
 jae .publish_output
 mov rax,r11
 imul rax,NEBO_INFERENCE_OP_SIZE
 add rax,[r12+NEBO_INFERENCE_SESSION_OPS]
 cmp qword [rax],NEBO_INFERENCE_OP_IDENTITY
 je .operation_next
 cmp qword [rax],NEBO_INFERENCE_OP_RELU
 je .operation_relu
 ; Scale+bias is indexed per feature and repeated across the batch.
 mov r8,[rax+8]
 mov r9,[rax+16]
 xor ecx,ecx
.scale_loop:
 cmp rcx,rbp
 jae .operation_next
 mov rax,rcx
 xor edx,edx
 div qword [r12+NEBO_INFERENCE_SESSION_FEATURES]
 mov r10,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 movsd xmm0,[r10+rcx*8]
 mulsd xmm0,[r8+rdx*8]
 addsd xmm0,[r9+rdx*8]
 movq rdx,xmm0
 call is_nonfinite
 test eax,eax
 jnz .nonfinite
 mov r10,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 movsd [r10+rcx*8],xmm0
 inc rcx
 jmp .scale_loop
.operation_relu:
 mov r10,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 xorpd xmm1,xmm1
 xor ecx,ecx
.relu_loop:
 cmp rcx,rbp
 jae .operation_next
 movsd xmm0,[r10+rcx*8]
 maxsd xmm0,xmm1
 movsd [r10+rcx*8],xmm0
 inc rcx
 jmp .relu_loop
.operation_next:
 inc r11
 jmp .operation_loop
.publish_output:
 mov rsi,[r12+NEBO_INFERENCE_SESSION_WORKSPACE]
 xor ecx,ecx
 mov r10,[r12+NEBO_INFERENCE_SESSION_CHECKSUM]
.publish_loop:
 cmp rcx,rbp
 jae .publish_counters
 mov rax,[rsi+rcx*8]
 mov [r14+rcx*8],rax
 xor r10,rax
 inc rcx
 jmp .publish_loop
.publish_counters:
 mov [r12+NEBO_INFERENCE_SESSION_CHECKSUM],r10
 inc qword [r12+NEBO_INFERENCE_SESSION_RUNS]
 add [r12+NEBO_INFERENCE_SESSION_SAMPLES],r15
 add [r12+NEBO_INFERENCE_SESSION_ELEMENTS],rbp
 mov rax,[rsp]
 add [r12+NEBO_INFERENCE_SESSION_BYTES_READ],rax
 add [r12+NEBO_INFERENCE_SESSION_BYTES_WRITTEN],rax
 xor eax,eax
 jmp .return
.argument: mov eax,NEBO_INFERENCE_E_ARGUMENT
 jmp .return
.limit: mov eax,NEBO_INFERENCE_E_LIMIT
 jmp .return
.shape: mov eax,NEBO_INFERENCE_E_SHAPE
 jmp .return
.capacity: mov eax,NEBO_INFERENCE_E_CAPACITY
 jmp .return
.overlap: mov eax,NEBO_INFERENCE_E_OVERLAP
 jmp .return
.nonfinite: mov eax,NEBO_INFERENCE_E_NONFINITE
.return:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=session, rsi=iterations (1..16). Uses two fixed 512-byte stack vectors.
nebo_inference_warmup:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,1024
 mov r12,rdi
 mov r13,rsi
 call inference_validate_session
 test eax,eax
 jnz .warm_return
 test r13,r13
 jz .warm_limit
 cmp r13,16
 ja .warm_limit
 mov r14,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 xor eax,eax
 mov rdi,rsp
 mov ecx,128
 rep stosq
 xor ebx,ebx
.warm_loop:
 cmp rbx,r13
 jae .warm_ok
 mov rdi,r12
 mov rsi,rsp
 lea rdx,[rsp+512]
 mov ecx,1
 mov r8,r14
 mov r9,r14
 call inference_execute
 test eax,eax
 jnz .warm_return
 dec qword [r12+NEBO_INFERENCE_SESSION_RUNS]
 dec qword [r12+NEBO_INFERENCE_SESSION_SAMPLES]
 sub [r12+NEBO_INFERENCE_SESSION_ELEMENTS],r14
 mov r15,r14
 shl r15,3
 sub [r12+NEBO_INFERENCE_SESSION_BYTES_READ],r15
 sub [r12+NEBO_INFERENCE_SESSION_BYTES_WRITTEN],r15
 xor ecx,ecx
.warm_checksum:
 cmp rcx,r14
 jae .warm_next
 mov rax,[rsp+512+rcx*8]
 xor [r12+NEBO_INFERENCE_SESSION_CHECKSUM],rax
 inc rcx
 jmp .warm_checksum
.warm_next:
 inc rbx
 jmp .warm_loop
.warm_ok:
 xor eax,eax
 jmp .warm_return
.warm_limit: mov eax,NEBO_INFERENCE_E_LIMIT
.warm_return:
 add rsp,1024
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=session, rsi=Plan48: input/output/workspace/ops/batch/features.
nebo_inference_memory_plan:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 sub rsp,8
 call inference_validate_session
 add rsp,8
 test eax,eax
 jnz .plan_return
 test r13,r13
 jz .plan_argument
 mov rax,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 imul rax,[r12+NEBO_INFERENCE_SESSION_BATCH_LIMIT]
 shl rax,3
 mov [r13],rax
 mov [r13+8],rax
 mov [r13+16],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_OP_COUNT]
 mov [r13+24],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_BATCH_LIMIT]
 mov [r13+32],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_FEATURES]
 mov [r13+40],rax
 xor eax,eax
 jmp .plan_return
.plan_argument: mov eax,NEBO_INFERENCE_E_ARGUMENT
.plan_return:
 pop r13
 pop r12
 ret

; rdi=session, rsi=Profile48. No input values or parameter material is exposed.
nebo_inference_profile:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 sub rsp,8
 call inference_validate_session
 add rsp,8
 test eax,eax
 jnz .profile_return
 test r13,r13
 jz .profile_argument
 mov rax,[r12+NEBO_INFERENCE_SESSION_RUNS]
 mov [r13],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_SAMPLES]
 mov [r13+8],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_ELEMENTS]
 mov [r13+16],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_BYTES_READ]
 add rax,[r12+NEBO_INFERENCE_SESSION_BYTES_WRITTEN]
 mov [r13+24],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_WORKSPACE_CAP]
 mov [r13+32],rax
 mov rax,[r12+NEBO_INFERENCE_SESSION_OP_COUNT]
 mov [r13+40],rax
 xor eax,eax
 jmp .profile_return
.profile_argument: mov eax,NEBO_INFERENCE_E_ARGUMENT
.profile_return:
 pop r13
 pop r12
 ret

inference_validate_session:
 test rdi,rdi
 jz .valid_argument
 mov rax,NEBO_INFERENCE_SESSION_MAGIC
 cmp [rdi+NEBO_INFERENCE_SESSION_MAGIC_OFF],rax
 jne .valid_state
 cmp qword [rdi+NEBO_INFERENCE_SESSION_STATE],NEBO_INFERENCE_SESSION_STATE_CANCELLED
 je .valid_cancelled
 cmp qword [rdi+NEBO_INFERENCE_SESSION_STATE],NEBO_INFERENCE_SESSION_STATE_READY
 jne .valid_state
 cmp qword [rdi+NEBO_INFERENCE_SESSION_RESERVED],0
 jne .valid_state
 cmp qword [rdi+NEBO_INFERENCE_SESSION_PROFILE],1
 ja .valid_state
 mov rcx,[rdi+NEBO_INFERENCE_SESSION_OP_COUNT]
 test rcx,rcx
 jz .valid_limit
 cmp rcx,NEBO_INFERENCE_MAX_OPERATIONS
 ja .valid_limit
 mov r8,[rdi+NEBO_INFERENCE_SESSION_OPS]
 test r8,r8
 jz .valid_argument
 mov r9,[rdi+NEBO_INFERENCE_SESSION_FEATURES]
 test r9,r9
 jz .valid_limit
 cmp r9,NEBO_INFERENCE_MAX_FEATURES
 ja .valid_limit
 mov r10,[rdi+NEBO_INFERENCE_SESSION_BATCH_LIMIT]
 test r10,r10
 jz .valid_limit
 cmp r10,NEBO_INFERENCE_MAX_BATCH
 ja .valid_limit
 cmp qword [rdi+NEBO_INFERENCE_SESSION_WORKSPACE],0
 je .valid_argument
 mov rax,[rdi+NEBO_INFERENCE_SESSION_WORKSPACE_CAP]
 cmp rax,NEBO_INFERENCE_MAX_WORKSPACE
 ja .valid_limit
 mov r11,r9
 imul r11,r10
 shl r11,3
 cmp rax,r11
 jb .valid_limit
 xor edx,edx
.valid_ops:
 cmp rdx,rcx
 jae .valid_ok
 mov rax,rdx
 imul rax,NEBO_INFERENCE_OP_SIZE
 add rax,r8
 cmp [rax+24],r9
 jne .valid_shape
 cmp qword [rax],NEBO_INFERENCE_OP_IDENTITY
 je .valid_no_params
 cmp qword [rax],NEBO_INFERENCE_OP_RELU
 je .valid_no_params
 cmp qword [rax],NEBO_INFERENCE_OP_SCALE_BIAS
 jne .valid_state
 cmp qword [rax+8],0
 je .valid_argument
 cmp qword [rax+16],0
 je .valid_argument
 jmp .valid_next
.valid_no_params:
 cmp qword [rax+8],0
 jne .valid_state
 cmp qword [rax+16],0
 jne .valid_state
.valid_next:
 inc rdx
 jmp .valid_ops
.valid_ok: xor eax,eax
 ret
.valid_argument: mov eax,NEBO_INFERENCE_E_ARGUMENT
 ret
.valid_limit: mov eax,NEBO_INFERENCE_E_LIMIT
 ret
.valid_state: mov eax,NEBO_INFERENCE_E_STATE
 ret
.valid_shape: mov eax,NEBO_INFERENCE_E_SHAPE
 ret
.valid_cancelled: mov eax,NEBO_INFERENCE_E_CANCELLED
 ret

; rdi/rsi and rdx/rcx are two ranges. Overflow is conservatively overlap.
ranges_overlap:
 test rsi,rsi
 jz .ranges_no
 test rcx,rcx
 jz .ranges_no
 mov r8,rdi
 add r8,rsi
 jc .ranges_yes
 mov r9,rdx
 add r9,rcx
 jc .ranges_yes
 cmp rdi,r9
 jae .ranges_no
 cmp rdx,r8
 jae .ranges_no
.ranges_yes: mov eax,1
 ret
.ranges_no: xor eax,eax
 ret

; rdx contains raw F64 bits; eax=1 for NaN or infinity.
is_nonfinite:
 mov rax,rdx
 mov r10,0x7ff0000000000000
 and rax,r10
 xor edx,edx
 cmp rax,r10
 sete dl
 mov eax,edx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
