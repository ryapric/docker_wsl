#!/usr/bin/env bash
set -e

# Instructions available at:
# https://blogs.msdn.microsoft.com/commandline/2017/12/08/cross-post-wsl-interoperability-with-docker/

# Set Windows system username for Go, and drop its \r and possible illegal characters
win_user=$(cmd.exe /c "echo %USERNAME%")
win_user=$(echo "$win_user" | sed -r 's/\\r//g')
# win_user=$(echo "$win_user" | sed -r 's/\./\\./g')

# Update if applicable, and install golang, socat, and the docker.io client
sudo apt-get update && sudo apt-get install golang socat docker.io

# Build the relay between WSL and the Windows Docker host
GOPATH=$HOME/go go get -d github.com/jstarks/npiperelay
GOPATH=$HOME/go GOOS=windows go build -o /mnt/c/Users/ryan.price/go/bin/npiperelay.exe github.com/jstarks/npiperelay
sudo ln -sf /mnt/c/Users/ryan.price/go/bin/npiperelay.exe /usr/local/bin/npiperelay.exe

# Make the relay file, fill it, make it executable, and add it to ~/.bashrc
echo "
#!/bin/sh
exec socat UNIX-LISTEN:/var/run/docker.sock,fork,group=docker,umask=007 EXEC:\"npiperelay.exe -ep -s //./pipe/docker_engine\",nofork
" > ~/docker-relay
chmod +x ~/docker-relay

echo "

# Start Docker relay at shell launch
sh ~/docker-relay
" >> ~/.bashrc
