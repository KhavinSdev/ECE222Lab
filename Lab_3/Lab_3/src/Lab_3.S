

.section .text
.align 2
.globl _start


_start:
    
    # GPIO Control Registers Memory Mapping
    # Refer to lab manual or SiFive FE310-G002 Manual v1p5
    # Define the GPIO control register base address and offsets
    # (Output enable, output value, input enable, input value, etc.)
    # -----------------------------write the instructions here-----------------------------

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000

    .equ GPIO_INPUT_VAL, 0x00 # read inputs here
    .equ GPIO_INPUT_EN, 0x04 # offset for enabling input
    
    .equ GPIO_OUTPUT_VAL, 0x0C # write outputs here
    .equ GPIO_OUTPUT_EN, 0x08 # offset for enabling output


    # Define GPIO Pin Mapping for LEDs (8 LEDs in LED bar, LED6)
    # Optional: you may also configure the 7-segment display pins
    # -----------------------------write the instructions here-----------------------------
    .equ GPIO_7SEGLED_PINS, 0x0000023F      # Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00fc0c00      # LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00fc0e3f      # All LED Pins (15)
    .equ GPIO_LEDBAR_LED_7, 0x00800000      # LEDBAR LED7 (Bit 24)

    .equ GPIO_LED_1, 0x800 # LED 1 bit mask
    .equ GPIO_LED_6, 0x400000 # LED 6 bit mask




    # Configure the GPIO Outputs for all LEDs
    # -----------------------------write the instructions here-----------------------------
         li s0, GPIO_BASE_CTRL_ADDR

        # stores output write value for All LEDs
         li t2, GPIO_ALL_LED_PINS

        # writing to output enabling value for All LEDs to memory address starting from byte 0
         sw t2, GPIO_OUTPUT_EN(s0)


    # Define GPIO Pin Mapping for Pushbuttons (S1, S2, and both)
    # -----------------------------write the instructions here-----------------------------
    .equ GPIO_PB1, 0x1000
    .equ GPIO_PB2, 0x2000
    .equ GPIO_ALL_PB, 0x3000

    # Configure the GPIO Inputs for the pushbuttons used (S1, S2, or both)
    # -----------------------------write the instructions here-----------------------------

        # stores output write value for all PBs
        li t2, GPIO_ALL_PB

        # writing to output enabling value for All PBs to memory address starting from byte 0
        sw t2, GPIO_INPUT_EN(s0)


    # Turn off all LEDs
    # -----------------------------write the instructions here-----------------------------
        li t2, 0x0 # stores write value to turn off all LEDs

        sw t2, GPIO_OUTPUT_VAL(s0) # writes to output address to turn off all LEDs

# ----------------------Initialize the pseudo-random number generator-----------------------
InitRandomNum:
    # Sets a7 to a 16-bit non-zero value; only the PRNG subroutine should modify a7
    li a7, 0xABCD


    


# -------------------Task 1: LED Binary Counter and GPIO Verification----------------------
Task_1:
    # -----------------------------write the instructions here-----------------------------

    
    li t2, 0x00 # counter
    li t3, 0xFF # max counter value
    
    li t0, 0 # stores bit 0-1 of counter
    li t1, 0 # stores bit 2-7 of counter
    Loop: beq t2, t3, ResetCounter
        li t4, 0x3 # mask for LED bits 10-11
        li t5, 0xFC # mask for LED bits 18-23
        and t0, t2, t4
        slli t0, t0, 10

        and t1, t2, t5
        slli t1, t1, 16

        or t1, t1, t0

        sw t1, GPIO_OUTPUT_VAL(s0)

        addi sp, sp, -4
        sw t4, 0(sp)

        jal ra, Delay

        lw t4, 0(sp)
        addi sp, sp, 4

        addi t2, t2, 1

        Task_Toggler:
            li t0, GPIO_PB2

            lw t5, GPIO_INPUT_VAL(s0) # read inputs        

            and t5, t5, t0 # isolate button bit
            beqz t5, Task_2 # 1 => not pressed (active-low)


        j Loop

    ResetCounter:
        li t2, 0x00
        j Loop
    

# ----------------------------------Task 2: Reflex Meter-----------------------------------
Task_2:
    # -----------------------------write the instructions here-----------------------------
    /*li t0, GPIO_PB1
    li t3, GPIO_LEDBAR_LED_7

    loop:
    
        lw t5, GPIO_INPUT_VAL(s0) # read inputs        

        and t5, t5, t0 # isolate button bit
        bnez t5, led_off # 1 => not pressed (active-low)

        sw t3, GPIO_OUTPUT_VAL(s0) # pressed => LED ON
        j loop

    led_off:
        sw x0, GPIO_OUTPUT_VAL(s0) # not pressed => LED OFF
        j loop */


    # turn off all LEDs
    
    li t2, 0x0
    sw t2, GPIO_OUTPUT_VAL(s0)

    jal ra, RandomNum
    add t3, x0, a7 # t3 now contains the random number

    jal ra, Scale // scales delay and calls sub sub routine to delay

    reflex_meter:
        # turn on LED 6
        li t2, GPIO_LED_6
        sw t2, GPIO_OUTPUT_VAL(s0)

        li t0, 0 # counter
        li t3, GPIO_LED_1 # LED mask
        li t1, GPIO_PB1 # BTN mask


        counter_poll_loop:
            jal ra, delay_count
            addi t0, t0, 1 # increment counter by 1 after 0.1 msec delay

            lw t5, GPIO_INPUT_VAL(s0) # read inputs        

            and t5, t5, t1 # isolate button bit
            bnez t5, counter_poll_loop # 1 => not pressed (active-low)

            display_reactiontime: beqz t0, Exit_display_reactiontime
                sw x0, GPIO_OUTPUT_VAL(s0) #  pressed => LED OFF

                li s2,  0xFF # mask to get least signifcant 8 bits
                and t2, t0, s2 # get least significant 8 bits of counter value


                li s3, 0x3 # mask for LED bits 10-11
                li s4, 0xFC # mask for LED bits 18-23

                and s3, t2, s3 # get last two bits of least significant 8 bits of counter
                slli s3, s3, 10 # shift last two bits to map to LED bits 10-11

                and s4, t2, s4 # get first 6 bits of least significant 8 bits of counter
                slli s4, s4, 16 # shift first 6 bits to map to LED bits 18-23

                or t2, s3, s4 # combine both shifted LED bits

                sw t2, GPIO_OUTPUT_VAL(s0) // writes to turn on the 8 LEDs


                srli t0, t0, 8 # right shift counter by 8 bits to get next least significant 8 bits of counter
                jal ra, delay_hold_count # hold delay for 2 sec
                j display_reactiontime # repeat process until all bytes are read (counter is 0)
            
            Exit_display_reactiontime:
                jal ra, delay_display_all # delays 5 seconds after displaying all bytes
                j reflex_meter # restart process






        

    



        



    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------


