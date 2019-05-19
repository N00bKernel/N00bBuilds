#!/bin/bash
clear
mkdir ./Toolchains && cd ./Toolchains
echo "[I] Getting gcc"
wget https://is.gd/malakas_gcc -O gcc.tar.xz
tar -xvf gcc.tar.xz
mv gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/ gcc/
export PATH=$PWD/gcc/bin:$PATH
echo "[I] Getting clang"
git clone https://github.com/N00bKernel/DragonTC-9.0.git clang
export PATH=$PWD/clang/bin:$PATH
export CC=clang
cd ..
clear
echo ""
echo " __    _  _______  _______  _______ "
echo "|  |  | ||  _    ||  _    ||  _    |"
echo "|   |_| || | |   || | |   || |_|   |"
echo "|       || | |   || | |   ||       |"
echo "|  _    || |_|   || |_|   ||  _   | "
echo "| | |   ||       ||       || |_|   |"
echo "|_|  |__||_______||_______||_______|"
echo " ___      _______  _______ "
echo "|   |    |   _   ||  _    |"
echo "|   |    |  |_|  || |_|   |"
echo "|   |    |       ||       |"
echo "|   |___ |       ||  _   | " 
echo "|       ||   _   || |_|   |"
echo "|_______||__| |__||_______|"
echo ""
echo "Scientist : chankruze"
echo "Company   : GEEKOFIA"
echo "Hobby     : Banging bitches like you !"
echo ""
####################### N00b Lab Initialization #######################
# 
# Configure Local Directories & Variables
#
# libncurses5 <-- bhosdiwala
# kernel source dir
SOURCE_DIR=$PWD
DEVICE_CODE_NAME=stanlee
# ARCH & SUBARCH
ARCH=arm64
SUBARCH=arm64
# Toolchain dir
TOOLCHAIN_DIR=$SOURCE_DIR/Toolchains
# kernel build / work dir
OUT_DIR=$SOURCE_DIR/out
# kernel out dir
KERNEL_DIR=$OUT_DIR/arch/$ARCH/boot
# archiving dir
SHIPPING_DIR=$SOURCE_DIR/shipping_dir
# release dir
RELEASE_DIR=$SOURCE_DIR/release_dir
# Clang & GCC PATH
CLANG_PATH=$TOOLCHAIN_DIR/$CLANG_DIR
GCC_PATH=$TOOLCHAIN_DIR/$GCC_DIR
#############################################################
# Clang dir
CLANG_DIR=clang
# GCC dir
GCC_DIR=gcc
# Prefix & flags
CC=clang
CLANG_TRIPLE_PREFIX=aarch64-linux-gnu-
CROSS_COMPILE_PREFIX=aarch64-linux-gnu-
# Kernel image Name
KERNEL=Image.gz
#
# Build details
#
CONFIG=sdm660-perf_defconfig
ZIP_NAME=N00bKernel-stanlee
KERNEL_VERSION=2.0.0
####################### Start The Shit #######################
# change directory to kernel source
cd $SOURCE_DIR/
# SET PATH FIRST
export PATH=$CLANG_PATH/bin:$GCC_PATH/bin:$PATH
# set ARCH & SUBARCH 
export ARCH=$ARCH
export SUBARCH=$ARCH
# set TOOLCHAIN
export CC=$CC
export CLANG_TRIPLE=$CLANG_TRIPLE_PREFIX
export CROSS_COMPILE=$CROSS_COMPILE_PREFIX
# cache (automatically done by travis)
# export USE_CCACHE=1
# export CCACHE_DIR=$HOME/.ccache
# clean up old builds
export KBUILD_BUILD_USER="chankruze"
export KBUILD_BUILD_HOST="Travis-CI"
make clean
make mrproper
##########################
# Out/Building Directory #
##########################
if [ ! -d $OUT_DIR/ ]; then
    echo "[I] Creating Work Directory !"
    mkdir -p $OUT_DIR/
fi
make O=$OUT_DIR clean
make O=$OUT_DIR mrproper
# write device_defconfig to .config
make O=$OUT_DIR ARCH=$ARCH $CONFIG
# start build
echo "[I] kernel compiling started...."
ccache make O=$OUT_DIR ARCH=$ARCH CC=$CC CLANG_TRIPLE=$CLANG_TRIPLE_PREFIX CROSS_COMPILE=$CROSS_COMPILE_PREFIX
clear
echo "[I] kernel compiled...."
sleep 2
echo "[I] copying kernel to shipping directory...."
# copy compiled kernel to shipping directory
sleep 2
######################
# Shipping Directory #
######################
if [ ! -d $SHIPPING_DIR/ ]; then
    echo "[I] Creating Shipping Directory !"
    mkdir -p $SHIPPING_DIR/
    echo "[I] Setting Up Shipping Directory !"
    git clone https://github.com/N00bKernel/FlashableArchive.git $SHIPPING_DIR
fi
# change directory to shipping directory
cd $SHIPPING_DIR/
# remove old zip (here kept as backup)
echo "[I] removing older flashable zips & kernel...."
rm $KERNEL
rm N00bKernel-*.zip *.sha1
cp $KERNEL_DIR/$KERNEL $SHIPPING_DIR/
# archive and make flashable zip
echo "[I] building flashable zip...."
make NAME=$ZIP_NAME VERSION=$KERNEL_VERSION
sleep 5
#####################
# Release Directory #
#####################
if [ ! -d $RELEASE_DIR/ ]; then
    echo "[I] Creating Release Directory !"
    mkdir -p $RELEASE_DIR/
fi
if [ ! -f $RELEASE_DIR/N00bKernel-*.zip ]; then
    echo "[I] Cleaning Release Directory !"
    rm $RELEASE_DIR/N00bKernel-*.zip
fi
# copy to release dir
echo "[I] copying flashable zip to release directory..."
cp $SHIPPING_DIR/N00bKernel-*.zip $RELEASE_DIR/

####### CREATE RELEASE ########
cd $RELEASE_DIR
export RELEASE_DIR=$PWD
# Release details
# REPO=N00bKernel/$DEVICE_CODE_NAME
RELEASE_NAME=$ZIP_NAME-$KERNEL_VERSION
RELEASE_TAG=$(date +'%Y%m%d-%H%M')
RELEASE_BODY=$(cat $OUT_DIR/include/generated/compile.h)
export RELEASE_BODY=$RELEASE_BODY
export RELEASE_NAME=$RELEASE_NAME
ASSET_LABEL=$RELEASE_NAME
git config --local user.name "chankruze"
git config --local user.email "chankruze@gmail.com"
TOKEN=f23171ce79e10d0a39ff1ec200b02d9a3601a1f5

upload_url=$(curl -s -H "Authorization: token $TOKEN"  \
     -d '{"tag_name": "build-001", "name":"N00bKernel 2.0.0","body":"Initial Release"}'  \
     "https://api.github.com/repos/$REPO/releases" | jq -r '.upload_url')

upload_url="${upload_url%\{*}"

echo "uploading N00bKernel to github release : $upload_url"

curl -s -H "Authorization: token $TOKEN"  \
        -H "Content-Type: application/zip" \
        --data-binary @N00bKernel-2.0.0.zip  \
        "$upload_url?name=$RELEASE_NAME.zip&label=$ASSET_LABEL.zip"
        
cat $OUT_DIR/include/generated/compile.h