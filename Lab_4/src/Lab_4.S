
.section .text
.align 2
.globl _start

# --------------------------------------------------------------------------------------------------------------
# Constants and Register Definitions
# --------------------------------------------------------------------------------------------------------------


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

    # Define GPIO Pin Mapping for Pushbuttons (S1, S2, and both)
    # -----------------------------write the instructions here-----------------------------
    .equ GPIO_PB1, 0x1000
    .equ GPIO_PB2, 0x2000
    .equ GPIO_ALL_PB, 0x3000

    # Define PLIC mappings

    .equ PLIC_BASE, 0x0C000000
    .equ PLIC_THRESHOLD_BASE, 0x0C200000
    .equ PLIC_INTERUPT_ENABLE_BASE1, 0x0C002000
    .equ PLIC_CLAIM_COMPLETE, 0x0C200004


# Use saved register s5 for storing GPIO base address:

li s5, GPIO_BASE_CTRL_ADDR

# Set up mtvec with the address of the interrupt vector (S1_interrupt)
      la t0, S1_interrupt                 # Load the address of the interrupt handler 'S1_interrupt' into t0
                                          # S1_interrupt represents the Interrupt Service Routine (ISR) found at the bottom of the code
      csrw mtvec, t0                      # csrw: CSR write,  writes the value in register t0 (which is the 
                                          # address of the interrupt handler) to the mtvec register.                        
                                          # Set the mtvec register to th e address in t0 (S1_interrupt)
# Enable "External" machine interrupts in the mie register
      li t0, (1 << 11)                    # Set bit 11 to "1" and write it to t0
                                          # This bit (bit 11) corresponds to the external interrupt enable
      csrs mie, t0                        # csrs: CSR Set, it performs a bitwise OR between the current 
                                          # value of mie and the value in t0
                                          # Set bit 11 in the mie register (enable external interrupts)
# mtvec: Machine Trap Vector register, it stores the address of the interrupt handler
# directing the processor to jump to this address, S1_interrupt, when an interrupt occurs.

# Enable global machine interrupts (MIE, bit 3 of mstatus)
      csrr t0, mstatus                    # read the value of the mstatus into t0
      li t1, (1 << 3)                     # Set MIE (Machine Interrupt Enable)
                                          # (1<<3): this instruction puts "1" at the 3rd bit 
      or t0, t0, t1                       # add t0 "mstatus" to t1, where we actually are setting bit 3 to "1"
                                          # This sets the 3rd bit (MIE) in t0 without modifying other bits
      csrw mstatus, t0                    # Write the modified value in t0 back to the mstatus register



# store PLIC base address in saved register
      li s1, PLIC_BASE

# store PLIC Threshold base address in saved register
      li s2, PLIC_THRESHOLD_BASE





# ------------------------------Configure SW1 as an input------------------------------
# -----------------------------write the instructions here-----------------------------

      # stores output write value for PB1
      li t2, GPIO_PB1

      # writing to output enabling value for PB1 to memory address starting from byte 0
      sw t2, GPIO_INPUT_EN(s5)


# -----------------------Configure GPIO LEDs pins as an output-------------------------
# -----------------------------write the instructions here-----------------------------

      # stores output write value for All LEDs
      li t2, GPIO_ALL_LED_PINS

      # writing to output enabling value for All LEDs to memory address starting from byte 0
      sw t2, GPIO_OUTPUT_EN(s5)


# ----------------------------Turn Off all LEDs in LED Bar-----------------------------
# -----------------------------write the instructions here-----------------------------
      
      # stores output value that would turn off all LEDs in LED BAR (just turns off all LEDs since we don't need 7 segment ones)
      li t2, 0

      # writes to output val memory location to turn off LEDs in LED BAR
      sw t2, GPIO_OUTPUT_VAL(s5)


# ------------Enable Falling edge for S1: Remember S1 is a GPIO and not PLIC-----------
# -----------------------------write the instructions here-----------------------------

# Configure GPIO bit to have interrupt trigger edge to be on falling edge

      # sets the pb1 bit to be 1 for writing to set as falling edge 
      li t2, (1 << 12)

      # enables pb1 as a falling edge interrupt
      sw t2, 0x20(s5)

# ----------------------------Enable PLIC for S1 interrupt-----------------------------
# -----------------------------write the instructions here-----------------------------

      li t3, PLIC_INTERUPT_ENABLE_BASE1
      li t2, 0x100000

      # enables PLIC for enabling PB1 GPIO as a source
      sw t2, 0x0(t3)
               

