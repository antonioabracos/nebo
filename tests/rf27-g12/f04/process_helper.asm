bits 64
default rel
section .text
global _start
_start:
 mov edi,7
 mov eax,60
 syscall
