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
*               LED2 & LED4 are @ PORTB bits 5 & 7.
*               This pgrm is developed and simulated using CodeWarrior 5.9
*               only, with switch simulation problem. So, one MUST set
*               Switch1 @ PORTB bit 0 as an OUTPUT, not an INPUT.
*               (If running on actual board, PORTB bit 0 must be INPUT).
*
* Algorithm:    Simple Parallel I/O use and time delay-loop
*
* Register use: A:    LED Light on/off state and Switch 1 on/off state
*               B:    Loop counters for LED2 ON & OFF periods of time
*               X:    Delay loop counters
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
* Observation:  This is a prgm that blinks LED 2 & has LED 4 on all the time
*               and blinking period can be changed with the delay loop counter value.
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
Counter1  DC.W      $01F1   ;X register count number for time delay
                            ; inner loop for msec                          
On1       DC.B      $0015   ;duty cycle for LED2 when switch1 is off (21)
On2       DC.B      $0059   ;duty cycle for LED2 when switch1 is on  (89)
Off1      DC.B      $004F   ;fraction of second LED2 is off when switch1 is off
Off2      DC.B      $000B   ;fraction of second LED2 is off when switch1 is on                

                            
                            ;Remaining data memory space for stack,
                            ; up to prgm mem start.                            
*
***********************************************************************
* Program Section:  addr used [$3100 to $3FFF] RAM
*

            ORG       $3100         ;Prgm start addr, in RAM
pstart      LDS       #$3100        ;init stack ptr

            LDAA      #%11110001    ;LED 1,2,3,4 @ PORTB bit 4,5,6,7
            STAA      DDRB          ;set PORTB bit 4,5,6,7 as output
                                    ;plus the bit 0 for Switch1
                                
            LDAA      #%10000000
            STAA      PORTB         ;turn off LED 1,2,3; turn ON LED4 
        
mainLoop     
            LDAA      PORTB         ;read switch 1 @ PORTB bit 0
            ANDA      #%00000001    ;if 0, run blinkLED2 21% light level
            BNE       p89LED2       ;if 1, run blinkLED2 89% light level
          
 
        
p21LED2                             ;Switch1 OFF, 21% duty cycle
            LDAA      #%00100000    ;turn ON LED2 @ PORTB bit 5
            ORAA      PORTB
            STAA      PORTB             
                    
            LDAB      On1           ;load duty cycle for switch1 == OFF (0.21)
p21LoopON   JSR       delay10US     ;delay
            DECB                    ;decrement the ON counter
          
            BNE       p21LoopON     ;loop time!!
          
            LDAA      #%11011111    ;turn off LED2 @ PORTB bit 5, leave LED4 ON!!!
            ANDA      PORTB
            STAA      PORTB
          
            LDAB      Off1          ;load off amount for switch1==OFF (0.79)
p21LoopOFF  JSR       delay10US
            DECB                    ;decrement the OFF counter
            
            BNE       p21LoopOFF    ;loop time!!             
        
            BRA       mainLoop      ;check switch, loop forever!
            
                                   
          
p89LED2                             ;Switch1 ON, 89% duty cycle
            LDAA      #%00100000    ;turn ON LED2 @ PORTB bit 5
            ORAA      PORTB
            STAA      PORTB
                                  
            LDAB      On2           ;load duty cycle for switch1 == OFF (0.89)
p89LoopON   JSR       delay10US    
            DECB                    ;decrement the ON counter
          
            BNE       p89LoopON     ;loop time!!
          
            LDAA      #%11011111    ;turn off LED2 @ PORTB bit 5, leave LED4 ON!!!
            ANDA      PORTB
            STAA      PORTB
                    
            LDAB      Off2          ;load off amount for switch1==OFF (0.11)
p89LoopOFF  JSR       delay10US
            DECB                    ;decrement the OFF counter
            
            BNE       p89LoopOFF    ;loop time!!
                       
            BRA       mainLoop      ;check switch, loop forever!                    

***********************************************************************
* Subroutine Section: addr used [$3100 to $3FFF] RAM
*

;***********************************************************
; delay10US subroutine 
;
; This subroutine causes 10 usec. delay
;
; Input:  a 16bit count number in 'Counter1'
; Output: time delay, cpu cycle wasted
; Registers in use: X register, as counter
; Memory locations in use: a 16bit input number @ 'Counter1'
;
; Comments: one can add more NOPs to lengthen the delay time.
;

delay10US
          PSHX                  ;save X
          LDX   Counter1        ;short delay
          
dlyUSLoop NOP                   ;total time delay = X * NOP
          DEX
          BNE   dlyUSLoop
          
          PULX                  ;restore X
          RTS                   ;return                 
           
*
* Add any subroutines here
*

        END                     ;last line of a file
       















































