# MIPS Assembly Program for Matrix Exponentiation to Compute Fibonacci Numbers
# This program computes the nth Fibonacci number using matrix exponentiation.
# It includes functions mat_mul and mat_fast_power_recursive.

.data
prompt_str: .asciiz "input n: "
fib_str1:   .asciiz "fib["
fib_str2:   .asciiz "] = "
newline_str: .asciiz "\n"
finish_str: .asciiz "-- program is finished running --\n" 

trans:      .word 1, 1, 1, 0    # 2x2 matrix stored in row-major order
result:     .space 16           # Space for 2x2 result matrix (4 words)
n:          .word 0             # Variable to store 'n'

.text
.globl main
main:
    # Prompt for input 'n'
    li $v0, 4              # syscall code for print string
    la $a0, prompt_str
    syscall

    # Read 'n' from user
    li $v0, 5              # syscall code for read integer
    syscall
    sw $v0, n              # Store 'n' in memory

    # Set up arguments for mat_fast_power_recursive
    la $a0, trans          # $a0 = address of 'trans' matrix
    lw $a1, n              # $a1 = 'n'
    la $a2, result         # $a2 = address of 'result' matrix

    # Call mat_fast_power_recursive(trans, n, result)
    jal mat_fast_power_recursive

    # After return, prepare to print the result
    lw $t0, n              # $t0 = n
    lw $t1, 4($a2)         # $t1 = result[0][1]

    # Print "fib["
    li $v0, 4
    la $a0, fib_str1
    syscall

    # Print 'n' as unsigned integer
    li $v0, 1              # syscall code for print integer
    move $a0, $t0
    syscall

    # Print "] = "
    li $v0, 4
    la $a0, fib_str2
    syscall

    # Print result[0][1] as unsigned integer
    li $v0, 36             # syscall code for print unsigned integer
    move $a0, $t1
    syscall
    
    # Print newline
    li $v0, 4
    la $a0, newline_str
    syscall
    
    # Exit program
    li $v0, 10
    syscall

# Function: mat_fast_power_recursive
# void mat_fast_power_recursive(unsigned base[2][2], unsigned exp, unsigned res[2][2])
mat_fast_power_recursive:
    # Function Prologue
    addi $sp, $sp, -72         # Allocate stack frame
    sw $ra, 68($sp)            # Save return address
    sw $s0, 64($sp)            # Save callee-saved registers
    sw $s1, 60($sp)
    sw $s2, 56($sp)
    sw $s3, 52($sp)
    sw $s4, 48($sp)
    sw $s5, 44($sp)
    sw $a0, 40($sp)            # Save $a0 (base)
    sw $a1, 36($sp)            # Save $a1 (exp)
    sw $a2, 32($sp)            # Save $a2 (res)

    move $s0, $a1              # Save 'exp' in $s0
    move $s1, $a0              # Save 'base' in $s1
    move $s2, $a2              # Save 'res' in $s2

    # Check if exp == 0
    beq $s0, $zero, exp_zero

    # Check if exp == 1
    li $t0, 1
    beq $s0, $t0, exp_one

    # Recursive case
    # Compute exp / 2
    srl $t0, $s0, 1            # $t0 = exp / 2

    # Prepare arguments for recursive call
    move $a0, $s1              # $a0 = base
    move $a1, $t0              # $a1 = exp / 2
    addiu $a2, $sp, 0          # $a2 = address of temp[2][2] on stack

    # Recursive call: mat_fast_power_recursive(base, exp/2, temp)
    jal mat_fast_power_recursive

    # After return, compute res = temp * temp
    addiu $a0, $sp, 0          # $a0 = temp
    addiu $a1, $sp, 0          # $a1 = temp
    move $a2, $s2              # $a2 = res

    jal mat_mul

    # Check if exp % 2 == 1
    andi $t0, $s0, 1           # $t0 = exp % 2
    beq $t0, $zero, mat_fast_power_recursive_exit  # If exp even, skip next part

    # exp is odd, compute res = res * base
    # Copy res to temp2[2][2]
    addiu $t1, $sp, 16         # $t1 = address of temp2[2][2]
    lw $t2, 0($s2)
    sw $t2, 0($t1)
    lw $t2, 4($s2)
    sw $t2, 4($t1)
    lw $t2, 8($s2)
    sw $t2, 8($t1)
    lw $t2, 12($s2)
    sw $t2, 12($t1)

    # Call mat_mul(temp2, base, res)
    move $a0, $t1              # $a0 = temp2
    move $a1, $s1              # $a1 = base
    move $a2, $s2              # $a2 = res
    jal mat_mul

    # Function Epilogue and Return
