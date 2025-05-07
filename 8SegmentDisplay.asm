#include <xc.inc>
PROCESSOR 16F15276
PAGEWIDTH 132
RADIX DEC
psect LedCode, global, class=code, delta=2

EightSegPins:
    movlb 00h
    clrf TRISC
    clrf LATC
    return

EightSegDisplay:
    movlw 00
    incf WREG
    return
