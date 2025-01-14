*-----------------------------------------------------------
* Title      : Assembly Airplane's Astonishing Acceleratory Advancement And Annihilation
* Written by : Igor Antonov
* Date       : 29/01/2024
* Description: An amazing game about grandiose adventures of a tiny paper airplane who chased the sun.
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

	bsr initSound
* Put program code here
	move.w #3, ship_speed
	move.w #$180, player_position
	move.w #0, player_position+4
	move.w #1, level_number
	move.l #0, points_score
	bsr enableDoubleBuffering
	bsr playMainTheme
BIGLOOP:
	bsr clearScreen
	bsr drawBackground
	bsr processGameInput
	;update stuff
	move.w ship_speed, d0
	add.w d0, player_position+4
	add.w #1, time_counter
	move.w time_counter, d0
	and.w #$0FFF, d0
	cmp.w #$F00, d0
	bne .dont_speedup
	add.w #1, ship_speed
	clr.l d0
	move.w ship_speed, d0
	add.l d0, points_score
.dont_speedup
	;stay positive :D
	cmp.w #$6400, player_position+4
	blt .dont_advance
	bsr increaseLevel
	move.w #0, player_position+4
.dont_advance
	
	lea example_map, A1
	bsr drawMap
	
	; draw player
	move.w player_position, ship_position
	move.w player_position+4, ship_position+4
	move.l #$0010AAAA, D1
	bsr setPenColor
	bsr getShipModel
	lea $10000, A1
	lea ship_position, a2
	bsr projectAllModelVertices
	bsr getShipModel
	lea $10000, A1
	lea ship_position, a2

	bsr drawAllTriangles
	
	bsr processCollisions
	lea example_map, A1
	bsr maybeInsertPowerup
	
	bsr displayPoints
.end_chlg
	bsr repaintScreen
	bra BIGLOOP
	
ship_position: dc.w 0, -64, 0
ship_speed: dc.w 3
level_number dc.w 1
points_score dc.l 0
upgrade_stage: dc.w 0
upgrade_table: dc.l paperplane_model
maxUpgrade EQU 0

initSound:
	lea you_died_sndpath, a1
	move.b #0, D1
	bsr loadSound
	lea maintheme_sndpath, a1
	move.b #1, D1
	bsr loadSound
	rts
	
playMainTheme:
	bsr stopAllSound
	move.b #1, D1
	bsr playLoopSound
	rts
	
playDeathSignal:
	bsr stopAllSound
	move.b #0, d1
	bsr playSound
	rts

loadSound: ; args: (a1) - filepath, d1.b - sound id
	move.b #71, d0
	trap #15
	rts

playSound: ; args: d1.b - sound id
	move.b #72, d0
	trap #15
	rts

stopAllSound: ;args: none
	move.l #3, D2
	move.b #76, D0
	trap #15
	rts

playLoopSound: ;args: d1.b - sound id
	move.l #1, D2
	move.b #76, D0
	trap #15
	rts


you_died_sndpath: dc.b './died.wav', 0
maintheme_sndpath: dc.b './haupth.wav', 0
 

getShipModel: ; returns a0 - model address
    lea upgrade_table, A0
    clr.l d0
    move.w upgrade_stage, d0
    asl.l #2, D0 ; each address is 4 bytes
    add.l D0, A0
    move.l (A0), A0
    rts

getUpgradeModel:
	move.l #upgrade_table, A0
	clr.l d0
	move.w upgrade_stage, d0
	add.l #1, D0
	asl.l #2, D0 ; each address is 4 bytes
	add.l D0, A0
	move.l (A0), A0
.end
	rts

increaseLevel:
	bsr clearScreen
	add.w #1, level_number
	move.l #$00FFFFFF, D1
	bsr setPenColor
	lea newlevel_msg, A1
	move.b #14, D0
	trap #15
	clr.l d1
	move.w level_number, d1
	move.b #3, d0
	trap #15
	bsr repaintScreen
.chk_spc
	move.b #' ', D1
	bsr areKeysPressed
	cmp.b #$FF, D1
	bne .chk_spc
	rts
	
displayPoints:
    move.l points_score, D1
    bsr putInt
    lea zeros_msg, a1
    bsr putStr
    rts
	
