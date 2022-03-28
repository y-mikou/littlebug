#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".html"/"_removed.txt"}                 #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

# 最終的にlittlebug.shと統合する
# sed -iが何故かエラーになるので、tmpファイルで実装していく。
# 開発中は各置換を目視しやすいように、目的ごとに分割するが、最終的にワンライナーに置き換える予定

## littlebugXX.cssの読み込みを除去する
sed -z 's/<link rel=\"stylesheet\" href=\".\+littlebug.\+css\">//' ${tgtFile} >tmp

## 章区切りを[chapter:XXXX]に
### 閉じタグ</section><!--ltlbg_section-->を除去
### <section class="ltlbg_section" id="XXX">を[chapter:]へ
  sed -e 's/<\/section><!--ltlbg_section-->//g' tmp \
| sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
| sed -e 's/\[chapter:\]/\[chapter\]/g'  >tmp2

## 段落区切りを行頭空白に
### 閉じタグ</p><!--ltlbg-->を除去
### <p class="ltlbg_p">を一旦<span class="ltlbg_wSp"></span>へ
### 直後が<span class="ltlbg_talk/think/wquote">の場合、「<span class="ltlbg_wSp"></span>」を除去
  sed -e 's/<\/p><!--ltlbg_p-->//g' tmp2 \
| sed -e 's/<p class="ltlbg_p">/<span class="ltlbg_wSp"><\/span>/g' \
| sed -z 's/<span class="ltlbg_wSp"><\/span>\n<span class="ltlbg_talk">/\n<span class="ltlbg_talk">/g' >tmp

## </span><!--ltlbg_talk/think/wquote"-->をそれぞれの閉じ括弧へ
## <span class="ltlbg_talk/think/wquote">をそれぞれの開き括弧へ
  sed -e 's/<\/span><!--ltlbg_talk-->/」/g' tmp \
| sed -e 's/<\/span><!--ltlbg_think-->/）/g' \
| sed -e 's/<\/span><!--ltlbg_wquote-->/〟/g' \
| sed -e 's/<span class="ltlbg_talk">/「/g' \
| sed -e 's/<span class="ltlbg_think">/（/g' \
| sed -e 's/<span class="ltlbg_wquote">/〝/g' >tmp2

## <span class="ltlbg_tcyA">XX</span>を除去
## <span class="ltlbg_wdfix">XX</span>を除去
## <span ltlbg_semicolon>；</span>を除去
## <span ltlbg_colon>：</span>を除去
  sed -e 's/<span class="ltlbg_tcyA">\([^<]\{2\}\)<\/span>/\1/g' tmp2 \
| sed -e 's/<span class="ltlbg_wdfix">\([^<]\)<\/span>/\1/g' \
| sed -e 's/<span class="ltlbg_semicolon">；<\/span>/；/g' \
| sed -e 's/<span class="ltlbg_colon">：<\/span>/：/g' >tmp

## 括弧類段落記号を除去
  sed -e 's/<p class="ltlbg_p_brctGrp">//g' tmp \
| sed -e 's/<\/p><\!--ltlbg_p_brctGrp-->//g' >tmp2

cat tmp2 >tmp

## <span class="ltlbg_dakuten">を「゛」に復旧
## <span class="ltlbg_tcyM">XX</span>を復旧
## <span class="ltlbg_wSize">字</span>を復旧
## <span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>を復旧
  sed -e 's/<span class="ltlbg_dakuten">\(.\)<\/span>/\1゛/g' tmp \
| sed -e 's/<span class="ltlbg_tcyM">\([^<]\{1,3\}\)<\/span>/^\1^/g' \
| sed -e 's/<span class="ltlbg_wSize">\(.\)<\/span>/\1\1/g' \
| sed -e 's/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/／＼/g' >tmp2

## <span class="ltlbg_ruby" data-ruby_XXX="XXX"></span>を復旧
  sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' tmp2 \
| sed -e 's/<ruby class="ltlbg_emphasis" data-emphasis="[^"]\+">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/《《\1》》/g' >tmp

## <h2 class="ltlbg_sectionName">\1<\/h2>を行頭◆へ
sed -e 's/<h2 class="ltlbg_sectionName">\([^<]\+\)<\/h2>/◆\1/g' tmp >tmp2

## 「<」(半角)を「&lt;」へ変換
## 「>」(半角)を「&gt;」へ変換
## 「&」(半角)を「&amp;」へ変換
## 「'」(半角)を「&quot;」へ変換
## 「"」(半角)を「&#39;」へ変換
  sed -e 's/\&amp;/&/g' tmp2 \
| sed -e 's/\&lt;/</g' \
| sed -e 's/\&gt;/>/g' \
| sed -e "s/\&quot;/'/g" \
| sed -e 's/\&#39;/\"/g' >tmp

## ここまで生じているハード空行は副産物なので削除
## その上で、<br class="ltlbg_br">、<br class="ltlbg_blankline">を削除
  sed -z 's/^\n//g' tmp \
| sed -e 's/<br class="ltlbg_br">//g' \
| sed -e 's/^<br class="ltlbg_blankline">//g' >tmp2

## <span class="ltlbg_wSp"></span>を「　」へ
  sed -e 's/<span class="ltlbg_wSp"><\/span>/　/g' tmp2 \
| sed -z 's/　\n/\n/g' >${destFile}

###########################################################################################
## ファイルが上書きできないため使用している中間ファイルのゴミ掃除。なんとかならんか…
###########################################################################################
pth=$(pwd)
rmstrBase='rm -rf '${pth}'/'
eval $rmstrBase'tmp'
eval $rmstrBase'tmp2'
