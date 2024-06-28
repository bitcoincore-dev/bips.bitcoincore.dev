#!/usr/bin/env bash

unameOut=$(uname -a)
case "${unameOut}" in
    *Microsoft*)     OS="WSL";; #must be first since Windows subsystem for linux will have Linux in the name too
    *microsoft*)     OS="WSL2";; #WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work
    Linux*)          OS="linux";;
    Darwin*)         OS="macos";type -P brew && brew install zola;;
    CYGWIN*)         OS="Cygwin";;
    MINGW*)          OS="windows";;
    *Msys)           OS="windows";;
    *)               OS="UNKNOWN:${unameOut}"
esac

arch=$(uname -m)

if [ "$arch" == 'x86_64' ];
then
ARCH=x64
fi

if [ "$arch" == 'armv*' ];
then
ARCH=armv7
fi
if [ "$arch" == '*rm64*' ];
then
ARCH=arm64
fi

echo OS=$OS
echo ARCH=$ARCH
