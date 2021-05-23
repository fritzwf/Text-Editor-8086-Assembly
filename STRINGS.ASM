%TITLE "String Procedures--Copyright 1989 by Tom Swan"

        IDEAL
        DOSSEG
        MODEL   small

        CODESEG

        PUBLIC  MoveLeft, MoveRight, StrNull, StrLength
        PUBLIC  StrUpper, StrCompare, StrDelete, StrInsert
        PUBLIC  StrConcat, StrCopy, StrPos, StrRemove

;---------------------------------------------------------------------
; Assemble with the command TASM STRINGS to create STRINGS.OBJ. To use 
; the procedures, add EXTRN <procedure>:PROC statements where
; <procedure> is one of the following identifiers:
;
;       MoveLeft        -- memory move with increasing indexes
;       MoveRight       -- memory move with decreasing indexes
;       StrNull         -- erase all chars in string
;       StrLength       -- return number of chars in string
;       StrUpper        -- convert chars in string to uppercase
;       StrCompare      -- alphabetically compare two strings
;       StrDelete       -- delete chars from string
;       StrInsert       -- insert chars into string
;       StrConcat       -- attach one string to another
;       StrCopy         -- copy one string to another
;       StrPos          -- find position of substring in a string
;       StrRemove       -- remove substring from a string
;
; After assembling your program, link with STRINGS.OBJ.  For example, 
; if your program is named MYPROG, first assemble MYPROG to MYPROG.OBJ
; and link with the command TLINK MYPROG+STRINGS to create MYPROG.EXE.
;
; STRING VARIABLES:
; A string is a simple array of characters with one character per
; eight-bit byte.  A null character (ASCII 0) must follow the last
; character in the string.  An empty string contains a single null.
; Declare string variables this way:
;
;       STRING  DB      81 DUP (0)      ; 80-character string + null
;
; STRING CONSTANTS:
; Always allow one extra byte for the null terminator.  Character 
; constants (which may be used as variables) must be properly 
; terminated.  For example:
;
;       C1      db      'This is a test string.', 0
;
; SEGMENT REGISTERS:
; Routines in this package assume that ES and DS address the
; same segment.  Set ES=DS before calling any of these routines.
;---------------------------------------------------------------------

ASCNull         EQU     0               ; ASCII null character

%NEWPAGE
;---------------------------------------------------------------
; MoveLeft      Move byte-block left (down) in memory
;---------------------------------------------------------------
; Input:
;       si = address of source string (s1)
;       di = address of destination string (s2)
;       bx = index s1 (i1)
;       dx = index s2 (i2)
;       cx = number of bytes to move (count)
; Output:
;       count bytes from s1[i1] moved to the location
;       starting at s2[i2]
; Registers:
;       none
;---------------------------------------------------------------
PROC    MoveLeft
        jcxz    @@99            ; Exit if count = 0
        push    cx              ; Save modified registers
        push    si
        push    di

        add     si, bx          ; Index into source string
        add     di, dx          ; Index into destination string
        cld                     ; Auto-increment si and di
        rep     movsb           ; Move while cx <> 0

        pop     di              ; Restore registers
        pop     si
        pop     cx
@@99:
        ret                     ; Return to caller
ENDP    MoveLeft
%NEWPAGE
;---------------------------------------------------------------
; MoveRight     Move byte-block right (up) in memory
;---------------------------------------------------------------
; Input:
;       (same as MoveLeft)
; Output:
;       (same as MoveLeft)
; Registers:
;       none
;---------------------------------------------------------------
PROC    MoveRight
        jcxz    @@99            ; Exit if count = 0
        push    cx              ; Save modified registers
        push    di
        push    si

        add     si, bx          ; Index into source string
        add     di, dx          ; Index into destination string
        add     si, cx          ; Adjust to last source byte
        dec     si
        add     di, cx          ; Adjust to last destination byte
        dec     di
        std                     ; Auto-decrement si and di
        rep     movsb           ; Move while cx <> 0

        pop     si              ; Restore registers
        pop     di
        pop     cx
@@99:
        ret                     ; Return to caller
ENDP    MoveRight
%NEWPAGE
;---------------------------------------------------------------
; StrNull       Erase all characters in a string
;---------------------------------------------------------------
; Input:
;       di = address of string (s)
; Output:
;       s[0] <- null character (ASCII 0)
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrNull
        mov     [byte ptr di], ASCNull  ; Insert null at s[0]
        ret                             ; Return to caller
ENDP    StrNull
%NEWPAGE
;---------------------------------------------------------------
; StrLength     Count non-null characters in a string
;---------------------------------------------------------------
; Input:
;       di = address of string (s)
; Output:
;       cx = number of non-null characters in s
; Registers:
;       cx
;---------------------------------------------------------------
PROC    StrLength
        push    ax              ; Save modified registers
        push    di

        xor     al, al          ; al <- search char (null)
        mov     cx, 0ffffh      ; cx <- maximum search depth
        cld                     ; Auto-increment di
        repnz   scasb           ; Scan for al while [di]<>null & cx<>0
        not     cx              ; Ones complement of cx
        dec     cx              ;  minus 1 equals string length

        pop     di              ; Restore registers
        pop     ax
        ret                     ; Return to caller