mat_fast_power_recursive_exit:
    lw $ra, 68($sp)            # Restore saved registers and return address
    lw $s0, 64($sp)
    lw $s1, 60($sp)
    lw $s2, 56($sp)
    lw $s3, 52($sp)
    lw $s4, 48($sp)
    lw $s5, 44($sp)
    lw $a0, 40($sp)            # Restore $a0
    lw $a1, 36($sp)            # Restore $a1
    lw $a2, 32($sp)            # Restore $a2
    addi $sp, $sp, 72          # Deallocate stack frame
    jr $ra                     # Return

# Handle exp == 0
exp_zero:
    li $t0, 1
    sw $t0, 0($s2)             # res[0][0] = 1
    sw $zero, 4($s2)           # res[0][1] = 0
    sw $zero, 8($s2)           # res[1][0] = 0
    sw $t0, 12($s2)            # res[1][1] = 1
    j mat_fast_power_recursive_exit

# Handle exp == 1
exp_one:
    lw $t0, 0($s1)             # base[0][0]
    sw $t0, 0($s2)             # res[0][0] = base[0][0]
    lw $t0, 4($s1)             # base[0][1]
    sw $t0, 4($s2)             # res[0][1] = base[0][1]
    lw $t0, 8($s1)             # base[1][0]
    sw $t0, 8($s2)             # res[1][0] = base[1][0]
    lw $t0, 12($s1)            # base[1][1]
    sw $t0, 12($s2)            # res[1][1] = base[1][1]
    j mat_fast_power_recursive_exit

# Function: mat_mul
# void mat_mul(unsigned a[2][2], unsigned b[2][2], unsigned res[2][2])
mat_mul:
    # Compute res[0][0]
    lw $t0, 0($a0)             # a[0][0]
    lw $t1, 0($a1)             # b[0][0]
    multu $t0, $t1
    mflo $t2                   # t2 = a[0][0] * b[0][0] (lower 32 bits)

    lw $t0, 4($a0)             # a[0][1]
    lw $t1, 8($a1)             # b[1][0]
    multu $t0, $t1
    mflo $t3                   # t3 = a[0][1] * b[1][0] (lower 32 bits)

    addu $t4, $t2, $t3         # res[0][0] = t2 + t3 (modulo 2^32)
    sw $t4, 0($a2)             # Store res[0][0]

    # Compute res[0][1]
    lw $t0, 0($a0)             # a[0][0]
    lw $t1, 4($a1)             # b[0][1]
    multu $t0, $t1
    mflo $t2                   # t2 = a[0][0] * b[0][1]

    lw $t0, 4($a0)             # a[0][1]
    lw $t1, 12($a1)            # b[1][1]
    multu $t0, $t1
    mflo $t3                   # t3 = a[0][1] * b[1][1]

    addu $t4, $t2, $t3         # res[0][1] = t2 + t3
    sw $t4, 4($a2)             # Store res[0][1]

    # Compute res[1][0]
    lw $t0, 8($a0)             # a[1][0]
    lw $t1, 0($a1)             # b[0][0]
    multu $t0, $t1
    mflo $t2                   # t2 = a[1][0] * b[0][0]

    lw $t0, 12($a0)            # a[1][1]
    lw $t1, 8($a1)             # b[1][0]
    multu $t0, $t1
    mflo $t3                   # t3 = a[1][1] * b[1][0]

    addu $t4, $t2, $t3         # res[1][0] = t2 + t3
    sw $t4, 8($a2)             # Store res[1][0]

    # Compute res[1][1]
    lw $t0, 8($a0)             # a[1][0]
    lw $t1, 4($a1)             # b[0][1]
    multu $t0, $t1
    mflo $t2                   # t2 = a[1][0] * b[0][1]

    lw $t0, 12($a0)            # a[1][1]
    lw $t1, 12($a1)            # b[1][1]
    multu $t0, $t1
    mflo $t3                   # t3 = a[1][1] * b[1][1]

    addu $t4, $t2, $t3         # res[1][1] = t2 + t3
    sw $t4, 12($a2)            # Store res[1][1]

    jr $ra                     # Return from function
