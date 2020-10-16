TYPE ZBIOS.ASM
; Z-80 BIOS FOR CP/M SYSTEM
;
; THIS CODE LINKS TO 6502 SUBROUTINES TO DO ALL DISK I/O
; ALL TTY AND LPT I/O IS DONE WITHOUT SWITCHING PROCESSORS
;
; MEM  7/78
;
; EQUATES
;
CCP     EQU     0A900H
;
; VECTOR TABLE
;
        ORG     0BE00H
        CALL    LINK    ; 1 COLD BOOT
        CALL    LINK    ; 2 WARM BOOT
        JMP     CONST   ; 3 CONSOLE TEST
        JMP     CONIN   ; 4 CONSOLE INPUT
        JMP     CONOUT  ; 5 CONSOLE OUTPUT
        JMP     LIST    ; 6 LIST OUTPUT
        JMP     CA10OU  ; 7 PUNCH OUTPUT (16-PORT)
        JMP     CA10IN  ; 8 READER INPUT (16-PORT)
        CALL    LINK    ; 9 HOME HEAD
        CALL    LINK    ;10 SELECT DISK
        CALL    LINK    ;11 SELECT TRACK
        CALL    LINK    ;12 SELECT SECTOR
        CALL    LINK    ;13 SET DMA ADDRESS
        CALL    LINK    ;14 READ SECTOR
        CALL    LINK    ;15 WRITE SECTOR
;
; LINK SUBROUTINE SAVES STATE, AND CALLS 6502 SUBROUTINE
; VIA A VECTOR TABLE.
;
LINK:   MOV     H,B
        MOV     L,C
        SHLD    0EE22H
        STA     0EE21H
;
        POP     D               ;CALCULATE RETURN ADDRESS
        LXI     H,0             ;SAVE SP
        DAD     SP
        SHLD    0EE34H
        XCHG
        MVI     E,3
        MOV     A,L
        SUB     E
        MOV     L,A
        MVI     H,0D0H
        SHLD    0F2FCH          ;SET UP 6502 RESET VECTOR
        NOP
        NOP
        NOP
        NOP
        NOP
        MVI     A,0FFH          ;SWITCH PROCESSORS
        MVI     B,0CFH
        STA     0F700H
        MOV     A,B
        STA     0F700H
SLEEP:  JMP     SLEEP           ;WAIT TILL PROCESSORS SWITCH
;
; ENTRY POINT FROM 6502 TO RETURN FROM SUBROUTINE
;
RETR:   NOP
        NOP
        NOP
        NOP
        NOP
        MVI     A,0C3H          ;SET UP WARM START
        STA     0
        LXI     H,0BE03H
        SHLD    1
        LHLD    0EE22H          ;RESTORE STATE
        MOV     B,H
        MOV     C,L
        LHLD    0EE34H
        SPHL
        LDA     0EE21H
        CPI     0               ;SET UP CONDITION CODES
        RET
;
; ENTRY POINT FROM 6502 TO JUMP TO CCP
;
VCCP:   NOP
        NOP
        NOP
        NOP
        NOP
        MVI     A,0C3H          ;SET UP WARM START
        STA     0
        LXI     H,0BE03H
        SHLD    1
        LHLD    0EE22H          ;RESTORE STATE
        MOV     B,H
        MOV     C,L
        LHLD    0EE34H
        SPHL
        LDA     0EE21H
        JMP     CCP
;
; DEVICE DRIVERS
;
; TTY READY
;
        ORG     0BF00H
CONST:  LDA     0FC00H
        RAR
        JC      NO
        MVI     A,0
        RET
NO:     MVI     A,0FFH
        RET
;
; TTY INPUT
;
CONIN:  LDA     0FC00H
        RAR
        JNC     CONIN
        LDA     0FC01H
        ANI     7FH
        RET
;
; TTY OUTPUT
;
CONOUT: PUSH    PSW
        LDA     0FC00H
        RAR
        RAR
        JNC     CONOUT+1
        MOV     A,C
        STA     0FC01H
        POP     PSW
        RET
;
; LPT OUTPUT
;
LIST:   PUSH    PSW
        LDA     0F400H
        RAR
        JC      LIST+1
        MOV     A,C
        STA     0F402H
        LDA     0F420H
        POP     PSW
        RET
;
; CA-10X INPUT
;
CA10IN  LHLD    CA10X           ;GET PORT INDEX
CA10I1  MOV     A,M
        RAR
        JNC     CA10I1
        INX     H
        MOV     A,M
        ANI     07FH
        RET
;
; CA-10X OUTPUT
;
CA10OU  LHLD    CA10X
        PUSH    PSW
CA10O1  MOV     A,M
        RAR
        RAR
        JNC     CA10O1
        INX     H
        MOV     A,C
        MOV     M,A
        POP     PSW
        RET
;
CA10X   DW      0CF00H
;
        END
        END

A>