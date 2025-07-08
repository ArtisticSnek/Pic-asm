customCharacter1:
	movlb 00h
	movf udcTableIndex, w
	brw
	retlw 01h
	retlw 0b00000
	retlw 0b01110
	retlw 0b10011
	retlw 0b10011
	retlw 0b10011
	retlw 0b01110
	retlw 0b01010
