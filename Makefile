#========================================================================
#	Makefile for MOTOS
#			Written by Igarashi
#========================================================================
#========================================================================
#	再アセンブルには、以下のツールが必要です。
#		make.x			SHARP/Hudson
#		has060.x		Y.Nakamura/M.Kamada
#		hlk.x			SALT
#	make.xはGNU makeも使用できます。
#	doscall.macは、LIBC付属のものを使用しています。XCのものを使用す
#	る場合、motos.sおよびmkmotos.sのDOSコール部分を修正する必要があ
#	ります。
#========================================================================

.phony: all

all: motos.x mkmotos.x

%.x: %.o
	hlk $< -o $@
%.o: %.s
	has060 $< -o $@

motos.o: motos.s
mkmotos.o: mkmotos.s

