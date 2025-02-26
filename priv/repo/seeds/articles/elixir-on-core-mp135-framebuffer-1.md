---
title: Elixir で M5Stack CoreMP135 の液晶ディスプレイに色を塗る
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack", "framebuffer"]
---

# 本稿について

本稿ではプログラミング言語 Elixir を用いて小型 Linux PC である M5Stack CoreMP135（以下、「CoreMP135」と呼ぶ）の液晶ディスプレイ（LCD）に色を塗る方法について解説します。

拙稿 [Elixir を M5Stack CoreMP135 上で動かす](https://zenn.dev/tkrd/articles/elixir-on-m5stack-core-mp135) の内容に沿って Elixir を CoreMP135 にインストールしてあることが本稿の前提条件です。

# フレームバッファとは

**フレームバッファ**とは、ビデオディスプレイの表示内容を記憶するメモリ領域のことです。

CoreMP135 の上面に備わっている 320px × 240px の LCD には `/dev/fb1` という名前のフレームバッファが対応しています。これにビットマップデータを書き込めば、LCD の表示を更新できます。

CoreMP135 の LCD の各ピクセルは、16 ビットのデータで表現されます。最初の 5 ビットが赤、次の 6 ビットが緑、最後の 5 ビットが青を表します。ただし、緑を表す 6 ビットの先頭 1 ビットは使用されません。

また、CoreMp135 のプロセッサ（Cortex-A7）がビッグエンディアンで、CoreMP135 のフレームバッファはリトルエンディアンであるため、16 ビットデータの前半 8 ビットと後半 8 ビットを入れ替える必要があります。

:::details エンディアン
複数バイトからなるデータ（ワード）をコンピュータの記憶装置に書き込む際のバイトの並び順に関する規則を**エンディアン**（endianness）と呼びます。ワードの最上位バイトを最小のアドレスに、最下位バイトを最大のアドレスに格納する規則を**ビッグエンディアン**、ワードの最上位バイトを最大のアドレスに、最下位バイトを最小のアドレスに格納する規則を**リトルエンディアン**と呼びます。
:::

# Elixir スクリプト(1)

次に示すのは、私が作成した Elixir スクリプト `paint_red.exs` です。

```elixir
fb_width = 320
fb_height = 240

<<a, b>> = <<31::5, 0::6, 0::5>>
red_pixel = <<b, a>>
pixels = List.duplicate(red_pixel, fb_width * fb_height)
data = :erlang.list_to_bitstring(pixels)

File.open("/dev/fb1", [:binary, :write], fn file ->
  IO.binwrite(file, data)
end)
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir paint_red.exs` コマンドで実行すると、LCD 全体が赤色で塗りつぶされます。

# ソースコードの解説(1)

4 行目をご覧ください。

```elixir
<<a, b>> = <<31::5, 0::6, 0::5>>
```

`<<` と `>>` は[ビットストリング](https://hexdocs.pm/elixir/binaries-strings-and-charlists.html#bitstrings)を作るための記号です。等号 `=` の右辺にある `31::5` は `011111`、`0::6` は `00000`、`0::5` は `00000` というビットストリングを作るという意味となり、全体としては `0111110000000000` というビットストリングが作られます。

等号 `=` の左辺にある `<<a, b>>` は、右辺のビットストリングの前半 8 ビットを変数 `a` に、後半 8 ビットを変数 `b` にセットするという意味になります。

5 行目をご覧ください。

```elixir
red_pixel = <<b, a>>
```

変数 `a` と `b` の値を用いてビットストリングを作っています。4 行目で作られた 16 ビットデータの前半 8 ビットと後半 8 ビットを入れ替えたものが変数 `red_pixel` にセットされます。これが赤色のピクセルデータです。

6 行目をご覧ください。

```elixir
pixels = List.duplicate(red_pixel, fb_width * fb_height)
```

関数 [List.duplicate/2](https://hexdocs.pm/elixir/1.12/List.html#duplicate/2) を用いて、76,800（320 × 240）個の同一のピクセルデータを要素とするリストを作っています。

7 行目をご覧ください。

```elixir
data = :erlang.list_to_bitstring(pixels)
```

Erlang の関数 [list_to_bitstring/1](https://erlang.org/documentation/doc-10.0/erts-10.0/doc/html/erlang.html#list_to_bitstring-1) により、ビットストリングのリストを連結して長大なビットストリングを作っています。これがビットマップデータです。

9-11 行をご覧ください。

```elixir
File.open("/dev/fb1", [:binary, :write], fn file ->
  IO.binwrite(file, data)
end)
```

関数 [File.open/3](https://hexdocs.pm/elixir/File.html#open/3) を用いてフレームバッファ `/dev/fb1` をオープンし、関数 [IO.binwrite/2](https://hexdocs.pm/elixir/IO.html#binwrite/2) を用いてビットマップデータをフレームバッファに書き込んでいます。

バイナリモードで書き込むため、関数 `File.open/3` の第 3 引数にオプション `[:binary, :write]` を指定しています。この場合、データを書き込む関数として `IO.write/2` ではなく `IO.binwrite/2` を使う必要があります。

# Elixir スクリプト(2)

次に示すのは、`paint_red.exs` を改造して作った Elixir スクリプト `paint_eight_colors.exs` です。

```elixir
fb_width = 320
fb_height = 240

pixels =
  for x <- 0..(fb_height - 1), y <- 0..(fb_width - 1) do
    {r, g, b} =
      cond do
        x < 120 && y < 80 -> {0, 0, 0}
        x < 120 && y < 160 -> {31, 0, 0}
        x < 120 && y < 240 -> {0, 31, 0}
        x < 120 -> {31, 31, 0}
        y < 80 -> {0, 0, 31}
        y < 160 -> {31, 0, 31}
        y < 240 -> {0, 31, 31}
        true -> {31, 31, 31}
      end

    <<a, b>> = <<r::5, g::6, b::5>>
    <<b, a>>
  end

data = :erlang.list_to_bitstring(pixels)

File.open("/dev/fb1", [:binary, :write], fn file ->
  IO.binwrite(file, data)
end)
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir paint_eight_colors.exs` コマンドで実行すると、LCD の表示が次のように変化します。

![LCD](/images/articles/elixir-on-core-mp135-framebuffer-1/lcd-1.jpg)

# ソースコードの解説(2)

5 行目をご覧ください。

```elixir
  for x <- 0..(fb_height - 1), y <- 0..(fb_width - 1) do
```

変数 `fb_height` と `fb_width` の値を埋め込んでしまうと、こうなります。

```elixir
  for x <- 0..319, y <- 0..239 do
```

Elixir の[リスト内包表記](https://hexdocs.pm/elixir/comprehensions.html)により、変数 `x` と `y` にビットマップのピクセルの座標をセットしながら、`do` と `end` の間のコードを評価して、リストを作り上げます。`do` と `end` の間のコードは 76,800（320 × 240）回評価されます。

6-16 行をご覧ください。

```elixir
    {r, g, b} =
      cond do
        x < 120 && y < 80 -> {0, 0, 0}
        x < 120 && y < 160 -> {31, 0, 0}
        x < 120 && y < 240 -> {0, 31, 0}
        x < 120 -> {31, 31, 0}
        y < 80 -> {0, 0, 31}
        y < 160 -> {31, 0, 31}
        y < 240 -> {0, 31, 31}
        true -> {31, 31, 31}
      end
```

変数 `x` と `y` の値から 3 個の整数の組を作って変数 `r`, `g`, `b` にセットしています。それぞれ赤、緑、青の色の値を示します。値は 0 から 31 までです。

3 個の整数の組は、それぞれ次のような色に対応しています：

* `{0, 0, 0}`: 黒
* `{31, 0, 0}`: 赤
* `{0, 31, 0}`: 緑
* `{31, 31, 0}`: 黄色
* `{0, 0, 31}`: 青
* `{31, 0, 31}`: マゼンタ
* `{0, 31, 31}`: シアン
* `{31, 31, 31}`: 白

18-19 行をご覧ください。

```elixir
    <<a, b>> = <<r::5, g::6, b::5>>
    <<b, a>>
```

`<<` と `>>` についてはすでに説明しています。`r::5` は変数 `r` の値から 5 ビットのビットストリングを作るという意味です。上記の式により 16 ビットのビットストリングができあがります。

例えば、整数の組 `{31, 31, 0}` からは `1110000011111011` というビットストリングが作られます。これは黄色のピクセルデータです。

# 備考

* 当初、本稿は「Elixir で CoreMP135 のフレームバッファを操作する①」というタイトルで公開されました。
* [Nerves LivebookでRoller485を動かしてみた](https://qiita.com/GeekMasahiro/items/d49897e7f6e746e47814) の著者 @GeekMasahiro 様よりの指摘を受けて 2024 年 10 月 5 日に本稿は大幅に改訂されました。それまで CoreMP135 のフレームバッファがリトルエンディアンであることに気づいていなかったため、本文およびソースコードに重大な誤りがありました。

# 参考文献

* [CoreMP135のLCDにPythonでCPU温度を表示](https://qiita.com/nnn112358/items/e8b806d76943ab3ee319) -- @nnn112358
* [Nerves LivebookでRoller485を動かしてみた](https://qiita.com/GeekMasahiro/items/d49897e7f6e746e47814) -- @GeekMasahiro