processCollisions:

	clr.l D1
	clr.l D2
	move.w ship_position, D1
	move.w ship_position+4, D2
	add.w #0,d1
	add.w #256, D2
	asr.w #8, D1
	asr.w #8, D2
	lea example_map, A1
	bsr getMapTile
	bsr checkTileCollision
	
	move.w ship_position, D1
	move.w ship_position+4, D2
	add.w #256,d1
	add.w #256, D2
	asr.w #8, D1
	asr.w #8, D2
	lea example_map, A1
	bsr getMapTile
	bsr checkTileCollision

	
	rts
	
checkTileCollision:
	cmp.b #'#', D0
	beq killPlayer
	cmp.b #'@', D0
	bne .end ; it's a powerup!
	move.b #'.', D0
	bsr setMapTile
	add.l #5, points_score
.end
	rts

putInt: ; args: D1 - integer
	move.b #3, d0
	trap #15
	rts
	
putStr: ;ARGS: a1 - string
	move.b #14, D0
	trap #15
	rts


killPlayer:
	bsr clearScreen
	add.w #1, level_number
	move.l #$00FFFFFF, D1
	bsr setPenColor
	lea dead_msg, A1
	move.b #14, D0
	trap #15
	bsr repaintScreen
	bsr playDeathSignal
.chk_spc
	move.b #' ', D1
	bsr areKeysPressed
	cmp.b #$FF, D1
	bne .chk_spc
	bra START
	
zeros_msg: dc.b '00', 0
dead_msg: dc.b 'Congratulations! You crashed and died!', 0
newlevel_msg: dc.b 'Congratulations! You reached level ', 0
	
SIMHALT             ; halt simulator
* Put variables and constants here
toggleFullscreen:
	not.w .is_fullscreen
	cmp.w #$FFFF, .is_fullscreen
	beq .set_fullscreen
	move.l #1, D1
	move.b #33, D0
	trap #15
	bra .end
.set_fullscreen
	move.l #2, D1
	move.b #33, D0
	trap #15
.end
	rts
.is_fullscreen: dc.w $0000

time_counter dc.w 0
processGameInput:
	move.b #'W', D1
	LSL.l #8, D1
	move.b #'F', D1
	LSL.l #8, D1
	move.b #'A', D1
	LSL.l #8, D1
	move.b #'D', D1
	bsr areKeysPressed
	cmp.b #$FF, D1
	BNE end_pgi
	move.w ship_speed, d0
	asl.w #2, d0
	add.w d0, player_position
end_pgi:
	lsr.l #8, d1
	cmp.b #$FF, D1
	bne .next
	move.w ship_speed, d0
	asl.w #2, d0
	sub.w d0, player_position
.next
    lsr.l #8, D1
    cmp.b #$FF, D1
    bne .end
    ;need to put fullscreen stuff here
	bsr toggleFullscreen
	
.end
	rts

drawBackground:
	bsr drawSun
	bsr drawEarth
	rts
	
drawSun:
	move.l #$0000EEFF, D1
	bsr setPenColor
	bsr setFillColor
	move.w #(320-60), D1
 	 move.w #(240-60), D2
	  move.w #(320+60), D3
	   move.w #(240+60), D4
	   bsr drawEllipse
	   bsr drawSunLines
	   rts

drawSunLines:
	move.l #$0, D0
	bsr setPenColor
	bsr SetFillColor
	;same for all lines
	move.w #(320-60), D1
	move.w #(320+60), D3
	; line 1
	move.w #(240+18), D2
	move.w #(240+22), D4
	bsr drawRect
	;line 2
	move.w #(240+30), D2
	move.w #(240+37), D4
	bsr drawRect
	;line 3
	move.w #(240+45), D2
	move.w #(240+55), D4
	bsr drawRect
	rts
	

drawEarth:
	move.l #$00200500, d1 ;very dark bluish
	bsr setPenColor
	bsr setFillColor
	move.w #0, D1
	move.w #290, D2
	move.w #640, D3
	move.w #480, D4
	bsr drawRect
	rts

drawEllipse: ;args: D1 - X1, D2 - Y1, D2 - X2, D3 - Y2
	move.b #88, D0
	trap #15
	rts

drawRect:;args: D1 - X1, D2 - Y1, D2 - X2, D3 - Y2
	move.b #87, D0
	trap #15
	rts

