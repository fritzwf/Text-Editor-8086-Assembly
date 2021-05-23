%TITLE "Utils Library"
; -- Written by Fritz Feuerbacher

        IDEAL
        DOSSEG
        MODEL   small

greenbg         EQU     32      ; these are screen color attributes
redbg           EQU     64
blinkatr        EQU     128
bluebg          EQU     16
intensity       EQU     8
redfg           EQU     4
greenfg         EQU     2
bluefg          EQU     1

      DATASEG	
vbase           dw      ?       ; video starting location for color
msg_004         db      "Esc - Quit || F1 - Save || F2 - Load || F3 - Clear Screen",0

      CODESEG

      PUBLIC  Clear_Screen, Clear_Screen2, PrintASCII, CursorOff, CursorOn
      PUBLIC  StatusBar

;--- create status bar -----------------------------------------------------
PROC StatusBar
	push	di
	push	ax
	push	bx
	push	cx
	push	dx
	mov     di, 3840         ; move beginning of status line into di
	mov     cx, 160          ; move length of status line into cx
	mov     ah, bluebg OR redbg OR intensity ; set status line color
	mov     al, 32           ; make status line reverse blanks
@@Status_Line:
	stosw
	loop    @@Status_Line    ; draw the status line
	mov     di, 3840         ; put beginning of status line in di again
	mov     al, [msg_004]    ; set up message location
	mov     cx, 57           ; set length of message
	mov     bx, 1            ; initialize counter
	mov     ah, bluebg OR redbg OR intensity OR bluefg OR greenfg
AssignMentNum:                   ; write the assignment number in status bar
	stosw
	mov     al, [msg_004 + bx] ; actually write the message on the
	inc     bx                 ; the status bar
	loop    AssignMentNum
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	di
	ret
ENDP StatusBar

;------------------------------------------------------------------------------
PROC    Clear_Screen
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; PURPOSE:      clear the screen
;
; INPUTS:       NONE
;
; 
;OUTPUTS:      NONE
;
; MODIFIED:     NONE
;------------------------------------------------------------------------------
	push    ax                      ; save working registers & flags
	push    cx                      ;  "
	push    dx                      ;  "
	pushf                           ;  "
	mov     [vbase], 0B800h         ; setting up video segment reference
	mov     es, [vbase]
	push    di
	cld
	mov     di, 0
	mov     cx, 2000
	mov     al, 32
	mov     ah, 0

@@Clearing:        
	stosw
	loop    @@Clearing
	
	pop     di
	popf                            ; restore working registers & flags
	pop     dx                      ;  "
	pop     cx                      ;  "
	pop     ax                      ;  "
	ret                             ; return to caller
ENDP    Clear_Screen

;------------------------------------------------------------------------------
PROC    Clear_Screen2
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; PURPOSE:      clear the screen
;
; INPUTS:       NONE
;
; 
;OUTPUTS:      NONE
;
; MODIFIED:     NONE
;------------------------------------------------------------------------------
	push    ax                      ; save working registers & flags
	push    cx                      ;  "
	push    dx                      ;  "
	pushf                           ;  "
	cld
	mov     di, 0
	mov     cx, 1920
	mov     al, 32
	mov     ah, 0
@@Clearing:        
	stosw
	loop    @@Clearing
	popf                            ; restore working registers & flags
	pop     dx                      ;  "
	pop     cx                      ;  "
	pop     ax                      ;  "
	ret                             ; return to caller
ENDP    Clear_Screen2

;---------------------------------------------------------------
; HexDigit      Convert 4-bit value to ASCII digit
;---------------------------------------------------------------
; Input:
;       dl = value limited to range 0..15
; Output:
;       dl = ASCII hex digit equivalent
; Registers:
;       dl
;---------------------------------------------------------------
PROC    HexDigit
        cmp     dl, 10          ; Is dl < 10 (i.e. hex 'A')?
        jb      @@10            ; If yes, jump
        add     dl, 'A'-10      ; Else convert to A, B, C, D, E, or F
        ret                     ; Return to caller
@@10:
        or      dl, '0'         ; Convert digits 0 to 9
        ret                     ; Return to caller
ENDP    HexDigit

;---------------------------------------------------------------
; NumToAscii    Convert unsigned binary value to ASCII
;---------------------------------------------------------------
; Input:
;       ax = 16-bit value to convert
;       bx = base for result (2=binary;10=decimal;16=hex)
;       cx = minimum number of digits to output
;       di = address of string to hold result
;       Note: assumes string is large enough to hold result
;       Note: creates full result if cx is less than the number
;             of digits required to specify the result or cx = 0
;       Note: if cx=0 and ax=0 then length of string will be 0
;             set cx=1 if you want string to = '0' if ax=0
;       Note: assumes (2<=bx<=16)
; Output:
;       none
; Registers:
;       ax, cx
;---------------------------------------------------------------
PROC    NumToAscii              ; Normal entry point
        push    dx              ; Save some modified registers
        push    di
        push    si

; si = count of digits on stack

        xor     si, si          ; Set digit-count to zero
        jcxz    @@20            ; If cx=0, jump to set cx=1
@@10:
        xor     dx, dx          ; Extend ax to 32-bit dxax
        div     bx              ; ax<-axdx div bx; dx<-remainder
        call    HexDigit        ; Convert dl to ASCII digit
        push    dx              ; Save digit on stack
        inc     si              ; Count digits on stack
        loop    @@10            ; Loop on minimum digit count
@@20:
        inc     cx              ; Set cx = 1 in case not done
        or      ax, ax          ; Is ax = 0? (all digits done)
        jnz     @@10            ; If ax <> 0, continue conversion
        mov     cx, si          ; Set cx to stack char count
        jcxz    @@40            ; Skip next loop if cx=0000
        cld                     ; Auto-increment di for stosb
@@30:
        pop     ax              ; Pop next digit into al
        mov	ah, bluebg OR redbg OR intensity OR redfg OR greenfg
	cld
	stosw
        loop    @@30            ; Loop for cx digits
@@40:
        mov     [byte di], 0    ; Store null at end of string
        pop     si              ; Restore saved registers
        pop     di
        pop     dx

        ret                     ; Return to caller
ENDP    NumToAscii

;---------------------------------------------------------------
; PrintASCII   Convert binary values to ASCII decimal strings
;---------------------------------------------------------------
; Input:
;       Same as BinToAscHex
; Output:
;       none
; Registers:
;       ax, cx (indirectly)
;---------------------------------------------------------------
PROC    PrintASCII
        push    bx              ; Save bx on stack
        mov     bx, 10          ; Set base = 10 (decimal)
        call    NumToAscii      ; Convert ax to ASCII
        pop     bx              ; Restore bx
        ret                     ; Return to caller
ENDP    PrintASCII

;------Turn Cursor Off -------------------------------------------
PROC   CursorOff
	;
	; This procedure simply turns the Cursor off
	;

		push    ax
		push    bx
		push    cx
		push    dx
		mov     ah, 03h         ; BIOS INT 10 func 3 (Get Cursor pos)
		int     10h             ; Call INT 10
		or      ch, 0100000b    ; Turn on cursor bit
		mov     ah, 01h         ; BIOS INT 10 func 1 (Set cursor type)
		int     10h             ; Call INT 10
		pop     dx
		pop     cx
		pop     bx
		pop     ax
		ret
 ENDP CursorOff

;---- Turn Cursor On --------------------------------------------------------
PROC   CursorOn

	; This procedure simply turns the Cursor on
	;
		push    ax
		push    bx
		push    cx
		push    dx
		mov     ah, 03h         ; BIOS INT 10 func 3 (Get Cursor pos)
		int     10h             ; Call INT 10
		and     ch, 1011111b    ; Turn off cursor bit
		mov     ah, 01h         ; BIOS INT 10 func 1 (Set cursor type)
		int     10h             ; Call INT 10
		pop     dx
		pop     cx
		pop     bx
		pop     ax
		ret

 ENDP CursorOn

        END                     ; End of module
