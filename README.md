# テキスト⇔HTML相互変換「リトルバグ」

## これはなに？
**! 詳しくは[Wiki](https://github.com/y-mikou/littlebug/wiki)を参照してください !**

以下の機能を持ったbashスクリプトです。

- 一定程度規則(マークアップ)に則って書かれたテキスト文書(txt)に対しHTMLタグを付与してhtmlファイルにする。
- これによって付与したhtmlタグを除去・変換して、出来る限り元のマークアップ文書(txt)に戻す。

特に、小説のような形式で書かれた日本語文章に特化します。

## 変換概要
# 当スクリプトでの変換対象一覧
> 細かい挙動や仕様は、仕様書を参照してください。

| 効果             | 対象文字、状況       | htmlタグとClass(終了タグ省略)                    | 概要/デフォ設定
| ---------------- | -------------------- | -------------------------------------------- | -----------------
| 改行             | 改行コード           | `<br class="ltlbg_br">`                      | 特殊style無し
| 空行             | 行頭改行コード       | `<br class="ltlbg_blankline">`               | 特殊style無し
| ダーシ           | `―`or`――`         | `<span class="ltlbg_wSize">`                 | 1字を長さ倍
| 段落             | 行頭全角空白         | `<p class="ltlbg_p">`                        | 先頭空白除去、空行挿入
| 踊字             | `／＼`or`〱`         | `<span class="ltlbg_odori1">`                | 1字目。横書時回転
|                  |                      | `<span class="ltlbg_odori2">`                | 2字目。横書時回転
| 「会話」         | 行頭`「`から`」`     | `<span class="ltlbg_talk">`                  | ぶら下がりIndent
| 『会話』         | 行頭`『`から`』`     | `<span class="ltlbg_talk2">`                  | ぶら下がりIndent
| （思考）         | 行頭`（`から`）`     | `<span class="ltlbg_think">`                 | ぶら下がりIndent
| 〝強調〟         | 行頭`〝`から`〟`     | `<span class="ltlbg_wqote">`                 | ぶら下がりIndent
| ――会話         | 行頭`――`から改行まで | `<span class="ltlbg_dash">`                 | ぶら下がりIndent
| ＞会話           | 行頭`＞`から改行まで  | `<span class="ltlbg_citation">`              | ぶら下がりIndent
| 会話等の疑似段落  | 連続する括弧類の行    | `<p class="ltlbg_p_brctGrp">`                | 擬似的な段落
| 右大不等号       | `<`                  | `&lt;`                                       | クラス化なし
| 左大不等号       | `>`                  | `&gt;`                                       | クラス化なし
| アンパサンド     | `&`                  | `&amp;`                                      | クラス化なし
| ダブルクォート   | `"`                  | `&quot;`                                     | クラス化なし
| シングルクォート | `'`                  | `&#39;`                                      | クラス化なし
| コロン           | `：`or`:`            | `<hr class="ltlbg_colon">`                   | 縦書きのみ。全角化
| セミコロン       | `；`or`;`            | `<hr class="ltlbg_semicolon">`               | 縦書きのみ。全角化、回転
| 線               | `---`                | `<hr class="ltlbg_hr">`                      | 特殊style無し
| 全角空白         | 行頭以外の全角空白   | `<span class="ltlbg_wSP">`                   | 全角空白。1em幅確保
| 半角空白         | 半角空白             | `<span class="ltlbg_sSP">`                   | 半角空白。0.5em幅確保
| 後ろ空白         | ！や？               | `<span class="ltlbg_wSP">`                   | 記号の直後に強制全角空白
| 半角英数記号     | ！や？、英数の重なり | `<span class="ltlbg_tcyA">`                  | 2字のみ。自動半角縦中横化
| エロ濁点         | `゛`                 | `<span class="ltlbg_dakten">`                | 縦書時のみ前字の右上に移動
| ルビ             | `{母字｜ルビ}`or     | `<ruby class="ltlbg_ruby" data-ruby_center="ルビ">`        | 母字数=ルビ字数はモノルビ化
|                  | `｜母字《ルビ》`     | `<ruby class="ltlbg_ruby" data-ruby_long="ルビ">`        | 長いルビは始点合わせ
|                  |                      | `<ruby class="ltlbg_ruby" data-ruby_center="ルビ">`       | 少し短いルビは中央寄せ
|                  |                      | `<ruby class="ltlbg_ruby" data-ruby_short="ルビ">`       | 短いルビは1マス空けして中央寄せ
| 傍点             | `《《傍点》》`       | `<ruby class="ltlbg_emphasis" data-emphasis="﹅">`       | ルビ化する。黒ゴマ
| 太字             | `**太字**`           | `<span class="ltlbg_bold">`                              | font-weight:bold
| 縦中横           | `^XX^`               | `<span class="ltlbg_tcyM">`                              | 1〜3字のみ
| 章区切り         | `[chapter:章idx]`    | `<section class="ltlbg_section" id="章idx">`             | 章idxは必須でない
| 章タイトル       | 行頭`§`or`◆`or`■` | `<h2 class="ltlbg_sectionname">`                         | 2字幅行に大Font
| 改ページ         | `[newpage]`          | `<div class="ltlbg_newpage">`                            | breakAfter:Allの空div
| 回転対応         | `[^字^]`             | `<span class="ltlbg_rotate">`                            | 全半角1字。1em幅確保、回転
| 字幅対応         | `[-字-]`             | `<span class="ltlbg_wdfix">`                             | 全半角1字。1em幅確保
| 強制合字         | `[l[字]r]`           | `<span class="ltlbg_forceGouji">`                        | 左右のやつ限定「忄実」みたいの

# 仕様
[仕様書的なもの](https://github.com/y-mikou/littlebug/wiki/20_%E4%BB%95%E6%A7%98%E6%9B%B8%E7%9A%84%E3%81%AA%E3%82%82%E3%81%AE)参照

# 使い方
```
bash littlebug.sh [引数1:(パスと)対象ファイル] [引数2:変換方法] 
```

---

# 処理概要

## 方針

基本的に上記の置換を行うのみ。

元ファルから変換後ファイルを新設する。

同名ファイルがあれば上書きする。

## 主処理への分岐

``` mermaid 
flowchart TD

開始 --> 引数_ファイルの判定
引数_ファイルの判定 --ファイルあり--> 引数_変換方法の判定1 
引数_ファイルの判定 --ファイルなし--> 引数エラー
引数_変換方法の判定1 --引数=HかT--> 変換後ファイルを空作成
引数_変換方法の判定1 --引数=HでもTでもない--> 引数エラー
変換後ファイルを空作成 --> 引数_変換方法の判定2
引数_変換方法の判定2 --引数=H--> txtからhtmlへ変換
引数_変換方法の判定2 --引数=T--> htmlからtxtへ変換
txtからhtmlへ変換 --> 非対応マークアップの警告表示
非対応マークアップの警告表示 --> 変換後ファイルへ上書き
htmlからtxtへ変換 --> 変換後ファイルへ上書き
変換後ファイルへ上書き --> 各中間ファイルの削除
```
