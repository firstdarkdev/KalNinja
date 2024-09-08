!cpu 6510

!source "../../Library/c64.asm",once

!zone CORE

  FRONT_BUFFER = $0400
  BACK_BUFFER = $0800
  GAME_CHAR = $1000
  UI_CHAR = $1800
  CORE = $2000
  
  * = $1800
  
  !media "../../Characters/ui.charsetproject",char
  
  jam
  

!zone