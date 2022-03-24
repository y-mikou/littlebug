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
##########################################################################################
# 特殊文字など、htmlタグに含まれることが多いものを先に置換する
##########################################################################################
## 「<」(半角)を「&lt;」へ変換
## 「>」(半角)を「&gt;」へ変換
## 「&」(半角)を「&amp;」へ変換
## 「'」(半角)を「&quot;」へ変換
## 「"」(半角)を「&#39;」へ変換
## ――を―へ変換
  sed -e 's/&/\&amp;/g' ${tgtFile} \
| sed -e 's/</\&lt;/g' \
| sed -e 's/>/\&gt;/g' \
| sed -e "s/'/\&quot;/g" \
| sed -e 's/\"/\&#39;/g' \
| sed -e 's/――/―/g' >tmp.txt

#特殊文字変換類置換ここまで##############################################################
#########################################################################################
# 文章中に登場するスペース類はすべてタグへ置換する。
# 以降登場するスペース類はhtml上の区切り文字としてのスペースのみで、置換対象ではない
# 以降でスペースを置換したい場合は、空白クラスのタグを置換すること
#########################################################################################

## 半角SPを<span class="ltlbg_sSp">へ。
## 特定の記号(の連続)のあとに全角SPを挿入する。直後に閉じ括弧類、改行、「゛」がある場合は回避する
## 行頭以外の全角SPを<span class="ltlbg_wSp">へ。
  sed -e 's/\ /<span class="ltlbg_sSp"><\/span>/g' tmp.txt \
| sed -e 's/\([！？♥♪☆\!\?]\+\)　\?/\1　/g' \
| sed -e 's/　\([」）〟゛/n]\)/\1/g' \
| sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' >tmp2.txt

# 章区切り前後の空行を削除する
## 事前に、作品冒頭に空行がある場合は削除する
  sed -z 's/\n*\(\[chapter[^]]\+\]\)\n\+/\n\1\n/g' tmp2.txt \
| sed -z '1,/^\n*/s/^\n*//' >tmp.txt

## 文章中スペース類置換ここまで###########################################################


## 英数字2文字と、！？!?の重なりを<span class="ltlbg_tcy">の変換対象にする
  sed -e 's/\([^a-zA-Z0-9\<\>]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9/</>]\)/\1^\2^\3/g' tmp.txt \
| sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">!!<\/span>\3/g' \
| sed -e 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">??<\/span>\3/g' \
| sed -e 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">!?<\/span>\3/g' \
| sed -e 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcy">?!<\/span>\3/g' >tmp2.txt

## [capter]を<section class="ltlbg_section">に。:XXXXXはid="XXXX"に。
## 章区切りのない文章対応で、先頭に必ず章を付与し、重なった章開始を除去
  sed -z 's/^/<section class="ltlbg_section">\n/g' tmp2.txt \
| sed -e 's/\[chapter:/[chapter id=/g' \
| sed -e 's/\[chapter\( id=\([^[]\+\)\)\?\]/<section class="ltlbg_section"\1>/g' \
| sed -e 's/id=\([^>]\+\)\+>/id="\1">/' \
| sed -z 's/<section class="ltlbg_section">\n<section class="ltlbg_section"/<section class="ltlbg_section"/g' >tmp.txt

## 章を閉じる
## 置換の都合上必ず生じる先頭の章閉じは削除
## 作品の末尾には必ず章閉じを付与
  sed -e 's/<section/<\/section>\n<section/g' tmp.txt \
| sed -z '1,/<\/section>\n/s/<\/section>\n//' \
| sed -z 's/$/\n<\/section>\n/' >tmp2.txt

## 行頭§◆■の次に空白(なくても良い)に続く行を、<h2 class="ltlbg_sectionName">章タイトルに
## 順序の都合上直後に</p>が現れる場合、</p>は除去
sed -e 's/^[§◆■][ 　]*\(.\+\)/<h2 class="ltlbg_sectionName">\1<\/h2>/g' tmp2.txt >tmp.txt

## 行頭全角スペースを<p>タグに
## 行頭括弧類の前に<p>タグへ
  sed -e 's/^　/<p class="ltlbg_p">/g' tmp.txt \
| sed -e 's/^「/<p class="ltlbg_p">\n「/g' \
| sed -z 's/」\n<p class="ltlbg_p">\n「/」\n「/g' >tmp2.txt

## <p>の手前に</p>
## 章区切り(終了)の手前でも段落を終了させる
## 但し章区切り(開始)、hタグ行がある行の場合は回避する
  sed -z 's/\n<p class="ltlbg_p">/<\/p>\n<p class="ltlbg_p">/g' tmp2.txt \
| sed -z 's/」<\/p>/」\n<\/p>/g' \
| sed -z 's/\n<\/section>/<\/p>\n<\/section>/g' \
| sed -z 's/<\/h2>\n<\/p>/<\/h2>/g' \
| sed -e 's/\(<section.*>\)<\/p>/\1/g' >tmp.txt

## 改行→改行タグ
## crlf→lf してから lf→<br class="ltlbg_br">+lfに
## 但し直前にブロック要素(章区切り、段落区切り、章タイトル、改ページ)がある場合は回避
  sed -z 's/\r\n/\n/g' tmp.txt \
| sed -z 's/\n/<br class="ltlbg_br">\n/g' \
| sed -e 's/\(<section.*>\)<br class="ltlbg_br">/\1/g' \
| sed -e 's/<\/section><br class="ltlbg_br">/<\/section>/g' \
| sed -e 's/<\/h2><br class="ltlbg_br">/<\/h2>/g' \
| sed -e 's/<p class="ltlbg_p"><br class="ltlbg_br">/<p class="ltlbg_p">/g' \
| sed -e 's/<\/p><br class="ltlbg_br">/<\/p>/g' >tmp2.txt

## 行頭<br>を、<br class="ltlbg_blankline">に
sed -e 's/^<br class="ltlbg_br">/<br class="ltlbg_blankline">/' tmp2.txt >tmp.txt

## 行頭「ではじまる、」までを<div class="ltlbg_talk">にする
## 行頭（ではじまる、）までを<div class="ltlbg_talk">にする
## 行頭〝ではじまる、〟までを<div class="ltlbg_wquote">にする
  sed -e 's/^「\(.\+\)」/<span class="ltlbg_talk">\1<\/span>/g' tmp.txt \
| sed -e 's/^（\(.\+\)）/<span class="ltlbg_think">\1<\/span>/g' \
| sed -e 's/^〝\(.\+\)〟/<span class="ltlbg_wquote">\1<\/span>/g' >tmp2.txt

##{母字|ルビ}となっているものを<ruby class="ltlbg_ruby">母字<rt>ルビ</rt></ruby>へ
## [newpage\]を、<br class="ltlbg_blankline">に
## ―を<br class="ltlbg_wSize">―</span>に
## **太字**を<br class="ltlbg_wSize">―</span>に
## ／＼もしくは〱を、<span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>に
## ---を<span class="ltlbg_hr">へ。
  sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt class="ltlbg_rt">\2<\/rt><\/ruby>/g' tmp2.txt \
| sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' \
| sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' \
| sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' \
| sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' \
| sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' >tmp.txt

##《《母字》》となっているものを母字と同文字数の﹅をふるルビへ置換する
## <ruby class="ltlbg_emphasis" data-ruby="﹅">母字<rt>﹅</rt></ruby>
### 圏点用変換元文字列|変換先文字列を作成する
grep -E -o "《《[^》]*》》" tmp.txt >tgt
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/.*/<ruby class=\\\\\"ltlbg_emphasis\\\\\" data-emphasis=\\\\\"/g' >1
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/[《》]//g' | sed -e 's/./﹅/g' | sed -e 's/$/\\\\\">/g' >2
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/[《》]//g' >3
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/.*/<rt>/g' >4
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/[《》]//g' | sed -e 's/./﹅/g' >5
grep -E -o "《《[^》]*》》" tmp.txt | sed -e 's/.*/<\\\\\/rt><\\\\\/ruby>/g' >6
paste 1 2 3 4 5 6 | sed 's/\t//g' >rep
paste -d \| tgt rep >replaceSeed
cat  tmp.txt >rslt.html
### 変換元文字列|変換先文字列に従って順次圏点置換を行う
while read line
do
    from="${line%%\|*}"
    to="${line##*\|}"
    str="sed -e 's/${from}/${to}/g' rslt.html"
    eval ${str} >rslt2.html
    cat rslt2.html >rslt.html
done < ./replaceSeed
cat rslt.html >tmp.txt



## [-字-]を<span class="ltlbg_wdfix">へ
## 特定の文字についてはltlbg_wSpを挿入されている可能性がるのでそれも考慮した置換を行う
sed -e 's/\[\-\(.\)\(<span class="ltlbg_wSp"><\/span>\)\?\-\]/<span class="ltlbg_wdfix">\1<\/span>\2/g' tmp.txt >tmp2.txt

## ^と^に囲まれた1〜2文字の範囲を、<br class="ltlbg_tcy">縦中横</span>に。[^字^]は食わないように
sed -e 's/\([^[]\)\^\([^\^]\{1,2\}\)\^\([^]]\)/\1<span class="ltlbg_tcy">\2<\/span>\3/g' tmp2.txt >tmp.txt

## [^字^]を<span class="ltlbg_rotate">へ
## ^字^でtcyになっている可能性があるので考慮する。
sed -e 's/\[\(\^\|<span class="ltlbg_tcy">\)\(.\)\(\^\|<\/span>\)\]/<span class="ltlbg_rotate">\2<\/span>/g' tmp.txt >tmp2.txt

## 「;」「；」に<span ltlbg_semicolon>を適用する
## 「:」「：」に<span ltlbg_colon>を適用する
  sed -e 's/\(；\|\;\)/<span class="ltlbg_semicolon">；<\/span>/g' tmp2.txt \
| sed -e 's/\(：\|\:\)/<span class="ltlbg_colon">：<\/span>/g' >tmp.txt

## 「゛」を、<span class="ltlbg_dakuten">に変換する
## 後ろスペース挿入されているケースを考慮する
  sed -e 's/\([！？♥♪☆]\)<span class="ltlbg_wSp"><\/span>゛/<span class="ltlbg_dakuten">\1<\/span><span class="ltlbg_wSp"><\/span>/g'  tmp.txt \
| sed -e 's/\(.\)゛/<span class="ltlbg_dakuten">\1<\/span>/g' >tmp2.txt


##########################################################################################
# 退避的復旧。置換対象文字に抵触するが、特例的に置換したくない箇所のみ復旧する
##########################################################################################
## chapter:XXXX には英数字が使えるのでtcyタグの当て込みがある可能性がある。それを削除する
  sed -e 's/id="\(.*\)<span class="ltlbg_tcy">\(.*\)">/id="\1\2">/g' tmp2.txt \
| sed -e 's/id="\(.*\)<\/span>\(.*\)">/id="\1\2">/g' >tmp.txt

##########################################################################################
# デバッグ用。先頭にlittlebugU.css、littlebugTD.cssを読み込むよう追記する
##########################################################################################
  sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/\.\.\/littlebugU\.css"\>\n/' tmp.txt\
| sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/\.\.\/littlebugTD\.css"\>\n/' >${destFile}

##########################################################################################
# ファイルが上書きできないため使用している中間ファイルのゴミ掃除。なんとかならんか…
##########################################################################################
pth=$(pwd)
rmstrBase='rm -rf '${pth}'/'
eval $rmstrBase'1'
eval $rmstrBase'2'
eval $rmstrBase'3'
eval $rmstrBase'4'
eval $rmstrBase'5'
eval $rmstrBase'6'
eval $rmstrBase'rep'
eval $rmstrBase'tgt'
eval $rmstrBase'replaceSeed'
eval $rmstrBase'rslt.html'
eval $rmstrBase'rslt2.html'
eval $rmstrBase'tmp.txt'
eval $rmstrBase'tmp2.txt'
