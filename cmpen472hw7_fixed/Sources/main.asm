***********************************************************************
*
* Title:          Simple Calculator
*
* Objective:      CMPEN 472 Homework 7
*
* Revision:       V2.0  for CodeWarrior 5.2 Debugger Simulation
*
* Date:	          Mar. 17, 2021, updated Mar. 31, 2021
*
* Programmer:     Nicholas Hutton
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        Simple SCI Serial Port I/O and Demonstration
*                 Calculator
*                                  
*
* Algorithm:      Simple Serial I/O use, typewriter, ASCII and hex conversions
*                 Arithmetic calls, overflow checking, negative checking
*
* Register use:	  A: Serial port data
*                 B: misc data
*                 X: character buffer
*                 Y: misc uses and buffer
*
* Memory use:     RAM Locations from $3000 for data, 
*                 RAM Locations from $3100 for program
*
*	Input:			    Parameters hard-coded in the program - PORTB, 
*                 Terminal connected over serial
* Output:         
*                 Terminal connected over serial
*                 PORTB bit 7 to bit 4, 7-segment MSB
*                 PORTB bit 3 to bit 0, 7-segment LSB
*
* Observation:    This is a menu-driven program that prints to and receives
*                 data from a terminal, and will do different things based 
*                 on user input. It can do +, -, *, and /.
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
SPACE       equ         $20          ; space character

***********************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG         $3000        ; Reserved RAM memory starting address 
                                     ;   for Data for CMPEN 472 class

CCount      DS.B        $0001        ; Number of chars in buffer
HCount      DS.B        $0001        ; number of ASCII characters to be converted to hex
DCount      DS.B        $0001        ; number of ASCII chars to be converted to decimal
DCount1     DS.B        $0001        ; number of decimal digits in Arg1
DCount2     DS.B        $0001        ; number of decimal digits in Arg2
Hex         DS.B        $0002        ; stores a hex number with leading 0s

InputBuff   DS.B        $0009        ; The actual command buffer

DecBuff     DS.B        $0004        ; used to store Hex -> Decimal -> ASCII conversion, terminated with NULL

Arg1ASCII   DS.B        $0004        ; Arg1 in ASCII-formatted decimal
Arg2ASCII   DS.B        $0004        ; Arg2 in ASCII-formatted decimal

HexArg1     DS.B        $0002        ; stores first argument in expression (hex number with leading 0s)
HexArg2     DS.B        $0002        ; stores second argument in expression (hex number with leading 0s)
Temp        DS.B        $0001        
Operation   DS.B        $0001        ; stores what operation was requested (0 for +, 1 for -, 2 for *, 3 for /)                            
err         DS.B        $0001        ; error flag (0 for no error, 1 for error)
negFlag     DS.B        $0001        ; negative answer flag (0 for positive, 1 for negative)
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
            
            jsr   menu               ; print the menu messages, 'Welcome...'
                                   
main        
            ldx   #prompt            ; print the prompt message
            jsr   printmsg
            
            ldx   #InputBuff         ; cmd buffer init
            clr   CCount
            clr   HCount
            jsr   clrBuff            ; clear out old buffer data to prevent garbage second arguments
            ldx   #InputBuff         ; cmd buffer init

cmdLoop     jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   cmdLoop
                                     
            cmpa  #CR
            beq   noReturn
            jsr   putchar            ; is displayed on the terminal window - echo print

noReturn    staa  1,X+               ; store char in buffer
            inc   CCount             ; 
            ldab  CCount
            cmpb  #$08               ; max # chars in buffer is 8, including Enter
            lbhi   Error              ; user filled the buffer
            cmpa  #CR
            bne   cmdLoop            ; if Enter/Return key is pressed, move the
            ;ldaa  #LF                ; cursor to next line
            ;jsr   putchar
            
            
            ldab  CCount
            cmpb  #$04               ; min # chars in buffer is 4, including Enter /////// change to $02 in HW9 since smallest cmd is "q" followed by Enter
            lblo   Error              ; user didn't write enough
            
            
