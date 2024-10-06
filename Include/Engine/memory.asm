!zone MEMORY
  ;Fills 1K with the same character.  As fast as possible (6,664 cycles)
  ;Accumulator contains byte to fill, Y contains page high byte pointer.
  .FILL_4_PAGES:
    sty .FILL_PAGES.LOOP + 2 ;store page high byte.
    iny
    sty .FILL_PAGES.LOOP + 5 ;next page.
    iny
    sty .FILL_PAGES.LOOP + 8
    iny
    sty .FILL_PAGES.LOOP + 11
    
    ldy #0
    
    .FILL_PAGES.LOOP:
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      sta $0000,Y ;self modified at the start.
      iny
      bne .FILL_PAGES.LOOP

      ;all pages done
      rts 
    
  ;Copies 1K.  As fast as possible (10,806 cycles).
  ;X contains page to copy, Y contains page destination.
  .COPY_4_PAGES:
    stx .COPY_PAGES.LOOP + 2
    sty .COPY_PAGES.LOOP + 5  
    inx
    iny
    stx .COPY_PAGES.LOOP + 8 ;next page
    sty .COPY_PAGES.LOOP + 11 ;next page
    inx
    iny
    stx .COPY_PAGES.LOOP + 14
    sty .COPY_PAGES.LOOP + 17
    inx
    iny 
    stx .COPY_PAGES.LOOP + 20
    sty .COPY_PAGES.LOOP + 23
  
    ldy #0
  
    .COPY_PAGES.LOOP:
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      lda $0000,Y ;self modified
      sta $0000,Y ;self modified
      iny
      bne .COPY_PAGES.LOOP ;branch if y has not returned to zero.
    
      ;all pages done
      rts