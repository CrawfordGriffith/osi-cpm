
        TITLE 'User BIOS and Disk BIOS Links - CP/M 2.0 - OSI C3-C'
;
; (C) Copyright 1980 by Lifeboat Associates
;
;       RECORD OF CHANGES
;         DATE          DESCRIPTION
;       9/15/80         Final changes to user bios, Phillip Woellhof
;       9/18/80         Changes to CONIN routine.
;       10/21/80        Change label CA10X to first port address
;                       CA-10 board - cf02 hex
;                       Change to TTYOUT routine for control S.
;
        MACLIB  Z80

MSIZE   EQU     49

BIAS    EQU     (MSIZE-20)*1024
CCP     EQU     3400H+BIAS
BIOS    EQU     CCP+1600H

        IF      MSIZE GT 45
ORGBIOS EQU     0D000H          ;location of disk BIOS
        ELSE
ORGBIOS EQU     0B000H          ;location of disk BIOS
        ENDIF

; Disk BIOS entry points

WBOOTX  EQU     ORGBIOS+3
HOME    EQU     ORGBIOS+(8*3)
SELDSK  EQU     ORGBIOS+(9*3)
SETTRK  EQU     ORGBIOS+(10*3)
SETSEC  EQU     ORGBIOS+(11*3)
SETDMA  EQU     ORGBIOS+(12*3)
READ    EQU     ORGBIOS+(13*3)
WRITE   EQU     ORGBIOS+(14*3)
SECTRAN EQU     ORGBIOS+(16*3)
FLUSH   EQU     ORGBIOS+(18*3)
        PAGE
;       EQUATES FOR CONSOLE PORT ACIA
CRST    EQU     0F700H  ;RESET ADDRESS
CRST1   EQU     3       ;MASTER RESET
CRST2   EQU     10110001B       ;8 BIT WORD LENGTH
;               2 STOP BITS CLOCK DEVIDED BY 16
TTYISA  EQU     0FC00H  ;INPUT STATUS ADDRESS
TTYISB  EQU     1       ;INPUT STATUS BIT
TTYOSA  EQU     0FC00H  ;OUTPUT STATUS ADDRESS
TTYOSB  EQU     2       ;OUTPUT STATUS BIT
TTYIDA  EQU     0FC01H  ;INPUT DATA ADDRESS
TTYODA  EQU     0FC01H  ;OUTPUT DATA ADDRESS
CA6ISA  EQU     0FB05H  ;INPUT STATUS ADDRESS
CA6OSA  EQU     0FB05H  ;OUTPUT STATUS ADDRESS
CA6SR   EQU     0FB07H  ;INPUT STATUS REGISTER
CA6IDA  EQU     0FB03H  ;INPUT DATA ADDRESS
CA6ODA  EQU     0FB04H  ;OUTPUT DATA ADDRESS
CSTOP   EQU     13H     ;STOP CHAR
CSTRT   EQU     11H     ;START CHAR
CA9OSA  EQU     0F400H  ;LIST STATUS ADDRESS
CA9OSB  EQU     1       ;OUTPUT STATUS BIT
CA9ODA  EQU     0F402H  ;OUTPUT DATA ADDRESS
CA9SR   EQU     0F420H  ;STATUS REGISTER ?
IOBYTE  EQU     3

;       Jump vector for individual routines

        ORG     BIOS
        JMP     BOOT    ;FOR COLD START LOADER
        JMP     WBOOT   ;FOR WARM START
        JMP     CONST   ;TEST CONSOLE STATUS
        JMP     CONIN   ;CCONSOLE INPUT RTN.
        JMP     CONOUT  ;CONSOLE OUTPUT RTN.
        JMP     LIST    ;LIST OUTPUT
        JMP     PUNCH   ;PUNCH OUTPUT
        JMP     READER  ;READER INPUT
        JMP     HOME    ;HOME THE DISK
        JMP     SELDSK  ;SELECT DISK DRIVE
        JMP     SETTRK  ;SET TRACK NUMBER
        JMP     SETSEC  ;SET SECTOR
        JMP     SETDMA  ;SET DISK STARTING ADDRESS
        JMP     READ    ;READ SELECTED SECTOR
        JMP     WRITE   ;WRITE THE SELECTED SECTOR
        JMP     LISTST  ;LIST STATUS RTN.
        JMP     SECTRAN ;SECTOR TRANSLATE RTN.

; User Cold Start Initialization routine - called by
; disk BIOS cold start.  Should end with a RET

BOOT    MVI     A,080H  ;Initial setting of IOBYTE
        STA     IOBYTE
        MVI     A,000H  ;Initialize Centronics Printer
        STA     CA9OSA+1
        STA     CA9OSA
        STA     CA9OSA+3
        MVI     A,0FFH
        STA     CA9ODA
        MVI     A,004H
        STA     CA9OSA+1
        STA     CA9OSA+3
;
        LHLD    CA10X   ;Initialize one CA-10X port
        MVI     A,003H
        MOV     M,A
        MVI     A,051H
        MOV     M,A
;
        LDA     0FB06H  ;Initialize CA-6 port
        MVI     A,0FFH
        STA     CA6OSA  ;Eight bits, 2 stop, no parity
;
        RET             ;return to cold boot routine


WBOOT   JMP     WBOOTX  ;just go to Disk BIOS warm start
;
;       CONSOLE STATUS INPUT
;
CONST   LDA     IOBYTE
        ANI     003H
        JZ      TTYSTI
        CPI     001H
        JZ      CA10STI
        CPI     003H
        JZ      CA6STI
        JMP     TTYSTI
