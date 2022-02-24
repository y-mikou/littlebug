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
sed -e '/^<br>/c <br class="blankline">' tmp.txt >${destFile}
