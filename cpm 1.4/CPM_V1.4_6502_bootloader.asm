;OSI CPM V1.4 bootloader disassembly + notes
; Mark Spankus 7/2010
; Feel free to use as you wish, no guarantees on accuracy but it should be generally correct!
;
;This is a disassembly of the bootloader and the BIOS I/O routines implemented in 6502 code
;for OSI CPM V1.4. CPM is designed for a 56K OSI C3 machine with 510 CPU board with working 
;Z80 and 6502. Required memory: 48K memory starting at 0, plus 4K at $D000, and 4K at $E000

;OSI has a unique floppy disk controller. It uses an ACIA clocked at 250KHz to write an FM stream
;to a single density 8" diskette. 
;OSI CPM uses the same disk format as OS65D, an 8E1 formatted stream of bytes.
;Data starts after the end of dection of the index hole after a short delay.

;Track 0 contains the Boot track which is 13 pages long and loads at $2200
; trk0 [8E1]<index><delay>loadHi,loadLo,#pages,(#pages*256 data) 

;The rest of the tracks are	stored as a single OS65D sector, 13 pages(256bytes) long
; trk1-n [8E1]<index><delay>$43,$57,bcd trk#,$58 <delay>$76,Sect#,SectLen,#len-pages-data,$47,$53

; CPM reads and writes a whole OSI track at a time, checking for Parity or formatting errors on read.
; If one byte is bad in sector data, all 13 pages (26 CPM block) will be flagged in error

;The first two disk tracks contain the OSI bootloader and the CPM core.  The CPM directory starts on 
;track 3 of the disk (logical block 0 to CPM)

;$E000 is the address of 4K shared memory for an OSI hard disk controller ($E000-EFFF)
;The hard disk controller can read / write to this memory upon request DMA-like, although no hard disk
;specific code is in this disassembly. The code seems to be compatible with hard disk I/O.
;The OSI hard disk controller registers are invisible until access at $C2xx makes it available 
;for a short time

;OSI CPM V1.4 uses the processor selection feature of the OSI510 CPU extensively. It handles disk I/O
;in 6502 code while CPM runs under Z80.  Processor selection is controlled via a 6820 PIA at $F700
;in addition the 510CPU board has a 128 byte 6810 RAM at $F2xx that can be mapped in instead of the 
;system ROM at $FF80-$FFFF to override the default 6502 vectors for RESET etc.
;Because CPM uses RAM at $100, software must swap it out for the saved 6502 stack upon every processor
;switch, otherwise a simple JSR could cause CP/M memory corruption


;Memory locations of interest
; $44 = target track # (0 to 76)
; $E018 = start of disk track in memory 13 pages per track (3328 bytes)
; $EE22 transfer value low 
; $EE23 transfer value high

;CPM Disk Error #
;1 = disk step failed (?)
;2 = write failed ?
;4 = Disk write protected
;5 = Track header not found or wrong track # read from disk
;6 = Invalid Drive #
;7 = Invalid Sector # request (CPM sector is 128 bytes) Sect # 1-26
;8 = Bad Track to Seek (0-76 OK)
;9 = index encountered waiting for character

;This is what gets executed after the boot track is loaded into memory
;BOOT track is 13 pages long , loads $2200 - $2F00, relocate $2300-$2F00 to $D000

*=$2200
L2200               ldy #$bf
                    jsr S22b9	;Test for RAM at BFFF
                    beq L221d
                    jsr PRINTHALT
					.BYTE $0D,$0A, "** NEED 48K **", $0D,$A, 0

L221d               ldy #$df
                    jsr S22b9	;test for RAM at DFFF
                    beq L2242
                    jsr PRINTHALT
					.BYTE $0D,$0A, "NEED 4K AT $D000 **",$0D,$0A,0

L2242               lda $c280  ;Access $C280 to make HD controller visible
                    lda #$20
                    sta $c207  ;HD controller "memory process set" ?
                    ldy #$ef
                    jsr S22b9	;test for RAM $EFFF
                    beq L226f
                    jsr PRINTHALT
					.BYTE $0D, $0A, "NEED 4K AT $E000 **", $0D, $0A, 0

L226f               ldy #$00     ;Transfer $2300-2EFF to $D000+ for 12 pages while also making a checksum
                    ldx #$0c
                    sty $00
                    sty $02
                    sty $05
                    lda #$23
                    sta $01
                    lda #$d0
                    sta $03
                    clc
L2282               lda ($00),y   ;load addr
                    sta ($02),y   ;stor addr
                    adc $05
                    sta $05
L228a               iny
                    bne L2282
                    inc $03
                    inc $01
                    dex
                    bne L2282   ;loop until all pages transfered
                    lda $05
                    cmp #$31    ;checksum match? 
L2298               beq L22b6  
                    jsr PRINTHALT
					.BYTE $D,$A, "** CHECKSUM ERROR **", $0D, $0A, 0

L22b6               jmp Ld000    ;JMP to code at $D000
                    
S22b9               sty $01      ; Non Destructive Mem Test, on entry Y= Target Page uses Loc $00, $01, $04
                    ldy #$ff     ; Tests yyFF where yy=taget page, return Zero if OK
                    sty $00
                    iny
                    lda ($00),y
                    tax
                    and #$3f
                    eor #$3f
                    sta ($00),y
                    sta $04
                    lda ($00),y
                    and #$3f
                    cmp $04
                    php
                    txa
                    sta ($00),y
                    ldy $01
                    plp
                    rts
                    
PRINTHALT           pla       ; Print message following JSR and stop executing by looping to self
                    sta $00
                    pla
                    sta $01
                    ldy #$01
L22e1               lda ($00),y  ;load message following JSR
                    beq L22eb
                    jsr $FE0B	;send character to console serial port ROM routine
                    iny
                    bne L22e1
L22eb               jmp L22eb   ; STOP EXECUTION BY ENDLESS LOOP
                    
					;pad rest of page out
			.BYTE $24, $24, $24, $24, $24, $24, $24, $24, $24
			.BYTE $24, $24, $24, $24, $24, $24, $24, $24, $24
*=$D000
;Boot code at $2300 moved to $D000
LD000
                    ;this table matches CP/M bios entry points except some routines are not implemented
					;in 6502 land. Maybe in Z80 land.
					;
					; From CPM 1.4 manual
					;on warm boot addr 0,1,2 set to JMP WBOOT 3=initial value of iobyte, 5,6,7 JMP BDOS
					;location 4 used for currently selected drive 0=A
					;The primary entry point to CP/M for transient programs 0005H: JMP 3106H+b
					;upon completion of initialization, WBOOT program must branch to the CCP at 2900H+b 
					;to (re)start the system. Upon entry register C is set to the drive to select after system 
					;initialization
					; $FE35 is OSI System ROM Monitor entry point -- should not be called by CPM
					;thus those table entries are handled by Z80, not 6502
					JMP LD14B	;print welcome msg, start init ;cold boot
					JMP LD16C   ;warm boot(?) - cpm system must be loaded from disk
					JMP $FE35    ;enter into ROM monitor (con chk) check for console ready character
					JMP $FE35    ;enter into ROM monitor (con IN) read console character
					JMP $FE35    ;enter into ROM monitor (con out) write console character
					JMP $FE35    ;enter into ROM monitor (list printer/teletype)
					JMP $FE35    ;enter into ROM monitor (paper tape punch)
					JMP $FE35    ;enter into ROM monitor (paper tape reader)
					JMP LD1F0	;home (move to trk 0 on selected dev)
					JMP LD213   ;sel disk via register C 0=A
					JMP LD23D   ;set track Register C contaon the track # for later disk accesses 0-76
					JMP LD284   ;set sector # Register C contains sector# 1-26
					JMP LD2AE   ;set DMA addr Reg B & C contain high8(B) and low order8 (C) for r/w operations
					; Read/Write (should auto-retry for up to 10 times before reporting bdos error)
					JMP LD2E4   ;read selected sector  return 0 =no error 1=non recoverable error in register A
					JMP LD326   ;write selected sector return 0 =no error 1=non recoverable error in register A
