; PATTERN-MATCHING-E-DESTRUCTURING-F02 bounded RGBA8/GRAY8 color operations
bits 64
default rel
%define NEBO_COLOR_IMPLEMENTATION 1
%include "runtime/media/color.inc"
section .rodata
align 32
srgb_to_linear_q16:
    dw 0,20,40,60,80,99,119,139,159,179,199,219,241,264,288,313
    dw 340,367,396,427,458,491,526,562,599,637,677,718,761,805,851,898
    dw 947,997,1048,1101,1156,1212,1270,1330,1391,1453,1517,1583,1651,1720,1790,1863
    dw 1937,2013,2090,2170,2250,2333,2418,2504,2592,2681,2773,2866,2961,3058,3157,3258
    dw 3360,3464,3570,3678,3788,3900,4014,4129,4247,4366,4488,4611,4736,4864,4993,5124
    dw 5257,5392,5530,5669,5810,5953,6099,6246,6395,6547,6700,6856,7014,7174,7335,7500
    dw 7666,7834,8004,8177,8352,8528,8708,8889,9072,9258,9445,9635,9828,10022,10219,10417
    dw 10619,10822,11028,11235,11446,11658,11873,12090,12309,12530,12754,12980,13209,13440,13673,13909
    dw 14146,14387,14629,14874,15122,15371,15623,15878,16135,16394,16656,16920,17187,17456,17727,18001
    dw 18277,18556,18837,19121,19407,19696,19987,20281,20577,20876,21177,21481,21787,22096,22407,22721
    dw 23038,23357,23678,24002,24329,24658,24990,25325,25662,26001,26344,26688,27036,27386,27739,28094
    dw 28452,28813,29176,29542,29911,30282,30656,31033,31412,31794,32179,32567,32957,33350,33745,34143
    dw 34544,34948,35355,35764,36176,36591,37008,37429,37852,38278,38706,39138,39572,40009,40449,40891
    dw 41337,41785,42236,42690,43147,43606,44069,44534,45002,45473,45947,46423,46903,47385,47871,48359
    dw 48850,49344,49841,50341,50844,51349,51858,52369,52884,53401,53921,54445,54971,55500,56032,56567
    dw 57105,57646,58190,58737,59287,59840,60396,60955,61517,62082,62650,63221,63795,64372,64952,65535
section .text
global nebo_color_rgb_media_native_vertical
global nebo_color_rgba_media_native_vertical
global nebo_color_to_linear_u8
global nebo_color_to_srgb_q16
global nebo_pixel_format_rgba8
global nebo_pixel_format_gray8
global nebo_pixel_pack
nebo_color_rgb_media_native_vertical:
    mov ecx,255
    jmp color_pack_checked
nebo_color_rgba_media_native_vertical:
color_pack_checked:
    cmp rdi,255
    ja .argument
    cmp rsi,255
    ja .argument
    cmp rdx,255
    ja .argument
    cmp rcx,255
    ja .argument
    mov eax,ecx
    shl eax,8
    or eax,edx
    shl eax,8
    or eax,esi
    shl eax,8
    or eax,edi
    mov edx,eax
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    xor edx,edx
    ret
nebo_color_to_linear_u8:
    cmp edi,255
    ja .range
    lea r11,[rel srgb_to_linear_q16]
    movzx edx,word [r11+rdi*2]
    xor eax,eax
    ret
.range:
    mov eax,NEBO_MEDIA_E_RANGE
    xor edx,edx
    ret
nebo_color_to_srgb_q16:
    cmp edi,65535
    ja .range
    lea r11,[rel srgb_to_linear_q16]
    xor r8d,r8d
    mov r9d,255
.search:
    cmp r8d,r9d
    jae .found
    lea eax,[r8+r9]
    shr eax,1
    movzx ecx,word [r11+rax*2]
    cmp ecx,edi
    jae .move_high
    lea r8d,[rax+1]
    jmp .search
.move_high:
    mov r9d,eax
    jmp .search
.found:
    mov edx,r8d
    test r8d,r8d
    jz .ok
    movzx ecx,word [r11+r8*2]
    mov eax,r8d
    dec eax
    movzx r10d,word [r11+rax*2]
    sub ecx,edi
    sub edi,r10d
    cmp edi,ecx
    jbe .choose_previous
.ok:
    xor eax,eax
    ret
.choose_previous:
    dec edx
    xor eax,eax
    ret
.range:
    mov eax,NEBO_MEDIA_E_RANGE
    xor edx,edx
    ret
nebo_pixel_format_rgba8:
    mov rax,NEBO_PIXEL_FORMAT_RGBA8_VALUE
    ret
nebo_pixel_format_gray8:
    mov rax,NEBO_PIXEL_FORMAT_GRAY8_VALUE
    ret
nebo_pixel_pack:
    cmp esi,NEBO_PIXEL_RGBA8
    je .rgba
    cmp esi,NEBO_PIXEL_GRAY8
    jne .format
    movzx eax,dil
    imul eax,eax,13933
    mov edx,edi
    shr edx,8
    movzx edx,dl
    imul edx,edx,46871
    add eax,edx
    mov edx,edi
    shr edx,16
    movzx edx,dl
    imul edx,edx,4732
    add eax,edx
    add eax,32768
    shr eax,16
    mov edx,eax
    xor eax,eax
    ret
.rgba:
    mov edx,edi
    xor eax,eax
    ret
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    xor edx,edx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
