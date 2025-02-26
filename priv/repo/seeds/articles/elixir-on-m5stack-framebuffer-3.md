---
title: Elixir で M5Stack CoreMP135 の液晶ディスプレイにテキストを表示する
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack", "framebuffer"]
---

# 本稿について

本稿では Elixir ライブラリ [image](https://github.com/elixir-image/image) を用いて M5Stack CoreMP135（以下、「CoreMP135」と呼ぶ）の液晶ディスプレイ（LCD）上にテキストを表示する方法について解説します。

拙稿 [Elixir を M5Stack CoreMP135 上で動かす](https://zenn.dev/tkrd/articles/elixir-on-m5stack-core-mp135) の内容に沿って Elixir を CoreMP135 にインストールしてあることが本稿の前提条件です。

# Elixir スクリプト(1)

次に示すのは、私が作成した Elixir スクリプト `hello_world_on_lcd.exs` です。

```elixir
Mix.install([
  {:image, "~> 0.54"}
])

import Bitwise

defmodule CoreMP135 do
  @fb_width 320
  @fb_height 240

  def get_image() do
    text =
      Image.Text.text!(
        "Hello, world!",
        font_size: 48,
        text_fill_color: "#ffffff"
      )

    w = Vix.Vips.Image.width(text)
    h = Vix.Vips.Image.height(text)

    x = floor((@fb_width - w) / 2)
    y = floor((@fb_height - h) / 2)

    img = Image.new!(@fb_width, @fb_height)
    Image.compose!(img, text, x: x, y: y)
  end

  def write_to_framebuffer(img) do
    {:ok, data} = Vix.Vips.Image.write_to_binary(img)

    pixels =
      for <<r::8, g::8, b::8, _a::8 <- data>> do
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
  end
end

img = CoreMP135.get_image()
CoreMP135.write_to_framebuffer(img)
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir hello_world_on_lcd.exs` コマンドで実行すると、LCD の表示が次のように変化します。

![LCD](/images/articles/elixir-on-core-mp135-framebuffer-3/lcd-3.jpg)

# ソースコードの解説(1)

5 行目の `import Bitwise` の意味、34-36 行で使われている演算子 `>>>` の意味については、[Elixir で M5Stack CoreMP135 の液晶ディスプレイに図形を描く](https://zenn.dev/tkrd/articles/elixir-on-core-mp135-framebuffer-2) を参照してください。

12-17 行をご覧ください。

```elixir
    text =
      Image.Text.text!(
        "Hello, world!",
        font_size: 48,
        text_fill_color: "#ffffff"
      )
```

関数 [Image.Text.text!/2](https://hexdocs.pm/image/Image.Text.html#text!/2) を利用して、デフォルトフォントである「Helvetica」で 48 ピクセルサイズの白い「Hello, world!」というテキストの描かれた画像を生成しています。

19-23 行をご覧ください。

```elixir
    w = Vix.Vips.Image.width(text)
    h = Vix.Vips.Image.height(text)

    x = floor((@fb_width - w) / 2)
    y = floor((@fb_height - h) / 2)
```

テキストの描かれた画像の幅と高さを求め、その画像がキャンバスの中央に重ねられるように、始点座標（x, y）を計算しています。

25-26 行をご覧ください。

```elixir
    img = Image.new!(@fb_width, @fb_height)
    Image.compose!(img, text, x: x, y: y)
```

関数 [Image.compose!](https://hexdocs.pm/image/Image.html#compose!/3) を用いて CoreMP135 の液晶ディスプレイと同じ大きさの背景黒の画像（キャンバス）を作り、その上にテキストの描かれた画像を重ね合わせています。

# Elixir スクリプト(2)

次に示すのは、`hello_world_on_lcd.exs` を改造して作った Elixir スクリプト `cpu_temperatur.exs` です。CPU 温度の取り方については、[CoreMP135のLCDにPythonでCPU温度を表示](https://qiita.com/nnn112358/items/e8b806d76943ab3ee319) を参考にしました。

```elixir
Mix.install([
  {:image, "~> 0.54"}
])

import Bitwise

defmodule CoreMP135 do
  @fb_width 320
  @fb_height 240

  def get_image() do
    text =
      Image.Text.text!(
        "#{get_cpu_temperature()}°C",
        font_size: 48,
        text_fill_color: "#ffffff"
      )

    w = Vix.Vips.Image.width(text)
    h = Vix.Vips.Image.height(text)

    x = floor((@fb_width - w) / 2)
    y = floor((@fb_height - h) / 2)

    img = Image.new!(@fb_width, @fb_height)
    Image.compose!(img, text, x: x, y: y)
  end

  defp get_cpu_temperature() do
    {cpu_temp, _} =
      "/sys/class/thermal/thermal_zone0/temp"
      |> File.read!()
      |> Integer.parse()

    :erlang.float_to_binary(cpu_temp / 1000.0, decimals: 1)
  end

  def write_to_framebuffer(img) do
    {:ok, data} = Vix.Vips.Image.write_to_binary(img)

    pixels =
      for <<r::8, g::8, b::8, _a::8 <- data>> do
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
  end

  def main() do
    image = get_image()
    write_to_framebuffer(image)
    Process.sleep(1000)
    main()
  end
end

CoreMP135.main()
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir cpu_temperature.exs` コマンドで実行すると、LCD の表示が次のように変化し、1 秒ごとに温度表示が更新されていきます。

![LCD](/images/articles/elixir-on-core-mp135-framebuffer-3/lcd-4.jpg)

スクリプトを停止するには、ターミナル上で `Ctrl+C` を 2 回入力してください。

# ソースコードの解説(2)

29-36 行をご覧ください。

```elixir
  defp get_cpu_temperature() do
    {cpu_temp, _} =
      "/sys/class/thermal/thermal_zone0/temp"
      |> File.read!()
      |> Integer.parse()

    :erlang.float_to_binary(cpu_temp / 1000.0, decimals: 1)
  end
```

ファイル `/sys/class/thermal/thermal_zone0/temp` の内容を読み取ると、摂氏で測った CPU 温度に 1000 を掛けた値が取れます。関数 [Integer.parse/2](https://hexdocs.pm/elixir/1.17.3/Integer.html#parse/2) で整数に変換し、1000.0 で割ってから、Erlang の関数 [float_to_binary/2](https://www.erlang.org/doc/apps/erts/erlang.html#float_to_binary/2) で文字列に変換して返しています。

# 参考文献

* [Elixir Image で図形・文字描画](https://qiita.com/RyoWakabayashi/items/54e92be2e134e0fde0f5) @RyoWakabayashi
* [CoreMP135のLCDにPythonでCPU温度を表示](https://qiita.com/nnn112358/items/e8b806d76943ab3ee319) @nnn112358 (nnn)