CmdChk                
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key                    
            ldaa  #LF              ; for testing purposes ONLY  
            jsr   putchar
            
            jsr   parser             ; parse the user input
            ldaa  err                ; check the error flag,
            cmpa  #$01               ;  branch to error handler if flag set
            lbeq   Error
            
            ldx   #Hex
            clr   1,X+
            clr   1,X+
            
            ldy   #HexArg1
            ldx   #Arg1ASCII
            ldaa  DCount1
            staa  DCount
            jsr   asciiDec2Hex       ; convert ASCII-formatted arg1 into hex
            ldaa  err                ; check the error flag,
            cmpa  #$01               ;  branch to error handler if flag set
            lbeq   Error
            sty   HexArg1
            
            ldx   #Hex
            clr   1,X+
            clr   1,X+
            
            ldy   #HexArg2
            ldx   #Arg2ASCII
            ldaa  DCount2
            staa  DCount
            jsr   asciiDec2Hex       ; convert ASCII-formatted arg2 into hex
            ldaa  err                ; check the error flag,
            cmpa  #$01               ;  branch to error handler if flag set
            lbeq   Error
            sty   HexArg2
            
            
            ldaa  Operation          ; Operation switch statement
            cmpa  #$00
            beq   opAdd
            cmpa  #$01
            beq   opMinus
            cmpa  #$02
            beq   opMult
            cmpa  #$03
            beq   opDiv
            bra   Error              ; if somehow operation variable is invalid, error out
            
            
opAdd       ldd   HexArg1            ; load arg1 into D
            addd  HexArg2            ; add to arg2, store in D
            std   Hex                ; store answer in Hex
            bra   answer

opMinus     ldd   HexArg1
            cpd   HexArg2            ; answer will be negative when Arg1 < Arg2
            blt   negative
            subd  HexArg2
            std   Hex
            bra   answer
negative    ldd   HexArg2            ; so do Arg2 - Arg1 
            subd  HexArg1
            std   Hex
            ldaa  #$01
            staa  negFlag            ; set negative flag
            bra   answer            

opMult      ldd   HexArg1
            ldy   HexArg2
            emul
            bcs   Overflow           ; check if carry bit set (overflow occurred)
            cpy   #$00               ; check if upper bits of answer are 0
            bne   Overflow           ; if not, then we overflowed
            
            std   Hex
            bra   answer

opDiv       ldd   HexArg1
            ldx   HexArg2
            cpx   #$0000             ; check for divide by zero error
            beq   Error
            idiv                     ; do division (answer stored in X)
            stx   Hex
            ;bra  answer


answer                               ; print the answer
            ldx   #equals
            jsr   printmsg           ; print the '='

            ldd   Hex
            jsr   hex2asciiDec       ; convert answer to ascii
            ldaa  negFlag
            cmpa  #$01               ; check if answer is supposed to be negative
            bne   pozz               
            ldx   #minus
            jsr   printmsg
            
pozz        ldx   #DecBuff
            jsr   printmsg
            
            ldaa    #CR                ; move the cursor to beginning of the line
            jsr     putchar            ;   Cariage Return/Enter key
            ldaa    #LF                ; move the cursor to next line, Line Feed                                 
            jsr     putchar            
            clr    negFlag           ; reset negative flag
            lbra   main

Error                                ; no recognized command entered, print err msg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key                    
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
                        
            ldx   #error1              ; print the error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed                                 
            jsr   putchar
            clr   err                ; reset error flag
            lbra  main               ; loop back to beginning, infinitely


Overflow                             ; multiplication too big
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key                    
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            
            ldx   #error2              ; print the 2nd error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed                                 
            jsr   putchar
            clr   err                ; reset error flag
            lbra  main               ; loop back to beginning, infinitely            
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


;***************echoPrint**********************
;* Program: makes calls to putchar but ends when CR is passed to it
;* Input:   ASCII char in A
;* Output:  1 char is displayed on the terminal window - echo print
;* Registers modified: CCR
;* Algorithm: if(A==CR) return; else print(A);
;**********************************************
echoPrint      cmpa       #CR       ; if A == CR, end of string reached
               beq        retEcho   ; return
               
               jsr        putchar
               
retEcho        rts
;***************end of echoPrint***************


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


;***************menu***************************
;* Program: Print the menu UI
;* Input:   
;* Output:  Prints a menu to the terminal
;* Registers modified: X, A
;**********************************************
menu            ldx   #menu1             ; print the first message, 'Welcome...'
                jsr   printmsg
            
                ldaa  #CR                ; move the cursor to beginning of the line
                jsr   putchar            ;   Cariage Return/Enter key
                ldaa  #LF                ; move the cursor to next line, Line Feed
                jsr   putchar
                
                ldx   #menu2             ; print the second message
                jsr   printmsg
                
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar
                
                
                ldx   #menu3             ; print the third menu item
                jsr   printmsg
                
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar

                ldx   #menu4             ; print the fourth menu item
                jsr   printmsg
                
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar
                
                
                ldx   #menu5             ; print the fifth menu item
                jsr   printmsg
                
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar
                
                ldaa  #CR                
                jsr   putchar            
                ldaa  #LF                
                jsr   putchar
                rts
