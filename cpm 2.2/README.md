CP/M 2.2 files folder

This folder contains files specific to CP/M 2.2 on the OSI C3

The goal is to have a complete CP/M 2.2 source that can be built
and modified as necessary.

Files description:

DUMP.ASM
	This is the source for the DUMP utility, that takes a file name
	and outputs the file contents as a Hexadecimal dump.
	
OSIGEN.DMP
	This is a hex dump of the OSIGEN utility on the CP/M 2.22 disk.
	I believe that this is similar to the SYSGEN utility for CP/M.
	More to come... needs disassembly.
	
OSILNKS.ASM
	This is a 'glue' file for the OSI Z80 bios for CP/M.  It shows all
	of the entry points for warm boot, cold boot, I/O etc.  It has some
	initialization code for centronics printers.