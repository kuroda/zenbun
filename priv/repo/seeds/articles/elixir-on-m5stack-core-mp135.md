---
title: Elixir を M5Stack CoreMP135 上で動かす
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack"]
---

# 本稿の前提条件

本稿では小型 Linux PC である M5Stack CoreMP135 上にプログラミング言語 Elixir の実行環境を構築する手順を解説します。

本稿の記述は、読者が Ubuntu 24.04 LTS のインストールされた PC と M5Stack CoreMP135 を所有していることを前提としています。Windows PC および Mac でも類似の手順により作業を進めることが可能と考えられますが、miniSD カードに Debian OS を焼き付ける手順と PC から M5Stack CoreMP135 に SSH 接続する手順が若干異なる点に留意してください。

# M5Stack CoreMP135 とは

**M5Stack**（エムファイブスタック）は、中国深圳に拠点を持つスタートアップ企業です。同社を代表する製品は M5Stack ESP32 という名前の小型のマイコンモジュールです（2021 年発売開始）。この製品は、54 mm × 54 mm × 17 mm という小さな筐体に、2 インチの液晶ディスプレイ、スピーカー、Wi-Fi、Bluttooth、Type-C USB コネクタ、Grove I2C コネクタ、SD カードリーダー等を搭載しています。

本稿が扱うのは、2024 年に発売が開始された **M5Stack CoreMP135** という同社の別の製品です（以下、「CoreMP135」と呼びます）。M5Stack ESP32 とは異なり、CoreMP135 では Linux ディストリビューションの一つである Debian が動きます。したがって、プログラミング言語 Elixir で書かれたプログラムを CoreMP135 上で動作させることができます。

CoreMP135 のサイズは、54 mm × 54 mm × 34.5 mm です。2 インチの液晶ディスプレイ、スピーカー、HDMI コネクタ、Type-A USB コネクタ（×2）、Type-C USB コネクタ、CAN ポート、RS-485 ポート、Grove I2C コネクタ、UART コネクタ、M5BUS コネクタ、イーサネットコネクタ、microSD カードリーダー等を搭載しています。M5Stack ESP32 よりも高さがある分、ポートとコネクタの数が多くなっています。工場でよく見る DIN レールに据付可能である点も特徴です。RAM のサイズは 512 MBです。別売りの 12V 5A 電源アダプタまたは USB ケーブルで給電します。

![M5Stack CoreMP135 (1)](/images/articles/elixir-on-m5stack-core-mp135/core-mp135-1.jpg =360x)

注意すべきは、CoreMP135 が Wi-Fi と Bluetooth 接続機能を備えていないことです。ネットワークアクセスを得るには LAN ケーブルで CoreMP135 のイーサネットコネクタとルーターを接続する必要があります。

もう 1 点注意があります。スイッチサイエンス社の M5Stack CoreMP135 販売ページに掲載されている画像には「DISPLAY PORT」のテキストが書かれていますが、注意書きに記載されている通り、外部モニタ出力用のコネクタは HDMI 形状のものです。

# 入手すべきもののリスト

本稿に沿って実際に CoreMP135 上で Elixir プログラムを動かしてみるには、以下の製品が必要です（合計 17,810 円）。なお、価格は2024年9月17日時点でのものであり、単位は日本円、消費税込みです。CoreMP135 以外の製品に関しては、同等のもので代替できます。

|品名|URL|価格|
|----|---|----------:|
|M5Stack CoreMP135|https://www.switch-science.com/products/9650|13,728|
|12V 5A 電源アダプタ（※）|https://www.amazon.co.jp/dp/B082TXXVY3|1,608|
|16GB microSD カード|https://www.amazon.co.jp/dp/B088KJFWMD|550|
|microSD カードリーダー（※）|https://www.amazon.co.jp/dp/B006T9B6R2|990|
|HDMI ケーブル（※）|https://www.amazon.co.jp/dp/B095C96HH6|550|
|LAN ケーブル|https://www.amazon.co.jp/dp/B00N2VILDM|384|

その他に、HDMI コネクタを持つモニターと英語配列の USB キーボードが必要です。

## 注記

* Type-A USB または Type-C USB コネクタに接続できる電源アダプタがあれば、12V 5A 電源アダプタは不要です。あるいは、USB ケーブルで PC から給電することも可能です。
* microSD カードリーダーは、Debian を microSD カードにインストールするために必要です。あなたの PC で microSD カードを読み書きできるなら、新たに購入する必要はありません。
* HDMI ケーブルは外付けモニターと CoreMP135 を接続するために使用しますが、外部から CoreMP135 に SSH で接続できる環境が整った後は必須ではありません。他の用途で使用している HDMI ケーブルを一時的に借用してもよいでしょう。
* USB キーボードは、外部から CoreMP135 に SSH で接続できるように環境が整った後は必須ではありません。

