---
title: "[ImageMagick] PDF ファイルの各ページを左右反転した PNG 画像に変換する"
published: true
type: tech
emoji: 🧙
topics: ["ImageMagick", "PDF", "PNG"]
---

講演会や動画撮影で使うプロンプターという機器があります。底面のモニターに映された像をガラスに投影させることで、話し手はまっすぐ前を見て原稿を読むことができます。

しかし、ひとつ注意すべき点があります。モニターには左右反転（鏡像反転）した映像を表示する必要がある、ということです。反転機能付きのプロンプターもありますが、かなり高価です。

そこで、あらかじめ左右反転した原稿を用意することを考えましょう。

原稿は PDF 形式で用意されているとします。これを PNG 形式のファイル群に変換します。

----

まず、無料のオープンソースソフトウェアである [ImageMagick](https://imagemagick.org/script/index.php) をあなたの PC にインストールしてください。インストール手順の説明は省略します。

続いて、ImageMagick の `policy.xml` を書き換えます。Linux の場合は、`/etc/ImageMagick-6` または `/etc/ImageMagick-7` の下にあります。そこに移動して、`sudo vim policy.xml` で開いてください。そして、

```xml
<policy domain="coder" rights="none" pattern="PDF" />
```

という行を探して、次のように書き換えてください。

```xml
<policy domain="coder" rights="read | write" pattern="PDF" />
```

ここまでが準備作業です。

----

カレントディレクトリに `speech_script.pdf` というファイルがあるとします。

まず、`mkdir -p speech_script` コマンドで `speech_script` ディレクトリを作成してください。

そして、次のコマンドを実行してください。

```
convert speech_script.pdf -background white -alpha remove -alpha off -flop \
  speech_script/page-%03d.png
```

これで、白背景の左右反転された画像群が `speech_script` ディレクトリの下に作られます。ファイル名は、`page-000.png`, `page-001.png`, ... となります。

PDF ファイルのページ数が 1000 を超える場合は、コマンドの `%03d` の部分を `%04d` としてください。

----

さらに画像の白黒を反転させる（黒背景に白の文字で表示させる）には、次のコマンドを実行してください。

```
convert speech_script.pdf -background black -alpha remove -alpha off -flop \
  --negate -quiet speech_script/page-%03d.png
```

:::details -quiet オプションを付ける理由
私の環境では `-negate` オプションを付けると次のような警告が出力されます。

```
convert-im6.q16: profile 'icc': 'RGB ': RGB color space not permitted on grayscale PNG
```

これは単なる警告に過ぎず、正しく白黒反転された画像が作られています。そこで `-quiet` オプションを付けて警告表示を抑制することにしました。
:::
