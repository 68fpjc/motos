*========================================================================
*	motos.s
*			Written by Igarashi
*========================================================================
		.cpu	68000
*========================================================================
		.include	doscall.mac
		.include	iocscall.mac
*========================================================================
SIZEofSYSTEM	equ	$08000
SIZEofSPDATA	equ	$08000
SIZEofBGD001	equ	$02000
SIZEofBGD002	equ	$02000
SIZEofBGD003	equ	$04000
SIZEofMUSD01	equ	$08000
SIZEofMUSD02	equ	$08000
SIZEofMUSD03	equ	$08000
SIZEofMUSD04	equ	$08000
SIZEofM1EXDT	equ	$0a000
SIZEofPCMDAT	equ	$3e000
SIZEofWORK2	equ	$10000
SIZEofMANPRG	equ	$18000
SIZEofROMIMG	equ	$08000
SIZEofWORK1	equ	$10000		*???
SIZEofMUSD00	equ	5786		*これと
SIZEofTTLGRH	equ	3350		* これはアラインしなくていいらしい

		.offset	0
SYSTEM:		.ds.b	SIZEofSYSTEM
SPDATA:		.ds.b	SIZEofSPDATA
BGD001:		.ds.b	SIZEofBGD001
BGD002:		.ds.b	SIZEofBGD002
BGD003:		.ds.b	SIZEofBGD003
MUSD01:		.ds.b	SIZEofMUSD01
MUSD02:		.ds.b	SIZEofMUSD02
MUSD03:		.ds.b	SIZEofMUSD03
MUSD04:		.ds.b	SIZEofMUSD04
M1EXDT:		.ds.b	SIZEofM1EXDT
PCMDAT:		.ds.b	SIZEofPCMDAT
WORK2:		.ds.b	SIZEofWORK2
MANPRG:		.ds.b	SIZEofMANPRG
ROMIMG:		.ds.b	SIZEofROMIMG
WORK1:		.ds.b	SIZEofWORK1
MUSD00:		.ds.b	SIZEofMUSD00
TTLGRH		.ds.b	SIZEofTTLGRH
SIZEofMOTOSBUF:
		.text
*========================================================================
NSAVE		equ	33
*========================================================================
CHKCPU		macro	dreg
		moveq.l	#1,dreg
		.cpu	68020
		and.b	*-3(pc,dreg.w*2),dreg
		.cpu	68000
		.endm
*========================================================================
		.text
		.even
*========================================================================
entry:
		lea.l	motos_stack(pc),sp

		pea.l	title(pc)
		DOS	__PRINT
		addq.l	#4,sp

		move.l	#bottom,d0
		addi.l	#$0000ffff,d0
		clr.w	d0
		movea.l	d0,a5		*a5.l = MOTOSBUF 先頭アドレス

		movea.l	a0,a4		*a4 = PSP
		bsr	chkopt

		btst.l	#1,d7
		bne	@f
		moveq.l	#0,d1
		moveq.l	#-1,d2
		IOCS	__TGUSEMD
		tst.b	d0
		beq	@f
		subq.b	#3,d0
		bne	gerror
@@:
		bsr	fread
		bsr	patch1
		bsr	patch2
		bsr	patch3

		bsr	flushcache

		pea.l	0.w
		DOS	__SUPER
		addq.l	#4,sp
		move.l	d0,sspbuf

		bsr	savecon

		move.w	sr,-(sp)
		ori.w	#$0700,sr
		bsr	savevec
		bsr	chgvec
		bsr	saveMFP
		move.w	(sp)+,sr

		moveq.l	#$90,d7		*instead of __BOOTINF
		jmp	SYSTEM(a5)
