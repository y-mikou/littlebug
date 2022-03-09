#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

# sed -iが何故かエラーになるので、tmpファイルで実装していく。
# 開発中は各置換を目視しやすいように、目的ごとに分割するが、最終的にワンライナーに置き換える予定

## 半角SPを<span class="ltlbg_sSp">へ。
sed -z 's/\ /<span class="ltlbg_sSp"><\/span>/g' ${tgtFile} >tmp.txt

## 行頭以外の全角SPを<span class="ltlbg_wSp">へ。
sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' tmp.txt >tmp2.txt

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

## ^と^に囲まれた範囲を、<br class="ltlbg_tcy">縦中横</span>に
sed -e 's/\^\([^\^]\+\)\^/<span class="ltlbg_tcy">\1<\/span>/g' tmp2.txt >tmp.txt

## ／＼もしくは〱を、<span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>に
sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' tmp.txt >tmp2.txt

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
sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' tmp.txt >${destFile}