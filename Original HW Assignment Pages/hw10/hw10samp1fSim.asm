;*******************************************************
;* CMPEN 472, HW10 Sample 1, Timer Interrupt, MC9S12C128 Program
;*   for CodeWarrior Simulator/Debugger (not on CSM-12C128 board), 
;*   with Visualizer: 8 bit DIP switch and 7 segment display
;*   CodeWarrior project MUST specify MC9S12C32 chip for the terminal simulation to work.
;* Nov.   3,2016 Kyusun Choi
;* Nov.   7,2016 Kyusun Choi
;* Dec.  18,2016 Kyusun Choi
;* Nov.   2,2018 Kyusun Choi
;* April  6,2020 Kyusun Choi
;* Oct.  28,2020 Kyusun Choi
;* March 31,2021 Kyusun Choi
;*
;* Using CodeWarrior Simulator/Debugger,
;*   with Visualizer: 8 bit DIP switch and 7 segment display
;* This is 10 second timer using Timer channer 2, Output Compare Interrupt.
;* Displays the time remaining on the Visualizer 7 Segment Display 
;*   connected to PORTB, every 1 second.  
;* That is, this program displays '987654321098765432109876543210 . . . ' on the 
;* 7 segment display connected to PORTB bit 7 to 4 of MC9S12C128 chip on CSM-12C128 board.  
;* User may enter 'stop' command followed by an enter key hit on the
;* simulator terminal to stop the timer 
;* and re-start the timer with 'run' command followed by an enter key.
;*
;* Please note the new feature of this program:
;* Timer OC2 interrupt vector, initialization of 
;* TIOS, TIE, TSCR1, TSCR2, TFLG1, TC2H registers for the
;* Timer channel 2 Output Compare Interrupt.
;* We assumed 24MHz bus clock and 4MHz external resonator clock frequency.  
;* This program evaluates user input (command) after the enter key hit and allow 
;* maximum five characters for user input.  This program ignores the wrong 
;* user inputs with error message, and continue count down.
;* 
;*******************************************************
; export symbols
            XDEF        Entry        ; export 'Entry' symbol
            ABSENTRY    Entry        ; for assembly entry point

; include derivative specific macros
PORTB       EQU         $0001        ; I/O port B, 7 segment display at bit 7 to 4
DDRB        EQU         $0003        ; I/O port B data direction control

SCIBDH      EQU         $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU         $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU         $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU         $00cc        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00cf        ; Serial port (SCI) Data Register
;*   CodeWarrior project MUST specify MC9S12C32 chip for the terminal simulation to work.

TIOS        EQU         $0040        ; Timer Input Capture (IC) or Output Compare (OC) select
TIE         EQU         $004C        ; Timer interrupt enable register
TCNTH       EQU         $0044        ; Timer free runing main counter
TSCR1       EQU         $0046        ; Timer system control 1
TSCR2       EQU         $004D        ; Timer system control 2
TFLG1       EQU         $004E        ; Timer interrupt flag 1
TC2H        EQU         $0054        ; Timer channel 2 register

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character


intct       equ         79           ; my PC simulation works,  79 => 1 sec approximately
;intct       equ         7999         ; For 1 sec., interrupt count is 8000
; 125usec * 8000 = 1 sec,  0 to 7999 count is 8000
; For simulation, reduce this number for faster 1 sec. timing
; If interrupt count less than 8000, then not 1 sec yet.
;    no need to update display.


;*******************************************************
; variable/data section
            ORG     $3000            ; RAMStart defined as $3000
                                     ; in MC9S12C128 chip, also OK for MC9S12C32 chip

ctr125u     DS.W    1                ; 16bit interrupt counter for 125 uSec. of time
cbufct      DS.B    1                ; user input character buffer fill count
cbuf        DS.B    6                ; user input character buffer, maximum 6 char
cerror      DS.B    1                ; user input error count, 1 - 9 (ASCII $31 - $39)

times       DS.B    1                ; time to display on screen, second

msg1        DC.B    'Hello, this is 10 second count down timer program.', $00
msg2        DC.B    'You may type <stop> or <run> command with enter key', $00
msg3err     DC.B    'sys> Command Error, ', $00   ; error message
msg4        DC.B    'CMD> ', $00                  ; command prompt

;*******************************************************
; interrupt vector section

;            ORG     $3FEA            ; Timer channel 2 interrupt vector setup, HC12 board
            ORG     $FFEA            ; Timer channel 2 interrupt vector setup, simulator
            DC.W    oc2isr

;*******************************************************
; code section
            ORG     $3100
Entry
            LDS     #Entry           ; initialize the stack pointer

            ldd     $0001       ; Set SCI Baud Register = $0001 => 2M baud at 24MHz (for simulation)
