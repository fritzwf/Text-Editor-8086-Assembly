%TITLE "Keyboard Input Routines -- Copyright (c) 1989 by Tom Swan"

        IDEAL
        DOSSEG
        MODEL   small


        CODESEG

        PUBLIC  KeyWaiting, GetCh

%NEWPAGE
;---------------------------------------------------------------
; KeyWaiting    Test if a keypress is available
;---------------------------------------------------------------
; Input:
;       none
; Output:
;       zf = 0 : (JNZ) Character is waiting to be read
;       zf = 1 : (JZ)  No character is waiting
; Registers:
;       none (flags only)
;---------------------------------------------------------------
PROC    KeyWaiting
        push    ax              ; Save modified register
        mov     ah, 1           ; BIOS check buffer function
        int     16h             ; Call BIOS keyboard service
        pop     ax              ; Restore register
        ret                     ; Return to caller
ENDP    KeyWaiting
%NEWPAGE
;---------------------------------------------------------------
; GetCh         Return ASCII, Control, or Function key value
;---------------------------------------------------------------
; Input:
;       none
; Output:
;       zf = 0 (ah = 1) : (JNZ) al = ASCII character 
;       zf = 1 (ah = 0) : (JZ) al = ASCII control or function
; Registers:
;       ax
;---------------------------------------------------------------
PROC    GetCh
        xor     ah, ah          ; BIOS read-key function
        int     16h             ; Call BIOS keyboard service
        or      al, al          ; Is ASCII code = 0?
        jnz     @@10            ; If no, jump (not a special key)
        xchg    ah, al          ; Else set ah<-0, al<-scan code
        add     al, 32          ; Adjust scan code to >= 32
        jmp     short @@20      ; Jump to exit
@@10:
        xor     ah, ah          ; Initialize ah to 0
        cmp     al, 32          ; Is ASCII code < 32 (i.e. a Ctrl)?
        jb      @@20            ; If yes, jump (al=control key)
        inc     ah              ; Else set ah = 1 (al=ASCII char)
@@20:
        or      ah, ah          ; Set or clear zf result flag
        ret                     ; Return to caller
ENDP    GetCh

        END                     ; End of module
