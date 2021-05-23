%TITLE "File Operations"
; -- Written by Fritz Feuerbacher

        IDEAL
        DOSSEG
        MODEL   small

greenbg         EQU     32      ; these are my screen attributes
redbg           EQU     64
blinkatr        EQU     128
bluebg          EQU     16
intensity       EQU     8
redfg           EQU     4
greenfg         EQU     2
bluefg          EQU     1

      DATASEG	
  
mymodel		db 20000 DUP (32); create a 10 page model	
handle          dw      ?       ; file handle
filename        db  80 dup (?)  ; asciiz filename
buffer          db  3840 dup (1)  ; buffer for file reads
msg_000         db      "Esc - to Quit ||   Enter Filename: ",0 
msg_001         db      "      ERROR - Could not open file   -= Press any key to continue =-",0
msg_004         db      "Esc - Quit || F1 - Save || F2 - Load || F3 - Clear Screen",0
vbase           dw      ?       ; video starting location for color

      CODESEG

;-----  From KEYBOARD.OBJ  (From the text "Mastering Turbo Assembler")
	EXTRN   Keywaiting:proc, Getch:proc
        EXTRN   StatusBar : proc

       PUBLIC  FileEnterMessage, FileErrorMessage
       PUBLIC  LoadFile, SaveFile


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
	add	di, 2
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
	mov	[mymodel + bx], 32
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
	mov     di, bx			; set di to 0 (top of video page)
	mov     cx, 1920		; set loop for 1920
@@PutScreen:
 	mov     al, [mymodel + bx]	; move buffer byte into al
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
	cmp	al, 27			; check for escape key
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


        END                     ; End of module
