!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  .GAME_STATE = $20
  .NEW_GAME_STATE = $21
  ;$24 to $29 are used for various operations, best not to use them to be safe from the KERNAL
  
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
    lda #MENU.TYPE.LIST
    ldx #<.MAIN_MENU
    ldy #>.MAIN_MENU
    jsr MENU.NEW_MENU
    
    lda #.GAME_STATE.MAIN_MENU
    sta .GAME_STATE
    sta .NEW_GAME_STATE
    
    ;sei is already done in MENU_START, so no need to control interrupt here again.
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
    jsr ENGINE.FILL_PAGES
    
    ;event responded.
    rts
    
  .MAIN_MENU.ADD_CURSOR:
    ;TODO
  
    rts
    
  .MAIN_MENU.REMOVE_CURSOR:
    ;TODO
    
    rts
    
  .MAIN_MENU.ON_NEW_GAME:
    ;set the engine to "load level mode" so it will escape correctly when the engine has stopped loading.
    lda #.GAME_STATE.TRAINING_VOID
    sta .NEW_GAME_STATE
    
    lda #<.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    ldx #>.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    ldy #.MAIN_MENU.ON_NEW_GAME.FILE_NAME_END - .MAIN_MENU.ON_NEW_GAME.FILE_NAME
    
    ;TODO: call engine loader.
    
    rts
    
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME:
      !text "INTRO,PRG"
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME_END:
    
  .MAIN_MENU.ON_LOAD_GAME:
    ;change to the load menu
    lda #.GAME_STATE.LOAD_MENU
    sta .NEW_GAME_STATE
    
    rts
    
    
  ;RESOURCES
  .MAIN_MENU:
    !byte MENU.ELEMENT.BACKGROUND_ROUTINE
      !byte <.MAIN_MENU.DRAW_BACKGROUND, >.MAIN_MENU.DRAW_BACKGROUND
      
    ;TODO: logo via ICON
    
    !byte MENU.ELEMENT.TEXT
      !byte 2, 6, 12, .MAIN_MENU.INSTRUCTIONS - .MAIN_MENU.INSTRUCTIONS.END ;high up on the screen, hugs its width, grey
      .MAIN_MENU.INSTRUCTIONS:
      !text "JOYSTICK (PORT 2) TO NAVIGATE MENUS"
      .MAIN_MENU.INSTRUCTIONS.END:
    
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte 15, 12, 7, .MAIN_MENU.NEW_GAME - .MAIN_MENU.NEW_GAME.END ;somewhere in the middle of the screen, yellow
        .MAIN_MENU.NEW_GAME:
        !text "NEW GAME"
        .MAIN_MENU.NEW_GAME.END:
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.ADD_CURSOR, >.MAIN_MENU.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.REMOVE_CURSOR, >.MAIN_MENU.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_NEW_GAME, >.MAIN_MENU.ON_NEW_GAME
        
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte 15, 18, 7, .MAIN_MENU.LOAD_GAME - .MAIN_MENU.LOAD_GAME.END ;somewhere in the middle of the screen but lower than new game, yellow
        .MAIN_MENU.LOAD_GAME:
        !text "LOAD GAME"
        .MAIN_MENU.LOAD_GAME.END:
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.ADD_CURSOR, >.MAIN_MENU.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.REMOVE_CURSOR, >.MAIN_MENU.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_LOAD_GAME, >.MAIN_MENU.ON_LOAD_GAME
      
    !byte MENU.ELEMENT.END

  * = ENGINE.UI_CHAR

  !media "../../Characters/ui.charsetproject",char

  * = ENGINE.CORE_SPRITE

  !media "../../Sprites/player.spriteproject",sprite,0,32
  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone