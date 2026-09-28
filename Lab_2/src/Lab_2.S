

# ---------------------------- DATA SECTION -------------------------
.section .rodata          # Read-only data section for constants / lookup tables
.align 2                  # Align to 4-byte boundary (2^2 = 4)

# Input string (Message) to be sent / converted to Morse code
InputLUT:
    .asciz "EA"        # Null-terminated string

# Morse Code Look-Up Table
# Each character is mapped to a 16-bit pattern for the Morse LED display
.align 2
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75       # A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55        # E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175      # I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD       # M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7        # Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757      # U, V, W, X
    .half 0x1D77, 0x775                  # Y, Z


# ---------------------------- CODE SECTION -------------------------
.section .text                               # Begin code section
.globl _start                                # Entry point
.align  2                                    # Align to 4-byte boundary

_start:
    # GPIO Control Registers Memory Mapping
    # Refer to lab manual or SiFive FE310-G002 Manual v1p5
    .equ GPIO_BASE_CTRL_ADDR,   0x10012000      # Base address for GPIO control registers
    .equ GPIO_OUTPUT_EN,        0x08          # address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,       0x0c          # Address offset for writing to GPIO outputs

    # Determine the correct bitmask values (in hex) for: LED Bar Pins, Seven Segment LED Display Pins
    # All LED Pins, and LEDBAR LED1. Example is given here for GPIO_7SEGLED_PINS
    .equ GPIO_7SEGLED_PINS, 0x0000023F      # Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00fc0c00      # LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00fc3e3f      # All LED Pins (15)
    .equ GPIO_LEDBAR_LED_7, 0x00800000          # LEDBAR LED7 (Bit 24)

    # Initialize GPIO outputs
    # -----------------------------write the instructions here-----------------------------
    # stores output enabling register memory address
    li t1, GPIO_BASE_CTRL_ADDR

    # stores output write value for All LEDs
    li t2, GPIO_ALL_LED_PINS

    # writing to output enabling value for All LEDs to memory address starting from byte 0
    sw t2, GPIO_OUTPUT_EN(t1)


    # Turn Off all LEDs
    # -----------------------------write the instructions here-----------------------------

    # stores write value to turn off all LEDs
    li t2, 0

    # writes to turn off all LEDs
    sw t2, GPIO_OUTPUT_VAL(t1) # stores output enabling register memory address
    li t1, GPIO_BASE_CTRL_ADDR

    # stores output write value for All LEDs
    li t2, GPIO_ALL_LED_PINS

    # writing to output enabling value for All LEDs to memory address starting from byte 0
    sw t2, GPIO_OUTPUT_EN(t1)

    

# ---------------------------- MAIN LOOP -----------------------------
# Initialize pointer and start processing each character of the input string
InputPointer:
    
    la s1, InputLUT                             # Load address of input string into s1

# Process each character in the input string
NextChar:

    # stores write value to turn off all LEDs
    li t2, 0

    # writes to turn off all LEDs
    sw t2, GPIO_OUTPUT_VAL(t1) # stores output enabling register memory address
    li t1, GPIO_BASE_CTRL_ADDR

    lbu a0, 0(s1)                               # Load next character into a0 (unsigned)
    addi s1, s1, 1                              # Increment pointer to next character
    snez a1, a0                                 # Set a1 = 1 if a0 != 0 (not null)
    bnez a1, CHAR2MORSE                         # If character valid, convert to Morse
    jal ra, Delay_bwWords                               # If null terminator reached, wait 3.5 sec
    j InputPointer                              # Restart from first character