;***************end of menu********************


 ;***********clrBuff****************************
;* Program: Clear out command buff
;* Input:   
;* Output:  buffer is filled with zeros
;* 
;* Registers modified: X,A,B,CCR
;* Algorithm: set each byte (9 total) in InputBuff to $00
;************************************************
clrBuff
            ldab    #$09        ; number of bytes allocated
clrLoop
            cmpb    #$00        ; standard while loop
            beq     clrReturn
            ldaa    #$00
            staa    1,X+        ; clear current byte
            decb                ; B = B-1
            bra     clrLoop     ; loop thru whole buffer

clrReturn   rts                            
            
;***********clrBuff*****************************


 ;***********parser****************************
;* Program: parse user input and echo back to terminal
;* Input: 2 ASCII-formatted decimal nums, separated 
;*        by a math operator, in #InputBuff 
;* Output: 2 hex nums in HexArg1 and HexArg2, 
;*          operator code stored in Operation variable
;*          with error flag set if error detected 
;* 
;* Registers modified: X,Y,A,B,CCR
;* Algorithm: iterate through buffer and extract each char,
;*            checking for legality along the way
;************************************************
parser      ldx     #indent     ;
            jsr     printmsg    ; print beginning of output
            ldx     #InputBuff  ; load the input buffer
            ldy     #Arg1ASCII  ; load the arg1 buffer
            clrb                ; B = 0;
                        
loopArg1    ldaa    1,X+
            jsr     echoPrint   ; print loaded character            
            
            cmpa    #$39        ; check for illegal symbols
            bhi     parseErr    ;   if so, then error out
            
            cmpa    #$30        ; is this an operator?
            blo     opChk       ;   if so, branch to operator switch statement
            
            cmpb    #$03        ; do we have more than max digits?
            bhi     parseErr    ; if so, then error time
            
            staa    1,Y+        ; store digit in arg1 buffer
            incb                ; increment digit ctr
            bra     loopArg1    ; loop

opChk       cmpb    #$03        ; no more than 3 digits in Arg 1
            bhi     parseErr    
            tstb
            beq     parseErr    ; must be at least 1 digit before operator
            
            stab    DCount1     ; store number of decimal digits
            clrb
            stab    0,Y         ; NULL-terminate Arg1 string
            
            cmpa    #$2B        ; operator == '+'?
            bne     chkMinus    ; if not, branch
            ldaa    #$00        
            staa    Operation   ; 0 == +
            bra     Arg2
            
chkMinus    cmpa    #$2D        ; operator == '-'?
            bne     chkMult     
            ldaa    #$01
            staa    Operation   ; 1 == -
            bra     Arg2
            
chkMult     cmpa    #$2A        ; operator == '*'?
            bne     chkDiv      
            ldaa    #$02        ; 2 == *
            staa    Operation
            bra     Arg2
            
chkDiv      cmpa    #$2F        ; operator == '/'?
            bne     parseErr    ; if not, illegal symbol (',' or '.') entered
            ldaa    #$03        ; 3 == /
            staa    Operation
                                                         
Arg2        ldy     #Arg2ASCII  ; load the arg2 buffer

loopArg2    ldaa    1,X+
            jsr     echoPrint   ; print loaded char
            
            cmpa    #CR         ; if char == CR, then end of input buff
            beq     parseRet    ; prepare to return
            
            cmpa    #$39        ; check if numeric
            bhi     parseErr    
            cmpa    #$30
            blo     parseErr
            
            cmpb    #$03        ; no more than 3 digits in 2nd arg
            bhi     parseErr
            
            staa    1,Y+
            incb
            bra     loopArg2
            
parseRet    cmpb    #$03        ; no more than 3 digits in Arg 2
            bhi     parseErr    
            tstb
            beq     parseErr    ; must be at least 1 digit in Arg 2
            
            stab    DCount2     ; store number of decimal digits
            clrb
            stab    0,Y         ; NULL-terminate Arg2 string    

            ;ldaa    #CR                ; move the cursor to beginning of the line
            ;jsr     putchar            ;   Cariage Return/Enter key
            ;ldaa    #LF                ; move the cursor to next line, Line Feed                                 
            ;jsr     putchar
            rts     
            
