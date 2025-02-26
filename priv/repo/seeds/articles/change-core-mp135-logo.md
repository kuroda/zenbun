---
title: "M5Stack CoreMP135: 起動時のロゴ画像を差し替える"
published: true
type: tech
emoji: 🫐
topics: ["m5stack", "coremp135"]
---

# 概要

https://docs.m5stack.com/en/guide/linux/coremp135/image からダウンロードした Debian イメージで動く M5Stack CoreMP135 において、起動時に液晶ディスプレイ（LCD）に表示されるロゴ画像を差し替える方法を解説します。

# 手順

* 横 320px、縦 240px のオリジナルロゴ画像（JPEG）を用意します。
* `scp` コマンドでオリジナルロゴ画像を CoreMP135 に転送します。
* その画像を `/usr/local/m5stack` ディレクトリに移動します。
* `/usr/local/m5stack` ディレクトリにある `logo.jpg` を `logo.orig.jpg` にリネームします。
* オリジナルロゴ画像の名前を `logo.jpg` にリネームします。

オリジナルロゴ画像が PNG 形式の場合は、`logo.png` という名前で `/usr/local/m5stack` ディレクトリにおいてください。そして、`/usr/local/m5stack/init.sh` を Vim エディタで開いて、`logo.jpg` を `logo.png` と書き換えてください。

![オリジナルロゴ画像](/images/articles/change-core-mp135-logo/original_logo.jpg =360x)
