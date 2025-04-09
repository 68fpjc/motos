# motos.x

## これはなに？

X68000 版『MOTOS』を Human68k から起動するツールです。黒歴史として公開します。

以下は、当時のアーカイブに同梱されていた motos.doc です。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

		       「MOTOS」をＸファイル化！
				motos.x
			Copyright 1998 Igarashi

───────────────────────────────────
━━━━━━
これはなに？
──────
　ズバリ、「MOTOS」(Copyright 1985 NAMCO, 1989 DEMPA)をＸ形式実行ファイ
ルにして、Human68kから実行できるようにするためのツールです。WINDOWSでも
「MOTOS」が遊べる時代にいまさら、と思う方もいるでしょうが、作ってしまっ
たものは仕方がありません。

━━━
使い方
───
　まず、「MOTOS」のマスターディスクをドライブ０に挿入し、mkmotos.xを実行
してください。ディスクを読み込んで、カレントディレクトリにデータファイル
を作成します。正常終了すれば、以下の15ファイルが作成されるはずです。

	BGD001	BGD002	BGD003	M1EXDT	MANPRG	MUSD00	MUSD01	MUSD02
	MUSD03	MUSD04	PCMDAT	ROMIMG	SPDATA	SYSTEM	TTLGRH

　これらのファイルがカレントディレクトリにある状態で、「MOTOS」マスター
ディスクをドライブ０に挿入し (キーディスクプロテクトのため)、motos.xを実
行してください。

━━━━
付加機能
────
●SHIFT+DELでDOS復帰できます。

●motos.x実行時に-r1オプションをつけると384*256の画面モードで起動します。

●高クロックマシンで動作させる場合は、-mオプションを付加してください。こ
れにより、FM音源へのアクセス時にウェイトを挿入します。ただしMIDIに関して
は対処していません。理由は、パッチ箇所が多すぎて、ほとんどミュージックド
ライバの書き直しになってしまいそうだったからです。すみません。

━━━━━━
実行時の注意
──────
●motos.x実行時、「バージョンが違うようです」というメッセージが表示され
た場合は、あきらめてください。また、mkmotos.xが出力するファイルが足りな
かったり、ファイル名が違ったりした場合も、別バージョンの可能性があります。

●motos.x起動時にキーディスクを挿入していなかった場合、その後あわててディ
スクを挿入しても手遅れです。一旦、SHIFT+DELでHuman68kに戻ってからやり直
してください。対処はできるのですが、あえてそのままにしてあります。

●グラフィックRAMをRAMディスクなどに使用している場合、motos.xを実行でき
ません。強制的に実行する場合は-gオプションをつけてください。

●motos.x実行時には800Kバイト弱の空きメモリが必要です。

●作者はX68030(無改造)でのみ動作確認をしています。また、作者はSC-88しか
所有していないので、MIDI関連のチェックは十分ではありません。

━━━━━━
その他の注意
──────
●例によって、ナムコや電波新聞社とは関係なく作成されたプログラムですので、
各社への問い合わせはご遠慮願います。

●例によって、無保証です。各自の責任において使用してください。

●例によって、このプログラムはフリーソフトウェアとします。配布は自由です。
ただし、mkmotos.xによって出力されたファイル群はフリーではありませんので
注意してください。


						    Aug 12 1998 いがらし
```

## 連絡先

https://github.com/68fpjc/motos
