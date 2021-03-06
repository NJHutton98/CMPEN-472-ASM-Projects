***********************************************************************
*
* Title:  StarFill
*
* Objective:  CSE472 Homework 1
*
* Revision:   v1.0
*
* Date:       Jan. 22, 2021
*
* Programmer: Nicholas Hutton, (original: Kyusun Choi)
*
* Company:  The Pennsylvania State University
* Electrical Engineering and Computer Science
*
* Algorithm:  Simple while-loop demo of HCS12 assembly program
*
* Register use: A accumulator:  char data to be filled
*               B accumulator:  counter, num of filled locations
*               X register:     mem addr ptr
*
* Memory use: RAM locs from $3000 to $30CA
*
* Input: Params hardcoded in the prgm
*
* Output: Data filled in memory locations, from $3000 to $30C9 changed
*
* Observation: This prgm is designed for instruction purpose
* This prgm can be used as a "loop" template
*
* Note: This is a good example of program comments
* All HW prgms MUST have comments similar
* to this HW1 Prgm. So, please use this comment
* format for all your subsequent CMPEN472 HWs.
*
* Adding more explanations and comments helps you
* and others to understand your program later.
*
* Comments: This prgm is developed and simulated using CodeWarrior IDE.
*
***********************************************************************
* Parameter Declaration Section
*
* Export Symbols
        XDEF      pgstart ; export "pgstart" symbol
        ABSENTRY  pgstart ; for assembly entry point
* Symbols and Macros
PORTA   EQU       $0000   ; i/o port addrs
PORTB   EQU       $0001   
DDRA    EQU       $0002
DDRB    EQU       $0003
***********************************************************************
* Data Section
*
        ORG       $3000   ;reserved mem starting addr
here    DS.B      $CA     ;202 memory locations reserved
count   DC.B      $CA     ;constant, star count = 202
*
***********************************************************************
* Program Section
*
        ORG       $3100   ;Prgm start addr, in RAM
pgstart ldaa      #'*'    ;load '*' into accumulator A
        ldab      count   ;load star counter into B
        ldx       #here   ;load addr ptr into X
loop    staa      0,x     ;put a star
        inx               ;point to next location
        decb              ;decrease counter
        bne       loop    ;if not done, repeat
done    bra       done    ;task finished,
                          ; do nothing
*
* Add any subroutines here
*
        END               ;last line of a file
       