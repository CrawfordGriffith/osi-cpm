
;
;
; CHANGE HISTORY
;
;
;       THE FOLLOWING ROUTINES MUST BE PROVIDED FOR PROPER OPERATION
;       OF ASCOM. THE 16 JUMP INSTRUCTIONS AT THE START OF THE 
;       PROGRAM AREA AFTER THE JUMP TO ASCOM'S COMMAND PROCESSOR 
;       ENTRY POINT MUST BE MAINTAINED AS SHOWN, ALTHOUGH THE 
;       ROUTINES THAT THE 14 JUMPS BRANCH TO SHOULD BE MODIFIED 
;       FOR THE PARTICULAR SERIAL PORT TO BE USED. THE MODEM 
;       ROUTINES DO NOT HAVE TO PROTECT ANY REGISTERS,
;       BUT MAY HAVE TO RETURN REGISTER OR FLAG VALUES TO ASCOM.
;
;
;
;
;       SET UP FOR OHIO SCIENTIFIC C3-OEM
;       
;       SYSTEM ALSO CONTAINS DRIVERS FOR THE HAYES SMARTMODEM.
;
;
FALSE   EQU     0
TRUE    EQU     NOT FALSE
;
INITC1  EQU     03              ;1ST MODEM INITIALIZATION CODE
INITC2  EQU     0B1H            ;2ND MODEM INITIALIZATION CODE
;
MODCTLP EQU     0FB00H          ;STATUS PORT
MODDATP EQU     0FB01H          ;DATA PORT
;
MODSNDB EQU     2               ;BIT TO TEST FOR SEND
MODSNDR EQU     2               ;VALUE WHEN READY
MODRCVB EQU     1               ;BIT TO TEST FOR RECEIVE
MODRCVR EQU     1               ;VALUE WHEN READY
;
;       MISCELLANEOUS EQUATES
CR      EQU     13
LF      EQU     10
ESC     EQU     27
BDOS    EQU     5               ;ADDRESS OF ENTRY TO DOS        
CNSTAT  EQU     11              ;FUNCTION NUMBER FOR CONSOLE STATUS
CNIN    EQU     1               ;FUNCTION NUMBER FOR CONSOLE INPUT
;
        ORG     103H
;
;*****************************************************************
;                                                                *
;               INTERFACE JUMP TABLE (IJT)                       *
;                                                                *
;*****************************************************************
;
;       THE FOLLOWING 16 JUMP INSTRUCTIONS MUST BE PLACED HERE 
;       STARTING AT LOCATION 103H.
;
        JMP     COMINI  ;JUMP TO COMMUNICATIONS INITIALIZE
        JMP     COMSTA  ;JUMP TO MODEM STATUS
        JMP     COMINP  ;JUMP TO MODEM INPUT
        JMP     COMOUT  ;JUMP TO MODEM OUTPUT
        JMP     COMBRK  ;JUMP TO MODEM BREAK ROUTINE
        JMP     COMDIL  ;JUMP TO AUTO DIAL ROUTINE
        JMP     COMANS  ;JUMP TO AUTO ANSWER ROUTINE
        JMP     COMHNG  ;JUMP TO HANGUP ROUTINE
        JMP     BEFDMP  ;JUMP TO ROUTINE BEFORE CAPTURE DUMPING
        JMP     AFTDMP  ;JUMP TO ROUTINE AFTER CAPTURE DUMPED
        JMP     INIT    ;JUMP TO USER INITIALIZATION
        JMP     EXIT    ;JUMP TO USER EXIT
        JMP     USER1   ;JUMP TO FIRST USER WRITTEN ROUTINE
        JMP     USER2   ;JUMP TO SECOND USER WRITTEN ROUTINE
        JMP     USER3   ;JUMP TO THIRD USER WRITTEN ROUTINE
        JMP     USER4   ;JUMP TO FOURTH USER WRITTEN ROUTINE
;
;*****************************************************************
;                                                                *
;                      BAUD RATE TABLE                           *      
;                                                                *
;*****************************************************************
;
;       BAUD VALUES ALLOWED- SOME NUMBER CONTAINED IN THIS TABLE
;       MUST MATCH THE NUMBER ENTERED BY THE OPERATOR IN A "BAUD" 
;       COMMAND IN ORDER TO HAVE A "BAUDSL" NUMBER CHOSEN. THE 
;       DECIMAL NUMBER ENTERED BY THE OPERATOR WILL BE CONVERTED 
;       TO A BINARY INTEGER AND COMPARED AGAINST ALL THE ENTRIES 
;       IN THIS TABLE. IF NO MATCH IS FOUND, AN "ARGUMENT ERROR" 
;       WILL RESULT. IF A MATCH IS FOUND, THE NUMBER (0-15) WITHIN
;       THE TABLE CORRESPONDING TO THE POSITION OF THE MATCHED ENTRY
;       WILL BE PLACE AT LOCATION "BAUDSL".
;
BAUDRT:
        DW      110
        DW      300
        DW      600
        DW      1200
        DW      2400
        DW      4800
        DW      9600
        DW      19200
        DW      9999    ;DUMMY VALUES
        DW      9999
        DW      9999    
        DW      9999
        DW      9999    
        DW      9999    
        DW      9999    
        DW      9999    
;
BAUDSL: DB      0               ;THIS ENTRY MUST BE HERE--WHEN 
                                ; MODEM INIT ROUTINE IS CALLED, 
                                ; IT WILL CONTAIN A NUMBER FROM 
                                ; 0 TO 15 CORRESPONDING TO THE 
                                ; SELECTED BAUD RATE
;
;*****************************************************************
;                                                                *
;                   USER SPECIFIED MESSAGES                      *
;                                                                *
;*****************************************************************
;
SIGN:   DW      USIGN           ;USER SIGNON STRING ADDRESS
USHELP: DW      UHELP           ;USER HELP STRING ADDRESS
;
;       END OF AREA THAT MUST CONTAIN THE EXACT NUMBER OF BYTES
;       NECESSARY FOR THE ABOVE INFORMATION.
;
;=================================================================
;
;       USER STRINGS - MUST HAVE A DOLLAR SIGN AS THE LAST
;                       CHARACTER IN THE STRING.
;
;
;       USER SIGNON STRING TO BE DISPLAYED FOLLOWING ASCOM'S 
;       NORMAL SIGNON
;
USIGN:
        DB      ESC,28          ;CLEAR SCREEN
        DB      ESC,17,114,116  ;GOTO X=18, Y=20
        DB      ESC,31          ;HI INTENSITY
        DB      'ASCOM customized for OSI C3-OEM and SMARTMODEM'
        DB      CR,LF
        DB      ESC,25          ;background follows
        DB      '$'
;
;       USER HELP STRING WILL BE DISPLAYED FOR USERHELP COMMAND 
;
UHELP:  DB      CR,LF,'USER1 will redial the previous number if'
        DB      CR,LF,'      no connection was made.'
        DB      CR,LF,'USER2 will cancel auto-answer mode.'
        DB      CR,LF,'USER3-4 are not implemented',CR,LF,'$'
;
;*****************************************************************
;                                                                *
;                   SIO CONTROL ROUTINES                         *
;                    (NOT IMPLEMENTED)                           *
;*****************************************************************
;
;       The baud value table is used by the customized
;       COMINI routine.  This table is an offset pointer into
;       the SIOCTC table. The SIOCTC table contains values that must be sent
;       to the various output ports to set the communications 
;       BAUD RATE for that particular session.
;
BAUDVL:
        DB      00      
        DB      02      
        DB      04
        DB      06
        DB      08
        DB      10
        DB      12
        DB      14
        DB      00
        DB      00
        DB      00
        DB      00
        DB      00
        DB      00
        DB      00
        DB      00
;
SIOCTC:  

;
;       MODEM INITIALIZATION ROUTINE-- THIS ROUTINE DOES
;       EVERYTHING NECESSARY TO PREPARE THE SERIAL PORT FOR 
;       COMMUNICATIONS.
;
COMINI:
        MVI     A,INITC1
        STA     MODCTLP
        MVI     A,INITC2
        STA     MODCTLP
        CALL    SETUP
        RET
