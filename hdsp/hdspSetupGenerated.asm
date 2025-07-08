;Code to place before main loop
movlb 00h
movlw 6h
movwf stringLength
movlw 4h
movwf numberOfudc
movlw 0b00000000
movwf controlRegister
call setControlRegister
call defineCustomCharacters
;Code to place after main loop
string:
	brw
	retlw 54h
	retlw 65h
	retlw 73h
	retlw 74h
	retlw 53h
	retlw 74h
	retlw 72h
customCharacter0:
	movlb 00h
	movf udcTableIndex, w
	brw
	retlw 0h
	retlw 0b10111
	retlw 0b10101
	retlw 0b11101
	retlw 0b00001
	retlw 0b11111
	retlw 0b10000
	retlw 0b11111
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
customCharacter2:
	movlb 00h
	movf udcTableIndex, w
	brw
	retlw 02h
	retlw 0b01110
	retlw 0b01110
	retlw 0b01110
	retlw 0b10101
	retlw 0b00100
	retlw 0b01010
	retlw 0b10001
customCharacter3:
	movlb 00h
	movf udcTableIndex, w
	brw
	retlw 03h
	retlw 0b11111
	retlw 0b11111
	retlw 0b11111
	retlw 0b11111
	retlw 0b11111
	retlw 0b11111
	retlw 0b11111
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
udcTable:
	lslf WREG
	brw
	call customCharacter0
	return
	call customCharacter1
	return
	call customCharacter2
	return
	call customCharacter3
	return
	call customCharacter4
	return
