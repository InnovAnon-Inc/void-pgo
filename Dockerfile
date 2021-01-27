FROM innovanon/void-base as builder

ARG CPPFLAGS
ARG   CFLAGS
ARG CXXFLAGS
ARG  LDFLAGS

ENV CHOST=x86_64-linux-gnu
ENV CC=$CHOST-gcc
ENV CXX=$CHOST-g++
ENV FC=$CHOST-gfortran
ENV NM=$CC-nm
ENV AR=$CC-ar
ENV RANLIB=$CC-ranlib
ENV STRIP=$CHOST-strip

ENV CPPFLAGS="$CPPFLAGS"
ENV   CFLAGS="$CFLAGS"
ENV CXXFLAGS="$CXXFLAGS"
ENV  LDFLAGS="$LDFLAGS"

#ENV PREFIX=/usr/local
ENV PREFIX=/opt/cpuminer
ENV CPPFLAGS="-I$PREFIX/include $CPPFLAGS"
ENV CPATH="$PREFIX/incude:$CPATH"
ENV    C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
ENV OBJC_INCLUDE_PATH="$PREFIX/include:$OBJC_INCLUDE_PATH"

ENV LDFLAGS="-L$PREFIX/lib $LDFLAGS"
ENV    LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
ENV LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
ENV     LD_RUN_PATH="$PREFIX/lib:$LD_RUN_PATH"

ENV PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PKG_CONFIG_LIBDIR"
ENV PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PKG_CONFIG_LIBDIR:$PKG_CONFIG_PATH"

ARG ARCH=native
ENV ARCH="$ARCH"

#ENV CPPFLAGS="-DUSE_ASM $CPPFLAGS"
#ENV   CFLAGS="-march=$ARCH -mtune=$ARCH $CFLAGS"

# PGO
#ENV   CFLAGS="-pg -fipa-profile -fprofile-reorder-functions -fvpt -fprofile -fprofile-abs-path -fprofile-arcs -fprofile-dir=/var/cpuminer $CFLAGS"
#ENV  LDFLAGS="-pg -fipa-profile -fprofile-reorder-functions -fvpt -fprofile -fprofile-abs-path -fprofile-arcs -fprofile-dir=/var/cpuminer $LDFLAGS"

# Debug
#ENV CPPFLAGS="-DNDEBUG $CPPFLAGS"
#ENV   CFLAGS="-Ofast -g0 $CFLAGS"

# Static
ENV  LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"

# LTO
#ENV   CFLAGS="-fuse-linker-plugin -flto $CFLAGS"
#ENV  LDFLAGS="-fuse-linker-plugin -flto $LDFLAGS"
##ENV   CFLAGS="-fuse-linker-plugin -flto -ffat-lto-objects $CFLAGS"
##ENV  LDFLAGS="-fuse-linker-plugin -flto -ffat-lto-objects $LDFLAGS"

# Dead Code Strip
#ENV   CFLAGS="-ffunction-sections -fdata-sections $CFLAGS"
##ENV  LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections $LDFLAGS"
#ENV  LDFLAGS="-Wl,-Bsymbolic -Wl,--gc-sections $LDFLAGS"

# Optimize
#ENV   CLANGFLAGS="-ffast-math -fassociative-math -freciprocal-math -fmerge-all-constants $CFLAGS"
#ENV       CFLAGS="-fipa-pta -floop-nest-optimize -fgraphite-identity -floop-parallelize-all $CLANGFLAGS"

ENV CLANGXXFLAGS="$CLANGFLAGS $CXXFLAGS"
ENV CXXFLAGS="$CFLAGS $CXXFLAGS"

WORKDIR /tmp
RUN command -v "$CC"                               \
 && command -v "$CXX"                              \
 && command -v "$FC"                               \
 && command -v "$NM"                               \
 && command -v "$AR"                               \
 && command -v "$RANLIB"                           \
 && command -v "$STRIP"                            \
 && test -n "$PREFIX"                              \
 \
 && FLAG=0                                         \
  ; for k in $(seq 1009) ; do                      \
      polygen -pedantic -o fingerprint.bc llvm.grm \
   || continue                                     \
    ; clang -c -o fingerprint.o                    \
        fingerprint.bc -static                     \
   || continue                                     \
    ; ar vcrs libfingerprint.a fingerprint.o       \
   || continue                                     \
    ; FLAG=1                                       \
    ; break                                        \
  ; done                                           \
 && test "$FLAG" -ne 0                             \
 && install -v -D libfingerprint.a "$PREFIX"       \
 \
 && sleep 91                                 \
 && git clone --depth=1 --recursive          \
      https://github.com/madler/zlib.git     \
 && cd                          zlib         \
 && ./configure --prefix=$PREFIX             \
      --const --static --64                  \
 && make -j$(nproc)                          \
 && make install                             \
 && git reset --hard                         \
 && git clean -fdx                           \
 && git clean -fdx                           \
 && cd ..                                    \
 && git clone --depth=1 --recursive          \
      https://github.com/akheron/jansson.git \
 && cd                           jansson     \
 && autoreconf -fi                           \
 && ./configure --prefix=$PREFIX             \
        --target=$CHOST           \
        --host=$CHOST             \
	--disable-shared                     \
	--enable-static                      \
	CPPFLAGS="$CPPFLAGS"                 \
	CXXFLAGS="$CXXFLAGS"                 \
	CFLAGS="$CFLAGS"                     \
	LDFLAGS="$LDFLAGS"                   \
        CPATH="$CPATH"                                \
        C_INCLUDE_PATH="$C_INCLUDE_PATH"              \
        OBJC_INCLUDE_PATH="$OBJC_INCLUDE_PATH"        \
        LIBRARY_PATH="$LIBRARY_PATH"                  \
        LD_LIBRARY_PATH="$LD_LIBRARY_PATH"            \
        LD_RUN_PATH="$LD_RUN_PATH"                    \
        PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"        \
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH"            \
        CC="$CC"                             \
        CXX="$CXX"                           \
        FC="$FC"                             \
        NM="$NM"                             \
        AR="$AR"                             \
        RANLIB="$RANLIB"                     \
        STRIP="$STRIP"                       \
 && make -j$(nproc)                          \
 && make install                             \
 && git reset --hard                         \
 && git clean -fdx                           \
 && git clean -fdx                           \
 && cd ..                                    \
 && cd $PREFIX                               \
 && rm -rf etc man share ssl

#FROM scratch as squash
#COPY --from=builder / /
#RUN chown -R tor:tor /var/lib/tor
#SHELL ["/usr/bin/bash", "-l", "-c"]
#ARG TEST
#
#FROM squash as test
#ARG TEST
#RUN tor --verify-config \
# && sleep 127           \
# && xbps-install -S     \
# && exec true || exec false
#
#FROM squash as final
#
