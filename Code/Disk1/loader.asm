!cpu 6510

!source "../../Library/engine.asm",once

!zone LOADER

  .BORDER_FRAME_TIMER = $02
  .BORDER_COLOR = $03
  .OLD_IRQ_LO = $04
  .OLD_IRQ_HI = $05

  * = $0801
  
  ;sys call
  !word .BASIC_END
  !word 0
  !byte $9E ;sys
  !text "2061"
  !byte 0
  .BASIC_END:
  !word 0
  
  * = $080D
  
  ;disable basic
  lda #$36
  sta $01
  
  ;link chain to irq using self modifying code
  lda $0314
  sta .IRQ_CHAIN + 1
  sta .OLD_IRQ_LO
  lda $0315
  sta .IRQ_CHAIN + 2
  sta .OLD_IRQ_HI
  
  ;then inject own routine
  lda #<.BORDER_COLOR_IRQ
  sta $0314
  lda #>.BORDER_COLOR_IRQ
  sta $0315
  
  ;setup raster line irq
  lda #%10000001
  sta VIC.IRQ_MASK
  lda #%00000000 ;screen is also entirely made of border
  sta VIC.CONTROL_1
  lda #0 ;we wanna wait for line zero
  sta VIC.RASTER_POS
  
  ;and start loading CORE,PRG
  lda #.CORE_FILE_NAME_END - .CORE_FILE_NAME
  ldx #<.CORE_FILE_NAME
  ldy #>.CORE_FILE_NAME
  jsr KERNAL.SETNAM
  
  lda #15
  ldx #8
  ldy #0
  jsr KERNAL.SETLFS
  
  lda #0
  ldx #<ENGINE.CORE_PRG
  ldy #>ENGINE.CORE_PRG
  jsr KERNAL.LOAD
  
  ;once done, jump to the first instruction in the core, exiting this loader.
  jmp ENGINE.START
  
  .BORDER_COLOR_IRQ:
    ;respond to vic
    lda #%00000000
    sta VIC.IRQ_MASK
  
    ;count frames
    inc .BORDER_FRAME_TIMER
    lda #50 ;about 3 seconds
    cmp .BORDER_FRAME_TIMER
    bcs .IRQ_CHAIN ;don't do anything if not enough frames elapsed.
    
    ;increment colour and reset timer.
    jsr .NEXT_COLOR
    
  .IRQ_CHAIN: jmp $0000
    
  .NEXT_COLOR:
    ;reset frame counter
    lda #0
    sta $02
    
    ;we don't need to worry about the top 4 bits as the VIC ignores them anyway
    inc $03
    lda $03
    sta VIC.BORDER_COLOR
    
    rts
  
  .CORE_FILE_NAME:  
    !text "CORE,PRG"
  .CORE_FILE_NAME_END:
  
!zone