; COLECOES-PRIMITIVAS-PF005 deterministic bounded array program emitter
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_vertical.inc"
%include "compiler/codegen/collections/x86_64/array_codegen.inc"
extern neboc_assembly_writer_append_bytes
section .rodata
prefix: db 10,'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    mov rax, '
prefix_len equ $-prefix
suffix: db 10,'    ret',10
suffix_len equ $-suffix
digits: db '0123456789abcdef'
section .data
value: db '0x0000000000000000'
value_len equ $-value
g011_template:
 db 10,'extern nebo_g011_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g011_mode_offset equ $-g011_template
 db '00000000',10
 db '    mov esi, 0x'
g011_seed_offset equ $-g011_template
 db '00000000',10
 db '    call nebo_g011_source_probe',10
 db '    ret',10
g011_template_len equ $-g011_template
g012_template:
 db 10,'extern nebo_g012_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g012_mode_offset equ $-g012_template
 db '00000000',10
 db '    mov esi, 0x'
g012_seed_offset equ $-g012_template
 db '00000000',10
 db '    call nebo_g012_source_probe',10
 db '    ret',10
g012_template_len equ $-g012_template
g013_template:
 db 10,'extern nebo_g013_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g013_mode_offset equ $-g013_template
 db '00000000',10
 db '    mov esi, 0x'
g013_seed_offset equ $-g013_template
 db '00000000',10
 db '    call nebo_g013_source_probe',10
 db '    ret',10
g013_template_len equ $-g013_template
g008_template:
 db 10,'extern nebo_g008_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g008_mode_offset equ $-g008_template
 db '00000000',10
 db '    mov esi, 0x'
g008_seed_offset equ $-g008_template
 db '00000000',10
 db '    call nebo_g008_source_probe',10
 db '    ret',10
g008_template_len equ $-g008_template
g009_template:
 db 10,'extern nebo_g009_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g009_mode_offset equ $-g009_template
 db '00000000',10
 db '    mov esi, 0x'
g009_seed_offset equ $-g009_template
 db '00000000',10
 db '    call nebo_g009_source_probe',10
 db '    ret',10
g009_template_len equ $-g009_template
g010_template:
 db 10,'extern nebo_g010_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g010_mode_offset equ $-g010_template
 db '00000000',10
 db '    mov esi, 0x'
g010_seed_offset equ $-g010_template
 db '00000000',10
 db '    call nebo_g010_source_probe',10
 db '    ret',10
g010_template_len equ $-g010_template
g025_template:
 db 10,'extern nebo_g025_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g025_mode_offset equ $-g025_template
 db '00000000',10
 db '    mov esi, 0x'
g025_seed_offset equ $-g025_template
 db '00000000',10
 db '    call nebo_g025_source_probe',10
 db '    ret',10
g025_template_len equ $-g025_template
g031_template:
 db 10,'extern nebo_reactive_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g031_mode_offset equ $-g031_template
 db '00000000',10
 db '    mov esi, 0x'
g031_seed_offset equ $-g031_template
 db '00000000',10
 db '    call nebo_reactive_source_probe',10
 db '    ret',10
g031_template_len equ $-g031_template
g032_template:
 db 10,'extern nebo_database_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g032_mode_offset equ $-g032_template
 db '00000000',10
 db '    mov esi, 0x'
g032_seed_offset equ $-g032_template
 db '00000000',10
 db '    call nebo_database_source_probe',10
 db '    ret',10
g032_template_len equ $-g032_template
g014_template:
 db 10,'extern nebo_g014_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g014_mode_offset equ $-g014_template
 db '00000000',10
 db '    mov esi, 0x'
g014_seed_offset equ $-g014_template
 db '00000000',10
 db '    call nebo_g014_source_probe',10
 db '    ret',10
g014_template_len equ $-g014_template
g015_template:
 db 10,'extern nebo_g015_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g015_mode_offset equ $-g015_template
 db '00000000',10
 db '    mov esi, 0x'
g015_seed_offset equ $-g015_template
 db '00000000',10
 db '    call nebo_g015_source_probe',10
 db '    ret',10
g015_template_len equ $-g015_template
g016_template:
 db 10,'extern nebo_g016_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g016_mode_offset equ $-g016_template
 db '00000000',10
 db '    mov esi, 0x'
g016_seed_offset equ $-g016_template
 db '00000000',10
 db '    call nebo_g016_source_probe',10
 db '    ret',10
g016_template_len equ $-g016_template
g018_template:
 db 10,'extern nebo_g018_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g018_mode_offset equ $-g018_template
 db '00000000',10
 db '    mov esi, 0x'
g018_seed_offset equ $-g018_template
 db '00000000',10
 db '    call nebo_g018_source_probe',10
 db '    ret',10
g018_template_len equ $-g018_template
g019_template:
 db 10,'extern nebo_g019_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g019_mode_offset equ $-g019_template
 db '00000000',10
 db '    mov esi, 0x'
g019_seed_offset equ $-g019_template
 db '00000000',10
 db '    call nebo_g019_source_probe',10
 db '    ret',10
