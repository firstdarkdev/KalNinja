!zone GRAPHICS
  ;A contains the character, X and Y contain the buffer index.
  ;byte index is required in hopes the programmer will do the maths themselves, usually before actually coding.
  .PUT_CHAR:
    clc ;silly adc logic, if carry is set, 1 is added.  stop that.
    pha ;character to put
    
    txa ;hi byte.
    adc ENGINE.BUFFER_POINTER_HI ;add the buffer ram pointer to it.
    sta .PUT_CHAR.ADDRESS + 2
    
    pla ;get the character to put
    .PUT_CHAR.ADDRESS:
    sta $0000,Y ;self modifying
  
    rts
    
  ;A contains the character, X and Y contain the buffer index.
  ;byte index is required in hopes the programmer will do the maths themselves, usually before actually coding.
  .PUT_COLOR:
    clc ;silly adc logic, if carry is set, 1 is added.  stop that.
    pha ;character to put
    
    txa ;hi byte.
    adc #>ENGINE.COLOR_BACK_BUFFER ;add the buffer ram pointer to it.
    sta .PUT_COLOR.ADDRESS + 2
    
    pla ;get the character to put
    .PUT_COLOR.ADDRESS:
    sta $0000,Y ;self modifying
  
    rts
    
  ;set the vic registers in an easily accessed manner.
  .SET_CHAR_MULTICOLORS:
    sta VIC.BACKGROUND_COLOR
    stx VIC.CHARSET_MULTICOLOR_1
    sty VIC.CHARSET_MULTICOLOR_2
    rts