setFillColor: ; args: D1 = $00BBGGRR 
	move.b #81, D0
	trap #15
	rts
	
areKeysPressed: ;args: D1.l - 4 key codes; returns: d1.l - 4 booleans
	move.b #19, D0
	trap #15
	rts

drawLine: ; draws line from (D1.w, D2.w) to (D3.w, D4.w) 
    move.l #84, D0
    trap #15
    rts
    
enableDoubleBuffering:
    move.l #92, D0
    move.l D1, -(SP)
    move.b #17, D1
    trap #15
    move.l (SP)+, D1
    rts
   
    
repaintScreen:
    move.l #94, D0
    trap #15
    rts
    
setPenColor: ;args: D1.L - #$00BBGGRR
	move.b #80, D0
	trap #15
	rts

    
clearScreen:
    move.l #11, D0
    move.w D1, -(SP)
    move.w #$FF00, D1
    trap #15
    move.w (SP)+, D1
    rts
    
setPenWidth: ; args: d1 - width
    move.b #93, d0
    trap #15
    rts
    
drawPixel: ; args: d1 - x, d2 - y
    move.b #82, d0
    trap #15
    rts
    
projectPoint: ;args: a0 - point address, a1 - player position, a2 - point offset; results: d1 - x, d2 - y
	move.w 4(a0), d6
	sub.w 4(a1), d6 ; z_point - z_player
	ADD.W 4(A2), D6 ; z_point - z_player + POINT OFFSET
	
	move.w 0(a0), d1 ; x
	sub.w 0(a1), d1 ; x_point - x_player
	ADD.W 0(A2), D1 ; + POINT OFFSET
	
	muls #SIN_60, D1
	divs D6, D1
	and.l #$0000FFFF, D1
	
	move.w 2(a0), D2 ; y
	sub.w 2(a1), D2 ; y_point- y_player
	ADD.W 2(A2), D2 ; + POINT OFFSET
	
	muls.w #SIN_60, D2
	divs.w D6, D2
	and.l #$0000FFFF, D2
	
	rts
	
viewportToScreen: ;args; d1 - x, d2 - y, ;results - d1 - x_screen, d2 - y_screen
	muls #SCREEN_WIDTH, D1
	asr.l #1, D1 ; convert from fixed point <<8 to integer
	
	muls #SCREEN_WIDTH, D2
	asr.l #1, D2 ; adjust so it's and integer too
	
	add.w #SCREEN_HCENTER, D1
	neg.w D2
	add.w #SCREEN_VCENTER, D2
	
	rts
	
renderPoint:
	bsr projectPoint
	bsr viewportToScreen
	bsr drawPixel
	rts

render2DWireframeTriangle: ;args: A0, A1, A2 - p1, p2, p3
	move.w 0(A0), D1
	move.w 2(A0), D2
	move.w 0(A1), D3
	move.w 2(A1), D4
	bsr drawLine
	move.w 0(A2), D3
	move.w 2(A2), D4
	bsr drawLine
	move.w 0(A1), D1
	move.w 2(A1), D2
	bsr drawLine
	rts

projectAllModelVertices: ;args: A0 - model address, A1 - where to write the points, A2 - OFFSET
	move.l a1, -(SP)
	move.w player_position+4, -(SP)
	sub.w #$256, player_position+4
	clr.l D7
	move.b 0(A0), D7 ; vertex number
	sub.b #1, D7
	move.b #0, D6 ; current vertex
	ADD.L #2, A0
.loop
	move.l A1, -(SP)
	lea player_position, A1
	bsr projectPoint
	bsr viewportToScreen
	move.l (SP)+, A1
	move.w D1, 0(A1)
	move.w D2, 2(A1)
	add.l #4, A1
	add.l #6, A0
	DBRA D7, .loop
	move.w (SP)+, player_position+4
	move.l (SP)+, A1
	rts

drawAllTriangles: ;args: A0 - model address A1 - projected points, A2 - MODEL OFFSET
	clr.l d7
	clr.l d6
	move.b 1(a0), d7 ; number of triangles
	sub.b #1, D7
	move.b 0(A0), d6 ; number of points
	asl.b #1, d6
	muls #3, d6 ;every point is three words
	add.l #2, A0
	add.l d6, A0 ; now it's the triangle starting address
.loop
	clr.l d1
	clr.l d2
	clr.l d3
	lea 0, a2
	;load p1 address
	move.b 0(A0), D1 ;load point number
	asl.w #2, D1 ; every point is 4 bytes
	add.l A1, D1
	;add point number to point origin address
	;load p2 address
	move.b 1(A0), D2
	asl.w #2, D2 ; every point is 4 bytes
	add.l A1, D2
	;load p3 address
	move.b 2(A0), D3
	asl.w #2, D3 ; every point is 4 bytes
	add.l A1, D3
	
	move.l A0, -(SP)
	move.l A1, -(SP)
	move.l d1, a0
	move.l d2, a1
	move.l d3, a2
	bsr render2DWireframeTriangle
	move.l (SP)+, A1
	move.l (SP)+, A0
	

	add #3, A0 ;let's go on to the next triangle, every triangle is 3 bytes
	DBRA D7, .loop

	rts

charToModel: ;args d0.b - map cell char ; returns: A0 - model address
	cmp.b #'#', d0
	beq .wall
	cmp.b #'@', D0
	beq .powerup
.floor
	lea floor_tile, a0
	bra .end
.powerup
    lea powerup_model, a0
    bra .end
.wall
	lea example_model, a0
	bra .end
.end
	rts
	
mapModelOffset: ; args: d1.b - x, d2.b - z, A2 - wrere to write offset to; returns A2 - offset address
	asl.w #8, d1
	asl.w #8, d2
	move.w d1, 0(A2)
	move.w d2, 4(A2)
	asr.w #8, d1
	asr.w #8, d2
	rts

getMapTile: ; args: d1.b - x, d2.b - z, A1 - the map ; returns: D0.b - map cell char
	move.l d1, -(SP)
	move.l d2, -(SP)
	move.l A1, -(SP)

	move.B #$FF, D0
	lsr.b #(8-MAP_Z_BITSHIFT), D0
	and.b D0, D2
	lsl.b #MAP_Z_BITSHIFT, D2
	and.b D0, D1
	add.b D2, D1
	and.l #$000000FF, D1
	add.l D1, A1
	move.b (A1), D0
	
	move.l (SP)+, A1
	move.l (SP)+, D2
	move.l (SP)+, D1
	rts

insertPowerup: ; inserts a flag you can pick up for xtra chlng&pts
	move.b D0, -(SP)
	move.b D1, -(SP)
	move.b D2, -(SP)
	move.b #2, D1
	move.b #3, D2
	move.b #'@', D0
	bsr setMapTile
	move.b (SP)+, D2
	move.b (SP)+, D1
	move.b (SP)+, D0
	rts

maybeInsertPowerup: ; inserts powerup if theres none and player is in front
	move.b #2, D1
	move.b #3, D2
	bsr getMapTile
	cmp.b #'@', D0
	beq .end ; no need to insert, powerup already here
	move.w player_position+4, D1
	asr.w #8, D1
	and.b #7, D1
	cmp.b #3, D1
	blt .end
	bgt insertPowerup
.end
	rts

setMapTile: ; args: d1.b - x, d2.b - z, A1 - the map ; modifies: D0.b - map cell char
	move.l d1, -(SP)
	move.l d2, -(SP)
	move.l A1, -(SP)

	move.b D0, -(SP)
	move.B #$FF, D0
	lsr.b #(8-MAP_Z_BITSHIFT), D0
	and.b D0, D2
	lsl.b #MAP_Z_BITSHIFT, D2
	and.b D0, D1
	add.b D2, D1
	and.l #$000000FF, D1
	add.l D1, A1
	move.b (SP)+, (A1)
	
	move.l (SP)+, A1
	move.l (SP)+, D2
	move.l (SP)+, D1
	rts



drawMap: ;args: A1 - the map
	;init
	clr.l D1
	clr.l D2

	move.w player_position+4, D2
	add.w #$800, D2
	asr.w #8, d2
	move.l D1, -(SP)
	move.l #$00404020, D1
	bsr setPenColor
	move.l (SP)+, D1
	move.b #64, .blue_brightness
	
.loop
	;if z < player.z, goto end (stupid FOV for the time being)
	lea player_position, A6
	move.w 4(A6), D7
	sub.w 256, d7
	asr.w #8, D7 ;round player z to an integer
	;sub.b #1, D7
	cmp.b D2, D7 ;if the cell z is less or equal to players z
	bge .continue
	;retrieve tile
	bsr getMapTIle 
	;draw model
	bsr charToModel
	move.l A0, A6
	lea $9000, A2 ; model offset for now
	bsr mapModelOffset
	move.l A1, -(SP) ; push map
	move.b d1, -(SP)
	move.b d2, -(SP)
	lea $9100, A1 ; model vertices for now
	move.l A0, -(SP)
	move.l A6, A0
	bsr projectAllModelVertices
	lea $9100, A1
	move.l (SP)+, A0
	move.l A6, A0
	bsr drawAllTriangles
	move.b (SP)+, D2
	move.b (SP)+, D1
	move.l (SP)+, A1 ; pop map
	;update coords
.continue
	add.b #1, d1
	cmp.b #(MAP_SIDE-1), D1
	
	ble .loop

	
	move.b #0, D1 ; x goes to 0 again
	sub.b #1, D2 ; z decreases
	;make color brighter
	move.l D1, -(SP)
	move.b #0, D1 ;zero
	lsl.l #8, D1
	add.b #24, .blue_brightness
	move.b .blue_brightness, D1 ;blue
	lsl.l #8, D1
	move.b .blue_brightness, D1 ;green
	lsl.l #8, D1
	move.b #$20, D1 ;red
	bsr setPenColor
	move.l (SP)+, D1
	cmp.b D7, D2 ; are we on last row?
	blt .end ; if we finished the last row we end
	
	;goto loop
	bra .loop
.end
	rts
.blue_brightness dc.b 64
AAA_SHIT: dc.b 0
    
; constants
example_triangle:
	dc.w 5, 5
	dc.w 120, 5
	dc.w 5, 60
example_model:
num_vertices dc.b 5
num_triangles: dc.b 6
pyramid_vertices:
    dc.w -128, 0, -128
    dc.w -128, 0, 128
    dc.w 128, 0, -128
    dc.w 128, 0, 128
    dc.w 0, $180, 0
pyramid_triangles:
    dc.b 0, 1, 2
    dc.b 2, 3, 1
    dc.b 0, 4, 1
    dc.b 1,4,3
    dc.b 2,4, 3
    dc.b 2, 4, 0
    
floor_tile:
	dc.b 4 ;v
	dc.b 4 ;t
	dc.w -127, 0, 127 ; vertices
	dc.w 127, 0, 127
	dc.w 127, 0, -127
	dc.w -127, 0, -127
	dc.b 0, 1, 1 ; triangles
	dc.b 1, 2, 2
	dc.b 2, 3, 3
	dc.b 3, 0, 0

paperplane_model:
    dc.b 5
    dc.b 3
    dc.w 0, 128, 128
    dc.w -8, 128, -32
    dc.w -128, 128, -128
    dc.w 128, 128, -128
    dc.w -8, 96, -32 
    dc.b 0, 1, 2
    dc.b 0, 1, 3
    dc.b 0, 1, 4
    
    dc.b $ff ;  word padding garbage
	
powerup_model:
    dc.b 4 ; four points
    dc.b 2 ; 2 "triangles"
    dc.w 0, 0, 0
    dc.w 0, 64, 0
    dc.w 0, 96, 0
    dc.w 32, 80, 0
    dc.b 1,2,3
    dc.b 0, 1, 1

example_map:
	dc.b '#...####'
	dc.b '#......#'
	dc.b '#......#'
	dc.b '#.@....#'
	dc.b '####...#'
	dc.b '#......#'
	dc.b '#......#'
	dc.b '#......#'
    
player_position dc.w 0,$100,0

EXAMPLE_POINT_OFFSET DC.W 0, 0, 3<<8
    
SCREEN_WIDTH EQU 640>>7
SCREEN_HEIGHT EQU 480>>5
SCREEN_VCENTER EQU (SCREEN_HEIGHT<<5)/2
SCREEN_HCENTER EQU (SCREEN_WIDTH<<7)/2
MAP_Z_BITSHIFT EQU 3
MAP_SIDE EQU 8

SIN_60 EQU 222 ; in fixed-point rep with <<8, render plane distance from "eye"
    END    START        ; last line of source
























*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
