%TITLE "Text Editor"
; -- Written by Fritz Feuerbacher

		IDEAL
		DOSSEG
		MODEL   small
		STACK   256


;--  EQUATE SECTION

greenbg         EQU     32      ; these are background attributes
redbg           EQU     64      ; 
blinkatr        EQU     128	; 
bluebg          EQU     16	; 
intensity       EQU     8	; 
redfg           EQU     4	; these are foreground attributes
greenfg         EQU     2	; 
bluefg          EQU     1	; 

	DATASEG

mymodel		db 20000 DUP (32); create a 10 page model	
beginpage	dw	0
index		dw	0
vbase           dw      ?       ; video starting location for color
attrib          db      ?       ; used to manipulate the attribute
Row             dw      0	; keeps track of what row your on
Column          dw      0	; keeps track of what column your on
cursor          db      greenbg OR bluebg OR redbg ; defines the cursor
multiplier      dw      2	; used for various screen calculations
multrow		dw	160	; used for screen calculations
instog          dw      1	; variable used for toggling insert
insBool         dw	1	; boolean to tell if INS is on or off?
inson           db      "INS",0 ; INS indicator for display on status bar
insoff		db	"   ",0 ; INS space to clear status bar indicator
handle          dw      ?       ; file handle
filename        db  20 dup (?)  ; asciiz filename
msg_000         db      "Esc - to Quit ||   Enter Filename: ",0 
msg_001         db      "      ERROR - Could not open file   -= Press any key to continue =-",0
msg_004         db      "Esc - Quit || F1 - Save || F2 - Load || F3 - Clear Screen",0

	  CODESEG

;-----  From MYLIB.OBJ  (my personal library from modifications)
	EXTRN   Clear_Screen : proc     
	EXTRN   Clear_Screen2 : proc     
	EXTRN   PrintASCII : proc
	EXTRN	CursorOff : proc
	EXTRN	CursorOn : proc
	EXTRN   StatusBar : proc
	
;-----  From BINASC.OBJ  (From the text "Mastering Turbo Assembler")
	EXTRN   BinToAscDec : proc
	EXTRN   SBinToAscDec : proc
	EXTRN   BinToAscBin : proc
	
;-----  From STRIO.OBJ   (From the text "Mastering Turbo Assembler")
	EXTRN   StrWrite:proc, NewLine:proc

;-----  From KEYBOARD.OBJ  (From the text "Mastering Turbo Assembler")
	EXTRN   Keywaiting:proc, Getch:proc

PROC FileEnterMessage
	push	ax
	push	bx
	push	cx
	mov     di, 3840         ; move beginning of status line into di
	mov     cx, 160          ; move length of status line into cx
	mov     ah, bluebg OR redbg OR intensity ; set status line color
	mov     al, 32           ; make status line reverse blanks
@@Status_Line:
	stosw
	loop    @@Status_Line    ; draw the status line
	mov     di, 3840         ; put beginning of status line in di again
	mov     cx, 34           ; set length of message
	mov     bx, 0            ; initialize counter
	mov     ah, bluebg OR redbg OR intensity OR greenfg OR redfg
@@DoMessage:                 ; write the assignment number in status bar
	mov     al, [msg_000 + bx] ; actually write the message on the
	stosw
	inc     bx                 ; the status bar
	loop    @@DoMessage
	add	di, 2
	pop	cx
	pop	bx
	pop	ax
	ret
ENDP FileEnterMessage

PROC FileErrorMessage
	push	ax
	push	bx
	push	cx
	mov     di, 3840         ; move beginning of status line into di
	mov     cx, 160          ; move length of status line into cx
	mov     ah, bluebg OR redbg OR intensity ; set status line color
	mov     al, 32           ; make status line reverse blanks
@@Status_Line:
	stosw
	loop    @@Status_Line    ; draw the status line
	mov     di, 3840         ; put beginning of status line in di again
	mov     cx, 67           ; set length of message
	mov     bx, 0            ; initialize counter
	mov     ah, bluebg OR redbg OR intensity OR greenfg OR redfg
@@DoMessage:                 ; write the assignment number in status bar
	mov     al, [msg_001 + bx] ; actually write the message on the
	stosw
	inc     bx                 ; the status bar
	loop    @@DoMessage
	pop	cx
	pop	bx
	pop	ax
	ret
ENDP FileErrorMessage

;-- This function loads a screen page from a file --------------------------
PROC LoadFile

	push    di		; save all working registers and flags
	push    ax
	push    bx
	push    cx
	push    dx
	pushf
	call   FileEnterMessage	
	mov     bx, 0
@@Repeat:
	call    GetCh                   ; Read keypress
	jnz     @@Read                  ; Jump if key is a character
	cmp     al, 13			; is character the return key?
	je      @@Loadit		; if so, filename is read
	cmp	al, 27			; else, is character the esc key?
	je	@@Exit			; if so quit operation
	cmp	al, 8			; is character the bs key?
	jne	@@Repeat		; if not ignore the key pressed
	sub	di, 2			; else perform bs operation
	mov     ah, bluebg OR redbg OR intensity OR redfg
        mov	al, 32			; write a space and back up one
        stosw
        sub	di, 2
	dec	bx			; decrement the actual filename
	jmp	@@Repeat		; get next key
@@Exit:
	jmp	@@ExitFile
@@Read:
	mov     [filename + bx], al	; put character into the filename byte
	inc     bx			; increment filename offset pointer
	mov     ah, bluebg OR redbg OR intensity OR redfg OR bluefg OR greenfg
	stosw				; write the charactered keyed
	jmp     @@Repeat		; get next keyed character
@@Loadit:
	mov     [filename + bx], 0h	; make filename end in asciiZ
	mov	cx, 20000
	mov	bx, 0
@@Init:
	mov	[BYTE mymodel + bx], 32
	inc	bx
	loop	@@Init
	clc				; clear the carry flag
	lea     dx, [filename]       	; put filename offset into dx
	mov     ah, 03Dh           	; try to open file first
	mov     al, 02			; set to normal file use
	int     21h			; call dos bios function
	jnc     @@lbl1			; if successful goto write function
	call	FileErrorMessage
	call	GetCh
	jmp     @@ExitFile		; don't erase error message
@@lbl1:
	mov     [handle], ax       	; save file handle
	mov     bx, [handle]		; move file handle into bx
	mov     cx, 20000		; request to read 20k bytes
	mov     dx, offset mymodel	; tell where to put those bytes
	mov     ah, 03Fh		; load interupt
	int     21h			; call dos
	mov     ah, 03Eh		; load close file interupt
	int     21h			; call dos
	mov     bx, 0			; set up an offset counter
	mov     di, 0			; set di to 0 (top of video page)
	mov     cx, 1920		; set loop for 1920
@@PutScreen:
 	mov     al, [BYTE mymodel + bx]	; move buffer byte into al
	mov     ah, greenfg		; set ah to text color
	stosw				; store character on screen
	inc     bx			; increment offset counter by 2
	loop    @@PutScreen		; keep doing it for the whole screen
@@ExitFile:
	call	StatusBar
	popf	
	pop     dx
	pop     cx
	pop     bx
	pop     ax
	pop     di
	ret
ENDP LoadFile

;--- This function saves a screen page to a file ----------------------------
PROC SaveFile

	push    di		; save all working registers and flags
	push    ax
	push    bx
	push    cx
	push    dx
	pushf
	mov     di, 3916	; set di to display filename prompt
	mov     cx, 32		; set cx to length of filename prompt
	mov     ah, bluebg OR redbg OR intensity OR redfg
	mov     bx, 0
	call	FileEnterMessage
	add	di, 2
	mov     bx, 0
