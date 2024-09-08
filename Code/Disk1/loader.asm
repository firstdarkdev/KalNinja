!cpu 6510

!source "../../Library/c64.asm",once

!zone LOADER

  .BORDER_FRAME_TIMER = $02
  .BORDER_COLOR = $03

  !macro LOAD_FILE addrlo, addrhi, namelen, name

    lda #namelen
    ldx #<name
    ldy #>name
    jsr KERNAL.SETNAM
    
    lda #15
    ldx #8
    ldy #0
    jsr KERNAL.SETLFS
    
    lda #0
    ldx #addrlo
    lda #addrhi
    jsr KERNAL.LOAD

  !end

  !macro RESET_BORDER_TIMER
    
    lda #0
    sta $02
    
  !end
  
  !macro CHANGE_BORDER_COLOR
    
    ;we don't need to worry about the top 4 bits as the VIC ignores them anyway
    inc $03
    lda $03
    sta VIC.BORDER_COLOR
    
  !end

  * = $0801
  
  ;disable basic
  lda #36
  sta $01
  
  ;setup raster line irq
  lda #%10000001
  sta VIC.IRQ_MASK
  lda #%00000000 ;screen is also entirely made of border
  sta VIC.CONTROL_1
  lda #0 ;we wanna wait for line zero
  sta VIC.RASTER_POS
  
  ;reset frame counter
  +RESET_BORDER_TIMER
  
  ;setup border colour incremental.  this lets us give an immediate response that the program has started running
  +CHANGE_BORDER_COLOR
  
  ;link chain to irq using self modifying code
  lda $0314
  sta CHAIN + 1
  lda $0315
  sta CHAIN + 2
  
  ;then inject own routine
  lda <BORDER_COLOR_IRQ
  sta $0314
  lda >BORDER_COLOR_IRQ
  sta $0315
  
  ;and start loading CORE,PRG
  +LOAD_FILE $00, $18, CORE_FILE_NAME_END - CORE_FILE_NAME, CORE_FILE_NAME
  
  ;once done, jump to the first instruction in the core, exiting this loader.
  jmp $2000
  
  BORDER_COLOR_IRQ:
    ;count frames
    inc .BORDER_FRAME_TIMER
    lda #150 ;about 3 seconds
    cmp .BORDER_FRAME_TIMER
    bne CHAIN ;don't do anything if not enough frames elapsed.
    
    ;increment colour and reset timer.
    +CHANGE_BORDER_COLOR
    +RESET_BORDER_TIMER
  
    CHAIN: jmp $0000
  
  CORE_FILE_NAME:  
    !text "CORE,PRG"
  CORE_FILE_NAME_END:
  
!zone