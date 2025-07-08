customCharacter4:
	movlb 00h
	movf udcTableIndex, w
	brw
	retlw 04h
	retlw 0b00000
	retlw 0b00100
	retlw 0b01100
	retlw 0b00100
	retlw 0b00110
	retlw 0b00010
	retlw 0b00000
