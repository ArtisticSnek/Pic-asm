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
    btfsc IOCBF,5 ;skips when the button has not been pressed
    goto clockSpeedChange
    pastClockSpeedChange:
    
    goto IsrExit
	
    clockSpeedChange:
	bcf IOCBF, 5 ;reset interrupt that caused this
	movlb 0Bh
	btfss T0CON1, 2 ; if the timer is slow now, don't set it slow again
	movlw 85h;10000011B
	btfsc T0CON1, 2; if the timer is fast now, don't set it fast again
	movlw 70h;10000111B
	movwf T0CON1 ;set up Timer0 as LFINTOC, with new speed
	goto pastClockSpeedChange
IsrExit:
    retfie                  ; Return from interrupt

;
; Power-On-Reset entry point
;
PSECT   Por_Vec,global,class=CODE,delta=2;, reloc = 0
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

ledMatrixToggleColumn:
    addwf PCL, f
    goto toggleColumnOne
    goto toggleColumnTwo
    goto toggleColumnThree
    goto toggleColumnFour
    goto toggleColumnFive
    goto toggleColumnSix
    goto toggleColumnSeven
    goto toggleColumnEight
    toggleColumnOne:
	movlw 10h
	xorwf LATB, f
	return
    toggleColumnTwo:
	movlw 10h
	xorwf LATC, f
	return
    toggleColumnThree:
	movlw 08h
	xorwf LATC, f
	return
    toggleColumnFour:
	movlw 02h
	xorwf LATB, f
	return
    toggleColumnFive:
	movlw 20h
	xorwf LATC, f
	return
    toggleColumnSix:
	movlw 04h
	xorwf LATB, f
	return
    toggleColumnSeven:
	movlw 02h
	xorwf LATE, f
	return
    toggleColumnEight:
	movlw 01h
	xorwf LATA, f
	return
	
ledMatrixToggleRow:
    movlb 00h
    addwf PCL, f
    goto toggleRowOne
    goto toggleRowTwo
    goto toggleRowThree
    goto toggleRowFour
    goto toggleRowFive
    goto toggleRowSix
    goto toggleRowSeven
    goto toggleRowEight
    toggleRowOne:
	movlw 01h
	xorwf LATB, f
	return
    toggleRowTwo:
	movlw 01h
	xorwf LATE, f
	return
    toggleRowThree:
	movlw 80h
	xorwf LATC, f
	return
    toggleRowFour:
	movlw 08h
	xorwf LATB, f
	return
    toggleRowFive:
	movlw 01h
	xorwf LATC, f
	return
    toggleRowSix:
	movlw 40h
	xorwf LATC, f
	return
    toggleRowSeven:
	movlw 02h
	xorwf LATC, f
	return
    toggleRowEight:
	movlw 04h
	xorwf LATC, f
	return
togglePixel:
    movlb 00h
    andwf pixelX, f
    andwf pixelY, f
    movf pixelX, w
    lsrf WREG, w
    lsrf WREG, w
    lsrf WREG, w
    lsrf WREG, w
    call ledMatrixToggleColumn
    movf pixelY, w
    call ledMatrixToggleRow
    movlw 0F0h
    movwf pixelX
    movlw 00Fh
    movwf pixelY
    return
    
   
ledMatrixPins:
    clrf TRISB
    clrf TRISC
    clrf TRISE
    clrf TRISA
    clrf LATA
    clrf LATB
    clrf LATC
    clrf LATE
    return

imagePixelMap:
brw
retlw 01h
retlw 02h
retlw 05h
retlw 06h
retlw 10h
retlw 11h
retlw 12h
retlw 13h
retlw 14h
retlw 15h
retlw 16h
retlw 17h
retlw 20h
retlw 21h
retlw 22h
retlw 23h
retlw 24h
retlw 25h
retlw 26h
retlw 27h
retlw 30h
retlw 31h
retlw 32h
retlw 33h
retlw 34h
retlw 35h
retlw 36h
retlw 37h
retlw 41h
retlw 42h
retlw 43h
retlw 44h
retlw 45h
retlw 46h
retlw 52h
retlw 53h
retlw 54h
retlw 55h
retlw 63h
retlw 64h
retlw 0FFh




