!cpu 6510

!source "c64.asm",once

!zone ENGINE

  ;variables
  .IRQ_WAIT_FLAGS = $02
  .GAME_MODE = $03
  ;0A used by KERNAL LOAD/VERIFY switch
  .KEY_IN = $08
  .JOY_IN = $09
  .BUFFER_SWITCH = $0B
  .CHAR_SWITCH = $0C
  
  ;irq wait flags
  .IRQ_WAIT_FLAGS.CLEARED = %00000000
  .IRQ_WAIT_FLAGS.PENDING_OVERDRAW = %10000000
  .IRQ_WAIT_FLAGS.OVERDRAW_REACHED = %10000001
  
  ;game modes
  .GAME_MODE.MENU = $00
  .GAME_MODE.GAMEPLAY = $01
  
  ;VIC Buffer modes
  .VIC_BUFFER_1 = %00010000
  .VIC_BUFFER_2 = %10010000
  .VIC_UI_CHAR = %00000001
  .VIC_GAME_CHAR = %00001011

  ;MEMORY MAP
  ;the following areas always have the same space.
  .SAVE_FILE = $0334
  .SCRIPT_PRG = $0400
  .CORE_PRG = $2000
  .UI_CHAR = $4000
  .PLAYER_SPRITE = $4800
  .WEAPON_SPRITE = $5000
  .BUFFER_1 = $6000
  .BUFFER_2 = $6400
  .LEVEL_CHAR = $6800
  .LEVEL_SPRITE = $7000
  .LEVEL_QUIET_MUSIC = $8000
  .LEVEL_DYNAMIC_MUSIC = $8800
  .LEVEL_SFX = $9000
  .LEVEL_TILES = $9800
  .LEVEL_MAP = $AC00
  .COLOR_BACK_BUFFER = $BC00
  .SCRATCHPAD_MEMORY = $C000

  * = .CORE_PRG

  ;PRIVATE CODE
  .START:
    ;override the loader's IRQ.
    ;we can't link the addresses in compilation in a specified order, so we just use the global variables in the zero page instead.
    ;we are also gonna reuse these variables later, so just extract directly.
    lda $04
    sta .IRQ.CHAIN + 1
    lda $05
    sta .IRQ.CHAIN + 2
    
    lda #<.IRQ
    sta $0314
    lda #>.IRQ
    sta $0315
    
    ;setup input system
    lda #1
    sta $0289 ;disable buffer
    lda #127
    sta $028A ;disable key repeat
    
    ;setup VIC
    lda CIA2.DATA_PORT_A
    and #%11111100
    ora #%00000010 ;set to Bank 1 ($4000 - $7FFF)
    sta CIA2.DATA_PORT_A
    
    lda #0
    sta VIC.BORDER_COLOR
    sta VIC.BACKGROUND_COLOR
    lda #%00010000 ;24 rows, char mode.
    sta VIC.CONTROL_1
    lda #%00010000 ;38 columns, multicolor mode.
    
    ;setup variables
    lda #.VIC_BUFFER_1
    sta .BUFFER_SWITCH
    lda #.VIC_UI_CHAR
    sta .CHAR_SWITCH
    lda #.GAME_MODE.MENU
    sta .GAME_MODE
    
    ;setup core.
    jsr SCRIPT.MENU_START
    
    
  ;occurs in the background whilst VIC is doing literally anything.
  .GAME_LOOP:
    ;get key in
    jsr KERNAL.SCNKEY
    jsr KERNAL.GETIN
    sta .KEY_IN
    
    ;get joystick in
    lda #0
    sta CIA1.DATA_DIRECTION_REGISTER_B
    lda CIA1.DATA_PORT_B
    sta .JOY_IN
  
    ;judge what to do with input responses based on the game mode.
    ;based on this, only two game modes are possible.
    ;TODO: consider better check
    lda .GAME_MODE
    cmp .GAME_MODE.GAMEPLAY
    beq .GAME_LOOP.GAMEPLAY
    
    .GAME_LOOP.MENU:
      
    
      .GAME_LOOP.RUN_MENU_SCRIPT:
        jsr $0000
        
        jmp .WAIT_TO_DRAW
      
    .GAME_LOOP.GAMEPLAY:
      
    
      .GAME_LOOP.RUN_GAMEPLAY_SCRIPT:
        jsr $0000
      
      
  ;wait until the raster beam has just entered lower overdraw to enter the render loop.
  .WAIT_TO_DRAW:
    
    lda #.IRQ_WAIT_FLAGS.PENDING_OVERDRAW
    sta .IRQ_WAIT_FLAGS
    
  ;rendering occurs the moment raster enters overdraw so that colour data gets copied at the right timings.
  .RENDER_LOOP:
    lda .IRQ_WAIT_FLAGS
    cmp #.IRQ_WAIT_FLAGS.OVERDRAW_REACHED
    bne .RENDER_LOOP
    
    ;combine the buffer switch and char switch into one vic memory map.
    lda .BUFFER_SWITCH
    ora .CHAR_SWITCH
    sta VIC.MEMORY_CONTROL
    
    ;switch buffers, so that next game loop puts data into the back buffer.
    lda .BUFFER_SWITCH
    clc
    adc #%10000000 ;switch to address $6000
    bcc .COLOR_SWITCH
    lda .VIC_BUFFER_1
    sta .BUFFER_SWITCH
    
    ;TODO: flip colour buffer.
    .COLOR_SWITCH:
    
    
    .BUFFER_DONE:
      lda #.IRQ_WAIT_FLAGS.CLEARED
      sta .IRQ_WAIT_FLAGS
      jmp .GAME_LOOP

    
  ;PRIVATE INTERRUPT
  .IRQ:
    lda .GAME_MODE
    cmp .GAME_MODE.MENU
    beq .MENU
    cmp .GAME_MODE.GAMEPLAY
    beq .GAMEPLAY
    
    .MENU:
      ;TODO: no sprite multiplexing
      
      ;Sound
    
      jmp .IRQ.EXIT
    
    .GAMEPLAY:
      ;TODO: sprite multiplexing
      
      ;TODO: screen splitting
      
      ;Sound
    
      jmp .IRQ.EXIT

    .IRQ.EXIT:
      lda .IRQ_WAIT_FLAGS
      cmp .IRQ_WAIT_FLAGS.PENDING_OVERDRAW
      bne .IRQ.CHAIN
      
      
      
      lda .IRQ_WAIT_FLAGS.OVERDRAW_REACHED
      sta .IRQ_WAIT_FLAGS
    
    .IRQ.CHAIN: 
      jmp $0000 ;self modified, usually ends up going back to KERNAL.

