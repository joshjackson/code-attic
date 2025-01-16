TYPE soundrec
   IDLen AS STRING * 1
   ID    AS STRING * 8
   DLen  AS STRING * 1
   Desc  AS STRING * 55
   LI1   AS LONG
   li2   AS LONG
END TYPE
DIM s AS soundrec

'OPEN "wad.dir" FOR INPUT AS #1
'OPEN "sound.ids" FOR OUTPUT AS #2
'DO UNTIL EOF(1)
'   LINE INPUT #1, a$
'   IF MID$(a$, 2, 1) <> "P" THEN
'      PRINT #2, LEFT$(a$, 8)
'   END IF
'LOOP
'CLOSE 1, 2

OPEN "sound.ids" FOR INPUT AS #1
OPEN "sounds.lst" FOR INPUT AS #2
OPEN "sound.def" FOR BINARY AS #3
DO UNTIL EOF(1)
   LINE INPUT #1, a$
   LINE INPUT #2, b$
   b$ = RTRIM$(b$)
   s.DLen = CHR$(LEN(b$))
   a$ = RTRIM$(a$)
   s.IDLen = CHR$(LEN(a$))
   s.Desc = b$
   s.ID = a$
   PUT #3, , s
LOOP
CLOSE 1
CLOSE 2
CLOSE 3


