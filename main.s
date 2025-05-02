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



; Skip macros
;
skipnc  MACRO
    btfsc   STATUS,STATUS_C_POSITION
  ENDM

skipc  MACRO
    btfss   STATUS,STATUS_C_POSITION
  ENDM

skipnz  MACRO
    btfsc   STATUS,STATUS_Z_POSITION
  ENDM

skipz  MACRO
    btfss   STATUS,STATUS_Z_POSITION
  ENDM
;
; Power-On-Reset entry point
;
    PSECT   Por_Vec,global,class=CODE,delta=2
    global  resetVec
resetVec:
    PAGESEL Start
    goto    Start
;
;   Data space use by interrupt handler to save context
    PSECT   Isr_Data,global,class=COMMON,space=1,delta=1,noexec
;
    GLOBAL  WREG_save,STATUS_save,PCLATH_save
;
WREG_save:      DS  1
STATUS_save:    DS  1
PCLATH_save:    DS  1
;
;   Interrupt vector and handler
    PSECT   Isr_Vec,global,class=CODE,delta=2
   GLOBAL  IsrVec
;
IsrVec:
    movwf   WREG_save       ; This context saving and restore may 
    swapf   STATUS,W        ; not be required for the PIC16F18313
    movwf   STATUS_save     ; It's here as an example just in
    movf    PCLATH,W        ; case you need it.
    movwf   PCLATH_save
;
IsrHandler:
;
IsrExit:
    movf    PCLATH_save,W   ; This context saving and restore may
    movwf   PCLATH          ; not be required for the PIC16F18313
    swapf   STATUS_save,W   ; It's here as an example just in
    movwf   STATUS          ; case you need it.
    swapf   WREG_save,F
    swapf   WREG_save,W
    retfie                  ; Return from interrupt
;
; Initialize the PIC hardware
;
Start:
    ;clrf    INTCON              ; Disable all interrupt sources
    ;banksel PIE0
    ;clrf    PIE1
    ;clrf    PIE2
    movlw 0C1h
    movwf INTCON ;enable interrupts
    
    movlw 0Eh
    movwf BSR
    
    movlw 10h ;set interupt on change enable on
    movlw PIE0
    
    movlw 3Eh
    movwf BSR
    
    movlw 00100000B
    movwf IOCBP ;set pin interrupt on change
    movwf IOCBP
    movwf IOCBN ;for positive and negative

    pagesel main
    goto    main
;
; Main application data
;
    PSECT   MainData,global,class=RAM,space=1,delta=1,noexec
    global  Count
Count:  ds  1
;
; Main application code
;
    PSECT   MainCode,global,class=CODE,delta=2
;
; Initialize the application
;
main:
    setTimer:
	movlw 0Bh
	movwf BSR ;select bank 11
	bsf T0CON0, 7 ;set up Timer0 Enabled, 8 bit, 1:1 postscalar
	movlw 10000011B
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8 prescalar

    setPins:
	movlw 00h ;select bank 0
	movwf BSR
	
	clrf TRISE ;Set Port E to be outputs
	clrf PORTB ;reset Port B
	
	movlw 0FFh
	movwf TRISB; set port B to be inputs
	
	movlw 3Eh
	movwf BSR
	
	clrf ANSELB ;turn off analog for port B
	bsf WPUB, 5 ;Set weak pull up for RB5
	
	
	
; Application process loop
;
AppLoop:
    movlw 0Eh ;move to the bank with timer interupt flag
    movwf BSR
    
    timerWait:
	btfss PIR0, 5; timer0 interupt flag - if set, then has overflowed
	goto timerWait
	
    bcf PIR0, 5
	
    movlw 00h
    movwf BSR
	
    btfss PORTB, 5
    goto clockSpeedUp
	
    btfsc PORTB, 5
    goto clockSpeedDown
	
    pastButton:
    
    movlw 00h
    movwf BSR
    ;btfsc PORTB, 5
    btfss LATE, 2 ;if led is off, skip step to turn it off
    goto ledOff
    
    ;btfss PORTB, 5
    btfsc LATE, 2 ;if led is on, skip step to turn it on
    goto ledOn
    
    goto    AppLoop  
    
    ledOn:
	movlw 00h
	movwf BSR
	bcf LATE, 2
	
	movlw 0Eh ;move to the bank with timer interupt flag
	movwf BSR
	goto AppLoop
    ledOff:
	movlw 00h
	movwf BSR
	bsf LATE, 2
	
	movlw 0Eh ;move to the bank with timer interupt flag
	movwf BSR
	goto AppLoop
    clockSpeedUp:
	movlw 0Bh
	movwf BSR
	btfss T0CON1, 2
	goto pastButton
	movlw 10000011B
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:8
	goto pastButton
    clockSpeedDown:
	movlw 0Bh
	movwf BSR
	btfsc T0CON1, 2
	goto pastButton
	movlw 10000111B
	movwf T0CON1 ;set up Timer0 as LFINTOC, Synced, 1:256
	goto pastButton
;
; Declare Power-On-Reset entry point
;
    END     resetVec



