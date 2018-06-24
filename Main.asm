*=$0801
          BYTE $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $36, $34, $29, $00, $00, $00
target    TGT_C64
*=$0810
start
          lda  #$20      ; space
          ldx  #0        ; border color
          ldy  #0        ; background color
          jsr  clrscr    ; clear screen
          jsr  init      ; initialize system
                         ;jsr  music_init ; init music

          jsr  build_track
          jsr  update_track
          jsr  update_trl ; update track lines
main
                         ;jsr  joy2dir   ; read joystick
          jmp  main
;-------------------------------------------------------------------------------
;       IRQ
;-------------------------------------------------------------------------------
irq2
          lda  #$04
          sta  $d020
                         ;sta  $d021
          jsr  music_play;
          lda  #<irq1
          ldx  #>irq1
          sta  $0314
          stx  $0315
          ldy  #202      ; Create raster interrupt at line 204 / row 19
          jsr  update_track
          
          sty  $d012
          asl  $d019
          jmp  $ea81
irq1
          lda  #$05
          sta  $d020
                         ;sta  $d021
                         ;jsr  update_physics
          lda  $d016     ; load x-scroll value         
          and  #%111     ; mask value
          
          bne  @restx    
          jsr  update_trl ; update track lines
@restx
          lda  $d016     ; restore x-scroll
          and  #%11111000
          sta  $d016
          lda  #<irq2
          ldx  #>irq2
          sta  $0314
          stx  $0315
          ldy  #153      ; Create raster interrupt at line 153 / row 13
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
; routine: joy2dir
; purpose: get joystic 2 state
; output: j2dx, j2dy
;-------------------------------------------------------------------------------
joy2dir
@djrr    lda  $dc00     ; get input from port 2 only
@djrrb   ldy  #0        ; this routine reads and decodes the
          ldx  #0        ; joystick/firebutton input data in
          lsr            ; the accumulator. this least significant
          bcs  @djr0     ; 5 bits contain the switch closure
          dey            ; information. if a switch is closed then it
@djr0    lsr            ; produces a zero bit. if a switch is open then
          bcs  @djr1     ; it produces a one bit. The joystick dir-
          iny            ; ections are right, left, forward, backward
@djr1    lsr            ; bit3=right, bit2=left, bit1=backward,
          bcs  @djr2     ; bit0=forward and bit4=fire button.
          dex            ; at rts time dx and dy contain 2's compliment
@djr2    lsr            ; direction numbers i.e. $ff=-1, $00=0, $01=1.
          bcs  @djr3     ; dx=1 (move right), dx=-1 (move left),
          inx            ; dx=0 (no x change). dy=-1 (move up screen),
@djr3    lsr            ; dy=0 (move down screen), dy=0 (no y change).
          stx  j2dx      ; the forward joystick position corresponds
          sty  j2dy      ; to move up the screen and the backward
          rts            ; position to move down screen.
                         ;
                         ; at rts time the carry flag contains the fire
                         ; button state. if c=1 then button not pressed.
                         ; if c=0 then pressed.
j2dx      BYTE 0        ;joystick x dir
j2dy      BYTE 0        ;joystick y dir
;-------------------------------------------------------------------------------
*=$1000
music_init
          rts
music_play
          rts
*=$c000
update_physics
                         ;determine car state (solid, fly, jump)
                         ;handle joystic (speed change, orientation)
          rts
update_track
          
          ldx  @scroll             
          dex          
          txa
          and  #%00000111
          sta  @scroll
          lda  $d016
          and  #%11111000
          ora  @scroll
          sta  $d016
                         ;d016 scroll and major scroll
          rts
@scroll  BYTE 7


update_sprites
                         ;x,y position, sprite# based on orientation
          rts
;-------------------------------------------------------------------------------
; Update Track lines
;-------------------------------------------------------------------------------
update_trl
          ldx  #0
          ldy  @scr_offs 
          iny
          sty  @scr_offs
@loop
          lda  $8000,y   
          iny
          sta  $607,x    ;row 13
          sta  $62f,x    ;row 14
          sta  $657,x    ;row 15
          sta  $67f,x    ;row 16
          sta  $6a7,x    ;row 17
          sta  $6cf,x    ;row 18

          inx
          cpx  #40
          bne  @loop

          rts
@scr_offs BYTE 0
;-------------------------------------------------------------------------------
; Test track data at $c400
;-------------------------------------------------------------------------------
build_track
          ldx  #$ff
          ldy  #0
@loop
          dey
          tya
          sta  $8000,x   ;row 13
          dex
          bne  @loop
          rts