# ----------------------------------------Scaling-------------------------------------------
# Scaling the randum number generated (a7) between 2 and 10 sec
Scale:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------
    addi sp, sp, -4
    sw ra, 0(sp)

    li t4, 10
    rem t3, t3, t4

    bnez t3, skip
    li t3, 10

    skip:

    li t4, 1
    bne t3, t4, skip1

    li t3, 2

    skip1:
    
    call_delay:

        jal ra, Delay_Random

    lw ra, 0(sp)
    addi sp, sp, 4

    ret


    # ------------------------------------Complete the task--------------------------------
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly if needed---------------------


# -------------------------Pseudo-Random Number Generator------------------------------
# Register a7 will hold the generated random number
# You may read this register anywhere in your program.
# Important: Only this subroutine should write to a7.

    # --------------------------------Use the Stack Properly if needed---------------------
RandomNum:
    addi sp, sp, -16
    sw ra, 12(sp)                  # Save return address

    li s4, 0x8000                  # Select bit 15 of a7
    and t1, a7, s4                 # Extract bit 15

    li s4, 0x2000                  # Select bit 13 of a7
    and t3, a7, s4                 # Extract bit 13

    slli t3, t3, 2                 # Shift extracted bit 13 left by 2
    xor t3, t1, t3                 # Combine with extracted bit 15

    li s4, 0x1000                  # Select bit 12 of a7
    and t1, a7, s4                 # Extract bit 12

    slli t1, t1, 3                 # Shift extracted bit 12 left by 3
    xor t3, t3, t1                 # Combine with previous result

    andi t1, a7, 0x0400            # Select bit 10 of a7
    slli t1, t1, 5                 # Shift bit 10 left by 5
    xor t3, t3, t1                 # Combine with previous result

    srli t3, t3, 15                # Shift result right by 15
    slli a7, a7, 1                 # Shift a7 left by 1
    or a7, a7, t3                  # Update a7 with new pseudo-random value

    lw ra, 12(sp)                  # Restore return address
    addi sp, sp, 16                # Restore stack pointer
    ret                             # Return from subroutine

# ---------------------------- DELAY ROUTINES -----------------------
# Create as much as you need.
Delay:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly if needed---------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------
    li t4, 0xC3500 # storing counter value of 800000(decimal) corresponds to 0.1 second worth of cycles  

    delay_loop_bits:
        addi t4, t4, -1
        bnez t4, delay_loop_bits
    ret

Delay_Random:

    li t4, 0
    li t5, 0

    loop_add16M:

        li t5, 0x5B8D80   # Load 16 million (decimal)
        add t4, t4, t5
        addi t3, t3, -1
        bnez t3, loop_add16M


    delay_random_loop:
        addi t4, t4, -1
        bnez t4, delay_random_loop
    ret

delay_count:

    li t4, 0x320 //  for 2 instruction/loop we get a delay of 0.1 ms 

    delay_count_loop:
        addi t4, t4, -1
        bnez t4, delay_count_loop
    ret

delay_hold_count:
    li t4, 0xB71B00 // 2 second delay between each byte processed  

    delay_hold_count_loop:
        addi t4, t4, -1
        bnez t4, delay_hold_count_loop
    ret

delay_display_all:
    li t4, 0x1C9C380 // delay 5 seconds

    delay_display_all_loop:
        addi t4, t4, -1
        bnez t4, delay_display_all_loop
    ret

End:
    .end


# Lab Report Questions

/*

a.)  Based on the randomly generated number, we calculate the remainder of the number divided by 10 by using the modulus operator to offset it to a value between 0 and 9.
If the remainder is 0, then we set the delay to 10 seconds, and if the remainder is 1, then we set the delay to 2 seconds; otherwise, the remainder will directly correspond
to a delay value (in seconds) between 2 and 9. This will ensure that the difference between the remainder and the delay value has a max of 5% error.

b.)

i. 0.0128 seconds
ii. 3.2768 seconds
iii. 838.8608 seconds
iv. 214748.3648 seconds

c.) 16 bits since human reaction times can be be more than 0.5 seconds but usually less than 5 seconds.


*/