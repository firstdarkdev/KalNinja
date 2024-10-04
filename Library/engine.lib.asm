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
    jsr SCRIPT.MENU_START
    
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
    lda #ENGINE.GAME_MODE.MENU
    sta ENGINE.GAME_MODE
    
    rts
    
  
  
;PUBLIC SUBMODULES
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



!zone INPUT
  .JOY.IN = $20
  .JOY.OLD = $21
  ;$22-$25 are used for "various operations", best not to mess with it.
  .KEY.IN = $26
  .KEY.OLD = $27
  .JOY.CHANGED.ON = $28
  .JOY.CHANGED.OFF = $29
  
  .JOY.RESET:
    ldy #<.DO_NOTHING
    ldx #>.DO_NOTHING
    
    stx .JOY.TEST.UP + 2
    sty .JOY.TEST.UP + 1
    stx .JOY.TEST.DOWN + 2
    sty .JOY.TEST.DOWN + 1
    stx .JOY.TEST.RIGHT + 2
    sty .JOY.TEST.RIGHT + 1
    stx .JOY.TEST.LEFT + 2
    sty .JOY.TEST.LEFT + 1
    stx .JOY.TEST.FIRE + 2
    sty .JOY.TEST.FIRE + 1
    stx .JOY.TEST.UP.RELEASE + 2
    sty .JOY.TEST.UP.RELEASE + 1
    stx .JOY.TEST.DOWN.RELEASE + 2
    sty .JOY.TEST.DOWN.RELEASE + 1
    stx .JOY.TEST.RIGHT.RELEASE + 2
    sty .JOY.TEST.RIGHT.RELEASE + 1
    stx .JOY.TEST.LEFT.RELEASE + 2
    sty .JOY.TEST.LEFT.RELEASE + 1
    stx .JOY.TEST.FIRE.RELEASE + 2
    sty .JOY.TEST.FIRE.RELEASE + 1
    
    rts
  
    
      
  .JOY.POLL:
    ;shove away old input.
    lda .JOY.IN
    sta .JOY.OLD
  
    ;instruct CIA1 to get joystick input.
    lda CIA1.DATA_PORT_A
    eor #%11111111 ;invert itself
    sta .JOY.IN
    
    rts
      
    
  
  ;test and fire events according to changes in the input, ignoring holds.
  .JOY.TEST:
    ;find out which buttons have been changed to on and which ones off.
    lda .JOY.IN ;get current CIA result
    eor .JOY.OLD ;only show flags that are new.
    sta .JOY.CHANGED.ON ;store temporarily.
    lda .JOY.OLD ;look back at the old ones.
    and .JOY.CHANGED.ON ;see if any match the new one.
    sta .JOY.CHANGED.OFF ;ones that are in the old one are treated as now off.
    eor .JOY.CHANGED.ON ;only ones that were not in the old one are treated as now turned on.
    sta .JOY.CHANGED.ON ;store result for the ones now treated as on.
  
    ;choose an input routine for directions
    ;note the joystick cannot be in both opposite directions at once.  
    lda .JOY.CHANGED.ON
    and #%00000001 ;up 
    bne .JOY.TEST.UP
    lda .JOY.CHANGED.ON
    and #%00000010 ;down
    bne .JOY.TEST.DOWN
    .JOY.TEST.RIGHT_LEFT_TEST:
    lda .JOY.CHANGED.ON
    and #%00000100 ;left 
    bne .JOY.TEST.RIGHT
    lda .JOY.CHANGED.ON
    and #%00001000 ;right
    bne .JOY.TEST.LEFT
    .JOY.TEST.FIRE_TEST:
    lda .JOY.CHANGED.ON
    and #%00010000 ;fire
    bne .JOY.TEST.FIRE
    
    .JOY.TEST.UP_DOWN_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00000001 ;up 
    bne .JOY.TEST.UP.RELEASE
    lda .JOY.CHANGED.OFF
    and #%00000010 ;down
    bne .JOY.TEST.DOWN.RELEASE
    .JOY.TEST.RIGHT_LEFT_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00000100 ;left 
    bne .JOY.TEST.RIGHT.RELEASE
    lda .JOY.CHANGED.OFF
    and #%00001000 ;right
    bne .JOY.TEST.LEFT.RELEASE
    .JOY.TEST.FIRE_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00010000 ;fire
    bne .JOY.TEST.FIRE.RELEASE
    
    .JOY.TEST.EXIT:
    rts
    
    .JOY.TEST.UP:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST
      
    .JOY.TEST.DOWN:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST
      
    .JOY.TEST.RIGHT:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST
      
    .JOY.TEST.LEFT:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST
      
    .JOY.TEST.FIRE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.UP_DOWN_TEST.RELEASE
      
    .JOY.TEST.UP.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST.RELEASE
      
    .JOY.TEST.DOWN.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST.RELEASE
      
    .JOY.TEST.RIGHT.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST.RELEASE
      
    .JOY.TEST.LEFT.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST.RELEASE
      
    .JOY.TEST.FIRE.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.EXIT
     
      
      
  .KEY.POLL:
    ;shove away old input
    lda .KEY.IN
    sta .KEY.OLD
  
    ;utilize kernal routines to get keyboard input.
    jsr KERNAL.SCNKEY
    jsr KERNAL.GETIN
    sta .KEY.IN
    
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.UP:
    stx .JOY.TEST.UP + 2
    sty .JOY.TEST.UP + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.DOWN:
    stx .JOY.TEST.DOWN + 2
    sty .JOY.TEST.DOWN + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.RIGHT:
    stx .JOY.TEST.RIGHT + 2
    sty .JOY.TEST.RIGHT + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.LEFT:
    stx .JOY.TEST.LEFT + 2
    sty .JOY.TEST.LEFT + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.FIRE:
    stx .JOY.TEST.FIRE + 2
    sty .JOY.TEST.FIRE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.UP.RELEASE:
    stx .JOY.TEST.UP.RELEASE + 2
    sty .JOY.TEST.UP.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.DOWN.RELEASE:
    stx .JOY.TEST.DOWN.RELEASE + 2
    sty .JOY.TEST.DOWN.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.RIGHT.RELEASE:
    stx .JOY.TEST.RIGHT.RELEASE + 2
    sty .JOY.TEST.RIGHT.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.LEFT.RELEASE:
    stx .JOY.TEST.LEFT.RELEASE + 2
    sty .JOY.TEST.LEFT.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.FIRE.RELEASE:
    stx .JOY.TEST.FIRE.RELEASE + 2
    sty .JOY.TEST.FIRE.RELEASE + 1
    rts
  
  ;also used for making an event do nothing.
  .DO_NOTHING:
    rts
    
    
    
!zone LOGIC
  .B = $30 ;b register
  ;A contains state, X contains hi byte of jump table, Y contains lo byte of jump table.
  ;this routine only supports up to 64 states.
  .SWITCH:
    ;setup decoding tree.
    ;note that this means we only support up to 64 instructions in the menu interpreter.
    sta .B
    asl ;multiply by three.
    adc .B 
    sta .B ;store this for later addition.
    
    ;index where to jump to in the jump table.
    ;note that the carry operation is only necessary as the compiler cannot guarantee where this instruction ends up.
    stx .SWITCH.JUMP + 2 ;increment page because the carry was set when we added the lo byte.
    tya ;add it to how many bytes we have to look into the table.
    adc .B ;add it to the instruction jump table index
    sta .SWITCH.JUMP + 1
    bcc .SWITCH.JUMP ;jump now if we don't have to increment the high byte.  
    inc .SWITCH.JUMP + 2 ;page boundary crossed.
    
    .SWITCH.JUMP:
      jsr $0000 ;self modified
      rts
  

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
    
    

!zone MEMORY
  ;Fills 1K with the same character.  As fast as possible (6,664 cycles)
  ;Accumulator contains byte to fill, Y contains page high byte pointer.
  .FILL_4_PAGES:
    sty .FILL_PAGES.LOOP + 2 ;store page high byte.
    iny
    sty .FILL_PAGES.LOOP + 5 ;next page.
    iny
    sty .FILL_PAGES.LOOP + 8
    iny
    sty .FILL_PAGES.LOOP + 11
    
    ldy #0
    
    .FILL_PAGES.LOOP:
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      iny
      bne .FILL_PAGES.LOOP

      ;all pages done
      rts 
    
  ;Copies 1K.  As fast as possible (10,806 cycles).
  ;X contains page to copy, Y contains page destination.
  .COPY_4_PAGES:
    stx .COPY_PAGES.LOOP + 2
    sty .COPY_PAGES.LOOP + 5  
    inx
    iny
    stx .COPY_PAGES.LOOP + 8 ;next page
    sty .COPY_PAGES.LOOP + 11 ;next page
    inx
    iny
    stx .COPY_PAGES.LOOP + 14
    sty .COPY_PAGES.LOOP + 17
    inx
    iny 
    stx .COPY_PAGES.LOOP + 20
    sty .COPY_PAGES.LOOP + 23
  
    ldy #0
  
    .COPY_PAGES.LOOP:
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      iny
      bne .COPY_PAGES.LOOP ;branch if y has not returned to zero.
    
      ;all pages done
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

