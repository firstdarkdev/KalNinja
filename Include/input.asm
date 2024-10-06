!zone INPUT
  .JOY.IN = $20
  .JOY.OLD = $21
  ;$22-$25 are used for "various operations", best not to mess with it.
  .KEY.IN = $26
  .KEY.OLD = $27
  .JOY.CHANGED.ON = $28
  .JOY.CHANGED.OFF = $29
  
  .JOY.RESET:
    ldy #<.DO_NOTHING
    ldx #>.DO_NOTHING
    
    stx .JOY.TEST.UP + 2
    sty .JOY.TEST.UP + 1
    stx .JOY.TEST.DOWN + 2
    sty .JOY.TEST.DOWN + 1
    stx .JOY.TEST.RIGHT + 2
    sty .JOY.TEST.RIGHT + 1
    stx .JOY.TEST.LEFT + 2
    sty .JOY.TEST.LEFT + 1
    stx .JOY.TEST.FIRE + 2
    sty .JOY.TEST.FIRE + 1
    stx .JOY.TEST.UP.RELEASE + 2
    sty .JOY.TEST.UP.RELEASE + 1
    stx .JOY.TEST.DOWN.RELEASE + 2
    sty .JOY.TEST.DOWN.RELEASE + 1
    stx .JOY.TEST.RIGHT.RELEASE + 2
    sty .JOY.TEST.RIGHT.RELEASE + 1
    stx .JOY.TEST.LEFT.RELEASE + 2
    sty .JOY.TEST.LEFT.RELEASE + 1
    stx .JOY.TEST.FIRE.RELEASE + 2
    sty .JOY.TEST.FIRE.RELEASE + 1
    
    rts
  
    
      
  .JOY.POLL:
    ;shove away old input.
    lda .JOY.IN
    sta .JOY.OLD
  
    ;instruct CIA1 to get joystick input.
    lda CIA1.DATA_PORT_A
    eor #%11111111 ;invert itself
    sta .JOY.IN
    
    rts
      
    
  
  ;test and fire events according to changes in the input, ignoring holds.
  .JOY.TEST:
    ;find out which buttons have been changed to on and which ones off.
    lda .JOY.IN ;get current CIA result
    eor .JOY.OLD ;only show flags that are new.
    sta .JOY.CHANGED.ON ;store temporarily.
    lda .JOY.OLD ;look back at the old ones.
    and .JOY.CHANGED.ON ;see if any match the new one.
    sta .JOY.CHANGED.OFF ;ones that are in the old one are treated as now off.
    eor .JOY.CHANGED.ON ;only ones that were not in the old one are treated as now turned on.
    sta .JOY.CHANGED.ON ;store result for the ones now treated as on.
  
    ;choose an input routine for directions
    ;note the joystick cannot be in both opposite directions at once.  
    lda .JOY.CHANGED.ON
    and #%00000001 ;up 
    bne .JOY.TEST.UP
    lda .JOY.CHANGED.ON
    and #%00000010 ;down
    bne .JOY.TEST.DOWN
    .JOY.TEST.RIGHT_LEFT_TEST:
    lda .JOY.CHANGED.ON
    and #%00000100 ;left 
    bne .JOY.TEST.RIGHT
    lda .JOY.CHANGED.ON
    and #%00001000 ;right
    bne .JOY.TEST.LEFT
    .JOY.TEST.FIRE_TEST:
    lda .JOY.CHANGED.ON
    and #%00010000 ;fire
    bne .JOY.TEST.FIRE
    
    .JOY.TEST.UP_DOWN_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00000001 ;up 
    bne .JOY.TEST.UP.RELEASE
    lda .JOY.CHANGED.OFF
    and #%00000010 ;down
    bne .JOY.TEST.DOWN.RELEASE
    .JOY.TEST.RIGHT_LEFT_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00000100 ;left 
    bne .JOY.TEST.RIGHT.RELEASE
    lda .JOY.CHANGED.OFF
    and #%00001000 ;right
    bne .JOY.TEST.LEFT.RELEASE
    .JOY.TEST.FIRE_TEST.RELEASE:
    lda .JOY.CHANGED.OFF
    and #%00010000 ;fire
    bne .JOY.TEST.FIRE.RELEASE
    
    .JOY.TEST.EXIT:
    rts
    
    .JOY.TEST.UP:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST
      
    .JOY.TEST.DOWN:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST
      
    .JOY.TEST.RIGHT:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST
      
    .JOY.TEST.LEFT:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST
      
    .JOY.TEST.FIRE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.UP_DOWN_TEST.RELEASE
      
    .JOY.TEST.UP.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST.RELEASE
      
    .JOY.TEST.DOWN.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.RIGHT_LEFT_TEST.RELEASE
      
    .JOY.TEST.RIGHT.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST.RELEASE
      
    .JOY.TEST.LEFT.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.FIRE_TEST.RELEASE
      
    .JOY.TEST.FIRE.RELEASE:
      jsr .DO_NOTHING ;self modified
      jmp .JOY.TEST.EXIT
     
      
      
  .KEY.POLL:
    ;shove away old input
    lda .KEY.IN
    sta .KEY.OLD
  
    ;utilize kernal routines to get keyboard input.
    jsr KERNAL.SCNKEY
    jsr KERNAL.GETIN
    sta .KEY.IN
    
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.UP:
    stx .JOY.TEST.UP + 2
    sty .JOY.TEST.UP + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.DOWN:
    stx .JOY.TEST.DOWN + 2
    sty .JOY.TEST.DOWN + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.RIGHT:
    stx .JOY.TEST.RIGHT + 2
    sty .JOY.TEST.RIGHT + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.LEFT:
    stx .JOY.TEST.LEFT + 2
    sty .JOY.TEST.LEFT + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.FIRE:
    stx .JOY.TEST.FIRE + 2
    sty .JOY.TEST.FIRE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.UP.RELEASE:
    stx .JOY.TEST.UP.RELEASE + 2
    sty .JOY.TEST.UP.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.DOWN.RELEASE:
    stx .JOY.TEST.DOWN.RELEASE + 2
    sty .JOY.TEST.DOWN.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.RIGHT.RELEASE:
    stx .JOY.TEST.RIGHT.RELEASE + 2
    sty .JOY.TEST.RIGHT.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.LEFT.RELEASE:
    stx .JOY.TEST.LEFT.RELEASE + 2
    sty .JOY.TEST.LEFT.RELEASE + 1
    rts
    
  ;X contains hi, Y contains lo.
  .JOY.SUBSCRIBE.FIRE.RELEASE:
    stx .JOY.TEST.FIRE.RELEASE + 2
    sty .JOY.TEST.FIRE.RELEASE + 1
    rts
  
  ;also used for making an event do nothing.
  .DO_NOTHING:
    rts