g019_template_len equ $-g019_template
g087_template:
 db 10,'extern nebo_g087_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g087_mode_offset equ $-g087_template
 db '00000000',10
 db '    mov esi, 0x'
g087_seed_offset equ $-g087_template
 db '00000000',10
 db '    call nebo_g087_source_probe',10
 db '    ret',10
g087_template_len equ $-g087_template
g088_template:
 db 10,'extern nebo_g088_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g088_mode_offset equ $-g088_template
 db '00000000',10
 db '    mov esi, 0x'
g088_seed_offset equ $-g088_template
 db '00000000',10
 db '    call nebo_g088_source_probe',10
 db '    ret',10
g088_template_len equ $-g088_template
g089_template:
 db 10,'extern nebo_g089_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g089_mode_offset equ $-g089_template
 db '00000000',10
 db '    mov esi, 0x'
g089_seed_offset equ $-g089_template
 db '00000000',10
 db '    call nebo_g089_source_probe',10
 db '    ret',10
g089_template_len equ $-g089_template
g090_template:
 db 10,'extern nebo_g090_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g090_mode_offset equ $-g090_template
 db '00000000',10
 db '    mov esi, 0x'
g090_seed_offset equ $-g090_template
 db '00000000',10
 db '    call nebo_g090_source_probe',10
 db '    ret',10
g090_template_len equ $-g090_template
g091_template:
 db 10,'extern nebo_g091_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g091_mode_offset equ $-g091_template
 db '00000000',10
 db '    mov esi, 0x'
g091_seed_offset equ $-g091_template
 db '00000000',10
 db '    call nebo_g091_source_probe',10
 db '    ret',10
g091_template_len equ $-g091_template
g092_template:
 db 10,'extern nebo_g092_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g092_mode_offset equ $-g092_template
 db '00000000',10
 db '    mov esi, 0x'
g092_seed_offset equ $-g092_template
 db '00000000',10
 db '    call nebo_g092_source_probe',10
 db '    ret',10
g092_template_len equ $-g092_template
g093_template:
 db 10,'extern nebo_g093_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g093_mode_offset equ $-g093_template
 db '00000000',10
 db '    mov esi, 0x'
g093_seed_offset equ $-g093_template
 db '00000000',10
 db '    call nebo_g093_source_probe',10
 db '    ret',10
g093_template_len equ $-g093_template
g094_template:
 db 10,'extern nebo_g094_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g094_mode_offset equ $-g094_template
 db '00000000',10
 db '    mov esi, 0x'
g094_seed_offset equ $-g094_template
 db '00000000',10
 db '    call nebo_g094_source_probe',10
 db '    ret',10
g094_template_len equ $-g094_template
g097_template:
 db 10,'extern nebo_g097_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g097_mode_offset equ $-g097_template
 db '00000000',10
 db '    mov esi, 0x'
g097_seed_offset equ $-g097_template
 db '00000000',10
 db '    call nebo_g097_source_probe',10
 db '    ret',10
g097_template_len equ $-g097_template
g098_template:
 db 10,'extern nebo_g098_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g098_mode_offset equ $-g098_template
 db '00000000',10
 db '    mov esi, 0x'
g098_seed_offset equ $-g098_template
 db '00000000',10
 db '    call nebo_g098_source_probe',10
 db '    ret',10
g098_template_len equ $-g098_template
g099_template:
 db 10,'extern nebo_g099_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g099_mode_offset equ $-g099_template
 db '00000000',10
 db '    mov esi, 0x'
g099_seed_offset equ $-g099_template
 db '00000000',10
 db '    call nebo_g099_source_probe',10
 db '    ret',10
g099_template_len equ $-g099_template
g100_template:
 db 10,'extern nebo_g100_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g100_mode_offset equ $-g100_template
 db '00000000',10
 db '    mov esi, 0x'
g100_seed_offset equ $-g100_template
 db '00000000',10
 db '    call nebo_g100_source_probe',10
 db '    ret',10
g100_template_len equ $-g100_template
g101_template:
 db 10,'extern nebo_g101_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g101_mode_offset equ $-g101_template
 db '00000000',10
 db '    mov esi, 0x'
g101_seed_offset equ $-g101_template
 db '00000000',10
 db '    call nebo_g101_source_probe',10
 db '    ret',10
g101_template_len equ $-g101_template
g102_template:
 db 10,'extern nebo_g102_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g102_mode_offset equ $-g102_template
 db '00000000',10
 db '    mov esi, 0x'
g102_seed_offset equ $-g102_template
 db '00000000',10
 db '    call nebo_g102_source_probe',10
 db '    ret',10
g102_template_len equ $-g102_template
g103_template:
 db 10,'extern nebo_g103_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g103_mode_offset equ $-g103_template
 db '00000000',10
 db '    mov esi, 0x'
g103_seed_offset equ $-g103_template
 db '00000000',10
 db '    call nebo_g103_source_probe',10
 db '    ret',10
g103_template_len equ $-g103_template
g104_template:
 db 10,'extern nebo_g104_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g104_mode_offset equ $-g104_template
 db '00000000',10
 db '    mov esi, 0x'
