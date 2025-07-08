#include <xc.inc>
PROCESSOR 16F15276
PAGEWIDTH 132
RADIX DEC

; CONFIG1
  CONFIG  FEXTOSC = OFF         ; External Oscillator Mode Selection bits (Oscillator not enabled)
  CONFIG  RSTOSC = HFINTOSC_32MHZ; Power-up Default Value for COSC bits (HFINTOSC (32 MHz))
  CONFIG  CLKOUTEN = OFF        ; Clock Out Enable bit (CLKOUT function is disabled; I/O function on RA4)
  CONFIG  VDDAR = HI            ; VDD Range Analog Calibration Selection bit (Internal analog systems are calibrated for operation between VDD = 2.3V - 5.5V)

; CONFIG2
  CONFIG  MCLRE = EXTMCLR       ; Master Clear Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RA3 pin function is MCLR)
  CONFIG  PWRTS = PWRT_64       ; Power-up Timer Selection bits (PWRT set at 64 ms)
  CONFIG  WDTE = OFF            ; WDT Operating Mode bits (WDT disabled; SEN is ignored)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable bits (Brown-out Reset disabled)
  CONFIG  BORV = LO             ; Brown-out Reset Voltage Selection bit (Brown-out Reset Voltage (VBOR) set to 1.9V)
  CONFIG  PPS1WAY = OFF         ; PPSLOCKED One-Way Set Enable bit (The PPSLOCKED bit can be set and cleared as needed (unlocking sequence is required))
  CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset Enable bit (Stack Overflow or Underflow will cause a reset)

; CONFIG3

; CONFIG4
  CONFIG  BBSIZE = BB512        ; Boot Block Size Selection bits (512 words boot block size)
  CONFIG  BBEN = OFF            ; Boot Block Enable bit (Boot Block is disabled)
  CONFIG  SAFEN = OFF           ; SAF Enable bit (SAF is disabled)
  CONFIG  WRTAPP = OFF          ; Application Block Write Protection bit (Application Block is not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot Block is not write-protected)
  CONFIG  WRTC = OFF            ; Configuration Registers Write Protection bit (Configuration Registers are not write-protected)
  CONFIG  WRTSAF = OFF          ; Storage Area Flash (SAF) Write Protection bit (SAF is not write-protected)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (Low Voltage programming enabled. MCLR/Vpp pin function is MCLR. MCLRE Configuration bit is ignored.)

; CONFIG5
  CONFIG  CP = OFF              ; User Program Flash Memory Code Protection bit (User Program Flash Memory code protection is disabled)

#define _XTAL_FREQ 32000000

;   Interrupt vector and handler
PSECT   Isr_Vec,global,class=CODE,delta=2
global IsrHandler
IsrHandler:
    movlb 3Eh
    ;handle interrupts
    goto IsrExit
IsrExit:
    retfie                  ; Return from interrupt

;
; Power-On-Reset entry point
;
PSECT   Por_Vec,global,class=CODE,delta=2
global  resetVec
resetVec:
    pagesel Start
    goto Start
;
; Initialize the PIC hardware
; 
PSECT Start_Code, global, class = CODE, delta=2
Start:

    clrf INTCON              ; Disable all interrupt sources
    banksel PIE0
    clrf PIE0
    clrf PIE1
    clrf PIE2
   
    pagesel main
    goto    main
;
; Main application data
;
PSECT   udata;,global,class=RAM,space=1,delta=2;,noexec

