要件を抽出/明確化中です

# テキスト⇔HTML相互変換「リトルバグ」

一定程度規則に則って書かれたただのテキスト(.txt)に対し、CSS組版とWEB表示のソースを作り分ける素材となるHTMLタグを付与する。あるいはそれを除去してただのテキストに戻す。

特に、小説のような形式で書かれた日本語文章に特化する。

専用のCSSを用意し、htmlに対して付与する情報ではそれを使用する。スタイルにはこのアプリ以外でのタグ記述と競合しないよう専用クラスを付与する。

- [VFM](https://github.com/vivliostyle/vfm)
- [でんでんマークダウン](https://conv.denshochan.com/markdown)

みたいな変換を**可逆で**おこなうシェルスクリプトです。


## 変換の要約

それぞれの詳細は、[txtと.htmlの約物定義](#.txtと.htmlの約物定義)以降に記載しています。

※マークアップに`or`を含むものは完全に可逆変換にならない(いずれか一つに収斂される)

### 実装予定の変換
| 効果         | txtマークアップ      | htmlタグとClass(閉じ省略)                    | 概要/デフォ設定
| ------------ | -------------------- | -------------------------------------------- | -----------------
| 作品タイトル | (ファイル名)         | `<title class="ltlbg_noveltitle">`           | 利用想定無し
|              |                      | `<h1 class="ltlbg_noveltitle">`              | 利用想定無し
| 改行         | 改行コード           | `<br class="ltlbg_br">`                      | 特殊style無し
| 空行         | 行頭改行コード       | `<br class="ltlbg_blankline">`               | 特殊style無し
| ルビ         | `{母字｜ルビ}`       | `<ruby class="ltlbg_ruby">`,`<tr>`           | 特殊style無し
| 傍点         | `《《傍点》》`       | `<span class="ltlbg_emphasis">`              | 黒ゴマ
| 太字         | `**太字**`           | `<span class="ltlbg_bold">`                  | font-weight:bold
| 縦中横       | `^XX^`               | `<span class="ltlbg_tcy">`                   | 半角2字のみ
| ダーシ       | `―`or`――`         | `<span class="ltlbg_wSize">`                 | 1字を長さ倍
| 章タイトル   | 行頭`§`or`◆`or`■` | `<h2 class="ltlbg_sectionname">`             | 2字幅行に大Font
| 章区切り     | `[capter:章idx]`     | `<section class="ltlbg_section" id="章idx">` | 章idxは必須でない
| 改ページ     | `[newpage]`          | `<div class="ltlbg_newpage">`                | breakAfter:Allの空div
| 線           | `---`                | `<hr class="ltlbg_hr">`                      | 特殊style無し

### 実装予定の、当アプリの特徴的な変換
| 効果         | txtマークアップ      | htmlタグとClass(閉じ省略)                    | 概要/デフォ設定
| ------------ | -------------------- | -------------------------------------------- | -----------------
| 段落         | 行頭全角空白         | `<p class="ltlbg_p">`                        | 先頭空白除去、空行挿入
| 横書踊字     | `／＼`or`〱`         | `<span class="ltlbg_odori1v">`               | 1字目"〵"_左90度回転
|              |                      | `<span class="ltlbg_odori2v">`               | 2字目"〳"_右90度回転
| 「会話」     | 行頭`「`から`」`     | `<span class="ltlbg_talk">`                  | ぶら下がりIndent
| （思考）     | 行頭`（`から`）`     | `<span class="ltlbg_think">`                 | ぶら下がりIndent
| 〝強調〟     | 行頭`〝`から`〟`     | `<span class="ltlbg_wqote">`                 | ぶら下がりIndent
| 半角ズレ修正 | 奇数長の半角文字列   | `<span class="ltlbg_lenfil">`                | 右merginに0.5em
| 回転対応     | `[^字^]`             | `<span class="ltlbg_rotate">`                | 全半角1字。1em幅確保、回転
| 字幅対応     | `[-字-]`             | `<span class="ltlbg_lenfix">`                | 全半角1字。1em幅確保

### 検討中の変換
他では絶対実装されないのでやりたいけど後回し
| 効果         | txtマークアップ      | htmlタグとClass(閉じ省略)                    | 概要/デフォ設定
| ------------ | -------------------- | -------------------------------------------- | -----------------
| アへ声       | `(h`から`h)`         | `<span class="ltlbg_ahe">`                   | 字間サイズ傾き位置を乱す？
| エロ濁点     | `゛`                 | `<span class="ltlbg_dakten">`                | 直前の1字と縦中横？


## 雑な目的
- でんでんエディタでは対応が厳しいサイズの変換したいのでFile読込んでFile出力したい
- VivliostyleFlavoredMarkdown(VFM)より日本語小説向けのやつが欲しい
- txt<->HTMLを可逆変換したい

## 目的
小説などの形式で書かれた日本語文章を、WEBで公開するhtmlにしたりCSS組版を実施する際、
- 元の生テキスト
- CSS組版されたデータ
- WEB用にスタイリングされたデータ

を行き来する、あるいは元データを一元的に扱うために、形式化された変換(可能であればある程度の可逆変換)が求められるため、その一助となる仕組みを作る。

「WEB表示用のファイル」「組版データ」を「元の文章データ」1ソースからの生成物とした上で、「WEB表示用のファイル」「組版データ」へ加えた変更を容易に「元の文章データ」へ逆反映できるようにする。

簡易なルールだけでtxtで記載した文章をhtml化し、html(とCSS)側でtxtで表現できないスタイルを付与した後でtxtに戻す場合に、一定程度その情報を残したいときにそれを補佐する。

- 例えばtxtで「魔法」とだけ書いていた文章に、html化後にルビ「マジック」を付与した際、その情報をtxt側に保持(移送)したいが、ただhtmlタグを取ると消えてしまう。手でやると面倒。
- txtで書いていた文章をhtml化後に画面や版面を意識した形に修正した。その内容をtxtへ反映するのはかなり面倒。

それを避けるために、簡易なタグ(VFM準拠だがもう少し簡易かつ、小説のような日本語文章に特化)なものとして残すことで、文章データのソースを単一ファイルで残す。

これを実現する一連の正規表現置換のトランザクション化を期待するもの。

VFMは、Markdownの「HTMLコードはそのままHTMLコードとして出力する」の仕様を踏襲しているため、ここで作成された.htmlファイルを.mdにリネームしてVFMで扱うMarkdownファイルとして扱い、VFMでの追加修飾の原版とすることも可能と考えている。

``` mermaid
flowchart LR

subgraph 元の文章データ.txt
一定の書式
end

元の文章データ.txt <==> littlebug.sh((littlebug.sh))

一定の書式 -.固定的な対表現.- littlebug.css>littlebug.css]

subgraph 文章データ.html
WEBコンテンツ(WEBコンテンツ)
組版素材(組版素材)
end

littlebug.sh <==> 文章データ.html
littlebug.css -.一定の表示保証.-> 文章データ.html
```

> - WEBや組版の都合でhtml側に文章データの変更があっても、元の文章データへの逆反映を容易にしたい
> - htmlコンテンツ作成中や組版作業中にも元の文章データを気軽に加筆・修正したい。

## ターゲット
- **自分**
- 日本語文章、特に小説などをテキストエディタで書いている人
- 変換したい文章が長い(文庫本1冊とか)
- テキストでSS書くときにも「ルビ」「傍点」「章」程度の記述をしてる人(各種マークダウンとか)
  - 当アプリでは、可能な限り
    - [VFM](https://github.com/vivliostyle/vfm)
    - [でんでんマークダウン](https://conv.denshochan.com/markdown)
    - [Pixiv小説特殊タグ](https://www.pixiv.help/hc/ja/articles/235584168-%E5%B0%8F%E8%AA%AC%E4%BD%9C%E5%93%81%E3%81%AE%E6%9C%AC%E6%96%87%E5%86%85%E3%81%AB%E4%BD%BF%E3%81%88%E3%82%8B%E7%89%B9%E6%AE%8A%E3%82%BF%E3%82%B0%E3%81%A8%E3%81%AF-)
    - [カクヨム記法](https://kakuyomu.jp/help/entry/notation)
    <br>に寄せようとしています
- WEBで公開するために、簡単にhtmlファイルにしたい人
- 同人誌として組版する際に、CSS組版を使用したい人
  - [VivliostyleViewer](https://vivliostyle.org/)での解釈を想定
- 「WEB表示用のファイル」「組版データ」を「元の文章データ」1ソースで管理したい人
- WindowsやMac用のリッチなアプリが使えない環境の人
  - Chromebookとか、RaspberryPiとか

## メリット
- 生htmlと.mdファイルの解釈順で消耗しない
- 生html(とCSS)が出力されるので、そのままWEBサイトの素材にもできる
- 小説みたいなレイアウトの日本語文章に機能を絞っている
- 変換後のHTMLタグに本アプリで出力したことを明示するクラスを必ず付与しており、テキストエディタなどでの後からのメンテナンスで目印にできる
  - これによって、当アプリによって付与されたタグ除去を含む可逆変換を実現しています

## デメリット
- でんでんマークダウン、VFM、Pixiv小説、カクヨム、複数の形式を継ぎ接ぎしているのでそれなりの学習コストがある

## 注意
- **ぶっちゃけ自分用です**
- htmlを生成する際、段落と、カッコ類の扱いについて、かなりイロモノな設定を行う想定のhtmlを生成します。
  - [■カッコ類について](#■カッコ類について)
  - [段落の表現](#段落の表現)
- htmlからtxtに変換する際、一定程度のタグが残る。
  - txtで文章を書く際にも一定程度のタグを直書きしている人をターゲットにしている
- これは組版を実施するものではない
- このアプリは[VivliostyleProject](https://vivliostyle.org/ja/)とは直接関係していません
- [スコープアウト](#スコープアウト)参照

## 形式
1. bashスクリプト(要Linux環境)
- 引数
  - 対象ファイル
  - 変換方向
    1. htmlタグを付与し、Styleを適用できる形にする
    2. htmlタグを除去し、特定の文字を復旧して、一定程度の規則を持ったtxtファイルに戻す
2. CSSファイル

- 基礎CSS…縦書き横書きに関わらないスタイル
- 縦書用CSS…縦書きのときにのみ有効になるスタイル
- 横書用CSS…横書きのときにのみ有効になるスタイル
  - 縦書用CSSに対応する形で作成しているだけで、横書用CSSを使用する特別の理由はない想定
  - ※基礎CSSは横書用とほぼ等しい

   html化した際に、最低限の表示を担保するstyleを記載したもの。

   元ファイルに関らず3種類、同じもの。
   
   生成するのではなく、ここに同梱する。

## スコープアウト
- htmlのタグを挿入するにあたり、組版後の縦書きと横書きを意識すること(デフォルトは横書き)
  - これは組版をするものではない
  - とはいえ縦横で必要な約物/記号/表示が異なることはあるため、一定程度区別する
- 後述の、セクションを指定する文字などを可変とすること、またこの文字をエスケープできるようにすること
  - めんどくさい
- html化時の、章番号の自動採番
  - めんどくさい
- ルビの母字に対する配置距離
  - めんどくさい
- 数式や注釈はしらない。VFMかCSS直でやってください。
  - 注釈：txtで書くときには結局手動で後ろに書きがち
  - 数式：しらん
- 行の文字数をまたぐ単語、サイズ拡大文字の対応
  - 今の所目視…
- VFMの完全なフォロー
  - 今後VFM側に変更があったとき、**私が気付けば**追従して変更する。

## 名前について
ぼくはリグルくんがすきです。

## Q
- 最初からでんでんマークダウン/VFMで書けば？
  - ごもっとも。但し、以下を主目的にしています。
    - 可逆変換
    - 小説みたいな日本語文章に特化
    - ファイル長がまあまあでかくても使える
- txt側にタグ残りすぎ
  - 可逆にするためなので
  - 残すタグを「ルビ」と「傍点」と「章」だけにする破壊変換なモードを検討中です

---

# .txtと.htmlの約物、特殊文字の定義
可逆変換を実現するため、なるべく多義性を持たないよう対定義する。

## ■改行について
- txtの改行
  - ハード改行(`\n`、`\r`、`\r\n`)
- htmlの改行
  - `改行クラス`を指定した`br`タグ+ハード改行(`\n`)
  - ※特別なスタイルは指定していない。Littlebugによって付与されたことを明示するクラス。

> `\r`、`\r\n`は予め`\n`へ置換する

## ■空行について
- txtの空行1行(行頭`\n`) = htmlの行頭`br`タグ(`空行クラス`指定)
> 追加で、行頭に登場するクラス指定なしの`br`タグは、`空行クラス`を**強制適用**する

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
  - ※特別なスタイルは指定していない。Littlebugによって付与されたことを明示するクラス。

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
  - 行頭`[chapter(:章Index)]`の文字から、次の行頭`[chapter(:章Index)]`の文字の手前まで(Pixiv小説)
    - `章Index`は必須ではない。記載された場合、html化時の`section`タグに、id=[`:章Index`]で要素が追加される。
    - この`章ラベル`は`章Index`ではない(同じにしても良い)。
- htmlの章
  - `章クラス`を指定した`section`タグに囲まれた範囲

## ■章タイトルについて
- txtでの章タイトル
  - `§`か`◆`か`■`の章を指定する文字で始まる1行
  - これらの文字の直後に現れる空白1文字(全角半角問わない)は除去する。なければそのまま。
- htmlでの章タイトル
  - `章タイトルクラス`を指定した`h2`タグに囲まれた範囲

> 章タイトルの判定にはいくつかの既定の文字を使用するが、txtからhtmlへ置換する際にはこれらの文字は**除去される**。

> `§`や`◆`や`■`にて章を記すとき、"◆"や"§"の文字を章タイトルとしたい場合には、`章クラス`の`before`や`after`の疑似要素にて指定すること。
> 
> →`§`や`◆`や`■`の文字を残すと、章番号を先頭に見出しとしたいケースで邪魔になる

### 章タイトルの表現
`章タイトル(見出し)`は、`章の区間`とは**密結合しない**。  

一般的に、章タイトルは章の冒頭にあるものと先入されるが、これを切り離す。

`h`系タグの開始前に強制的に章区切り用merginがつくような、テキストで文章を書いている人間にとって非直観的な記述をやめる。

**章タイトルは「タイトル」→文字列の表現**。<br>
**章の区切りは「区切り」→レイアウトの表現**。<br>
**別物とする**。

これにより、章区切りから数行導入があって章タイトルが表示されるような演出が可能。

## 作品タイトルについて
- txt
  - ファイル名
- html
  - `作品タイトル`クラスを指定した`title`タグ
  - `作品タイトル`クラスを指定した`h1`タグ

> htmlからtxtへ変換する際は、`title`タグを変換元とする。
> あまり使用を想定していない。

## ■改ページについて
ページの途中で行われる能動的な改ページ指示のこと。文字数が1ページぶんを超えて次のページへ進む「ページ送り」のことではない。
- txt
  - `[newpage]`の文字(Pixiv小説形式)
    - CSS組版で常用される、「特定のタグの開始/終了に改行を指定する(`page-break`疑似要素での指定)」方式は、文章書き、特にテキストで執筆する者には馴染みがない。
    - 基本的にtxt形式のデータには登場しない想定。改ページ指定済みのhtmlをtxtに直したときに情報が残るよう指定するもの
- html
  - `終了後改ページクラス`を指定した**空の**`div`タグ

> 段落後に自動改ページすることは想定していない。
> 必要であればCSSのカスタマイズで対応する制限とする。
> 改ページする空div要素という点ではでんでんマークダウンの型式に近いが、ページ番号を手で書くことは少ない想定でPixiv小説との折衷案

## ■ルビについて
- txt
  - `{母字｜ルビ}`による形式(VFM/でんでんマークダウン)
- html
  - `ルビクラス`を指定した`<ruby>、<rt>`タグによる形式
  - ※特別なスタイルは指定していない。Littlebugによって付与されたことを明示するクラス。

> 母字とルビの距離については操作を諦める。
> 組版時には行間を縛る障害になるが、技術的にコストが高い。

## ■傍点(圏点)について
- txt
  - `《《kenten》》`による形式(カクヨム)
    - VFMでは圏点は定義されておらず、でんでんマークダウンでは縦書き時に限定される。また、太字とも区別したいため、これを採用。
- html
  - `圏点クラス`を指定した`span`タグ
  - デフォルトは黒ゴマ

## ■太字について
### 定義
- txt
  - `**太字**`での形式(でんでんマークダウン/一般的なMarkdown)
- html
  - `太字クラス`を指定した`span`タグ

### 太字と他の修飾の共存について
太字と、ルビ/圏点は共存可能とする。

その際、太字指定を他のタグより内側に記述するよう制限する。

> 制限事項は調査中…
> 太字化によって行間がずれないよう調整が必要？

## ■縦中横について
- txt
  - `^yo^`による形式(でんでんマークダウン型式)、**半角2文字限定**
- html
  - `縦中横クラス`を指定した`span`タグ

※`縦中横`は縦書き用の表現なので、横書きでは特に何もおこらない。

## 水平(垂直)線について
- txt
  - `---`のみの行
- html
  - `hr`タグ

一般的な区切り線だが、見た目のみのものとする。章や段落などの構造の区切りとしての機能は持たせない。

## ■カッコ類について
### 定義
- txt
  - 行頭から始まる「」、（）、〝〟記述されたまま
- html
  - カッコ類は、「」、（）、〝〟それぞれの`括弧クラス`を指定した`div`タグの範囲

>行頭ではないところから始まる括弧はそのまま残存させる

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

この`括弧クラス`を指定した`div`タグでは`「」`や`（）`、`〝〟`の括弧類の文字は、疑似要素`before`、`after`に取り込むことを想定しており、txtからhtmlに変換した際には**括弧類は文字としては除去される**。

htmlからtxtへ変換する際には、`括弧クラス`を判断して該当の括弧類の文字へ置換する。

## ダーシについて
- txt
  - "―"1つ、もしくは2つ
- html
  - `倍サイズクラス`を指定した`span`タグで囲んだ"―"1つ

> txtからhtmlに変換する際、"――"は予め"―"へ置換する。
> htmlからtxtへ変換する際には、必ず"――"(2つ分)へ置換する。

倍サイズとなった結果、行末が限界をはみ出す可能性があるが、それはやむなしとする([スコープアウト](#スコープアウト)項目)。

## 踊り字について

- txt
  - `／＼`
  - `〱`
- html
  - `踊り字クラス`を適用した空`span`タグ2種類(前と後ろ)
    - `before`/`after`疑似要素で"〳"と"〵"を指定する。
    - 縦書きの場合は、`transform: rotate`をカスタムすること
    - 縦書きの場合と横書きの場合で、字順が違うのも注意
    - 縦書き横書きの意識は[スコープアウト](#スコープアウト)しているので、手カスタマイズでお願いします

> 濁点付きの踊り字は使用しない。
> txtからhtmlへ変換する際は二者どちらからでも変換する
> htmlからtxtへ置換する際は、`／＼`に変換する

## 半角英数について
> 全角英数についてはそのまま文字として扱う。
- txt
  - そのまま記述されている
  - 但し、`縦中横クラス`が適用されていないもの
  - かつ、奇数文字数の文字列
- html
  - `偶数長化処理`を施す
  - 右に半角1文字分のマージンを指定

### 偶数長化処理
独自のものなので記載する。

以下は、私個人の好み。

- 半角2文字で全角1文字になってほしい
  - **小説でも等幅フォント派**
- 版面として、マス目にハマるように並んでほしい
- 半角英数字は1マスに2文字入り、ずれてほしくない
  - 両端揃え(均等割付け)でズレるのが好きじゃない
  - ズレるくらいならケツに半角空白が入るほうがマシ

これに従って施される処理。

1. 連続する半角英数字・半角空白文字を検出する
     - htmlタグは除く
2. その文字列長を算出する
   - もし偶数であれば
     - 何もしない
   - もし奇数であれば
     - 末尾に半角1文字分のマージンを指定する(`span`タグ)

## その他、1文字記号
### 概要
- 縦書きの際、フォントによって、`：`(コロン)や`；`(セミコロン)がうまく回転しない文字がある
- 横書きでも、絵文字など等幅が実現できない文字がある

細かい調整はユーザ側に委ねる前提でこれに対応するために

- 回転
- 幅の指定
- 位置

をStyle側で調整するもの。
**対象は1文字だけとし、2文字以上含まれる場合はHITしない**

これらは主として、html+CSS側で加えた修正をtxt復帰時に残置するためのもの。
- テキストで文章書いてるときに回転のことを考えながら書いてる人は…あんまいないだろうし
- 縦書きにしてみたら/htmlで表示してみたら表示が崩れてたんでこれらのスタイルを適用して修正する、という利用方法を想定している

## ■文字の強制回転
主に縦書きで使用することを想定するが、横書きでも機能するようにする。

デフォルトは90度回転。

- txt
  - `[^字^]`
- html
  - `回転クラス`を指定した`span`タグ
  - `1文字幅クラス`同様に、幅の調整も含む。

## ■文字幅の強制一致
主に横書きで使用することを想定
- txt
  - `[-字-]`
- html
  - `1文字幅クラス`を指定した`span`タグ


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

……加筆中……
