; ----------------------
;   macros and functions:
;   strlen:   return the length of a string
;   push_registers: saves values of all general purpose registers
;   pop_registers: restores values of all general purpose registers
;
;----------------------
; %include "filesio.s"

%define ASM_UTILS_H

section .data
ATOI_DIGIT_MULTIPLIER: equ 10

section .text
global stack_registers
global pop_registers

%macro push_registers 0
    ; saves values of all general purpose registers
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
%endmacro

%macro pop_registers 0
    ; restores values of all general purpose registers
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro

strlen:
    ; returns the length of a zero terminated string on rax, excpets a pointer to a string[0] on rdi
    xor rax, rax ; length = 0
    .strlen_loop:
        mov bl, byte [rdi+rax] ; read next byte
        inc rax ; i++
        cmp bl, 0
        jne .strlen_loop
    dec rax ; exclude the zero terminator
    ret

strfind:
    ; expects a pointer to a string on rdi,
    ; a char to find on rsi,
    ; returns the position of the char on rax.
    ; if 0 is found first, returns the length of the string and r8 is set to -1
    ;
    ; modifies rax, rbx

    xor rax, rax ; position = 0
    xor rbx, rbx ; 
    .strfind_loop:
        mov bl, byte [rdi+rax] ; read next byte
        inc rax ; i++
        
        ; check if zero terminator is found
        cmp bl, 0 ; if zero terminator is found
        je .not_found

        cmp bl, sil ; current byte == char to find
        je .found

        jmp .strfind_loop


    .not_found:
    xor r8, r8 ; r8 = -1
    dec r8 ; r8 = -1
    dec rax ; position = length of string
    ret

    .found:
    xor r8, r8 ; r8 = 0
    inc r8 ; r8 = 1
    dec rax ; the current character is compared after rax is incremented so if found that means the previous character was rsi
    ret

atoi:
    ; reads n characters from [rdi] to [rdi+rsi] returns its numeric value on rax
    ; *string to parse = rdi
    ; string length = rsi
    ; result = rax
    ; current char = rbx
    ; digit_position_value = rdx
    xor rax, rax ; result = 0
    xor rbx, rbx ; current char = 0
    xor rdx, rdx ; digit_position_value = 0
    
    ; seting the magnitude of the result on rdx
    mov rdx, 1
    mov rbx, rsi ; use rbx as a counter to find the magnitude of the digit 
    sub rbx, 1
    jz .atoi_loop ; just 1 digit to parse

    .set_digit_position_value:
        ; swap rdx and rax to use mul 
        .set_digit_position_value_loop:
            imul rdx, 10 ; rax = rax * 10
            dec rbx 

        jnz .set_digit_position_value_loop
    
    .atoi_loop:
        mov bl, byte [rdi] ; read char
        sub rbx, '0' ; convert from char to int
        imul rbx, rdx ; rbx = rbx * 10^(rsi - i) this means ord(bl) * 10^(rsi - i)
        add rax, rbx ; result = result + rbx
        xor rbx, rbx ; current char = 0
        inc rdi ; next char, rdi++

        ; devide rdx by 10, to get the next digit position value
        push rax ; will store the new rdx value
        mov rbx, ATOI_DIGIT_MULTIPLIER
        mov rax, rdx
        xor rdx, rdx ; div uses rdx:rax as dividend, so we need to clean rdx before div operation
        div rbx ; sets result in rax
        mov rdx, rax
        pop rax

        dec rsi ; next digit to parse
        jnz .atoi_loop
    
    ret



