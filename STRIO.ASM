%TITLE "String Input/Output Routines"

        IDEAL
        DOSSEG
        MODEL   small


;-----  Equates

BufSize         EQU     255             ; Maximum string size (<=255)
ASCnull         EQU     0               ; ASCII null
ASCcr           EQU     13              ; ASCII carriage return
ASClf           EQU     10              ; ASCII line feed 


;-----  String buffer structure for DOS function 0Ah

STRUC StrBuffer
 maxlen         db BufSize              ; Maximum buffer length
 strlen         db 0                    ; String length
 chars          db BufSize DUP (?)      ; Buffer for StrRead
ENDS strBuffer


        DATASEG

buffer  StrBuffer <>                    ; Buffer variable for ReadStr


        CODESEG

;-----  From: STRINGS.OBJ

        EXTRN   StrLength:proc, StrCopy:proc

        PUBLIC  StrRead, StrWrite, StrWrite2, NewLine

%NEWPAGE
;---------------------------------------------------------------
; StrRead               Read string with editing keys
;---------------------------------------------------------------
; Input:
;       di = address of destination string
;       cl = maximum string length EXCLUDING null terminator
;       Note: if cl = 0, StrRead does nothing
;       Note: actual variable must be cl+1 bytes long
;       Note: string length is limited to 255 characters
; Output:
;       String copied from standard input into your buffer
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrRead
        or      cl, cl          ; Is cl = 0?
        jz      @@99            ; If yes, jump to exit

        push    ax              ; Save modified registers
        push    bx
        push    dx
        push    si

        mov     [buffer.maxlen], cl     ; Set maxlen byte
        mov     ah, 0ah                 ; DOS Buffered-Input function
        mov     dx, offset buffer.maxlen    ; Address struc with ds:dx
        int     21h                     ; Call DOS to read string
        xor     bh, bh                  ; Zero high byte of bx
        mov     bl, [buffer.strlen]     ; bx = # chars in buffer
        mov     [bx+buffer.chars], ASCnull  ; Change cr to null
        mov     si, offset buffer.chars ; Address buffer with si
        call    StrCopy                 ; Copy chars to user string

        pop     si                      ; Restore registers
        pop     dx
        pop     bx
        pop     ax
@@99:
        ret                     ; Return to caller
ENDP    StrRead
%NEWPAGE
;---------------------------------------------------------------
; StrWrite/StrWrite2    Write string to standard output
;---------------------------------------------------------------
; Input:
;       di = address of string (s)
;       cx = number of chars to write (StrWrite2 only)
; Output:
;       string s copied to standard output
;
; Registers:
;       cx (StrWrite only)
;---------------------------------------------------------------
PROC    StrWrite
        call    StrLength       ; Set cx=length of string

PROC    StrWrite2               ; Alternate entry point
        push    ax              ; Save modified registers
        push    bx
        push    dx

        mov     bx, 1           ; Standard output handle
        mov     dx, di          ; ds:dx address string
        mov     ah, 40h         ; DOS write to file or device
        int     21h             ; Call DOS (on ret ax=# chars written)

        pop     dx              ; Restore registers
        pop     bx
        pop     ax
        ret                     ; Return to caller
ENDP    StrWrite2               ; End of alternate procedure
ENDP    StrWrite                ; End of normal procedure

%NEWPAGE
;---------------------------------------------------------------
; NewLine       Start new line on standard output file
;---------------------------------------------------------------
; Input:
;       none
; Output:
;       carriage return, line feed sent to standard output
; Registers:
;       ah, dl
;---------------------------------------------------------------
PROC    NewLine
        mov     ah, 2           ; DOS write-char routine
        mov     dl, ASCcr       ; Load carriage return into dl
        int     21h             ; Write carriage return
        mov     dl, ASClf       ; Load line feed into dl
        int     21h             ; Write line feed
        ret                     ; Return to caller
ENDP    NewLine


        END             ; End of STRIO module
