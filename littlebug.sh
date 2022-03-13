#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

# sed -iが何故かエラーになるので、tmpファイルで実装していく。
# 開発中は各置換を目視しやすいように、目的ごとに分割するが、最終的にワンライナーに置き換える予定

##########################################################################################
# 先行変換。特殊文字など、htmlタグに含まれることが多いものを先に置換する
##########################################################################################
# 特殊文字など、htmlタグに含まれることが多いものを先に置換する
##########################################################################################
## 「<」(半角)を「&lt;」へ変換
## 「>」(半角)を「&gt;」へ変換
## 「&」(半角)を「&amp;」へ変換
## 「'」(半角)を「&quot;」へ変換
## 「"」(半角)を「&#39;」へ変換
  sed -e 's/&/\&amp;/g' ${tgtFile} \
| sed -e 's/</\&lt;/g' \
| sed -e 's/>/\&gt;/g' \
| sed -e "s/'/\&quot;/g" \
| sed -e 's/"/\&#39;/g' >tmp.txt

##特殊文字変換類置換ここまで##############################################################
##########################################################################################
# 文章中に登場するスペース類はすべてタグへ置換する。
# 以降登場するスペース類はhtml上の区切り文字としてのスペースのみで、置換対象ではない
# 以降でスペースを置換したい場合は、空白クラスのタグを置換すること
##########################################################################################

## 半角SPを<span class="ltlbg_sSp">へ。
sed -z 's/\ /<span class="ltlbg_sSp"><\/span>/g' tmp.txt >tmp2.txt

## 行頭以外の全角SPを<span class="ltlbg_wSp">へ。
sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' tmp2.txt >tmp.txt

## 特定の記号(の連続)のあとに全角SPを挿入する。直後に閉じ括弧類がある場合は回避する
  sed -e 's/\([！？♥♪☆\!\?]\+\)\(<span class="ltlbg_wSp"><\/span>\)\?/\1\<span class="ltlbg_wSp"><\/span>/g' tmp.txt \
| sed -e 's/<span class="ltlbg_wSp"><\/span>\([」）〟]\)/\1/g' >tmp2.txt

##文章中スペース類置換ここまで###########################################################

# 改行→改行タグ
# crlf→lf してから cr|lf→<br>+lfに
sed -z 's/\r\n/\n/g' tmp2.txt | sed -z 's/[\r\n]/<br class="ltlbg_br">\n/g' >tmp.txt

## 行頭<br>を、<br class="ltlbg_blankline">に
sed -e '/^<br>/c <br class="ltlbg_blankline">' tmp.txt >tmp2.txt

##{母字|ルビ}となっているものを<ruby class="ltlbg_ruby">母字<rt>ルビ</t></ruby>へ
sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby class="ltlbg_ruby">\1<rt>\2<\/rt><\/ruby>/g' tmp2.txt >tmp.txt

##《《母字》》となっているものを<span class="ltlbg_emphasis">母字</span>へ
sed -e 's/《《\([^《]\+\)》》/<span class="ltlbg_emphasis">\1<\/span>/g' tmp.txt >tmp2.txt

## [newpage\]を、<br class="ltlbg_blankline">に
sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' tmp2.txt >tmp.txt

## ――を―へ | ―を<br class="ltlbg_wSize">―</span>に
sed -e 's/――/―/g' tmp.txt | sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' >tmp2.txt

## **太字**を<br class="ltlbg_wSize">―</span>に
sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' tmp2.txt >tmp.txt

## 行頭を§◆■の次に空白(なくても良い)に続く行を、<br class="ltlbg_sectionName">章タイトル</span>に
sed -e 's/^[§◆■][ 　]*\(.\+\)<br class="ltlbg_br">/<span class="ltlbg_sectionName">\1<\/span><br class="ltlbg_br">/g' tmp.txt >tmp2.txt

cat tmp2.txt >tmp.txt #順序入れ替え時の不整合修正の糊

## ／＼もしくは〱を、<span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>に
sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' tmp.txt >tmp2.txt

## 行頭全角スペースを<p>タグに
  sed -e 's/^　/<\/p>\n<p class="ltlbg_p">\n/g' tmp2.txt \
| sed -z '1,/\n<\/p>\n/s/<\/p>\n//' \
| sed -z 's/$/<\/p>\n/' \
| sed -z 's/<p class="ltlbh_p">\n<p class="ltlbh_p">/<p class="ltlbh_p">\n/g' \
| sed -z 's/\n<\/p>\n<\/p>/<\/p>/g' >tmp.txt

cat tmp.txt >tmp2.txt #順序入れ替え時の不整合修正の糊

## [capter]を<section class="ltlbg_section">に。:XXXXXはid="XXXX"に。
  sed -z 's/^/<section class="ltlbg_section">\n/g' tmp2.txt \
| sed -z 's/\[capter:/[capter id=/g' \
| sed -z 's/\[capter\( id=\([^[]\+\)\)\?\]/<\/section>\n<section class="ltlbg_section"\1>\n/g' \
| sed -e 's/id=\([^>]\+\)\+>/id="\1">/' \
| sed -z 's/<section class="ltlbg_section"\( id="[^"]\+"\)\?>\n<br class="ltlbg_br">/<section class="ltlbg_section"\1>/g' \
| sed -z '1,/<\/section>\n/s/<\/section>\n//' \
| sed -z 's/$/<\/section>\n/' \
| sed -z 's/<section class="ltlbg_section">\n<section class="ltlbg_section"/<section class="ltlbg_section"/g' \
| sed -z 's/<\/section>\n<\/section>/<\/section>/g' >tmp.txt

## ---を<span class="ltlbg_hr">へ。
sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' tmp.txt >tmp2.txt

## 英数字2文字と、！？!?の重なりを<span class="ltlbg_tcy">にする
  sed -z 's/\([^a-zA-Z0-9<_\&#;\^]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9>_\&#;\^]\)/\1<span class="ltlbg_tcy">\2<\/span>\3/g' tmp2.txt \
| sed -z 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">!!<\/span>\3/g' \
| sed -z 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">??<\/span>\3/g' \
| sed -z 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">!?<\/span>\3/g' \
| sed -z 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">?!<\/span>\3/g' >tmp.txt

## [-字-]を<span class="ltlbg_wdfix">へ
## 特定の文字についてはltlbg_wSpを挿入されている可能性がるのでそれも考慮した置換を行う
sed -e 's/\[\-\(.\)\(<span class="ltlbg_wSp"><\/span>\)\?\-\]/<span class="ltlbg_wdfix">\1<\/span>\2/g' tmp.txt >tmp2.txt

## [^字^]を<span class="ltlbg_rotate">へ
## ^字^でtcyになっている可能性があるので考慮する。
## 前段で、特定の文字についてはltlbg_wSpを挿入されているが、その空白は消す。
sed -e 's/\[\(\^\|<span class="ltlbg_tcy">\)\(.\)\(\^\|<\/span>\)\]/<span class="ltlbg_rotate">\2<\/span>/g' tmp2.txt >tmp.txt

## ^と^に囲まれた1〜2文字の範囲を、<br class="ltlbg_tcy">縦中横</span>に。[^字^]は食わないように
sed -e 's/\([^[]\)\^\([^\^]\{1,2\}\)\^\([^]]\)/\1<span class="ltlbg_tcy">\2<\/span>\3/g' tmp.txt >tmp2.txt

## 縦書きの際、「;」「；」に<span ltlbg_semicolon>を適用する
sed -e 's/\(；\|\;\)/<span class="ltlbg_semicolon">；<\/span>/g' tmp2.txt >tmp.txt

## 縦書きの際、「:」「：」に<span ltlbg_colon>を適用する
sed -e 's/\(：\|\:\)/<span class="ltlbg_colon">：<\/span>/g' tmp.txt >tmp2.txt

## 行頭「ではじまる、」までを<div class="ltlbg_talk">にする
sed -e 's/^「\(.\+\)」/<span class="ltlbg_talk">\1<\/span>/g' tmp2.txt >tmp.txt
## 行頭（ではじまる、）までを<div class="ltlbg_talk">にする
sed -e 's/^（\(.\+\)）/<span class="ltlbg_think">\1<\/span>/g' tmp.txt >tmp2.txt
## 行頭〝ではじまる、〟までを<div class="ltlbg_wquote">にする
sed -e 's/^〝\(.\+\)〟/<span class="ltlbg_wquote">\1<\/span>/g' tmp2.txt >${destFile}