;            ldd    #$0002       ; Set SCI Baud Register = $0002 => 1M baud at 24MHz
;            ldd    #$000D       ; Set SCI Baud Register = $000D => 115200 baud at 24MHz
;            ldd    #$009C       ; Set SCI Baud Register = $009C => 9600 baud at 24MHz
            std    SCIBDH       ; SCI port baud rate change

            ldaa   #$0C         ; Enable SCI port Tx and Rx units
            staa   SCICR2       ; disable SCI interrupts

            LDAA   #%11111111   ; Set PORTB bit 0,1,2,3,4,5,6,7
            STAA   DDRB         ; as output
            STAA   PORTB        ; set all bits of PORTB, initialize


            ldx     #msg1            ; print the first message, 'Hello'
            jsr     printmsg
            jsr     nextline
            ldx     #msg2            ; print the second message, user instruction
            jsr     printmsg

            ldaa    #$31             ; initialize error counter with '1' ($31)
            staa    cerror

            ldx     #cbuf            ; set up initial command
            ldaa    #'r'             ; start with 'run' command
            staa    1,x+
            ldaa    #'u'
            staa    1,x+
            ldaa    #'n'
            staa    1,x+
            ldaa    #CR              ; command buffer now filled with 4 characters
            staa    1,x+             ;   including the Enter key
            ldaa    #4
            staa    cbufct

looop       jsr   NewCommand         ; check command buffer for a new command entered.

loop2       jsr   UpDisplay          ; update display, each 1 second 

            jsr   getchar            ; user may enter command
            cmpa  #0                 ;  save characters if typed
            beq   loop2

            staa  1,x+               ; save the user input character
            inc   cbufct
            jsr   putchar            ; echo print, displayed on the terminal window

            cmpa  #CR
            bne   loop3              ; if Enter/Return key is pressed, scroll up the
            bra   looop              ; and evaluate the new command entered so far.

loop3       ldaa  cbufct             ; if user typed 5 characters, it is the maximum, stop command
            cmpa  #5                 ;   is in error, ignore the input and continue timer
            blo   loop2
            bra   looop


;*******************************************************
;subroutine section below

;***********Timer OC2 interrupt service routine***************
oc2isr
            ldd   #3000              ; 125usec with (24MHz/1 clock)
            addd  TC2H               ;    for next interrupt
            std   TC2H               ; 
            bset  TFLG1,%00000100    ; clear timer CH2 interrupt flag, not needed if fast clear enabled
            ldx   ctr125u            ; 125uSec => 8.000KHz rate
            inx
            stx   ctr125u            ; every time the RTI occur, increase interrupt count
oc2done     RTI
;***********end of Timer OC2 interrupt service routine********

;***************Update Display**********************
;* Program: Update count down timer display if 1 second is up
;* Input:   ctr2p5m variable
;* Output:  timer display on the Hyper Terminal
;* Registers modified: CCR
;* Algorithm:
;    Check for 1 second passed
;      if not 1 second yet, just pass
;      if 1 second has reached, then update display, and reset ctr2p5m interrupt counter
;**********************************************
UpDisplay
            psha
            pshx
            ldx   ctr125u          ; check for 1 sec.  For Simulation, reduce number for faster tic
            cpx   #intct           ; 125usec * 8000 = 1 sec  0 to 7999 count is 8000
            blo   UpDone           ; if interrupt count less than 8000, then not 1 sec yet.
                                   ;    no need to update display.

            ldx   #0               ; interrupt counter reached 8000 count, 1 sec up now
            stx   ctr125u          ; clear the interrupt count to 0, for the next 1 sec.


; only for the simulator terminal and 7 seg. display
            ldaa  times            ; load time, in second, kept in bit 3 to 0
            lsla                   ; left shift 4 times for 7 seg. display
            lsla
            lsla
            lsla
            staa  PORTB        

            dec   times            ; update time for next time display
            bpl   UpDone           ; if -1 < times < 10 then OK, if not, reset times to 9 to restart
            ldaa  #9               ; reset because count display down to 0
            staa  times

UpDone      pulx
            pula
            rts
;***************end of Update Display***************

