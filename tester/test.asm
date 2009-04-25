; test.asm (v0)
; 
; Generates a simple 16bit pattern consisting of an 8bit counter
; and an 8(9)bit circular shifter with one bit set.
;
; target: ATmega8515
; port A: counter
; port C: shifter
;
; For more information go to:
; http://sump.org/projects/analyzer


.equ	PORTA = 0x1b
.equ	DDRA = 0x1a  
.equ	PORTC = 0x15
.equ	DDRC = 0x14 

.def	a = r16
.def	c = r18

;===== program =========================================================

	ldi	a, 0b11111111
	out	DDRA, a
	out	DDRC, a

	ldi	a, 0
	ldi	c, 1
loop:	inc	a
	out	PORTA, a
	rol	c
	out	PORTC, c
	rjmp	loop

;===== eof =============================================================
