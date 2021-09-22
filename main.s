; ----------------------
;    [Code description for main]
;----------------------

DEFAULT rel ; 

; INCLUDES GO BELOW:
%include "asm_utils.s"
%include "futils.s"
%include "filesio.s"
%include "generic_data.data.s"
%include "generic_lib.s"


section .data
; Constants section
error_reading_digit: db "Digit size exceeds the int buffer size", 10, 0
error_vectors_length: db "Vectors are not of the same length", 10, 0
INT_BUFFER_SIZE: equ 20
VECTOR_LENGTH_MSG: db "Vector has a length of ", 0
VECTOR_A_BEEN_LOADED: db "Loading Vector A",10,0
VECTOR_B_BEEN_LOADED: db "Loading Vector B",10,0
COMA_MSG: db ", ", 0

section .bss
; Variables section
vector_a: resd 100
vector_b: resd 100
vector_a_str: resb 35
vector_b_str: resb 35
a_length: resb 1
b_length: resb 1

; used to store a digit of a vector
int_buffer: resb 20

section .text
; Code section

%macro load_vector 4
    ; Loads a vector from a file
    ; Parameters:
    ;   1 - vector filename
    ;   2 - *buffer to store the vector string
    ;   3 - where to store vector length
    ;   4 - *buffer to store the parsed vector 

    ; read vector file
    read_file %1, %2 ; filename, *buffer
    mov rdi, %2

    ; get string length of vector         
    call strlen
    mov [%3], al


    ; call _parse_vector 
    mov rdi, %2 ; *vector string
    mov rsi, %4 ; *vector parsed
    mov rdx, %3 ; vector length
    call _parse_vector

    print_str VECTOR_LENGTH_MSG
    xor rax, rax
    movzx rax, BYTE [%3]
    print_int rax

    print_str newline
%endmacro

global _start
_start:
    ; LOADING VECTORS
    ; ----------------

    print_str VECTOR_A_BEEN_LOADED
    load_vector vector_a_file, vector_a_str, a_length, vector_a
    print_str newline

    print_str VECTOR_B_BEEN_LOADED
    load_vector vector_b_file, vector_b_str, b_length, vector_b
    
    ; both vectors must have the same length
    movzx rax, BYTE [a_length]
    movzx rbx, BYTE [b_length]

    cmp rax, rbx
    je .operations_start ; if they are equal, go to operations else print error and exit
    print_str error_vectors_length
    jmp .end_error


    .operations_start:



    .end_ok:
    exit 0

    .end_error:
    exit 1
; }

_parse_vector:
    ; 
    ; excpects vecotr in string format (e.g. "1:2:3:4:5") on rdi 
    ; the buffer to store the vector in on rsi
    ; the length of the vector on rdx
    ; returns nothing
    ; ---------------- Register usage:
    ; next_number_delimiter = rax
    ; *current_char_index = rbx
    ; length of the vector = rdx
    ; length of current number = rcx
    ; *buffer to store the vector in = rsi  
    ; *string to parse = rdi
    ; r15 = numbers parsed
    ; ------------------
    xor rbx, rbx ; rbx = 0 ; current_char_index
    xor rax, rax ; rax = 0 ; next_number_delimiter
    xor r15, r15 ; r15 = 0 ; numbers parsed

    mov rbx, rdi ; rbx = rdi ; 
    push rdx ; save rdx, the length of the vector
    .parse_loop:
        ; get : position
        ; save rsi, rbx, rax
        push rdi
        push rsi
        
        mov rsi, ':'
        mov rdi, rbx ; rdi points to the current char
        push rbx 
        call strfind ; modifies rax and rbx; rax = position of :

        mov rsi, rax ; rsi = vector_a_str[current_char_index:]

        push rax ; save position of :, from here rax will be the value of the number before rdi-rsi
        call atoi
        mov r14, rax ; temporary store the number until we get the reference to  buffer back
        pop rax ; restore position of :

        pop rbx ; restore *current_char_index
        pop rsi ; restore the poiner to the buffer
        pop rdi ; restore the position of *vector_a_str
        
        mov [rsi+r15*4], r14d ; store the number in the buffer
        inc r15 ; increment the number of numbers parsed
        
        add rbx, rax ; rbx = position of :
        inc rbx ; rbx = position of next number
        print_int r14

        cmp r8, -1 ; this means : was not found so the vector is over
        je .done_parsing

        print_str COMA_MSG

        jmp .parse_loop



    .done_parsing:
    pop rdx ; restore rdx
    xor rbx, rbx ; intermidiate holder for r15 (number of numbers parsed) because for some reason
    ; r15l is not 'defined' and r15b is void. TODO: i should ask salomon about this.
    mov rbx, r15
    mov [rdx], bl ; i forgot i was using rdx for this purpose -_- jajaja, i'm a genius
    print_str newline
    ret



    

; }




