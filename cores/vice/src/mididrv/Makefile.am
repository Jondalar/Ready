# Makefile.am for `libmididrv.a'.

AM_CPPFLAGS = \
	@VICE_CPPFLAGS@ \
	@ARCH_INCLUDES@ \
	-I$(top_srcdir)/src/arch/shared \
	-I$(top_builddir)/src \
	-I$(top_srcdir)/src

AM_CFLAGS = @VICE_CFLAGS@

AM_CXXFLAGS = @VICE_CXXFLAGS@

noinst_LIBRARIES = libmididrv.a

libmididrv_a_SOURCES = \
	midi-osx-drv.c \
	midi-unix-drv.c \
	midi-win32-drv.c