# Debian を microSD カードに焼き付ける

ブラウザで https://docs.m5stack.com/en/guide/linux/coremp135/image を開き、「1. Download image file」セクションにある表から最新版のイメージをダウンロードしてください。

ダウンロードしたファイルは `M5_CoreMP135_debian12_20240628.7z` のような名前のファイルです。これを展開すると `M5_CoreMP135_debian12_20240628.img` のような名前のファイルが出現します。

これを microSD カードに焼き付ける手順については、https://docs.m5stack.com/en/guide/linux/coremp135/image の「2. Burn image」セクションを参照してください。

大まかな手順は次の通りです:

1. microSD カードリーダーを PC に接続し、microSD カードを挿入する。
1. balenaEtcher をインストール（詳細は後述）。
1. balenaEtcher を起動。
1. 「Flash from file」ボタンをクリック。
1. 展開した `.img` ファイルを選択。
1. 「Select target」ボタンをクリック。
1. microSD カードを選択する。
1. 「Flash」ボタンをクリック。

Ubuntu に balenaEtcher をインストールする方法は次の通りです:

1. ブラウザで https://github.com/balena-io/etcher/releases/ を開く。
1. 「Latest」というラベルの付いたバージョン（2024 年 9 月 19 日現在、v1.19.21）の `.deb` ファイルをダウンロードする。
1. `sudo apt install balena-etcher_1.19.21_amd64.deb` コマンドを実行する。ただし、`1.19.21` の部分はダウンロードしたファイルに合わせて置き換える。

# CoreMP135 を起動する

購入した CoreMP135 の microSD カードリーダーには初めから microSD カードが入っていますので、これを取り出して、Debian イメージを焼いた microSD カードを挿入してください。

そして、CoreMP135 の USB コネクタにキーボード、HDMI コネクタにモニターを接続してから、CoreMP135 に電源アダプタを差し込んで給電してください。約 30 秒経過すると、CoreMP135 上の液晶ディスプレイが点灯し、スピーカーからブザー音が鳴ります。

![M5Stack CoreMP135 (1)](/images/articles/elixir-on-m5stack-core-mp135/core-mp135-3.jpg =360x)

そして、モニターには Debian へログインするためのプロンプトが表示されます。

![M5Stack CoreMP135 (1)](/images/articles/elixir-on-m5stack-core-mp135/debian-login.jpg =360x)

ユーザー名 `root`、パスワード `root` でログインできます。

# 起動時のビープ音を止める

CoreMP135 の起動時には、かなり大きなビープ音が鳴ります。これを止めたい方は、コマンド `vim /usr/local/m5stack/init.sh` を実行して、エディタ Vim で設定ファイルを開き、`tinyplay` で始まる行の先頭に `#` を加えてください。

# `debian` ユーザーのパスワードを変更する

CoreMP135 上でコマンド `password debian` を実行し `debian` ユーザーのパスワードを変更してください。

# Debian OS に割り当てられた IP アドレスを調べる

CoreMP135 には LAN ポートが 2 個あります。右側が `eth0`、左側が `eth1` です。右側の LAN ポートに Ethernet ケーブル（LAN ケーブル）を接続し、ネットワークと連結してください。

そして、コマンド `hostname -I` を実行して、Debian OS に割り当てられた IP アドレスを調べてください。

```
192.168.0.130 2408:26:22ee:0:7e85:21ad:f5ea:1171
```

のように表示されたとすれば、`192.168.0.130` がその IP アドレスです。

# Debian OS の IP アドレスを固定する

前節で調べた IP アドレスは DHCP により割り当てられたものであり、Debian を起動するたびに変化します。今後の作業をやりやすくするために、IP アドレスを固定すべきです。

