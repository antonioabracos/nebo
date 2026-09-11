bits 64
default rel
%include "runtime/image/image_io.inc"
%include "runtime/canvas/canvas_image.inc"
%define SYS_read 0
%define SYS_write 1
%define SYS_close 3
%define SYS_pipe2 293
section .data
bmp_fixture:
 db 0x42,0x4d,0x46,0,0,0,0,0,0,0,0x36,0,0,0
 dd 40,2,2
 dw 1,32
 dd 0,16,0,0,0,0
 db 0xff,0,0,0x40, 0xff,0xff,0xff,0xff
 db 0,0,0xff,0xff, 0,0xff,0,0x80
section .bss
align 16
fds resd 2
cap resb NEBO_FILE_CAPABILITY_SIZE
file resb NEBO_FILE_SIZE
request resb 64
scratch resb 70
desc resb 64
pixels resb 16
outbytes resb 70
outlen resq 1
canvas resb NEBO_CANVAS_SIZE
canvaspixels resb 64
section .text
global _start
make_pipe:
 lea rdi,[rel fds]
 xor esi,esi
 mov eax,SYS_pipe2
 syscall
 ret
init_cap_file:
 ; edi=fd esi=permission
 mov r8d,edi
 mov r9d,esi
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 mov [rel cap+NEBO_FILE_CAPABILITY_MAGIC],rax
 mov [rel cap+NEBO_FILE_CAPABILITY_PERMISSIONS],r9
 mov qword [rel cap+NEBO_FILE_CAPABILITY_MAX_IO_BYTES],1048576
 mov [rel file+NEBO_FILE_FD],r8
 mov qword [rel file+NEBO_FILE_STATE],NEBO_FILE_STATE_OPEN
 lea rax,[rel cap]
 mov [rel file+NEBO_FILE_CAPABILITY],rax
 mov qword [rel file+NEBO_FILE_BYTES_READ],0
 mov qword [rel file+NEBO_FILE_BYTES_WRITTEN],0
 ret
_start:
 call make_pipe
 test eax,eax
 js .fail1
 mov edi,[rel fds+4]
 lea rsi,[rel bmp_fixture]
 mov edx,70
 mov eax,SYS_write
 syscall
 cmp eax,70
 jne .fail2
 mov edi,[rel fds+4]
 mov eax,SYS_close
 syscall
 mov edi,[rel fds]
 mov esi,NEBO_FILE_CAP_READ
 call init_cap_file
 lea rax,[rel file]
 mov [rel request],rax
 mov qword [rel request+8],70
 lea rax,[rel scratch]
 mov [rel request+16],rax
 mov qword [rel request+24],70
 lea rax,[rel desc]
 mov [rel request+32],rax
 lea rax,[rel pixels]
 mov [rel request+40],rax
 mov qword [rel request+48],16
 mov qword [rel request+56],0
 lea rdi,[rel request]
 call nebo_image_load
 test eax,eax
 jnz .fail3
 cmp dword [rel pixels],0xff0000ff
 jne .fail4
 cmp dword [rel pixels+4],0x8000ff00
 jne .fail5
 mov edi,[rel fds]
 mov eax,SYS_close
 syscall
 ; Canvas descriptor compatible with controlo_de_fluxo_estruturado-F06.
 lea rax,[rel canvaspixels]
 mov [rel canvas+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],rax
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET],64
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],4
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],4
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],16
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET],NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
 mov qword [rel canvas+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],1
 mov dword [rel canvas+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
 mov dword [rel canvas+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_INITIALIZED
 mov rax,NEBO_CANVAS_MAGIC
 mov [rel canvas+NEBO_CANVAS_MAGIC_OFFSET],rax
 lea rdi,[rel canvas]
 lea rsi,[rel desc]
 mov edx,1
 mov ecx,1
 call nebo_canvas_image
 test eax,eax
 jnz .fail6
 cmp dword [rel canvaspixels+20],0xffff0000
 jne .fail7
 cmp dword [rel canvaspixels+24],0x80008000
 jne .fail8
 cmp dword [rel canvaspixels+36],0x40000040
 jne .fail9
 cmp dword [rel canvaspixels+40],0xffffffff
 jne .fail10
 test dword [rel canvas+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_DIRTY
 jz .fail11
 lea rdi,[rel canvas]
 lea rsi,[rel desc]
 mov edx,3
 mov ecx,3
 call nebo_canvas_image
 cmp eax,NEBO_CANVAS_ERROR_DIMENSION_MISMATCH
 jne .fail12
 ; Save through an explicit write-capable File and compare its pipe bytes.
 call make_pipe
 test eax,eax
 js .fail13
 mov edi,[rel fds+4]
 mov esi,NEBO_FILE_CAP_WRITE
 call init_cap_file
 lea rax,[rel file]
 mov [rel request],rax
 lea rax,[rel desc]
 mov [rel request+8],rax
 lea rax,[rel scratch]
 mov [rel request+16],rax
 mov qword [rel request+24],70
 lea rax,[rel outlen]
 mov [rel request+32],rax
 mov qword [rel request+40],0
 mov qword [rel request+48],0
 mov qword [rel request+56],0
 lea rdi,[rel request]
 call nebo_image_save
 test eax,eax
 jnz .fail14
 cmp qword [rel outlen],70
 jne .fail15
 mov edi,[rel fds+4]
 mov eax,SYS_close
 syscall
 mov edi,[rel fds]
 lea rsi,[rel outbytes]
 mov edx,70
 mov eax,SYS_read
 syscall
 cmp eax,70
 jne .fail16
 lea rsi,[rel bmp_fixture]
 lea rdi,[rel outbytes]
 mov ecx,70
.compare:
 mov al,[rsi]
 cmp al,[rdi]
 jne .fail17
 inc rsi
 inc rdi
 dec ecx
 jnz .compare
 mov edi,[rel fds]
 mov eax,SYS_close
 syscall
 ; Closed Image is refused before Canvas mutation.
 or word [rel desc+30],NEBO_IMAGE_FLAG_CLOSED
 lea rdi,[rel canvas]
 lea rsi,[rel desc]
 xor edx,edx
 xor ecx,ecx
 call nebo_canvas_image
 cmp eax,NEBO_CANVAS_ERROR_BAD_STATE
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
