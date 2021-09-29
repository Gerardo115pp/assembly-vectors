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

    ; Error messages
    error_reading_digit: db "Digit size exceeds the int buffer size", 10, 0
    error_vectors_length: db "Vectors are not of the same length", 10, 0

    ; Messages for the user
    VECTOR_LENGTH_MSG: db "Vector has a length of ", 0
    VECTOR_A_BEEN_LOADED: db "Loading Vector A",10,0
    VECTOR_B_BEEN_LOADED: db "Loading Vector B",10,0
    COMA_MSG: db ", ", 0
    DOT_PRO_MSG: db "dot product: ", 0
    ADDITION_MSG: db "Addition: ", 0

    ; Reverse vectors excerise
    VECTOR_A_REVERSE_MSG: db "Reversing Vector A",10,0 
    VECTOR_B_REVERSE_MSG: db "Reversing Vector B",10,0
    A_PREFIX_REVERSE_VECTOR: db "A[", 0
    B_PREFIX_REVERSE_VECTOR: db "B[", 0
    A_SUFFIX_REVERSE_VECTOR: db "]", 0
    OUTPUT_FILE: db "output.txt", 0
; end of data section

section .bss
    ; Variables section
    vector_a: resd 100
    vector_b: resd 100
    vector_a_str: resb 35
    vector_b_str: resb 35
    a_length: resb 1
    b_length: resb 1

    added_vector: resd 100

    ; used to store a digit of a vector
    int_buffer: resb 20
; end of bss section

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

        ;dot product
        call dot_product ; result in rax
        print_str DOT_PRO_MSG
        print_int rax
        print_str newline

        ;addition
        call vector_addition ; result in added_vector, it will also print the necesary messages to stdout

        ; print reversed vector A
        print_str newline
        print_str newline
        print_str VECTOR_A_REVERSE_MSG
        
        ; call reverse_vector for vector A
        mov rdi, vector_a
        mov rsi, a_length
        lea rdx, A_PREFIX_REVERSE_VECTOR
        call reverse_vector

        ; print reversed vector B
        print_str newline
        print_str VECTOR_B_REVERSE_MSG
        
        ; call reverse_vector for vector A
        mov rdi, vector_b
        mov rsi, b_length
        lea rdx, B_PREFIX_REVERSE_VECTOR
        call reverse_vector


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

dot_product:
    ; this program will use local variables because is not meant to be reused
    ; rdi = dot product result
    ; rsi = vector a, length of a and b should be the same so its not important which one 
    ; r8 =  counter
    ; just for convension we will return the result in rax
    xor rdi, rdi ; rdi = 0
    xor rax, rax ; rax = 0
    xor r8, r8 ; r8 = 0
    xor rsi , rsi ; rsi = 0

    movzx rsi, byte [a_length] ; rsi = length of vectors

    .dot_product_loop:

        mov rax, [vector_a+r8*4] ; rax = vector_a[counter]
        mul dword [vector_b+r8*4] ; rax = vector_a[counter] * vector_b[counter]
        add rdi, rax ; rdi = rdi + rax
        inc r8 ; r8++ 

        dec rsi ; rsi--
        jnz .dot_product_loop
    
    mov rax, rdi ; return the result in rax
    ret
; }

vector_addition:
    ; also will use local variables
    ; rbx = nth addition result
    ; rcx = vector length control variable, when its 0 we are done
    ; r8 = counter
    xor rbx, rbx ; rbx = 0
    xor r8, r8 ; r8 = 0


    print_str ADDITION_MSG
    movzx rcx, byte [a_length] ; rcx = length of vectors
    .addition_loop:
        xor rax, rax ; rax = 0
        xor rdx, rdx ; rdx = 0
        mov ebx, dword [vector_a+r8*4] ; rbx = vector_a[counter]
        mov eax, dword [vector_b+r8*4] ; rax = vector_b[counter]
        add rbx, rax ; rbx = rbx + rax

        print_int rbx

        mov [added_vector+r8*4], ebx ; store the 32 lower bits of rbx in the added vector
        inc r8 ; r8++
        
        dec rcx ; rcx--
        jz .addition_done

        print_str COMA_MSG
        jmp .addition_loop
        
    .addition_done:
    ret
; }

reverse_vector:
    ; Reverses a vector
    ; Parameters:
    ;   rdi - *vector to reverse
    ;   rsi - *length of the vector
    ;   rdx - *prefix string
    ; Register usage:
    ;   rcx - counter, stop when rcx == 0
    ;   rax - vector element
    ;   r11 - vector element, [32]byte
    ;   r12 - output file content, [100]byte
    
    ; Local variables:
    push rbp ; save rbp
    mov rbp, rsp ; rbp = rsp
    sub rsp, 0x20 ; allocate 32 bytes for number storage
    mov r11, rsp ; r11 = vector element[32]byte
    sub rsp, 0x64 ; allocate 100 bytes for number storage
    mov r12, rsp ; r12 = output file content[100]byte

    xor rcx, rcx
    xor rax, rax

    movzx rcx, byte [rsi] ; length of vector
    dec rcx ; rcx = length of vector - 1
    .loop_reverse_vector:
        ; clear strings
            push rdi
            push rsi
            push rax

            mov rdi, r11 ; *vector_element = r11
            mov rsi, 32 ; length of array
            call strclear

            pop rax
            pop rsi
            pop rdi
        ; end clear strings

        ; copy prefix string on the vector element
            push rdi
            push rsi
            push rax
            push rbx
            mov rdi, rdx ; rdi = prefix string
            mov rsi, r11 ; rsi = vector_element
            call strcopy
            mov r8, rax ; r8 = length of prefix string
            pop rbx
            pop rax
            pop rsi
            pop rdi
        ; end copy prefix string

        ; copy number on the vector element
            push rdi
            push rsi
            push rax
            push rbx
            push rdx
            push rcx
            
            xor rax, rax ; rax = 0
            mov eax, dword [rdi + rcx*4]
            mov rdi, rax ; rdi = number
            mov rsi, r11 ; rdi = vector_element
            add rsi, r8 ; rdi = vector_element + length of prefix string
            call parseInt

            mov rsi, r11 ; rsi = vector_element
            mov rdi, r12
            call strcat ; add the vector element to the output file

            mov rsi, A_SUFFIX_REVERSE_VECTOR 
            call strcat ; add the suffix to the output file

            pop rcx
            pop rdx
            pop rbx
            pop rax
            pop rsi
            pop rdi

        ; end copy number

        dec rcx

        cmp rcx, -1
        jle .done_reverse_vector
        
        push rsi
        push rdi
        push rax
        push rbx
        push rcx

        mov rdi, r12
        mov rsi, COMA_MSG
        call strcat ; add the coma to the output file

        pop rcx
        pop rbx
        pop rax
        pop rdi
        pop rsi

        jmp .loop_reverse_vector

    .done_reverse_vector:
    print_str r12
    print_str newline

    push rdi
    push rsi
    mov rdi, r12
    call strlen
    
    mov rdi, OUTPUT_FILE
    mov rsi, r12
    mov rdx, rax

    push rax
    ; adding a newline at the end of output file
    mov byte [r12+rdx], 10
    inc rdx

    call write_file

    pop rax
    mov rdi, r12
    mov rsi, rax ; rsi = length of output file
    call strclear ; clear the output file

    pop rsi
    pop rdi
    mov rsp, rbp ; restore rsp
    pop rbp ; restore rbp
    ret
; }



    



