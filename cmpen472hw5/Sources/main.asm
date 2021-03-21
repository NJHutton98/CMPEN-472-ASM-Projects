***********************************************************************
*
* Title:          SCI Serial Port and 7-segment Display at PORTB
*
* Objective:      CMPEN 472 Homework 5
*
* Revision:       V3.2  for CodeWarrior 5.2 Debugger Simulation
*
* Date:	          Feb. 25, 2021
*
* Programmer:     Nicholas Hutton
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        Simple SCI Serial Port I/O and Demonstration
*                 Typewriter program and 7-Segment display, at PORTB
*                 LED flashing
*                 
*
* Algorithm:      Simple Serial I/O use, typewriter, LED flashing
*
* Register use:	  A: Serial port data
*                 B: misc data
*                 X: Delay loop counters, character buffer
*
* Memory use:     RAM Locations from $3000 for data, 
*                 RAM Locations from $3100 for program
*
*	Input:			    Parameters hard-coded in the program - PORTB, 
*                 Terminal connected over serial
* Output:         
*                 Terminal connected over serial
*                 LED1 @ PORTB bit 4
*						      LED2 @ PORTB bit 5
*						      LED3 @ PORTB bit 6
*					    	  LED$ @ PORTB bit 7
*                 PORTB bit 7 to bit 4, 7-segment MSB
*                 PORTB bit 3 to bit 0, 7-segment LSB
*
* Observation:    This is a menu-driven program that prints to and receives
*                 data from a terminal, and will do different things based 
*                 on user input, including LED flashing and a typewriter 
*                 program that displays ASCII data on PORTB - 7-segment displays.
*
***********************************************************************
* Parameter Declearation Section
*
* Export Symbols
            XDEF        pstart       ; export 'pstart' symbol
            ABSENTRY    pstart       ; for assembly entry point
  
* Symbols and Macros
PORTB       EQU         $0001        ; i/o port B addresses
DDRB        EQU         $0003

SCIBDH      EQU         $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU         $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU         $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU         $00CC        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00CF        ; Serial port (SCI) Data Register

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character

***********************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG         $3000        ; Reserved RAM memory starting address 
                                     ;   for Data for CMPEN 472 class
Counter1    DC.W        $0001        ; X register count number for time delay (46 ($2E) loops makes 
                                     ; delay10US take approx 10usec on HCS12 board)

CTR         DC.W        $0000        ;counter variable for dim40ms loop
LEVEL       DC.W        $0000        ;Loop control variable and time on/off decider 
ONN         DC.W        $0000        ;Turn-on-loop control variable   
OFF         DC.W        $0000        ;Turn-off-loop control variable 
                                                                          
CCount      DS.B        $0001        ; Number of chars in buffer
Buff        DS.B        $0005        ; The actual buffer
                                    
; Each message ends with $00 (NULL ASCII character) for your program.
;
; There are 256 bytes from $3000 to $3100.  If you need more bytes for
; your messages, you can put more messages 'msg3' and 'msg4' at the end of 
; the program - before the last "END" line.
                                     ; Remaining data memory space for stack,
                                     ;   up to program memory start

*
***********************************************************************
* Program Section: address used [ $3100 to $3FFF ] RAM memory
*
            ORG        $3100        ; Program start address, in RAM
pstart      LDS        #$3100       ; initialize the stack pointer

            LDAA       #%11111111   ; Set PORTB bit 0,1,2,3,4,5,6,7
            STAA       DDRB         ; as output

            LDAA       #%00000000
            STAA       PORTB        ; clear all bits of PORTB

            ldaa       #$0C         ; Enable SCI port Tx and Rx units
            staa       SCICR2       ; disable SCI interrupts

            ldd        #$0001       ; Set SCI Baud Register = $0001 => 2M baud at 24MHz (for simulation)
;            ldd        #$0002       ; Set SCI Baud Register = $0002 => 1M baud at 24MHz
;            ldd        #$000D       ; Set SCI Baud Register = $000D => 115200 baud at 24MHz
;            ldd        #$009C       ; Set SCI Baud Register = $009C => 9600 baud at 24MHz
            std        SCIBDH       ; SCI port baud rate change

            ldx   #msg1              ; print the first message, 'Hello'
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar          
            