LD02D				LDY #<LD034 ;#$34
					LDX #>LD034 ;#$D0
					JMP SWAPKANDGO
LD034				JSR LD174
					LDY #<LD03E ; #$3E
					LDX #>LD03E ; #$D0
					JMP SWAPKANDGO
LD03E				JMP LD101

	;filler D041 - D0FF
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

LD100 = *
				.BYTE $01   ;flag to output diagnostics messages; 0=diag
LD101  = *   ;D101 GOZ80BE7A
				LDA #$7A		switch to Z80; Z80 execute at $BE7A
				STA $01
				LDA #$BE
				STA $02
GOZ80 = * ;D109
				LDA #$C3
				STA $00
				LDX #$00     ;SET DDRA visible
				STX $F701
				DEX
				STX $F700   ;Set Port A output
				LDY #$04
				STY $F701   ;SET Port A visible
				LDY #$5F
				STX $F700   ;SET Port A=$FF
				STY $F700   ; Set Port A Z80 active
				BNE *      ;loop to self till Z80 takes over
Z80_BE5B=*  ;D125
				LDA #$5B
				STA $01
				LDA #$BE
				STA $02
				JMP GOZ80
				
SWAPKANDGO = * ;D130			;SWAP CONTENTS OF STACK PAGE AND DF00, RETURN ADDR IS IN XY (hi lo)
				STY LD149
				STX LD149+1   ;store desired return address in code below XY= (hi lo)
				LDX #$00      ;swap 6502 stack ($0100+) and $DF00+
LD138			LDA $0100,X
				LDY $DF00,X
				STA $DF00,X
				TYA
				STA $0100,X
				INX
				BNE LD138
LD149 = *+1
				JMP $FFFF	;this address patched with desired return address in X & Y

LD14B			CLD
				SEI
				JSR RESET_IO
				JSR PRINTMSG
	.BYTE $D, $A, "OSI CP/M VERSION 1.4", $D, $A, 0

LD16C			CLD
				SEI
				JMP LD02D
				JMP LD101
				
LD174 			LDA #$C0    ;
				STA $03
				LDA #$C3	; Z80 JMP $B106 instruction @ 0005
				STA $05
				LDA #$06    ; $B106
				STA $06
				LDA #$B1
				STA $07
				LDA #$00
				STA $EE22
				STA $04
				LDA #$80
				STA LDB31
				LDA #$00
				STA LDB32
				LDA #$01
				JSR SEEKTRK
				LDA #$02
				STA LDB30
				JSR READTRAK ;read track
				LDA #$A9  ;target = A900
				STA $49
				LDA #$00
				STA $48
				LDA #$E0   ;src = E098
				STA $4B
				LDA #$98
				STA $4A
				LDX #$1B   ;copy $1B 128 byte pages = ($D 256 byte pages = 1 track of data) 
				JSR LD1CF
				LDA #$02
				JSR SEEKTRK  ;seek track #2
				JSR READTRAK
				LDA #$E0
				STA $4B
				LDA #$18
				STA $4A
				LDA #$80
				STA $48
				DEC $49
				LDX #$15

LD1CF			LDY #$00     ;move X*128 bytes from ($4A) to ($48)
LD1D1			LDA ($4A),Y
				STA ($48),Y
				INY
				BPL LD1D1
				TYA
				CLC
				ADC $48
				STA $48
				BCC LD1E2
				INC $49
LD1E2			TYA
				CLC
				ADC $4A
				STA $4A
				BCC LD1EC
				INC $4B
LD1EC			DEX
				BNE LD1CF
				RTS

LD1F0			CLD
				SEI
				LDY #<LD1F9 ;#$F9
				LDX #>LD1F9 ;#$D1
				JMP SWAPKANDGO
LD1F9			LDA LD100
				BNE LD208
				JSR PRINTMSG
		.BYTE $A, $D, "HOME", 0
LD208			JSR TZERO			;go to track zero 
				LDA #$00
				STA LDB27
				JMP LD366
				
LD213			CLD
				SEI
				LDY #<LD21C ;#$1C
				LDX #>LD21C ;#$D2
				JMP SWAPKANDGO
LD21C			LDA LD100
				BNE LD234
				JSR PRINTMSG
		.BYTE $A, $D, "SELDSK ", 0 
				LDA $EE22
				JSR HEXOUT
LD234			LDA $EE22
				JSR LDAB3  ;check for error code in A
				JMP LD366


LD23D			CLD
				SEI
				LDY #<LD246  ;#$46
				LDX #>LD246  ;#$D2
				JMP SWAPKANDGO
LD246			LDA LD100
				BNE LD25E
				JSR PRINTMSG
		.BYTE $A,$D, "SETTRK ", 0
				LDA $EE22
				JSR HEXOUT
LD25E			LDA $EE22
				LDX #$FF
				SEC
LD264			INX
				SBC #$0A
				BEQ LD26B
				BCS LD264
LD26B			CLC
				ADC #$0A
				STA $EE18
				TXA
				ASL A
				ASL A
				ASL A
				ASL A
				ORA $EE18
				CLC
				SED
				ADC #$01
				CLD
				JSR SEEKTRK
				JMP LD366

LD284			CLD
				SEI
				LDY #<LD28D ;#$8D
				LDX #>LD28D ;#$D2
				JMP SWAPKANDGO
LD28D			LDA LD100
				BNE LD2A5
				JSR PRINTMSG
	.BYTE $A, $D, "SETSEC ", 0
				LDA $EE22
				JSR HEXOUT
LD2A5			LDA $EE22
				STA LDB30
				JMP LD366
				
LD2AE			CLD
				SEI
				LDY #<LD2B7 ;#$B7
				LDX #>LD2B7 ;#$D2
				JMP SWAPKANDGO
LD2B7			LDA LD100
				BNE LD2D5
				JSR PRINTMSG
	.BYTE $D, $A, "SETDMA ", 0
				LDA $EE23
				JSR HEXOUT
				LDA $EE22
				JSR HEXOUT
LD2D5			LDA $EE23
				STA LDB32
				LDA $EE22
				STA LDB31
				JMP LD366
				
LD2E4			CLD
				SEI
				LDY #<LD2ED ;#$ED
				LDX #>LD2ED ;#$D2
				JMP SWAPKANDGO
LD2ED			LDA LD100
				BNE LD2FC
				JSR PRINTMSG
		.BYTE $A, $D, "READ", 0
LD2FC			LDA #$00
				STA LDB2F
				JSR READTRAK
				LDA LDB2F
				STA $EE21
				BEQ LD366
				PHA
				JSR PRINTMSG
		.BYTE $A, $D, "ERROR CODE: ", 0
LD31F 			PLA
				JSR HEXOUT
				JMP LD366
				
LD326			CLD
				SEI
				LDY #<LD32F ;$2F
				LDX #>LD32F ;#$D3
				JMP SWAPKANDGO
LD32F			LDA LD100
				BNE LD33F
				JSR PRINTMSG
		.BYTE $D, $A, "WRITE", 0
LD33F			LDA #$00
				STA LDB2F
				JSR LD86B
				LDA LDB2F
				STA $EE21
				BEQ LD366
				PHA
				JSR PRINTMSG
				.BYTE $D, $A, "ERROR CODE: ", 0
				PLA
				JSR HEXOUT
LD366     		LDY #<LD36D ; #$6D
				LDX #>LD36D ; #$D3
				JMP SWAPKANDGO
LD36D			JMP Z80_BE5B		;D125

HEXOUT=*
				PHA			;WRITE HEX BYTE TO CONSOLE
				LSR A
				LSR A
				LSR A
				LSR A
				JSR $D379
				PLA
				AND #$0F
				ORA #$30
				CMP #$3A
				BCC $D383
				ADC #$06
				JMP $FE0B
RESET_IO=* ;$D386
				LDA #$03
				STA $FC00	  ;RESET CONSOLE ACIA
				LDA #$11
				STA $FC00     ;SET ACIA 8N2
				LDX #$00
				STX $F401     ;RESET PIA AT $F400 (sytem printer?)
				STX $F400
				STX $F403    
				DEX
				STX $F402
				LDA #$04     ;make ports visible
				STA $F401
				STA $F403
				LDA $C280     ;Access $C280 to make HD controller visible
				LDA #$20
				STA $C207    ;HD controller "memory process set" ?
				JSR $D700
				RTS

	;filler $D3B3-D6FF
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.BYTE $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


*=$D700
LD700			JSR LD837	;reset disk ACIA
				LDY #$00
				STY LDB27   ;current trk
				STY LDB28
				STY LDB29
				STY LDB2B   ;=00
				STY $C001		;set disk PIA DDRA visible
				LDA #$40
				STA $C000       ;set port a output except PA6
				LDX #$04 
				STX $C001       ;set disk PIA Port Visible
				STY $C000       ;set portA low
				STY $C003       ;set DDRB visible
				DEY
				STY $C002       ;set PORTB to Output
				STX $C003       ;set Port B visible
				STY LDB2A  ;=FF
				JSR LDAED
				LDA $C000		;read disk status
				ASL A
				ASL A
				ASL A
				ASL A
				BCC LD75B     ;check RDY 2
				LDA #$82      ;error $82?
				STA LDB2F
				JSR PRINTMSG
	.BYTE $D, $A, "DRIVE B NOT READY", $D, $A, 0
				JMP LD75E
LD75B			JSR TZERO
LD75E			JSR RESETDISK
				LDA $C000		;test drive 1 ready
				LSR A
				BCC TZERO		
				LDA #$81
				ORA LDB2F		;error $81 or $83
				STA LDB2F
				JSR PRINTMSG
	.BYTE $D, $A, "DRIVE A NOT READY", $D, $A, 0
				RTS
				
TZERO			JSR STEPUP
				JSR DELAY12		;delay 12
LD78F			LDA #$02		;test trk 0 set
				BIT $C000
				BEQ DELAY12		;yup at 0, branch
				JSR STEPDWN
				BEQ LD78F   	;try again

DELAY12			LDX #$0C

DELAY			LDY #$C7		;delay * X
				DEY
				BNE $D79F
				DEX
				BNE DELAY
				RTS
				
STEPDWN			LDA $C002	;Set Step out to trk 0 $D7A6
				ORA #$04
				BNE STEP
				
STEPUP 			LDA #$FB	;Set Step direction inwards $D7AD 
				AND $C002
				
STEP			STA $C002    ;set direction
				CMP ($00,X)  ;some delay?
				AND #$F7     ;set step lo
				STA $C002
				CMP ($00,X)  ;some delay?
				ORA #$08    
				STA $C002	;set step high 
				LDX #$08
				BNE DELAY	;delay 8x
				
SEEKTRK			STA $44
				CMP #$77
				BCC LD7EF
				JSR PRINTMSG
	.BYTE $D, $A, "BAD TRACK # TO SEEK", $D, $A, 0
				LDA #$08
				STA LDB2F		;error 8
				SEC
				RTS
				
LD7EF       	SED
				LDX $44			;get target trk#
				CPX LDB27       ;compare to current track
				BEQ LD813       ;done
				BCS LD806
				LDA #$99
				ADC LDB27       ;subtract 1
				STA LDB27
				JSR STEPDWN
				BEQ LD7EF     ;always
				
LD806			LDA #$00   ;step 
				ADC LDB27       ;add 1
				STA LDB27
				JSR STEPUP
				BEQ LD7EF     ;always
				
LD813			CLD				;done with track step
				JSR DELAY12
				LDA $C002
				LDX #$42
				CPX LDB27
				BCC LD825
				ORA #$40
				BNE LD827
LD825			AND #$BF
LD827			STA $C002
				CLC
				RTS

INDXWAIT		LDA $C000	    ;check disk index $D82C EXITS on falling edge of index
				BMI INDXWAIT    ; not set? loop
LD831			LDA $C000
				BPL LD831       ; now while set, loop
				RTS
LD837			LDA #$03		; reset disk ACIA
				STA $C010
				LDA #$58		; Set 8E1 /1
				STA $C010
				RTS
LOADHEAD		LDA #$7F  		;load head
				AND $C002