;
;       MODEM STATUS ROUTINE- THIS ROUTINE MUST RETURN WITH THE 
;       ZERO FLAG ON IF NO RECEIVED CHARACTER FROM MODEM IS 
;       AVAILABLE OR OFF IF A CHARACTER IS READY.
;
;       For this implementation, there is a possibility that
;       there is a character buffered in the autodump buffer
;       used to prevent data loss during CAPTURE with
;       AUTODUMP ON.
;
COMSTA:
        LDA     BUFCNT          ;GET COUNT IN AUTODUMP BUFFER
        ORA     A               ;TEST FOR NON-ZERO
        RNZ                     ;RETURN IF SO, CHARACTER THERE
        LDA     MODCTLP         ;GET STATUS
        ANI     MODRCVB         ;SEE IF CHARACTER READY, SET Z
        RET                     ; FLAG ACCORDINGLY AND RETURN
;
;       MODEM OUTPUT ROUTINE-THIS ROUTINE SHOULD SEND THE 
;       CHARACTER CONTAINED IN REGISTER C TO THE MODEM 
;       TRANSMITTER. IT SHOULD FIRST BE SURE THAT THE MODEM IS 
;       READY TO TRANSMIT, AS THIS CHECK IS NOT DONE ELSEWHERE.
;
;       Check output char against KEYTRAN table. If equal, output
;        all following codes until NUL code, then RET. If not equal,
;        move past next NUL code, then continue checking.
;        If end of table reached (double NUL), output original code,
;        then RET.
;
COMS    EQU     FALSE           ;turn ON COMS translations
;
KEYTRAN:
         if COMS                ;KEYTRAN table for IS&DP COMS system
        DB      06h,1Bh,4Fh,53h,0       ;PA1
        DB      88h,1Bh,4Fh,50h,0       ;PF1
        DB      09h,1Bh,4Fh,51h,0       ;PF2
        DB      0Ah,1Bh,4Fh,52h,0       ;PF3
        DB      8Bh,1Bh,4Fh,53h,0       ;PF4
        DB      0Ch,1Bh,4Fh,54h,0       ;PF5
        DB      12h,0Ah,0               ;LINEFEED
        DB      11h,1Bh,1Bh,5Bh,44h,0   ;ERASE EOF
        DB      93h,2Eh,0               ;INSERT char
        DB      14h,7Fh,0               ;DELETE char
        DB      95h,1Bh,1Bh,5Bh,43h,0   ;TAB
        DB      96h,1Bh,1Bh,5Bh,44h,0   ;back TAB
        DB      17h,1Bh,5Bh,41h,0       ;cursor UP
        DB      18h,1Bh,5Bh,44h,0       ;cursor LEFT
        DB      99h,1Bh,5Bh,43h,0       ;cursor RIGHT
        DB      9Ah,1Bh,5Bh,42h,0       ;cursor DOWN
         endif
;
        DB      0               ;END of KEYTRAN table
;
COMOUT:
        PUSH    H               ;save (HL)
        LXI     H,KEYTRAN-1     ;addr of key translation table -1
COMOUT1 INX     H
        MOV     A,M
        CPI     00              ;end of table?
        JZ      COMOUT3         ; yes
        CMP     C               ;equal output char?
        JZ      COMOUT4         ; yes
COMOUT2 INX     H
        MOV     A,M             ;skip past next NUL
        CPI     00
        JZ      COMOUT1         
        JMP     COMOUT2
COMOUT3:
        CALL    COMOUT$C        ;output original char
        POP     H               ;restore (HL)
        RET
COMOUT4:                        ;output substitute chars
        PUSH    B               ;save C (original char)
COMOUT5 INX     H
        MOV     A,M
        CPI     00              ;end of string?
        JZ      COMOUT6         ; yes
        ORA     A               ;set PARITY flag
        JPE     COMOUT5A        ;char parity even?
        XRI     80h             ; no, set even parity
COMOUT5A MOV    C,A
        CALL    COMOUT$C        ;output 1 char
        JMP     COMOUT5
COMOUT6 POP     B               ;restore original output char
        POP     H               ;restore (HL)
        RET
;
COMOUT$C:
        LDA     MODCTLP         ;GET STATUS
        ANI     MODSNDB         ;transmitter ready?
        CPI     MODSNDR
        JNZ     COMOUT$C        ; no, wait
        MOV     A,C             ;move char to A
        STA     MODDATP         ;OUTPUT CHAR
        RET
;
;
;COMOUT:
;       IN      STATUS          ;GET SIO STATUS
;       ANI     ALLSENT         ;CHECK FOR TRANSMITTER READY
;       JZ      COMOUT          ; JUMP IF NOT TO WAIT
;       MOV     A,C             ;GET CHARACTER TO A
;       OUT     DATA            ;OUTPUT CHARACTER TO SIO
;       RET
;
;       MODEM INPUT CHAR- THIS ROUTINE IS USED TO FETCH A 
;       RECEIVED CHARACTER FROM THE MODEM PORT AND PLACE IN THE A 
;       REGISTER. IT DOES NOT HAVE TO CHECK FOR RECEIVED DATA 
;       AVAILABLE SINCE ASCOM USES THE MODEM STATUS ROUTINE ABOVE 
;       BEFORE ANY ATTEMPT TO FETCH A CHARACTER IS MADE.
;
;       For this implementation, the input character may come from
;       the autodump buffer.
;
COMINP:
        LDA     BUFCNT          ;GET COUNT IN AUTODUMP BUFFER
        ORA     A               ;TEST
        JZ      COMIP1          ; JUMP IF NONE WAITING
        LHLD    BUFPTR          ;GET CURRENT BUFFER POINTER
        MOV     A,M             ;GET NEXT CHARACTER FROM BUFFER
        INX     H               ;BUMP POINTER
        SHLD    BUFPTR          ;RESAVE IT
        LXI     H,BUFCNT        ;POINT TO COUNT IN BUFFER       
        DCR     M               ;COUNT DOWN ONE
        RNZ                     ;RETURN IF MORE STILL LEFT
        PUSH    PSW             ;SAVE CHARACTER IN A
        MVI     C,11H           ;GET XON CHARACTER
        CALL    COMOUT          ;SEND IT
        POP     PSW             ;GET BACK INPUT CHARACTER
        RET                     ;ALL DONE
;
;       CHARACTER MUST BE WAITING AT INPUT PORT
;
COMIP1:
        LDA     MODDATP         ;GET CHARACTER
        RET
;
;       MODEM BREAK ROUTINE- IF AVAILABLE, YOU MAY PLACE A 
;       ROUTINE HERE THAT WILL BE USED BY ASCOM WHEN THE OPERATOR 
;       IN CONVERSATIONAL MODE REQUESTS A "BREAK" BY DEPRESSING 
;       CONTROL-B. IF YOUR SERIAL DEVICE DOES NOT SUPPORT A BREAK 
;       CHARACTER (DEFINED TO BE A 500ms LOW ON THE TRANSMITTED 
;       DATA LINE), THEN SIMPLY RETURN.
;
COMBRK:
        RET
;
;
;       USER AUTO DIAL ROUTINE. ON ENTRY, HL POINTS TO REST OF
;       COMMAND LINE, ENDING WITH A NULL.
;
;       This implementation will use the HAYES Smartmodem. It
;       makes no assumptions about the settings of the VERBOSE
;       and ECHO switches under the front cover. All characters
;       on the command line entered after the DIAL command will
;       be sent to the modem. The operator can therefore take
;       advantage of the Smartmodem's programmable features.
;
COMDIL:
        PUSH    H               ;SAVE ADDRESS OF REST OF CMD LINE
        CALL    SETUP           ;SET NON-VERBOSE, NO ECHO, FULL DPX
        LXI     D,DIALMS        ;POINT TO DIAL MESSAGE  
        CALL    SNDMSG          ;SEND MESSAGE TO MODEM
        POP     D               ;GET BACK ADDRESS OF REST OF CMD
        CALL    SNDMSG          ;SEND MESSAGE TO MODEM
        MVI     C,CR            ;CR TO TERMINATE MESSAGE
        CALL    COMOUT          ; SEND IT
COMDI1:
        CALL    GETRET          ;GET RETURN CODE FROM SMART MODEM
        SUI     '1'             ;SET A TO ZERO IF RET CODE=1
        RET                     ; ==>CONNECTED
;
;       USER AUTO ANSWER ROUTINE. ON ENTRY, HL POINTS TO REST OF
;       COMMAND LINE, ENDING WITH A NULL.
;
COMANS:
        CALL    SETUP           ;SET NON-VERBOSE, NO ECHO, FULL DPX
        LXI     D,ANSMSG        ;ANSWER MESSAGE 
        CALL    SNDMSG          ; SEND IT
        CALL    GETRET          ;GET RETURN CODE
        SUI     '0'             ;MUST BE ZERO TO SAY CMD ACCEPTED
        RNZ                     ;RETURN IF NOT
COMAN1:
        CALL    GETRET          ;GET RETURN CODE FORM SMART MODEM
        CPI     '2'             ;RINGING?
        JZ      COMAN1          ; JUMP IF SO, WAIT FOR ANOTHER
        SUI     '1'             ;SET Z FLAG AND A=0 IF OK
        RZ                      ;RETURN IF CONNECTION MADE
        PUSH    PSW             ;SAVE FLAGS
        CALL    USER2           ;CANCEL AUTO-ANSWER MODE
        POP     PSW             ;GET BACK FLAGS
        RET
;
;       USER HANGUP ROUTINE. ON ENTRY, HL POINTS TO REST OF
;       COMMAND LINE ENDING WITH A NULL.
;
COMHNG:
        MVI     C,0             ;MUST SEND AT LEAST ONE CHARACTER
        CALL    COMOUT          ; OUTPUT IT
        CALL    WAIT            ;WAIT 1 SECOND
        LXI     D,ESCMSG        ;ESCAPE MESSAGE 
        CALL    SNDMSG          ; SEND IT
        CALL    PURGE           ;WAIT FOR 1 SEC QUIET
        LXI     D,HNGMSG        ;HANGUP MESSAGE
        CALL    SNDMSG          ;SEND IT
        CALL    WAIT
        CALL    WAIT
        CALL    PURGE           ;CLEAR ANY RESPONSE
        RET
;
;       ROUTINE TO BE CALLED WHEN CAPTURE IS ON AND CAPTURE BUFFER 
;       IS FULL. ON ENTRY, A WILL CONTAIN A BYTE WHOSE BITS 
;       INDICATE VARIOUS STATUS OF THE ACTIVE CAPTURE MODE:
;
;               BIT 0 = CAPTURE ON
;               BIT 1 = CAPTURE INCOMING DATA
;               BIT 2 = CAPTURE OUTGOING DATA
;               BIT 3 = CAPTURE FILE OPEN
;
;       POSSIBLE USE OF THIS ROUTINE WILL BE TO SEND AN XOFF 
;       CHARACTER FOLLOWED BY POSSIBLY WAITING FOR SOME MORE 
;       INPUT UNTIL THE XOFF HAS BEEN ACCEPTED BY THE SENDER. 
;       THIS ROUTINE AND THE ONE FOLLOWING WILL ONLY BE CALLED 
;       IF AUTODUMP IS ON.
;
;       The basic algorithm for this implementation will be to 
;       send an XOFF character to the sending station, waiting for
;       approximately 3 seconds of silence (while still receiving
;       characters) then returning. The characters received will
;       have to be retrievable from the modem input routine.
;
BEFDMP:
        MVI     C,13H           ;GET XOFF CHARACTER
        CALL    COMOUT          ;SEND IT
;
;       Begin loop waiting for about 3 seconds of silence, buffering
;       input characters (to a maximum of 80 for this implementation).
;       If the autodump buffer gets full, we will simply exit to allow
;       ASCOM to dump its capture buffer, causing any additional 
;       incoming data to be lost.
;
        LXI     H,BUFFER        ;HL POINTS TO BASE OF AUTODUMP BUFF
        SHLD    BUFPTR          ;SET AS START PTR TO RETRIEVE CHAR'S
        MVI     B,0             ;B WILL COUNT CHARACTERS IN BUFFER
