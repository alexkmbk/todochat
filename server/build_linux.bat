REM @echo off
set GOOS=linux
set GOARCH=amd64
go build -o todochat_server_linux -ldflags="-s -w" 
echo Build complete: myapp-linux
pause
