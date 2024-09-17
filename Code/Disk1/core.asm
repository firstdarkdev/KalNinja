!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  .GAME_STATE = $20
  .NEW_GAME_STATE = $21
  
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

  ;EVENTS
    
  ;RESOURCES
  .MAIN_MENU:
    

  * = ENGINE.UI_CHAR

  !media "../../Characters/ui.charsetproject",char

  * = ENGINE.CORE_SPRITE

  !media "../../Sprites/player.spriteproject",sprite,0,32
  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone