---
title: Elixir で M5Stack CoreMP135 の液晶ディスプレイに図形を描く
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack", "framebuffer"]
---

# 本稿について

本稿では Elixir ライブラリ [image](https://github.com/elixir-image/image) を用いて M5Stack CoreMP135（以下、「CoreMP135」と呼ぶ）の液晶ディスプレイ（LCD）上に図形を描く方法について解説します。

拙稿 [Elixir を M5Stack CoreMP135 上で動かす](https://zenn.dev/tkrd/articles/elixir-on-m5stack-core-mp135) の内容に沿って Elixir を CoreMP135 にインストールしてあることが本稿の前提条件です。

# Elixir スクリプト

次に示すのは、私が作成した Elixir スクリプト `draw_circles.exs` です。

```elixir
Mix.install([
  {:image, "~> 0.54"}
])

import Bitwise

fb_width = 320
fb_height = 240

img = Image.new!(fb_width, fb_height)

img =
  img
  |> Image.Draw.circle!(160, 120, 50, color: "#0000ff")
  |> Image.Draw.circle!(200, 160, 20, color: "#ff0000")
  |> Image.Draw.circle!(120, 150, 30, color: "#00ff00")

{:ok, data} = Vix.Vips.Image.write_to_binary(img)

pixels =
  for <<r::8, g::8, b::8 <- data>> do
    r = r >>> 3
    g = g >>> 3
    b = b >>> 3
    <<a, b>> = <<r::5, g::6, b::5>>
    <<b, a>>
  end

data = :erlang.list_to_bitstring(pixels)

File.open("/dev/fb1", [:binary, :write], fn file ->
  IO.binwrite(file, data)
end)
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir draw_circles.exs` コマンドで実行すると、LCD の表示が次のように変化します。

![LCD](/images/articles/elixir-on-core-mp135-framebuffer-2/lcd-2.jpg)

写真映りのせいで左下の円板が白く見えますが、実際には緑色です。

# ソースコードの解説

5 行目をご覧ください。

```elixir
import Bitwise
```

ビット操作演算子 `>>>` を使用するために `Bitwise` モジュールをインポートしています。

9 行目をご覧ください。

```elixir
{:ok, img} = Image.new(fb_width, fb_height)
```

関数 [Image.new!/3](https://hexdocs.pm/image/Image.html#new!/3) を用いて、幅 320px、高さ 240px のキャンバスを作成しています。変数 `img` には、構造体 `%Vix.Vips.Image{}` がセットされます。

12-16 行をご覧ください。

```elixir
img =
  img
  |> Image.Draw.circle!(160, 120, 50, color: "#0000ff")
  |> Image.Draw.circle!(200, 160, 20, color: "#ff0000")
  |> Image.Draw.circle!(120, 150, 30, color: "#00ff00")
```

関数 [Image.Draw.circle!/5](https://hexdocs.pm/image/Image.Draw.html#circle!/5) を用いて、キャンバス上に 3 種類の円板を描いています。第 2 引数に中心の X 座標、第 3 引数に中心の Y 座標、第 4 引数に円の半径、第 5 引数は省略可能なオプションです。`color` オプションには `#rrggbb` 形式で色を指定しています。

18 行目をご覧ください。

```elixir
{:ok, data} = Vix.Vips.Image.write_to_binary(img)
```

関数 [Vix.Vips.Image.write_to_binary/1](https://hexdocs.pm/vix/0.30.0/Vix.Vips.Image.html#write_to_binary/1) を用いて、構造体 `%Vix.Vips.Image{}` をバイナリデータに変換しています。

このバイナリデータは、1 個のピクセルを 3 バイト（24 ビット）で表します。第 1 バイトが赤、第 2 バイトが緑、第 3 バイトが緑の値を表します。

20-27 行をご覧ください。

```elixir
pixels =
  for <<r::8, g::8, b::8 <- data>> do
    r = r >>> 3
    g = g >>> 3
    b = b >>> 3
    <<a, b>> = <<r::5, g::6, b::5>>
    <<b, a>>
  end
```

バイナリデータを CoreMP135 のフレームバッファに適合するピクセルデータのリストに変換しています。`<<r::8, g::8, b::8 <- data>>` は、`data` の先頭から 3 バイトずつを順に取り出して、1 バイトずつの 3 個の断片を変数 `r`, `g`, `b` にセットしています。

23 行目の `r = r >>> 3` はビット操作演算子 [>>>](https://hexdocs.pm/elixir/Bitwise.html#%3E%3E%3E/2) を利用して 3 ビット右にシフトしています。これにより 24 ビットで表現されるフルカラーのピクセルデータが、16 ビットのピクセルデータに変換されます。例えば、ビットストリング `11001110` は `00011001` に変換されます。

25 行目以降のコードに関しては、[Elixir で M5Stack CoreMP135 の液晶ディスプレイに色を塗る](https://zenn.dev/tkrd/articles/elixir-on-core-mp135-framebuffer-1) を参照してください。

# 備考

* 当初、本稿は「Elixir で CoreMP135 のフレームバッファを操作する②」というタイトルで公開されました。

# 参考文献

* [Elixir Image で図形・文字描画](https://qiita.com/RyoWakabayashi/items/54e92be2e134e0fde0f5) @RyoWakabayashi
* [Elixir Comprehensions(内包表記) Bitstring generators](https://qiita.com/tbpgr/items/ffb710f9d212ab930a40) @tbpgr
