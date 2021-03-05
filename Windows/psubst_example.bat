@ECHO OFF

CALL psubst /P

ECHO [Remove old disk]
CALL psubst E: /D
CALL psubst E: /D /PF

ECHO [Add new disk]
CALL psubst E: D:\E_Data /PF

PAUSE
