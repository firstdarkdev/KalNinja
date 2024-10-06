!zone LOGIC
  .B = $30 ;b register
  ;A contains state, X contains hi byte of jump table, Y contains lo byte of jump table.
  ;this routine only supports up to 64 states.
  .SWITCH:
    ;setup decoding tree.
    ;note that this means we only support up to 64 instructions in the menu interpreter.
    sta .B
    asl ;multiply by three.
    adc .B 
    sta .B ;store this for later addition.
    
    ;index where to jump to in the jump table.
    ;note that the carry operation is only necessary as the compiler cannot guarantee where this instruction ends up.
    stx .SWITCH.JUMP + 2 ;increment page because the carry was set when we added the lo byte.
    tya ;add it to how many bytes we have to look into the table.
    adc .B ;add it to the instruction jump table index
    sta .SWITCH.JUMP + 1
    bcc .SWITCH.JUMP ;jump now if we don't have to increment the high byte.  
    inc .SWITCH.JUMP + 2 ;page boundary crossed.
    
    .SWITCH.JUMP:
      jsr $0000 ;self modified
      rts