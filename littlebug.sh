#!/bin/bash
tgtFile=${1}                                       #引数で指定されたファイルを対象とする
#convMode=${2:=1}                                   #引数2は未対応
destFile=${tgtFile/".txt"/"_littlebugResult.html"} #出力ファイルの指定する
touch ${destFile}                                  #出力先ファイルを生成

filecontent=$( cat ${tgtFile} )

# 改行→改行タグ
## crlf→<br>
(echo -e "${filecontent//$'\r\n'/<br>$'\n'}")>${destFile}
## cr→<br>
(echo -e "${filecontent//$'\r'/<br>$'\n'}")>${destFile}
## lf→<br>
(echo -e "${filecontent//$'\n'/<br>$'\n'}")>${destFile}
