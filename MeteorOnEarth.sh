#!/bin/bash
export lang=ja_jp.utf-8

tgtFile="${1}"   #引数で指定されたファイルを対象とする
chrEmph="${2}"   #引数で指定された文字を傍点文字とする

#出力ファイルの指定する
dstFile="${tgtFile/.txt/_moe.txt}"
touch "${dstFile}"

# チェック #################################################
if [ ! -e ${tgtFile} ]; then
  echo "💩 そんなファイルいないです"
  exit 1
fi

#入れ子検知チェックをいれる

if [ ${#chrEmph} -eq 0 ]; then
  echo "🍕 第2引数がないので傍点文字は「・」になります"
  chrEmph='・'
fi

if [ ! ${#chrEmph} -eq 1 ]; then
  echo "🍕 傍点文字は1文字にしてください"
  exit 1
fi

# 入力ファイルがSJISだったら、UTF8に変換する
if [ "${chrset##*charset=}" = "unknown-8bit" ]; then
  iconv -f SHIFT_JIS -t UTF-8 "${tgtFile}" >tmp1_moe
else
  cat "${tgtFile}" >tmp1_moe
fi
# 後続処理ファイルはtmp1_moe

# 変換処理 ###############################################

cat tmp1_moe \
| grep -E -o "《《[^》]+》》"  \
| uniq \
> tgtStr_moe

## 中間ファイルreplaceSeed(《《[^》]*》》で抽出したもの)の長さが0の場合、処理しない
if [ ! -s tgtStr_moe ]; then 
  echo "🤔 変換対象はありませんでした"
  exit 1
fi

cat tgtStr_moe \
| sed -e 's/《《//g' \
| sed -e 's/》》//g' \
| while read line || [ -n "${line}" ]; do
      echo "${line}" \
    | sed -e 's/\(.\)/｜\1《'${chrEmph}'》/g'
  done > dstStr_moe

paste -d / tgtStr_moe dstStr_moe \
  | sed -e 's/^/\| sed -e '\''s\//' \
  | sed -e 's/$/\/g'\'' \\/g' \
  | sed -z 's/^/cat tmp1_moe \\\n/g' \
  | sed -z 's/$/>tmp_distTxt\n/g' \
  > tmp_moe.sh
bash tmp_moe.sh 
cat tmp_distTxt > "${dstFile}"

echo "✨ "${dstFile}"を出力しました[傍点をルビに]"

# 後処理 #################################################
pth=$(pwd)
rmstrBase='rm -rf '${pth}'/'
eval $rmstrBase'*_moe'
eval $rmstrBase'tmp_moe.sh'
exit 0
