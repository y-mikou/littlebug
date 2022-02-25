#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

filecontent=$( cat ${destFile} )

# 改行→改行タグ
# crlf→lf してから cr|lf→<br>+lfに
#echo -e "${filecontent//$'\r\n'/$'\n'}") | echo -e "${filecontent//[$'\r'$'\n']/<br>$'\n'}" >tmp.txt
sed -z 's/\r\n/\n/g' ${tgtFile} | sed -z 's/[\r\n]/<br>\n/g' >tmp.txt

## 行頭<br>を、<br class="blankline">に
sed -e '/^<br>/c <br class="blankline">' tmp.txt >tmp2.txt

##{母字|ルビ}となっているものを<rb>母字<rt>ルビ</t></rb>へ
sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby>\1<rt>\2<\/rt><\/ruby>/g' tmp2.txt >tmp.txt

##《《母字》》となっているものを<span class="emphasis">母字</span>へ
sed -e 's/《《\([^《]\+\)》》/<span class="emphasis">\1<\/span>/g' tmp.txt >tmp2.txt

## [newpage\]を、<br class="blankline">に
sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' tmp2.txt >tmp.txt

## ――を―へ | ―を<br class="wSize">―</span>に
sed -e 's/――/―/g' tmp.txt | sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' >${destFile}
