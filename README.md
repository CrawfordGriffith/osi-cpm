# osi-cpm
 Files for the OSI CP/M operating system
 
This is my repository of CP/M files from my OSI Challenger 3-OEM

The folders are:

	apps 	- applications not specific to the CP/M release
	cpm 1.4	- files and sources for OSI CP/M 1.4
	cpm 2.2	- files and sources for OSI CP/M 2.2
	
	
The purpose of this repository is to share the code I found on disks 
that came with my OSI C3.  CP/M disks are rare for this system, so I
am attempting to both share what I have, as well as have a place to
reverse-engineer the parts that have no source code.

A little bit about the OSI Challenger 3:

	The OSI Challenger 3 was an unusual machine.  While most of the
	OSI systems were based on the 6502 processor, the Challenger 3 had
	three CPU's: a 6502, a 6800, and a Z80.  The system boots with the
	6502 active, and the C3 will act like a normal OSI system.  There
	is a software switch, and some utilities that allow the C3 to change
	to one of the other processors.  Some C3's had a physical switch for
	processor select.  Having a Z80 allowed the C3 to run CP/M, so this
	repository is for that unique CP/M version.

CP/M on the OSI came in two versions

OSI CP/M 1.4

	The first version of CP/M on the C3 used both the 6502 and Z80 
	processors.  The 6502 handled the hardware for input/output like
	serial ports and disk controller, while the Z80 did most of the
	processing.  While this showed off the co-operative processing of
	multiple different processors, it was inefficient and slow.
	
OSI CP/M 2.2

	The second version of CP/M for the C3 did not use the 6502 for 
	I/O, and was therefore faster.  In addition, CP/M 2.x was the most
	popular CP/M version in use at the time.  This CP/M version sets
	up the Z80, and a BIOS using the Z80 to directly control the C3 hardware.
	
	
OSI CP/M disk formats (To be completed)

	Since CP/M was very popular at the time, one might think that the OSI
	C3 could exchange disk media with other CP/M machines of the day.  Not
	the case unfortunately - OSI chose to make their CP/M more compatible
	with their OS65x operating systems.
	
	
