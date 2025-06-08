#!/bin/bash

set -e

# ========== Warna ==========
GREEN='\033[0;32m'
BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ========== Default Config ==========
SDK_URL="https://downloads.openwrt.org/releases/24.10.0/targets/armsr/armv8/openwrt-sdk-24.10.0-armsr-armv8_gcc-13.3.0_musl.Linux-x86_64.tar.zst"
SDK_ARCHIVE="openwrt-sdk.tar.zst"
SDK_DIR="openwrt-sdk"
PKG_NAME="mongoose"
PKG_VERSION="7.12"
PORT="27017"
WEBROOT="/www"

# ========== Fungsi Bantuan ==========
usage() {
  echo -e "${YELLOW}Usage: $0 [options]${NC}"
  echo -e "  -d         Download SDK (jika belum ada)"
  echo -e "  -b         Build mongoose package"
  echo -e "  -i         Install dependencies"
  echo -e "  -p <port>  Port server (default: 27017)"
  echo -e "  -r <path>  Web root directory (default: /www)"
  echo -e "  -h         Tampilkan bantuan"
  exit 1
}

# ========== Parsing Argumen ==========
DO_DOWNLOAD=false
DO_BUILD=false
DO_INSTALL=false

while getopts "dbip:r:h" opt; do
  case $opt in
    d) DO_DOWNLOAD=true ;;
    b) DO_BUILD=true ;;
    i) DO_INSTALL=true ;;
    p) PORT="$OPTARG" ;;
    r) WEBROOT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ========== Install Dependencies ==========
if $DO_INSTALL; then
  echo -e "${BLUE}>> Menginstal dependencies build...${NC}"
  sudo apt update
  sudo apt install -y build-essential libncurses5-dev gawk git subversion libssl-dev wget unzip python3 zstd
fi

# ========== Download SDK ==========
if $DO_DOWNLOAD; then
  if [ ! -f "$SDK_ARCHIVE" ]; then
    echo -e "${BLUE}>> Mengunduh OpenWrt SDK...${NC}"
    wget -O "$SDK_ARCHIVE" "$SDK_URL"
  else
    echo -e "${GREEN}>> SDK sudah ada. Melewati download.${NC}"
  fi

  if [ ! -d "$SDK_DIR" ]; then
    echo -e "${BLUE}>> Mengekstrak SDK...${NC}"
    mkdir -p "$SDK_DIR"
    tar -I zstd -xvf "$SDK_ARCHIVE" -C "$SDK_DIR" --strip-components=1
  else
    echo -e "${GREEN}>> Direktori SDK sudah tersedia.${NC}"
  fi
fi

# ========== Build Package ==========
if $DO_BUILD; then
  cd "$SDK_DIR"

  echo -e "${BLUE}>> Menyiapkan direktori package...${NC}"
  mkdir -p package/$PKG_NAME/src
  cd package/$PKG_NAME/src

  # Unduh mongoose.c dan .h jika belum ada
  [ -f mongoose.c ] || wget https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.c
  [ -f mongoose.h ] || wget https://raw.githubusercontent.com/cesanta/mongoose/master/mongoose.h

  # Tulis main.c dinamis
  cat > main.c <<EOF
#include "mongoose.h"

static const char *s_listen_on = "http://0.0.0.0:$PORT";
static const char *s_web_root = "$WEBROOT";

static void fn(struct mg_connection *c, int ev, void *ev_data, void *fn_data) {
  if (ev == MG_EV_HTTP_MSG) {
    struct mg_http_message *hm = (struct mg_http_message *) ev_data;
    mg_http_serve_dir(c, hm, s_web_root);
  }
  (void) fn_data;
}

int main(void) {
  struct mg_mgr mgr;
  mg_mgr_init(&mgr);
  mg_http_listen(&mgr, s_listen_on, fn, &mgr);
  for (;;) mg_mgr_poll(&mgr, 1000);
  mg_mgr_free(&mgr);
  return 0;
}
EOF

  cd ..
  # Tulis Makefile jika belum ada
  cat > Makefile <<EOF
include \$(TOPDIR)/rules.mk

PKG_NAME:=${PKG_NAME}
PKG_VERSION:=${PKG_VERSION}
PKG_RELEASE:=1

include \$(INCLUDE_DIR)/package.mk

define Package/${PKG_NAME}
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Mongoose Embedded Web Server
endef

define Package/${PKG_NAME}/description
  Mongoose is a simple embedded web server in a single C file.
endef

define Build/Prepare
	mkdir -p \$(PKG_BUILD_DIR)
	cp ./src/mongoose.c \$(PKG_BUILD_DIR)/
	cp ./src/mongoose.h \$(PKG_BUILD_DIR)/
	cp ./src/main.c \$(PKG_BUILD_DIR)/
endef

define Build/Compile
	\$(TARGET_CC) \$(TARGET_CFLAGS) -I\$(PKG_BUILD_DIR) \\
	  \$(PKG_BUILD_DIR)/main.c \$(PKG_BUILD_DIR)/mongoose.c -o \$(PKG_BUILD_DIR)/mongoose
endef

define Package/${PKG_NAME}/install
	\$(INSTALL_DIR) \$(1)/usr/bin
	\$(INSTALL_BIN) \$(PKG_BUILD_DIR)/mongoose \$(1)/usr/bin/
endef

\$(eval \$(call BuildPackage,${PKG_NAME}))
EOF

  echo -e "${BLUE}>> Memulai proses build...${NC}"
  make package/$PKG_NAME/clean
  make package/$PKG_NAME/compile V=s

  echo -e "${GREEN}✅ Build selesai. File ipk berada di:${NC}"
  find bin/ -name "${PKG_NAME}_*aarch64_generic.ipk"
fi
