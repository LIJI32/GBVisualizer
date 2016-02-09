INCLUDE "gbhw.asm"

current_music_pause EQU $90
music_pointer EQU $91
done_flag EQU $93
pcm_read_index EQU $94
pcm_write_index EQU $95
pcm_ram_start EQU $c000

; Reading these two undocumented registers  returns the current PCM value of the
; 4 APU channels in each of their nibbles.
rPCM12 EQU $ff76
rPCM34 EQU $ff77

SECTION "VBlank", ROM0[$40]
    jp VBlank

SECTION "OAMInt", ROM0[$48]
    jp OAMInt

SECTION "Timer", ROM0[$50]
Timer::
    ; Point HL to the write position
    ld h, pcm_ram_start / $100
    ldh a, [pcm_write_index]
    ld l, a

    ; Advance the index
    inc a
    ldh [pcm_write_index],  a

    ; Sum the four nibbles in registers PCM12 and PCM34
    ldh a, [rPCM12]
    ld b, a
    ldh a, [rPCM34]
    ld d, a
    and $F
    ld c, a

    ld a, d

    swap a
    and $F
    add c
    ld c, a

    ld a, b

    and $F
    add c
    ld c, a

    ld a, b

    swap b
    and $F
    add c

    ; Store result to hl
    ld [hl], a

    reti

SECTION "Header", ROM0[$100]

Start::
    di
    jp _Start

SECTION "Home", ROM0[$150]

_Start::
    ; Increase the CPU speed from 4MHz to 8MHz
    ld a, 1
    ldh [rKEY1], a
    stop

    ; Init the stack
    ld sp, $fffe

    ; Init buffer pointers
    xor a
    ldh [pcm_write_index], a
    ldh [pcm_read_index], a

    ; Other inits
    call LCDOff
    call LoadGraphics
    call InitSound
    call CreateMap
    call LoadPalette
    call InitTimer

    ; Start Playing
    call InitMusic
    jp Main

WaitFrame::
    ldh a, [rLY]
    and a
    jr nz, WaitFrame
    ; Fall through

WaitVBlank::
    ldh a, [rLY]
    cp 145
    jr nz, WaitVBlank
    ret

LCDOff::
    call WaitVBlank
    ldh a, [rLCDC]
    and $7F
    ldh [rLCDC], a
    ret

LCDOn::
    di
    ldh a, [rLCDC]
    or $80
    ldh [rLCDC], a
    call WaitVBlank
    xor a
    ldh [rIF], a
    reti

InitTimer::
    ld a, $100-30 ; 262144 / 144*60 is about 30
    ldh [rTIMA], a
    ldh [rTMA], a
    ld a, 5 ; Enabled, 262144
    ldh [rTAC], a
    ret

InitSound::
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ldh [rNR21], a
    ld a, $20
    ldh [rNR32], a

; Make the waveform square.
    ld a, $FF
    ld hl, $FF30

    ld b, $8
.loop
    ld [hli], a
    dec b
    jr nz, .loop

    xor a
    ld b, $8
.loop2
    ld [hli], a
    dec b
    jr nz, .loop2
    ret

LoadGraphics::
    ld de, $8000
    ld b, TilesEnd - Tiles
    ld hl, Tiles
.loop
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    ret

Colors::
    dw $65C3
    dw $077F
    dw $5BDF
    dw $2108

LoadPalette::
    ld hl, Colors
    ld a, $80
    ldh [rBGPI], a
    ld b, 64
.loop
    ld a, [hli]
    ldh [rBGPD], a
    dec b
    jr nz, .loop
    ret


CreateMap::
    ld hl, $9800
    ld c, 18
.loopY
    ld b, 19
    ld a, 2
    ld [hli], a
    xor a
.loopX
    ld [hli], a
    dec b
    jr nz, .loopX
    ld b, 12
    ld a, 1
.loopX2
    ld [hli], a
    dec b
    jr nz, .loopX2
    xor 1
    dec c
    jr nz, .loopY
    ret

Tiles::
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000
    db %00000000

    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000
    db %11111111
    db %00000000

    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011
    db %11111101
    db %00000011


TilesEnd::

VBlank::
    ; Sync pointers
    ldh a, [pcm_read_index]
    ldh [pcm_write_index], a
    call HandleMusic
    reti

OAMInt::
    ; Point HL to the read position
    ld h, pcm_ram_start / $100
    ldh a, [pcm_read_index]
    ld l, a

    ; Advance the index
    inc a
    ldh [pcm_read_index],  a

    ; Read
    ld a, [hl]

    ; Negate
    xor $FF
    inc a

    ; Update SCX
    ldh [rSCX], a
    reti

InitMusic::
    xor a
    ldh [done_flag], a

    ; Init the music pointer
    ld a, Music >> 8
    ldh [music_pointer + 1], a
    ld a, Music & $FF
    ldh [music_pointer], a

    ; Clear pending interrupts
    ldh [rIF], a

    ; Enable interrupts
    ld a, 7
    ldh [rIE], a
    ld a, 32
    ldh [rSTAT], a
    call LCDOn
    ret

; The main loop. We only operate inside interrupts, we just constantly halt.
Main::
    halt
    jr Main

HandleMusic:
    ; The music system  is a simple array of  2-byte items.  The first byte is a
    ; pointer to HRAM (which includes our  sound registers) and second byte is a
    ; value that should be written into this pointer.
    ; We also define two variables in the HRAM:  current_music_pause, which will
    ; stop this loop when it's non-zero, and cause an n-frame pause in the music
    ; until the next byte is written.  The second variable, done_flag, reset the
    ; music pointer to loop the song.
    ; This function will never return without  writing to current_music_pause or
    ; the done_flag.
    ldh a, [music_pointer + 1]
    ld h, a
    ldh a, [music_pointer]
    ld l, a

.loop
    ldh a, [done_flag]
    and a
    jr nz, InitMusic
    ldh a, [current_music_pause]
    and a
    jr nz, .exit

    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld [c], a
    jr .loop

.exit
    dec a
    ldh [current_music_pause], a
    ld a, h
    ldh [music_pointer + 1], a
    ld a, l
    ldh [music_pointer], a
    ret

Music::
INCBIN "music.gbm"
db done_flag, $01 ; loop