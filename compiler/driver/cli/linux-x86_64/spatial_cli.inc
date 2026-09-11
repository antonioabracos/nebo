; G042 bounded read-only geometry validator and local route-suite verifier.
section .rodata
cli_geometry_magic: db 'NEBO-GEOMETRY-V1',10
cli_geometry_magic_len equ $-cli_geometry_magic
cli_geometry_precision: db 'precision=exact',10
cli_geometry_precision_len equ $-cli_geometry_precision
cli_geometry_crs: db 'crs=LOCAL-CARTESIAN-V1',10
cli_geometry_crs_len equ $-cli_geometry_crs
cli_geometry_units: db 'units=millimetre',10
cli_geometry_units_len equ $-cli_geometry_units
cli_geometry_value: db 'geometry='
cli_geometry_value_len equ $-cli_geometry_value
cli_geometry_point: db 'POINT('
cli_geometry_point_len equ $-cli_geometry_point
cli_geometry_line: db 'LINESTRING('
cli_geometry_line_len equ $-cli_geometry_line
cli_geometry_polygon: db 'POLYGON(('
cli_geometry_polygon_len equ $-cli_geometry_polygon
cli_geometry_report:
 db 'geometry-check v1',10
 db 'format=NEBO-GEOMETRY-V1',10
 db 'precision=exact',10
 db 'crs=LOCAL-CARTESIAN-V1',10
 db 'units=millimetre',10
 db 'syntax=VALID',10
 db 'topology=NOT_EVALUATED',10
 db 'geometry='
cli_geometry_report_end:
cli_geometry_report_suffix:
 db 10,'repair=NOT_APPLIED',10
 db 'mutation=NO',10
cli_geometry_report_suffix_end:
cli_geometry_error:
 db 'NEBO-G042-GEOMETRY-CHECK-082: invalid incomplete or implicit geometry document',10
cli_geometry_error_end:

cli_route_magic: db 'NEBO-ROUTE-SUITE-V1',10
cli_route_magic_len equ $-cli_route_magic
cli_route_version: db 'version='
cli_route_version_len equ $-cli_route_version
cli_route_dataset: db 'dataset=synthetic-grid-v1',10
cli_route_dataset_len equ $-cli_route_dataset
cli_route_cost: db 'cost-model=distance',10
cli_route_cost_len equ $-cli_route_cost
cli_route_units: db 'units=metre',10
cli_route_units_len equ $-cli_route_units
cli_route_cases: db 'cases='
cli_route_cases_len equ $-cli_route_cases
cli_route_report:
 db 'route-bench v1',10
 db 'format=NEBO-ROUTE-SUITE-V1',10
 db 'versioned=YES',10
 db 'dataset=synthetic-grid-v1',10
 db 'cost-model=distance',10
 db 'units=metre',10
 db 'cases='
cli_route_report_end:
cli_route_report_suffix:
 db 10
 db 'deterministic=YES',10
 db 'network=FORBIDDEN',10
cli_route_report_suffix_end:
cli_route_error:
 db 'NEBO-G042-ROUTE-BENCH-083: invalid incomplete or unversioned routing suite',10
cli_route_error_end:

section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL

; RDI=line prefix, ECX=prefix length. RAX points to its non-empty value or is 0.
cli_spatial_line_value:
 push rbx
 push r12
 mov r12,rdi
 mov ebx,ecx
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r8,rbx
 jb .absent
 sub r8,rbx
 xor r9d,r9d
.candidate:
 cmp r9,r8
 ja .absent
 test r9,r9
 jz .compare
 lea rax,[rel cli_source]
 cmp byte [rax+r9-1],10
 jne .next
.compare:
 lea rsi,[rel cli_source]
 add rsi,r9
 mov rdi,r12
 mov ecx,ebx
 repe cmpsb
 jne .next
 lea rax,[rel cli_source]
 add rax,r9
 add rax,rbx
 cmp byte [rax],32
 jbe .next
 jmp .done
.next:
 inc r9
 jmp .candidate
