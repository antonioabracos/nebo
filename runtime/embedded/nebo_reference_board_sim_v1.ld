OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_nebo_board_reset)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00100000, LENGTH = 256K
  RAM (rw)  : ORIGIN = 0x00200000, LENGTH = 256K
}

SECTIONS
{
  .vectors ORIGIN(ROM) : ALIGN(16)
  {
    KEEP(*(.vectors))
  } > ROM

  .text ALIGN(16) :
  {
    KEEP(*(.text.startup))
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > ROM

  .data ORIGIN(RAM) : ALIGN(16)
  {
    __data_start = .;
    *(.data .data.*)
    __data_end = .;
  } > RAM AT > ROM
  __data_load = LOADADDR(.data);

  .bss (NOLOAD) : ALIGN(16)
  {
    __bss_start = .;
    *(.bss .bss.* COMMON)
    __bss_end = .;
  } > RAM

  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
  ASSERT((__stack_top & 15) == 0, "initial stack must be 16-byte aligned")
  ASSERT(SIZEOF(.vectors) == 128, "reference vector table must contain 16 entries")
}