# ----------------Set PLIC priority for S1 interrupt to 7 "Highest Priority"-----------
# -----------The address is calculated according to: PLIC_BASE + 4 × S1_PLIC_ID--------
# -----------------------------write the instructions here-----------------------------

# sets priority level of PB1 GPIO to 7
      li t2, 7
      sw t2, 80(s1)    

# -------------------------------Set PLIC threshold to 6-------------------------------
# -----------------------------write the instructions here-----------------------------

# sets priority threshold of PLIC to 6:

      li t2, 6
      sw t2, 0(s2)

# Initialize pseudo-random generator and countdown timer
InitRandomNum:
    # Sets a7 to a 16-bit non-zero value; only the PRNG subroutine should modify a7
    li a7, 0xABCD


main_program:                             
# -------------------Flashing the LEDS at a rate of 10 Hz (0.1 seconds)----------------
# -----------------------------write the instructions here----------------------------- 
      main_loop:
            jal RandomNum

            # turns on all LEDs
            li t2, GPIO_LEDBAR_PINS
            sw t2, GPIO_OUTPUT_VAL(s5)

            jal Delay_10Hz

            # turns off all LEDs
            li t2, 0
            sw t2, GPIO_OUTPUT_VAL(s5)

            jal Delay_10Hz

            j main_loop




# Interrupt Service Routine (ISR) for S1 interrupt

.balign 64
S1_interrupt:
# ----------------------------- Save Registers to Stack -----------------------------
      addi sp, sp, -12
      sw ra, 0(sp)
      sw a7, 4(sp) // original non-scaled randomly generated value
      sw s2, 8(sp) // PLIC Threshold base address (we are using s2 in our ISR)




# -------------------------- Acknowledge Interrupt in PLIC --------------------------

// get PLIC Interrupt ID from Claim register
li a6, PLIC_CLAIM_COMPLETE
lw a5, 0(a6)


# ----------------------------- Scale a7 and save it in a4 ---------------------------
      Scale:
            li t1, 201
            remu a4, a7, t1 # scaling to value between 0 and 200
            addi a4, a4, 50 # shift value to make it between 50 and 250
            # li a4, 0x55
            li t1, 1

            display_time: blt a4, t1, Exit_display_time
                sw x0, GPIO_OUTPUT_VAL(s5) #  pressed => LED OFF

                li s2,  0xFF # mask to get least signifcant 8 bits
                and t2, a4, s2 # get least significant 8 bits of counter value


                li s3, 0x3 # mask for LED bits 10-11
                li s4, 0xFC # mask for LED bits 18-23

                and s3, t2, s3 # get last two bits of least significant 8 bits of counter
                slli s3, s3, 10 # shift last two bits to map to LED bits 10-11

                and s4, t2, s4 # get first 6 bits of least significant 8 bits of counter
                slli s4, s4, 16 # shift first 6 bits to map to LED bits 18-23

                or t2, s3, s4 # combine both shifted LED bits

                sw t2, GPIO_OUTPUT_VAL(s5) // writes to turn on the 8 LEDs
                jal ra, delay_hold_count # hold delay for 2 sec

                addi a4, a4, -10 // reduce counter value by 10
                j display_time // repeat counter display loop
            
            Exit_display_time:

      

# -------------------------- Complete the Interrupt in the PLIC --------------------------
# ------------------------ Clear the falling interrupt pending in the GPIO ---------------

      # sets the pb1 bit to be 0 for writing to set as falling edge 
      li t2, (1 << 12)

      # clears pb1 as a falling edge interrupt (DOUBLE CHECK EARLIER)
      sw t2, 0x24(s5)

      sw a5, 0(a6) # write interrupt ID back to PLIC Claim/Complete register

      li a4, 0 # reset ol' timer

# ----------------------------- Restore Registers & Return --------------------------

      lw ra, 0(sp)
      lw a7, 4(sp)
      lw s2, 8(sp)
      addi sp, sp, 12
      mret                                  # Return from interrupt


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


Delay_10Hz:

# desired frequency in hertz
    li t4, 0xC3500 # 10 Hz frequency
      
      delay_loop:
        addi t4, t4, -1
        bgtz t4, delay_loop
    ret

delay_hold_count:
    li t4, 0x895440 // 1 second delay between each byte processed  

    delay_hold_count_loop:
        addi t4, t4, -1
        bgtz t4, delay_hold_count_loop

      ret