g104_seed_offset equ $-g104_template
 db '00000000',10
 db '    call nebo_g104_source_probe',10
 db '    ret',10
g104_template_len equ $-g104_template
g105_template:
 db 10,'extern nebo_g105_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g105_mode_offset equ $-g105_template
 db '00000000',10
 db '    mov esi, 0x'
g105_seed_offset equ $-g105_template
 db '00000000',10
 db '    call nebo_g105_source_probe',10
 db '    ret',10
g105_template_len equ $-g105_template
g106_template:
 db 10,'extern nebo_g106_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g106_mode_offset equ $-g106_template
 db '00000000',10
 db '    mov esi, 0x'
g106_seed_offset equ $-g106_template
 db '00000000',10
 db '    mov edx, 0x'
g106_variant_offset equ $-g106_template
 db '00000000',10
 db '    call nebo_g106_source_probe',10
 db '    ret',10
g106_template_len equ $-g106_template
g107_template:
 db 10,'extern nebo_g107_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g107_mode_offset equ $-g107_template
 db '00000000',10
 db '    mov esi, 0x'
g107_seed_offset equ $-g107_template
 db '00000000',10
 db '    mov edx, 0x'
g107_variant_offset equ $-g107_template
 db '00000000',10
 db '    call nebo_g107_source_probe',10
 db '    ret',10
g107_template_len equ $-g107_template
g108_template:
 db 10,'extern nebo_g108_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g108_mode_offset equ $-g108_template
 db '00000000',10
 db '    mov esi, 0x'
g108_seed_offset equ $-g108_template
 db '00000000',10
 db '    mov edx, 0x'
g108_variant_offset equ $-g108_template
 db '00000000',10
 db '    call nebo_g108_source_probe',10
 db '    ret',10
g108_template_len equ $-g108_template
g110_template:
 db 10,'extern nebo_g110_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g110_mode_offset equ $-g110_template
 db '00000000',10
 db '    mov esi, 0x'
g110_seed_offset equ $-g110_template
 db '00000000',10
 db '    call nebo_g110_source_probe',10
 db '    ret',10
g110_template_len equ $-g110_template
g111_template:
 db 10,'extern nebo_g111_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g111_mode_offset equ $-g111_template
 db '00000000',10
 db '    mov esi, 0x'
g111_seed_offset equ $-g111_template
 db '00000000',10
 db '    call nebo_g111_source_probe',10
 db '    ret',10
g111_template_len equ $-g111_template
g112_template:
 db 10,'extern nebo_g112_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g112_mode_offset equ $-g112_template
 db '00000000',10
 db '    mov esi, 0x'
g112_seed_offset equ $-g112_template
 db '00000000',10
 db '    call nebo_g112_source_probe',10
 db '    ret',10
g112_template_len equ $-g112_template
g113_template:
 db 10,'extern nebo_g113_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g113_mode_offset equ $-g113_template
 db '00000000',10
 db '    mov esi, 0x'
g113_seed_offset equ $-g113_template
 db '00000000',10
 db '    call nebo_g113_source_probe',10
 db '    ret',10
g113_template_len equ $-g113_template
g114_template:
 db 10,'extern nebo_g114_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g114_mode_offset equ $-g114_template
 db '00000000',10
 db '    mov esi, 0x'
g114_seed_offset equ $-g114_template
 db '00000000',10
 db '    call nebo_g114_source_probe',10
 db '    ret',10
g114_template_len equ $-g114_template
g115_template:
 db 10,'extern nebo_g115_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g115_mode_offset equ $-g115_template
 db '00000000',10
 db '    mov esi, 0x'
g115_seed_offset equ $-g115_template
 db '00000000',10
 db '    call nebo_g115_source_probe',10
 db '    ret',10
g115_template_len equ $-g115_template
g116_template:
 db 10,'extern nebo_g116_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g116_mode_offset equ $-g116_template
 db '00000000',10
 db '    mov esi, 0x'
g116_seed_offset equ $-g116_template
 db '00000000',10
 db '    call nebo_g116_source_probe',10
 db '    ret',10
g116_template_len equ $-g116_template
g109_template:
 db 10,'extern nebo_g109_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g109_mode_offset equ $-g109_template
 db '00000000',10
 db '    mov esi, 0x'
g109_seed_offset equ $-g109_template
 db '00000000',10
 db '    mov edx, 0x'
g109_config_offset equ $-g109_template
 db '00000000',10
 db '    call nebo_g109_source_probe',10
 db '    ret',10
g109_template_len equ $-g109_template
g096_template:
 db 10,'extern nebo_g096_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g096_mode_offset equ $-g096_template
 db '00000000',10
 db '    mov esi, 0x'
g096_seed_offset equ $-g096_template
 db '00000000',10
 db '    call nebo_g096_source_probe',10
 db '    ret',10
g096_template_len equ $-g096_template
g095_template:
 db 10,'extern nebo_g095_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g095_mode_offset equ $-g095_template
 db '00000000',10
 db '    mov esi, 0x'
