.section .data
str:    .asciz "Hello, World!"   # The string to be reversed

.section .text
.globl _start
_start:
    # Calculate the length of the string
    li a0, 0    # Initialize a0 to 0
    la a1, str  # Load the address of the string into a1
    not a0      # Negate a0
    cld
    repne scasb
    not a0      # Negate a0
    addi a0, a0, -1  # Decrement a0 by 1 to get the length

    # Allocate space on the stack for the reversed string
    addi sp, sp, -12  # Reserve 12 bytes on the stack for the reversed string

    # Reverse the string
    la a1, str  # Load the address of the string into a1
    add a2, a1, a0  # Calculate the end address of the string
    addi a0, zero, 0  # Initialize a0 to 0
    addi a3, zero, 1  # Initialize a3 to 1 (increment value)
    addi a4, zero, 0  # Initialize a4 to 0 (direction: forward)
reverse_loop:
    lbu t0, 0(a2)  # Load a byte from the end of the string
    sb t0, 0(a1)  # Store the byte at the current position
    addi a1, a1, 1  # Increment the source address
    addi a2, a2, -1  # Decrement the destination address
    addi a0, a0, 1  # Increment the loop counter
    blt a0, a0, reverse_loop  # Repeat the loop until the counter reaches the length

    # Terminate the reversed string with a null character
    sb zero, 0(a1)

    # Exit the program
    li a7, 10
    ecall
