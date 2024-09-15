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
    sta VIC.BORDER_COLOR ;black border
    sta VIC.BACKGROUND_COLOR ;black background by default
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
    ;change interrupt routine based on the engine's mode.
    lda #<.IRQ.MENU
    sta $0314
    lda #>.IRQ.MENU
    sta $0315
    
    ;TODO: change this based on engine mode, depends on our sprite multiplexing implementation research.
    ;we only want to interrupt at the end of the frame.
    ;setup raster line irq
    lda #%00000001
    sta VIC.IRQ_MASK
    lda #%00010000 ;24 rows, char mode, vertical scroll middle, raster line target bit 8 set to 0
    sta VIC.CONTROL_1
    lda #252 ;we wanna wait for the bottom border to start
    sta VIC.RASTER_POS
  
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
    
    ;instruct the vic to show the buffer we have been writing to during the game loop.
    jsr .SWAP_BUFFERS
    
    ;flip colour buffer (takes a hopeful 11,348 cycles, which theoretically stays behind the raster even in NTSC.  we'll find out if sprite multiplexing is happy with this.)
    ldy #0
    ldx #1 ;loop counter
    .COLOR_SWITCH:
      lda .COLOR_BACK_BUFFER,Y ;self modified
      sta $d800,Y ;color ram.
      iny
      bne .COLOR_SWITCH ;branch if y has not returned to zero.
      
      inx
      cpx #5 ;4 pages done, exit
      beq .BUFFER_DONE
      inc .COLOR_SWITCH + 2 ;change page
      inc .COLOR_SWITCH + 5 ;change page
      jmp .COLOR_SWITCH
    
    .BUFFER_DONE:
      lda #>.COLOR_BACK_BUFFER ;reset indexes
      sta .COLOR_SWITCH + 2
      lda #$d8
      sta .COLOR_SWITCH + 5
    
      lda #.IRQ_WAIT_FLAGS.CLEARED
      sta .IRQ_WAIT_FLAGS
      jmp .GAME_LOOP

    
  ;PRIVATE INTERRUPTS
  ;TODO: using the SID.
  .IRQ.MENU:
    ;respond to the VIC immediately.  this engine uses the VIC to time absolutely everything.
    lda #%00001111
    sta VIC.IRQ_REQUEST
    
    ;the engine should stop waiting.  this means the buffers shall be flipped.
    lda #.IRQ_WAIT_FLAGS.OVERDRAW_REACHED
    sta .IRQ_WAIT_FLAGS
    
    ;only menu mode allows KERNAL interrupts.
    .IRQ.CHAIN: 
      jmp $0000 ;self modified, usually ends up going back to KERNAL.
  
  .IRQ.GAMEPLAY:
    ;TODO: sprite multiplexing, this means the interrupt position will change every time.
    
    ;TODO: screen splitting
    
    ;we can't allow kernal interrupts with this mode as we need too many cycles.
    rti
      
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

