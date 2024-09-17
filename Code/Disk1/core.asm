!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  .GAME_STATE = $20
  .NEW_GAME_STATE = $21
  .LEVEL_NAME.LO = $22
  .LEVEL_NAME.HI = $23
  ;$24 to $29 are used for various operations, best not to use them to be safe from the KERNAL
  .LEVEL_NAME.LENGTH = $2A
  
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
    
    ;sei is already done in MENU_START, so no need to control interrupt here again.
    jsr ENGINE.GO_MENU_MODE
    
    ;return to engine
    rts
    
  .LOOP:
  
    ;TODO game state machine

    ;return to engine
    rts
    
  ;SUBROUTINES
  ;TODO: generalize this routine as its memory fill may be useful for other things.
  ;fills the buffer with the character in the accumulator.
  .FILL_MENU_BACKGROUND:
    ldx #0
    ldy ENGINE.BUFFER_POINTER_HI
    sty .FILL_MENU_BACKGROUND.LOOP + 2 ;store page high byte.
    
    .FILL_MENU_BACKGROUND.LOOP:
      sta $0000,Y
      iny
      bne .FILL_MENU_BACKGROUND.LOOP
    
      inx
      cpx #5 ;all four pages done.
      beq .FILL_MENU_BACKGROUND.DONE
      inc .FILL_MENU_BACKGROUND.LOOP + 2 ;next page
      jmp .FILL_MENU_BACKGROUND.LOOP
    
    .FILL_MENU_BACKGROUND.DONE:
      rts
    

  ;EVENTS
  .MAIN_MENU.DRAW_BACKGROUND:
    ;TODO: background colours
  
    lda #" "
    jsr .FILL_MENU_BACKGROUND
    
    ;event responded.
    rts
    
  .MAIN_MENU.ADD_CURSOR:
    ;TODO
  
    rts
    
  .MAIN_MENU.REMOVE_CURSOR:
    ;TODO
    
    rts
    
  .MAIN_MENU.ON_NEW_GAME:
    ;set the core to "load level mode."
    lda #.GAME_STATE.TRAINING_VOID
    sta .NEW_GAME_STATE
    
    lda #<.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    sta .LEVEL_NAME.LO
    lda #>.MAIN_MENU.ON_NEW_GAME.FILE_NAME
    sta .LEVEL_NAME.HI
    lda #.MAIN_MENU.ON_NEW_GAME.FILE_NAME_END - .MAIN_MENU.ON_NEW_GAME.FILE_NAME
    sta .LEVEL_NAME.LENGTH
    
    rts
    
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME:
      !text "INTRO,PRG"
    .MAIN_MENU.ON_NEW_GAME.FILE_NAME_END:
    
  .MAIN_MENU.ON_LOAD_GAME:
    lda #.GAME_STATE.LOAD_MENU
    sta .NEW_GAME_STATE
    
    rts
    
    
  ;RESOURCES
  .MAIN_MENU:
    !byte MENU.ELEMENT.BACKGROUND_ROUTINE
      !byte <.MAIN_MENU.DRAW_BACKGROUND, >.MAIN_MENU.DRAW_BACKGROUND
      
    ;TODO: logo via ICON
    ;TODO: colors
    
    !byte MENU.ELEMENT.TEXT
      !byte 2, 6 ;high up on the screen, hugs its width.
      !text "JOYSTICK (PORT 2) TO NAVIGATE MENUS",0,0
    
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte 15, 12 ;somewhere in the middle of the screen.
        !text "NEW GAME",0,0
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.ADD_CURSOR, >.MAIN_MENU.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.REMOVE_CURSOR, >.MAIN_MENU.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_NEW_GAME, >.MAIN_MENU.ON_NEW_GAME
        
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte 15, 18 ;somewhere in the middle of the screen but lower than new game
        !text "LOAD GAME",0,0
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