ENDP    StrLength
%NEWPAGE
;---------------------------------------------------------------
; StrUpper      Convert chars in string to uppercase
;---------------------------------------------------------------
; Input:
;       di = address of string to convert (s)
; Output:
;       lowercase chars in string converted to uppercase
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrUpper
        push    ax              ; Save modified registers
        push    cx
        push    di
        push    si
        call    StrLength       ; Set cx = length of string
        jcxz    @@99            ; Exit if length = 0
        cld                     ; Auto-increment si, di
        mov     si, di          ; Set si = di
@@10:
        lodsb                   ; al <- s[si]; si <- si + 1
        cmp     al, 'a'         ; Is al >= 'a'?
        jb      @@20            ; No, jump to continue scan
        cmp     al, 'z'         ; Is al <= 'z'?
        ja      @@20            ; No, jump to continue scan
        sub     al, 'a'-'A'     ; Convert lowercase to uppercase
@@20:
        stosb                   ; s[di] <- al; di <- di + 1
        loop    @@10            ; cx <- cx - 1; loop if cx <> 0
@@99:
        pop     si              ; Restore registers
        pop     di
        pop     cx
        pop     ax
        ret                     ; Return to caller
ENDP    StrUpper
%NEWPAGE
;---------------------------------------------------------------
; StrCompare    Compare two strings
;---------------------------------------------------------------
; Input:
;       si = address of string 1 (s1)
;       di = address of string 2 (s2) 
; Output:
;       flags set for conditional jump using jb, jbe,
;        je, ja, or jae.
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrCompare
        push    ax              ; Save modified registers
        push    di
        push    si
        cld                     ; Auto-increment si
@@10:
        lodsb                   ; al <- [si], si <- si + 1
        scasb                   ; Compare al and [di]; di <- di + 1
        jne     @@20            ; Exit if non-equal chars found
        or      al, al          ; Is al=0? (i.e. at end of s1)
        jne     @@10            ; If no jump, else exit
@@20:
        pop     si              ; Restore registers
        pop     di
        pop     ax
        ret                     ; Return flags to caller
ENDP    StrCompare
%NEWPAGE
;---------------------------------------------------------------
; StrDelete     Delete characters anywhere in a string
;---------------------------------------------------------------
; Input:
;       di = address of string (s)
;       dx = index (i) of first char to delete
;       cx = number of chars to delete (n)
; Output:
;       n characters deleted from string at s[i]
;       Note: prevents deleting past end of string
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrDelete
        push    bx              ; Save modified registers
        push    cx
        push    di
        push    si

; bx = SourceIndex
; cx = Count / Len / CharsToMove
; dx = Index

        mov     bx, dx          ; Assign string index to bx
        add     bx, cx          ; Source index <- index + count
        call    StrLength       ; cx <- length(s)
        cmp     cx, bx          ; Is length > index?
        ja      @@10            ; If yes, jump to delete chars
        add     di, dx          ;  else, calculate index to string end
        mov     [byte ptr di], ASCNull  ; and insert null
        jmp     short @@99      ; Jump to exit
@@10:
        mov     si, di          ; Make source = destination
        sub     cx, bx          ; CharsToMove <- Len - SourceIndex
        inc     cx              ; Plus one for null at end of string
        call    MoveLeft        ; Move chars over deleted portion
@@99:
        pop     si              ; Restore registers
        pop     di
        pop     cx
        pop     bx
        ret                     ; Return to caller
ENDP    StrDelete
%NEWPAGE
;---------------------------------------------------------------
; StrInsert     Insert a string into another string
;---------------------------------------------------------------
; Input:
;       si = address of string 1 (s1)
;       di = address of string 2 (s2)
;       dx = insertion index for s2 (i)
;       NOTE: s2 must be large enough to expand by length(s1)!
; Output:
;       chars from string s1 inserted at s2[i]
;       s1 not changed
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrInsert
        push    ax              ; Save modified registers
        push    bx
        push    cx

; ax = LenInsertion
; cx = CharsToMove 

        xchg    si, di          ; Exchange si and di
        call    StrLength       ;  and find length of s1
        xchg    si, di          ; Restore si and di
        mov     ax, cx          ; Save length(s1) in ax

        call    StrLength       ; Find length of s2
        sub     cx, dx          ; cx <- length(s2) - i + 1
        inc     cx              ; cx = (CharsToMove)

; bx = s1 index

        push    dx              ; Save index (dx) and si
        push    si
        mov     si, di          ; Make si and di address s2 
        mov     bx, dx          ; Set s1 index to dx (i)
        add     dx, ax          ; Set s2 index to i+LenInsertion
        call    MoveRight       ; Open a hole for the insertion
        pop     si              ; Restore index (dx) and si
        pop     dx

        xor     bx, bx          ; Set s1 (source) index to zero
        mov     cx, ax          ; Set cx to LenInsertion
        call    MoveLeft        ; Insert s1 into hole in s2

        pop     cx              ; Restore registers
        pop     bx
        pop     ax
        ret                     ; Return to caller
ENDP    StrInsert
%NEWPAGE
;---------------------------------------------------------------
; StrConcat     Concatenate (join) two strings
;---------------------------------------------------------------
; Input:
;       si = address of source string (s1)
;       di = address of destination string (s2)
;       Note: s2 must be large enough to expand by length(s1)!
; Output:
;       chars from s1 added to end of s2
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrConcat
        push    bx              ; Save modified registers
        push    cx
        push    dx

; dx = s2 destination

        call    StrLength       ; Find length of destination (s2)
        mov     dx, cx          ; Set dx to index end of string
        xchg    si, di          ; Exchange si and di
        call    StrLength       ; Find find length of source (s1)
        inc     cx              ; Plus one includes null terminator
        xchg    si, di          ; Restore si and di
        xor     bx, bx          ; Source index = 0
        call    MoveLeft        ; Copy source string to destination

        pop     dx              ; Restore registers
        pop     cx
        pop     bx
        ret                     ; Return to caller
ENDP    StrConcat
%NEWPAGE
;---------------------------------------------------------------
; StrCopy       Copy one string to another
;---------------------------------------------------------------
; Input:
;       si = address of source string (s1)
;       di = address of destination string (s2)
; Output:
;       Chars in s1 copied to s2
;       Note: s2 must be at least Length(s1)+1 bytes long
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrCopy
        push    bx              ; Save modified registers
        push    cx
        push    dx

        xchg    si, di          ; Swap si and di
        call    StrLength       ; Find length of source string (s1)
        inc     cx              ; Plus one includes null terminator
        xchg    si, di          ; Restore si and di
        xor     bx, bx          ; Source string index = 0
        xor     dx, dx          ; Destination string index = 0
        call    MoveLeft        ; Copy source to destination

        pop     dx              ; Restore registers
        pop     cx
        pop     bx
        ret                     ; Return to caller
ENDP    StrCopy
%NEWPAGE
;---------------------------------------------------------------
; StrPos        Search for position of a substring in a string
;---------------------------------------------------------------
; Input:
;       si = address of substring to find
;       di = address of target string to scan
; Output:
;       if zf = 1 then dx = index of substring
;       if zf = 0 then substring was not found
;       Note: dx is meaningless if zf = 0
; Registers:
;       dx
;---------------------------------------------------------------
PROC    StrPos
        push    ax              ; Save modified registers
        push    bx
        push    cx
        push    di

        call    StrLength       ; Find length of target string
        mov     ax, cx          ; Save length(s2) in ax
        xchg    si, di          ; Swap si and di
        call    StrLength       ; Find length of substring
        mov     bx, cx          ; Save length(s1) in bx
        xchg    si, di          ; Restore si and di
        sub     ax, bx          ; ax = last possible index
        jb      @@20            ; Exit if len target < len substring
        mov     dx, 0ffffh      ; Initialize dx to -1
@@10:
        inc     dx              ; For i = 0 TO last possible index
        mov     cl, [byte bx + di]      ; Save char at s[bx] in cl
        mov     [byte bx + di], ASCNull ; Replace char with null
        call    StrCompare              ; Compare si to altered di
        mov     [byte bx + di], cl      ; Restore replaced char
        je      @@20            ; Jump if match found, dx=index, zf=1
        inc     di              ; Else advance target string index
        cmp     dx, ax          ; When equal, all positions checked
        jne     @@10            ; Continue search unless not found

        xor     cx, cx          ; Substring not found.  Reset zf = 0
        inc     cx              ;  to indicate no match
@@20:
        pop     di              ; Restore registers
        pop     cx
        pop     bx
        pop     ax
        ret                     ; Return to caller
ENDP    StrPos
%NEWPAGE
;---------------------------------------------------------------
; StrRemove     Remove substring from a string
;---------------------------------------------------------------
; Input:
;       si = address of substring to delete
;       di = address of string to delete substring from
; Output:
;       if zf = 1 then substring removed
;       if zf = 0 then substring was not found
;       Note: string at si is not changed
;       Note: if zf = 0 then string at di is not changed
; Registers:
;       none
;---------------------------------------------------------------
PROC    StrRemove
        push    cx              ; Save modified registers
        push    dx

        call    StrPos          ; Find substring, setting dx=index
        jne     @@99            ; Exit if substring not found
        pushf                   ; Save zf flag
        xchg    si, di          ; Swap si and di
        call    StrLength       ; Find length of substring
        xchg    si, di          ; Restore si and di
        call    StrDelete       ; Delete cx chars at di[dx]
        popf                    ; Restore zf flag
@@99:
        pop     dx              ; Restore registers
        pop     cx
        ret                     ; Return to caller
ENDP    StrRemove


        END                     ; End of STRINGS.ASM module
