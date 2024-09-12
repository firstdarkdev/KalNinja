!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

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
    
    ;set engine to render it and not gameplay.
    lda #ENGINE.GAME_MODE.MENU
    sta ENGINE.GAME_MODE
    
  ;return to engine
    rts
    
  .LOOP:
  
    ;TODO all menu functionality.

    ;return to engine
    rts

  ;EVENTS
    
  ;RESOURCES
  .MAIN_MENU:
    

  * = ENGINE.UI_CHAR

  !media "../../Characters/ui.charsetproject",char

  * = ENGINE.PLAYER_SPRITE

  !media "../../Sprites/player.spriteproject",sprite,0,32

  * = ENGINE.WEAPON_SPRITE

  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone