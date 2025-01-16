path$ = "D:\BP\DOOM\WHTK\"
OPEN path$ + "test.wav" FOR BINARY AS #1
OPEN path$ + "dssgtsit.wav" FOR BINARY AS #2
b = 0
DO UNTIL EOF(2)
        a$ = " "
        b$ = " "
        GET #1, , a$
        GET #2, , b$
        IF a$ <> b$ THEN
                PRINT "Byte # "; HEX$(b); " "; ASC(a$); " "; ASC(b$)
        END IF
        b = b + 1
        LOCATE 1, 1
        PRINT SEEK(2)
LOOP
CLOSE 1, 2


