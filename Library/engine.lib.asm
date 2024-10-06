!cpu 6510

!source "c64.asm",once

!zone ENGINE

  ;variables
  .IRQ_WAIT_FLAGS = $02
  .GAME_MODE = $03
  .BUFFER_SWITCH = $04
  .CHAR_SWITCH = $05
  .BUFFER_POINTER_HI = $06
  ;0A used by KERNAL LOAD/VERIFY switch
  
  ;irq wait flags
  .IRQ_WAIT_FLAGS.PENDING_OVERDRAW = 1
  .IRQ_WAIT_FLAGS.OVERDRAW_REACHED = 2
  .IRQ_WAIT_FLAGS.CLEARED = 3
  
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
  .SAVE_FILE = $0200
  .SCRIPT_PRG = $0400
  .CORE_PRG = $2000
  .UI_CHAR = $4000
  .CORE_SPRITE = $4800
  .BUFFER_1 = $6000
  .BUFFER_2 = $6400
  .LEVEL_CHAR = $6800
  .LEVEL_SPRITE = $7000
  .LEVEL_QUIET_MUSIC = $8000
  .LEVEL_DYNAMIC_MUSIC = $8800
  .LEVEL_SFX = $9000
  .LEVEL_TILES = $9800 ;tiles need to be 3x3, so the map itself is large.
  .LEVEL_MAP = $AC00 ;10 x 6 screens of 11x6 tiles (110 tiles wide, 36 tiles tall), or if vertical (square), 66 tiles by 60 tiles 
  .COLOR_BACK_BUFFER = $BC00
  .ENTITY_MEMORY = $C000

  * = .CORE_PRG

  ;PRIVATE CODE
  .START:
    ;override the loader's IRQ.
    ;we can't link the addresses in compilation in a specified order, so we just use the global variables in the zero page instead.
    ;we are also gonna reuse these variables later, so just extract directly.
    sei
    
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
    lda #.IRQ_WAIT_FLAGS.CLEARED
    sta .IRQ_WAIT_FLAGS
    
    ;and start swapping buffers via menu mode
    jsr .SWAP_BUFFERS
    jsr .GO_MENU_MODE
    
    ;setup menu
    jsr MENU.END ;be closed at the start, so the interpreter is not running.
    
    ;then run the start script.
    jsr .MENU_START
    
    ;now start looping
    cli
    
    
    
  ;occurs in the background whilst VIC is doing literally anything.
  .GAME_LOOP:
    ;poll inputs
    jsr INPUT.KEY.POLL
    jsr INPUT.JOY.POLL
  
    ;only do the level's script and tilemap scrolling if we're in gameplay mode
    lda .GAME_MODE
    cmp #.GAME_MODE.GAMEPLAY
    bne .GAME_LOOP.DRAW_MENU
    
    ;TODO back buffer rendering stuff for the map's scrolling
    
    .GAME_LOOP.RUN_LEVEL_SCRIPT:
      jsr $0000
      jmp .GAME_LOOP.DRAW_MENU
    
    ;now we draw the menu.
    ;note that the menu must have been setup correctly by the programmer otherwise garbage shows up.
    .GAME_LOOP.DRAW_MENU:
      jsr MENU.INTERPRET

    ;now run the main script no matter which screen mode.
    .GAME_LOOP.RUN_MAIN_SCRIPT:
      jsr $0000
      
    ;TODO: entity scripts
    
      
      
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
    
    ;TODO: sort sprites now, hopefully fast enough that the colour buffer remains in time.
    
    ;flip colour buffer
    ldx #>.COLOR_BACK_BUFFER
    ldy #$d8 ;into color ram pages.
    jsr MEMORY.COPY_4_PAGES
    
    ;reset wait flag and loop the engine.
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
    lda .IRQ_WAIT_FLAGS
    cmp #.IRQ_WAIT_FLAGS.PENDING_OVERDRAW
    bne .IRQ.CHAIN ;don't allow the buffers to flip until the core is done drawing.
    lda #.IRQ_WAIT_FLAGS.OVERDRAW_REACHED
    sta .IRQ_WAIT_FLAGS
    
    ;only menu mode allows KERNAL interrupts.
    .IRQ.CHAIN: 
      jmp $0000 ;self modified, usually ends up going back to KERNAL.
  
  .IRQ.GAMEPLAY:
    ;TODO: sprite multiplexing, this means the interrupt position will change every time.
    
    ;TODO: screen splitting
    
    ;we can't allow KERNAL interrupt routines with this mode as we need too many cycles.
    rti
 
    
    
  ;PUBLIC SUBROUTINES
  .SWAP_BUFFERS:
    ;combine the buffer switch and char switch into one vic memory map.
    lda .BUFFER_SWITCH
    ora .CHAR_SWITCH
    sta VIC.MEMORY_CONTROL
    
    ;switch buffers, so that next game loop puts data into the back buffer.
    lda .BUFFER_SWITCH
    eor #%00010000 ;switch to address $6800, or back.
    sta .BUFFER_SWITCH
    
    ;buffer bank for mathematic addressing is done via this.
    lsr ;divide by 4.
    lsr 
    ora #%01000000 ;address to bank 2.
    sta .BUFFER_POINTER_HI ;we don't touch lo as other routines can handle that assuming 0 is the bottom.
    
    rts

  ;NOTE: programmers should sei and cli to prevent VIC interruptions at weird times, such as sprite multiplexing
  .GO_MENU_MODE:
    ;change interrupt routine based on the engine's mode.
    lda #<.IRQ.MENU
    sta $0314
    lda #>.IRQ.MENU
    sta $0315
    
    ;we only want to interrupt at the end of the frame.
    ;setup raster line irq
    lda #%00000001
    sta VIC.IRQ_MASK
    lda #%00010000 ;24 rows, char mode, vertical scroll middle, raster line target bit 8 set to 0
    sta VIC.CONTROL_1
    lda #252 ;we wanna wait for the bottom border to start
    sta VIC.RASTER_POS
    
    ;set engine to render to menu-only mode.
    lda #.GAME_MODE.MENU
    sta .GAME_MODE
    
    rts
    
  .SUBSCRIBE.LEVEL_LOOP:
    sta .GAME_LOOP.RUN_LEVEL_SCRIPT + 1
    stx .GAME_LOOP.RUN_LEVEL_SCRIPT + 2
    rts
    
  .SUBSCRIBE.MAIN_LOOP:
    sta .GAME_LOOP.RUN_MAIN_SCRIPT + 1
    stx .GAME_LOOP.RUN_MAIN_SCRIPT + 2
    rts
  
  
;SUBMODULES
  !source "../Include/menu.asm", once
  !source "../Include/input.asm", once
  !source "../Include/logic.asm", once
  !source "../Include/graphics.asm", once
  !source "../Include/memory.asm", once
 
!zone ENGINE
  .MENU_START:
  ;point to here with your core code so the engine can kickstart.

