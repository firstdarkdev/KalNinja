!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  ;SCRIPTS
  * = SCRIPT.MENU_START

  ;setup main menu
    lda #MENU.TYPE.LIST
    ldx #<.MAIN_MENU
    ldy #>.MAIN_MENU
    jsr MENU.NEW_MENU
    
  ;setup menu loop script
    lda #<.LOOP
    ldx #>.LOOP
    jsr SCRIPT.REGISTER_MENU_LOOP
    
  ;return to engine
    rts
    
  .LOOP:
  
    ;TODO all menu functionality.

    ;return to engine
    rts

  ;MENU EVENTS
  .MAIN_MENU.ON_LOAD:
    rts
  .MAIN_MENU.ON_NEW:
    rts
    
  ;PRIVATE RESOURCES
  .MAIN_MENU:
    ;title
    !byte MENU.TITLE
    !byte <.MAIN_MENU.TITLE, >.MAIN_MENU.TITLE
    !byte 0
    ;load
    !byte MENU.CHOICE
    !text "LOAD GAME"
    !byte 0
    !byte <.MAIN_MENU.ON_LOAD, >.MAIN_MENU.ON_LOAD
    !byte 0
    ;save
    !byte MENU.CHOICE
    !text "NEW GAME"
    !byte 0
    !byte <.MAIN_MENU.ON_NEW, >.MAIN_MENU.ON_NEW
    !byte 0
    !byte 0
    
    .MAIN_MENU.TITLE:
      !media "../../Library/menutitles.charscreen",charcolor,0,0,10,5

  * = ENGINE.UI_CHAR

  !media "../../Characters/ui.charsetproject",char

  * = ENGINE.PLAYER_SPRITE

  !media "../../Sprites/player.spriteproject",sprite,0,32

  * = ENGINE.WEAPON_SPRITE

  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone