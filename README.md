要件を抽出/明確化中です

# テキスト置換「リトルバグ」
一定程度規則に則って書かれたただのテキスト(.txt)に対し、CSS組版とWEB表示のソースを作り分ける素材となるHTMLタグを付与する。あるいはそれを除去してただのテキストに戻す。

特に、小説のような形式で書かれた日本語文章に特化する。

専用のCSSを用意し、htmlに対して付与する情報ではそれを使用する。専用CSSは組版用/WEB表示用それぞれで競合しないようクラス分けを行う。

## ターゲット
- 日本語文章、特に小説などをテキストエディタで書いている
- (VFM/MDを知っていても)SS書くときに「ルビ」「傍点」「章」程度の記述しかしない人
  - 当アプリでは、可能な限り[VFM](https://github.com/vivliostyle/vfm)に寄せたい。
  - 今後VFM側に変更があったとき、**私が気付けば**追従して変更する。
  - とはいえ完全にVFMに準拠して書くのは面倒だし、txtに直したときにタグが残りすぎるのも嫌だ
- WEBで公開するために、簡単にhtmlファイルにしたい
- 同人誌として組版する際に、CSS組版を使用したい
  - [VivliostyleViewer](https://vivliostyle.org/)での解釈を想定
- 「WEB表示用のファイル」「組版データ」「生原稿」を別のファイルにせず1ソースとしたい
- WindowsやMac用のリッチなアプリが使えない環境
  - Chromebookとか、RaspberryPiとか

## 目的
小説などの形式で書かれた日本語文章を、WEBで公開するhtmlにしたりCSS組版を実施する際、
- 元の生テキスト
- CSS組版されたデータ
- WEB用にスタイリングされたデータ

を行き来する、あるいは元データを一元的に扱うために、形式化された変換(可能であればある程度の可逆変換)が求められるため、その一助となる仕組みを作る。

簡易なルールだけでtxtで記載した文章をhtml化し、html(とCSS)側でtxtで表現できないスタイルを付与した後でtxtに戻す場合に、一定程度その情報を残したいときにそれを補佐する。

- 例えばtxtで「魔法」とだけ書いていた文章に、html化後にルビ「マジック」を付与した際、その情報をtxt側に保持(移送)したいが、ただhtmlタグを取ると消えてしまう。手でやると面倒。
- txtで書いていた文章をhtml化後に画面や版面を意識した形に修正した。その内容をtxtへ反映するのはかなり面倒。

それを避けるために、簡易なタグ(VFM準拠だがもう少し簡易かつ、小説のような日本語文章に特化)なものとして残すことで、文章データのソースを単一ファイルで残す。

これを実現する一連の正規表現置換のトランザクション化を期待するもの。

## 注意
- **ぶっちゃけ自分用です**
- htmlを生成する際、段落と、カッコ類の扱いについて、かなりイロモノな設定を行う想定のhtmlを生成します。
  - [■カッコ類について](#■カッコ類について)
  - [段落の表現](#段落の表現)
- htmlからtxtに変換する際、一定程度のタグが残る。
  - txtで文章を書く際にも一定程度のタグを直書きしている人をターゲットにしている
- これは組版を実施するものではない
- [スコープアウト](#スコープアウト)参照

## 形式
1. bashスクリプト(要Linux環境)
   - 引数
     1. 対象ファイル
     2. 変換方向
        1. htmlタグを付与し、Styleを適用できる形にする
        2. htmlタグを除去し、特定の文字を復旧して、一定程度の規則を持ったtxtファイルに戻す
2. CSSファイル
   
   html化した際に、最低限の表示を担保するstyleを記載したもの。
   
   元ファイルに関らず1種類、同じもの。
   
   生成するのではなく、ここに同梱する。

## スコープアウト
- htmlのタグを挿入するにあたり、組版後の縦書きと横書きを意識すること
- 後述の、セクションを指定する文字などを可変とすること、またこの文字をエスケープできるようにすること
- html化時の、章番号の自動採番
- ルビの母字に対する配置距離

## 名前について
ぼくはリグルがすきです。

---

# .txtと.htmlの約物定義
可逆変換を実現するため、なるべく多義性を持たないよう対定義する。

## ■改行について
- txtの改行…ハード改行(`\n`)
- htmlの改行…`br`タグ+ハード改行(`\n`)

> `\r`、`\r\n`は予め`\n`へ置換する

## ■空行について
- txtの空行1行(行頭`\n`) = htmlの行頭`br`タグ(`1行空けクラス`指定)
- txtの空行2行(2連続する行頭`\n`) = htmlの行頭`br`タグ(`2行空けクラス`指定)
> txtの空行3行以上…[章区切り](■章について)へ変換する<br>
> 行頭に登場するクラス指定なしの`br`タグは、`1行空けクラス`を**強制適用**する

> また1行空行においては、段落による空行と区別する。<br>
> →htmlからtxtへ戻す際に、可逆性が失われるため<br>
> ※段落の詳細については[段落の表現](#段落の表現)にて後述


## ■段落について
### 段落の定義
- txtの段落
  - `行頭全角空白文字`から、次の`行頭全角空白文字`の手前まで 
  - `行頭全角空白文字`から、`章区切り(開始)`の手前まで

- htmlの段落
  - `変換対象段落クラス`を指定した`p`タグで囲まれた範囲
    - `p`タグは本来的に段落を示すものだが、当アプリで注入したものであるか否かを判断するために明示的にクラス指定する

### 段落の表現
一般的に、日本語文章における段落は`先頭の字下げ`を行うとされるが、これは「書籍に記載される場合」に限って「一般的に」と注される。

書籍ではなくWEB掲載文章において、段落の字下げを行うべきか否かについては一般的な回答は得られておらず、個人的には読みやすいとは思っていない。

現実的に、WEB文章における段落は開いた行間(空行)によって表現されることの方が多く、その方が読みやすいとも言われる。

この変換機能においては、txtとからhtmlへ変換する際、`p`タグへ変換したあと**行頭に全角空白文字は残さない**。

加えて、`p`タグにはstyle設定により開始時に1文字分程度の行間merginを加える。

これにより、html上の段落は**広い行間**による表現へ変換される。

またhtmlからtxtへ置換する際には、`段落クラス`を指定した`p`タグを判断して、`行頭全角空白文字`へ置換する。

## ■章について
章の大小、段階は設けない。

htmlにおいては`見出し`と混同されがちだが、明確に区別する。

`h`系タグは、章のタイトルの記載には使用するが、**章の区切りにはしない**。

- txtの章
  - 3行以上の空行から、次の3行以上の空行の手前まで
- htmlの章
  - `章クラス`を指定した`section`タグに囲まれた範囲

## ■章タイトルについて
- txtでの章タイトル
  - `$`か`◆`の章を指定する文字で始まる1行
    - 3行以上の空行による章は、予め`◆`か`§`が付与されている想定
- htmlでの章タイトル
  - `章タイトルクラス`を指定した`h3`タグに囲まれた範囲
    - `h1`、`h2`は競合しやすそうなので。

> 章タイトルの判定にはいくつかの既定の文字を使用するが、txtからhtmlへ置換する際にはこれらの文字は**除去される**。

> `◆`や`§`にて章を記すとき、"◆"や"§"の文字を章タイトルとしたい場合には、`章クラス`の`before`や`after`の疑似要素にて指定すること。
> 
> →`◆`や`§`文字を残すと、章番号を先頭に見出しとしたいケースで邪魔になる

### 章タイトルの表現
`章タイトル(見出し)`は、`章の区間`とは**密結合しない**。  

一般的に、章タイトルは章の冒頭にあるものと先入されるが、これを切り離す。

`h`系タグの開始前に強制的に章区切り用merginがつくような、テキストで文章を書いている人間にとって非直観的な記述をやめる。

**章タイトルは「タイトル」→文字列の表現**。<br>
**章の区切りは「区切り」→レイアウトの表現**。<br>
**別物とする**。

これにより、章区切りから数行導入があって章タイトルが表示されるような演出が可能。

## ■改ページについて
- txt
  - `[newpage]`の文字(Pixiv小説形式)
    - CSS組版で常用される、「特定のタグの開始/終了に改行を指定する(`page-break`疑似要素での指定)」方式は、文章書き、特にテキストで執筆する者には馴染みがない。
    - 基本的にtxt形式のデータには登場しない想定。改ページ指定済みのhtmlをtxtに直したときに情報が残るよう指定するもの
- html
  - `終了後改ページクラス`を指定した**空の**`div`タグ

> 段落後に自動改ページすることは想定していない。
> 必要であればCSSのカスタマイズで対応する制限とする。


## ■ルビについて
- txt
  - `{母字｜ルビ}`による形式(VFM/でんでんマークダウン)
- html
  - `<rb>、<rt>`タグによる形式
> 母字とルビの距離については操作を諦める。
> 組版時には行間を縛る障害になるが、技術的にコストが高い。

## ■傍点(圏点)について
- txt
  - `《《kenten》》`による形式(カクヨム)
    - VFMでは圏点は定義されておらず、でんでんマークダウンでは縦書き時に限定される。また、太字とも区別したいため、これを採用。
- html
  - `圏点クラス`を指定した`span`タグ

## ■太字について
### 定義
- txt
  - `__太字__`での形式(独自形式)
    - "_"一つでは通常文章で競合する可能性がある。"*"よりは日本語文章で用いられる可能性が低い。文章書いてるときにエスケープしたくない。
- html
  - `b`タグ

### 太字と他の修飾の共存について
太字と、ルビ/圏点は共存可能とする。

その際、太字指定を他のタグより内側に記述するよう制限する。

> 制限事項は調査中…
> 太字化によって行間がずれないよう調整が必要？

## ■縦中横について
- txt
  - `《｜yoko｜》`による形式(独自形式)
- html
  - `縦中横クラス`を指定した`span`タグ

※`縦中横`は縦書き用の表現なので、横書きでは特に何もおこらない。

## ■カッコ類について
### 定義
- txt
  - 「」（）など、記述されたまま
- html
  - カッコ類は、「」、（）などそれぞれの`括弧クラス`を指定した`div`タグの範囲
  
### 括弧類の表現
書籍等に記載する型式をそのまま表示した場合、括弧類(や段落も含め)は以下のように表現される。
```
　当人もあまり甘うまくないと思ったものか、ある日その友人で美
学とかをやっている人が来た時に下しものような話をしているのを
聞いた。
「どうも甘うまくかけないものだね。人のを見ると何でもないよう
だが自みずから筆をとって見ると今更いまさらのようにむずかしく
感ずる」
　これは主人の述懐である。
```
開始括弧`「`で1字下がり、字送りがあると`「`と高さが重なる。

個信的な好みでしかないが、書籍では気にならないが、WEB表示では好きではない。

個人的にはhtml上では前述の[段落の表現](■段落の表現)と合わせて以下のようになってほしい

①
```
当人もあまり甘うまくないと思ったものか、ある日その友人で美
学とかを　やっている人が来た時に下しものような話をしている
のを聞いた。

「どうも甘うまくかけないものだね。人のを見ると何でもないよ
　うだが自みずから筆をとって見ると今更いまさらのようにむず
　かしく感ずる」

これは主人の述懐である。
```
もしくは

②
```
　当人もあまり甘うまくないと思ったものか、ある日その友人で
　美学とかを　やっている人が来た時に下しものような話をして
　いるのを聞いた。

「どうも甘うまくかけないものだね。人のを見ると何でもないよ
　うだが自みずから筆をとって見ると今更いまさらのようにむず
　かしく感ずる」

　これは主人の述懐である。
```
①、②いずれにするにせよ、何らかの`インデント`を実施する必要があり、単純に`「」`を保持していても実現できない。

そこで、括弧類も単に文字として保持するのではなく、`括弧クラス`を指定した`div`としておき、`括弧クラス`や文章全体をくくる何らかのクラスをカスタマイズすることで、これを実現する。

あるいはこうした特殊な表現をしない場合においても、`括弧クラス`の編集によりもとに戻せる利便性を得られる。

この`括弧クラス`を指定した`div`タグでは`「」`や`（）`など括弧類の文字は、疑似要素`before`、`after`に取り込むことを想定しており、txtからhtmlに変換した際には**括弧類は文字としては除去される**。

htmlからtxtへ変換する際には、`括弧クラス`を判断して該当の括弧類の文字へ置換する。

---

# 処理概要

## 方針

基本的に上記の置換を行うのみ。

バックアップは強制的に作成する。

同名ファイルがあれば上書きする。

## 主処理への分岐

``` mermaid 
flowchart TD

開始 --> 引数_ファイルの判定
引数_ファイルの判定 --ファイルあり--> 引数_変換方法の判定1 
引数_ファイルの判定 --ファイルなし--> 引数エラー
引数_変換方法の判定1 --引数=1か2--> バックアップ作成
引数_変換方法の判定1 --引数=1でも2でもない--> 引数エラー
バックアップ作成 --> 引数_変換方法の判定2
引数_変換方法の判定2 --引数=1--> txtからhtmlへ変換
引数_変換方法の判定2 --引数=2--> htmlからtxtへ変換
```
以降は一本道の処理になる想定なので、下記に箇条書き。

## 主処理_txtからhtmlへ変換

1. 処理…


## 主処理_htmlからtxtへ変換

1. 処理…

---

# 予約語パターン
上記処理を行うために、置換対象を判断するための予約語的なパターンを規定する(正規表現)。

この文字は現状、可変とする想定はない。エスケープ処理も想定していない([スコープアウト](#スコープアウト))。

これらのパターンを本来の目的以外に使用した場合、想定外の結果を招く可能性がある。

- `\{[^{]+｜[^{]+?\}`…ルビ
- `《《.+?》》`…圏点
- `^[§|◆].+\n`…セクションの判断に使用
- `《｜[^《]+｜》`…縦中横
- `__.+?__`…太字 

> 随時追加……？

> これらの中に登場する**正規表現のメタ文字以外の**"｜"はすべて**全角**である
> 
> ※VFM準拠(半角"|"はテーブル記述のカラム指定と競合するらしい)

---

……加筆中……