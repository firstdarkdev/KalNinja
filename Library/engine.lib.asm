!cpu 6510

!source "c64.asm",once

!zone ENGINE

  ;variables
  .IRQ_WAIT_FLAGS = $02
  .GAME_MODE = $03
  .KEY_IN = $04
  .JOY_IN = $05
  .BUFFER_SWITCH = $06
  .CHAR_SWITCH = $07
  
  ;irq wait flags
  .IRQ_WAIT_FLAGS.CLEARED = %00000000
  .IRQ_WAIT_FLAGS.PENDING_OVERDRAW = %10000000
  .IRQ_WAIT_FLAGS.OVERDRAW_REACHED = %10000001
  
  ;game modes
  .GAME_MODE.MENU = 1
  .GAME_MODE.GAMEPLAY = 2
  
  ;VIC Buffer modes
  .VIC_BUFFER_1 = %10000000
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
    lda CIA2.DATA_DIRECTION_REGISTER_A
    ora #%00000011 ;set port to output so the VIC switches banks
    sta CIA2.DATA_DIRECTION_REGISTER_A
    lda CIA2.DATA_PORT_A
    and #%11111100
    ora #%00000010 ;set to Bank 1 ($4000 - $7FFF)
    sta CIA2.DATA_PORT_A
    
    lda #0
    sta VIC.BORDER_COLOR
    sta VIC.BACKGROUND_COLOR
    lda #%00010000 ;24 rows, char mode, vertical scroll middle
    sta VIC.CONTROL_1
    lda #%11010000 ;38 columns, multicolor mode.
    sta VIC.CONTROL_2
    
    ;setup variables
    lda #.VIC_BUFFER_1
    sta .BUFFER_SWITCH
    lda #.VIC_UI_CHAR
    sta .CHAR_SWITCH
    lda #.GAME_MODE.MENU
    sta .GAME_MODE
    
    jsr .SWAP_BUFFERS
    
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
  
    ;only do the level's script and tilemap scrolling if we're in gameplay mode
    lda .GAME_MODE
    cmp #.GAME_MODE.MENU
    beq .GAME_LOOP.MENU_LOOP
    
    ;TODO back buffer rendering stuff for the map's scrolling
    
    .GAME_LOOP.RUN_LEVEL_SCRIPT:
      jsr $0000
      
    ;TODO render the current menu as a HUD.
      
    ;now run the main script.
    jmp .GAME_LOOP.RUN_MAIN_SCRIPT
      
    ;rendering the screen as a menu instead of gameplay was requested...
    .GAME_LOOP.MENU_LOOP:
      
      ;TODO render the menu as the whole screen.

    ;now run the main script no matter which screen mode.
    .GAME_LOOP.RUN_MAIN_SCRIPT:
      jsr $0000
      
    ;and now we wait for overdraw
    lda #.IRQ_WAIT_FLAGS.PENDING_OVERDRAW
    sta .IRQ_WAIT_FLAGS
    
  ;rendering occurs the moment raster enters overdraw so that colour data gets copied at the right timings.
  .RENDER_LOOP:
    lda .IRQ_WAIT_FLAGS
    cmp #.IRQ_WAIT_FLAGS.OVERDRAW_REACHED
    bne .RENDER_LOOP
    
    jsr .SWAP_BUFFERS
    
    ;TODO: flip colour buffer.
    .COLOR_SWITCH:
    
    
    .BUFFER_DONE:
      lda #.IRQ_WAIT_FLAGS.CLEARED
      sta .IRQ_WAIT_FLAGS
      jmp .GAME_LOOP

    
  ;PRIVATE INTERRUPT
  .IRQ:
    ;respond to the VIC immediately.  this engine uses the VIC to time absolutely everything.
    lda #%00000000
    sta VIC.IRQ_MASK
    
    ;TODO: increase registered timers here.
  
    lda .GAME_MODE
    cmp #.GAME_MODE.GAMEPLAY
    beq .IRQ.GAMEPLAY
    
    .IRQ.MENU:
      ;TODO: no sprite multiplexing, just pull the bottom 8.
      
      ;TODO: sound during the border/blank
      
      ;we want to interrupt next time at the screen bottom.
      
    
      jmp .IRQ.EXIT
    
    .IRQ.GAMEPLAY:
      ;TODO: sprite multiplexing, this means the interrupt position will change every time.
      
      ;TODO: screen splitting
      
      ;TODO: sound during the border/blank
      
      ;and now we want to interrupt when the screen hits the bottom.
    
      jmp .IRQ.EXIT

    .IRQ.EXIT:
      ;don't respond to the engine if it isn't waiting.
      ;this allows sprite multiplexing, timers and sound to tick even whilst the game is processing.
      lda .IRQ_WAIT_FLAGS
      cmp .IRQ_WAIT_FLAGS.PENDING_OVERDRAW
      bne .IRQ.CHAIN
      
      ;the engine should stop waiting.  this means the buffers shall be flipped.
      lda .IRQ_WAIT_FLAGS.OVERDRAW_REACHED
      sta .IRQ_WAIT_FLAGS
    
    .IRQ.CHAIN: 
      jmp $0000 ;self modified, usually ends up going back to KERNAL.
      
  ;PRIVATE SUBROUTINES
  .SWAP_BUFFERS:
    ;combine the buffer switch and char switch into one vic memory map.
    lda .BUFFER_SWITCH
    ora .CHAR_SWITCH
    sta VIC.MEMORY_CONTROL
    
    ;switch buffers, so that next game loop puts data into the back buffer.
    lda .BUFFER_SWITCH
    eor #%00010000 ;switch to address $6800, or back.
    sta .BUFFER_SWITCH
    
    .SWAP_BUFFERS.EXIT:
      rts

;PUBLIC SUBROUTINES
!zone MENU
  
  ;variables
  .OPTIONS = $08
  .OPTIONS_END = $09
  ;0A used by KERNAL LOAD/VERIFY switch
  .TYPE = $0B
  .SELECTION = $0C
  
  ;menu types
  .TYPE.LIST = 1
  .TYPE.GRID = 2
  
  .ELEMENT.END = 1
  .ELEMENT.TEXT = 2
  .ELEMENT.ICON = 3
  .ELEMENT.CHOICE = 4
  .ELEMENT.CHOICE.ON_SELECT = 5
  .ELEMENT.CHOICE.ON_CHOSEN = 6
  .ELEMENT.CHOICE.ON_NOT_CHOSEN = 7
  .ELEMENT.COLOR = 8
  .ELEMENT.BACK_COLOR_1 = 9
  .ELEMENT.BACK_COLOR_2 = 10
  .ELEMENT.BACK_COLOR_3 = 11
  
  .NEW_MENU:
    ;store parameters
    sta .TYPE
    stx .OPTIONS
    sty .OPTIONS_END
    
    ;reset menu selection
    lda #0
    sta .SELECTION
    
    rts

!zone SCRIPT
  
  ;self modify the loop caller
  .REGISTER_LEVEL_LOOP:
    sta ENGINE.GAME_LOOP.RUN_LEVEL_SCRIPT + 1
    stx ENGINE.GAME_LOOP.RUN_LEVEL_SCRIPT + 2
    rts
    
  .REGISTER_MAIN_LOOP:
    sta ENGINE.GAME_LOOP.RUN_MAIN_SCRIPT + 1
    stx ENGINE.GAME_LOOP.RUN_MAIN_SCRIPT + 2
    rts

  .MENU_START:
  ;point to here with your core code so the engine can kickstart.
  
!zone