# ---------------------------- SUBROUTINES ---------------------------
# Converts an ASCII uppercase letter (A-Z) into its Morse pattern and Flash the LED according to the pattern
CHAR2MORSE:
    # --------------Optional: You may separate the logic into two subroutines:-------------
    # ------------------1. CHAR2MORSE: Lookup Morse pattern from ASCII---------------------
    # ------------------2. PROCESSCHAR: Flash the LED according to the pattern-------------
    # -----------------------------write the instructions here-----------------------------

    la s2, MorseLUT

    Loop: 
      
        addi t0, a0, -65 # calculating index for MorseLUT = -0x41

        slli t0, t0, 1 # multiplying index by 2 for correct offset for 2 byte MorseLUT entry

        add t0, t0, s2 # storing memory address for letter from MorseLUT

        lhu t0, 0(t0) # load morse hex value from MorseLUT

        beqz t0, call_Delay_bwLetters_subroutine // goes to instruction to call Delay_bwLetters sub routine

        call_Delay_bwLetters_subroutine:
            jal ra, Delay_bwLetters

        li t2, 0x80000000 # bit mask for getting most significant bit
        remove_leading_zeroes_loop:
            and t3, t2, t0 # gets most significant bit
            bnez t3, LEDLoop
            slli t0, t0, 1
            j remove_leading_zeroes_loop


        LEDLoop:
      
            and t3, t2, t0 # use t3 to store the most significant bit of current letter code(t0)

            beqz t3, call_LED_OFF # if LSB is 0, go to call for LED_OFF sub routine
            jal ra, LED_ON # else, turn on LED
            j exit_if # exits conditional branching and continues loop code

            call_LED_OFF:
                jal ra, LED_OFF # calls LED_OFF sub routine
            
        
            exit_if:
                slli t0, t0, 1 # shifts loaded letter's binary value to the left by 1

                bnez t0, LEDLoop # loops if letter not terminated yet

                j NextChar # loads next character in string

    


    # Input: a0 = ASCII character. Store Output in a1 = Morse code pattern
    # Index into MorseLUT must be by steps of 2 bytes 
    # Example layout in MorseLUT:
    # 0000 0000 | 0000 0000 | 0000 0000 | 0000 0000 
    #       B (2 Bytes)     |        A (2 bytes)

# ---------------------------- LED CONTROL ---------------------------
# Turn On LED7
LED_ON:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------

    // store previous return address to stack to return to LEDLoop
    addi sp, sp, -4
    sw ra, 0(sp)

    // write to address to turn on LED
    li t4, GPIO_BASE_CTRL_ADDR

    li t5, GPIO_LEDBAR_LED_7
    sw t5, GPIO_OUTPUT_VAL(t4)

    // add delay between bits of a letter
    jal ra, Delay_bwBits 

    // restore return address from stack
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


# Turn LED7 off
LED_OFF:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------
   
    // store previous return address to stack to return to LEDLoop
    addi sp, sp, -4
    sw ra, 0(sp)

    // write to address to turn off led
    li t4, GPIO_BASE_CTRL_ADDR

    li t5, 0
    sw t5, GPIO_OUTPUT_VAL(t4)

    // add delay between bits of a letter
    jal ra, Delay_bwBits 

    // restore return address from stack
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


# ---------------------------- DELAY ROUTINES -----------------------
# You can implement three separate subroutines for 0.5s, 1.5s, and 3.5s delays
# Or use a single 0.5s Delay and call it multiple times as requried
Delay_bwWords:
    # -----------------------------write the instructions here-----------------------------
    # --------------------------------Use the Stack Properly-------------------------------
    # -----------------Refer to the lab manual for more detail about stack-----------------

    li t4, 0xF42400 # storing counter value of 16 million(decimal) corresponds to 2 second worth of cycles
    
    delay_loop_words:
        addi t4, t4, -1
        bnez t4, delay_loop_words
    ret


Delay_bwLetters:
    li t4, 0x5B8D80  # storing counter value of 12 million(decimal) corresponds to 1.5 second worth of cycles
    
    delay_loop_letters:
        addi t4, t4, -1
        bnez t4, delay_loop_letters

    ret

Delay_bwBits:

    li t4, 0x3D0900 # storing counter value of 4 million(decimal) corresponds to 0.5 second worth of cycles  

    delay_loop_bits:
        addi t4, t4, -1
        bnez t4, delay_loop_bits
    ret

End:
    .end


# Lab Report

# character string: "KSSGZ"

# K             1.5s       S            1.5        S         1.5s        G              1.5s        Z                   2s
# 1 1101 0111   000        1 0101       000        1 0101    000        1 1101 1101     000         111 0111 0101       0000