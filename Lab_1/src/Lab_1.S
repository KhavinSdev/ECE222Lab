

.section .text      # Begin code (text) section — stores executable instructions
.globl _start       # Make the '_start' label globally visible to the linker as entry point
.align  2           # Align the next instruction to a 4-byte boundary (2^2 = 4) for efficiency

_start:

# Define base address and offsets for GPIO control registers (memory-mapped I/O)
# Refer to the lab manual or SiFive FE310-G002 Manual v1p5 on Learn for more info about the addresses
.equ GPIO_BASE_CTRL_ADDR,   0x10012000    # Base address for the GPIO control registers
.equ GPIO_OUTPUT_EN,        0x08          # address offset for enabling GPIO outputs
.equ GPIO_OUTPUT_VAL,       0x0c          # Address offset for writing to GPIO outputs

# Determine the correct bitmask values (in hex) for: LED Bar Pins, Seven Segment LED Display Pins
# All LED Pins, and LEDBAR LED1. Example is given here for GPIO_7SEGLED_PINS
.equ GPIO_7SEGLED_PINS, 0x0000023F      # Seven Segment LED Display Pins (7)
.equ GPIO_LEDBAR_PINS,  0x00fc0c00      # LED Bar Pins (8)
.equ GPIO_ALL_LED_PINS, 0x00fc3e3f      # All LED Pins (15)
.equ GPIO_LEDBAR_LED_1, 0x00000800      # LEDBAR LED1 (Bit 11)


# Initialize the GPIO control registers (configure all LEDs as output)
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
sw t2, GPIO_OUTPUT_VAL(t1)



# Turn On (toggle) LED1
# -----------------------------write the instructions here-----------------------------

 

# Create a delay of ~500 ms, toggle LED1, then delay another ~500 ms and toggle again.
# Repeat this process indefinitely.
# To start, implement the design using two separate counters (see Flowchart 1 in the lab manual),
# then optimize it to use a single counter as shown in Flowchart 2,and demo this.

li t4, GPIO_LEDBAR_LED_1 # initialized to write value to turn on LED write register
li t0, GPIO_LEDBAR_LED_1 # saving the same value as a mask 

loop:      
                                    # Start of delay loop used as a simple timer (~0.5 sec)                                                           
    li t3, 0x001E8480               # Load the correct values that corresponds to 500 msec (8 MHz) to t3 respectively i.e. 4 million in decimal
                                    
    loop1:                          # Here you have to write the conditons, for example: 
        
            
        
        addi t3, t3, -1                                              # and increment or decrement till t3 = 0x00000000

        
# -----------------------------write the instructions here-----------------------------

        bnez t3, loop1                            # If t3 = 0x00000000  continue, else go back to loop1

        # stores write value to toggle LED1
        add t2, x0, t4
        # writes to toggle only LED1
        sw t2, GPIO_OUTPUT_VAL(t1)
        
        # changes toggle state register
        xor t4, t2, t0                                       

        # go back to parent loop
        beqz t3, loop
            

    /*
  Task 2- Hand-assembly of ADDI instruction using the tables in Appendix A:
    addi t4, t3, 0x100

    Answer: 0000_0010_0000_11100_000_11101_0010011
    */


/*     
# Create a delay of ~500 ms, toggle LED1, then delay another ~500 ms and toggle again.
# Repeat this process indefinitely.
# To start, implement the design using two separate counters (see Flowchart 1 in the lab manual),
# then optimize it to use a single counter as shown in Flowchart 2,and demo this.

loop:      
                                    # Start of delay loop used as a simple timer (~0.5 sec)                                                           
    li t3, 0x001E8480               # Load the correct values that corresponds to 500 msec (4 MHz) to t4 and t3 respectively i.e. 2 million in decimal
    li t4, 0x001E8480               # 4 million clock cycles = 0.5 sec, cycles consumed/loop = ~2, therefore cycles required between LEDON and LEDOFF = 2 million
    loop1:                          # Here you have to write the conditons, for example: 
        
            
        
        addi t4, t4, -1                                              # and increment or decrement till t4 = 0x00000000

        
# -----------------------------write the instructions here-----------------------------

        bnez t4, loop1                            # If t4 = 0x00000000  continue, else go back to loop1
    
        # stores write value to turn on LED1
        li t2, GPIO_LEDBAR_LED_1
        # writes to turn on only LED1
        sw t2, GPIO_OUTPUT_VAL(t1)
        
                                               

        loop2:
            # similar to above, decrement t3 counter by 1
            addi t3, t3, -1


            bnez t3, loop2      # If t3 = 0x00000000  continue, else go back to loop2

            # stores write value to turn off LED1
            li t2, 0
            # writes to turn off only LED1
            sw t2, GPIO_OUTPUT_VAL(t1)

            # Jump back to parent loop if conditon(s) met
            beqz t3, loop       

*/