main        ldx   #menu1             ; print the first menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu2             ; print the second menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu3             ; print the third menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #menu4             ; print the fourth menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu5             ; print the fifth menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu6             ; print the sixth menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu7             ; print the seventh menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu8             ; print the eighth menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #menu9             ; print the ninth menu item
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #msg3              ; print the third message
            jsr   printmsg
                                                                                                            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #Buff              ; cmd buffer init
            clr   CCount
            LDAA  #$0000
				    STAA	LEVEL		           ;set LEVEL = 0
 
            
cmdLoop     jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   cmdLoop
                                     ;  otherwise - what is typed on key board
            jsr   putchar            ; is displayed on the terminal window - echo print

            staa  1,X+               ; store char in buffer
            inc   CCount             ; 
            ldab  CCount
            cmpb  #$06
            beq   Error             ; user filled the buffer
            cmpa  #CR
            bne   cmdLoop            ; if Enter/Return key is pressed, move the
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            
            
            ldx   #Buff              ;
            ldaa  1,X+   
FChk        cmpa  #$46               ; is character == F?
            bne   LChk               ;    No, check if == L
            ldaa  1,X+               ; load next character
            cmpa  #$31               ; is character == 1?
            beq   F1                 ;  Yes, F1 execute
            cmpa  #$32               ; is character == 2?
            beq   F2start            ;  Yes, F2 execute
            cmpa  #$33               ; is character == 3?
            lbeq  F3                 ;  Yes, F3 execute
            cmpa  #$34               ; is character == 4?
            lbeq  F4                 ;  Yes, F4 execute
            bra   Error
            
LChk        cmpa  #$4C               ; is character == L?
            bne   QUITChk            ;    No, check if string == QUIT
            ldaa  1,X+   
            cmpa  #$31               ; is character == 1?
            lbeq  L1                 ;  Yes, L1 execute
            cmpa  #$32               ; is character == 2?
            lbeq  L2
            cmpa  #$33               ; is character == 3?
            lbeq  L3
            cmpa  #$34               ; is character == 4?
            lbeq  L4
            bra   Error
            
QUITChk     cmpa  #$51               ; is character == Q?
            bne   Error              ;    No, so invalid entry
            ldaa  1,X+               ; load next char
            cmpa  #$55               ; is character == U?
            bne   Error
            ldaa  1,X+
            cmpa  #$49               ; is character == I?
            bne   Error
            ldaa  1,X+
            cmpa  #$54               ; is character == T?
            lbeq  ttyStart           ;    Yes, go to typewriter, else, continue below
            
Error                                ; no recognized command entered, print err msg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #msg4              ; print the error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  main               ; loop back to beginning, infinitely

F1          LDAA  #%11101111         ;turn OFF LED1 @ PORTB bit 4
            ANDA  PORTB
            STAA  PORTB
            lbra  main

F2start     LDAA  #$0064
            STAA  LEVEL              ;set LEVEL = 100
            
F2          TST   LEVEL              ;does LEVEL == 0?
				    LBEQ  main               ; if so, branch back to mainLoop
				    
				    JSR		dim40MS
				    DEC   LEVEL              ;LEVEL = LEVEL - 1
				    BRA		F2	               ;restart dimDown loop
            

F3          LDAA  #%10111111         ;turn OFF LED3 @ PORTB bit 6
            ANDA  PORTB
            STAA  PORTB
            lbra  main
            
F4          LDAA  #%01111111         ;turn OFF LED4 @ PORTB bit 7
            ANDA  PORTB
            STAA  PORTB
            lbra  main 
            
L1          LDAA  #%00010000         ;turn ON LED1 @ PORTB bit 4
            ORAA  PORTB
            STAA  PORTB
            lbra  main

L2          LDAA  LEVEL		           ;check bit 0 of PORTB, switch1
				    CMPA	#$0065	           ;does LEVEL == 101? (0x65 == 101)
				    LBEQ  main               ; if so, exit dimUp loop and proceed
				    
				    JSR		dim40MS			    
				    INC   LEVEL              ;LEVEL = LEVEL + 1
				    BRA		L2  	             ;restart dimUp loop

L3          LDAA  #%01000000         ;turn ON LED3 @ PORTB bit 6
            ORAA  PORTB
            STAA  PORTB
            lbra  main
            
L4          LDAA  #%10000000         ;turn ON LED4 @ PORTB bit 7
            ORAA  PORTB
            STAA  PORTB
            lbra  main  

ttyStart    ldx   #msg1              ; print the first message, 'Hello'
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #msg2              ; print the third message
            jsr   printmsg
                                                                                                            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
                 
