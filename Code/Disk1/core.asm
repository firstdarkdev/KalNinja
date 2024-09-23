!cpu 6510

* = $2000 ;ENGINE.CORE_PRG

;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
!source "../../Library/engine.lib.asm",once

!zone CORE

  .MENU_STATE = $FB
  .NEW_MENU_STATE = $FC
  
  .MENU_STATE.MAIN_MENU = 0
  .MENU_STATE.SAVE_MENU = 1
  .MENU_STATE.LOAD_MENU = 2
  .MENU_STATE.CUTSCENES = 3
  .MENU_STATE.HINTS = 4
  .MENU_STATE.HUD = 5
  .MENU_STATE.HUD.CONTROLLED = 6

  ;SCRIPTS
  * = SCRIPT.MENU_START
    
    ;setup menu loop script
    lda #<.LOOP
    ldx #>.LOOP
    jsr SCRIPT.REGISTER_MAIN_LOOP
    
    ;initialize the game state machine
    lda #.MENU_STATE.MAIN_MENU
    sta .NEW_MENU_STATE ;force the loop state machine to respond.
    lda #$ff ;null state
    sta .MENU_STATE
    
    ;return to engine
    rts
    
  .LOOP:
  
    ;detect a state change.
    lda .NEW_MENU_STATE
    cmp .MENU_STATE
    beq .LOOP.NO_STATE_CHANGE
    sta .MENU_STATE ;and update it.
    
    ;get the address for the next menu to render.
    ldx #>.LOOP.MENU_STATE.JUMP_TABLE
    ldy #<.LOOP.MENU_STATE.JUMP_TABLE
    jsr LOGIC.SWITCH
    
    ;set the menu submodule to use the selected data.
    jsr MENU.NEW
    jsr ENGINE.GO_MENU_MODE ;and switch to menu mode to render it.
    
    ;and exit.
    .LOOP.NO_STATE_CHANGE:
    
    
    rts ;return to engine
    
    
    
  ;SUBROUTINES

  
    

  ;EVENTS
  
    
  
  .LOOP.MENU_STATE.MAIN_MENU:
    jsr MENU.SUBSCRIBE_INPUT ;this menu takes control of input.
    ldx #<.MAIN_MENU
    ldy #>.MAIN_MENU
    
    rts
  
  .LOOP.MENU_STATE.SAVE_MENU:
    jsr MENU.SUBSCRIBE_INPUT ;this menu takes control of input.
    ldx #<.SAVE_MENU
    ldy #>.SAVE_MENU
    
    rts
    
  .LOOP.MENU_STATE.LOAD_MENU:
    jsr MENU.SUBSCRIBE_INPUT ;this menu takes control of input.
    ldx #<.LOAD_MENU
    ldy #>.LOAD_MENU
    
    rts
  
  .LOOP.MENU_STATE.CUTSCENES:
    jsr MENU.SUBSCRIBE_INPUT ;this menu takes control of input.
    ldx #<.CUTSCENE_MENU
    ldy #>.CUTSCENE_MENU
    
    rts
    
  .LOOP.MENU_STATE.HINTS:
    jsr MENU.SUBSCRIBE_INPUT ;this menu takes control of input.
    ldx #<.HINTS_MENU
    ldy #>.HINTS_MENU
    
    rts
    
  .LOOP.MENU_STATE.HUD.CONTROLLED:
    ;only let the HUD take input control in a certain menu state.
    jsr MENU.SUBSCRIBE_INPUT
    
  .LOOP.MENU_STATE.HUD:
    ldx #<.HUD_MENU
    ldy #>.HUD_MENU 
    
    rts
  
  
  
  .FULL_SCREEN_MENU.DRAW_BACKGROUND:
    lda #0 ;black background
    ldx #8 ;orange other colour
    ldy #9 ;brown shading
    jsr GRAPHICS.SET_CHAR_MULTICOLORS
  
    lda #" "
    ldx #4 ;1KB of memory to fill
    ldy ENGINE.BUFFER_POINTER_HI
    jsr MEMORY.FILL_PAGES
    
    lda #0 ;black
    ldx #4
    ldy #>ENGINE.COLOR_BACK_BUFFER
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
    ldy #%11011111
    jsr GRAPHICS.PUT_CHAR
    
    lda #1 ;white (no multicolor)
    jsr GRAPHICS.PUT_COLOR
  
    rts
    
  .MAIN_MENU.LOAD_GAME.REMOVE_CURSOR:
    lda #" "
    ;it is unbelievably fast to do the maths at coding time, so let's just do that...
    ldx #%00000010
    ldy #%11011111
    jsr GRAPHICS.PUT_CHAR
    
    lda #0 ;black
    jsr GRAPHICS.PUT_COLOR
  
    rts
  
    
  .MAIN_MENU.ON_NEW_GAME:
    jam
    ;TODO: reset save file.
  
    ;TODO: load the tutorial level immediately. 
    
    rts
    
  .MAIN_MENU.ON_LOAD_GAME:
    ;change to the load menu
    lda #.MENU_STATE.LOAD_MENU
    sta .NEW_MENU_STATE
    
    rts
    
    
    
  ;SWITCHES
  .LOOP.MENU_STATE.JUMP_TABLE:
    jmp .LOOP.MENU_STATE.MAIN_MENU
    jmp .LOOP.MENU_STATE.SAVE_MENU
    jmp .LOOP.MENU_STATE.LOAD_MENU
    jmp .LOOP.MENU_STATE.CUTSCENES
    jmp .LOOP.MENU_STATE.HINTS
    jmp .LOOP.MENU_STATE.HUD
    jmp .LOOP.MENU_STATE.HUD.CONTROLLED
    
    
    
  ;RESOURCES
  .MAIN_MENU:
    ;dimensions of the menu options
    !byte 1, 2 ;change if enabled options have changed.
  
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.FULL_SCREEN_MENU.DRAW_BACKGROUND, >.FULL_SCREEN_MENU.DRAW_BACKGROUND
      
    ;TODO: logo via ICON
    
    !byte MENU.ELEMENT.TEXT
      ;text expects a buffer index, not character coordinates.
      ;we do this at coding time, because it's super fast.
      !byte %11110010, %00000000, 5, .MAIN_MENU.INSTRUCTIONS.END - .MAIN_MENU.INSTRUCTIONS ;high up on the screen, hugs its width, non-multicolor green
      .MAIN_MENU.INSTRUCTIONS:
      !text "JOYSTICK (PORT 2) TO NAVIGATE MENUS"
      .MAIN_MENU.INSTRUCTIONS.END:
    
    ;choice parameter must be choice count.  if zero, we'll still render it, it just won't be considered for input.
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte %11110001, %00000001, 7, .MAIN_MENU.NEW_GAME.END - .MAIN_MENU.NEW_GAME ;somewhere in the middle of the screen, non-multicolor yellow
        .MAIN_MENU.NEW_GAME:
        !text "NEW GAME"
        .MAIN_MENU.NEW_GAME.END:
      !byte MENU.ELEMENT.CHOICE.ON_CHOSEN
        !byte <.MAIN_MENU.NEW_GAME.ADD_CURSOR, >.MAIN_MENU.NEW_GAME.ADD_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_NOT_CHOSEN
        !byte <.MAIN_MENU.NEW_GAME.REMOVE_CURSOR, >.MAIN_MENU.NEW_GAME.REMOVE_CURSOR
      !byte MENU.ELEMENT.CHOICE.ON_SELECT
        !byte <.MAIN_MENU.ON_NEW_GAME, >.MAIN_MENU.ON_NEW_GAME
        
    !byte MENU.ELEMENT.CHOICE
      !byte MENU.ELEMENT.TEXT
        !byte %11100001, %00000010, 7, .MAIN_MENU.LOAD_GAME.END - .MAIN_MENU.LOAD_GAME ;somewhere in the middle of the screen but lower than new game, non-multicolor yellow
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
    
  ;TODO
  .LOAD_MENU:
    !byte 1, 1
    
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.FULL_SCREEN_MENU.DRAW_BACKGROUND, >.FULL_SCREEN_MENU.DRAW_BACKGROUND
      
    !byte MENU.ELEMENT.END
  
  ;TODO
  .SAVE_MENU:
    !byte 1, 1
    
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.FULL_SCREEN_MENU.DRAW_BACKGROUND, >.FULL_SCREEN_MENU.DRAW_BACKGROUND
      
    !byte MENU.ELEMENT.END
  
  ;TODO
  .CUTSCENE_MENU:
    !byte 1, 1
    
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.FULL_SCREEN_MENU.DRAW_BACKGROUND, >.FULL_SCREEN_MENU.DRAW_BACKGROUND
      
    !byte MENU.ELEMENT.END
  
  ;TODO
  .HINTS_MENU:
    !byte 1, 1
    
    !byte MENU.ELEMENT.BACKGROUND
      !byte <.FULL_SCREEN_MENU.DRAW_BACKGROUND, >.FULL_SCREEN_MENU.DRAW_BACKGROUND
      
    !byte MENU.ELEMENT.END
  
  ;TODO
  .HUD_MENU:
    ;TODO

  * = ENGINE.UI_CHAR

  !media "../../Characters/core.charsetproject",char

  * = ENGINE.CORE_SPRITE

  !media "../../Sprites/core.spriteproject",sprite,0,96

!zone