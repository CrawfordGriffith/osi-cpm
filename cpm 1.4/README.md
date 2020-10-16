CP/M 1.4 files folder

This folder contains files specific to CP/M 1.4 on the OSI C3

The goal is to have a complete CP/M 1.4 source that can be built
and modified as necessary.

Description of files in this folder:

CPM.MAN

	Mini-manual for CP/M 1.4 (text file)
	
DSKDRV.MAC

	FORTRAN-80 RUNTIME DISK DRIVER -- CP/M VERSIONS

IOINIT.MAC

	Appears to be the I/O initialization routine, probably for FORTRAN-80

LPTDRV.MAC

	FORTRAN-80 RUNTIME LINE PRINTER DRIVER


TEST.MAC

	(currently empty, sorry)
	
WFBIOS.DMP

	Hex dump of WFBIOS.COM, which will write the OSI CP/M BIOS to a disk
	(as claimed when I ran it, untested as yet)
	
ZBIOS.ASM

	Source for the CP/M 1.4 BIOS which does some calls directly to the
	OSI hardware (tty, centronics).  Most of the calls are to the 6502 with
	associated code to do the software processor swap.