@@Repeat:
	call    GetCh                   ; Read keypress
	jnz     @@Read                  ; Jump if key is a character
	cmp     al, 13			; if return key was pressed filename
	je      @@Loadit		; was entered
	cmp	al, 27  		; check for escape key
	je	@@Exit			; if escape was entered then quit
	cmp	al, 8			; check for bs key
	jne	@@Repeat		; if character was not bs then get
	sub	di, 2			; next key pressed, else perform bs
	mov     ah, bluebg OR redbg OR intensity OR redfg
        mov	al, 32			; clear last character pressed
        stosw				
        sub	di, 2			; and backup di
	dec	bx			; and decrement the actual filename
	jmp	@@Repeat		; get next key entry
@@Exit:
	jmp	@@ExitFile
@@Read:
	mov     [filename + bx], al	; get filename
	inc     bx
	mov     ah, bluebg OR redbg OR intensity OR redfg OR bluefg OR greenfg
	stosw
	jmp     @@Repeat
@@Loadit:			; this is essentially identical to loadfile
        clc
        mov     [filename + bx], 0h
	lea     dx, [filename]
	mov     ah, 03Dh           ; try to open file
	mov     al, 02
	int     21h
	jnc     @@lbl1
	clc
	lea     dx, [filename]       
	mov     cx, 0
	mov     ah, 03Ch           ; try to create file
	int     21h
	jnc     @@lbl1
@@RunError:
	call	FileErrorMessage
	call	GetCh
	jmp     @@ExitFile
@@lbl1:
	clc
        mov     [handle], ax       ; save file handle
	mov	bx, [handle]
	mov     cx, 20000
	lea     dx, [mymodel]
	mov     ah, 040h
	int     21h
	mov     ah, 3Eh
	int     21h
	jnc	@@ExitFile
	mov     di, 3916
	mov     cx, 32
	mov     ah, bluebg OR redbg OR intensity OR redfg
	mov     bx, 0
        jmp	@@RunError
@@ExitFile:
	call	StatusBar
	popf
	pop     dx
	pop     cx
	pop     bx
	pop     ax
	pop     di
	ret
ENDP SaveFile

;--- This writes the row and column indicator on the status bar ---------
PROC SetRowColumn
 
	push    di			; save working registers
	push    ax
	push	bx
	push    cx
	mov	bx, di
	mov     ax, [Row]		; get current row position
	mov     cx, 3			; set loop counter
	mov     di, 3980		; set screen position to write to
	call    PrintASCII		; write binary number as ascii
	mov     di, 3986		; set screen position
	mov     al, ":"			; set divider character
	stosw				; write divider character
	mov     ax, [Column]		; get current column position
	mov     cx, 2			; set loop counter
	call    PrintASCII		; write binary number as ascii
	mov	di, bx
	mov	al, [BYTE es:di]
	mov	ah, [cursor]
	stosw
	pop     cx			; restore working registers
	pop	bx
	pop     ax
	pop     di
	ret
ENDP SetRowColumn

;--- This writes the INS indicator on the status bar ----------------------
PROC SetINSTog

	push    di			; save working registers
	push    ax
	push    cx
	mov     cx, 3			; set loop counter
	mov     di, 3994		; set write position on screen
	mov	bx, 0			; set bx as a counter
        mov	ah, bluebg OR redbg OR intensity OR redfg OR greenfg ; color
@@Writeinsoff:
        mov	al, [insoff + bx]	; first wipe INS indicator off screen
        stosw
	inc	bx
        loop	@@Writeinsoff
	cmp	[instog], 0		; quit if insert is turned off
	je	@@Over
	mov     cx, 3			; if insert is on, set up loop
	mov     di, 3994		; to write INS on status bar
	mov	bx, 0			; set bx to counter
        mov	ah, bluebg OR intensity OR redfg OR greenfg
@@Writeinson:
        mov	al, [inson + bx]	; write the INS indicator text
        stosw
	inc	bx
        loop	@@Writeinson
@@Over:
	pop     cx			; restore working registers
	pop     ax
	pop     di
	ret
ENDP SetINSTog

;-- Used to redraw the screen ------------------------------------------
PROC DrawScreen
	push	di
	push	ax
	push	bx
	push	cx
	
	call	Clear_Screen2
	mov	di, 0
	mov	cx, 1920
	mov	bx, [beginpage]
	mov	ah, greenfg
@@Loopit:
	mov	al, [mymodel + bx]
	inc	bx
	stosw
	loop	@@Loopit
	pop	cx
	pop	bx
	pop	ax
	pop	di
	ret
 ENDP DrawScreen

;-- This performs a left arrow key function -------------------------------
PROC DoLeftArrow

	cmp     [Column], 0			; Is cursor at 0,0 on screen?
	je      @@Endofla		; if so quit, can't go left
	mov     ax, [es:di]		; else, get current character
	mov     ah, greenfg    		; set text color
	stosw				; write current character
	sub     di, 4			; was before current character
	mov     ax, [es:di]		; actually get the character
	mov     ah, [cursor]   		; set color to cusor type
	stosw				; write previous character
	sub     di, 2			; character previous to the current
	dec	[index]
	dec	[Column]
@@Endofla:        
	 ret
ENDP DoLeftArrow

;-- This doe the right arrow key function ---------------------------------
PROC DoRightArrow

	cmp     [Column], 79		; see if di is at end of page
	je      @@Endofla		; if so, can't go any further right
	mov     ax, [es:di]		; else get current character
	mov     ah, greenfg    		; set text color
	stosw				; write current character in the
	mov     ax, [es:di]		; text color and then get next
	mov     ah, [cursor]   		; character and set cusor color.
	stosw				; write the next character
	sub     di, 2
	inc	[index]
	inc     [Column]		; if not then increment column
@@Endofla:        
	 ret
ENDP DoRightArrow

;-- This does the up arrow key function -------------------------------------
PROC DoUpArrow

	cmp     [Row], 0		; if row is zero don't go up
	je      @@Endofla
	cmp	di, 160
	jl	@@Advancepage
	mov     ax, [es:di]		; write current char to the screen
	mov     ah, greenfg    
	stosw
	sub     di, 162			; calculate new di position
	mov     ax, [es:di]		; get new character at new di
	mov     ah, [cursor]   		; set cursor color
	stosw				; write new character at new position
	sub     di, 2
	sub     [Row], 1		; decrement a row
	sub	[index], 80
	jmp	@@Endofla
@@Advancepage:
	sub	[beginpage], 80
	call	DrawScreen
	sub     [Row], 1		; decrement a row
	sub	[index], 80
@@Endofla:        
	 ret
ENDP DoUpArrow

;-- This does the down arrow key function ----------------------------------
PROC DoDownArrow

	cmp     [Row], 249        	; check if last row, if so can't
	je      @@Endofla		; go down any further
	cmp	di, 3680
	jge	@@AdvancePage
	mov     ax, [es:di]		
	mov     ah, greenfg    		; write current character in text
	stosw				; color
	add     di, 158			; calculate new di postion
	mov     ax, [es:di]		; get new di position character
	mov     ah, [cursor]   		; set cursor color
	stosw				; write new character at new location
	sub     di, 2
	add     [Row], 1		; increment a row
	add	[index], 80
	jmp	@@Endofla
@@AdvancePage:
	add	[beginpage], 80
	call	DrawScreen
	add     [Row], 1		; increment a row
	add	[index], 80
@@Endofla:        
	 ret
ENDP DoDownArrow

;-- This does the home key function ----------------------------------------
PROC DoHomeKey

	cmp     [Column], 0
	je      @@Endofla
	mov     ax, [es:di]
	mov     ah, greenfg    
	stosw
	mov     ax, [Column]
	mul     [multiplier]
	sub     di, ax
	sub     di, 2
	mov     ax, [es:di]
	mov     ah, [cursor]   
	stosw
	sub     di, 2
	mov	ax, [index]
	sub	ax, [Column]
	mov	[index], ax
	mov     [Column], 0
@@Endofla:        
	 ret
ENDP DoHomeKey

;-- This does the end key function ------------------------------------------
PROC DoEndKey

	cmp     [Column], 79
	je      @@Endofla
	mov     ax, [es:di]
	mov     ah, greenfg    
	stosw
	mov     ax, 79
	sub     ax, [Column]
	add     [Column], ax
	add	[index], ax
	mul     [multiplier]
	add     di, ax
	sub	di, 2
	mov     ax, [es:di]
	mov     ah, [cursor]   
	stosw
	sub     di, 2
@@Endofla:        
	 ret
ENDP DoEndKey

;-- This the the return key function ---------------------------------------
PROC DoReturnKey

	cmp     [Row], 249
	je      @@Endofla
	mov     ax, [es:di]
	mov     ah, greenfg    
	stosw
	mov     ax, 80
	sub     ax, [Column]
	add	[index], ax
	mov     ax, [Column]
	mul     [multiplier]
	sub     di, ax
	add     di, 158
	mov     ax, [es:di]
	mov     ah, [cursor]   
	stosw
	sub     di, 2
	mov     [Column], 0
	add     [Row], 1        
@@Endofla:
	ret
ENDP DoReturnKey

PROC DoPgDwn

	cmp     [Row], 249
	je      @@Endofla
	mov	cx, 25
@@GoDown:
	call	DoDownArrow	
	loop	@@GoDown
	@@Endofla:
	ret
ENDP DoPgDwn

PROC DoPgUp

	cmp     [Row], 0
	je      @@Endofla
	mov	cx, 25
@@GoUpMySon:
	call	DoUpArrow
	loop	@@GoUpMySon
@@Endofla:
	ret
ENDP DoPgUp

;-- This does the back space key function ----------------------------------
PROC DoBSKey

	cmp     [Column], 0
	je      @@Endofla
	mov     cx, 80
	sub     cx, [Column]
	mov     ax, [es:di]
	mov     ah, [cursor]   
	sub     di, 2
	push	di
	stosw
	dec     [Column]
        mov	bx, [index]
	sub	bx, 1
@@Backit:        
	mov     ax, [es:di+2]
	mov     ah, greenfg    
	stosw
	mov	al, [mymodel + bx + 1]
	mov	[mymodel + bx], al
	inc	bx 
	loop    @@Backit
	mov	[mymodel + bx], 32
	dec	[index]
	sub	di, 2
	mov	al, 32
	stosw
	pop	di
@@Endofla:        
	ret
ENDP DoBSKey

;-- This does the delete key function ---------------------------------------
PROC DoDELKey

	push	di
	cmp     [Column], 79
	je      @@Endofla
	mov     cx, 80
	sub     cx, [Column]
	mov     ax, [es:di+2]
	mov     ah, [cursor]   
        mov	bx, [index]
	mov	al, [mymodel + bx + 1]
	mov	[mymodel + bx], al
	inc	bx 
	stosw
        sub	cx, 1
@@Backit:        
	mov     ax, [es:di+2]
	mov     ah, greenfg    
	stosw
	mov	al, [mymodel + bx + 1]
	mov	[mymodel + bx], al
	inc	bx 
	loop    @@Backit
	mov	[mymodel + bx], 32
	sub	di, 2
	mov	al, 32
	stosw
	
@@Endofla:        
	 pop	di
	 ret

ENDP DoDELKey

PROC DoTabKey

	cmp     [Row], 23		; see if di is at end of page
	jne     @@Tabit 		; if so, can't go any further right
	cmp	[Column], 74
	jge	@@Endofla
@@Tabit:
	cmp	[Column], 74
	jge	@@Endofla
	mov     ax, [es:di]		; else get current character
	mov     ah, greenfg    		; set text color
	stosw				; write current character in the
	add	di, 8
	mov     ax, [es:di]		; text color and then get next
	mov     ah, [cursor]   		; character and set cusor color.
	stosw				; write the next character
	mov     dx, di			; set di back to next character
	sub     dx, 2
	mov     di, dx
	cmp     [Row], 23		; check if your on the last row
	je      @@CheckColumn		; if so see if colomn can be incremented
	cmp     [Column], 74		; if not on last row then see if your
	jge     @@IncRow        	; on the last column of current row
	add     [Column], 5		; if not then increment column
	add	[index], 5
	jmp     @@Endofla		; leave here
@@IncRow:				; if row isn't 23 and column is 79 then
	inc     [Row]			; you must increment the row
	mov     [Column], 0        	; and set column to new position
	jmp     @@Endofla
@@CheckColumn:				; if row is last then just check
	cmp     [Column], 74		; the column
	jge     @@Endofla		; if column is last one then don't inc
	add     [Column], 5		; else increment column
	add	[index], 5
@@Endofla:        
	 ret
ENDP DoTabKey

PROC ClearIt

call	Clear_Screen2
	mov	bx, 0
	mov	cx, 20000
@@ClearBuf:
	mov	[BYTE mymodel + bx], 32
	inc	bx
	loop	@@ClearBuf
	mov	di, 0
	mov	[Row], 0
	mov	[Column], 0
	mov	al, 32
	mov     ah, [cursor]   
	stosw
	mov     di, 0
	mov	[index], 0
	mov	[beginpage], 0
	ret
ENDP ClearIt	


;------------ Main Program Body -------------------------------------------

Start:
	mov     ax, @data        ; Initialize ds to address
	mov     ds, ax           ; of data segment. blah,blah,blah
	
	call    Clear_Screen
	call	CursorOff
	mov     [vbase], 0B800h  ; setting up video segment reference
	mov     es, [vbase]

;-- Preliminary recursiveness ----------------------------------------------

	mov     di, 0
	mov	al, 32
	mov     ah, [cursor]   
	stosw
	mov     di, 0
	call	StatusBar
Repeat:
	call    SetRowColumn            ; update Row and Column indicator
	call	SetINSTog
	call    KeyWaiting              ; Wait for any keypress
	jz      Repeat                  ; Repeat until key waiting
	call    GetCh                   ; Read keypress
	jnz     @@12A                   ; Jump if key is a character
	cmp     al, 27                  ; Was Escape key pressed?
	je      @@MainOut               ; If yes, jump to exit

	cmp     al, 93			; check for F3 key
	jne     @@1D
	call	ClearIt
	jmp     Repeat
@@1D:
	cmp     al, 105			; check for page up
	jne     @@1C
	call	DoPgUp
	jmp     Repeat
@@1C:
	cmp     al, 113			; check for page down
	jne     @@1B
	call	DoPgDwn
	jmp     Repeat
@@1B:
	cmp     al, 9			; check for tab key
	jne     @@1A
	call	DoTabKey
	jmp     Repeat
@@12A:
	jmp     @@13
@@1A:
	cmp     al, 114			; check for insert key
	jne     @@1
	mov	bx, [insBool]
	cmp	bx, [instog]
	jne	@@ChangeToOn
	mov	[instog], 0
	jmp	Repeat
    @@ChangeToOn:
	mov	[instog], 1
	jmp     Repeat
	
@@1:
	cmp     al, 115			; check for delete key
	jne     @@3
	call    DoDELKey
	cld
	jmp     Repeat

@@MainOut:
	jmp     MainExit

@@3:
	cmp     al, 91			; check for F1 key
	jne     @@4
	call    SaveFile
	jmp     Repeat
@@4:
	cmp     al, 8			; check for back space key
	jne     @@5
	call    DoBSKey
	cld
	jmp     Repeat

@@5:
	cmp     al, 13			; check for return key
	jne     @@6
	call    DoReturnKey
	jmp     Repeat

@@6:    cmp     al, 111			; check for end key
	jne     @@7
	call    DoEndKey
	jmp     Repeat
@@7:
	cmp     al, 103			; check for home key
	jne     @@8
	call    DoHomeKey
	jmp     Repeat
@@8:    
	cmp     al, 92			; check for F2 key
	jne     @@9
	call    LoadFile
	jmp     Repeat
@@9:
	cmp     al, 68h                 ; check for up arrow key
	jne     @@10
	call    DoUpArrow
	jmp     Repeat
@@10:
	cmp     al, 112			; check for down arrow key
	jne     @@11
	call    DoDownArrow
	jmp     Repeat
@@11:       
	cmp     al, 6Bh                 ; check for left arrow key
	jne     @@12
	call    DoLeftArrow
	jmp     Repeat
@@12:
	cmp     al, 109         	; check forright arrow key
	jne     @@13
	call    DoRightArrow
	jmp     Repeat
@@13:
	cmp	[instog], 1
	jne	@@InsertOff
	jmp	@@InsertOn
@@InsertOff:	
	cmp     di, 3836
	jle     @@Noadvance
	cmp	[index], 19999
	je	@@inm
	mov	bx, [index]
	mov	[mymodel + bx], al
	mov	ah, greenfg
	stosw
	inc	[index]
	add	[beginpage], 80
	call	DrawScreen
	sub	di, 160
	mov     ax, [es:di]
	mov     ah, [cursor]
	stosw
	sub     di, 2
	jmp	@@Dontinc
@@Noadvance:
	cmp	[index], 19999
	je	@@inm
	mov     ah, greenfg   		; set text color
	mov	bx, [index]
	mov	[mymodel + bx], al
	stosw 
	inc	[index]
	mov     ax, [es:di]
	mov     ah, [cursor]
	stosw
	sub     di, 2
@@Dontinc:
	inc	[Column]
	cmp     [Column], 80
	jne     @@inm
	cmp     [Row], 249
	je      @@inm
	inc     [Row]
	mov     [Column], 0
@@inm:
	jmp	Repeat
;-- If the insert key is on then this gets done -----------------------------
@@InsertOn:
	cmp	di, 3836
        jle	@@NoPageAdvance
	cmp	[index], 19999
	je	@@inm
	add	[beginpage], 80
	call	DrawScreen
	sub	di, 160
@@NoPageAdvance:
 	push	ax
 	push	di
        cmp	[Column], 79
        je	@@Noneed
        mov	ax, 79
        sub	ax, [Column]
        mov	cx, ax
        mov	bx, [index]
	add	bx, ax
        mul	[multiplier]
        add	di, ax
        mov     ah, greenfg   ; set text color
@@Incthem:	
	mov	al, [es:di-2]
        std
	stosw 
	mov	[mymodel + bx], al
	dec	bx 
	loop	@@Incthem
	cld
@@Noneed:	
	pop	di
	pop	ax
	mov	bx, [index]
	mov	[mymodel + bx], al
	inc	[index]
	mov	ah, greenfg
	stosw
	mov	al, [es:di]
	mov	ah, [cursor]
	stosw
        sub	di, 2
@@Checking:
        inc	[Column]
	cmp     [Column], 80
	jne     @@NoNewRow
	inc     [Row]
	mov     [Column], 0
@@NoNewRow:
	jmp     Repeat                  ; Get next keypress

MainExit:
	call    Clear_Screen
	call	CursorOn

Exit:
	mov     ah,04Ch         ;DOS function: Exit program
	mov     al,0            ;Return exit-code value
	int     21h             ;Call DOS. Terminate program
	
	END     Start           ;End of program / entry point
