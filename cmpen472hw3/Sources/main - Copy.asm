***********************************************************************
*
* Title:        LED Light ON/OFF and Switch ON/OFF
*
* Objective:    CSE472 Homework 3
*
* Revision:     v1.0
*
* Date:         Feb. 10, 2021
*
* Programmer:   Nicholas Hutton, (original: Kyusun Choi)
*
* Company:      The Pennsylvania State University
*               Department of Computer Science and Engineering
*
* Program:      LED 4 blink every 1 second
*               ON for 0.2sec, OFF for 0.8sec when switch 1 is NOT pressed
*               ON for 0.8sec, OFF for 0.2sec when switch 1 IS pressed
*
* Note:
*               On the CSM-12C128 board, Switch1 is @ PORTB bit 0, and
*               LED4 is @ PORTB bit 7.
*               This pgrm is developed and simulated using CodeWarrior 5.9
*               only, with switch simulation problem. So, one MUST set
*               Switch1 @ PORTB bit 0 as an OUTPUT, not an INPUT.
*               (If running on actual board, PORTB bit 0 must be INPUT).
*
* Algorithm:    Simple Parallel I/O use and time delay-loop
*
* Register use: A:    LED Light on/off state and Switch 1 on/off state
*               X, Y: Delay loop counters
*
* Memory use:   RAM locs from $3000 for data,
*               RAM locs from $3100 for prgm.
*
* Input:        Parameters hard-coded in the prgm - PORTB
*               Switch 1 at PORTB bit 0
*                 (set this bit as an output for simulation only - and add Switch)
*               Switch 2 at PORTB bit 1
*               Switch 3 at PORTB bit 2
*               Switch 4 at PORTB bit 3
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
Counter1  DC.W      $008F   ;X register count number for time delay
                            ; inner loop for msec
Counter2  DC.W      $000C   ;Y register count number for time delay                            
                            ; outer loop for sec
* Values $008F & $000C will result in 1/10 sec delay on prof's PC
                            
                            ;Remaining data memory space for stack,
                            ; up to prgm mem start.                            
*
***********************************************************************
* Program Section:  addr used [$3100 to $3FFF] RAM
*
          ORG       $3100         ;Prgm start addr, in RAM
pstart    lds       #$3100        ;init stack ptr

          ldaa      #%11110001    ;LED 1,2,3,4 @ PORTB bit 4,5,6,7
          staa      DDRB          ;set PORTB bit 4,5,6,7 as output
                                  ;plus the bit 0 for Switch1
                                
          ldaa      #%00000000
          staa      PORTB         ;turn off LED 1,2,3,4 (all bits in PORTB, for simulation)
        
mainLoop     
          ldaa      PORTB         ;read switch 1 @ PORTB bit 0
          ANDA      #%00000001    ;if 0, run blinkLED4 20% light level
          BNE       p80LED4       ;if 1, run blinkLED4 80% light level
          
        
p20LED4   
          JSR       LED4on        ;20% light level (duty cycle)
          JSR       LED4on
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          JSR       LED4off
          BRA       mainLoop      ;check switch, loop forever!
          
p80LED4   
          JSR       LED4on        ;80% light level (duty cycle)
          JSR       LED4on
          JSR       LED4on
          JSR       LED4on
          JSR       LED4on
          JSR       LED4on
          JSR       LED4on
          JSR       LED4on
          JSR       LED4off
          JSR       LED4off
          BRA       mainLoop      ;check switch, loop forever!                     

***********************************************************************
* Subroutine Section: addr used [$3100 to $3FFF] RAM
*

;***********************************************************
; LED4 turn-on & turn-off subroutines 
;
; This subroutine ???
; 
; Input:  ???
; Output: ???
; Registers in use: ???
; Memory locations in use:  ???
;
; Comments: ???
;

LED4off
          PSHA                  ;save A
          LDAA  #%01111111      ;turn off LED4 @ PORTB bit 7
          ANDA  PORTB
          STAA  PORTB
          JSR   delay1sec       ;wait for 1 sec
          PULA                  ;restore A
          RTS
      
          
LED4on  
          PSHA                  ;save A
          LDAA  #%10000000      ;turn on LED4 @ PORTB bit 7
          ORAA  PORTB
          STAA  PORTB
          JSR   delay1sec       ;wait for 1 sec
          PULA                  ;restore A
          RTS

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
       















