*------------------------------------------------------------------------
retn:				*キー入力割り込みの途中なんだけど…激ヤバ？
		ori.w	#$0700,sr

		lea.l	motos_stack(pc),sp

		lea.l	$e88000,a0
		bclr.b	#5,$07(a0)		*IERA	Timer-A禁止
		bclr.b	#3,$09(a0)		*IERB	OPM Timer禁止
		bclr.b	#5,$13(a0)		*IMRA	Timer-Aマスク
		bclr.b	#3,$15(a0)		*IMRB	OPM Timerマスク
		clr.b	$19(a0)			*TACR	いちおう

		bsr	stopsnd

		bsr	rstrvec
		bsr	rstrMFP

		bsr	rstrcon

		move.l	sspbuf(pc),-(sp)
		move.l	sp,usp
		DOS	__SUPER
		addq.l	#4,sp

		DOS	__EXIT
*------------------------------------------------------------------------
nomemory:	lea.l	nomemmes(pc),a0
		bra	errorexit
rerror:		lea.l	rerrmes(pc),a0
		bra	errorexit
openerror:	lea.l	rerrmes(pc),a0
		bra	errorexit
vererror:	lea.l	vererrmes(pc),a0
		bra	errorexit
gerror:		lea.l	gerrmes(pc),a0
		bra	errorexit
usage:		lea.l	usgmes(pc),a0
errorexit:
		move.w	#2,-(sp)	*STDERR
		pea.l	(a0)
		DOS	__FPUTS
		addq.l	#6,sp

		move.w	#1,-(sp)
		DOS	__EXIT2
*------------------------------------------------------------------------
saveMFP:
		lea.l	$e88000,a0
		lea.l	mfpbuf(pc),a1
		move.b	$07(a0),(a1)+		*IERA
		move.b	$09(a0),(a1)+		*IERB
		move.b	$13(a0),(a1)+		*IMRA
		move.b	$15(a0),(a1)+		*IMRB
		move.b	$19(a0),(a1)+		*TACR
		move.b	$1f(a0),(a1)+		*TADR
		rts
rstrMFP:
		lea.l	$e88000,a0
		lea.l	mfpbuf(pc),a1
		move.b	(a1)+,$07(a0)		*IERA
		move.b	(a1)+,$09(a0)		*IERB
		move.b	(a1)+,$13(a0)		*IMRA
		move.b	(a1)+,$15(a0)		*IMRB
		move.b	(a1)+,$19(a0)		*TACR
		move.b	(a1)+,$1f(a0)		*TADR
		rts
*------------------------------------------------------------------------
stopsnd:
		move.w	#$0100,d0	*MIDIがキーオフしないので
		trap	#1		*BGM停止はYODEL DOSに任せる

		moveq.l	#$14,d1		*OPMタイマ停止
		moveq.l	#0,d2		*
		IOCS	__OPMSET	*}

		moveq.l	#$08,d1		*SEは自前でキーオフ
		moveq.l	#8-1,d2		*
@@:		IOCS	__OPMSET	*
		dbra	d2,@b		*}

		bset.b	#4,$e840c7	*DMAC3 CCR	ADPCM停止
		rts
*------------------------------------------------------------------------
savecon:
		IOCS	__MS_CUROF	*マウスカーソル消去
*		moveq.l	#0,d1		*ソフトキーボード消去
*		IOCS	__SKEY_MOD	*}

		moveq.l	#0,d1		*グラフィック画面・テキスト画面使用中
		moveq.l	#2,d2		*
		IOCS	__TGUSEMD	*
		moveq.l	#1,d1		*
*		moveq.l	#2,d2		*
		IOCS	__TGUSEMD	*}

		IOCS	__B_SFTSNS	*LED取得
		move.w	d0,ledbuf	*}

		pea.l	$0010ffff	*画面モード取得
		DOS	__CONCTRL	*(sp).w = 16, 2(sp).w = -1
		addq.l	#4,sp		*
		move.w	d0,crtmodbuf	*}

		rts
*------------------------------------------------------------------------
rstrcon:
		move.w	#$01f0,$e8002a	*テキストクリア
		lea.l	$e00000,a0	*
		moveq.l	#0,d0		*
		move.w	#1024-1,d1	*
1:		move.w	#128-1,d2	*
2:		move.w	d0,(a0)+	*
		dbra	d2,2b		*
		dbra	d1,1b		*}

		bclr.b	#1,$e8e007	*for screen mode 384*256

		move.w	crtmodbuf(pc),-(sp)	*画面モード復帰
		move.w	#16,-(sp)		*
		DOS	__CONCTRL		*
		addq.l	#4,sp			*}
		move.w	#17,-(sp)		*カーソル表示
		DOS	__CONCTRL		*
		addq.l	#2,sp			*}

		move.b	ledbuf+1(pc),d1
		moveq.l	#$06,d0		*__LEDCTRL
		trap	#15
		moveq.l	#$07,d0		*__LEDSET
		trap	#15

		moveq.l	#0,d1		*グラフィック画面・テキスト画面解放
		moveq.l	#3,d2		*
		IOCS	__TGUSEMD	*
		moveq.l	#1,d1		*
*		moveq.l	#3,d2		*
		IOCS	__TGUSEMD	*}

		moveq.l	#-1,d1		*ソフトキーボード自動制御
		IOCS	__SKEY_MOD	*}

		rts
*------------------------------------------------------------------------
savevec:
		lea.l	vecnotbl(pc),a0
		lea.l	vecbuf(pc),a1

		moveq.l	#NSAVE-1,d1
		clr.w	-(sp)
@@:		move.b	(a0)+,1(sp)
		DOS	__INTVCG
		move.l	d0,(a1)+
		dbra	d1,@b
		addq.l	#2,sp

		rts
*------------------------------------------------------------------------
chgvec:
		pea.l	trap04entry(pc)
		move.w	#$24,-(sp)
		DOS	__INTVCS
		addq.l	#6,sp
		rts
*------------------------------------------------------------------------
trap04entry:			*not for 68000
		addq.l	#8,sp
		move.w	(sp)+,sr
		rts
*------------------------------------------------------------------------
rstrvec:
.if 0
		lea.l	vecnotbl(pc),a0
		lea.l	vecbuf(pc),a1

		moveq.l	#NSAVE-1,d1
		subq.l	#6,sp
		clr.w	(sp)
@@:		move.l	(a1)+,2(sp)
		move.b	(a0)+,1(sp)
		DOS	__INTVCS
		dbra	d1,@b
		addq.l	#6,sp
.else
		lea.l	vecnotbl(pc),a2
		lea.l	vecbuf(pc),a3

		moveq.l	#NSAVE-1,d2
		clr.w	d1
@@:		move.b	(a2)+,d1
		move.l	(a3)+,a1
		IOCS	__B_INTVCS
		dbra	d2,@b
.endif
		rts
*------------------------------------------------------------------------
fread:
		movea.l	a5,a0
		adda.l	#SIZEofMOTOSBUF,a0
		cmpa.l	8(a4),a0	*pspMEMEND
		bhi	nomemory

		lea.l	freadtbl(pc),a1
		bra	freadnext
freadlp:	movem.l	(a1)+,d1-d3
		clr.w	-(sp)
		move.l	d1,-(sp)
		DOS	__OPEN
		addq.l	#6,sp
		move.l	d0,d4
		bmi	openerror
		move.l	d3,-(sp)
		pea.l	0(a5,d2.l)
		move.w	d4,-(sp)
		DOS	__READ
		lea.l	10(sp),sp
		tst.l	d0
		bmi	rerror
		move.w	d4,-(sp)
		DOS	__CLOSE
		addq.l	#2,sp
freadnext:	tst.l	(a1)
		bne	freadlp
		rts
*------------------------------------------------------------------------
freadtbl:	.dc.l	fn00,SYSTEM,SIZEofSYSTEM
		.dc.l	fn01,SPDATA,SIZEofSPDATA
		.dc.l	fn02,BGD001,SIZEofBGD001
		.dc.l	fn03,BGD002,SIZEofBGD002
		.dc.l	fn04,BGD003,SIZEofBGD003
		.dc.l	fn05,MUSD01,SIZEofMUSD01
		.dc.l	fn06,MUSD02,SIZEofMUSD02
		.dc.l	fn07,MUSD03,SIZEofMUSD03
		.dc.l	fn08,MUSD04,SIZEofMUSD04
		.dc.l	fn09,M1EXDT,SIZEofM1EXDT
		.dc.l	fn10,PCMDAT,SIZEofPCMDAT
		.dc.l	fn11,MANPRG,SIZEofMANPRG
		.dc.l	fn12,ROMIMG,SIZEofROMIMG
		.dc.l	fn13,MUSD00,SIZEofMUSD00
		.dc.l	fn14,TTLGRH,SIZEofTTLGRH
		.dc.l	0

fn00:		.dc.b	'SYSTEM',0
fn01:		.dc.b	'SPDATA',0
fn02:		.dc.b	'BGD001',0
fn03:		.dc.b	'BGD002',0
fn04:		.dc.b	'BGD003',0
fn05:		.dc.b	'MUSD01',0
fn06:		.dc.b	'MUSD02',0
fn07:		.dc.b	'MUSD03',0
fn08:		.dc.b	'MUSD04',0
fn09:		.dc.b	'M1EXDT',0
fn10:		.dc.b	'PCMDAT',0
fn11:		.dc.b	'MANPRG',0
fn12:		.dc.b	'ROMIMG',0
fn13:		.dc.b	'MUSD00',0
fn14:		.dc.b	'TTLGRH',0

		.even
*------------------------------------------------------------------------
chkopt:
		moveq.l	#0,d7
		addq.l	#1,a2
optlp:		move.b	(a2)+,d0
		beq	optretn
		cmpi.b	#' ',d0
		beq	optlp
		cmpi.b	#'	',d0
		beq	optlp
		cmpi.b	#'-',d0
		bne	usage
		moveq.l	#$20,d0
		or.b	(a2)+,d0
		cmpi.b	#'r',d0
		beq	ropt
		cmpi.b	#'g',d0
		beq	gopt
		cmpi.b	#'m',d0
		beq	mopt
		bra	usage
ropt:		move.b	(a2)+,d0
		cmpi.b	#'0',d0
		beq	ropt0
		cmpi.b	#'1',d0
		beq	ropt1
		bra	usage
ropt0:		bclr.l	#0,d7
		bra	optlp
ropt1:		bset.l	#0,d7
		bra	optlp
gopt:		bset.l	#1,d7
		bra	optlp
mopt:		bset.l	#2,d7
		bra	optlp
optretn:	rts
*------------------------------------------------------------------------
*	MPUキャッシュのフラッシュ
*		in:	none
*		out:	none
*		broken:	none
*------------------------------------------------------------------------
flushcache:
SAVREGS		reg	d0/d1
		movem.l	SAVREGS,-(sp)
		CHKCPU	d0
		beq	@f
		moveq.l	#3,d1		*flush
		moveq.l	#$ac,d0		*SYS_STAT
		trap	#15
@@:		movem.l	(sp)+,SAVREGS
		rts
*------------------------------------------------------------------------
patch1:
		CHKCPU	d0
		beq	nortepatch
		lea.l	pattbl0(pc),a0
		move.w	#$4e44,d0
		move.w	#$4e73,d1
		bsr	patch_short	*rte -> trap #4
					*「ストライダー飛竜」の030パッチで
					*使われていた技
					*040や060では動くのだろうか？
nortepatch:
		lea.l	pattbl1(pc),a0
		move.w	#$4e75,d0
		move.w	#$48e7,d1
		bsr	patch_short		*movem -> rts

		lea.l	pattbl2(pc),a0
		move.w	#$4e71,d0
		move.w	#$4250,d1
		bsr	patch_short		*clr.w (a0) -> nop

		lea.l	pattbl_stack(pc),a0	*スタック
		move.l	#motos_stack,d0		*
		move.l	#$004000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_spdata(pc),a0	*SPDATA
		move.l	a5,d0			*
		addi.l	#SPDATA,d0		*
		move.l	#$018000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_bgd001(pc),a0	*BGD001
		move.l	a5,d0			*
		addi.l	#BGD001,d0		*
		move.l	#$020000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_bgd002(pc),a0	*BGD002
		move.l	a5,d0			*
		addi.l	#BGD002,d0		*
		move.l	#$022000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_bgd003(pc),a0	*BGD003
		move.l	a5,d0			*
		addi.l	#BGD003,d0		*
		move.l	#$024000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_ttlgrh(pc),a0	*TTLGRH
		move.l	a5,d0			*
		addi.l	#TTLGRH,d0		*
		move.l	#$028000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_musd01(pc),a0	*MUSD01
		move.l	a5,d0			*
		addi.l	#MUSD01,d0		*
		move.l	#$028000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_musd02(pc),a0	*MUSD02
		move.l	a5,d0			*
		addi.l	#MUSD02,d0		*
		move.l	#$030000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_musd03(pc),a0	*MUSD03
		move.l	a5,d0			*
		addi.l	#MUSD03,d0		*
		move.l	#$038000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_musd04(pc),a0	*MUSD04
		move.l	a5,d0			*
		addi.l	#MUSD04,d0		*
		move.l	#$040000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_m1exdt(pc),a0	*M1EXDT
		move.l	a5,d0			*
		addi.l	#M1EXDT,d0		*
		move.l	#$048000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_musd00(pc),a0	*MUSD00
		move.l	a5,d0			*
		addi.l	#MUSD00,d0		*
		move.l	#$048010,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_pcmdat(pc),a0	*PCMDAT
		move.l	a5,d0			*
		addi.l	#PCMDAT,d0		*
		move.l	#$052000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl3(pc),a0		*TTLGRH展開バッファ (らしい)
		move.l	a5,d0			* オリジナルではPCM用バッファを
		addi.l	#WORK1,d0		* 使用しているが、都合によりWORK1を使用
		move.l	#$052000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_manprg(pc),a0	*MANPRG
		move.l	a5,d0			*
		addi.l	#MANPRG,d0		*
		move.l	#$0a0000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_work2(pc),a0	*WORK2
		move.l	a5,d0			*
		addi.l	#WORK2,d0		*
		move.l	#$090000,d1		*
		bsr	patch_long		*}

		lea.l	pattbl_work1(pc),a0	*WORK1
		move.l	a5,d0			*
		addi.l	#WORK1,d0		*
		move.l	#$0c0000,d1		*
		bsr	patch_long		*}

		bsr	patch_special

		rts

patch_special:
		lea.l	pattbl_sp1(pc),a0
		move.l	a5,d0
		addi.l	#WORK1,d0
		swap.w	d0
		move.l	#.highw.$0c0000,d1
		bra	2f
1:		cmp.w	0(a5,d2.l),d1
		bne	vererror
		move.w	(a0)+,d3
		cmp.w	2(a5,d2.l),d3
		bne	vererror
		move.w	d0,0(a5,d2.l)
2:		move.l	(a0)+,d2
		bne	1b

		lea.l	pattbl_sp2(pc),a0
		movea.l	a5,a1
		adda.l	#MANPRG+$0079fa,a1
*		move.l	a5,d0
*		addi.l	#WORK1,d0
*		swap.w	d0
*		move.l	#.highw.$0c0000,d1
		bra	4f
3:		cmp.w	2(a1),d1
		bne	vererror
		move.w	d0,(a1)
		addq.l	#4,a1
4:		move.w	(a0)+,d1
		bne	3b

		rts
*------------------------------------------------------------------------
patch2:				*DOS復帰パッチ
		lea.l	pattbl4(pc),a0
		move.w	#$7007,d0
		move.w	#$7006,d1
		bsr	patch_short
		lea.l	pattbl5(pc),a0
		move.w	#$4ef9,d0
		move.w	#$b03c,d1
		bsr	patch_short
		lea.l	pattbl6(pc),a0
		move.l	#chkexitkey,d0
		move.l	#$000666f2,d1
		bsr	patch_long	*-> jmp chkexitkey.l

		move.l	a5,d0
		addi.l	#SYSTEM+$04b8,d0
		move.l	d0,selfpat+2

		rts
chkexitkey:
		cmpi.b	#$01,d0
		beq	chkiocs		*SHIFT+DEL
		cmpi.b	#$06,d0
		bne	nojob
selfpat:	jmp	0.l		*SHIFT+CTRL+DEL -> reset
chkiocs:	cmpi.w	#-1,$0a0e.w	*ほとんどあり得ないけど
		beq	retn		*IOCSコール発行中か調べてみる
nojob:		rts
*------------------------------------------------------------------------
patch3:				*オプションによるパッチ
				*画面モード
		btst.l	#0,d7
		beq	@f
		lea.l	pattbl7(pc),a0
		move.w	#$4e71,d0
		move.w	#$5250,d1
		bsr	patch_short	*addq.w #1,(a0) -> nop
		lea.l	pattbl8(pc),a0
		move.w	#$0001,d0
		move.w	#$0000,d1
		bsr	patch_short	*CRT MODE
@@:
				*ミュージックドライバにウェイトを挿入
		btst.l	#2,d7
		beq	@f
		lea.l	pattbl9(pc),a0
		move.w	#$4eb9,d0
		move.w	#$13c2,d1
		bsr	patch_short
		lea.l	pattbl10(pc),a0
		move.l	#setopm,d0
		move.l	#$00e90003,d1
		bsr	patch_long	*move.b d2,$e90003 -> jsr setopm.l
		lea.l	pattbl11(pc),a0
		move.w	#$4eb9,d0
		move.w	#$13c0,d1
		bsr	patch_short
		lea.l	pattbl12(pc),a0
		move.l	#setopm2,d0
		move.l	#$00e90003,d1
		bsr	patch_long	*move.b d0,$e90003 -> jsr setopm2.l
@@:		rts
setopm:
		tst.b	$e9a001
@@:		tst.b	$e90003
		bmi	@b
		move.b	d2,$e90003
		tst.b	$e9a001
		rts
setopm2:
		tst.b	$e9a001
@@:		tst.b	$e90003
		bmi	@b
		move.b	d0,$e90003
		tst.b	$e9a001
		rts
*------------------------------------------------------------------------
patch_short0:
		cmp.w	0(a5,d2.l),d1
		bne	vererror
		move.w	d0,0(a5,d2.l)
patch_short:	move.l	(a0)+,d2
		bne	patch_short0
		rts

patch_long0:
		cmp.l	0(a5,d2.l),d1
		bne	vererror
		move.l	d0,0(a5,d2.l)
patch_long:	move.l	(a0)+,d2
		bne	patch_long0
		rts
*------------------------------------------------------------------------
pattbl0:	.dc.l	SYSTEM+$0003f2,SYSTEM+$000400,SYSTEM+$00067e
		.dc.l	SYSTEM+$0007ea,SYSTEM+$000804,SYSTEM+$000952
		.dc.l	SYSTEM+$000956,SYSTEM+$0009fc,SYSTEM+$000ac6
		.dc.l	SYSTEM+$000b28,SYSTEM+$000b64,SYSTEM+$00139e
		.dc.l	SYSTEM+$002220,SYSTEM+$002258,SYSTEM+$0022a6
		.dc.l	SYSTEM+$0022be,SYSTEM+$0022d4,SYSTEM+$0022f8
		.dc.l	SYSTEM+$002314,SYSTEM+$002350,SYSTEM+$002362
		.dc.l	SYSTEM+$002aa0,SYSTEM+$002c92
		.dc.l	MANPRG+$00738c,MANPRG+$007408
		.dc.l	0
pattbl1:	.dc.l	SYSTEM+$000030
		.dc.l	0
pattbl2:	.dc.l	SYSTEM+$002904
		.dc.l	0
pattbl3:	.dc.l	SYSTEM+$002e1e,SYSTEM+$002e2a
		.dc.l	0
pattbl_spdata:	.dc.l	MANPRG+$73ea
		.dc.l	MANPRG+$7516
		.dc.l	MANPRG+$776e
		.dc.l	0
pattbl_bgd001:	.dc.l	MANPRG+$006b10
		.dc.l	MANPRG+$0077de
		.dc.l	0
pattbl_bgd002:	.dc.l	MANPRG+$0077e6
		.dc.l	0
pattbl_bgd003:	.dc.l	MANPRG+$0077ee
		.dc.l	0
pattbl_ttlgrh:	.dc.l	SYSTEM+$002ca4
		.dc.l	0
pattbl_manprg:	.dc.l	SYSTEM+$0028bc
		.dc.l	0
pattbl_pcmdat:	.dc.l	SYSTEM+$002958
		.dc.l	0
pattbl_musd00:	.dc.l	SYSTEM+$002f2e
		.dc.l	0
pattbl_musd01:	.dc.l	SYSTEM+$00296c,SYSTEM+$002976
		.dc.l	MANPRG+$0019a2
		.dc.l	0
pattbl_musd02:	.dc.l	SYSTEM+$002982,SYSTEM+$00298c
		.dc.l	MANPRG+$0019a6
		.dc.l	0
pattbl_musd03:	.dc.l	MANPRG+$0019aa
		.dc.l	0
pattbl_musd04:	.dc.l	MANPRG+$0019ae
		.dc.l	0
pattbl_m1exdt:	.dc.l	MANPRG+$001912,MANPRG+$00192a
		.dc.l	0
pattbl_stack:	.dc.l	MANPRG+$00001e,MANPRG+$0023d2
		.dc.l	0
pattbl_work2:	.dc.l	MANPRG+$0073a2,MANPRG+$00740c,MANPRG+$0076d0
		.dc.l	0
pattbl_work1:	.dc.l	MANPRG+$000024,MANPRG+$0000b4,MANPRG+$0003a2
		.dc.l	MANPRG+$0067ae,MANPRG+$0067d0,MANPRG+$006990
		.dc.l	0
pattbl_sp1:	.dc.l	MANPRG+$001022
		.dc.w	$a000
		.dc.l	MANPRG+$001098
		.dc.w	$bffc
		.dc.l	MANPRG+$0010c8
		.dc.w	$bffc
		.dc.l	MANPRG+$0010fe
		.dc.w	$fffc
		.dc.l	MANPRG+$001138
		.dc.w	$fffc
		.dc.l	MANPRG+$001236
		.dc.w	$bffc
		.dc.l	MANPRG+$001244
		.dc.w	$bffc
		.dc.l	MANPRG+$0026c0
		.dc.w	$dffc
		.dc.l	MANPRG+$002810
		.dc.w	$dffc
		.dc.l	0
pattbl_sp2:	.dc.w	$07dd,$07dc,$07db,$07da,$07d9,$07d8,$07d7,$07d6
		.dc.w	$07d5,$07d4,$07d3,$07d2,$07c1,$07c0,$07cf,$07ce
		.dc.w	$07cd,$07cc,$07cb,$07ca,$07c9,$07c8,$07c7,$07c6
		.dc.w	$07c5,$07c4,$07c3,$07c2,$07fd,$07fc,$07fb,$07fa
		.dc.w	$07f9,$07f8,$07f7,$07f6,$07f5,$07f4,$07f3,$07f2
		.dc.w	$07e1,$07e0,$07ef,$07ee,$07ed,$07ec,$07eb,$07ea
		.dc.w	$07e9,$07e8,$07e7,$07e6,$07e5,$07e4,$07e3,$07e2
		.dc.w	$039f,$039e,$035f,$035e,$031f,$031e,$02df,$02de
		.dc.w	$029f,$029e,$025f,$025e,$021f,$021e,$01df,$01de
		.dc.w	$019f,$019e,$037f,$037e,$033f,$033e,$02ff,$02fe
		.dc.w	$02bf,$02be,$027f,$027e,$023f,$023e,$01ff,$01fe
		.dc.w	$01bf,$01be,$017f,$017e,$07bc,$079c,$07ba,$079a
		.dc.w	$07b8,$0798,$07b6,$0796,$07b4,$0794,$07b2,$0792
		.dc.w	$07a0,$0780,$07ae,$078e,$07ac,$078c,$07bb,$079b
		.dc.w	$07b9,$0799,$07b7,$0797,$07b5,$0795,$07b3,$0793
		.dc.w	$07b1,$0791,$079f,$079f,$07ad,$078d,$07ab,$078b
		.dc.w	0
pattbl4:	.dc.l	SYSTEM+$0004ac
		.dc.l	0
pattbl5:	.dc.l	SYSTEM+$0004b2
		.dc.l	0
pattbl6:	.dc.l	SYSTEM+$0004b4
		.dc.l	0
pattbl7:	.dc.l	SYSTEM+$002818
		.dc.l	0
pattbl8:	.dc.l	SYSTEM+$002aa2
		.dc.l	0
pattbl9:	.dc.l	SYSTEM+$001398
		.dc.l	0
pattbl10:	.dc.l	SYSTEM+$00139a
		.dc.l	0
pattbl11:	.dc.l	SYSTEM+$001432
		.dc.l	0
pattbl12:	.dc.l	SYSTEM+$001434
		.dc.l	0
*------------------------------------------------------------------------
vecnotbl:			*パッチ箇所を増やす場合は定数NSAVEを変更すること
				*SYSTEM
		.dc.b	$02		*Bus Error
		.dc.b	$03		*Address Error
		.dc.b	$04		*Illegal Instruction
		.dc.b	$05		*Zero Divide
		.dc.b	$06		*CHK, CHK2 Instruction
		.dc.b	$07		*cpTRAPcc, TRAPcc, TRAPV Instruction
		.dc.b	$08		*Privilege Violation
		.dc.b	$09		*Trace
		.dc.b	$0a		*Line 1010 Emulator
		.dc.b	$0b		*Line 1111 Emulator
		.dc.b	$0f		*Uninitialized Interrupt
		.dc.b	$18		*Spurious Interrupt
		.dc.b	$1f		*Level7 Interrupt Auto Vector
		.dc.b	$20		*TRAP #0 Instruction
		.dc.b	$21		*TRAP #1 Instruction
		.dc.b	$22		*TRAP #2 Instruction
		.dc.b	$23		*TRAP #3 Instruction
		.dc.b	$43		*MFP OPM Timer
		.dc.b	$49		*MFP USART Tx Error
		.dc.b	$4a		*MFP USART Tx Buffer Empty
		.dc.b	$4b		*MFP USART Rx Error
		.dc.b	$4c		*MFP USART Rx Buffer Full
		.dc.b	$4d		*MFP Timer-A
		.dc.b	$6a		*DMAC Ch.3 Normal
		.dc.b	$80
		.dc.b	$82
		.dc.b	$84
		.dc.b	$86
		.dc.b	$88
		.dc.b	$8a
		.dc.b	$8c
		.dc.b	$8e
				*motos.x
		.dc.b	$24		*TRAP #4 Instruction
*------------------------------------------------------------------------
title:		.dc.b	'[37mMOTOS for X680x0[m'
		.dc.b	' modified for Human68k 1998,2001 Igarashi'
		.dc.b	$0d,$0a,0
usgmes:		.dc.b	'usage: motos [option]',$0d,$0a
		.dc.b	'	-r<num>	画面モード (0:256*256/1:384*256)',$0d,$0a
		.dc.b	'	-g	グラフィック画面を強制使用する',$0d,$0a
		.dc.b	'	-m	FM音源アクセス時にウェイトを挿入',$0d,$0a,0
nomemmes:	.dc.b	'メモリが足りません',$0d,$0a,0
openerrmes:	.dc.b	'ファイルが見つかりません',$0d,$0a,0
rerrmes:	.dc.b	'ファイルが読み込めません',$0d,$0a,0
vererrmes:	.dc.b	'バージョンが違うようです',$0d,$0a,0
gerrmes:	.dc.b	'グラフィック画面が使用中です。起動できません',$0d,$0a,0
*========================================================================
		.bss
		.even
*------------------------------------------------------------------------
ledbuf:		.ds.w	1
crtmodbuf:	.ds.w	1
uspbuf:		.ds.l	1
sspbuf:		.ds.l	1
vecbuf:		.ds.l	NSAVE
mfpbuf:		.ds.b	6
*========================================================================
		.stack
		.even
*------------------------------------------------------------------------
		.ds.l	$2800/4
motos_stack:
*========================================================================
bottom:
*========================================================================
		.end	entry

