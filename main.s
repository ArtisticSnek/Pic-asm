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
    movlb 0Eh
    btfsc PIR1, 0
    goto adcToPwmInterrupt
    
    pastAdcToPwmInterrupt:
    
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
    adcToPwmInterrupt:
	movlb 0Eh
	bcf PIR1, 0
	goto pastAdcToPwmInterrupt
	
	movlb 01h
	movf ADRESL, w
	movlb 06h
	movwf PWM3DCL
	
	movlb 01h
	movf ADRESH, w
	movlb 06h
	movwf PWM3DCH
	
	movlb 01h
	clrf ADRESL
	clrf ADRESH
	
	goto pastAdcToPwmInterrupt
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
PSECT   MainData,global,class=RAM,space=1,delta=1,noexec
;define variables as necessary 
PSECT   MainCode,global,class=CODE,delta=2

main:

    setPins:
	movlb 00h ;select bank 0
	clrf TRISB
	clrf PORTE
	bcf TRISE, 2 ;set RE2 as output 
	;clrf TRISC
	clrf PORTB ;reset Port B
	;clrf LATC
	
	bsf TRISB, 5
	
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
	movlw 83h
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8 prescalar
	
    setPwm:
	movlb 05h
	
	bsf TRISB, 0 ;turn the pin output drivers off
	movlb 06h
	clrf PWM3CON
	
	movlb 05h
	movlw 0FFh
	movwf T2PR ;timer 2 period
	
	movlb 06h
	movlw 00h
	movwf PWM3DCH
	movlw 000h
	movwf PWM3DCL ;set the duty cycle register
	
	movlb 0Eh
	bcf PIR1, 6 ;clear Timer2 interupt flag
	
	movlb 05h
	
	;bsf T2HLT, 7 ;Sync to Fosc/4, not sure if this is needed as Fosc/4 is the input
	bsf T2HLT, 5 ;Sync to timer clock input
	
	bsf T2CLKCON, 0 ;Clock source - Fosc/4
	
	movlw 11110000B ;set as on, 1:128 prescalar, no postscalar
	movwf T2CON
	
	movlb 06h
	bsf PWM3CON, 7
	
	movlb 0Eh
	waitForPwmTimerOverflow:
	    btfss PIR1, 6
	    goto waitForPwmTimerOverflow
	bcf PIR1, 6
	bcf TRISB, 0
	
	movlb 3Eh
	movlw 03h
	movwf RB0PPS
    setAnalogPins:
	movlb 00h
	bsf TRISC, 2
	bsf ANSELC, 2
	
	movlb 01h
	movlw 01001000B
	movwf ADCON0 ;set to RC2 as input, and as ACD enabled
	clrf ADCON0
	;movlw 0Dh
	;movwf ADACT ;set triggers on read of ADRESH
	clrf ADACT
	bsf ADCON0, 0
	
	movlb 0Eh
	bsf PIE1, 0 ;analog interrupt enable
	bsf INTCON, 7 ;GIE
	bsf INTCON, 6 ;PEIE
	
	movlb 01h
	bsf ADCON0, 1
	
; Application process loop
;
AppLoop:
    movlb 0Eh ;move to the bank with timer interupt flag
    
    timerWait:
	btfss PIR0, 5; timer0 interupt flag - if set, then has overflowed
	goto timerWait
	
    movlb 0Eh	
    bcf PIR0, 5
    
    movlb 01h
    bsf ADCON0, 1
    
    
    ;movlb 06h
    ;incf PWM3DCH
    
    ;movf PWM3DCH, w
    ;sublw 40h
    ;btfsc STATUS, 2
    ;goto resetPwmDC
    
    
    

    
    movlb 00h
    btfss LATE, 2 ;if led is off, skip step to turn it off
    goto ledOff
    
    btfsc LATE, 2 ;if led is on, skip step to turn it on
    goto ledOn
    
    goto    AppLoop 
    
    resetPwmDC:
	movlb 06h
	clrf PWM3DCH
    
    ledOn:
	movlb 00h
	bcf LATE, 2
	
	movlb 0Eh ;move to the bank with timer interupt flag
	goto AppLoop
    ledOff:
	movlb 00h
	bsf LATE, 2
	
	movlw 0Eh ;move to the bank with timer interupt flag
	movwf BSR
	goto AppLoop
    
    END     resetVec