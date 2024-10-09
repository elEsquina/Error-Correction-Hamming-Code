.data 
    matricule: .word 1825641
    r: .word 7
    Q0: .asciiz "Matricule: "
    Q1: .asciiz "Message to be sent: "
    Q2: .asciiz "Mapped message: "
    Q3: .asciiz "Sent message: "
    Q4: .asciiz "Received message: "
    Q5: .asciiz "Corrected message: "
    Q6: .asciiz "Unmapped message: "

.text

main:
    lw s0, matricule
    lw s1, r

    li a0, 4
    la a1, Q0
    ecall
    mv a1, s0
    li a0 , 1
    ecall
    li a0, 11
    li a1, '\n'
    ecall

    mv a0, s0
    mv a1, s1
    jal get_message

    li a0, 4
    la a1, Q1
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall

    mv a0, a7
    jal hamming_map

    li a0, 4
    la a1, Q2
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall

    mv a0, a7
    jal hamming_encode

    li a0, 4
    la a1, Q3
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall

    xori a7, a7, 0x00000001  # Simulating an error thru a noisy channel
    li a0, 4
    la a1, Q4
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall   

    mv a0, a7
    jal hamming_decode

    li a0, 4
    la a1, Q5
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall   

    mv a0, a7
    jal hamming_unmap

    li a0, 4
    la a1, Q6
    ecall
    mv a1, a7
    li a0 , 34
    ecall
    li a0, 11
    li a1, '\n'
    ecall       

    li a0, 10
    ecall

parity: 
    # n = a0 and return value in a7
    li a7, 0
    loop_parity:
        beqz a0, end_loop_parity
            addi a7, a7, 1
            addi t0, a0, -1
            and a0, a0, t0
        j loop_parity

    end_loop_parity:
    andi a7, a7, 1 
    jr ra


get_message:
    #matricule = a0, r = a1 and return value in a7
    xori t0, a0, 0xFFFFFFFF

    sll t1, t0, a1  # (msg << r)
    li t3, 32 
    sub t2, t3, a1  # 32 - r
    srl t2, t0, t2 # (msg >> (32 - r))
    or t0, t1, t2  # msg = (msg << r) | (msg >> (32 - r))

    li t3, 0x00FFFFFF 
    and a7, t0, t3
    jr ra


hamming_map:
    #a0 = data and return value in a7
    li t0, 0 #current position in the data
    li a7, 0  

    #a7 = hamming 
    #t0 = bit_position
    #a0 = msg 

    li t1 , 0
    loop_map: 
        
        #Parity bits checking:
        beqz t1, map_skip_parity # check if t1 == 0
        addi t2, t1, -1
        and t2, t1, t2
        beqz t2, map_skip_parity # check if (t1 & (t1 - 1)) == 0
        
        li t2, 1
        sll t2, t2, t0
        and t2, a0, t2 # t2 = msg & (1 << bit_position)
        beq t2, x0, map_zero
            li t2, 1  
            slli t2, t2, 31
            or a7, a7, t2 # hamming = hamming | (1 << (bit_position))
        map_zero: 
        addi t0, t0, 1  # bit_position++

        j map_skip_parity_end
        map_skip_parity: 
            li t2, 0x7FFFFFFF 
            and a7, a7, t2 # Forcing parity bits to 0
        map_skip_parity_end:

        srli a7, a7, 1 # Shift hamming to the right so we can process the next bit 
        
    addi t1, t1, 1 
    li t2, 32
    bne t1, t2, loop_map

    jr ra


hamming_encode:
    #a0 = map and return value in a7
    mv t6, a0 # return
    mv t5, a0 # map
    mv t0, x0 # Parity bit
    
    addi sp, sp, -4
    sw ra, 0(sp)

    li t3, 0x55555554 
    and a0, t5, t3 # map & 0x55555554
    jal parity # parity(map & 0x55555554)
    or t6, t6, a7

    li t3, 0x66666664
    and a0, t5, t3 # map & 0x66666664
    jal parity # parity(map & 0x66666664)
    slli a7, a7, 1
    or t6, t6, a7

    li t3, 0x78787870
    and a0, t5, t3 # map & 0x78787870
    jal parity # parity(map & 0x78787870)
    slli a7, a7, 3
    or t6, t6, a7

    li t3, 0x7F807F00
    and a0, t5, t3 # map & 0x7F807F00

    jal parity # parity(map & 0x7F807F00)
    slli a7, a7, 7
    or t6, t6, a7

    li t3, 0x7FFF0000
    and a0, t5, t3 # map & 0x7FFF0000
    jal parity # parity(map & 0x7FFF0000)
    slli a7, a7, 15
    or t6, t6, a7

    lw ra, 0(sp)
    addi sp, sp, 4

    mv a7, t6
    jr ra


hamming_decode:
    #a0 = code and return value in a7
    mv t6, a0 
    li t5, 0 # Error code

    li t0, 0x55555555  
    li t1, 0x66666666
    li t2, 0x78787878
    li t3, 0x7F807F80
    li t4, 0x7FFF8000 

    and t0, t6, t0 # code & 0x55555555
    and t1, t6, t1 # code & 0x66666666
    and t2, t6, t2 # code & 0x78787878
    and t3, t6, t3 # code & 0x7F807F80
    and t4, t6, t4 # code & 0x7FFF8000

    addi sp, sp, -4
    sw ra, 0(sp)

    mv a0, t0
    jal parity
    slli a7, a7, 0
    or t5, t5, a7

    mv a0, t1
    jal parity
    slli a7, a7, 1
    or t5, t5, a7

    mv a0, t2
    jal parity
    slli a7, a7, 2
    or t5, t5, a7

    mv a0, t3
    jal parity
    slli a7, a7, 3
    or t5, t5, a7

    mv a0, t4
    jal parity
    slli a7, a7, 4

    or t5, t5, a7

    lw ra, 0(sp)
    addi sp, sp, 4

    beqz t5, no_error  # if C != 0, there is an error
        li t1, 1 
        addi t0, t5, -1 # t0 = C - 1
        sll t1, t1, t0  # 1 << (C - 1)
        xor t6, t6, t1  # code = code ^ (1 << (C - 1))
    no_error:


    mv a7, t6
    jr ra


hamming_unmap:
    # a0 = map and return value in a7
    li t0, 0 # bit position
    li a7, 0 # matricule
    # a0 = hamming 

    li t1, 0 # index
    loop_unmap: 

        # Parity bits checking:
        addi t2, t1, 1
        and t2, t1, t2
        beqz t2, unmap_skip_parity # check if (t1 & (t1 - 1)) == 0

        li t2, 1
        sll t3, t2, t1 # t3 = hamming & (1 << i)
        and t3, a0, t3 
        beqz t3, unmap_zero
            li t3, 1  
            sll t3, t3, t0 # (1 << bit_position)
            or a7, a7, t3 # matricule = matricule | (1 << bit_position)
        unmap_zero: 
        addi t0, t0, 1  # bit_position++

        unmap_skip_parity: 

        addi t1, t1, 1 
        li t2, 32
        bne t1, t2, loop_unmap

    jr ra

