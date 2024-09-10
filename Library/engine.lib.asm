!cpu 6510

!zone ENGINE

  ;MEMORY MAP
  ;the following areas always have the same space.
  .SAVE_FILE = $0334
  .SCRIPT_PRG = $0400
  .CORE_PRG = $2000
  .UI_CHAR = $4000
  .PLAYER_SPRITE = $4800
  .WEAPON_SPRITE = $5000
  .FRONT_BUFFER = $6000
  .BACK_BUFFER = $6400
  .LEVEL_CHAR = $6800
  .LEVEL_SPRITE = $7000
  .LEVEL_QUIET_MUSIC = $8000
  .LEVEL_DYNAMIC_MUSIC = $8800
  .LEVEL_SFX = $9000
  .LEVEL_TILES_PTR = $9800
  .LEVEL_MAP = $AC00
  .LEVEL_VARIABLES = $BC00
  .SCRATCHPAD_MEMORY = $C000

  * = .CORE_PRG

  .START:
    ;override the loader's IRQ.
    ;we can't link the addresses in compilation in a specified order, so we just use the global variables in the zero page instead.
    ;we are also gonna reuse these variables later, so just extract directly.
    lda $04
    sta .IRQ_CHAIN + 1
    lda $05
    sta .IRQ_CHAIN + 2
    
    lda #<.IRQ
    sta $0314
    lda #>.IRQ
    sta $0315
    
    jam
    
  .IRQ:
    jam
  
  
  .IRQ_CHAIN: 
    jmp $0000 ;self modified, usually ends up going back to KERNAL.
  
!zone