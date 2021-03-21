***********************************************************************
*
* Title:  LED Light Blinking
*
* Objective:  CSE472 Homework 2
*
* Revision:   v1.0
*
* Date:       Feb. 3, 2021
*
* Programmer: Nicholas Hutton, (original: Kyusun Choi)
*
* Company:  The Pennsylvania State University
*           Department of Computer Science and Engineering
*
* Algorithm:  Simple Parallel I/O use and time delay-loop demo
*
* Register use: A:    LED Light on/off state and Switch 1 on/off state
*               X, Y: Delay loop counters
*
* Memory use: RAM locs from $3000 for data,
*             RAM locs from $3100 for prgm.
*
* Input:      Parameters hard-coded in the prgm - PORTB
*             Switch 1 at PORTB bit 0
*             Switch 2 at PORTB bit 1
*             Switch 3 at PORTB bit 2
*             Switch 4 at PORTB bit 3
*
* Output:        LED 1 at PORTB bit 4
*                LED 2 at PORTB bit 5
*                LED 3 at PORTB bit 6
*                LED 4 at PORTB bit 7
*
* Observation:  This is a prgm that blinks LEDs and blinking period can
*               be changed with the delay loop counter value.
*
* Comments:     This prgm is developed and simulated using CodeWarrior IDE
*               and targeted for Axion Manufacturing's CSM-12C128 board 
*               running at 24MHz.
*
***********************************************************************
* Parameter Declaration Section
*
* Export Symbols
        XDEF      pstart ; export "pgstart" symbol
        ABSENTRY  pstart ; for assembly entry point
        
* Symbols and Macros
PORTA   EQU       $0000   ; i/o port A addrs
PORTB   EQU       $0001   ; i/o port B addrs
DDRA    EQU       $0002
DDRB    EQU       $0003
***********************************************************************
* Data Section: addr used [$3000 to $30FF] RAM
*
          ORG       $3000   ;reserved RAM starting addr
                            ; for Data for CMPEN 472 class
Counter1  DC.W      $0100   ;X register count number for time delay
                            ; inner loop for msec
Counter2  DC.W      $00BF   ;Y register count number for time delay                            
                            ; outer loop for sec
                            
                            ;Remaining data memory space for stack,
                            ; up to prgm mem start.                            
*
***********************************************************************
* Program Section:  addr used [$3100 to $3FFF] RAM
*
          ORG       $3100     ;Prgm start addr, in RAM
pstart    lds       #$3100    ;init stack ptr

;            ldaa      #%11110000  ;LED 1,2,3,4 @ PORTB bit 4,5,6,7 FOR CSM-12C128 board
          ldaa      #%11111111  ;LED 1,2,3,4 @ PORTB bit 4,5,6,7 FOR Simulation ONLY
          staa      DDRB        ;set PORTB bit 4,5,6,7 as output
        
          ldaa      #%00000000
          staa      PORTB       ;turn off LED 1,2,3,4 (all bits in PORTB, for simulation)
        
mainLoop     
          ldaa      PORTB
          ANDA      #%00000001        ;read switch 1 @ PORTB bit 0
          BNE       sw1pushed         ;check to see if it is pushed
          
        
sw1notpsh BCLR      PORTB,%11100000   ;turn OFF LED 2,3,4 @ PORTB bit 5,6,7
          BSET      PORTB,%00010000   ;turn ON LED 1 @ PORTB bit 4
          JSR       delay1sec         ;wait for 1sec
          
          BCLR      PORTB,%00010000   ;turn OFF LED 1 @ PORTB bit 4
          BSET      PORTB,%10000000   ;turn ON LED 4 @ PORTB bit 7
          BRA       mainLoop
          
sw1pushed BCLR      PORTB,%11110000   ;turn off all LEDs @ PORTB bits 4,5,6,7
          BSET      PORTB,%00110000   ;turn ON LED 1,2 @ PORTB bits 4,5
          
          JSR       delay1sec         ;wait for 1sec
          BCLR      PORTB,%00110000   ;turn off LEDs 1,2 @ PORTB bits 4,5
          BSET      PORTB,%11000000   ;turn ON LED 3,4 @ PORTB bits 6,7
          BRA       mainLoop                       

***********************************************************************
* Subroutine Section: addr used [$3100 to $3FFF] RAM
*

;***********************************************************
; delay1sec subroutine 
;
; This subroutine causes a 1 second delay
; 
; Input:  a 16bit count number in 'Counter2'
; Output: time delay, CPU wastes a ton of cycles
; Registers in use: Y register, as counter
; Memory locations in use:  a 16bit input number @ 'Counter2'
;
; Comments: one can add more jumps to delayMS to lengthen the delay time
;           by an additional 100% for each added jump (ie: 3 jsr calls results in 
;           delay equivalent to 300% of the original delay)
;

delay1sec
          PSHY                  ;save Y
          LDY   Counter2        ;long delay by Counter2
          
dly1Loop  JSR   delayMS         ;total time delay = Y * delayMS
          DEY
          BNE   dly1Loop
          
          PULY                  ;restore Y
          RTS                   ;return

;***********************************************************
; delayMS subroutine 
;
; This subroutine causes few msec. delay
;
; Input:  a 16bit count number in 'Counter1'
; Output: time delay, cpu cycle wasted
; Registers in use: X register, as counter
; Memory locations in use: a 16bit input number @ 'Counter1'
;
; Comments: one can add more NOPs to lengthen the delay time.
;

delayMS
          PSHX                  ;save X
          LDX   Counter1        ;short delay
          
dlyMSLoop NOP                   ;total time delay = X * NOP
          DEX
          BNE   dlyMSLoop
          
          PULX                  ;restore X
          RTS                   ;return
          
*
* Add any subroutines here
*

        END                     ;last line of a file
       