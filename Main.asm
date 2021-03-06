 *=$0801
          BYTE $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $36, $34, $29, $00, $00, $00
target    TGT_C64
*=$0810
start
          lda  #$20       ; space
          ldx  #0         ; border color
          ldy  #0         ; background color
          jsr  clrscr     ; clear screen
          jsr  init_scroll_color
          jsr  init      ; initialize system
          jsr  draw_stripes
          jsr  music_init ; init music

          jsr  build_scroll
          ;jsr  update_scroll
          ;jsr  update_scroll_text ; update scroll text 
main
          
          jmp  main      
          
;-------------------------------------------------------------------------------
;       IRQ
;-------------------------------------------------------------------------------
irq2
          ;lda  #$00
          ;sta  $d020
          ;sta  $d021
          jsr  music_play;
          
          lda  #<irq1  ;save cycles
          ;ldx  #>irq1
          sta  $0314
          ;stx  $0315

          jsr  update_scroll
         
          ldy  #202      ; Create raster interrupt at line 204 / row 19 
          ;sty  $d012
          ;asl  $d019
          ;jmp  $ea81

          bcc   irq_end  ;save space

irq1
          ;lda  #0
          ;sta  $d020
          ;sta  $d021

          lda  $d016     ; load x-scroll value         
          and  #%111     ; mask value
          
          bne  @restx    
          jsr  update_scroll_text ; update scroll lines
@restx
          lda  $d016     ; restore x-scroll
          and  #%11111000
          sta  $d016
          
          lda  #<irq2
          ;ldx  #>irq2
          sta  $0314
          ;stx  $0315     
          
          ldy  #153      ; Create raster interrupt at line 153 / row 13
          
irq_end
          sty  $d012
          asl  $d019
          jmp  $ea81     
          

;-------------------------------------------------------------------------------
; routine: init
; purpose: initialize all
;-------------------------------------------------------------------------------
init
          sei            ; disable interrupts
          ldy  #$7f      ; $7f = %01111111
          sty  $dc0d     ; Turn off CIAs Timer interrupts
          sty  $dd0d     ; Turn off CIAs Timer interrupts
          lda  $dc0d     ; cancel all CIA-IRQs in queue/unprocessed
          lda  $dd0d     ; cancel all CIA-IRQs in queue/unprocessed
          lda  #$01      ; Set Interrupt Request Mask...
          sta  $d01a     ; ...we want IRQ by Rasterbeam
          lda  #$00      ; trigger first interrupt at row zero
          sta  $d012
          lda  $d011     ; Bit#0 of $d011 is basically...
          and  #$7f      ; ...the 9th Bit for $d012
          sta  $d011     ; we need to make sure it is set to zero
          lda  $d016     ; d016 is VIC-II control register.
          and  #%11110111; un-set bit 3 to enable 38 column mode
          sta  $d016
          lda  #<irq2
          ldx  #>irq2
          sta  $0314
          stx  $0315
          asl  $d019
          ;lda  #$1c
          ;sta  $d018     ; chars at $3000
          lda  #$80      ; disable shift+CBM
          sta  $0291
          lda  #$ff      ; disable cursor
          sta  $cc
          cli            ; enable interrupts
          rts
;-------------------------------------------------------------------------------
; routine: clrscr
; purpose: clear screen and set border and background color
; input  : a = fill character
;          x = border color
;          y = background color
;-------------------------------------------------------------------------------
clrscr
          stx  $d020
          sty  $d021
          ldx  #0
@loop     sta  $0400,x
          sta  $0500,x
          sta  $0600,x
          sta  $0700,x
          dex
          bne  @loop
          rts
;-------------------------------------------------------------------------------
; routine: init_scroll_color
; purpose: init text color on scroll area
; input  : none

;-------------------------------------------------------------------------------
init_scroll_color
     
          ldx  #0
@loop

          lda  @text_color_data,x   
    
          sta  $da07,x    ;row 13
          sta  $da2f,x    ;row 14
          sta  $da57,x    ;row 15
          sta  $da7f,x    ;row 16
          sta  $daa7,x    ;row 17
          sta  $dacf,x    ;row 18

          inx
          cpx  #40
          bne  @loop

          rts
@text_color_data
          byte 2,11,11,12,15
repeat 30
          byte 1
endrepeat          
          byte 15,12,11,11,11

draw_stripes          
          ldx  #40
@loop     lda  #$40      ;character
          sta  $5df,x    ; row 12
          sta  $6f7,x    ; row 19
          lda  #2        ;red
          sta  $d9df,x   
          sta  $daf7,x   
          dex
          bne  @loop
          rts

*=$1000
music_init
          rts
music_play
          rts

update_scroll
          
          ldx  @xscroll             
          dex          
          txa
          and  #%00000111
          sta  @xscroll
          lda  $d016
          and  #%11111000
          ora  @xscroll
          sta  $d016
                         ;d016 scroll and major scroll
          rts
@xscroll  BYTE 7


;-------------------------------------------------------------------------------
; Update Scroll text
;-------------------------------------------------------------------------------
reset_scroll_text
          sta  scr_offs  ; 0 already in A
          rts
update_scroll_text
          ldx  #0
          ldy  scr_offs 
          iny
          sty  scr_offs
@loop
          lda  $8000,y      ;get character
     
          beq  reset_scroll_text ;0 ends the text   

          ;sta  $607,x    ;row 13
          sta  $62f,x    ;row 14
          sta  $657,x    ;row 15
          sta  $67f,x    ;row 16
          sta  $6a7,x    ;row 17
          ;sta  $6cf,x    ;row 18
         
          iny
          inx
          cpx  #40
          bne  @loop

          rts
        
scr_offs BYTE 0
;-------------------------------------------------------------------------------
; Test track data at $c400
;-------------------------------------------------------------------------------
build_scroll
          ldx  #0
          clc
@loop
          lda @scrolltext,x   
          beq @exit
          sta $8000,x   ;row 13
          inx
          bcc @loop
@exit       
          lda  #$00      ;filler character            
@exit2    
          sta  $8000,x   
          inx
          bne @exit2
          rts
;;todo compress spaces
@scrolltext

repeat 40
          byte $20
endrepeat
          
          text 'hello '
          
repeat 10
          byte $20
endrepeat
          
          text 'what the fuck is going on here '
          text 'greetings to all geezers '
repeat 40
          byte $20
endrepeat
          byte 0

;end