LD847			STA $C002
				LDX #$28
				JMP DELAY
UNLOADH 		LDA #$80   		;unload head
				ORA $C002
				BNE LD847
				
DWRITE          LDA $C010		;Write data in X to disk
				LSR A
				LSR A    		;check disk TDRE empty
				BCC DWRITE
				STX $C011
				RTS
DREADNE			LDA $C010		;read disk no error check
				LSR A
				BCC DREADNE
				LDA $C011
LD86A			RTS

LD86B			LDA #$02
				BIT $C000		;check for TRK 0
				BEQ LD86A     ; Yes, exit
				LDA #$20
				BIT $C000		;check WP
				BNE LD880
				LDA #$04		;error 4
				STA LDB2F
				SEC
				RTS
				
LD880			JSR LOADHEAD
				LDA LDB2A
				CMP LDB27
				BEQ LD8AE
				LDA LDB31
				PHA
				LDA LDB32
				PHA
				LDA #$D0
				STA LDB32
				LDA #$80
				STA LDB31
				JSR READTRAK
				PLA
				STA LDB32
				PLA
				STA LDB31
				BCC LD8AB
				RTS
LD8AB			JSR LOADHEAD
LD8AE			JSR LDA76
				BCC LD8B4
				RTS

LD8B4			LDY #$00		;transfer CPM sector to target address (128 bytes)
LD8B6			LDA ($40),Y
				STA ($42),Y
				INY
				CPY #$80
				BNE LD8B6
				LDA #$01
				STA LDB2E

LD8C4			LDA #$03
				STA LDB2C	;
				LDA #$E0
				STA $41
				LDA #$18
				STA $40
				JSR RDTRKHEAD
				BCC LD8DB
				JSR UNLOADH
				SEC
				RTS

LD8DB			LDA #$08
				JSR LD965		;delay
				LDA #$FE		;turn on erase
				AND $C002
				STA $C002
				LDX #$25		;delay
LD8EA			DEX
				BNE LD8EA
				LDA #$FD		;turn on write & erase
				AND $C002
				STA $C002
				LDA #$08
				JSR LD965		;delay
				LDX #$76		;write sector start marker #1
				JSR DWRITE
				LDX #$01		;sector start marker #2
				JSR DWRITE
				LDX #$0D		;sector length (13)
				STX $44
				JSR DWRITE
				LDY #$00
LD90D			LDA ($40),Y
				TAX
				JSR DWRITE
				INY
				BNE LD90D
				INC $41
				DEC $44
				BNE LD90D
				LDX #$47		;write $47 to disk end of sector marker
				JSR DWRITE
				LDX #$53        ;write $53 to disk
				JSR DWRITE
				LDA #$4E
				JSR LD965		;delay
				LDA $C002
				ORA #$01
				STA $C002		;turn off write
				LDX #$69		;delay
LD935         	DEX
				BNE LD935
				ORA #$02
				STA $C002		;turn off erase
LD93D			LDA #$FF
				JSR CHKTRK
				BCC LD960
				DEC LDB2C
				BNE LD93D
				DEC LDB2E
				BMI LD951
				JMP LD8C4
LD951			LDA LDB2F	  ;was there a disk error
				BNE LD95B
				
				LDA #$02	  ;error 2
				STA LDB2F
LD95B			JSR UNLOADH
				SEC
				RTS
LD960			JSR UNLOADH
				CLC
				RTS

LD965 			TAY     ;delay A times 84 clock ticks
LD966			LDX #$12
LD968			DEX
				BNE LD968
				NOP
				NOP
				DEY
				BNE LD966
				RTS

DREADNOIDX		LDA $C000   ;read disk ctrl  $D971
				BPL LD980	;exit on disk index set
				LDA $C010   ;read disk data reg
				LSR A
				BCC DREADNOIDX   ;wait for character ready
				LDA $C011
				RTS
LD980			LDA #$09
				STA LDB2F
				PLA		;pop return address
				PLA
				SEC
				RTS
				
RDTRKHEAD		JSR INDXWAIT   	;*** read track header, expected trk# in LDB27
				JSR LD837 			; reset disk acia
LD98F			JSR DREADNOIDX
				CMP #$43
				BNE LD98F        ;look for track start char $43 until index
				JSR DREADNOIDX
				CMP #$57		 ; and 2nd character track marker $57
				BNE LD98F
				JSR DREADNE	     ; and track #
				CMP LDB27
				BEQ LD9AF
				JSR UNLOADH
				LDA #$05		;disk error 5
				STA LDB2F
				SEC
				RTS
LD9AF			JSR DREADNE		;now read character after header ($58) 
				CLC
				RTS
				
CHKTRK			;test read track & sector return carry set if error
				PHA				
				JSR RDTRKHEAD
				BCC LD9BC
				PLA
				RTS
				
LD9BC			JSR DREADNOIDX  ; ** now search for start of sector mark $76
				CMP #$76
				BNE LD9BC
				JSR DREADNE
				CMP #$01	;sector # (1)
				BEQ LD9CD
				PLA
LD9CB			SEC			;error exit
				RTS
LD9CD			JSR DREADNE		;read sector size
				TAX
				LDY #$00
				PLA
				BEQ LD9F2	;branch to read sector
				
LD9D6			;read disk without storing for X pages
				LDA $C010  ;read disk serial status
				LSR A
				BCC LD9D6	;wait for character ready
				LDA $C011	;read data
				BIT $C010
				BVS LD9CB   ;check for parity error
				INY
				BNE LD9D6
				DEX
				BNE LD9D6
LD9EA			JSR DREADNE
				JSR DREADNE
				CLC
				RTS

LD9F2			LDA $C010	; ** READ X pages of data from disk to ($40)+
				LSR A			;read disk serial status
				BCC LD9F2		;wait for byte ready
				LDA $C011		;get data
				BIT $C010
				BVS LD9CB     ;check for parity error
				STA ($40),Y
				INY
				BNE LD9F2
				INC $41
				DEX
				BNE LD9F2
				BEQ LD9EA

READTRAK		LDA #$03
				STA LDB2D 
LDA11			LDA #$07        
				STA LDB2C
LDA16			LDA #$E0		;set disk read buffer pointer to $E018
				STA $41
				LDA #$18
				STA $40
				LDA LDB2A
				CMP LDB27
				BEQ LDA30
				JSR LOADHEAD
				LDA #$00
				JSR CHKTRK
				BCS LDA51
LDA30			JSR LDA76
				BCC LDA36
				RTS
LDA36			LDA LDB27
				STA LDB2A
				LDY #$00
LDA3E 			LDA ($42),Y
				STA ($40),Y
				INY
				CPY #$80
				BNE LDA3E
				LDA $C002	;is head loaded?
				BMI LDA4F   ;no, branch
				JSR UNLOADH
LDA4F			CLC
				RTS
LDA51			DEC LDB2C
				BNE LDA16
				JSR STEPDWN
				JSR DELAY12
				JSR STEPUP
				JSR DELAY12
				DEC LDB2D 
				BPL LDA11
				LDA LDB2F
				BNE LDA71
				LDA #$01
				STA LDB2F
LDA71			JSR UNLOADH
				SEC
				RTS

LDA76			;set CPM sector 1-27 location address
				LDX LDB30		;CPM sector # (1 sector = 128 bytes)
				DEX
				TXA
				BMI LDAA9       ;sector too low err
				CMP #$1A
				BPL LDAA9
				LSR A
				CLC
				ADC #$E0		; /2 +E0 = page offset
				STA $43
				LDA #$18
				STA $42
				TXA
				LSR A
				BCC LDA95    ; even or odd?
				LDA #$80     ; odd, add $80 for 1 more sector
				ORA $42
				STA $42
				
LDA95			LDA LDB31	;get target location for CPM sector data
				STA $40
				LDA LDB32
				STA $41
				CMP #$01
				BNE LDAA7
				LDA #$DF
				STA $41
LDAA7			CLC
				RTS
				
LDAA9			LDA #$07		;error 7
				STA LDB2F
				JSR UNLOADH
				SEC
				RTS

LDAB3     		CMP #$00
				BMI LDAF8
				CMP #$02
				BPL LDAF8
				CMP LDB2B
				BNE LDAC2
				CLC
				RTS

LDAC2 			STA LDB2B
				TAX
				LDA #$00
				STA LDB2A
				LDY LDB27
				LDA LDB28,X
				STA LDB27
				TXA
				EOR #$01
				TAX
				TYA
				STA LDB28,X
				LDA LDB2B
				BNE LDAED
RESETDISK = * ;DAE1
				LDA #$FF
				STA $C002
				LDA #$40
				STA $C000
				CLC
				RTS
LDAED 			LDX #$00   ;set porta PA6 low
				STX $C000
				DEX
				STX $C002  ;set portB Hi
				CLC
				RTS
				
LDAF8 			LDA #$06		;error 6
				STA LDB2F
				SEC
				RTS

LDAFF =*
PRINTMSG
				PLA
				STA LDB0A
				PLA
				STA LDB0A+1
				LDY #$01
LDB09=*
LDB0A = *+1
				LDA $FFFF,Y
				BEQ LDB14
				JSR $FE0B
				INY
				BNE LDB09
LDB14        	TYA
				SEC
LDB16			ADC LDB0A
				STA LDB25
				LDA LDB0A+1
				ADC #$00
				STA LDB25+1
LDB25 = *+1
				JMP $FFFF
LDB27			.BYTE $00   ;storage for current track #
LDB28			.BYTE $00   ;disk
LDB29			.BYTE $00   ;disk
LDB2A			.BYTE $00
LDB2B			.BYTE $00   ;disk
LDB2C 			.BYTE $00   ;disk retry count?
LDB2D			.BYTE $00
LDB2E 			.BYTE $00   ;sector valid when 1
LDB2F			.BYTE $00   ;disk error # storage
LDB30			.BYTE $00   ;sector # storage (1 sector = 128 bytes)
LDB31           .BYTE $80   ; target location lo
LDB32           .BYTE $00   ; target location hi




; ----------------------   Is the rest just random garbage left over when creating disk? --------------
		BCC LDB36  ; $DB33
		RTS
LDB36	LDA LDB27
		STA $DC2A
		LDY #$00
LDB3E	LDA ($42),Y
		STA ($40),Y
		INY
		CPY #$80
		BNE LDB3E
		LDA $C002
		BMI LDB4F
		JSR $D94F
LDB4F   CLC
		RTS
		DEC $DC2C
		BNE LDB16
		JSR $D8A6
		JSR $D89B
		JSR $D8AD
		JSR $D89B
		DEC $DC2D
		BPL $DB11
		LDA $DC2F
		BNE $DB71
		LDA #$01
		STA $DC2F
		JSR $D94F
		SEC
		RTS
		LDX $DC30
		DEX
		TXA
		BMI $DBA9
		CMP #$1A
		BPL $DBA9
		LSR A
		CLC
		ADC #$E0
		STA $43
		LDA #$18
		STA $42
		TXA
		LSR A
		BCC $DB95
		LDA #$80
		ORA $42
		STA $42
		LDA $DC31
		STA $40
		LDA $DC32
		STA $41
		CMP #$01
		BNE $DBA7
		LDA #$DF
		STA $41
		CLC
		RTS
		LDA #$07
		STA $DC2F
		JSR $D94F
		SEC
		RTS
		CMP #$00
		BMI $DBF8
		CMP #$02
		BPL $DBF8
		CMP $DC2B
		BNE $DBC2
		CLC
		RTS
		STA $DC2B
		TAX
		LDA #$00
		STA $DC2A
		LDY LDB27
		LDA $DC28,X
		STA LDB27
		TXA
		EOR #$01
		TAX
		TYA
		STA $DC28,X
		LDA $DC2B
		BNE LDBED
		LDA #$FF
		STA $C002
		LDA #$40
		STA $C000
		CLC
		RTS
LDBED	LDX #$00
		STX $C000
		DEX
		STX $C002
		CLC
		RTS
		LDA #$06
		STA $DC2F
		SEC
		RTS
		PLA