;***************New Command Process*******************************
;* Program: Check for 'run' command or 'stop' command.
;* Input:   Command buffer filled with characters, and the command buffer character count
;*             cbuf, cbufct
;* Output:  Display on Hyper Terminal, count down characters 9876543210 displayed each 1 second
;*             continue repeat unless 'stop' command.
;*          When a command is issued, the count display reset and always starts with 9.
;*          Interrupt start with CLI for 'run' command, interrupt stops with SEI for 'stop' command.
;*          When a new command is entered, cound time always reset to 9, command buffer cleared, 
;*             print error message if error.  And X register pointing at the begining of 
;*             the command buffer.
;* Registers modified: X, CCR
;* Algorithm:
;*     check 'run' or 'stop' command, and start or stop the interrupt
;*     print error message if error
;*     clear command buffer
;*     Please see the flow chart.
;* 
;**********************************************
NewCommand
            psha

            ldx   #cbuf            ; read command buffer, see if 'run' or 'stop' command entered
            ldaa  1,x+             ;    each command is followed by an enter key
            cmpa  #'r'
            beq   ckrun2           ; check for 'r' or 's', else error
            cmpa  #'s'
            bne   CNerror

ckstop2     ldaa  1,x+             ; check if 'stop' command
            cmpa  #'t'             ;    's' and 'top' with enter key CR.
            bne   CNerror
            ldaa  1,x+
            cmpa  #'o'
            bne   CNerror
            ldaa  1,x+
            cmpa  #'p'
            bne   CNerror
            ldaa  1,x+
            cmpa  #CR
            bne   CNerror

CNoff       SEI                    ; it is 'stop' command, turn off interrupt
            bra   CNexit

ckrun2      ldaa  1,x+             ; check if 'run' command
            cmpa  #'u'             ;    'r' and 'un' with enter key CR.
            bne   CNerror
            ldaa  1,x+
            cmpa  #'n'
            bne   CNerror
            ldaa  1,x+
            cmpa  #CR
            bne   CNerror

CNonn                                ; it is 'run' command, set up and turn on interrupt
            ldx     #intct-1            ; 125uSec => 8.000KHz
            stx     ctr125u          ; initialize interrupt counter with 7998, to begin soon.

            ldaa    #9
            staa    times            ; initialize 10 second timer with #9

            jsr     StartTimer2oc
          
            bra     CNexit


CNerror
            jsr   nextline         ; scroll up the screen
            ldx   #msg3err         ; print the 'Command Error' message
            jsr   printmsg
            ldaa  cerror
            jsr   putchar          ; print the error count
            inca
            cmpa  #$3A             ; error count from 1 to 9 only
            bne   CNerrdone
            ldaa  #$31
CNerrdone   staa  cerror            


CNexit
            jsr   nextline         ; scroll up the screen
            ldx   #msg4            ; print the prompt CMD> to terminal
            jsr   printmsg


            clr   cbufct           ; reset command buffer
            ldx   #cbuf

            pula
            rts
;***************end of New Command Process***************

;***************StartTimer2oc************************
;* Program: Start the timer interrupt, timer channel 2 output compare
;* Input:   Constants - channel 2 output compare, 125usec at 24MHz
;* Output:  None, only the timer interrupt
;* Registers modified: D used and CCR modified
;* Algorithm:
;             initialize TIOS, TIE, TSCR1, TSCR2, TC2H, and TFLG1
;**********************************************
StartTimer2oc
            PSHD
            LDAA   #%00000100
            STAA   TIOS              ; set CH2 Output Compare
            STAA   TIE               ; set CH2 interrupt Enable
            LDAA   #%10000000        ; enable timer, Fast Flag Clear not set
            STAA   TSCR1
            LDAA   #%00000000        ; TOI Off, TCRE Off, TCLK = BCLK/1
            STAA   TSCR2             ;   not needed if started from reset

            LDD     #3000            ; 125usec with (24MHz/1 clock)
            ADDD    TCNTH            ;    for first interrupt
            STD     TC2H             ; 

            PULD
            BSET   TFLG1,%00000100   ; initial Timer CH2 interrupt flag Clear, not needed if fast clear set
            CLI                      ; enable interrupt
            RTS
;***************end of StartTimer2oc*****************


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
NULL            equ     $00
printmsg        psha                   ;Save registers
                pshx
printmsgloop    ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
                cmpa    #NULL
                beq     printmsgdone   ;end of strint yet?
                bsr     putchar        ;if not, print character and do next
                bra     printmsgloop
printmsgdone    pulx 
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
putchar     brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
            staa  SCIDRL                      ; send a character
            rts
;***************end of putchar*****************

;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
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

getchar     brclr SCISR1,#%00100000,getchar7
            ldaa  SCIDRL
            rts
getchar7    clra
            rts
;****************end of getchar**************** 

;****************nextline**********************
nextline    ldaa  #CR              ; move the cursor to beginning of the line
            jsr   putchar          ;   Cariage Return/Enter key
            ldaa  #LF              ; move the cursor to next line, Line Feed
            jsr   putchar
            rts
;****************end of nextline***************


            END                    ; this is end of assembly source file
                                   ; lines below are ignored - not assembled
