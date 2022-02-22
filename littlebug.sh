#!/bin/bash
tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

# 改行→改行タグ
## crlf→lf してから cr|lf→<br>+lfに
filecontent=$( cat ${tgtFile} )
(echo -e "${filecontent//$'\r\n'/$'\n'}")>${destFile}
filecontent=$( cat ${destFile} )
(echo -e "${filecontent//[$'\r'|$'\n']/<br>$'\n'}")>${destFile}

filecontent=$( cat ${destFile} )