g095_seed_offset equ $-g095_template
 db '00000000',10
 db '    call nebo_g095_source_probe',10
 db '    ret',10
g095_template_len equ $-g095_template
g066_template:
 db 10,'extern nebo_g066_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g066_mode_offset equ $-g066_template
 db '00000000',10
 db '    mov esi, 0x'
g066_seed_offset equ $-g066_template
 db '00000000',10
 db '    call nebo_g066_source_probe',10
 db '    ret',10
g066_template_len equ $-g066_template
g067_template:
 db 10,'extern nebo_g067_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g067_mode_offset equ $-g067_template
 db '00000000',10
 db '    mov esi, 0x'
g067_seed_offset equ $-g067_template
 db '00000000',10
 db '    call nebo_g067_source_probe',10
 db '    ret',10
g067_template_len equ $-g067_template
g068_template:
 db 10,'extern nebo_g068_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g068_mode_offset equ $-g068_template
 db '00000000',10
 db '    mov esi, 0x'
g068_seed_offset equ $-g068_template
 db '00000000',10
 db '    call nebo_g068_source_probe',10
 db '    ret',10
g068_template_len equ $-g068_template
g069_template:
 db 10,'extern nebo_g069_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g069_mode_offset equ $-g069_template
 db '00000000',10
 db '    mov esi, 0x'
g069_seed_offset equ $-g069_template
 db '00000000',10
 db '    call nebo_g069_source_probe',10
 db '    ret',10
g069_template_len equ $-g069_template
g070_template:
 db 10,'extern nebo_g070_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g070_mode_offset equ $-g070_template
 db '00000000',10
 db '    mov esi, 0x'
g070_seed_offset equ $-g070_template
 db '00000000',10
 db '    call nebo_g070_source_probe',10
 db '    ret',10
g070_template_len equ $-g070_template
g071_template:
 db 10,'extern nebo_g071_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g071_mode_offset equ $-g071_template
 db '00000000',10
 db '    mov esi, 0x'
g071_seed_offset equ $-g071_template
 db '00000000',10
 db '    call nebo_g071_source_probe',10
 db '    ret',10
g071_template_len equ $-g071_template
g072_template:
 db 10,'extern nebo_g072_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g072_mode_offset equ $-g072_template
 db '00000000',10
 db '    mov esi, 0x'
g072_seed_offset equ $-g072_template
 db '00000000',10
 db '    call nebo_g072_source_probe',10
 db '    ret',10
g072_template_len equ $-g072_template
g073_template:
 db 10,'extern nebo_g073_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g073_mode_offset equ $-g073_template
 db '00000000',10
 db '    mov esi, 0x'
g073_seed_offset equ $-g073_template
 db '00000000',10
 db '    call nebo_g073_source_probe',10
 db '    ret',10
g073_template_len equ $-g073_template
g074_template:
 db 10,'extern nebo_g074_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g074_mode_offset equ $-g074_template
 db '00000000',10
 db '    mov esi, 0x'
g074_seed_offset equ $-g074_template
 db '00000000',10
 db '    call nebo_g074_source_probe',10
 db '    ret',10
g074_template_len equ $-g074_template
g075_template:
 db 10,'extern nebo_g075_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g075_mode_offset equ $-g075_template
 db '00000000',10
 db '    mov esi, 0x'
g075_seed_offset equ $-g075_template
 db '00000000',10
 db '    call nebo_g075_source_probe',10
 db '    ret',10
g075_template_len equ $-g075_template
g076_template:
 db 10,'extern nebo_g076_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g076_mode_offset equ $-g076_template
 db '00000000',10
 db '    mov esi, 0x'
g076_seed_offset equ $-g076_template
 db '00000000',10
 db '    call nebo_g076_source_probe',10
 db '    ret',10
g076_template_len equ $-g076_template
g077_template:
 db 10,'extern nebo_g077_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g077_mode_offset equ $-g077_template
 db '00000000',10
 db '    mov esi, 0x'
g077_seed_offset equ $-g077_template
 db '00000000',10
 db '    call nebo_g077_source_probe',10
 db '    ret',10
g077_template_len equ $-g077_template
g078_template:
 db 10,'extern nebo_g078_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g078_mode_offset equ $-g078_template
 db '00000000',10
 db '    mov esi, 0x'
g078_seed_offset equ $-g078_template
 db '00000000',10
 db '    call nebo_g078_source_probe',10
 db '    ret',10
g078_template_len equ $-g078_template
g079_template:
 db 10,'extern nebo_g079_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g079_mode_offset equ $-g079_template
 db '00000000',10
 db '    mov esi, 0x'
g079_seed_offset equ $-g079_template
 db '00000000',10
 db '    call nebo_g079_source_probe',10
 db '    ret',10
g079_template_len equ $-g079_template
g080_template:
 db 10,'extern nebo_g080_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g080_mode_offset equ $-g080_template
 db '00000000',10
 db '    mov esi, 0x'
g080_seed_offset equ $-g080_template
 db '00000000',10
 db '    call nebo_g080_source_probe',10
 db '    ret',10
