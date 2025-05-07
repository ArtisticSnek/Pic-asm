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
	btfsc T0CON1, 2 ; if the timer is slow now, don't set it slow again
	movlw 10000011B
	btfss T0CON1, 2; if the timer is fast now, don't set it fast again
	movlw 10000111B
	
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
PSECT   udata_shr;,global,class=RAM,space=1,delta=2;,noexec
;ledZero equ 020h
;ledOne equ 021h
;ledTwo equ 022h
;ledThree equ 023h
;ledFour equ 024h
;ledFive equ 025h
;ledSix equ 026h
;ledSeven equ 027h
;ledEight equ 028h
;ledNine equ 029h
;ledCounter equ 02Ah
ledStatesList: db 0DEh, 00Ch, 0D9h, 05Dh, 00Fh, 057h, 0D7h, 01Ch, 0DFh, 05Fh, 020h
;ledZero: db 0DEh ;define all as a list, then change the point you read in ram?? perhaps
;ledOne: db 00Ch
;ledTwo: db 0D9h
;ledThree: db 05Dh
;ledFour: db 00Fh
;ledFive: db 057h
;ledSix: db 0D7h
;ledSeven: db 01Ch
;ledEight: db 0DFh
;ledNine: db 05Fh
;ledDot: db 020h

ledCounter: db 00h
;define variables as necessary 
PSECT   MainCode,global,class=CODE,delta=2
    
EightSegPins:
    movlb 00h
    clrf TRISC
    clrf LATC
    return

EightSegDisplay:
    ;banksel ledZero
    movlb 00h
    movlw ledStatesList
    addwf ledCounter, w;store result in w
    
    
    
    clrf FSR0L
    clrf FSR0H
    
    movwf FSR0L
    movf BSR, w
    btfsc BSR, 0
    bsf FSR0L,7 ;move the location into the indirect file pointer register
    lsrf WREG
    movwf FSR0H
    
    movf INDF0, w
    movlb 00h
    movwf LATC
    banksel ledStatesList
    incf ledCounter
    return


main:
    defineVariables:
	movlb 00h
	movlw 00h
	movwf ledCounter
	
    setPins:
	movlb 00h ;select bank 0
	clrf PORTE
	bcf TRISE, 2 ;set RE2 as output - board led
	
	clrf PORTB ;reset Port B
	clrf TRISB
	bsf TRISB, 5 ;set RB5 as input - board button
	
	movlb 3Eh
	clrf ANSELB ;turn off analog for port B
	bsf WPUB, 5 ;Set weak pull up for RB5
	
	call EightSegPins
	
	
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
	movlw 83h
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8 prescalar
	
; Application process loop
;
AppLoop:
    movlw PIR0
    
    
    movlb 0Eh ;move to the bank with timer interupt flag
    
    timerWait:
	btfss PIR0, 5; timer0 interupt flag - if set, then has overflowed
	goto timerWait
	
    movlb 0Eh	
    bcf PIR0, 5
    
    movf ledStatesList, w
    
    movlw ledCounter
    
    
    call EightSegDisplay
    
    ;movf ledZero, w
    
    movlb 00h
    btfss LATE, 2 ;if led is off, skip step to turn it off
    goto ledOff
    
    btfsc LATE, 2 ;if led is on, skip step to turn it on
    goto ledOn
    
    goto    AppLoop 
    
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
    
    END     resetVec