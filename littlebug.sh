#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

filecontent=$( cat ${destFile} )

# 改行→改行タグ
# crlf→lf してから cr|lf→<br>+lfに
#echo -e "${filecontent//$'\r\n'/$'\n'}") | echo -e "${filecontent//[$'\r'$'\n']/<br class="ltlbg_br">$'\n'}" >tmp.txt
sed -z 's/\r\n/\n/g' ${tgtFile} | sed -z 's/[\r\n]/<br class="ltlbg_br">\n/g' >tmp.txt

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
sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' tmp2.txt  >tmp.txt

## 行頭を§◆■の次に空白(なくても良い)に続く行を、<br class="ltlbg_sectionName">章タイトル</span>に
sed -e 's/^[§◆■][ 　]*\(.\+\)<br class="ltlbg_br">/<span class="ltlbg_sectionName">\1<\/span><br class="ltlbg_br">/g' tmp.txt  >tmp2.txt

## ^と^に囲まれた範囲を、<br class="ltlbg_tcy">縦中横</span>に
sed -e 's/\^\([^\^]\+\)\^/<span class="ltlbg_tcy">\1<\/span>/g' tmp2.txt  >${destFile}
