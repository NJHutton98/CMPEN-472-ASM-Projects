***********************************************************************
*
* Title:          SCI Serial Port and 7-segment Display at PORTB
*
* Objective:      CMPEN 472 Homework 6
*
* Revision:       V1.0  for CodeWarrior 5.2 Debugger Simulation
*
* Date:	          Mar. 08, 2021
*
* Programmer:     Nicholas Hutton
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        Simple SCI Serial Port I/O and Demonstration
*                 Typewriter program and 7-Segment display, at PORTB
*                 Reading from memory and printing over Serial I/O
*                 Writing to memory
*                 
*
* Algorithm:      Simple Serial I/O use, typewriter, ASCII and hex conversions
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
*                 on user input, including writing to memory and a typewriter 
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
SPACE       equ         $20          ; space character

***********************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG         $3000        ; Reserved RAM memory starting address 
                                     ;   for Data for CMPEN 472 class

CCount      DS.B        $0001        ; Number of chars in buffer
HCount      DS.B        $0001        ; number of ASCII characters to be converted to hex
DCount      DS.B        $0001        ; number of ASCII chars to be converted to decimal
CmdBuff     DS.B        $000C        ; The actual command buffer
HexBuff     DS.B        $0004        ; used to store Hex -> ASCII conversion, terminated with NULL ($00)
AddrBuff    DS.B        $0006        ; stores the address copied from the command buffer, terminated with NULL
DecBuff     DS.B        $0004        ; used to store Hex -> Decimal -> ASCII conversion, terminated with NULL
Hex         DS.B        $0002        ; stores a hex number with leading 0s
Temp        DS.B        $0001                                    
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

            ldx   #HexBuff
            ldaa  #$24
            staa  1,X+               ; initialize the HexBuff with $ in first byte

            ldx   #Hex
            clr   1,X+
            clr   1,X+
            
            ldx   #menu1             ; print the first message, 'Welcome...'
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            ldx   #menu2             ; print the second message, 'commands ...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            
            ldx   #menu3             ; print the third menu item, '>S$3000...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #menu4             ; print the fourth menu item, '> $3000...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #prompt            ; print the prompt, '>'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            
            ldx   #menu5             ; print the fifth menu item, '>W$3001 $6A...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #menu6             ; print the sixth menu item, '> $3001...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #prompt            ; print the prompt, '>'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            
            ldx   #menu7             ; print the seventh menu item, '>W$3001 106...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #menu8             ; print the eighth menu item, '> $3001...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #prompt            ; print the prompt, '>'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            
            ldx   #menu9             ; print the ninth menu item, 'QUIT...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #msg3              ; print the third message
            jsr   printmsg
                                                                                                            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
main        ldx   #prompt            ; print the prompt character (>)
            jsr   printmsg
            ldx   #CmdBuff           ; cmd buffer init
            clr   CCount
            clr   HCount
            LDAA  #$0000
            ldy   #Hex
            staa  Y
            
            
cmdLoop     jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   cmdLoop
                                     ;  otherwise - what is typed on key board
            jsr   putchar            ; is displayed on the terminal window - echo print

            staa  1,X+               ; store char in buffer
            inc   CCount             ; 
            ldab  CCount
            cmpb  #$0C               ; max # chars in buffer is 12
            beq   Error              ; user filled the buffer
            cmpa  #CR
            bne   cmdLoop            ; if Enter/Return key is pressed, move the
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            
            
            ldx   #CmdBuff           ;
            ldaa  1,X+   
CmdChk      cmpa  #$53               ; is character == S?            
            lbeq   Show              ;  Yes, S execute
            cmpa  #$57               ; is character == W?            
            lbeq   Write             ;  Yes, W execute
                                     ;    No, check if string == QUIT below            
            
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
            lbeq  ttyStart           ;    Yes, go to typewriter, else, continue to Error below
            
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


Show        ldab  CCount
            cmpb  #$07               ; S cmds are 6 chars long + return
            lbne   SAddrError        ;  incorrect cmd length for Show
            inx                      ;skip the $ character. the S character was already bypassed in CmdChk
            ldaa  0,X   
            cmpa  #$33               ; is first addr character == 3? (addr range $3000 - 3FFF)
            ;lbne  SAddrError
            
            pshx                     ; save X
            inx
