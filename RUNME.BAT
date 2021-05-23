@echo off
cls
type note.txt
pause
@echo on
tasm edit10
pause
tlink edit10 mylib binasc strio keyboard strings fileio

