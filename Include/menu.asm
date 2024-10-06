!zone MENU
  ;variables
  .OPTIONS.LO = $10
  .OPTIONS.HI = $11
  .OPEN = $12
  ;$13 is used by Current I/O Device Number
  .SELECTION = $14
  .CHOICE_POINTER.LO = $15
  .CHOICE_POINTER.HI = $16
  .CHOICE.X = $17
  .CHOICE.Y = $18
  .CHOICE_DIMENSIONS.X = $19
  .CHOICE_DIMENSIONS.Y = $1A
  .B = $1B ;register B
  .C = $1C ;register C
  .CURRENT_CHOICE = $1D
  .INPUT_ACTIVE = $1E
  .SELECTED = $1F
  
  .ELEMENT.END = 0
  .ELEMENT.TEXT = 1
  .ELEMENT.ICON = 2
  .ELEMENT.CHOICE = 3
  .ELEMENT.CHOICE.ON_SELECT = 4
  .ELEMENT.CHOICE.ON_CHOSEN = 5
  .ELEMENT.CHOICE.ON_NOT_CHOSEN = 6
  .ELEMENT.BACKGROUND = 7
  
  
  ;functions
  .NEW:
    ;store parameters
    stx .OPTIONS.LO
    sty .OPTIONS.HI
    
    ;reset selection cursor.
    lda #1
    sta .CHOICE.X
    sta .CHOICE.Y
    sta .SELECTION
    
    ;menu is open
    lda #1
    sta .OPEN
    
    rts
    
    
    
  ;this routine is only required if you want total control of the screen!
  .END:
    ;reset menu pointers so the menu does not get interpreted.
    lda #0
    sta .OPTIONS.LO
    sta .OPTIONS.HI
    sta .OPEN
    sta .INPUT_ACTIVE
    
    rts
    
    
    
  ;allows the menu to take control of the joystick
  .SUBSCRIBE_INPUT:
    jsr INPUT.JOY.RESET
  
    ;let's only listen for press, release is ignored.
    ldx #>.INTERPRET.ON_DOWN_PRESSED
    ldy #<.INTERPRET.ON_DOWN_PRESSED
    jsr INPUT.JOY.SUBSCRIBE.DOWN
    ldx #>.INTERPRET.ON_UP_PRESSED
    ldy #<.INTERPRET.ON_UP_PRESSED
    jsr INPUT.JOY.SUBSCRIBE.UP
    ldx #>.INTERPRET.ON_LEFT_PRESSED
    ldy #<.INTERPRET.ON_LEFT_PRESSED
    jsr INPUT.JOY.SUBSCRIBE.LEFT
    ldx #>.INTERPRET.ON_RIGHT_PRESSED
    ldy #<.INTERPRET.ON_RIGHT_PRESSED
    jsr INPUT.JOY.SUBSCRIBE.RIGHT
    ldx #>.INTERPRET.ON_FIRE_PRESSED
    ldy #<.INTERPRET.ON_FIRE_PRESSED
    jsr INPUT.JOY.SUBSCRIBE.FIRE
    
    ;activate inputs.
    lda #1
    sta .INPUT_ACTIVE
  
    rts
    
  .INTERPRET.EXIT:
    rts

  .INTERPRET:
    lda .OPEN
    beq .INTERPRET.EXIT ;don't do anything if the menu is closed.
    
    ;reset interpreter cursor 
    lda .OPTIONS.LO
    sta .INTERPRET.NEXT_BYTE + 1
    lda .OPTIONS.HI
    sta .INTERPRET.NEXT_BYTE + 2
    
    ;get dimensions of the menu choices.
    jsr .INTERPRET.NEXT_BYTE
    sta .CHOICE_DIMENSIONS.X
    jsr .INTERPRET.NEXT_BYTE
    sta .CHOICE_DIMENSIONS.Y
    
    ;reset the choice counter
    lda #0
    sta .CURRENT_CHOICE
    
    ;don't waste cycles getting input if input isn't active.
    lda .INPUT_ACTIVE
    beq .INTERPRET.INSTRUCTION.LOOP ;zero disables input.
    jsr INPUT.JOY.TEST
   
    .INTERPRET.INSTRUCTION.LOOP:
      ;get instruction byte.
      jsr .INTERPRET.NEXT_BYTE
      cmp #0 ;because the zero flag is silly when doing an rts.
      beq .INTERPRET.EXIT ;the instruction was END, jump out immediately.
      
      ;execute instruction
      ldx #>.INTERPRET.INSTRUCTION.JUMP_TABLE
      ldy #<.INTERPRET.INSTRUCTION.JUMP_TABLE
      jsr LOGIC.SWITCH
      
      ;loop
      jmp .INTERPRET.INSTRUCTION.LOOP
      
      .INTERPRET.INSTRUCTION.JUMP_TABLE:
        !byte 0,0,0 ;EXIT has to kill this routine, so we just pretend it's on the jump table.
        jmp .INTERPRET.INSTRUCTION.TEXT
        jmp .INTERPRET.INSTRUCTION.ICON
        jmp .INTERPRET.INSTRUCTION.CHOICE
        jmp .INTERPRET.INSTRUCTION.CHOICE.ON_SELECT
        jmp .INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN
        jmp .INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN
        jmp .INTERPRET.INSTRUCTION.BACKGROUND
        
        
      
      ;text has to be done as fast as possible.
      ;so the coordinates are expected to be the index instead of an X and Y
      ;this means the programmer must calculate the indexes ahead of time.  
      .INTERPRET.INSTRUCTION.TEXT:
        ;get cursor indexrun
        jsr .INTERPRET.NEXT_BYTE ;get lo byte of index.
        tay
        jsr .INTERPRET.NEXT_BYTE ;get hi byte of index.
        tax
        
        ;get color
        jsr .INTERPRET.NEXT_BYTE
        sta .B ;store it for later.
        
        ;get string length.
        jsr .INTERPRET.NEXT_BYTE
        sta .C ;create a counter.
        
        ;now print the string and colour it.
        .INTERPRET.INSTRUCTION.TEXT.LOOP:
          ;now set the character and its colour.
          ;the X and Y we got before are the index on the buffer to copy it to.
          jsr .INTERPRET.NEXT_BYTE ;get character into A
          jsr GRAPHICS.PUT_CHAR
          lda .B ;get colour
          jsr GRAPHICS.PUT_COLOR
          
          ;go to the next character.
          dec .C ;decrement counter
          beq .INTERPRET.INSTRUCTION.TEXT.EXIT ;the counter hit zero, we are done.
          iny ;increment buffer index.
          bne .INTERPRET.INSTRUCTION.TEXT.LOOP ;increment hit zero?
          inx ;in the case of carry, we need to increment the page as 40 column rows doesn't math evenly all the time.
          jmp .INTERPRET.INSTRUCTION.TEXT.LOOP
        
        .INTERPRET.INSTRUCTION.TEXT.EXIT:
        rts
        
        
      
      .INTERPRET.INSTRUCTION.ICON:
        ;TODO
        
        rts
        
        
        
      .INTERPRET.INSTRUCTION.CHOICE:
        ;copy pointer to current choice
        lda .INTERPRET.NEXT_BYTE + 1 ;lo byte
        sta .CHOICE_POINTER.LO
        lda .INTERPRET.NEXT_BYTE + 2 ;hi byte
        sta .CHOICE_POINTER.HI
        
        ;increment choice counter
        ;TODO: disable choices.
        inc .CURRENT_CHOICE
        
        rts
        
      .INTERPRET.INSTRUCTION.CHOICE.ON_SELECT:
        ;judge if the trigger was pulled AND this choice was chosen.
        lda .CURRENT_CHOICE
        cmp .SELECTION
        bne .INTERPRET.INSTRUCTION.CHOICE.ON_SELECT.ABORT ;this object was not selected
        lda .SELECTED
        beq .INTERPRET.INSTRUCTION.CHOICE.ON_SELECT.ABORT ;the trigger was not pulled yet
        
        ;call the subscriber and return immediately.
        jsr .INTERPRET.GO_POINTER
        rts
      
        .INTERPRET.INSTRUCTION.CHOICE.ON_SELECT.ABORT:
          ;trash the next two bytes (the pointer) and get the next instruction.
          jsr .INTERPRET.NEXT_BYTE
          jsr .INTERPRET.NEXT_BYTE
          rts
        
      .INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN:
        ;judge if this choice was chosen.
        lda .CURRENT_CHOICE
        cmp .SELECTION
        bne .INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN.ABORT ;this object was not selected
        
        ;call the subscriber and return immediately.
        jsr .INTERPRET.GO_POINTER
        rts
      
        .INTERPRET.INSTRUCTION.CHOICE.ON_CHOSEN.ABORT:
          ;trash the next two bytes (the pointer) and get the next instruction.
          jsr .INTERPRET.NEXT_BYTE
          jsr .INTERPRET.NEXT_BYTE
          rts
        
      .INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN:
        ;judge if this choice was not chosen.
        lda .CURRENT_CHOICE
        cmp .SELECTION
        beq .INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN.ABORT ;this object was selected, ignore it.
        
        ;call the subscriber and return immediately.
        jsr .INTERPRET.GO_POINTER
        rts
      
        .INTERPRET.INSTRUCTION.CHOICE.ON_NOT_CHOSEN.ABORT:
          ;trash the next two bytes (the pointer) and get the next instruction.
          jsr .INTERPRET.NEXT_BYTE
          jsr .INTERPRET.NEXT_BYTE
          rts
        
      .INTERPRET.INSTRUCTION.BACKGROUND:
        ;simply execute the routine provided.
        jsr .INTERPRET.GO_POINTER
      
        rts
 
      
      
    ;subroutines
    ;Loads A with next byte in the menu data.
    .INTERPRET.NEXT_BYTE:
      lda $0000 ;self modified.
      inc .INTERPRET.NEXT_BYTE + 1 ;increment for next address in the future.
      bne .INTERPRET.NEXT_BYTE.EXIT ;lo has gone back to zero?
      inc .INTERPRET.NEXT_BYTE + 2 ;increment page because we assume the increment has looped.
    
      .INTERPRET.NEXT_BYTE.EXIT:
      rts
      
    ;jsr using self modification by reading menu data.
    .INTERPRET.GO_POINTER:
      jsr .INTERPRET.NEXT_BYTE ;get lo byte
      sta .INTERPRET.GO_POINTER.JUMP + 1
      jsr .INTERPRET.NEXT_BYTE ;get hi byte
      sta .INTERPRET.GO_POINTER.JUMP + 2
    
      .INTERPRET.GO_POINTER.JUMP:
      jsr $0000 ;self modified
      
      rts
      
      
      
    ;go up in the choice grid.
    .INTERPRET.ON_UP_PRESSED:
      dec .CHOICE.Y
      bne .INTERPRET.ON_UP_PRESSED.EXIT ;zero is out of bounds
      lda .CHOICE_DIMENSIONS.Y
      sta .CHOICE.Y
    
      .INTERPRET.ON_UP_PRESSED.EXIT:
      jsr .INTERPRET.CHANGE_CHOSEN
      rts
      
    ;go down in the choice grid.
    .INTERPRET.ON_DOWN_PRESSED:
      inc .CHOICE.Y
      lda .CHOICE.Y
      cmp .CHOICE_DIMENSIONS.Y ;dimension maximum + 1 is out of bounds.
      beq .INTERPRET.ON_DOWN_PRESSED.EXIT ;choice is allowed to be the same as the coordinates.
      bcc .INTERPRET.ON_DOWN_PRESSED.EXIT ;check if it's not more than.
      lda #1
      sta .CHOICE.Y
    
      .INTERPRET.ON_DOWN_PRESSED.EXIT:
      jsr .INTERPRET.CHANGE_CHOSEN
      rts
      
    ;go left in the choice grid
    .INTERPRET.ON_LEFT_PRESSED:
      dec .CHOICE.X
      bne .INTERPRET.ON_LEFT_PRESSED.EXIT ;zero is out of bounds
      lda .CHOICE_DIMENSIONS.X
      sta .CHOICE.X
    
      .INTERPRET.ON_LEFT_PRESSED.EXIT:
      jsr .INTERPRET.CHANGE_CHOSEN
      rts
      
    ;go right in the choice grid
    .INTERPRET.ON_RIGHT_PRESSED:
      inc .CHOICE.X
      lda .CHOICE.X
      cmp .CHOICE_DIMENSIONS.X ;dimension maximum + 1 is out of bounds.
      beq .INTERPRET.ON_DOWN_PRESSED.EXIT ;choice is allowed to be the same as the coordinates.
      bcc .INTERPRET.ON_DOWN_PRESSED.EXIT ;check if it's not more than.
      lda #1
      sta .CHOICE.X
    
      .INTERPRET.ON_RIGHT_PRESSED.EXIT:
      jsr .INTERPRET.CHANGE_CHOSEN
      rts
      
    ;select current choice.
    .INTERPRET.ON_FIRE_PRESSED:
      jsr .INTERPRET.CHANGE_CHOSEN
      jsr .FINALIZE_SELECTION
    
      rts
      
    ;gets the index out of the coordinates given within the boundaries of the menu.
    ;A contains a copy of selection.
    .INTERPRET.CHANGE_CHOSEN:
      lda #0
      sta .SELECTION
      ldx .CHOICE.X
      ldy .CHOICE.Y
      
      ;for every index on the coordinate table, increment the selection.
      .INTERPRET.CHANGE_CHOSEN.LOOP:
        inc .SELECTION ;next selection id.
        dex ;count down the row
        bne .INTERPRET.CHANGE_CHOSEN.LOOP ;whilst x has not hit zero...
        ldx .CHOICE_DIMENSIONS.X ;reset x counter to a full row length.
        dey ;count down the column
        bne .INTERPRET.CHANGE_CHOSEN.LOOP ;whilst y has not hit zero...
    
      ;all possible menu indices have been scanned.  
      .INTERPRET.CHANGE_CHOSEN.EXIT:
        lda .SELECTION ;copy the result into A.
        rts
      
    ;enforce a selection in the menu based on a chosen choice.
    ;useful for initializing a menu with a selection already made.
    ;A contains a new value for SELECTION
    .FINALIZE_SELECTION:
      sta .SELECTION
      lda #1
      sta .SELECTED
      
      rts