.absent:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; RDI=complete line including LF, ECX=length. EAX=1 only at a line boundary.
cli_spatial_exact_line:
 push rbx
 push r12
 mov r12,rdi
 mov ebx,ecx
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r8,rbx
 jb .absent
 sub r8,rbx
 xor r9d,r9d
.candidate:
 cmp r9,r8
 ja .absent
 test r9,r9
 jz .compare
 lea rax,[rel cli_source]
 cmp byte [rax+r9-1],10
 jne .next
.compare:
 lea rsi,[rel cli_source]
 add rsi,r9
 mov rdi,r12
 mov ecx,ebx
 repe cmpsb
 je .present
.next:
 inc r9
 jmp .candidate
.present:
 mov eax,1
 jmp .done
.absent:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; RDI points after a prefix. EAX=1 only for a positive decimal bounded to 6 digits.
cli_spatial_positive_decimal:
 lea r8,[rel cli_source]
 add r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rdi,r8
 jae .bad
 mov al,[rdi]
 cmp al,'1'
 jb .bad
 cmp al,'9'
 ja .bad
 xor ecx,ecx
.scan:
 cmp rdi,r8
 jae .good
 mov al,[rdi]
 cmp al,10
 je .good
 cmp al,'0'
 jb .bad
 cmp al,'9'
 ja .bad
 inc ecx
 cmp ecx,6
 ja .bad
 inc rdi
 jmp .scan
.good:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; RDI points at a known non-empty line value. Write it without its LF.
cli_spatial_write_line_value:
 push rbx
 mov rbx,rdi
 lea r8,[rel cli_source]
 add r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 xor esi,esi
.count:
 cmp rdi,r8
 jae .write
 cmp byte [rdi],10
 je .write
 inc rdi
 inc esi
 jmp .count
.write:
 mov rdi,rbx
 call cli_write_stdout
 pop rbx
 ret

; RDI points at a geometry value. Validate a bounded integer WKT shape token.
cli_spatial_geometry_value_valid:
 push rbx
 push r12
 mov r12,rdi
 lea rsi,[rel cli_geometry_point]
 mov ecx,cli_geometry_point_len
 repe cmpsb
 je .point
 mov rdi,r12
 lea rsi,[rel cli_geometry_line]
 mov ecx,cli_geometry_line_len
 repe cmpsb
 je .line
 mov rdi,r12
 lea rsi,[rel cli_geometry_polygon]
 mov ecx,cli_geometry_polygon_len
 repe cmpsb
 je .polygon
 jmp .invalid
.point:
 lea rdi,[r12+cli_geometry_point_len]
 mov ebx,1
 mov r12d,1
 mov r11d,1
 jmp .coordinate
.line:
 lea rdi,[r12+cli_geometry_line_len]
 mov ebx,1
 mov r12d,2
 mov r11d,4096
 jmp .coordinate
.polygon:
 lea rdi,[r12+cli_geometry_polygon_len]
 mov ebx,2
 mov r12d,4
 mov r11d,4096
.coordinate:
 lea r8,[rel cli_source]
 add r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 xor r10d,r10d
.first_sign:
 cmp rdi,r8
 jae .invalid
 mov al,[rdi]
 cmp al,'-'
 jne .first_digit
 inc rdi
.first_digit:
 cmp rdi,r8
 jae .invalid
 mov al,[rdi]
 cmp al,'0'
 jb .invalid
 cmp al,'9'
 ja .invalid
.first_digits:
 inc rdi
 cmp rdi,r8
 jae .invalid
 mov al,[rdi]
 cmp al,'0'
 jb .coordinate_space
 cmp al,'9'
 jbe .first_digits
.coordinate_space:
 cmp al,' '
 jne .invalid
 inc rdi
 cmp rdi,r8
 jae .invalid
 cmp byte [rdi],'-'
 jne .second_digit
 inc rdi
.second_digit:
 cmp rdi,r8
 jae .invalid
 mov al,[rdi]
 cmp al,'0'
 jb .invalid
 cmp al,'9'
 ja .invalid