;PUBLIC SUBROUTINES
!zone MENU
  
  ;variables
  .OPTIONS = $04
  .OPTIONS_END = $05
  .TYPE = $06
  .SELECTION = $07
  
  ;menu types
  .TYPE.LIST = $00
  .TYPE.GRID = $01
  .TYPE.DIALOGUE = $02
  
  .TITLE = 1
  .CHOICE = 2
  
  .NEW_MENU:
    ;store parameters
    sta .TYPE
    stx .OPTIONS
    sty .OPTIONS_END
    
    ;change engine modes
    lda #ENGINE.GAME_MODE.MENU
    sta ENGINE.GAME_MODE
    
    ;reset menu selection
    lda #0
    sta .SELECTION
    
    rts

!zone SCRIPT
  
  ;self modify the loop caller
  .REGISTER_GAMEPLAY_LOOP:
    sta ENGINE.GAME_LOOP.RUN_GAMEPLAY_SCRIPT + 1
    stx ENGINE.GAME_LOOP.RUN_GAMEPLAY_SCRIPT + 2
    rts
    
  .REGISTER_MENU_LOOP:
    sta ENGINE.GAME_LOOP.RUN_MENU_SCRIPT + 1
    stx ENGINE.GAME_LOOP.RUN_MENU_SCRIPT + 2
    rts

  .MENU_START:
  ;point to here with your core code so the engine can kickstart.
  
!zone

