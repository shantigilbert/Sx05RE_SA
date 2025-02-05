################################################################################
#      This file is part of Alex@ELEC - http://www.alexelec.in.ua
#      Copyright (C) 2011-2017 Alexandr Zuyev (alex@alexelec.in.ua)
################################################################################

PKG_NAME="glibc"
PKG_VERSION="2.23"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/libc/"
PKG_URL="http://ftp.gnu.org/pub/gnu/glibc/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="ccache:host autotools:host autoconf:host linux:host gcc:bootstrap"
PKG_DEPENDS_INIT="glibc"
PKG_SECTION="toolchain/devel"
PKG_SHORTDESC="glibc: The GNU C library"
PKG_LONGDESC="The Glibc package contains the main C library. This library provides the basic routines for allocating memory, searching directories, opening and closing files, reading and writing files, string handling, pattern matching, arithmetic, and so on."

PKG_IS_ADDON="no"
PKG_AUTORECONF="no"

PKG_CONFIGURE_OPTS_TARGET="BASH_SHELL=/bin/sh \
                           ac_cv_path_PERL= \
                           ac_cv_prog_MAKEINFO= \
                           --libexecdir=/usr/lib/glibc \
                           --cache-file=config.cache \
                           --disable-profile \
                           --disable-sanity-checks \
                           --enable-add-ons \
                           --enable-bind-now \
                           --with-elf \
                           --with-tls \
                           --with-__thread \
                           --with-binutils=$BUILD/toolchain/bin \
                           --with-headers=$SYSROOT_PREFIX/usr/include \
                           --enable-kernel=3.0.0 \
                           --without-cvs \
                           --without-gd \
                           --enable-obsolete-rpc \
                           --disable-build-nscd \
                           --disable-nscd \
                           --enable-lock-elision \
                           --disable-timezone-tools"

if [ "$DEBUG" = yes ]; then
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET --enable-debug"
else
  PKG_CONFIGURE_OPTS_TARGET="$PKG_CONFIGURE_OPTS_TARGET --disable-debug"
fi

NSS_CONF_DIR="$PKG_BUILD/nss"

GLIBC_EXCLUDE_BIN="catchsegv gencat getconf iconv iconvconfig ldconfig"
GLIBC_EXCLUDE_BIN="$GLIBC_EXCLUDE_BIN makedb mtrace pcprofiledump"
GLIBC_EXCLUDE_BIN="$GLIBC_EXCLUDE_BIN pldd rpcgen sln sotruss sprof xtrace"

pre_build_target() {
  cd $PKG_BUILD
    aclocal --force --verbose
    autoconf --force --verbose
  cd -
}

pre_configure_target() {
# Fails to compile with GCC's link time optimization.
  strip_lto

# glibc dont support GOLD linker.
  strip_gold

# Filter out some problematic *FLAGS
  export CFLAGS=`echo $CFLAGS | sed -e "s|-ffast-math||g"`
  export CFLAGS=`echo $CFLAGS | sed -e "s|-Ofast|-O2|g"`
  export CFLAGS=`echo $CFLAGS | sed -e "s|-O.|-O2|g"`

  if [ -n "$PROJECT_CFLAGS" ]; then
    export CFLAGS=`echo $CFLAGS | sed -e "s|$PROJECT_CFLAGS||g"`
  fi

  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-ffast-math||g"`
  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-Ofast|-O2|g"`
  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-O.|-O2|g"`

  export LDFLAGS=`echo $LDFLAGS | sed -e "s|-Wl,--as-needed||"`

  unset LD_LIBRARY_PATH

  # set some CFLAGS we need
  export CFLAGS="$CFLAGS -g -fno-stack-protector -fgnu89-inline"

  export BUILD_CC=$HOST_CC
  export OBJDUMP_FOR_HOST=objdump

cat >config.cache <<EOF
ac_cv_header_cpuid_h=yes
libc_cv_forced_unwind=yes
libc_cv_c_cleanup=yes
libc_cv_gnu89_inline=yes
libc_cv_ssp=no
libc_cv_ssp_strong=no
libc_cv_ctors_header=yes
libc_cv_slibdir=/lib
EOF

echo "libdir=/usr/lib" >> configparms
echo "slibdir=/lib" >> configparms
echo "sbindir=/usr/bin" >> configparms
echo "rootsbindir=/usr/bin" >> configparms
}

post_makeinstall_target() {
# we are linking against ld.so, so symlink
  ln -sf $(basename $INSTALL/lib/ld-*.so) $INSTALL/lib/ld.so

# cleanup
  for i in $GLIBC_EXCLUDE_BIN; do
    rm -rf $INSTALL/usr/bin/$i
  done
  rm -rf $INSTALL/usr/lib/audit
  rm -rf $INSTALL/usr/lib/glibc
  rm -rf $INSTALL/usr/lib/libc_pic
  rm -rf $INSTALL/usr/lib/*.o
  rm -rf $INSTALL/usr/lib/*.map
  rm -rf $INSTALL/var

# create locale
  if [ "$GLIBC_LOCALES" = yes ]; then
    mkdir -p $INSTALL/usr/share/i18n/locales
      cp $ROOT/$PKG_BUILD/localedata/locales/* $INSTALL/usr/share/i18n/locales/
    mkdir -p $INSTALL/usr/share/i18n/charmaps
      cp $ROOT/$PKG_BUILD/localedata/charmaps/* $INSTALL/usr/share/i18n/charmaps/
      cp $ROOT/$PKG_BUILD/localedata/SUPPORTED $INSTALL/usr/share/i18n/
      ln -s /storage/.config/locale $INSTALL/usr/lib/locale
  else
    # remove locales and charmaps
    rm -rf $INSTALL/usr/share/i18n/charmaps
    rm -rf $INSTALL/usr/share/i18n/locales

    mkdir -p $INSTALL/usr/share/i18n/locales
      cp -PR $ROOT/$PKG_BUILD/localedata/locales/POSIX $INSTALL/usr/share/i18n/locales
    mkdir -p $INSTALL/usr/share/i18n/charmaps
      cp -PR $ROOT/$PKG_BUILD/localedata/charmaps/UTF* $INSTALL/usr/share/i18n/charmaps
  fi

# create default configs
  mkdir -p $INSTALL/etc
    cp $PKG_DIR/config/nsswitch.conf $INSTALL/etc
    cp $PKG_DIR/config/host.conf $INSTALL/etc
    cp $PKG_DIR/config/gai.conf $INSTALL/etc

  if [ "$TARGET_ARCH" = "arm" -a "$TARGET_FLOAT" = "hard" ]; then
    ln -sf ld.so $INSTALL/lib/ld-linux.so.3
  fi
}

configure_init() {
  cd $ROOT/$PKG_BUILD
    rm -rf $ROOT/$PKG_BUILD/.$TARGET_NAME-init
}

make_init() {
  : # reuse make_target()
}

makeinstall_init() {
  mkdir -p $INSTALL/lib
    cp -PR $ROOT/$PKG_BUILD/.$TARGET_NAME/elf/ld*.so* $INSTALL/lib
    cp $ROOT/$PKG_BUILD/.$TARGET_NAME/libc.so.6 $INSTALL/lib
    cp $ROOT/$PKG_BUILD/.$TARGET_NAME/math/libm.so* $INSTALL/lib
    cp $ROOT/$PKG_BUILD/.$TARGET_NAME/nptl/libpthread.so.0 $INSTALL/lib
    cp -PR $ROOT/$PKG_BUILD/.$TARGET_NAME/rt/librt.so* $INSTALL/lib

    if [ "$TARGET_ARCH" = "arm" -a "$TARGET_FLOAT" = "hard" ]; then
      ln -sf ld.so $INSTALL/lib/ld-linux.so.3
    fi
}