詳しい手順は [M5Stack CoreMP135 Debian の IP アドレスを固定する](https://zenn.dev/tkrd/articles/fix-ip-addresss-of-core-mp135-debian) を参照してください。

# microSD カードのパーティションを拡大する

microSD カードに作られる Debian OS のためのパーティションサイズは約 1GB で、ほとんど空きがありません。以下の手順でパーティションを最大サイズまで拡大してください。

* `/usr/local/m5stack/resize_mmc.sh` コマンドを実行する。
* CoreMP135 の電源をオフにする。
* CoreMP135 の電源をオンにする。

`reboot` コマンドで Debian を再起動するのではなく、CoreMP135 の電源を入れ直してください。

# SSH で CoreMP135 上の Debian に接続する

あなたの PC のターミナルで次のコマンドを実行し、CoreMP135 上の Debian に接続してください。

```bash
ssh debian@192.168.0.200
```

ただし、`192.168.0.200` の部分は CoreMP135 の Debian OS に割り当てられた IP アドレスで置き換えてください。

これ以降の操作は PC から SSH 接続で行うので、CoreMP135 から HDMI ケーブルとキーボードを取り外すことができます。

# Elixir をインストールする

## 準備作業

CoreMP135 に SSH 接続したターミナルで以下のコマンドを実行してください。

```bash
sudo locale-gen en_US.UTF-8
echo export LANG=en_US.UTF-8 >> ~/.bashrc
echo export LC_ALL=en_US.UTF-8 >> ~/.bashrc
```

ここで、`exit` コマンドで SSH 接続を切り、接続し直してください。

```bash
sudo apt update
sudo apt -y install build-essential autoconf m4 libncurses-dev \
libwxgtk3.2-dev libwxgtk-webview3.2-dev libgl1-mesa-dev libglu1-mesa-dev \
libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-17-jdk
```

## asdf をインストール

バージョン管理ツール [asdf](https://asdf-vm.com/) をインストールします。

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
echo . $HOME/.asdf/asdf.sh >> ~/.bashrc
source ~/.bashrc
```

## Erlang をインストール

asdf を利用して Erlang 27.0.1 をインストールします。

```bash
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 27.0.1
asdf global erlang 27.0.1
```

かなりの時間（1 〜 2時間）を要します。

## Elixir をインストール

asdf を利用して Elixir 1.17.2 をインストールします。

```bash
asdf plugin add elixir
asdf install elixir 1.17.2-otp-27
asdf global elixir 1.17.2-otp-27
```

こちらは一瞬で完了します。

# 動作確認

## Elixir のバージョンを確認

`elixir --version` コマンドを実行し、Elixir のバージョンを確認してください。次のように出力されれば OK です。

```
Erlang/OTP 27 [erts-15.0.1] [source] [32-bit] [smp:1:1] [ds:1:1:10] [async-threads:1]

Elixir 1.17.2 (compiled with Erlang/OTP 27)
```

## IEx の起動と終了

`iex` コマンドを実行し、Elixir の対話型シェル IEx を起動します。

プロンプト `iex(1)>` に対し、`1 + 1` を入力し `2` と出力されることを確認してください。

`Ctrl+C` を 2 度入力して IEx を終了してください。

## CoreMP135 のシャットダウン

`sudo shutdown -h now` コマンドを実行し Debian OS をシャットダウンしてから、CoreMP135 の電源をオフにしてください。

# CoreMP135 に関する他の私の記事

* [Elixir で M5Stack CoreMP135 の LCD バックライトの明るさを調整する](https://zenn.dev/tkrd/articles/elixir-on-core-mp135-backlight)
* [M5Stack M5Stack CoreMP135: 起動時のロゴ画像を差し替える](https://zenn.dev/tkrd/articles/change-core-mp135-logo)
* [M5Stack M5Stack CoreMP135: IP アドレスを固定する](https://zenn.dev/tkrd/articles/fix-ip-addresss-of-core-mp135-debian)
* [Elixir で M5Stack CoreMP135 の液晶ディスプレイに色を塗る](https://zenn.dev/tkrd/articles/elixir-on-core-mp135-framebuffer-1)
* [Elixir で M5Stack CoreMP135 の液晶ディスプレイに図形を描く](https://zenn.dev/tkrd/articles/elixir-on-core-mp135-framebuffer-2)
* [Elixir で M5Stack CoreMP135 の液晶ディスプレイににテキストを表示する](https://zenn.dev/tkrd/articles/elixir-on-m5stack-framebuffer-3)
* [Elixir で M5Stack CoreMP135 のタッチパネルから入力を得る①](https://zenn.dev/tkrd/articles/elixir-on-core-m5stack-touch-panel-1)

# 参考文献

* [【M5Stack MP135】LivebookでLチカ（LED点滅）してみた](https://qiita.com/GeekMasahiro/items/1987ed321baa43724039) @GeekMasahiro
* [VM上のUbuntuで仮想ディスクのサイズを増やす](https://qiita.com/38pinn/items/e4b1e5a96d1ad3e4ed8a) @38pinn
* [CoreMP135の起動時のbeep音を止める](https://qiita.com/nnn112358/items/63944e500d0cd3d4b630) @nnn112358
* [【試行錯誤】M5Stack MP135でElixirを動かした時のメモ](https://qiita.com/GeekMasahiro/items/3ff5276a552c4430439c) @GeekMasahiro