BEFDM1:
        LXI     D,5000H         ;COUNT PASSES THROUGH LOOP
BEFDM2:
        CALL    COMSTA          ;GET MODEM
        JNZ     BEFDM3          ; JUMP IF A CHARACTER ARRIVES
        XTHL                    ;WASTE TIME
        XTHL
        XTHL
        XTHL
        DCX     D               ;COUNT DOWN PASSES THROUGH LOOP
        MOV     A,D
        ORA     E               ;ZERO YET
        JNZ     BEFDM2          ; JUMP IF NOT YET
        MOV     A,B             ;GET COUNT IN BUFFER
        STA     BUFCNT          ;SAVE THERE
        RET                     ;RET IF SO, REMOTE STATION QUIET
;
;       A CHARACTER HAS ARRIVED, GET IT AND SAVE IN BUFFER
;
BEFDM3:
        CALL    COMIP1          ;GET INPUT CHARACTER FROM MODEM
        MOV     M,A             ;SAVE IN BUFFER
        INX     H               ;ADVANCE BUFFER POINTER
        INR     B               ;BUMP COUNT IN BUFFER
        MOV     A,B             ;GET NEW COUNT TO A
        CPI     80              ;BUFFER FILLED WITH 80 CHARACTERS ?
        RNC                     ;RETURN IF SO, GIVE UP WAITING
        JMP     BEFDM1          ;RESTART LOOP WAITING FOR SILENCE
;
;       ROUTINE TO BE CALLED AFTER THE CAPTURE BUFFER DURING 
;       AUTODUMP HAS BEEN WRITTEN TO DISK. TYPICAL USE WOULD BE 
;       TO SEND THE XON THAT WOULD ALLOW THE SENDING STATION TO 
;       CONTINUE.
;
;       In this implementation, no after dump routine is used 
;       because there may be characters buffered in the autodump 
;       buffer. When those characters are used up, the XON will 
;       be send.
;
AFTDMP:
        RET
;
;       USER INITIALIZATION
;       This routine will be called after the user signon
;        is displayed.
INIT:
        MVI     A,1     ;
        STA     BAUDSL  ;initialize for 300 BAUD
        RET
;
;
;       USER EXIT
;       This routine will be called before exit to the operating
;        system.
EXIT:
        RET
;
;
;       USER1 will redial the last number
;
USER1:
        LXI     D,REDLMS        ;REDIAL MESSAGE
        CALL    SNDMSG          ; SEND IT
        JMP     COMDI1          ;JOIN DIAL ROUTINE
;
;       USER2 will cancel auto-answer mode
;
USER2:
        LXI     D,ANSMS1        ;GET NO ANSWER MESSAGE  
        CALL    SNDMSG          ; SEND TO STOP FURTHER ANSWERING
        JMP     GETRET          ;GET RETURN CODE
;
USER3:
USER4:
        RET
;
;       SPECIAL SUPPORT ROUTINES FOR HAYES SMARTMODEM
;
;       GETRET: Routine to get a single character result code back
;       from the SMARTMODEM. Possible values are:
;                       0 = OK
;                       1 = connect
;                       2 = ring
;                       3 = no carrier
;                       4 = command error
;
GETRET:
        CALL    COMSTA          ;GET STATUS
        JNZ     GETRE1          ; JUMP IF A CHARACTER IS WAITING
        CALL    CONBRK          ;CHECK FOR CONSOLE BREAK
        JZ      GETRET          ; CONTINUE WAITING IF NEITHER
        XRA     A               ;CLEAR A TO MAKE N.G. RET CODE
        RET
;
;       FIRST CHARACTER OF RETURN CODE WAITING, GET IT
;
GETRE1:
        CALL    COMINP          ;GET RETURN CODE
        ANI     7FH             ;CLEAR PARITY BIT
        PUSH    PSW             ; AND SAVE ON STACK
