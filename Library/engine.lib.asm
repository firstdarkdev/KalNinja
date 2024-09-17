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
  .BUFFER_POINTER_LO = $08
  .BUFFER_POINTER_HI = $09
  ;0A used by KERNAL LOAD/VERIFY switch
  
  ;irq wait flags
  .IRQ_WAIT_FLAGS.PENDING_OVERDRAW = 1
  .IRQ_WAIT_FLAGS.OVERDRAW_REACHED = 2
  .IRQ_WAIT_FLAGS.CLEARED = 3
  
  ;game modes
  .GAME_MODE.MENU = 1
  .GAME_MODE.GAMEPLAY = 2
  .GAME_MODE.MID_IRQ_GAMEPLAY = 3 ;a lightweight game mode used whilst the KERNAL is busy LOADing.
  
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
    
    jsr .SWAP_BUFFERS
    
    ;setup core.
    jsr SCRIPT.MENU_START
    
    cli
    
    
    
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
    beq .GAME_LOOP.DRAW_MENU
    
    ;TODO back buffer rendering stuff for the map's scrolling
    
    .GAME_LOOP.RUN_LEVEL_SCRIPT:
      jsr $0000
      jmp .GAME_LOOP.DRAW_MENU
    
    ;now we draw the menu.
    ;note that the menu must have been setup correctly by the programmer otherwise garbage shows up.
    .GAME_LOOP.DRAW_MENU:
      jsr MENU.INTERPRET_MENU

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
    
    ;flip colour buffer
    lda #>.COLOR_BACK_BUFFER
    ldx #4 ;all 1K of it.
    ldy #$d8 ;into color ram pages.
    jsr .COPY_PAGES
    
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
    lda .BUFFER_SWITCH ;consider the switch the high byte of the buffer pointer.
    ror ;divide by 4.
    ror 
    ora #%01000000 ;address to bank 2.
    sta .BUFFER_POINTER_HI ;we don't touch LO as other routines can handle that assuming 0 is the bottom.
    
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
    lda #ENGINE.GAME_MODE.MENU
    sta ENGINE.GAME_MODE
    
    rts
    
  ;Fills 256 byte pages with the same character.  As fast as possible.
  ;Accumulator contains byte to fill, X contains page count to do, Y contains page high byte pointer.
  .FILL_PAGES:
    sty .FILL_PAGES.LOOP + 2 ;store page high byte.
    
    ldy #0
    
    .FILL_PAGES.LOOP:
      sta $0000,Y ;self modified at the start.
      iny
      bne .FILL_PAGES.LOOP
    
      dex
      beq .FILL_PAGES.DONE ;all pages done.
      inc .FILL_PAGES.LOOP + 2 ;next page
      jmp .FILL_PAGES.LOOP
    
    .FILL_PAGES.DONE:
      rts
    
  ;Copies 256 byte pages.  As fast as possible.
  ;Accumulator contains page to copy, X contains page count to do, Y contains page destination.
  .COPY_PAGES:
    sta .COPY_PAGES.LOOP + 2
    sty .COPY_PAGES.LOOP + 5  
  
    ldy #0
  
    .COPY_PAGES.LOOP:
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      iny
      bne .COPY_PAGES.LOOP ;branch if y has not returned to zero.
      
      dex
      beq .COPY_PAGES.DONE ;all pages done
      inc .COPY_PAGES.LOOP + 2 ;change page
      inc .COPY_PAGES.LOOP + 5 ;change page
      jmp .COPY_PAGES.LOOP
    
    .COPY_PAGES.DONE:
      rts
      
  .SET_CHAR_MULTICOLORS:
    sta VIC.BACKGROUND_COLOR
    stx VIC.CHARSET_MULTICOLOR_1
    sty VIC.CHARSET_MULTICOLOR_2
    rts
  
  
;PUBLIC SUBROUTINES
!zone MENU
  
  ;variables
  .OPTIONS_LO = $10
  .OPTIONS_HI = $11
  .TYPE = $12
  ;$13 is used by Current I/O Device Number
  .SELECTION = $14
  .CURRENT_INSTRUCTION = $15
  .CURRENT_BYTE = $16
  .CHOICE_POINTER.LO = $17
  .CHOICE_POINTER.HI = $18
  
  ;menu types (these really only change the input controls)
  .TYPE.CLOSED = 0
  .TYPE.LIST = 1
  .TYPE.GRID = 2
  
  .ELEMENT.TEXT = 1
  .ELEMENT.TEXT.END = $2020
  .ELEMENT.ICON = 2
  .ELEMENT.CHOICE = 3
  .ELEMENT.CHOICE.ON_SELECT = 4
  .ELEMENT.CHOICE.ON_CHOSEN = 5
  .ELEMENT.CHOICE.ON_NOT_CHOSEN = 6
  .ELEMENT.CHOICE.END = 7
  .ELEMENT.BACKGROUND_ROUTINE = 8
  .ELEMENT.END = 9
  
  .NEW_MENU:
    ;store parameters
    sta .TYPE
    stx .OPTIONS_LO
    sty .OPTIONS_HI
    
    ;reset menu selection
    lda #0
    sta .SELECTION
    
    rts

  .INTERPRET_MENU:
    ;TODO
  
    rts
    
  ;this routine is only required if you want total control of the screen!
  .END_MENU:
    ;reset menu pointers so the menu does not get interpreted.
    lda #0
    sta .OPTIONS_LO
    sta .OPTIONS_HI
    sta .TYPE
    
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

