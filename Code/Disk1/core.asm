!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  .GAME_STATE = $FB
  .NEW_GAME_STATE = $FC
  
  .GAME_STATE.MAIN_MENU = 1
  .GAME_STATE.SAVE_MENU = 2
  .GAME_STATE.LOAD_MENU = 3
  .GAME_STATE.PAUSE_MENU = 4
  .GAME_STATE.TRAINING_VOID = 5
  .GAME_STATE.GAMEPLAY = 6

  ;SCRIPTS
  * = SCRIPT.MENU_START
    
    ;setup menu loop script
    lda #<.LOOP
    ldx #>.LOOP
    jsr SCRIPT.REGISTER_MAIN_LOOP
    
    ;setup main menu
    ldx #<.MAIN_MENU
    ldy #>.MAIN_MENU
    jsr MENU.NEW
    jsr MENU.SUBSCRIBE_INPUT
    
    ;initialize the game state machine
    lda #.GAME_STATE.MAIN_MENU
    sta .GAME_STATE
    sta .NEW_GAME_STATE
    
    ;sei and cli is already done in MENU_START, so no need to control interrupt here again.
    jsr ENGINE.GO_MENU_MODE
    
    ;return to engine
    rts
    
  .LOOP:
  
    ;TODO game state machine

    ;return to engine
    rts
    
  ;SUBROUTINES

    

  ;EVENTS
  .MAIN_MENU.DRAW_BACKGROUND:
    lda #0 ;black background
    ldx #1 ;orange white highlights
    ldy #9 ;orange shading
    jsr ENGINE.SET_CHAR_MULTICOLORS
  
    lda #" "
    ldx #4 ;1KB of memory to fill
    ldy ENGINE.BUFFER_POINTER_HI
    jsr MEMORY.FILL_PAGES
    
    ;event responded.
    rts
    
  .MAIN_MENU.NEW_GAME.ADD_CURSOR:
    lda #">"
    ;it is unbelievably fast to do the maths at coding time, so let's just do that...
    ldx #%00000001
    ldy #%11101111
    jsr GRAPHICS.PUT_CHAR
    
    lda #1 ;white
    jsr GRAPHICS.PUT_COLOR
  
    rts
    
  .MAIN_MENU.NEW_GAME.REMOVE_CURSOR:
    lda #" "
    ;it is unbelievably fast to do the maths at coding time, so let's just do that...
    ldx #%00000001
    ldy #%11101111
    jsr GRAPHICS.PUT_CHAR
    
    lda #0 ;black
    jsr GRAPHICS.PUT_COLOR
  
    rts
  
  .MAIN_MENU.LOAD_GAME.ADD_CURSOR:
    lda #">"
    ;it is unbelievably fast to do the maths at coding time, so let's just do that...
    ldx #%00000010
    ldy #%11101111
    jsr GRAPHICS.PUT_CHAR
    
    lda #1 ;white
    jsr GRAPHICS.PUT_COLOR
  
    rts
    
  .MAIN_MENU.LOAD_GAME.REMOVE_CURSOR:
    lda #" "
    ;it is unbelievably fast to do the maths at coding time, so let's just do that...
    ldx #%00000010
    ldy #%11101111
    jsr GRAPHICS.PUT_CHAR
    
    lda #0 ;black
    jsr GRAPHICS.PUT_COLOR
  
    rts
  
    
  .MAIN_MENU.ON_NEW_GAME:
    ;set the engine to "load level mode" so it will escape correctly when the engine has stopped loading.
    lda #.GAME_STATE.TRAINING_VOID
    sta .NEW_GAME_STATE
    
    lda #<.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    ldx #>.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    ldy #.MAIN_MENU.ON_NEW_GAME.FILE_NAME_END - .MAIN_MENU.ON_NEW_GAME.FILE_NAME
    
    ;TODO: call engine loader.
    jam
    
    rts
    
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME:
      !text "INTRO,PRG"
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME_END:
    
  .MAIN_MENU.ON_LOAD_GAME:
    ;change to the load menu
    lda #.GAME_STATE.LOAD_MENU
    sta .NEW_GAME_STATE
    
    ;TODO: remove
    jam
    
    rts
    
    
  ;RESOURCES
  .MAIN_MENU:
    ;dimensions of the menu options
    !byte 1, 2 ;change if enabled options have changed.
  
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.MAIN_MENU.DRAW_BACKGROUND, >.MAIN_MENU.DRAW_BACKGROUND
      
    ;TODO: logo via ICON
    
    !byte MENU.ELEMENT.TEXT
      ;text expects a buffer index, not character coordinates.
      ;we do this at coding time, because it's super fast.
      !byte %11110010, %00000000, 12, .MAIN_MENU.INSTRUCTIONS - .MAIN_MENU.INSTRUCTIONS.END ;high up on the screen, hugs its width, grey
      .MAIN_MENU.INSTRUCTIONS:
      !text "JOYSTICK (PORT 2) TO NAVIGATE MENUS"
      .MAIN_MENU.INSTRUCTIONS.END:
    
    ;choice parameter must be choice count.  if zero, we'll still render it, it just won't be considered for input.
    !byte MENU.ELEMENT.CHOICE, 1 ;always enabled
      !byte MENU.ELEMENT.TEXT
        !byte %11101111, %00000001, 7, .MAIN_MENU.NEW_GAME - .MAIN_MENU.NEW_GAME.END ;somewhere in the middle of the screen, yellow
        .MAIN_MENU.NEW_GAME:
        !text "NEW GAME"
        .MAIN_MENU.NEW_GAME.END:
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.NEW_GAME.ADD_CURSOR, >.MAIN_MENU.NEW_GAME.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.NEW_GAME.REMOVE_CURSOR, >.MAIN_MENU.NEW_GAME.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_NEW_GAME, >.MAIN_MENU.ON_NEW_GAME
        
    !byte MENU.ELEMENT.CHOICE, 1 ;always enabled
      !byte MENU.ELEMENT.TEXT
        !byte %11101111, %00000010, 7, .MAIN_MENU.LOAD_GAME - .MAIN_MENU.LOAD_GAME.END ;somewhere in the middle of the screen but lower than new game, yellow
        .MAIN_MENU.LOAD_GAME:
        !text "LOAD GAME"
        .MAIN_MENU.LOAD_GAME.END:
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.LOAD_GAME.ADD_CURSOR, >.MAIN_MENU.LOAD_GAME.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.LOAD_GAME.REMOVE_CURSOR, >.MAIN_MENU.LOAD_GAME.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_LOAD_GAME, >.MAIN_MENU.ON_LOAD_GAME
      
    !byte MENU.ELEMENT.END

  * = ENGINE.UI_CHAR

  !media "../../Characters/core.charsetproject",char

  * = ENGINE.CORE_SPRITE

  !media "../../Sprites/core.spriteproject",sprite,0,96

!zone