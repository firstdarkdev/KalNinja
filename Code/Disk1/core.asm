!cpu 6510

!source "../../Library/c64.asm",once

!zone CORE
  ;MEMORY MAP
  ;the following areas always have the same space.
  ;TODO consider allowing memory growth to save floppy disk space.
  SAVE_FILE = $0334
  SCRIPT_PRG = $0400
  CORE_PRG = $2000
  UI_CHAR = $4000
  PLAYER_SPRITE = $4800
  WEAPON_SPRITE = $5000
  FRONT_BUFFER = $6000
  BACK_BUFFER = $6400
  LEVEL_CHAR = $6800
  LEVEL_SPRITE = $7000
  LEVEL_QUIET_MUSIC = $8000
  LEVEL_DYNAMIC_MUSIC = $8800
  LEVEL_SFX = $9000
  LEVEL_TILES_PTR = $9800
  LEVEL_MAP = $AC00
  LEVEL_VARIABLES = $BC00
  SCRATCHPAD_MEMORY = $C000
  
  * = CORE_PRG
  
  jam
  
  * = UI_CHAR
  
  !media "../../Characters/ui.charsetproject",char
  
  * = PLAYER_SPRITE
  
  !media "../../Sprites/player.spriteproject",sprite,0,32
  
  * = WEAPON_SPRITE
  
  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone