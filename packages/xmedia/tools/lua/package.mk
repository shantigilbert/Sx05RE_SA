################################################################################
#      This file is part of Alex@ELEC - http://www.alexelec.in.ua
#      Copyright (C) 2011-2017 Alexandr Zuyev (alex@alexelec.in.ua)
################################################################################

PKG_NAME="lua"
PKG_VERSION="5.3.3"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="http://www.lua.org/"
PKG_URL="http://www.lua.org/ftp/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain readline lua:host"
PKG_SECTION="xmedia/tools"
PKG_SHORTDESC="lua: A lightweight, extensible programming language"
PKG_LONGDESC="Lua is a powerful light-weight programming language designed for extending applications. Lua is also frequently used as a general-purpose, stand-alone language."
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

_MAJORVER=${PKG_VERSION%.*}

make_host() {
  : none
}

makeinstall_host() {
  mkdir -p $ROOT/$TOOLCHAIN/bin
   cp -P $PKG_DIR/src/* $ROOT/$TOOLCHAIN/bin
}

make_target() {
  CFLAGS=`echo $CFLAGS | sed -e "s|-mcpu=cortex-a53||"`
  make CC="$CC" CFLAGS="$CFLAGS -fPIC -DLUA_COMPAT_5_2 -DLUA_COMPAT_5_1" linux
}

makeinstall_target() {
  make \
  TO_LIB="liblua.a liblua.so liblua.so.$_MAJORVER liblua.so.$PKG_VERSION" \
  INSTALL_DATA='cp -d' \
  INSTALL_TOP=$SYSROOT_PREFIX/usr \
  INSTALL_MAN=$SYSROOT_PREFIX/usr/share/man/man1 \
  install

  ln -sf $SYSROOT_PREFIX/usr/bin/lua $SYSROOT_PREFIX/usr/bin/lua$_MAJORVER
  ln -sf $SYSROOT_PREFIX/usr/bin/luac $SYSROOT_PREFIX/usr/bin/luac$_MAJORVER

  mkdir -p $SYSROOT_PREFIX/usr/lib/pkgconfig
    cp -P $PKG_DIR/config/lua.pc $SYSROOT_PREFIX/usr/lib/pkgconfig/lua53.pc
  ln -sf $SYSROOT_PREFIX/usr/lib/pkgconfig/lua53.pc $SYSROOT_PREFIX/usr/lib/pkgconfig/lua.pc

  make \
  TO_LIB="liblua.a liblua.so liblua.so.$_MAJORVER liblua.so.$PKG_VERSION" \
  INSTALL_DATA='cp -d' \
  INSTALL_TOP=$INSTALL/usr \
  INSTALL_MAN=$INSTALL/usr/share/man/man1 \
  install

  ln -sf $INSTALL/usr/bin/lua $INSTALL/usr/bin/lua$_MAJORVER
  ln -sf $INSTALL/usr/bin/luac $INSTALL/usr/bin/luac$_MAJORVER
}

