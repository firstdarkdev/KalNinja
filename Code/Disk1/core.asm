!cpu 6510

!source "../../Library/c64.asm",once
!source "../../Library/engine.asm",once

!zone CORE
  * = ENGINE.CORE_PRG
  
  ;include the actual library's binary in here.  the rest of this game's source should include the labels instead.
  !source "../../Library/engine.lib.asm",once
  
  * = ENGINE.UI_CHAR
  
  !media "../../Characters/ui.charsetproject",char
  
  * = ENGINE.PLAYER_SPRITE
  
  !media "../../Sprites/player.spriteproject",sprite,0,32
  
  * = ENGINE.WEAPON_SPRITE
  
  !media "../../Sprites/weapon.spriteproject",sprite,0,64

!zone