SaveMe      ldaa  1,X+
            cmpa  #$46               ; check to make sure third digit is F or below
            lbhi  SAddrError
            cmpa  #$41               ; check if third digit is A - F
            bhs   SAlpha3
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  SAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  SAddrError
            
SAlpha3     ldaa  1,X+               ; SAlpha3 label == skip to next digit
            cmpa  #$46               ; check to make sure second digit is F or below
            lbhi  SAddrError
            cmpa  #$41               ; check if second digit is A - F
            bhs   SAlpha2
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  SAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  SAddrError
            
SAlpha2     ldaa  0,X               ; SAlpha2 label == skip to last digit
            cmpa  #$46               ; check to make sure first digit is F or below
            lbhi  SAddrError
            cmpa  #$41               ; check if first digit is A - F
            bhs   SAlpha1
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  SAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  SAddrError
                       
SAlpha1     pulx                     ; restore X to the beginning of the ASCII address representation
            ldab  #$04
            stab  HCount
            jsr   asciiHex2Hex       ; jump to subrt to convert ASCII address text to an actual address
            ldy   Hex
            ldaa  0,Y                ; load the value from the deciphered address into A
            jsr   hex2ascii
            ldy   Hex
            ldaa  0,Y                ; load the value from the deciphered address into A
            jsr   hex2asciiDec       ; convert the hex value from the address into decimal then to ascii
            
            ldx   #CmdBuff
            ldy   #AddrBuff
            inx                      ; skip the 'S'
            ldaa  1,X+               ; load the '$' into A
            staa  1,Y+               ; store the '$' into AddrBuff
            ldaa  1,X+               ; load the '3' into A
            staa  1,Y+               ; store the '3' into AddrBuff
            ldaa  1,X+
            staa  1,Y+
            ldaa  1,X+
            staa  1,Y+
            ldaa  1,X+
            staa  1,Y+
            ldaa  #$00               ; load NULL into A
            staa  1,Y+               ; store the string terminator into AddrBuff
            
            ldaa  #SPACE                
            jsr   putchar
            
            ldx   #AddrBuff          ; print the entered address
            jsr   printmsg
            
            ldx   #equals            ; print the =
            jsr   printmsg
            
            ldx   #HexBuff           ; print the hex data at that address
            jsr   printmsg
            
            ldaa  #SPACE             ; print a space   
            jsr   putchar
            
            ldx   #DecBuff           ; print the decimal version of the data at that address
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            lbra  main


Write       ldy   #AddrBuff
            ldaa  0,X
            staa  1,Y+               ; store the '$' into AddrBuff
            cmpa  #$24               ; it had better be a $ or you're a dead man!
            lbne  WAddrError
            inx                      ;skip the $ character. the S character was already bypassed in CmdChk
            
            pshx                     ; save X
            
            
            ldaa  0,X
            cmpa  #$46               ; check to make sure fourth digit is F or below
            lbhi  WAddrError
            ldab  #$01               ; we know there will be at least 1 digit in the address if it's real
            cmpa  #$41               ; check if fourth digit is A - F
            bhs   WAlpha4
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  WAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  WAddrError            
            
WAlpha4     staa  1,Y+               ; store the fourth digit into AddrBuff
            inx
            ldaa  1,X+
            cmpa  #$46               ; check to make sure third digit is F or below
            lbhi  WAddrError
            cmpa  #$20               ; check if third digit is Enter, and address part of entry is done
            beq   WAlpha1
            incb                     ; at least 2 hex digits in the address
            cmpa  #$41               ; check if third digit is A - F
            bhs   WAlpha3
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  WAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  WAddrError
            
WAlpha3     staa  1,Y+               ; store the third digit into AddrBuff
            ldaa  1,X+               ; SAlpha3 label == skip to next digit
            cmpa  #$46               ; check to make sure second digit is F or below
            lbhi  WAddrError
            cmpa  #$20               ; check if second digit is Enter, and address part of entry is done
            beq   WAlpha1
            incb                     ; at least 3 hex digits in the address
            cmpa  #$41               ; check if second digit is A - F
            bhs   WAlpha2
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  WAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  WAddrError            

WAlpha2     staa  1,Y+               ; store the second digit into AddrBuff
            ldaa  0,X               ; SAlpha2 label == skip to last digit
            cmpa  #$46               ; check to make sure first digit is F or below
            lbhi  WAddrError
            cmpa  #$20               ; check if first digit is Enter, and address part of entry is done
            beq   WAlpha1
            incb                     ; the address is 4 hex digits long
            cmpa  #$41               ; check if first digit is A - F
            bhs   WAlpha1
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  WAddrError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  WAddrError
            
WAlpha1     staa  1,Y+               ; store the first digit into AddrBuff
            ldaa  #$00               ; load NULL into A
            staa  1,Y+               ; store the string terminator into AddrBuff
            pulx                     ; restore X to the beginning of the ASCII address representation            
            stab  HCount             ; store number of hex digits to be converted
            jsr   asciiHex2Hex       ; jump to subrt to convert ASCII address text to an actual address
            ldy   Hex
            inx                      ; skip the space character in the user's entry
            pshx                     ; save location of argument to W
            ldaa  1,X+               ; load next character into A. Should either be '$' or a number
            cmpa  #$24               ; is the argument to W a hex number?
            lbne  WDec               ;  if not, skip ahead to further checks
            pshx                     ; store the beginning of the argument in ASCII
            
            clr   HCount             ; reset hex digits counter
            ldaa  1,X+
            cmpa  #$46               ; check to make sure second digit is F or below
            lbhi  DataError
            inc   HCount             ; at least 1 hex digit in the address
            cmpa  #$41               ; check if second digit is A - F
            bhs   WAlpha5
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  DataError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  DataError
            
WAlpha5     ldaa  1,X+
            cmpa  #$46               ; check to make sure first digit is F or below
            lbhi  DataError
            cmpa  #CR                ; check if first digit is space
            beq   WAlpha6
            inc   HCount             ; at least 2 hex digits in the address
            cmpa  #$41               ; check if first digit is A - F
            bhs   WAlpha6
            cmpa  #$39               ; check to make sure digit is numeric
            lbhi  DataError
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  DataError            

WAlpha6     ldx   #Hex               ; clear out the Hex storage
            clr   1,X+
            clr   1,X+
            pulx                     ; restore X to the beginning of the ASCII Argument representation
            jsr   asciiHex2Hex       ; jump to subrt to convert ASCII argument text to an actual hex number
STORE       ldx   #Hex
            inx
            ldaa  0,X                ; load converted hex data stored in Hex
            staa  0,Y                ; store that data into the address input by the user
            
            
            ldx   #Hex
            inx
            ldaa  0,X                ; load converted hex data stored in Hex
            jsr   hex2asciiDec       ; convert the hex value from the address into decimal then to ascii
            
            pulx
            ldy   #HexBuff
            ldaa  1,X+               ; load next character into A. Should either be '$' or a number
            staa  1,Y+               ; store the first character into HexBuff
            ldaa  1,X+               ; load next character of argument into A
            cmpa  #CR                ; check if digit is Enter
            beq   terminator
            staa  1,Y+               ; store the second character into HexBuff
            ldaa  1,X+               ; load last character of argument into A
            cmpa  #CR                ; check if digit is Enter
            beq   terminator
            staa  1,Y+               ; store last digit of argument into HexBuff
terminator  ldaa  #$00               ; load null terminator into A
            staa  0,Y                ; terminate HexBuff
            
            ldaa  #SPACE                
            jsr   putchar
            
            ldx   #AddrBuff          ; print the entered address
            ;ldaa  #$24
            ;staa  0,X
            jsr   printmsg
            
            ldx   #equals            ; print the =
            jsr   printmsg
            
            ldx   #HexBuff           ; print the hex data at that address
            jsr   printmsg
            
            ldaa  #SPACE             ; print a space   
            jsr   putchar
            
            ldx   #DecBuff           ; print the decimal version of the data at that address
            jsr   printmsg

            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            lbra  main

WDec        cmpa  #$39               ; check to make sure third digit is numeric
            lbhi  DataError
            cmpa  #$30               ; check to make sure third digit is 0 - 9
            lblo  DataError
            pshx                     ; store the beginning of the argument in ASCII
            
            clr   DCount             ; reset dec digits counter
            inc   DCount             ; we already have 1 digit
            ldaa  1,X+
            cmpa  #$39               ; check to make sure second digit is numeric
            lbhi  DataError
            cmpa  #CR                ; check if second digit is enter
            beq   WDec2
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  DataError
            inc   DCount             ; at least 2 dec digits in the counter 
            
            ldaa  1,X+
            cmpa  #$39               ; check to make sure first digit is numeric
            lbhi  DataError
            cmpa  #CR                ; check if first digit is enter
            beq   WDec2
            cmpa  #$30               ; check to make sure digit is 0 - 9
            lblo  DataError
            inc   DCount             ; at least 3 dec digits in the counter
            
WDec2       ldx   #Hex               ; clear out the Hex storage
            clr   1,X+
            clr   1,X+
            pulx                     ; restore X to the beginning of the ASCII Argument representation
            pshx                     ;
            jsr   asciiDec2Hex       ; jump to subrt to convert ASCII argument text to an actual hex number            
            
            ldx   #Hex
            inx
            ldaa  0,X                ; load converted hex data stored in Hex
            staa  0,Y                ; store that data into the address input by the user
            
            ldx   #CmdBuff
            inx
            ldaa  1,X+
            pshx
            inx
            lbra  SaveMe
             
            ;jsr   hex2ascii
            
            ;pulx
            ;ldy   #DecBuff
            
            ;ldaa  1,X+               ; load next character into A. Should either be '$' or a number
            ;staa  1,Y+               ; store the first character into HexBuff
            ;ldaa  1,X+               ; load next character of argument into A
            ;cmpa  #CR                ; check if digit is Enter
            ;beq   terminator2
            ;staa  1,Y+               ; store the second character into HexBuff
            ;ldaa  1,X+               ; load last character of argument into A
            ;cmpa  #CR                ; check if digit is Enter
            ;beq   terminator2
            ;staa  1,Y+               ; store last digit of argument into HexBuff
;terminator2 ;ldaa  #$00               ; load null terminator into A
            ;staa  0,Y                ; terminate HexBuff
            
            
            
            
            ;ldaa  #SPACE                
            ;jsr   putchar
            
            ;ldx   #AddrBuff          ; print the entered address
            ;ldaa  #$24
            ;staa  0,X
            ;jsr   printmsg
            
            ;ldx   #equals            ; print the =
            ;jsr   printmsg
            
            ;ldx   #HexBuff           ; print the hex data at that address
            ;jsr   printmsg
            
            ;ldaa  #SPACE             ; print a space   
            ;jsr   putchar
            ;
            ;ldx   #DecBuff           ; print the decimal version of the data at that address
            ;jsr   printmsg

            ;ldaa  #CR                
            ;jsr   putchar            
            ;ldaa  #LF                
            ;jsr   putchar
            
            ;lbra  main

             

SAddrError                           ; user entered invalid addr, print S addr error
            ldaa  #CR                ; newline
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #error1            ; print the error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
                                     ; Show proper usage below
            ldx   #menu3             ; print the third menu item, '>S$3000...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #menu4             ; print the fourth menu item, '> $3000...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #msg3              ; print the third message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  main               ; loop back to beginning, infinitely
            
WAddrError                           ; user entered invalid addr, print S addr error
            ldaa  #CR                ; newline
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #error3            ; print the error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
                                     ; Show proper usage below
            ldx   #menu5             ; print the fifth menu item, '>W$3001 $6A'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #menu6             ; print the sixth menu item, '> $3001...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            
            ldx   #menu7             ; print the seventh menu item, '>W$3001 106'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #menu8             ; print the eighth menu item, '> $3001...'
            jsr   printmsg
            
            ldaa  #CR                
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #msg3              ; print the third message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  main               ; loop back to beginning, infinitely            

DataError                            ; user entered invalid data, print data error
            ldaa  #CR                ; newline
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar

            ldx   #error2            ; print the error message
            jsr   printmsg
            ldaa  #CR                ; newline
            jsr   putchar            ;   
            ldaa  #LF                ; 
            jsr   putchar
            ldx   #msg3              ; print the third message
            jsr   printmsg
            ldaa  #CR                ; newline
            jsr   putchar            
            ldaa  #LF                
            jsr   putchar
            lbra  main               ; loop back to beginning, infinitely
            
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


;****************asciiHex2Hex******************
;* Program: converts ascii-formatted hex (up to 2 digits) to actual hex
;*             
;* Input: a number in hex represented by ASCII stored in a buffer referenced by X      
;* Output: a number in hex 
;*                  
;* Registers modified: X, A, B
;* Algorithm: isolates the digits and uses shifting magic
;   
;**********************************************
asciiHex2Hex    ldd   Hex   ; load full 16bit Hex buffer into D
                lsld        ; shift D left once
                lsld
                lsld
                lsld        ; shift old least significant digit to the left
                std   Hex
                ldaa  1,X+  ;load first addr digit into A, X++
                cmpa  #$41  ; check if A - F
                bhs   Alpha1
                
                suba  #$30  ; numbers in ASCII are offset by $30
                staa  Temp
                ldd   Hex   ; load full 16bit Hex buffer into D
                orab  Temp  ; put new least significant digit into D
                std   Hex
                dec   HCount
                tst   HCount
                bne   asciiHex2Hex

                rts
                
Alpha1          suba  #$37  ; letters in ASCII are offset by $37
                staa  Temp
                ldd   Hex   ; load full 16bit Hex buffer into D
                orab  Temp  ; put new least significant digit into D
                std   Hex
                dec   HCount
                tst   HCount
                bne   asciiHex2Hex

                rts      

;************end of asciiHex2Hex*************** 


;****************asciiDec2Hex******************
;* Program: converts ascii-formatted decimal (up to 3 digits) to hex
;*             
;* Input: ascii-formatted decimal, number of digits      
;* Output: hex number in Hex 
;*          
;*          
;* Registers modified: X,A,B
;* Algorithm: from hw6 aid pdf
;   
;**********************************************
asciiDec2Hex    dex
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
                lbne  DataError
                dec   DCount  ; 0 left
                suba  #$30    ; numbers in ASCII are offset by $30
                ldab  #1      ; weight of digit
                mul           ; A * #1, stored in D
                addd  Hex
                std   Hex     ; store result in Hex                
                inx                

               
                rts


;************end of asciiDec2Hex*************** 


;****************hex2ascii*********************
;* Program: converts hex to ascii-formatted hex 
;*             
;* Input: HexBuff -- a buff to hold the converted number, hex number in A      
;* Output: hex number in ascii form in HexBuff 
;*          
;*          
;* Registers modified: A,X
;* Algorithm: read the comments
;   
;**********************************************
hex2ascii       ldx   #HexBuff  ;load the ASCII Hex buffer
                inx             ;skip the '$' at the beginning
                staa  Temp      ;put our hex number away for safe-keeping
                lsra            ;shift to so we can isolate high bits
                lsra
                lsra
                lsra
                cmpa  #$09      ;check if letter
                bhi   Alpha2    ; if letter, branch to letter code
                adda  #$30      ;add ASCII offset
                
                
                staa  1,X+      ;store first digit into HexBuff
                              
Num1            ldaa  Temp      ;reload the number
                anda  #$0F      ;isolate low bits of hex number (eg: $6A && $0F results in $0A)
                cmpa  #$09      ;check if letter
                bhi   Alpha3    ; if letter, branch to letter code
                adda  #$30      ;add ASCII offset
                staa  1,X+      ;store second digit into HexBuff
                ldaa  #$00      ;load NULL terminator into A
                staa  1,X+      ; store NULL terminator into HexBuff
                rts
                
