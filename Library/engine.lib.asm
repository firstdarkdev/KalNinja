!cpu 6510

!source "c64.asm",once

!zone ENGINE

  ;variables
  .IRQ_WAIT_FLAGS = $02
  .GAME_MODE = $03
  .MENU_OPTIONS = $04
  .MENU_OPTIONS_END = $05
  .MENU_TYPE = $06
  .MENU_SELECTION = $07
  .SCRIPT_LOOP_LO = $08
  .SCRIPT_LOOP_HI = $09
  ;0A used by KERNAL LOAD/VERIFY switch
  .KEY_IN = $0B
  .JOY_IN = $0C
  .BUFFER_SWITCH = $0D
  .CHAR_SWITCH = $0E
  
  ;irq wait flags
  .IRQ_WAIT_FLAGS.CLEARED = %00000000
  .IRQ_WAIT_FLAGS.PENDING_OVERDRAW = %10000000
  .IRQ_WAIT_FLAGS.OVERDRAW_REACHED = %10000001
  
  ;game modes
  .GAME_MODE.MENU = $00
  .GAME_MODE.GAMEPLAY = $01
  
  ;menu types
  .MENU_TYPE.LIST = $00
  .MENU_TYPE.GRID = $01
  .MENU_TYPE.DIALOGUE = $02
  
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
    
    lda #.VIC_BUFFER_1
    sta .BUFFER_SWITCH
    lda #.VIC_UI_CHAR
    sta .CHAR_SWITCH
    
    ;setup main menu
    lda #.MENU_TYPE.LIST
    ldx #<.MAIN_MENU
    ldy #>.MAIN_MENU
    jsr MENU.NEW_MENU
    
    
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
    lda .GAME_MODE
    cmp .GAME_MODE.MENU
    beq .GAME_LOOP.MENU
    cmp .GAME_MODE.GAMEPLAY
    beq .GAME_LOOP.GAMEPLAY
    
    .GAME_LOOP.MENU:
      
    
      jmp .WAIT_TO_DRAW
      
    .GAME_LOOP.GAMEPLAY:
      
    
      .GAME_LOOP.SCRIPT_EXIT:
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
    
    ;TODO: flip colour buffer.
    
    ;switch buffers, so that next game loop, puts data into the back buffer.
    lda .BUFFER_SWITCH
    clc
    adc #%10000000
    bcc .BUFFER_DONE
    sta .BUFFER_SWITCH
    
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
  
  ;PRIVATE EVENTS
  .MAIN_MENU.ON_LOAD:
    rts
  .MAIN_MENU.ON_NEW:
    rts
    
  ;PRIVATE RESOURCES
  .MAIN_MENU:
    ;title
    !byte MENU.TITLE
    !byte <.MAIN_MENU.TITLE, >.MAIN_MENU.TITLE
    !byte 0
    ;load
    !byte MENU.CHOICE
    !text "LOAD GAME"
    !byte 0
    !byte <.MAIN_MENU.ON_LOAD, >.MAIN_MENU.ON_LOAD
    !byte 0
    ;save
    !byte MENU.CHOICE
    !text "NEW GAME"
    !byte 0
    !byte <.MAIN_MENU.ON_NEW, >.MAIN_MENU.ON_NEW
    !byte 0
    !byte 0
    
    .MAIN_MENU.TITLE:
      !media "menutitles.charscreen",charcolor,0,0,10,5
  
!zone

;PUBLIC SUBROUTINES
!zone MENU
  
  .TITLE = 1
  .CHOICE = 2
  
  .NEW_MENU:
    ;store parameters
    sta ENGINE.MENU_TYPE
    stx ENGINE.MENU_OPTIONS
    sty ENGINE.MENU_OPTIONS_END
    
    ;change engine modes
    lda #ENGINE.GAME_MODE.MENU
    sta ENGINE.GAME_MODE
    
    ;reset menu selection
    lda #0
    sta ENGINE.MENU_SELECTION
    
    rts

!zone

!zone SCRIPT
  
  ;self modify the loop caller
  .REGISTER_LOOP:
    sta ENGINE.GAME_LOOP.SCRIPT_EXIT + 1
    stx ENGINE.GAME_LOOP.SCRIPT_EXIT + 2
    rts

!zone