main:
    setVariables:
	movlb 00h
	movlw 00h
	columnCounter equ 20h
	rowCounter equ 21h
	movwf columnCounter
	movwf rowCounter
	pixelX equ 22h
	pixelY equ 23h
	movlw 0F0h
	movwf pixelX
	movlw 00Fh
	movwf pixelY
	
	pixelCounter equ 24h
	clrf pixelCounter
	prevPixel equ 25h
	clrf prevPixel
    setPins:
	movlb 00h ;select bank 0
	call ledMatrixPins
	clrf PORTE
	bcf TRISE, 2 ;set RE2 as output - board led
	
	clrf PORTB ;reset Port B
	clrf TRISB
	bsf TRISB, 5 ;set RB5 as input - board button
	
	movlb 3Eh
	clrf ANSELB ;turn off analog for port B
	bsf WPUB, 5 ;Set weak pull up for RB5
	
    setInterrputs:
	movlb 3Eh
	bsf IOCBP, 5 ;enable detect for positive edge
	bsf IOCBN, 5 ;enable detect for negative edge
	bcf IOCBF, 5 ;clear interrupt flag

	bsf INTCON, 7 ;enable global interrupts

	movlb 0Eh
	bsf PIE0, 4 ;enable interrupt on change
	
    setTimer:
	movlb 0Bh
	bsf T0CON0, 7 ;set up Timer0 Enabled, 8 bit, 1:1 postscalar

	movlw 70h
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8 prescalar
	
; Application process loop
;
call toggleAllRow
call imagePixelMap
call togglePixel
AppLoop:
    movlb 0Eh ;move to the bank with timer interupt flag
    
    timerWait:
	btfss PIR0, 5; timer0 interupt flag - if set, then has overflowed
	goto timerWait
	
    movlb 0Eh	
    bcf PIR0, 5
    
    movlb 00h
    movf prevPixel, w
    call imagePixelMap
    call togglePixel
    
    movf pixelCounter, w
    call imagePixelMap
    btfsc WREG, 7 ;pixels end with a FFh, so when this is reached, clear
    goto resetPixelCounter
    call togglePixel
    movf pixelCounter, w
    movwf prevPixel
    incf pixelCounter
    pastPixelReset:
    
    movlb 00h
    btfss LATE, 2 ;if led is off, skip step to turn it off
    goto ledOff
    
    btfsc LATE, 2 ;if led is on, skip step to turn it on
    goto ledOn
    
    goto    AppLoop 
    resetPixelCounter:
	movlb 00h
	clrf pixelCounter
	clrf prevPixel
	movlw 00h
	call imagePixelMap
	call togglePixel
	incf pixelCounter
	goto pastPixelReset
    ledOn:
	movlb 00h
	bcf LATE, 2
	movlb 0Eh ;move to the bank with timer interupt flag
	goto AppLoop
    ledOff:
	movlb 00h
	bsf LATE, 2
	movlb 0Eh ;move to the bank with timer interupt flag
	goto AppLoop
	
    toggleAllColumn:
	movlb 00h
	clrf columnCounter ;reset counter
	toggleAllColumnLoop: ;iterate through each column, toggling it as you go
	    movf columnCounter, w
	    call ledMatrixToggleColumn 

	    movlb 00h
	    incf columnCounter
	    movf columnCounter, w
	    sublw 08h
	    btfss STATUS, 2
	    goto toggleAllColumnLoop
	clrf columnCounter
	return
	
    toggleAllRow:
	movlb 00h
	clrf rowCounter
	toggleAllRowLoop:
	    movf rowCounter, w
	    call ledMatrixToggleRow

	    movlb 00h
	    incf rowCounter
	    movf rowCounter, w
	    sublw 08h
	    btfss STATUS, 2
	    goto toggleAllRowLoop
	clrf rowCounter
	return
    toggleAllLeds:
	movlb 00h
	movlw 0FFh
	xorwf LATC, f
	movlw 0Fh
	xorwf LATB, f
	movlw 03h
	xorwf LATE, f
	movlw 01h
	xorwf LATA, f
	return
    
    END     resetVec