;       
;       LOOP TO WAIT FOR CR
;
GETRE2:
        CALL    COMSTA          ;GET MODEM STATUS
        JNZ     GETRE3          ; JUMP IF CHARACTER WAITING
        CALL    CONBRK          ;CHECK FOR BREAK
        JZ      GETRE2          ; CONTINUE WAITING IF NEITHER
        JMP     GETRE4          ;OPERATOR DID NOT WAIT FOR CR
GETRE3:
        CALL    COMINP          ;GET CR FROM SMARTMODEM
GETRE4:
        POP     PSW             ;GET RETURN CODE BACK TO A
        RET
;
;       SETUP: Routine to set SMARTMODEM up for NON-VERBOSE return codes
;       and full duplex operation and no echo of command characters.
;
SETUP:
        LXI     D,SETMSG
        CALL    SNDMSG          ;SEND SETUP MESSAGE
        CALL    COMINP
        CALL    WAIT            ;WAIT 2 SECONDS TO ALLOW SMARTMODEM TO RESPOND
        CALL    WAIT
;
;       PURGE: Routine to clear any input characters, forcing
;       1 second of silence.
;
PURGE:
        CALL    WAIT    ;wait 1 sec
        CALL    COMSTA  ;see if input waiting
        RZ              ; RETurn if not
        CALL    COMINP  ;clear character
        JMP     PURGE   ;keep waiting
;
;       CONBRK: Routine to check for a console break.  If the 
;       operator enters any control code, this routine will clear 
;       the Z flag and get the character.
;
CONBRK:
        MVI     C,CNSTAT
        CALL    BDOS            ;GET CONSOLE STATUS
        ORA     A               ;CHECK RETURN
        RZ                      ;RET IF NO BREAK
        MVI     C,CNIN
        CALL    BDOS            ;GET CONSOLE INPUT
        CPI     ' '             ;CHECK FOR A CONTROL CHARACTER
        JNC     CONBRK          ;TRY AGAIN IF NOT
        MVI     A,0FFH          ;GET SOMETHING NON-ZERO
        ORA     A               ;CLEAR Z FLAG
        RET
;
;       SNDMSG: Routine to send characters to the modem port
;       from the string pointed to by DE up until the first null.
;
SNDMSG:
        LDAX    D               ;GET A CHARACTER
        ORA     A               ;TEST FOR A NULL
        RZ                      ;RET IF SO
        MOV     C,A             ;GET CHARACTER TO C FOR COMOUT
        CALL    COMOUT          ; SEND IT
        INX     D               ;BUMP PTR
        JMP     SNDMSG          ;CONTINUE
;
;       WAIT: Routine to wait 1 second on a 4MHZ Z80
;
WAIT:
        LXI     H,0C000H
WAIT1:
        XTHL
        XTHL
        XTHL
        XTHL
        DCX     H
        MOV     A,H
        ORA     L
        JNZ     WAIT1
        RET
;
;       SMARTMODEM COMMAND STRINGS
;
SETMSG: DB      'ATF1V0E0',CR,0
DIALMS: DB      'ATD',0         ;FULL DUPLEX DIALING
ANSMSG: DB      'ATF1S0=1',CR,0 ;ANSWER ON 1ST RING
ANSMS1: DB      'ATS0=0',CR,0   ;NO AUTO-ANSWER
ESCMSG: DB      '+++',0
HNGMSG: DB      'ATH',CR,0      ;HANG-UP MESSAGE
REDLMS: DB      'A/',0          ;REDIAL MESSAGE
;
;       AUTODUMP BUFFER, COUNT AND POINTER.  
;
;       This area is needed to capture incoming characters arriving
;       after an XOFF is sent to allow AUTODUMP to be done,
;       and before ASCOM is allowed to dump its capture buffer to 
;       disk.
;
BUFFER: DS      80              ;ALLOW 80 CHARACTERS MAXIMUM
BUFPTR: DW      BUFFER          ;POINTER TO BUFFER
BUFCNT: DB      0               ;COUNT OF CHARACTERS USED IN BUFFER
;
;
        END

A>