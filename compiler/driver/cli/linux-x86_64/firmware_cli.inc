; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F07 bounded simulator-only firmware CLI reports.
%ifndef NEBO_FIRMWARE_CLI_INC
%define NEBO_FIRMWARE_CLI_INC 1

section .rodata
cli_firmware_build_report:
 db 'firmware-build v1',10
 db 'board=NEBO_REFERENCE_BOARD_SIM_V1',10
 db 'target=x86_64-nebo-reference-none',10
 db 'image=elf64+raw-bin',10
 db 'deterministic=yes',10
 db 'hardware=false',10
cli_firmware_build_report_end:
cli_firmware_test_report:
 db 'firmware-test v1',10
 db 'simulator=NEBO_REFERENCE_BOARD_SIM_V1',10
 db 'vectors=16',10
 db 'power-loss-corpus=bounded',10
 db 'hard-realtime=false',10
 db 'hardware=false',10
cli_firmware_test_report_end:

section .text
; edi=0 build report, edi=1 simulator test report.
cli_firmware_report:
 test edi,edi
 jnz .test
 lea rdi,[rel cli_firmware_build_report]
 mov esi,cli_firmware_build_report_end-cli_firmware_build_report
 jmp cli_write_stdout
.test:
 lea rdi,[rel cli_firmware_test_report]
 mov esi,cli_firmware_test_report_end-cli_firmware_test_report
 jmp cli_write_stdout

%endif