;
;       CONSOLE INPUT
;
CONIN   CALL    FLUSH
        LDA     IOBYTE
        ANI     003H
        JZ      TTYIN
        CPI     001H
        JZ      CA10IN
        CPI     003H
        JZ      CA6IN
        JMP     TTYIN
;
;       CONSOLE OUTPUT
;
CONOUT  LDA     IOBYTE
        ANI     003H
        JZ      TTYOUT
        CPI     001H
        JZ      CA10OUT
        CPI     003H
        JZ      CA6OUT
        JMP     TTYOUT
;
;       LIST OUTPUT STATUS
;
LISTST  LDA     IOBYTE
        ANI     0C0H
        RZ
        CPI     040H
        JZ      CA10STO
        CPI     080H
        JZ      CA9STO
        JMP     CA6STO
;
;       LIST OUTPUT ROUTINE
;
LIST    LDA     IOBYTE
        ANI     0C0H
        JZ      TTYOUT
        CPI     040H
        JZ      CA10OUT
        CPI     080H
        JZ      CA9OUT
        JMP     CA6OUT
;
;       PUNCH DEVICE
;
PUNCH   LDA     IOBYTE
        ANI     030H
        JZ      TTYOUT
        CPI     010H
        JZ      CA10OUT
        CPI     020H
        JZ      CA6OUT
        JMP     TTYOUT
;
;       READER DEVICE
;
READER  LDA     IOBYTE
        ANI     00CH
        JZ      TTYIN
        CPI     004H
        JZ      CA10IN
        CPI     008H
        JZ      CA6IN
        JMP     TTYIN
;
TTYSTI  LDA     TTYISA  ;console status check
        ANI     TTYISB
        RZ              ;return 0 if zero
        MVI     A,0FFH  ;else return 0FFH
        RET
;
TTYIN   CALL    TTYSTI  ;console read
        ADI     01H
        JRNZ    TTYIN   ;LOOP TILL READY
        LDA     TTYIDA  ;GET DATA
        ANI     7FH     ;STRIP PARITY BIT
        RET
;
TTYOUT: ;CONSOLE CHARACTER OUTPUT FROM REGISTER C
TTYOUTS CALL    TTYSTI  ;Console status input
        ADI     01H
        JRNZ    TTYOT2
        LDA     TTYIDA  ;IF STOP CHAR IS TYPED
        CPI     CSTOP   ;THEN WAIT
        JRNZ    TTYOT2  ;IN LOOP UNTIL START CHAR
TTYOTW  CALL    TTYSTI  ;WAIT FOR INPUT OF ANY CHAR
        ADI     01H
        JRNZ    TTYOTW
TTYOT2  LDA     TTYOSA  ;CHECK CONSOLE OUTPUT
        ANI     TTYOSB  ;STATUS AND LOOP
        JRZ     TTYOUTS ;UNTIL  READY
        MOV     A,C     ;GET TO ACCUMULATOR
        STA     TTYODA
        RET
;
CA9OUT:
        CALL    CA9STO
        ADI     01H
        JRNZ    CA9OUT
        MOV     A,C     ;CHARACTER TO REGISTER A
        STA     CA9ODA
        LDA     CA9SR
        RET             ;NULL SUBROUTINE
;
CA9STO: ;RETURN LIST STATUS (0 IF NOT READY, 1 IF READY)
        LDA     CA9OSA  ;LIST STATUS PORT
        RAR
        JC      CA9STO2
        MVI     A,0FFH  ;READY !
        RET
CA9STO2 XRA     A       ;Return with zero when not ready
        RET
;
;       CA-10X STATUS INPUT ROUTINE
;
CA10STI LHLD    CA10X           ;GET PORT INDEX
CA10ST2 MOV     A,M
        ANI     001H
        RZ
        MVI     A,0FFH
        RET
;
;       CA-10X INPUT ROUTINE
;
CA10IN  CALL    CA10STI
        ADI     01H
        JRNZ    CA10IN
        INX     H
        MOV     A,M
        ANI     07FH
        RET
;
;       CA-10X OUTPUT STATUS ROUTINE
;
CA10STO LHLD    CA10X           ;GET PORT INDEX
CA10ST3 MOV     A,M
        ANI     002H
        RZ
        MVI     A,0FFH
        RET
;
;       CA-10X OUTPUT ROUTINE
;
CA10OUT CALL    CA10STO
        ADI     01H
        JRNZ    CA10OUT
        INX     H               ;DATA PORT
        MOV     A,C
        MOV     M,A
        RET
;
CA10X   DW      0CF00H
;
;       CA-6 INPUT STATUS ROUTINE
;
CA6STI  LDA     CA6ISA
        XTHL
        XTHL
        ANI     001H
        RZ              ;RETURN ZERO IF NOTHING THERE
        MVI     A,0FFH
        RET
;
;       CA-6 INPUT ROUTINE
;
CA6IN   CALL    CA6STI
        ADI     01H
        JRNZ    CA6IN
        LDA     CA6IDA
        ANI     07FH    ;STRIP PARITY BIT
        RET
;
;       CA-6 OUTPUT STATUS ROUTINE
;
CA6STO  LDA     CA6OSA
        XTHL
        XTHL
        ANI     080H
        RZ              ;RETURN ZERO IF NOT READY
        MVI     A,0FFH
        RET
;
;       CA-6 OUTPUT ROUTINE
;
CA6OUT  CALL    CA6STO
        ADI     01H
        JRNZ    CA6OUT
        MOV     A,C
        STA     CA6ODA
        RET
        END