g080_template_len equ $-g080_template
g081_template:
 db 10,'extern nebo_g081_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g081_mode_offset equ $-g081_template
 db '00000000',10
 db '    mov esi, 0x'
g081_seed_offset equ $-g081_template
 db '00000000',10
 db '    call nebo_g081_source_probe',10
 db '    ret',10
g081_template_len equ $-g081_template
g082_template:
 db 10,'extern nebo_g082_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g082_mode_offset equ $-g082_template
 db '00000000',10
 db '    mov esi, 0x'
g082_seed_offset equ $-g082_template
 db '00000000',10
 db '    call nebo_g082_source_probe',10
 db '    ret',10
g082_template_len equ $-g082_template
g083_template:
 db 10,'extern nebo_g083_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g083_mode_offset equ $-g083_template
 db '00000000',10
 db '    mov esi, 0x'
g083_seed_offset equ $-g083_template
 db '00000000',10
 db '    call nebo_g083_source_probe',10
 db '    ret',10
g083_template_len equ $-g083_template
g084_template:
 db 10,'extern nebo_g084_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g084_mode_offset equ $-g084_template
 db '00000000',10
 db '    mov esi, 0x'
g084_seed_offset equ $-g084_template
 db '00000000',10
 db '    call nebo_g084_source_probe',10
 db '    ret',10
g084_template_len equ $-g084_template
g028_template:
 db 10,'extern nebo_g028_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g028_mode_offset equ $-g028_template
 db '00000000',10
 db '    mov esi, 0x'
g028_seed_offset equ $-g028_template
 db '00000000',10
 db '    call nebo_g028_source_probe',10
 db '    ret',10
g028_template_len equ $-g028_template
g029_template:
 db 10,'extern nebo_g029_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g029_mode_offset equ $-g029_template
 db '00000000',10
 db '    mov esi, 0x'
g029_seed_offset equ $-g029_template
 db '00000000',10
 db '    call nebo_g029_source_probe',10
 db '    ret',10
g029_template_len equ $-g029_template
g030_template:
 db 10,'extern nebo_g030_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g030_mode_offset equ $-g030_template
 db '00000000',10
 db '    mov esi, 0x'
g030_seed_offset equ $-g030_template
 db '00000000',10
 db '    call nebo_g030_source_probe',10
 db '    ret',10
g030_template_len equ $-g030_template
g035_template:
 db 10,'extern nebo_g035_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g035_mode_offset equ $-g035_template
 db '00000000',10
 db '    mov esi, 0x'
g035_seed_offset equ $-g035_template
 db '00000000',10
 db '    call nebo_g035_source_probe',10
 db '    ret',10
g035_template_len equ $-g035_template
g046_template:
 db 10,'extern nebo_g046_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g046_mode_offset equ $-g046_template
 db '00000000',10
 db '    mov esi, 0x'
g046_seed_offset equ $-g046_template
 db '00000000',10
 db '    call nebo_g046_source_probe',10
 db '    ret',10
g046_template_len equ $-g046_template
slash_core_template:
 db 10,'extern nebo_slash_core_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
slash_core_mode_offset equ $-slash_core_template
 db '00000000',10
 db '    mov esi, 0x'
slash_core_seed_offset equ $-slash_core_template
 db '00000000',10
 db '    call nebo_slash_core_source_probe',10
 db '    ret',10
slash_core_template_len equ $-slash_core_template
g060_template:
 db 10,'extern nebo_g060_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g060_mode_offset equ $-g060_template
 db '00000000',10
 db '    mov esi, 0x'
g060_seed_offset equ $-g060_template
 db '00000000',10
 db '    call nebo_g060_source_probe',10
 db '    ret',10
g060_template_len equ $-g060_template
g061_template:
 db 10,'extern nebo_g061_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g061_mode_offset equ $-g061_template
 db '00000000',10
 db '    mov esi, 0x'
g061_seed_offset equ $-g061_template
 db '00000000',10
 db '    call nebo_g061_source_probe',10
 db '    ret',10
g061_template_len equ $-g061_template
g063_template:
 db 10,'extern nebo_g063_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g063_mode_offset equ $-g063_template
 db '00000000',10
 db '    mov esi, 0x'
g063_digest_offset equ $-g063_template
 db '00000000',10
 db '    call nebo_g063_source_probe',10
 db '    ret',10
g063_template_len equ $-g063_template
g062_template:
 db 10,'extern nebo_g062_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g062_mode_offset equ $-g062_template
 db '00000000',10
 db '    mov esi, 0x'
g062_seed_offset equ $-g062_template
 db '00000000',10
 db '    call nebo_g062_source_probe',10
 db '    ret',10
g062_template_len equ $-g062_template
g059_template:
 db 10,'extern nebo_g059_source_probe',10
 db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
 db '    mov edi, 0x'
g059_mode_offset equ $-g059_template
 db '00000000',10
 db '    mov esi, 0x'
g059_seed_offset equ $-g059_template
 db '00000000',10
 db '    call nebo_g059_source_probe',10
 db '    ret',10
