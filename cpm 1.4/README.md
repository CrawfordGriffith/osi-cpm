CP/M 1.4 files folder

This folder contains files specific to CP/M 1.4 on the OSI C3

The goal is to have a complete CP/M 1.4 source that can be built
and modified as necessary.

Description of files in this folder:

CPM.MAN (originally named CP/M.MAN)

	Mini-manual for CP/M 1.4 (text file).  Interesting note on the SAVE
	command: load data into RAM from another OS (presumably OS65D), cold 
	boot into CP/M and use SAVE to move the RAM data to disk.
	
CPM.DMP

	Dump of CPM.COM which should set up a disk for use with OSI CP/M 1.4 .
	(as yet untested/verified)
	
DSKDRV.MAC

	FORTRAN-80 RUNTIME DISK DRIVER -- CP/M VERSIONS

IOINIT.MAC

	Appears to be the I/O initialization routine, probably for FORTRAN-80

LPTDRV.MAC

	FORTRAN-80 RUNTIME LINE PRINTER DRIVER


TEST.MAC

	Source file for a simple Macro Assembler program in CP/M.
	
WFBIOS.DMP

	Hex dump of WFBIOS.COM, which will write the OSI CP/M BIOS to a disk
	(as claimed when I ran it, untested as yet)
	
ZBIOS.ASM

	Source for the CP/M 1.4 BIOS which does some calls directly to the
	OSI hardware (tty, centronics).  Most of the calls are to the 6502 with
	associated code to do the software processor swap.

CPM_V14_6502_bootloader (disassembly/explanation by Mark Spankus)

	OSI CPM uses track 0 to boot/load 6502 code, & tiny Z80 code which jumps 
	right back to 6502 to load CPM, track 1 contains CPM core.  Track 2 contains 
	the CPM directory, so is the start of a CPM disk (logical block 0) from 
	what I can tell. (Floppy Track 0 = CPM Track 1) One OSI track has 26 CPM disk blocks.
