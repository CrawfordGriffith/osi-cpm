CP/M 2.2 files folder

This folder contains files specific to CP/M 2.2 on the OSI C3

The goal is to have a complete CP/M 2.2 source that can be built
and modified as necessary.

Files description:

CPM2 on Ohio Scientific Challenger III.pdf
        This is a pdf of a scan of the documentation provided with
	OSI CP/M 2.2 version.  It contains a few pages of information
	on the files provided with the distribution.

DUMP.ASM
	This is the source for the DUMP utility, that takes a file name
	and outputs the file contents as a Hexadecimal dump.
	
OSIGEN.DMP
	This is a hex dump of the OSIGEN utility on the CP/M 2.22 disk.
	I believe that this is similar to the SYSGEN utility for CP/M.
	More to come... needs disassembly.
	
OSILNKS.ASM
	This is a 'part one' of the OSI Z80 bios for CP/M.  It has
	of the routines for serial I/O and initialization code for 
	centronics printers.  There is a jump table that hands off
	disk routines to 'part two' of the BIOS, which I've referred
	to (incorrectly) as BDOS.
	
BDOSDISASM.Z80
        This is the disassembly of the 'part two' BIOS, which handles
	disk routines.  It resides at D000, and has a fully populated
	jump table, with references to the part one BIOS.  Note that this
	is Z80 code!