g059_template_len equ $-g059_template
section .text
append:
 mov rax,[rdi+NEBOC_ARRAY_CODEGEN_WRITER_OFFSET]
 test rax,rax
 jz .bad
 mov rdi,rax
 jmp neboc_assembly_writer_append_bytes
.bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
format_hex:
 add rdi,18
 lea rsi,[rel digits]
 mov ecx,16
.loop:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .loop
 ret
format_hex32:
 add rdi,8
 lea rsi,[rel digits]
 mov ecx,8
.loop:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .loop
 ret
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_array_codegen_emit_start
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_ARRAY_CODEGEN_VERTICAL_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r13+NEBOC_ARRAY_VERTICAL_FOUND_OFFSET],1
 jne .source
 cmp qword [r13+NEBOC_ARRAY_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r13+NEBOC_ARRAY_VERTICAL_FLAGS_OFFSET],NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 jne .source
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 xor rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov rdx,0x5246323034473038
 cmp rax,rdx
 je .g008
 mov rdx,0x5246323034473039
 cmp rax,rdx
 je .g009
 mov rdx,0x5246323034473130
 cmp rax,rdx
 je .g010
 mov rdx,0x5246323034473235
 cmp rax,rdx
 je .g025
 mov rdx,0x5246323034473331
 cmp rax,rdx
 je .g031
 mov rdx,0x5246323034473332
 cmp rax,rdx
 je .g032
 mov rdx,0x5246323034473134
 cmp rax,rdx
 je .g014
 mov rdx,0x5246323034473135
 cmp rax,rdx
 je .g015
 mov rdx,0x5246323034473136
 cmp rax,rdx
 je .g016
 mov rdx,0x5246323034473138
 cmp rax,rdx
 je .g018
 mov rdx,0x5246323034473139
 cmp rax,rdx
 je .g019
 mov rdx,0x5246323034473837
 cmp rax,rdx
 je .g087
 mov rdx,0x5246323034473838
 cmp rax,rdx
 je .g088
 mov rdx,0x5246323034473839
 cmp rax,rdx
 je .g089
 mov rdx,0x5246323034473930
 cmp rax,rdx
 je .g090
 mov rdx,0x5246323034473931
 cmp rax,rdx
 je .g091
 mov rdx,0x5246323034473932
 cmp rax,rdx
 je .g092
 mov rdx,0x5246323034473933
 cmp rax,rdx
 je .g093
 mov rdx,0x5246323034473934
 cmp rax,rdx
 je .g094
 mov rdx,0x5246323034473935
 cmp rax,rdx
 je .g095
 mov rdx,0x5246323034473936
 cmp rax,rdx
 je .g096
 mov rdx,0x5246323034473937
 cmp rax,rdx
 je .g097
 mov rdx,0x5246323034473938
 cmp rax,rdx
 je .g098
 mov rdx,0x5246323034473939
 cmp rax,rdx
 je .g099
 mov rdx,0x4731303053524331
 cmp rax,rdx
 je .g100
 mov rdx,0x4731303153524331
 cmp rax,rdx
 je .g101
 mov rdx,0x4731303253524331
 cmp rax,rdx
 je .g102
 mov rdx,0x4731303353524331
 cmp rax,rdx
 je .g103
 mov rdx,0x4731303453524331
 cmp rax,rdx
 je .g104
 mov rdx,0x4731303553524331
 cmp rax,rdx
 je .g105
 mov rdx,0x4731303653524331
 cmp rax,rdx
 je .g106
 mov rdx,0x4731303753524331
 cmp rax,rdx
 je .g107
 mov rdx,0x4731303853524331
 cmp rax,rdx
 je .g108
 mov rdx,0x4731303953524331
 cmp rax,rdx
 je .g109
 mov rdx,0x4731313053524331
 cmp rax,rdx
 je .g110
 mov rdx,0x4731313153524331
 cmp rax,rdx
 je .g111
 mov rdx,0x4731313253524331
 cmp rax,rdx
 je .g112
 mov rdx,0x4731313353524331
 cmp rax,rdx
 je .g113
 mov rdx,0x4731313453524331
 cmp rax,rdx
 je .g114
 mov rdx,0x4731313553524331
 cmp rax,rdx
 je .g115
 mov rdx,0x4731313653524331
 cmp rax,rdx
 je .g116
 mov rdx,0x5246323034473636
 cmp rax,rdx
 je .g066
 mov rdx,0x5246323034473637
 cmp rax,rdx
 je .g067
 mov rdx,0x5246323034473638
 cmp rax,rdx
 je .g068
 mov rdx,0x5246323034473639
 cmp rax,rdx
 je .g069
 mov rdx,0x5246323034473730
 cmp rax,rdx
 je .g070
 mov rdx,0x5246323034473731
 cmp rax,rdx
 je .g071
 mov rdx,0x5246323034473732
 cmp rax,rdx
 je .g072
 mov rdx,0x5246323034473733
 cmp rax,rdx
 je .g073
 mov rdx,0x5246323034473734
 cmp rax,rdx
 je .g074
 mov rdx,0x5246323034473735
 cmp rax,rdx
 je .g075
 mov rdx,0x5246323034473736
 cmp rax,rdx
 je .g076
 mov rdx,0x5246323034473737
 cmp rax,rdx
 je .g077
 mov rdx,0x5246323034473738
 cmp rax,rdx
 je .g078
 mov rdx,0x5246323034473739
 cmp rax,rdx
 je .g079
 mov rdx,0x5246323034473830
 cmp rax,rdx
 je .g080
 mov rdx,0x5246323034473831
 cmp rax,rdx
 je .g081
 mov rdx,0x5246323034473832
 cmp rax,rdx
 je .g082
 mov rdx,0x5246323034473833
 cmp rax,rdx
 je .g083
 mov rdx,0x5246323034473834
 cmp rax,rdx
 je .g084
 mov rdx,0x5246323034473238
 cmp rax,rdx
 je .g028
 mov rdx,0x5246323034473239
 cmp rax,rdx
 je .g029
 mov rdx,0x5246323034473330
 cmp rax,rdx
 je .g030
 mov rdx,0x5246323034473335
 cmp rax,rdx
 je .g035
 mov rdx,0x5246323034473436
 cmp rax,rdx
 je .g046
 mov rdx,0x534c415348434f52
 cmp rax,rdx
 je .slash_core
 mov rdx,0x5246323034473630
 cmp rax,rdx
 je .g060
 mov rdx,0x5246323034473631
 cmp rax,rdx
 je .g061
 mov rdx,0x5246323034473633
 cmp rax,rdx
 je .g063
 mov rdx,0x5246323034473632
 cmp rax,rdx
 je .g062
 mov rdx,0x5246323034473539
 cmp rax,rdx
 je .g059
 mov rdx,0x5246323034473133
 cmp rax,rdx
 je .g013
 mov rdx,0x5246323034473132
 cmp rax,rdx
 je .g012
 mov rdx,0x5246323034473131
 cmp rax,rdx
 jne .ordinary
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g011_template+g011_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g011_template+g011_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g011_template]
 mov edx,g011_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g008:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g008_template+g008_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g008_template+g008_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g008_template]
 mov edx,g008_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g009:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g009_template+g009_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g009_template+g009_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g009_template]
 mov edx,g009_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g010:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g010_template+g010_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g010_template+g010_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g010_template]
 mov edx,g010_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g025:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g025_template+g025_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g025_template+g025_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g025_template]
 mov edx,g025_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g031:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g031_template+g031_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g031_template+g031_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g031_template]
 mov edx,g031_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g032:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g032_template+g032_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g032_template+g032_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g032_template]
 mov edx,g032_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g014:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g014_template+g014_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g014_template+g014_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g014_template]
 mov edx,g014_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g015:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g015_template+g015_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g015_template+g015_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g015_template]
 mov edx,g015_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g016:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g016_template+g016_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g016_template+g016_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g016_template]
 mov edx,g016_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g018:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g018_template+g018_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g018_template+g018_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g018_template]
 mov edx,g018_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g019:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g019_template+g019_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g019_template+g019_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g019_template]
 mov edx,g019_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g087:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g087_template+g087_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g087_template+g087_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g087_template]
 mov edx,g087_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g088:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g088_template+g088_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g088_template+g088_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g088_template]
 mov edx,g088_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g089:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g089_template+g089_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g089_template+g089_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g089_template]
 mov edx,g089_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g090:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g090_template+g090_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g090_template+g090_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g090_template]
 mov edx,g090_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g091:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g091_template+g091_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g091_template+g091_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g091_template]
 mov edx,g091_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g092:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g092_template+g092_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g092_template+g092_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g092_template]
 mov edx,g092_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g093:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g093_template+g093_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g093_template+g093_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g093_template]
 mov edx,g093_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g094:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g094_template+g094_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g094_template+g094_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g094_template]
 mov edx,g094_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g095:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g095_template+g095_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g095_template+g095_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g095_template]
 mov edx,g095_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g096:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g096_template+g096_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g096_template+g096_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g096_template]
 mov edx,g096_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g097:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g097_template+g097_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g097_template+g097_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g097_template]
 mov edx,g097_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g098:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g098_template+g098_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g098_template+g098_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g098_template]
 mov edx,g098_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g099:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g099_template+g099_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g099_template+g099_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g099_template]
 mov edx,g099_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g100:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g100_template+g100_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g100_template+g100_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g100_template]
 mov edx,g100_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g101:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g101_template+g101_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g101_template+g101_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g101_template]
 mov edx,g101_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g102:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g102_template+g102_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g102_template+g102_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g102_template]
 mov edx,g102_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g103:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g103_template+g103_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g103_template+g103_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g103_template]
 mov edx,g103_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g104:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g104_template+g104_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g104_template+g104_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g104_template]
 mov edx,g104_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g105:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g105_template+g105_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g105_template+g105_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g105_template]
 mov edx,g105_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g106:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,40
 lea rdi,[rel g106_template+g106_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g106_template+g106_seed_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 and eax,0xff
 lea rdi,[rel g106_template+g106_variant_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g106_template]
 mov edx,g106_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g107:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,40
 lea rdi,[rel g107_template+g107_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g107_template+g107_seed_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 and eax,0xff
 lea rdi,[rel g107_template+g107_variant_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g107_template]
 mov edx,g107_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g108:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,40
 lea rdi,[rel g108_template+g108_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g108_template+g108_seed_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 and eax,0xff
 lea rdi,[rel g108_template+g108_variant_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g108_template]
 mov edx,g108_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g110:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g110_template+g110_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g110_template+g110_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g110_template]
 mov edx,g110_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g111:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g111_template+g111_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g111_template+g111_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g111_template]
 mov edx,g111_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g112:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g112_template+g112_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g112_template+g112_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g112_template]
 mov edx,g112_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g113:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g113_template+g113_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g113_template+g113_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g113_template]
 mov edx,g113_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g114:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g114_template+g114_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g114_template+g114_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g114_template]
 mov edx,g114_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g115:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g115_template+g115_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g115_template+g115_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g115_template]
 mov edx,g115_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g116:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g116_template+g116_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g116_template+g116_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g116_template]
 mov edx,g116_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g109:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,56
 lea rdi,[rel g109_template+g109_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g109_template+g109_seed_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 and eax,0xffff
 lea rdi,[rel g109_template+g109_config_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g109_template]
 mov edx,g109_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g066:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g066_template+g066_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g066_template+g066_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g066_template]
 mov edx,g066_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g067:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g067_template+g067_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g067_template+g067_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g067_template]
 mov edx,g067_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g068:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g068_template+g068_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g068_template+g068_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g068_template]
 mov edx,g068_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g069:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g069_template+g069_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g069_template+g069_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g069_template]
 mov edx,g069_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g070:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g070_template+g070_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g070_template+g070_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g070_template]
 mov edx,g070_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g071:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g071_template+g071_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g071_template+g071_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g071_template]
 mov edx,g071_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g072:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g072_template+g072_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g072_template+g072_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g072_template]
 mov edx,g072_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g073:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g073_template+g073_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g073_template+g073_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g073_template]
 mov edx,g073_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g074:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g074_template+g074_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g074_template+g074_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g074_template]
 mov edx,g074_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g075:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g075_template+g075_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g075_template+g075_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g075_template]
 mov edx,g075_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g076:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g076_template+g076_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g076_template+g076_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g076_template]
 mov edx,g076_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g077:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g077_template+g077_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g077_template+g077_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g077_template]
 mov edx,g077_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g078:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g078_template+g078_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g078_template+g078_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g078_template]
 mov edx,g078_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g079:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g079_template+g079_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g079_template+g079_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g079_template]
 mov edx,g079_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g080:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g080_template+g080_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g080_template+g080_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g080_template]
 mov edx,g080_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g081:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g081_template+g081_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g081_template+g081_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g081_template]
 mov edx,g081_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g082:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g082_template+g082_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g082_template+g082_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g082_template]
 mov edx,g082_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g083:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g083_template+g083_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g083_template+g083_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g083_template]
 mov edx,g083_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g084:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g084_template+g084_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g084_template+g084_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g084_template]
 mov edx,g084_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g028:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g028_template+g028_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g028_template+g028_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g028_template]
 mov edx,g028_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g029:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g029_template+g029_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g029_template+g029_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g029_template]
 mov edx,g029_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g030:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g030_template+g030_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g030_template+g030_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g030_template]
 mov edx,g030_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g035:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g035_template+g035_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g035_template+g035_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g035_template]
 mov edx,g035_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g046:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g046_template+g046_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g046_template+g046_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g046_template]
 mov edx,g046_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.slash_core:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel slash_core_template+slash_core_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel slash_core_template+slash_core_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel slash_core_template]
 mov edx,slash_core_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g060:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g060_template+g060_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g060_template+g060_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g060_template]
 mov edx,g060_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g061:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g061_template+g061_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g061_template+g061_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g061_template]
 mov edx,g061_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g063:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g063_template+g063_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g063_template+g063_digest_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g063_template]
 mov edx,g063_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g062:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g062_template+g062_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g062_template+g062_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g062_template]
 mov edx,g062_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g059:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g059_template+g059_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g059_template+g059_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g059_template]
 mov edx,g059_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g012:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g012_template+g012_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g012_template+g012_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g012_template]
 mov edx,g012_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.g013:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 shr rax,32
 lea rdi,[rel g013_template+g013_mode_offset]
 call format_hex32
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov eax,eax
 lea rdi,[rel g013_template+g013_seed_offset]
 call format_hex32
 mov rdi,r12
 lea rsi,[rel g013_template]
 mov edx,g013_template_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.ordinary:
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_OUTPUT_VALUE_OFFSET]
 lea rdi,[rel value]
 call format_hex
 mov rdi,r12
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel value]
 mov edx,value_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_ARRAY_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_ARRAY_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_ARRAY_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.writer: mov qword [r12+NEBOC_ARRAY_CODEGEN_ERROR_OFFSET],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.source: mov qword [r12+NEBOC_ARRAY_CODEGEN_ERROR_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