parseErr    ldaa    #$01
            staa    err
            rts                   
            
;***********parser*****************************


;****************asciiDec2Hex******************
;* Program: converts ascii-formatted decimal (up to 3 digits) to hex
;*             
;* Input: ascii-formatted decimal, number of digits      
;* Output: hex number in buffer (#Hex) and Y
;*          
;*          
;* Registers modified: X,Y,A,B,CCR
;* Algorithm: from hw6 aid pdf   
;**********************************************
asciiDec2Hex    
                ldaa  0,X     ; load most significant digit into A
                ldab  DCount  ; load the number of digits into B
                cmpb  #$03    ; Are there 3 digits?
                bne   CHUNGUS
                dec   DCount  ; 2 left
                suba  #$30    ; numbers in ASCII are offset by $30
                ldab  #100    ; weight of most sig digit
                mul           ; A * #100, stored in D
                std   Hex     ; store result in Hex
                inx           ; X++
                ldaa  0,X     ; load next digit into A
                ldab  DCount  ; load the number of digits into B
                
CHUNGUS         cmpb  #$02    ; Are there 2 digits?
                bne   CHUNGUS2
                dec   DCount  ; 1 left
                suba  #$30    ; numbers in ASCII are offset by $30
                ldab  #10     ; weight of digit
                mul           ; A * #10, stored in D
                addd  Hex
                std   Hex     ; store result in Hex                
                inx
                ldaa  0,X     ; load least significant digit into A
                ldab  DCount  ; load the number of digits into B
                
CHUNGUS2        cmpb  #$01    ; Are there 1 digits?
                bne  ad2hErr
                dec   DCount  ; 0 left
                suba  #$30    ; numbers in ASCII are offset by $30
                ldab  #1      ; weight of digit
                mul           ; A * #1, stored in D
                addd  Hex
                std   Hex     ; store result in Hex                
                inx                
                ldy   Hex     ; load result into Y
               
                rts

ad2hErr         ldaa  #$01    ;set error flag
                staa  err
                rts

;************end of asciiDec2Hex*************** 


;****************hex2asciiDec******************
;* Program: converts a hex number to ascii-formatted decimal, max. 5 digits
;*             
;* Input:  a hex number in D     
;* Output: that same number in ascii-formatted decimal in DecBuff 
;*          
;*          
;* Registers modified: A, B, X, CCR
;* Algorithm: read the comments
;   
;**********************************************
hex2asciiDec    clr   HCount    ;clear HCount so we can reuse it as a loop counter
                cpd   #$0000    ;check if the hex number is already 0 -- $0 is equiv. to decimal 0
                lbeq  CHEESEBURGER
                ;cpd   #$8000    ;check if the hex number is negative
                ;bne   preConvLoop
                

preConvLoop     ldy   #DecBuff
convertLoop     ldx   #10       ; set divisor = 10
                idiv            ; Hex / 10   
                  
                stab  1,Y+      ; store first decimal digit into the decimal buffer
                inc   HCount    ; 1 division completed, 1 remainder obtained
                tfr   X,D       ; copy division result back into D
                tstb            ; check if the result was 0
                bne   convertLoop; if not, branch back to start of loop
                
                
reverse         ldaa  HCount    
                cmpa  #$05      ; check how many remainders were calculated (how long the decimal number is)
                beq   five
                cmpa  #$04
                beq   four
                cmpa  #$03
                lbeq   three
                cmpa  #$02
                lbeq   two
                                ; only 1 remainder, we can convert it here
                ldx   #DecBuff  ; reload the buffer
                ldaa  0,X       ; load 1s place
                adda  #$30      
                staa  1,X+      ; store converted 1s place, X++
                ldaa  #$00      ; load NULL into A
                staa  1,X+      ; store null terminator
                rts


five            ldx   #DecBuff
                ldaa  1,X+      ; load the 1s place remainder into A
                inx
                inx
                inx
                ldab  0,X       ; load the 10000s place remainder into B
                staa  0,X       ; put the 1s place into the 1s place
                ldx   #DecBuff
                stab  0,X       ; put the 10000s place into the 10000s place
                
                inx             ; move to 1000s place
                ldaa  1,X+      ; load current 1000s place (supposed to be 10s) and do X++
                inx             ; skip current 100s place
                ldab  0,X       ; load current 10s place (supposed to be 1000s)
                staa  0,X       ; put current 1000s into 10s place
                ldx   #DecBuff  ; reload buff
                inx             ; move to 1000s place
                stab  0,X       ; put proper 1000s place (former 10s) into 1000s place
                
                ldx   #DecBuff  ; reload buff
                ldaa  0,X       ; load 10000s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 10000s place and do X++
                ldaa  0,X       ; load 1000s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 1000s place and do X++
                ldaa  0,X       ; load 100s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 100s place and do X++
                ldaa  0,X       ; load 10s place into A
                adda  #$30
                staa  1,X+      ; store converted 10s place, X++
                ldaa  0,X       ; load 1s place
                adda  #$30      
                staa  1,X+      ; store converted 1s place, X++
                ldaa  #$00      ; load NULL into A
                staa  1,X+      ; store null terminator
                rts


four            ldx   #DecBuff
                ldaa  1,X+      ; load the 1s place remainder into A
                inx
                inx
                ldab  0,X       ; load the 1000s place remainder into B
                staa  0,X       ; put the 1s place into the 1s place
                ldx   #DecBuff
                stab  0,X       ; put the 1000s place into the 1000s place
                
                inx             ; move to 100s place
                ldaa  1,X+      ; load current 100s place (supposed to be 10s) and do X++
                ldab  0,X       ; load current 10s place (supposed to be 100s)
                staa  0,X       ; put current 100s into 10s place
                ldx   #DecBuff  ; reload buff
                inx             ; move to 100s place
                stab  0,X       ; put proper 100s place (former 10s) into 100s place
                
                ldx   #DecBuff  ; reload buff
                ldaa  0,X       ; load 1000s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 1000s place and do X++
                ldaa  0,X       ; load 100s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 100s place and do X++
                ldaa  0,X       ; load 10s place into A
                adda  #$30
                staa  1,X+      ; store converted 10s place, X++
                ldaa  0,X       ; load 1s place
                adda  #$30      
                staa  1,X+      ; store converted 1s place, X++
                ldaa  #$00      ; load NULL into A
                staa  1,X+      ; store null terminator
                rts


three           ldx   #DecBuff
                ldaa  1,X+      ; load the 1s place remainder into A
                inx
                ldab  0,X       ; load the 100s place remainder into B
                staa  0,X       ; put the 1s place into the 1s place
                ldx   #DecBuff
                stab  0,X       ; put the 100s place into the 100s place
                
                ldaa  0,X       ; load 100s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 100s place and do X++
                ldaa  0,X       ; load 10s place into A
                adda  #$30
                staa  1,X+      ; store converted 10s place, X++
                ldaa  0,X       ; load 1s place
                adda  #$30      
                staa  1,X+      ; store converted 1s place, X++
                ldaa  #$00      ; load NULL into A
                staa  1,X+      ; store null terminator
                rts
                

two             ldx   #DecBuff
                ldaa  1,X+      ; load the 1s place remainder into A
                ldab  0,X       ; load the 10s place remainder into B
                staa  0,X       ; put the 1s place into the 1s place
                ldx   #DecBuff  
                stab  0,X       ; put the 10s place into the 10s place
                
                ldaa  0,X       ; load 10s place into A
                adda  #$30      ;add ASCII offset
                staa  1,X+      ; store converted 10s place and do X++
                ldaa  0,X       ; load 1s place into A
                adda  #$30
                staa  1,X+      ; store converted 1s place, X++
                ldaa  #$00      ; load NULL into A
                staa  1,X+      ; store null terminator
                rts

               
CHEESEBURGER    ldx   #DecBuff  ;hex input was just 0. we can skip convoluted conversion and do it manually
                ldaa  #$30      ; $30 == '0'
                staa  1,X+      
                ldaa  #$00      ; null
                staa  1,X+               
                rts

;************end of hex2asciiDec***************


;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip

prompt         DC.B    'ECalc> ', $00
indent         DC.B    '       ', $00
equals         DC.B    '=', $00
minus          DC.B    '-', $00

error1         DC.B    '       Invalid input format', $00
error2         DC.B    '       Overflow error', $00

menu1          DC.B    'Welcome to the ECalc Program!  Choose an operation (+, -, *, /) and enter', $00
menu2          DC.B    'your expression below (example shown below) and hit Enter.', $00
menu3          DC.B    'No parentheses. Only 1 operation per expression. Max number of digits is 3. No negatives. Only use base-10 numbers.', $00
menu4          DC.B    'Ecalc> 123+4', $00
menu5          DC.B    '       123+4=127', $00



               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled

