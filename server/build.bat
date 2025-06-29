REM @echo off
REM set GOARCH=amd64
go build -o todochat_server.exe -ldflags="-s -w" 
echo Build complete: myapp-linux
pause
