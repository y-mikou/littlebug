#!/bin/bash
export lang=ja_jp.utf-8

tgtFile="${1}"   #引数で指定されたファイルを対象とする

#出力ファイルの指定する
dstFile="${tgtFile/.txt/_foe.txt}"
touch "${dstFile}"

# チェック #################################################
if [ ! -e ${tgtFile} ]; then
  echo "💩 そんなファイルいないです"
  exit 1
fi

# 入力ファイルがSJISだったら、UTF8に変換する
if [ "${chrset##*charset=}" = "unknown-8bit" ]; then
  iconv -f SHIFT_JIS -t UTF-8 "${tgtFile}" >tmp1_foe
else
  cat "${tgtFile}" >tmp1_foe
fi
# 後続処理ファイルはtmp1_foe

# 変換処理 ###############################################
cat tmp1_foe \
| grep -oP '{[^|{]+\｜[^｜}]+}' \
| uniq \
> tgtStr_foe
## 中間ファイルreplaceSeed(《《[^》]*》》で抽出したもの)の長さが0の場合、処理しない
if [ ! -s tgtStr_foe ]; then 
  echo "🤔 変換対象はありませんでした"
  exit 1
fi

cat tmp1_foe \
| sed -E -e 's/\{([^｜]+)｜([^｜\}]+)\}/｜\1《\2》/g' \
> tmpout_foe

cat tmpout_foe > "${dstFile}"

echo "✨ "${dstFile}"を出力しました[ {母字|ルビ}形式 → ｜母字《ルビ》形式]"

# 後処理 #################################################
pth=$(pwd)
rmstrBase='rm -rf '${pth}'/'
eval $rmstrBase'*_foe'
eval $rmstrBase'tmp_foe.sh'
exit 0