PSECT   MainCode,global,class=CODE,delta=2
main:
    setVariables:
	movlb 00h
	displayIndex equ 20h
	clrf displayIndex
	stringIndex equ 21h
	clrf stringIndex
	stringLength equ 22h
	clrf stringLength
	character equ 23h
	clrf character
	controlRegister equ 24h
	clrf controlRegister
	udcNumber equ 26h ;the custom character number 
	clrf udcNumber
	udcTableIndex equ 27h ;index in the table currently being read from
	clrf udcTableIndex
	numberOfudc equ 28h
	clrf numberOfudc
	flashRegister equ 29h
	clrf flashRegister	;bit 7 - flash on or off, bits 0-2 - character code
	wregShadow equ 30h
	clrf wregShadow
	counter equ 31h
	clrf counter
	
    setPins:
	movlb 00h ;select bank 0
	
	clrf PORTD ;All of pins D are used for data
	clrf TRISD ;set as outputs
	
	clrf PORTE
	clrf TRISE ; RE0 - Write enable, RE1 - Chip enable, RE2 - clock/ board LED
	bsf LATE, 0
	bsf LATE, 1
	
	clrf PORTA
	clrf TRISA; RA0-4 Data, RA5 - FL
	bsf LATA, 3
	bsf LATA, 4
	bsf LATA, 5
	
	clrf PORTC
	clrf TRISC; RC0 - RST, RC1 - Read enable
	bsf LATC, 0
	bsf LATC, 1
	
	clrf PORTB ;reset Port B
	bsf TRISB, 5 ;set RB5 as input - board button
	
	movlb 3Eh
	clrf ANSELB ;turn off analog for port B
	bsf WPUB, 5 ;Set weak pull up for RB5
	
	clrf ANSELA
	clrf ANSELB
	clrf ANSELC
	clrf ANSELD
	
    setInterrputs:
	
	
    setTimer:
	movlb 0Bh
	movlw 80h
	movwf T0CON0
	;bsf T0CON0, 7 ;set up Timer0 Enabled, 8 bit, 1:1 postscalar

	movlw 84h
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8 prescalar
	
	movlb 04h
	
	movlw 00h ;set up Timer1 as 1:1 prescaleer, synced, and disabled
	movwf T1CON
	movlw 07h ;set Timer1 as MFINTOSC 32khz
	movwf T1CLK
	
; Application process loop
;
movlb 00h
bcf LATC, 0 ;reset display
bsf LATC, 0

movlw 80h
movwf flashRegister
	
;paste generated code here
movlb 00h
movlw 7h
movwf stringLength
movlw 4h
movwf numberOfudc
movlw 0b00001000
movwf controlRegister
call setControlRegister
call defineCustomCharacters
;end of generated code
	
	


;call updateFlash

AppLoop:
    movlb 0Eh ;move to the bank with timer interupt flag
    timerWait:
	btfss PIR0, 5; timer0 interupt flag - if set, then has overflowed
	goto timerWait	
    movlb 0Eh	
    bcf PIR0, 5 
    
    movlb 00h
    call writeString
    incf counter
    
    goto AppLoop
    
writeBlock:
    movlb 00h
    bcf LATE, 0 ;enable write
    call fastDelay
    
    movlb 00h
    bsf LATE, 0 ;disable write
    call fastDelay
    return

updateFlash: 
    movlb 00h
    clrf LATA
    bcf LATA, 5
    movf flashRegister, w
    bcf WREG, 7
    addwf LATA, f
 
    
    clrf LATD
    btfsc flashRegister, 7
    bsf LATD, 0
    
    bcf LATE, 1 ;enable chip
    call fastDelay
    
    call writeBlock
    
    bsf LATE, 1
    call fastDelay
    return
    
    
writeCustomCharacter:
    movlb 00h
    
    movlw 20h
    addwf udcNumber, w
    movwf LATA ;FL high, rest are low - write to UDC, besides the character in which to write
    
    clrf udcTableIndex ;point to attribute 0 of table
    movf udcNumber, w
    call udcTable ;get atribute #0 - UDC address. Table of all UDC -> table specific to one UDC -> data
    movwf LATD ;move this address to port D
    call fastDelay
    
    movlb 00h
    bcf LATE, 1 ;enable chip
    call fastDelay
    
    ;Write cycle 1 only sends the UDC address
    call writeBlock
    
    movlb 00h
    movlw 28h ;00101000
    movwf LATA ;set A register to the correct value to start writing data
    ;next 7 write cycles are sending each row of the character
    ;register udcTableIndex will be used to keep track of what rows have been sent, by knowing what rows of the table have been read
    sendingCharacterRows:
	movlb 00h
	incf udcTableIndex
	
	movf udcNumber, w
	call udcTable ;wreg now contains the row of pixels to send
	
	movlb 00h
	movwf LATD
	call fastDelay
	
	call writeBlock
	
	movlb 00h
	incf LATA
	movlw 07h
	subwf udcTableIndex, w ;Compare current index to 7 (number of rows)
	btfss STATUS, 2;check if zero - if so, sending is completed
	goto sendingCharacterRows
    clrf udcTableIndex
    bsf LATE, 1 ;disable chip
    call fastDelay
    return
            
setControlRegister:
    movlb 00h
    movlw 30h
    movwf LATA
    call fastDelay
    
    movlb 00h
    bcf LATE, 1 ;enable chip
    call fastDelay
    
    movlb 00h
    movf controlRegister, w
    movwf LATD ;send command
    call fastDelay
    
    call writeBlock
    
    movlb 00h
    clrf LATD ;clear data
    bsf LATE, 1 ;disable chip enable
    call fastDelay
    return
    
writeString: ;wreg will determine what string is written
    movlb 00h
    writingToDisplay:
	movlw 00h
	call stringTable ;wreg decides what string, stringIndex determines what character of that string
	call stringRegister ;will set w to the character code
	movlb 00h
	movwf character ;move this to the character register - will be read by setCharacter
	call setCharacter
	
	movlb 00h
	movf stringIndex, w
	subwf stringLength, w ;Compare current index to length of string
	btfsc STATUS, 2;check if zero - if so, string is completed
	goto doneWritingToDisplay
	incf stringIndex ;if not done, increment display index and string index
	incf displayIndex
	goto writingToDisplay ;loop back
    doneWritingToDisplay:
    movlb 00h
    clrf displayIndex ;reset these registers
    clrf stringIndex
    return
	  
setCharacter: 
    movlb 00h
    movlw 78h ;set up A register to write a default character
    addwf displayIndex, w ;add the display index - such that the other parts of the A register remain untouched
    movwf LATA
    call fastDelay
    
    movlb 00h
    bcf LATE, 1 ;enable chip
    call fastDelay
    
    movlb 00h
    movf character, w
    movwf LATD ;send character
    call fastDelay
    
    call writeBlock
    
    movlb 00h
    clrf LATD ;clear data
    bsf LATE, 1 ;disable chip enable
    call fastDelay
    
    return
    
fastDelay:
    movlb 04h
    bsf T1CON, 0 ;enable timer
    waitForFastTimer:
	btfss TMR1L, 4 ;in theory, could look at bit 4 to get ~280us clock
	goto waitForFastTimer
    bcf T1CON, 0
    clrf TMR1H
    clrf TMR1L
    return

defineCustomCharacters:
    movlb 00h
    clrf udcNumber
    defineCustomCharacterLoop:
	call writeCustomCharacter
	movlb 00h
	movf udcNumber, w 
	subwf numberOfudc, w
	btfsc STATUS, 2;check if zero - if so, sending is completed
	return
	incf udcNumber
	goto defineCustomCharacterLoop
	
stringRegister:
    movlb 00h
    movf stringIndex, w
    movwf wregShadow
    lslf WREG
    addwf wregShadow, w
    movlb 00h
    brw
    btfss INDF0, 0
    retlw 30h
    retlw 31h
    btfss INDF0, 1
    retlw 30h
    retlw 31h
    btfss INDF0, 2
    retlw 30h
    retlw 31h
    btfss INDF0, 3
    retlw 30h
    retlw 31h
    btfss INDF0, 4
    retlw 30h
    retlw 31h
    btfss INDF0, 5
    retlw 30h
    retlw 31h
    btfss INDF0, 6
    retlw 30h
    retlw 31h
    btfss INDF0, 7
    retlw 30h
    retlw 31h

;start of generated code
stringTable:
    lslf WREG
    brw
    call stringRegister
    return
    call string
    return
    
string:
    movlb 00h
    movf stringIndex, w
    brw
    retlw 00h
    retlw 00h
    retlw 00h
    retlw 00h
    retlw 00h
    retlw 00h
    retlw 00h
    retlw 00h
    
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
;end of generated code
    END     resetVec
    

    