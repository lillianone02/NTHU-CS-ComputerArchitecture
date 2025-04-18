.data
    prompt_base:      .asciiz "base: "                  # Prompt the user to enter the base
    prompt_exponent:  .asciiz "exponent: "              # Prompt the user to enter the exponent
    result_msg:       .asciiz "result: "                      # Message to display the result
    negative_exp_msg: .asciiz "Error: Exponent cannot be negative.\n"  # Error message for negative exponents
    exit_msg:         .asciiz "Both base and exponent are zero. Exiting.\n"  # Message to display on exit
    newline:          .asciiz "\n"                            # Newline character

.text
    .globl main

main:
    # Initialize registers
    # In this section, you need to initialize some registers for use later. You can use the `addi` instruction for initialization.
    # Specifically, prepare a register to check for the parity of numbers (whether they are odd or even).
    # TODO: Initialize a register to store the value 1, used for checking parity (odd/even).
    addi $t0, $zero, 1 # $t0 = 1 used fo check parity (odd/even)

loop_start:
    # This section is used to prompt the user for the base and exponent and read them.
    # 1. Display the prompt for entering the base
    # 2. Use a system call to read the user's input for the base and store it in a register
    # 3. Display the prompt for entering the exponent
    # 4. Use a system call to read the user's input for the exponent and store it in a register
    # Hint: You need to use MIPS system call 4 to display a string and system call 5 to read an integer.
    # TODO: Display the prompt for base and read the base
    li $v0, 4
    la $a0, prompt_base
    syscall
    li $v0, 5
    syscall
    move $s0, $v0 # $s0 = base
    # TODO: Display the prompt for exponent and read the exponent
    li $v0, 4
    la $a0, prompt_exponent
    syscall
    li $v0, 5
    syscall
    move $s1, $v0 #s1 = exponent
    # Check if both base and exponent are zero
    # Here, you need to check if both the base and exponent are zero. If they are, the program should exit.
    # If the base is zero, then check if the exponent is also zero. If both are zero, display the exit message and terminate the program;
    # otherwise, continue execution.
    # TODO: Check if base is zero, if so check if exponent is zero
    beq $s0, $zero, check_exponent_zero
    j check_negative_exponent
check_exponent_zero:
    # In this section, check if the exponent is zero. If it is, the program should exit.
    # If not, continue to check if the exponent is negative.
    # TODO: Check if exponent is zero, if so exit the program
    bne $s1, $zero, check_negative_exponent
    j exit_program
check_negative_exponent:
    # Check if the exponent is negative
    # Here, you need to check if the entered exponent is negative. If it is, display an error message and return to prompt the user for new inputs.
    # If the exponent is not negative, continue to the calculation.
    # Hint: You can use the `slti` instruction to compare the exponent with zero.
    # TODO: Check if exponent is negative, if so display error message and loop back
    slt $t1, $s1, $zero
    beq $t1, $zero, proceed_calculation
    # Display error message for negative exponent
    li $v0, 4
    la $a0, negative_exp_msg
    syscall
    j loop_start
proceed_calculation:
    # Calculate base raised to the power of exponent
    # 1. Initialize some variables for the calculation. For example, initialize `result` to 1, which will hold the final result.
    # 2. Implement the fast exponentiation algorithm, which is an efficient way to perform the power calculation.
    #    This involves looping based on the value of `current_exponent`.
    # 3. Check if the exponent is odd, and if so, multiply the current base with the result.
    # 4. Each iteration squares the base and halves the exponent until the exponent reaches zero.
    # Hint: You can use `mul` for multiplication and `srl` for bitwise right shift.
    # TODO: Initialize result, current_base, and current_exponent for the loop
    # Initialize result
    addi $s2, $zero, 1 # $2 = result = 1
    # Current base
    add $s3, $s0, $zero # $s3 = current_base = base
    # Current exponent
    add $s4, $s1, $zero # $s4 = current_exponent = exponent
exp_loop:
    # In this section, you need to perform repeated exponentiation until the exponent becomes zero.
    # In each iteration of the loop, check the value of the exponent and decide whether to multiply based on its parity (odd/even).
    # Hint: Use `srl` to right shift the exponent, which is equivalent to dividing it by 2.
    # Hint: In binary, any odd number has its least significant bit (LSB) as 1, while an even number has its LSB as 0.
    # For example, 5 in binary is '101' (odd), and 4 in binary is '100' (even).
    # You can use bitwise operations to check the parity of the exponent.
    
    # TODO: Check if current_exponent > 0, if so continue, otherwise end loop
    beq $s4, $zero, exp_end
    # TODO: Check if current_exponent is odd, if so multiply result by current_base
    and $t1, $s4, $t0
    beq $t1, $zero, skip_multiplication
    mul $s2, $s2, $s3 # Mutiply result by current base
    
skip_multiplication:
    # TODO: Square current_base
    mul $s3, $s3, $s3
    # TODO: Halve current_exponent (right shift)
    srl $s4, $s4, 1
    # TODO: Repeat the loop
    j exp_loop

exp_end:
    # Display the result
    # This section is used to display the final result and prompt for the next input.
    # TODO: Display the result
    # 1. Display the message indicating the result
    li $v0, 4
    la $a0, result_msg
    syscall
    # 2. Display the actual result of the calculation
    li $v0, 36
    move $a0, $s2
    syscall
    # 3. Display a newline character
    li $v0, 4
    la $a0, newline
    syscall
    # Hint: Use MIPS system call 36 to display an unsigned integer result and system call 4 to display a string.
    # Return to loop start, continue accepting inputs
    # TODO: Loop back to start
    j loop_start

exit_program:
    # If both the base and exponent are zero, the program should exit.
    # Display an exit message and terminate the program.
    # Hint: Use MIPS system call 10 to terminate the program.
    # TODO: Display exit message
    li $v0, 4
    la $a0, exit_msg
    syscall
    # TODO: Terminate program
    li $v0, 10
    syscall