.second_digits:
 inc rdi
 cmp rdi,r8
 jae .invalid
 mov al,[rdi]
 cmp al,'0'
 jb .coordinate_end
 cmp al,'9'
 jbe .second_digits
.coordinate_end:
 inc r10d
 cmp r10d,r11d
 ja .invalid
 cmp al,','
 jne .closing
 inc rdi
 jmp .first_sign
.closing:
 cmp r10d,r12d
 jb .invalid
 cmp al,')'
 jne .invalid
 cmp ebx,2
 jne .after_close
 cmp byte [rdi+1],')'
 jne .invalid
 inc rdi
.after_close:
 inc rdi
 cmp rdi,r8
 je .valid
 cmp byte [rdi],10
 jne .invalid
.valid:
 mov eax,1
 pop r12
 pop rbx
 ret
.invalid:
 xor eax,eax
 pop r12
 pop rbx
 ret

cli_geometry_check:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],cli_geometry_magic_len
 jb .bad
 lea rsi,[rel cli_source]
 lea rdi,[rel cli_geometry_magic]
 mov ecx,cli_geometry_magic_len
 repe cmpsb
 jne .bad
 lea rdi,[rel cli_geometry_precision]
 mov ecx,cli_geometry_precision_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_geometry_crs]
 mov ecx,cli_geometry_crs_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_geometry_units]
 mov ecx,cli_geometry_units_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_geometry_value]
 mov ecx,cli_geometry_value_len
 call cli_spatial_line_value
 test rax,rax
 jz .bad
 mov rdi,rax
 call cli_spatial_geometry_value_valid
 test eax,eax
 jz .bad
 lea rdi,[rel cli_geometry_report]
 mov esi,cli_geometry_report_end-cli_geometry_report
 call cli_write_stdout
 lea rdi,[rel cli_geometry_value]
 mov ecx,cli_geometry_value_len
 call cli_spatial_line_value
 mov rdi,rax
 call cli_spatial_write_line_value
 lea rdi,[rel cli_geometry_report_suffix]
 mov esi,cli_geometry_report_suffix_end-cli_geometry_report_suffix
 call cli_write_stdout
 xor eax,eax
 ret
.bad:
 lea rdi,[rel cli_geometry_error]
 mov esi,cli_geometry_error_end-cli_geometry_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

cli_route_bench:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],cli_route_magic_len
 jb .bad
 lea rsi,[rel cli_source]
 lea rdi,[rel cli_route_magic]
 mov ecx,cli_route_magic_len
 repe cmpsb
 jne .bad
 lea rdi,[rel cli_route_version]
 mov ecx,cli_route_version_len
 call cli_spatial_line_value
 test rax,rax
 jz .bad
 mov rdi,rax
 call cli_spatial_positive_decimal
 test eax,eax
 jz .bad
 lea rdi,[rel cli_route_dataset]
 mov ecx,cli_route_dataset_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_route_cost]
 mov ecx,cli_route_cost_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_route_units]
 mov ecx,cli_route_units_len
 call cli_spatial_exact_line
 test eax,eax
 jz .bad
 lea rdi,[rel cli_route_cases]
 mov ecx,cli_route_cases_len
 call cli_spatial_line_value
 test rax,rax
 jz .bad
 mov rdi,rax
 call cli_spatial_positive_decimal
 test eax,eax
 jz .bad
 lea rdi,[rel cli_route_report]
 mov esi,cli_route_report_end-cli_route_report
 call cli_write_stdout
 lea rdi,[rel cli_route_cases]
 mov ecx,cli_route_cases_len
 call cli_spatial_line_value
 mov rdi,rax
 call cli_spatial_write_line_value
 lea rdi,[rel cli_route_report_suffix]
 mov esi,cli_route_report_suffix_end-cli_route_report_suffix
 call cli_write_stdout
 xor eax,eax
 ret
.bad:
 lea rdi,[rel cli_route_error]
 mov esi,cli_route_error_end-cli_route_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

%undef call