Alpha2          adda  #$37      ;add ASCII offset
                staa  1,X+      ;store first digit into HexBuff
                              
                ldaa  Temp      ;reload the number
                anda  #$0F      ;isolate low bits of hex number (eg: $6A && $0F results in $0A)
                cmpa  #$09      ;check if letter
                bls   Num1      ; if number, branch back to number code
                adda  #$37      ;add ASCII offset
                staa  1,X+      ;store second digit into HexBuff
                ldaa  #$00      ;load NULL terminator into A
                staa  1,X+      ; store NULL terminator into HexBuff
                rts
                
Alpha3          adda  #$37      ;add ASCII offset
                staa  1,X+      ;store second digit into HexBuff
                ldaa  #$00      ;load NULL terminator into A
                staa  1,X+      ; store NULL terminator into HexBuff
                rts                      

;************end of hex2ascii******************


;****************hex2asciiDec******************
;* Program: converts a hex number to ascii-formatted decimal
;*             
;* Input:  a hex number in A     
;* Output: that same number in ascii-formatted decimal in DecBuff 
;*          
;*          
;* Registers modified: A, B, X
;* Algorithm: read the comments
;   
;**********************************************
hex2asciiDec    tsta            ;check if the hex number is already 0 -- $0 is equiv. to decimal 0
                lbeq  CHEESEBURGER
                
                staa  Temp      ;put our hex number away for safe-keeping
                clr   HCount    ;clear HCount so we can reuse it as a loop counter
                ldaa  #$00
                ldab  Temp      ; set dividee = hex number
                
                ldx   #10       ; set divisor = 10
                idiv            ; Hex / 10   
                ldy   #DecBuff  
                stab  1,Y+      ; store first decimal digit into the decimal buffer
                inc   HCount    ; 1 division completed, 1 remainder obtained
                tfr   X,D       ; copy division result back into D
                tstb            ; check if the result was 0
                beq   reverse   ;   if so, branch, we're done dividing.
                
                ldx   #10       ; set divisor = 10
                idiv            ; Hex / 10   
                  
                stab  1,Y+      ; store second decimal digit into the decimal buffer
                inc   HCount    ; 1 division completed, 1 remainder obtained
                tfr   X,D       ; copy division result back into D
                tstb            ; check if the result was 0
                beq   reverse   ;   if so, branch, we're done dividing.
                
                ldx   #10       ; set divisor = 10
                idiv            ; Hex / 10   
                  
                stab  1,Y+      ; store third decimal digit into the decimal buffer
                inc   HCount    ; 1 division completed, 1 remainder obtained
                tfr   X,D       ; copy division result back into D

                
reverse         ldaa  HCount    
                cmpa  #$03      ; check how many remainders were calculated (how long the decimal number is)
                beq   three
                cmpa  #$02
                beq   two
                                ; only 1 remainder, we can convert it here
                ldx   #DecBuff  ; reload the buffer
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

                
                ;do the division thing and then find a way to reverse the order of the digits in memory so we don't have to do the reverse bullshit???
               
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

msg1           DC.B    'Hello', $00
msg2           DC.B    'You may type below', $00
msg3           DC.B    'Enter your command below:', $00
msg4           DC.B    'Error: Invalid command', $00

prompt         DC.B    '>', $00
equals         DC.B    ' = ', $00
menu1          DC.B    'Welcome to the Simple Memory Access Program!  Enter one of the following', $00
menu2          DC.B    'commands (examples shown below) and hit Enter.', $00
menu3          DC.B    '>S$3000                 to see the memory content at $3000', $00
menu4          DC.B    '> $3000 = $6A    106', $00
menu5          DC.B    '>W$3001 $6A             to write $6A to memory location $3001', $00
menu6          DC.B    '> $3000 = $6A    106', $00
menu7          DC.B    '>W$3001 106             to write $6A to memory location $3001', $00
menu8          DC.B    '> $3000 = $6A    106', $00
menu9          DC.B    'QUIT: Quit menu program, run Typewriter program.', $00   
error1         DC.B    '> invalid input, address must be a 4-digit hex number', $00
error3         DC.B    '> invalid input, address', $00
error2         DC.B    '> invalid input, data', $00
            ;

               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled

