*========================================================================
*	mkmotos.s
*			Written by Igarashi
*========================================================================
		.cpu	68000
*========================================================================
		.include	doscall.mac
		.include	iocscall.mac
*========================================================================
		.text
		.even
*========================================================================
entry:
		lea.l	inisp(pc),sp

		lea.l	buf(pc),a6
		move.l	12(a0),d7	*pspMEMEND
		sub.l	a6,d7		*d7.l = バッファサイズ

		lea.l	dirbuf(pc),a5
		move.w	#$9070,d1
		move.l	#$03000101,d2
		move.l	#$00000800,d3
		movea.l	a5,a1
		IOCS	__B_READ
		andi.l	#$c0000000,d0
		bne	readerror
		lea.l	dirid(pc),a0
		movea.l	a5,a1
		moveq.l	#16-1,d0
@@:		cmpm.b	(a0)+,(a1)+
		dbne	d0,@b
		bne	illdisk

		bra	next
loop:
		cmp.l	d7,d6
		bhi	nomem
*		move.w	#$9070,d1
		move.w	8(a5),d2
				*トラック/セクタ→トラック/サイド/セクタ
		move.w	d2,d0
		andi.w	#$01ff,d0
		lsr.w	#8,d2
		lsr.w	#1,d2
		add.w	#$0300,d2
		swap.w	d2
		move.w	d0,d2
		move.l	d6,d3
		movea.l	a6,a1
		IOCS	__B_READ
		andi.l	#$c0000000,d0
		bne	readerror

		movea.l	a5,a0		*a0 = ファイル名先頭
		lea.l	fnbuf(pc),a1
		moveq.l	#6-1,d0
@@:		move.b 	(a0)+,(a1)+
		dbra	d0,@b

		pea.l	wmes(pc)
		DOS	__PRINT
*		addq.l	#4,sp
		pea.l	fnbuf(pc)
		DOS	__PRINT
*		addq.l	#4,sp
		pea.l	wmes2(pc)
		DOS	__PRINT
		lea.l	4+4+4(sp),sp

		move.w	#$0020,-(sp)	*ARCHIVE
		pea.l	fnbuf(pc)
		DOS	__CREATE
*		addq.l	#6,sp
		move.l	d0,d5		*d5.w = ファイルハンドル
		bmi	writeerror

		move.l	d6,-(sp)
		pea.l	(a6)
		move.w	d5,-(sp)
		DOS	__WRITE
*		lea.l	10(sp),sp
		tst.l	d0
		bmi	writeerror
		DOS	__CLOSE
		lea.l	6+10(sp),sp

		pea.l	compmes(pc)
		DOS	__PRINT
		addq.l	#4,sp

next:		lea.l	16(a5),a5
		move.l	12(a5),d6	*d6.l = ファイルサイズ
		bpl	loop

		DOS	__EXIT

readerror:	lea.l	readerrmes(pc),a0
		bra	errorexit
illdisk:	lea.l	illdiskmes(pc),a0
		bra	errorexit
nomem:		lea.l	nomemmes(pc),a0
		bra	errorexit
writeerror:	lea.l	writeerrmes(pc),a0
		bra	errorexit
errorexit:	move.w	#2,-(sp)	*STDERR
		pea.l	(a0)
		DOS	__FPUTS
		addq.l	#6,sp
		move.w	#1,-(sp)
		DOS	__EXIT2
*========================================================================
dirid:		.dc.b	'YODEL. DOS V1.00'
readerrmes:	.dc.b	'ディスクが読み込めません',$0d,$0a,0
illdiskmes:	.dc.b	'MOTOS のディスクではないようです',$0d,$0a,0
nomemmes:	.dc.b	'メモリが足りません',$0d,$0a,0
writeerrmes:	.dc.b	'ファイルが書き出せません',$0d,$0a,0
wmes:		.dc.b	'Writing ',0
wmes2:		.dc.b	' ... ',0
compmes:	.dc.b	'Completed.',$0d,$0a,0
*========================================================================
		.bss
		.even
*========================================================================
dirbuf:
		.ds.b	$800
fnbuf:		.ds.b	6+1

*========================================================================
		.stack
		.even
*========================================================================
		.ds.l	256/4
inisp:
*------------------------------------------------------------------------
buf:
*========================================================================
		.end	entry


