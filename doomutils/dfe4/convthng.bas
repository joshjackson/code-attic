TYPE ThingDef
   Num      AS INTEGER
   PictID   AS STRING * 4
   AnimSeq  AS STRING * 7
   DefType  AS STRING * 1
   Desc     AS STRING * 65
END TYPE

DIM td AS ThingDef

OPEN "thing.dat" FOR INPUT AS #1
KILL "thing.def"
OPEN "thing.def" FOR BINARY AS #2
FOR t = 1 TO 98
   LINE INPUT #1, a$
   IF a$ = "" THEN EXIT FOR
   td.Num = VAL(MID$(a$, 1, 4))
   td.PictID = MID$(a$, 11, 4)
   td.AnimSeq = MID$(a$, 16, 7)
   SELECT CASE MID$(a$, 23, 1)
      CASE "!"
         td.DefType = CHR$(8)
      CASE "$"
         td.DefType = CHR$(1)
      CASE "*"
         td.DefType = CHR$(2)
      CASE ELSE
         td.DefType = CHR$(0)
   END SELECT
   IF MID$(a$, 24, 1) = "^" THEN
      td.DefType = CHR$(ASC(td.DefType) + 4)
   END IF
   td.Desc = MID$(a$, 25)
   PUT #2, , td
NEXT t
CLOSE 1, 2


        