tty         jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   tty
                                     ;  otherwise - what is typed on key board
            jsr   putchar            ; is displayed on the terminal window - echo print

            staa  PORTB              ; show the character on PORTB

            cmpa  #CR
            bne   tty                ; if Enter/Return key is pressed, move the
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            bra   tty


            
;subroutine section below

;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
NULL           equ     $00
printmsg       psha                   ;Save registers
               pshx
printmsgloop   ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
               cmpa    #NULL
               beq     printmsgdone   ;end of strint yet?
               jsr     putchar        ;if not, print character and do next
               bra     printmsgloop

printmsgdone   pulx 
               pula
               rts
;***********end of printmsg********************


;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar        brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               staa  SCIDRL                      ; send a character
               rts
;***************end of putchar*****************


;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, otherwise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************
getchar        brclr SCISR1,#%00100000,getchar7
               ldaa  SCIDRL
               rts
getchar7       clra
               rts
;****************end of getchar**************** 


;**********************************************
;	dim40MS subroutine
;
;	This subroutine loops 40 times and calls dim
;
;	Input:  CTR, a counter for this loop		
;	Output: Dim is called 40 times		
;	Registers in use:	A, for a numeric value
;	Memory locations in use: 16bit input number @ 'CTR'
;

dim40MS
				    LDAA    #$0028    
				    STAA    CTR         ;set CTR = 40
				    
dim40Loop   TST     CTR         ;does CTR == 0?
				    BNE     dim40cont   ; if so, skip dim40Loop
            RTS     
            
dim40cont   JSR     dim
            DEC     CTR         ;CTR = CTR - 1
            BRA     dim40Loop   ;restart loop		
;****************end of dim40MS****************

            
;**********************************************
;	dim subroutine
;
; This subroutine controls the dim up and down functionality at each stage
;
;	Input:  LEVEL, the current duty cycle, ONN & OFF, the time variables that control
;           how long each loop runs for	
;	Output:	Turns on and off LED2
;	Registers in use: A	register, as a counter and to store numeric values for 
;                     various purposes, such as setting which LEDs to turn on
;	Memory locations in use: 16bit input numbers @ 'ONN' and 'OFF' 
;

dim
				    LDAA    LEVEL
				    STAA    ONN         ;set ONN = LEVEL
				    LDAA    #$0064
				    SUBA    LEVEL
				    STAA    OFF         ;set OFF = 100 - LEVEL
				    
				    LDAA		#%00100000	;Turn on LED2 @ PORTB bit 5
				    ORAA	  PORTB
				    STAA		PORTB

onnLoop     TST     ONN         ;does ONN == 0?
				    BEQ     midDim      ; if so, skip onnLoop
            JSR     delay10US
            DEC     ONN         ;ONN = ONN - 1
            BRA     onnLoop     ;restart loop
				    
midDim	    LDAA		#%11011111	;Turn off LED2 @ PORTB bit 5
				    ANDA		PORTB
				    STAA		PORTB

offLoop     TST     OFF         ;does OFF == 0?
				    BEQ     return      ; if so, exit dim
            JSR     delay10US
            DEC     OFF         ;OFF = OFF - 1
				    BRA     offLoop     ;restart loop
				
return      RTS						      ;return
;****************end of dim********************


;**********************************************
; delay10US subroutine 
;
; This subroutine causes few usec. delay
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
          LDX       Counter1    ;short delay
          
dlyUSLoop NOP                   ;total time delay = X * NOP
          DEX
          BNE       dlyUSLoop
          
          PULX                  ;restore X
          RTS                   ;return
;****************end of delay10US**************


;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip

msg1           DC.B    'Hello', $00
msg2           DC.B    'You may type below', $00
msg3           DC.B    'Enter your command below:', $00
msg4           DC.B    'Error: Invalid command', $00

menu1          DC.B    'L1: Turn on LED1', $00
menu2          DC.B    'F1: Turn off LED1', $00
menu3          DC.B    'L2: LED 2 goes from 0% light level to 100% light level in 4 seconds', $00
menu4          DC.B    'F2: LED 2 goes from 100% light level to 0% light level in 4 seconds', $00
menu5          DC.B    'L3: Turn on LED3', $00
menu6          DC.B    'F3: Turn off LED3', $00
menu7          DC.B    'L4: Turn on LED4', $00
menu8          DC.B    'F4: Turn off LED4', $00
menu9          DC.B    'QUIT: Quit menu program, run Typewriter program.', $00               ;

               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled

