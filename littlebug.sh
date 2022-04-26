#!/bin/bash
export lang=ja_jp.utf-8

convMode=${1}  #1でtxt→html、2でhtml→txt、それ以外は今の所はエラー
tgtFile=${2}   #引数で指定されたファイルを対象とする

chrset=$(file -i ${tgtFile})

if [ ! -e ${2} ]; then
  echo "💩 そんなファイルいないです"
  exit 1
fi

if [ "${chrset##*charset=}" = "unknown-8bit" ]; then
  iconv -f SHIFT_JIS -t UTF-8 ${tgtFile} > tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >${tgtFile}
fi

if [ "${1}" = "1" ] ; then

  ## txt→html ############################################################################################

  destFile=${tgtFile/".txt"/"_tagged.html"} #出力ファイルの指定する
  touch ${destFile}                        #出力先ファイルを生成

  ##警告表示####################################################################
  # 変換不能なケースを予め抽出する。
  # 処理は中断せず最後まで行うが、警告表示を行う。
  # おそらく変換処理は成功しない。
  ##############################################################################
  ## ルビ指定の基底文字に圏点の同時指定
  cat ${tgtFile} \
  | grep -E -o -n '(\{《《[^》]+》》｜[^\}]+\})|(《《{[^｜]+｜[^\}]+}》》)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑でルビと圏点が同時に設定されています。不適切な指定です。変換結果は保証されません。' 
  fi
  ## 縦中横指定の一部に太字指定
  cat ${tgtFile} \
  | grep -E -o -n '(\^[^\*]+\*\*10\*\*[^\^]?\^)|(\^[^\*]?\*\*10\*\*[^\^]+\^)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で縦中横の一部にだけ太字が指定されています。この変換は非対応です。変換結果は保証されません。' 
  fi
  # 4文字以上の縦中横
  cat ${tgtFile} \
  | grep -E -o -n '\^[a-zA-Z0-9]{4,}\^' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で4桁以上の縦中横が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # 縦中横指定の一部にのみ圏点指定
  cat ${tgtFile} \
  | grep -E -o -n '(\^[a-zA-Z0-9]?《《[a-zA-Z0-9]+》》[a-zA-Z0-9]+\^)|\^[a-zA-Z0-9]+《《[a-zA-Z0-9]+》》[a-zA-Z0-9]?\^' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で縦中横の一部に圏点が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # ルビ指定全体に回転指定
  cat ${tgtFile} \
  | grep -E -o -n '\[\^\{[^｜]+｜[^\}]+\}\^\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑でルビ指定の全体に回転が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # 強制合字の一部を太字指定
  cat ${tgtFile} \
  | grep -E -o -n '\[l\[\*\*.\*\*.\]r\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で合字生成指定の一部にのみ太字が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # 強制合字の一部に回転指定
  cat ${tgtFile} \
  | grep -E -o -n '(\[l\[.\^.\^\]r\])|(\^\[l\[[^]]{2}\]r\]\^)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で合字生成と回転が同時に指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # アへ濁点に回転指定
  cat ${tgtFile} \
  | grep -E -o -n '\[\^.゛\^\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で濁点合字と回転が同時に指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # ルビ文字に特殊指定
  cat ${tgtFile} \
  | grep -E -o -n '(\{[^｜]+｜[^\*]?\*\*[^\*]+\*\*[^\*]?\})|({[^｜]+｜[^}]?\[\^[^\}]+\^\][^｜]?})|({[^｜]+｜[^}]?《《[^}]+》》[^}]?\})|({[^｜]+｜{[^｜]+｜[^\}]+\}\})|({[^｜]+｜[^\}]?\[l\[[^]]{2}\]r\][^\}]?\})' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑でルビ文字に修飾が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi

  # 警告表示ここまで############################################################
  ##########################################################################################
  # 先行変換：特殊文字など、htmlタグに含まれることが多いものを先に置換する
  ##########################################################################################
  ## 「&」(半角)を「＆ａｍｐ」へ変換
  ## 「<」(半角)を「&ｌｔ」へ変換(最初から&lt;と書かれているものを考慮)
  ## 「>」(半角)を「&ｇｔ」へ変換(最初から&gt;と書かれているものを考慮)
  ## 「'」(半角)を「&ｑｕｏｔ」へ変換(最初から&quot;と書かれているものを考慮)
  ## 「"」(半角)を「＆＃３９」へ変換(最初から&#39;と書かれているものを考慮)
  ## 「/」(半角)を「＆＃０４７」へ変換(最初から&#047;と書かれているものを考慮)
  ## ※全角であること、；をつけないは以降の変換に引っかからないように。
  ## 最後に復旧する。
  ## ――を―へ変換
  ## 改行コードをlfに統一
  cat ${tgtFile} \
  | sed -e 's/\&/＆ａｍｐ/g' \
  | sed -e 's/\&amp;/＆ａｍｐ/g' \
  | sed -e 's/\//＆＃０４７/g' \
  | sed -e 's/\(\(\&\|＆ａｍｐ\)#047;|\/\)/＆＃０４７/g' \
  | sed -e 's/\\/＆＃０９２/g' \
  | sed -e 's/\(\&\|＆ａｍｐ\)#092;/＆＃０９２/g' \
  | sed -e 's/>/＆ｇｔ/g' \
  | sed -e 's/\(\&\|＆ａｍｐ\)gt;/＆ｇｔ/g' \
  | sed -e 's/</＆ｌｔ/g' \
  | sed -e 's/\(\&\|＆ａｍｐ\)lt;/＆ｌｔ/g' \
  | sed -e 's/'\''/＆＃３９/g' \
  | sed -e 's/\(\&\|＆ａｍｐ\)#39;/＆＃３９/g' \
  | sed -e 's/\"/＆ｑｕｏｔ/g' \
  | sed -e 's/\(\&\|＆ａｍｐ\)#quot;/＆ｑｕｏｔ/g' \
  | sed -e 's/――/―/g' \
  | sed -z 's/\r\n/\n/g' | sed -z 's/\r/\n/g' \
  >tmp1_ltlbgtmp

  ## 行頭にしか登場しない括弧類の補完
  cat tmp1_ltlbgtmp \
  | sed -e 's/^―\(.\+\)/―\1―/g' \
  | sed -e 's/^＞\(.\+\)/＞\1＜/g' \
  >tmp2_ltlbgtmp

  cat tmp2_ltlbgtmp >tmp1_ltlbgtmp


  #変換処理の都合で、マークアップ括り順を入れ替える########################################
  #※複数文字を対象にできるタグを外側に####################################################
  ## [^《《字》》^]となっているものは、《《[^字^]》》へ順序交換する
  ## ^**字**^となっているものは、**^字^**へ順序交換する
  ## ^《《字》》^となっているものは、《《^字^》》へ順序交換する
  ## ^{基底文字｜ルビ}^となっているものは、{^基底文字^｜ルビ}へ順序交換する
  ## [^**基底文字**^]となっているものは、**[^基底文字^]**へ順序交換する
  cat tmp1_ltlbgtmp \
  | sed -e 's/\[\^《《\([^\*]\+\)》》\^\]/《《\[\^\1\^\]》》/g' \
  | sed -e 's/\^\*\*\([^\*]\+\)\*\*\^/\*\*\^\1\^\*\*/g' \
  | sed -e 's/\^《《\([^\*]\+\)》》\^/《《\^\1\^》》/g' \
  | sed -e 's/\^{\([^｜]\+\)｜\([^}]\+\)}\^/{\^\1\^｜\2}/g' \
  | sed -e 's/《《\*\*\([^\*]\+\)\*\*》》/\*\*《《\1》》\*\*/g' \
  | sed -e 's/\[\^\*\*\([^\*]\+\)\*\*\^\]/\*\*\[\^\1\^\]\*\*/g' \
  >tmp2_ltlbgtmp

  #特殊文字変換類置換ここまで##############################################################
  #########################################################################################
  # 文章中に登場するスペース類はすべてタグへ置換する。
  # 以降登場するスペース類はhtml上の区切り文字としてのスペースのみで、置換対象ではない
  # 以降でスペースを置換したい場合は、空白クラスのタグを置換すること
  #########################################################################################
  cat tmp2_ltlbgtmp >tmp1_ltlbgtmp

  ## 半角SPを<span class="ltlbg_sSp">へ。
  ## 特定の記号(の連続)のあとに全角SPを挿入する。直後に閉じ括弧類、改行、「゛」がある場合は回避する
  ## 行頭以外の全角SPを<span class="ltlbg_wSp">へ。
  cat tmp1_ltlbgtmp \
  | sed -e 's/\ /<span class=\"ltlbg_sSp\"><\/span>/g' \
  | sed -e 's/\([！？♥♪☆\!\?]\+\)　\?/\1　/g' \
  | sed -e 's/　\([」』）〟゛/n]\)/\1/g' \
  | sed -e 's/\(.\)　/\1<span class=\"ltlbg_wSp\"><\/span>/g' \
  >tmp2_ltlbgtmp

  # 章区切り前後の空行を削除する
  ## 事前に、作品冒頭に空行がある場合は削除する
  cat tmp2_ltlbgtmp \
  | sed -z 's/\n*\(\[chapter[^]]\+\]\)\n\+/\n\1\n/g' \
  | sed -z '1,/^\n*/s/^\n*//' \
  | LANG=C sed -e 's/\([^a-zA-Z0-9\<\>\^]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9\<\>\^]\)/\1~\2~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1~!!~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1~??~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1~!?~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1~?!~\3/g' \
  | sed -z 's/^/<section class=\"ltlbg_section\">\n/g' \
  | sed -e 's/\[chapter:/[chapter id=/g' \
  | sed -e 's/\[chapter\( id=\([^[]\+\)\)\?\]/<section class="ltlbg_section"\1>/g' \
  | sed -e 's/id=\([^>]\+\)\+>/id=\"\1\">/' \
  | sed -z 's/<section class=\"ltlbg_section\">\n<section class=\"ltlbg_section\"/<section class=\"ltlbg_section\"/g' \
  | sed -e 's/<section/<\/section><\!--ltlbg_section-->\n<section/g' \
  | sed -z '1,/<\/section><\!--ltlbg_section-->\n/s/<\/section><\!--ltlbg_section-->\n//' \
  | sed -z 's/$/\n<\/section><\!--ltlbg_section-->\n/' \
  >tmp2_ltlbgtmp

  ## 行頭§◆■の次に空白(なくても良い)に続く行を、<h2 class="ltlbg_sectionName">章タイトルに
  cat tmp2_ltlbgtmp \
  | sed -e 's/^[§◆■]\(.\+\)/<h2 class=\"ltlbg_sectionName\">\1<\/h2>/g' \
  >tmp1_ltlbgtmp

  ## 行頭全角スペースで始まる行を<p>タグに
  ## 行頭括弧類の前に<p class="ltlbg_brctGrp">タグ
  cat tmp1_ltlbgtmp \
  | sed -e 's/^　\(.\+\)/<p class=\"ltlbg_p\">\1<\/p><!--ltlbg_p-->/g' \
  | sed -e 's/^\([「（―『＞].\+[」』）〟―＜]\)/<p class=\"ltlbg_p_brctGrp\">\1\n<\/p><\!--ltlbg_p_brctGrp-->/g' \
  >tmp2_ltlbgtmp

  #ltlbg_p_brctGrpタグの整理
  cat tmp2_ltlbgtmp \
  | sed -z 's/<p class=\"ltlbg_p_brctGrp\">/<p class=\"ltlbg_p_brctGrp\">\n/g' \
  | sed -z 's/\([」』）〟―＜]\)\n<\/p><\!--ltlbg_p_brctGrp-->\n<p class=\"ltlbg_p_brctGrp\">\n\([「（〝『―＞]\)/\1\n\2/g' \
  >tmp1_ltlbgtmp

  ## 改行→改行タグ
  ## crlf→lf してから lf→<br class="ltlbg_br">+lfに
  ## 但し直前にブロック要素(章区切り、段落区切り、章タイトル、改ページなど)がある場合は、除去し直す
  cat tmp1_ltlbgtmp \
  | sed -z 's/\n/<br class=\"ltlbg_br\">\n/g' \
  | sed -e 's/<\/h2><br class=\"ltlbg_br\">/<\/h2>/g' \
  | sed -e 's/<p class=\"ltlbg_p_brctGrp\"><br class=\"ltlbg_br\">/<p class=\"ltlbg_p_brctGrp\">/g' \
  | sed -e 's/<\/p><\!--ltlbg_p_brctGrp--><br class=\"ltlbg_br\">/<\/p><\!--ltlbg_p_brctGrp-->/g' \
  | sed -e 's/\(<section.*>\)<br class=\"ltlbg_br\">/\1/g' \
  | sed -z 's/<\/p><\!--ltlbg_p--><br class=\"ltlbg_br\">\n<p class=\"ltlbg_p_brctGrp\">/<\/p><\!--ltlbg_p-->\n<p class=\"ltlbg_p_brctGrp\">/g' \
  | sed -z 's/\(<br class=\"ltlbg_br\">\n\)\+<h2 class=\"ltlbg_sectionName\">/\n<h2 class=\"ltlbg_sectionName\">/g' \
  | sed -z 's/<\/h2>\(\n<br class=\"ltlbg_br\">\)\+/<\/h2>/g' \
  >tmp2_ltlbgtmp

  cat tmp2_ltlbgtmp \
  | sed -e 's/^<br class=\"ltlbg_br\">/<br class=\"ltlbg_blankline\">/' \
  | sed -z 's/<br class=\"ltlbg_blankline\">\n<p class=\"ltlbg_p\">/<p class=\"ltlbg_p\">/g' \
  | sed -z 's/<br class=\"ltlbg_blankline\">\n<p class=\"ltlbg_p_brctGrp\">/<p class=\"ltlbg_p_brctGrp\">/g' \
  | sed -e 's/<\/p><\!--ltlbg_p--><br class=\"ltlbg_br\">/<\/p><\!--ltlbg_p-->/g' \
  >tmp1_ltlbgtmp

  ## 行頭「ではじまる、」までを<div class="ltlbg_talk">にする
  ## 行頭（ではじまる、）までを<div class="ltlbg_think">にする
  ## 行頭〝ではじまる、〟までを<div class="ltlbg_wquote">にする
  ## 行頭『ではじまる、』までを<div class="ltlbg_talk2">にする
  ## 行頭―ではじまる、改行までを<div class="ltlbg_dash">にする
  ## 行頭＞ではじまる、改行までを<div class="ltlbg_citation">にする
  ## これらのspanタグは複数行に渡る可能性があるため、閉じタグに<\!--ltlbg_XXX-->を付与する
  cat tmp1_ltlbgtmp \
  | sed -e 's/^「\(.\+\)」/<span class=\"ltlbg_talk\">\1<\/span><\!--ltlbg_talk-->/g' \
  | sed -e 's/^（\(.\+\)）/<span class=\"ltlbg_think\">\1<\/span><\!--ltlbg_think-->/g' \
  | sed -e 's/^〝\(.\+\)〟/<span class=\"ltlbg_wquote\">\1<\/span><\!--ltlbg_wquote-->/g' \
  | sed -e 's/^『\(.\+\)』/<span class=\"ltlbg_talk2\">\1<\/span><\!--ltlbg_talk2-->/g' \
  | sed -e 's/^―\(.\+\)―/<span class=\"ltlbg_dash\">\1<\/span><\!--ltlbg_dash-->/g' \
  | sed -e 's/^＞\(.\+\)＜/<span class=\"ltlbg_citation\">\1<\/span><\!--ltlbg_citation-->/g' \
  >tmp2_ltlbgtmp

  ############################圏点対応
  ##《《基底文字》》となっているものを基底文字と同文字数の﹅をふるルビへ置換する
  ## <ruby class="ltlbg_emphasis" data-ruby="﹅">基底文字<rt>﹅</rt></ruby>
  ### 圏点用変換元文字列|変換先文字列を作成する
  cat tmp2_ltlbgtmp >emphasisInput_ltlbgtmp
  cat emphasisInput_ltlbgtmp \
  | grep -E -o "《《[^》]+》》"  \
  | uniq \
  >tgt_ltlbgtmp
  if [ -s tgt_ltlbgtmp ]; then 
    cat tgt_ltlbgtmp \
    | sed -e 's/[《》]//g' \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/〼/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/〿/g' \
    >raw_ltlbgtmp
    cat raw_ltlbgtmp \
    | sed -e 's/\*\*//g' \
    | sed -e 's/゛//g' \
    | sed -e 's/\[\^.\^\]/﹅/g' \
    | sed -e 's/\[l\[..\]r\]/﹅/g' \
    | sed -e 's/\^.\{1,3\}\^/﹅/g' \
    | sed -e 's/~.\{2\}~/﹅/g' \
    | sed -e 's/./﹅/g' \
    >emphtmp_ltlbgtmp
    paste -d , raw_ltlbgtmp emphtmp_ltlbgtmp \
    | while read line || [ -n "${line}" ]; do 
      echo "${line##*,}" \
      | grep -E -o . \
      | sed -e 's/^/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"/' \
      | sed -e 's/$/\">/' \
      >1_ltlbgtmp
      echo "${line%%,*}" \
      | grep -E -o "(\[\^.\^\]|\^[^\^]+\^|\~[^~]{2}\~|<[^>]>[^<]+<\/>|\{[^｜]\+｜[^\}]\+\}|.゛|.)" \
      >2_ltlbgtmp
      echo "${line##*,}" \
      | grep -E -o "." \
      | sed -e 's/^/<rt>/g' \
      | sed -e 's/$/<\/rt><\/ruby>/g' \
      >3_ltlbgtmp
      paste 1_ltlbgtmp 2_ltlbgtmp 3_ltlbgtmp \
      | sed -e 's/\t//g' \
      | sed -z 's/\n//g' \
      | sed -e 's/\//\\\//g' \
      | sed -e 's/\"/\\\"/g' \
      | sed -e 's/\[/\\\[/g' \
      | sed -e 's/\]/\\\]/g' \
      | sed -e 's/\^/\\\^/g' \
      | sed -e 's/\*/\\\*/g' \
      | sed -e 's/$/\/g'\'' \\/'
      echo ''
      done \
    >rep_ltlbgtmp
    cat tgt_ltlbgtmp \
    | sed -e 's/\//\\\//g' \
    | sed -e 's/\"/\\\"/g' \
    | sed -e 's/\[/\\\[/g' \
    | sed -e 's/\]/\\\]/g' \
    | sed -e 's/\^/\\\^/g' \
    | sed -e 's/\*/\\\*/g' \
    | sed -e 's/^/\| sed -e '\''s\//' \
    | sed -e 's/$/\//g' \
    >replaceSeed_ltlbgtmp
    paste replaceSeed_ltlbgtmp rep_ltlbgtmp \
    | sed -e 's/\t//g' \
    | sed -z 's/^/cat emphasisInput_ltlbgtmp \\\n/' \
    >tmp.sh
    bash  tmp.sh >tmp1_ltlbgtmp
    cat tmp1_ltlbgtmp \
    | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">〼<rt>﹅<\/rt><\/ruby>/<span class=\"ltlbg_wSp\"><\/span>/g' \
    | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">〿<rt>﹅<\/rt><\/ruby>/<span class=\"ltlbg_sSp\"><\/span>/g' \
    | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">\([\*\^\~]\?\)<rt>﹅<\/rt><\/ruby>/\1/g' \
    >tmp2_ltlbgtmp
    cat tmp2_ltlbgtmp >emphasisOutput_ltlbgtmp
  else
    cat emphasisInput_ltlbgtmp >emphasisOutput_ltlbgtmp
  fi
  cat emphasisOutput_ltlbgtmp \
  >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >rubyInput_ltlbgtmp
  cat rubyInput_ltlbgtmp \
  | grep -E -o "\{[^｜]+｜[^}]+\}|｜[^《]+《[^》]+》" \
  | uniq \
  > tgt_ltlbgtmp
  if [ -s tgt_ltlbgtmp ]; then
    cat tgt_ltlbgtmp \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/〼/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/〿/g' \
    | sed -e 's/｜\([^《]\+\)《\([^》]\+\)》/{\1｜\2}/g' \
    >rubytmp_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/[\{\}]//g' \
    | while read line || [ -n "${line}" ]; do 
        echo -n "${line%%｜*}" \
        | sed -e 's/\*//g' \
        | sed -e 's/\[l\[[^\]\{2\}\]r\]/■/g' \
        | sed -e 's/\[\^.\^\]/■/g' \
        | sed -e 's/\~[^\~]\{2\}\~/■/g' \
        | sed -e 's/\^[^\^]\{1,3\}\^/■/g' \
        | wc -m;
      done \
    >1_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/[\{\}]//g' \
    | while read line || [ -n "${line}" ]; do 
        echo -n "${line##*｜}" \
        | sed -e 's/\~//g' \
        | wc -m;
      done \
    >2_ltlbgtmp
    paste -d , 1_ltlbgtmp 2_ltlbgtmp \
    | sed -e 's/\([0-9]\+\)\,\([0-9]\+\)/ \
      i=$((\1 * 2)); \
      if [ ${i} -ge \2 ] \&\& [ \1 -lt \2 ]; then \
        echo '"'_center'"'; \
      elif [ \1 -eq \2 ]; then \
        echo '"'_mono'"'; \
      elif [ ${i} -le \2 ] \|\| [ \1 -lt \2 ]; then \
        echo '"'_long'"'; \
      else echo '"'_short'"'; \
      fi/g' \
      >tmp.sh
    bash tmp.sh >ins_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/.\+/\| sed -e '\''s\//g' \
    >head_ltlbgtmp
    cat tgt_ltlbgtmp \
    | sed -e 's/\//\\\//g' \
    | sed -e 's/\[/\\\[/g' \
    | sed -e 's/\]/\\\]/g' \
    | sed -e 's/\^/\\\^/g' \
    | sed -e 's/\~/\\\~/g' \
    | sed -e 's/\*/\\\*/g' \
    | sed -e 's/\"/\\\"/g' \
    >tgtStr_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/.\+/\//g' \
    >slash_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/.\+/<ruby class=\"ltlbg_ruby\" data-ruby/g' \
    >rubyTag1_ltlbgtmp
    cat ins_ltlbgtmp \
    | sed -e 's/$/=\\\"/g' \
    >rubyType_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/[\{\}]//g' \
    | sed -e 's/^[^｜]\+｜//g' \
    | sed -e 's/\~\([a-zA-Z0-9!?]\{2\}\)\~/\1/g' \
    | sed -e 's/\//\\\//g' \
    | sed -e 's/\[/\\\[/g' \
    | sed -e 's/\]/\\\]/g' \
    | sed -e 's/\^/\\\^/g' \
    | sed -e 's/\*/\\\*/g' \
    | sed -e 's/\"/\\\"/g' \
    | sed -e 's/〼/　/g' \
    | sed -e 's/〿/ /g' \
    >rubyStr_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/.\+/\\\">/g' \
    >rubyTag2_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/[\{\}]//g' \
    | sed -e 's/｜.\+$//g' \
    | sed -e 's/\//\\\//g' \
    | sed -e 's/\[/\\\[/g' \
    | sed -e 's/\]/\\\]/g' \
    | sed -e 's/\^/\\\^/g' \
    | sed -e 's/\~/\\\~/g' \
    | sed -e 's/\*/\\\*/g' \
    | sed -e 's/\"/\\\"/g' \
    | sed -e 's/$/<rt>/g' \
    >rubyBase_ltlbgtmp
    cat rubytmp_ltlbgtmp \
    | sed -e 's/.\+/<\\\/rt><\\\/ruby>/g' \
    >rubyTag3_ltlbgtmp
    paste head_ltlbgtmp tgtStr_ltlbgtmp slash_ltlbgtmp >RepStr1_ltlbgtmp
    paste rubyTag1_ltlbgtmp rubyType_ltlbgtmp rubyStr_ltlbgtmp rubyTag2_ltlbgtmp >RepStr2_ltlbgtmp
    paste rubyBase_ltlbgtmp rubyStr_ltlbgtmp rubyTag3_ltlbgtmp >RepStr3_ltlbgtmp
    paste RepStr1_ltlbgtmp RepStr2_ltlbgtmp RepStr3_ltlbgtmp \
    | sed -e 's/\t//g' \
    | sed -e 's/$/\/g'\'' \\/g' \
    | sed -z 's/^/cat rubyInput_ltlbgtmp \\\n/g' \
    >tmp.sh
    bash tmp.sh >rubyOutput_ltlbgtmp
    cat rubyOutput_ltlbgtmp >monorubyInput_ltlbgtmp
    cat monorubyInput_ltlbgtmp \
    | grep -o '<ruby class=\"ltlbg_ruby\" data-ruby_mono=\"[^>]\+\">[^<]\+<rt>[^<]\+<\/rt><\/ruby>' \
    | uniq \
    >org_ltlbgtmp
    if [ -s org_ltlbgtmp ] ; then
      cat org_ltlbgtmp \
      | sed -e 's/\//\\\//g' \
      | sed -e 's/\[/\\\[/g' \
      | sed -e 's/\]/\\\]/g' \
      | sed -e 's/\^/\\\^/g' \
      | sed -e 's/\~/\\\~/g' \
      | sed -e 's/\*/\\\*/g' \
      | sed -e 's/\"/\\\"/g' \
      | sed -e 's/^/\| sed -e '\''s\//g' \
      >tgt_ltlbgtmp
      cat org_ltlbgtmp \
      | sed -e 's/<ruby class=\"ltlbg_ruby\" data-ruby_mono=\"[^\"]\+">\([^<]\+\)<rt>\([^<]\+\)<\/rt><\/ruby>/\1,\2/g' \
      | uniq \
      | while read line || [ -n "${line}" ]; do \
          echo "${line##*,}" \
          | grep -o . \
          | sed -e 's/^/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"/g' \
          | sed -e 's/$/\">/g' \
          | sed -e 's/\//\\\//g' \
          | sed -e 's/\"/\\\"/g' \
          >rubyStr_ltlbgtmp
          echo "${line%%,*}" \
          | grep -E -o "\[l\[[^\]{2}\]r\]|\[\^.\^\]|~[^~]{2}~|\^[^\^]{1,3}\^|\*\*.|.\*\*|." \
          | sed -e 's/\//\\\//g' \
          | sed -e 's/\[/\\\[/g' \
          | sed -e 's/\]/\\\]/g' \
          | sed -e 's/\^/\\\^/g' \
          | sed -e 's/\~/\\\~/g' \
          | sed -e 's/\*/\\\*/g' \
          | sed -e 's/\"/\\\"/g' \
          >rubyBase_ltlbgtmp
          echo "${line##*,}" \
          | grep -E -o . \
          | sed -e 's/^/<rt>/' \
          | sed -e 's/$/<\/rt><\/ruby>/' \
          | sed -e 's/\//\\\//g' \
          | sed -e 's/\"/\\\"/g' \
          >rubyStr2_ltlbgtmp
          paste rubyStr_ltlbgtmp rubyBase_ltlbgtmp rubyStr2_ltlbgtmp \
          | sed -e 's/\t//g' \
          | sed -z 's/\n//g' \
          | sed -e 's/$/\/g'\'' \\/' \
          | sed -e 's/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\(.\)\\\">\\\*\\\*\([^\*]\)<rt>.<\\\/rt><\\\/ruby>/\\\*\\\*<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\1\\\">\2<rt>\1<\\\/rt><\\\/ruby>/g' \
          | sed -e 's/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\(.\)\\\">\([^\*]\)\\\*\\\*<rt>.<\\\/rt><\\\/ruby>/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\1\\\">\2<rt>\1<\\\/rt><\\\/ruby>\\\*\\\*/g'
          echo ''
        done \
      >rep_ltlbgtmp
      paste tgt_ltlbgtmp rep_ltlbgtmp \
      | sed -e 's/\t/\//g' \
      | sed -z 's/^/cat monorubyInput_ltlbgtmp \\\n/' \
      >tmp.sh
      bash tmp.sh >monorubyOutput_ltlbgtmp
    else
      cat monorubyInput_ltlbgtmp >monorubyOutput_ltlbgtmp
    fi
    cat monorubyOutput_ltlbgtmp \
    | sed -e 's/<ruby class=\"ltlbg_ruby\" data-ruby_mono=\"\([^"]\{2,\}\)\">/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\1\">/g' \
    >rubyOutput_ltlbgtmp
  else
    cat rubyInput_ltlbgtmp >rubyOutput_ltlbgtmp
  fi
  cat rubyOutput_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp \
  | sed -e 's/\(；\|\;\)/<span class=\"ltlbg_semicolon\">；<\/span>/g' \
  | sed -e 's/\(：\|\:\)/<span class=\"ltlbg_colon\">：<\/span>/g' \
  | sed -e 's/―/<span class=\"ltlbg_wSize\">―<\/span>/g' \
  | sed -e 's/\[\-\(.\)\-\]/<span class=\"ltlbg_wdfix\">\1<\/span>/g' \
  | sed -e 's/\[\^\(.\)\^\]/<span class=\"ltlbg_rotate\">\1<\/span>/g' \
  | sed -e 's/\[l\[\(.\)\(.\)\]r\]/<span class=\"ltlbg_forceGouji1\">\1<\/span><span class=\"ltlbg_forceGouji2\">\2<\/span>/g' \
  | sed -e 's/~\([a-zA-Z0-9!?]\{2\}\)~/<span class=\"ltlbg_tcyA\">\1<\/span>/g' \
  | sed -e 's/\*\*\([^\*]\+\)\*\*/<span class=\"ltlbg_bold\">\1<\/span>/g' \
  | sed -e 's/\^<span class="ltlbg_sSp"><\/span>\(..\)\^/^〿\1^/g' \
  | sed -e 's/\^\(.\)<span class=\"ltlbg_sSp\"><\/span>\(.\)\^/^\1〿\2^/g' \
  | sed -e 's/\(..\)\^<span class=\"ltlbg_sSp\"><\/span>\^/^\1〿^/g' \
  | sed -e 's/\^\([^\^]\{1,3\}\)\^/<span class=\"ltlbg_tcyM\">\1<\/span>/g' \
  | sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' \
  | sed -e 's/-\{3,\}/<hr class=\"ltlbg_hr\">/g' \
  | sed -e 's/<hr class=\"ltlbg_hr\"><br class=\"ltlbg_br\">/<hr class=\"ltlbg_hr\">/g' \
  | sed -e 's/／＼/<span class=\"ltlbg_odori1\"><\/span><span class=\"ltlbg_odori2\"><\/span>/g' \
  | sed -e 's/〱/<span class=\"ltlbg_odori1\"><\/span><span class=\"ltlbg_odori2\"><\/span>/g' \
  | sed -e 's/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\([^\"]\+\)\">／<rt>[^\<]\+<\/rt><\/ruby><ruby class=\"ltlbg_ruby\" data-ruby_center=\"\([^\"]\+\)\">＼<rt>[^\<]\+<\/rt><\/ruby>/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\1\"><span class=\"ltlbg_odori1\"><\/span><rt>\1<\/rt><\/ruby><ruby class=\"ltlbg_ruby\" data-ruby_center=\"\2\"><span class=\"ltlbg_odori2\"><\/span><rt>\2<\/rt><\/ruby>/g' \
  | sed -e 's/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\([^\"]\+\)\">〳<rt>[^\<]\+<\/rt><\/ruby><ruby class=\"ltlbg_ruby\" data-ruby_center=\"\([^\"]\+\)\">〵<rt>[^\<]\+<\/rt><\/ruby>/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\1\"><span class=\"ltlbg_odori1\"><\/span><rt>\1<\/rt><\/ruby><ruby class=\"ltlbg_ruby\" data-ruby_center=\"\2\"><span class=\"ltlbg_odori2\"><\/span><rt>\2<\/rt><\/ruby>/g' \
  | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">／<rt>﹅<\/rt><\/ruby><ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">＼<rt>﹅<\/rt><\/ruby>/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\"><span class=\"ltlbg_odori1\"><\/span><rt>﹅<\/rt><\/ruby><ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\"><span class=\"ltlbg_odori2\"><\/span><rt>﹅<\/rt><\/ruby>/g' \
  | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">〳<rt>﹅<\/rt><\/ruby><ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\">〵<rt>﹅<\/rt><\/ruby>/<ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\"><span class=\"ltlbg_odori1\"><\/span><rt>﹅<\/rt><\/ruby><ruby class=\"ltlbg_emphasis\" data-emphasis=\"﹅\"><span class=\"ltlbg_odori2\"><\/span><rt>﹅<\/rt><\/ruby>/g' \
  | sed -e 's/\([！？♥♪☆]\)<span class="ltlbg_wSp"><\/span>゛/<span class="ltlbg_dakuten">\1<\/span><span class="ltlbg_wSp"><\/span>/g' \
  | sed -e 's/\(.\)゛/<span class="ltlbg_dakuten">\1<\/span>/g' \
  >tmp1_ltlbgtmp

  ##########################################################################################
  # 退避的復旧：置換対象文字に抵触するが、特例的に置換したくない箇所のみ復旧する
  # スペシャルロジック：タグ重複適用などで上述の置換で適応できないものを個別対応する
  ##########################################################################################
  ## chapter:XXXX には英数字が使えるのでtcyAタグの当て込みがある可能性がある。それを削除する
  ## ここでの復旧は想定外に壊れて当て込まれているものが対象なので、除去置換はほぼ個別対応
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp \
  | sed -e 's/id="\(.*\)<span class="ltlbg_tcyA[^>]\+">\(.*\)<\/span>\(.*\)>/id="\1\2\3">/g' \
  >tmp2_ltlbgtmp

  ## 特殊文字の復旧
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp2_ltlbgtmp \
  | sed -e 's/＆ａｍｐ/\&amp;/g' \
  | sed -e 's/＆ｌｔ/\&lt;/g' \
  | sed -e 's/＆ｇｔ/\&gt;/g' \
  | sed -e 's/＆＃３９/\&#39;/g' \
  | sed -e 's/＆ｅｍｓｐ/\&emsp;/g' \
  | sed -e 's/＆ｎｂｓｐ/\&nbsp;/g' \
  | sed -e 's/＆ｑｕｏｔ/\&quot;/g' \
  | sed -e 's/＆＃０４７/\&#047;/g' \
  | sed -e 's/＆＃０９２/\&#092;/g' \
  | sed -e 's/〿/<span class="ltlbg_sSp"><\/span>/g' \
  | sed -e 's/〼/<span class="ltlbg_wSp"><\/span>/g' \
  | sed -z 's/\n\n/\n/g' \
  >tmp1_ltlbgtmp

  ##########################################################################################
  # 先頭にlittlebugU.css、littlebugTD.cssを読み込むよう追記する
  ##########################################################################################
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugTD\.css"\>\n/' \
  | sed -z 's/^/\<\!--\<link rel=\"stylesheet\" href=\"\.\.\/littlebugRL\.css"\>-->\n/' \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugU\.css"\>\n/' \
  >${destFile}
  echo "✨ "${destFile}"を出力しました[html化]"
elif [ "${1}" = "2" ] ; then
  destFile=${tgtFile/".html"/"_removed.txt"}
  touch ${destFile}
  cat ${tgtFile} \
  | sed -z 's/<link rel=\"stylesheet\" href=\".\+littlebug.\+css\">//' \
  >tmp1_ltlbgtmp  
  for i in $(seq 0 2); do
    for i in $(seq 0 2); do
      cat tmp1_ltlbgtmp \
      | sed -e 's/<\/section><!--ltlbg_section-->//g' \
      | sed -e 's/<section class="ltlbg_section">/[chapter]/g' \
      | sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
      | sed -e 's/\[chapter:\]/\[chapter\]/g' \
      | sed -e 's/<\/p><!--ltlbg_p-->//g' \
      | sed -e 's/<p class="ltlbg_p">/<span class="ltlbg_wSp"><\/span>/g' \
      | sed -z 's/<span class="ltlbg_wSp"><\/span>\n<span class="ltlbg_talk">/\n<span class="ltlbg_talk">/g' \
      | sed -e 's/<\/span><!--ltlbg_talk-->/」/g' \
      | sed -e 's/<\/span><!--ltlbg_talk2-->/』/g' \
      | sed -e 's/<\/span><!--ltlbg_think-->/）/g' \
      | sed -e 's/<\/span><!--ltlbg_wquote-->/〟/g' \
      | sed -e 's/<\/span><!--ltlbg_dash-->//g' \
      | sed -e 's/<\/span><!--ltlbg_citation-->//g' \
      | sed -e 's/<span class="ltlbg_talk">/「/g' \
      | sed -e 's/<span class="ltlbg_talk2">/『/g' \
      | sed -e 's/<span class="ltlbg_think">/（/g' \
      | sed -e 's/<span class="ltlbg_wquote">/〝/g' \
      | sed -e 's/<span class="ltlbg_dash">/――/g' \
      | sed -e 's/<span class="ltlbg_citation">/＞/g' \
      | sed -e 's/<span class=\"ltlbg_tcyA\">\([^<]\{2\}\)<\/span>/\1/g' \
      | sed -e 's/<span class=\"ltlbg_wdfix\">\([^<]\)<\/span>/\1/g' \
      | sed -e 's/<span class="ltlbg_semicolon">；<\/span>/；/g' \
      | sed -e 's/<span class="ltlbg_colon">：<\/span>/：/g' \
      | sed -e 's/<p class="ltlbg_p_brctGrp">//g' \
      | sed -e 's/<\/p><\!--ltlbg_p_brctGrp-->//g' \
      | sed -e 's/<span class=\"ltlbg_dakuten\">\(.\)<\/span>/\1゛/g' \
      | sed -e 's/<span class=\"ltlbg_tcyM\">\([^<]\{1,3\}\)<\/span>/^\1^/g' \
      | sed -e 's/<span class=\"ltlbg_wSize\">\(.\)<\/span>/\1\1/g' \
      | sed -e 's/<span class=\"ltlbg_odori1\"><\/span>/／/g' \
      | sed -e 's/<span class=\"ltlbg_odori2\"><\/span>/＼/g' \
      | sed -e 's/<span class=\"ltlbg_forceGouji1\">\(.\)<\/span><span class=\"ltlbg_forceGouji2\">\(.\)<\/span>/[l[\1\2]r]/g' \
      | sed -e 's/<span class=\"ltlbg_rotate\">\(.\)<\/span>/\[\^\1\^\]/g' \
      | sed -e 's/<span class=\"ltlbg_bold\">\([^<]\+\)<\/span>/\*\*\1\*\*/g' \
      | sed -e 's/<h2 class=\"ltlbg_sectionName\">\([^<]\+\)<\/h2>/◆\1/g' \
      | sed -e 's/<hr class=\"ltlbg_hr\">/---/g' \
      >tmp1_ltlbgtmp
      cat tmp1_ltlbgtmp >tmp2_ltlbgtmp
    done
    cat tmp2_ltlbgtmp \
    | sed -e 's/&amp;/\&/g' \
    | sed -e 's/&lt;/</g' \
    | sed -e 's/&gt;/>/g' \
    | sed -e 's/&quot;/'\''/g' \
    | sed -e 's/&#39;/\"/g' \
    | sed -z 's/^\n//g' \
    | sed -e 's/<br class=\"ltlbg_br\">//g' \
    | sed -e 's/^<br class=\"ltlbg_blankline\">//g' \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/　/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/ /g' \
    | sed -z 's/　\n/\n/g' \
    | sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' \
    | sed -e 's/\*\*{\([^｜]\+\)｜\([^\}]\+\)}\*\*/{\*\*\1\*\*｜\2}/g' \
    | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\".\">\([^<]\+\)<rt>.<\/rt><\/ruby>/《《\1》》/g' \
    >tmp1_ltlbgtmp
  done
  cat tmp1_ltlbgtmp >monorubyInput_ltlbgtmp 
  cat monorubyInput_ltlbgtmp \
  | grep -E -o '(\{[^｜]+｜[^}]+\}){2,}' \
  | uniq \
  | sed -e 's/\//\\\//g' \
  | sed -e 's/\[/\\\[/g' \
  | sed -e 's/\]/\\\]/g' \
  | sed -e 's/\^/\\\^/g' \
  | sed -e 's/\~/\\\~/g' \
  | sed -e 's/\*/\\\*/g' \
  | sed -e 's/\"/\\\"/g' \
  > tgt_ltlbgtmp
  if [ -s tgt_ltlbgtmp ]; then
    cat tgt_ltlbgtmp \
    | while read line || [ -n "${line}" ]; do \
        echo ${line} \
        | grep -E -o '\{[^｜]+｜' \
        | sed -e 's/^{//g' \
        | sed -e 's/｜$//g' \
        | sed -z 's/\n//g' \
        | sed -e 's/^/\{/g' \
        | sed -e 's/\//\\\//g' \
        | sed -e 's/\[/\\\[/g' \
        | sed -e 's/\]/\\\]/g' \
        | sed -e 's/\^/\\\^/g' \
        | sed -e 's/\~/\\\~/g' \
        | sed -e 's/\*/\\\*/g' \
        | sed -e 's/\"/\\\"/g'
        echo -n '｜'
        echo ${line} \
        | grep -E -o '｜[^}]+\}' \
        | sed -e 's/^｜//g' \
        | sed -e 's/}$//g' \
        | sed -z 's/\n//g' \
        | sed -e 's/$/\}/g' \
        | sed -e 's/\//\\\//g' \
        | sed -e 's/\[/\\\[/g' \
        | sed -e 's/\]/\\\]/g' \
        | sed -e 's/\^/\\\^/g' \
        | sed -e 's/\~/\\\~/g' \
        | sed -e 's/\*/\\\*/g' \
        | sed -e 's/\"/\\\"/g'
        echo ''
    done \
    > rep_ltlbgtmp
    paste -d '/' tgt_ltlbgtmp rep_ltlbgtmp \
    | sed -e 's/^/| sed -e '\''s\//g' \
    | sed -e 's/$/\/g'\'' \\/g' \
    | sed -z 's/^/cat monorubyInput_ltlbgtmp \\\n/g' \
    > tmp.sh
    bash tmp.sh >monorubyOutput_ltlbgtmp
  else 
    cat monorubyInput_ltlbgtmp >monorubyOutput_ltlbgtmp
  fi
  cat monorubyOutput_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >emphasisInput_ltlbgtmp 
  cat emphasisInput_ltlbgtmp \
  | grep -E -o '(《《[^》]+》》[ 　]?){2,}' \
  | uniq \
  >emphtmp_ltlbgtmp
  if [ -s emphtmp_ltlbgtmp ] ; then 
    cat emphtmp_ltlbgtmp \
    | sed -e 's/\//\\\//g' \
    | sed -e 's/\[/\\\[/g' \
    | sed -e 's/\]/\\\]/g' \
    | sed -e 's/\^/\\\^/g' \
    | sed -e 's/\~/\\\~/g' \
    | sed -e 's/\*/\\\*/g' \
    | sed -e 's/\"/\\\"/g' \
    | sed -e 's/^/| sed -e '\''s\//g' \
    >tgt_ltlbgtmp
    cat emphtmp_ltlbgtmp \
    | sed -e 's/[《》]//g' \
    | sed -e 's/^/《《/g' \
    | sed -e 's/$/》》/g' \
    | sed -e 's/$/\/g'\'' \\/g' \
    >rep_ltlbgtmp
    paste -d '/t' tgt_ltlbgtmp rep_ltlbgtmp \
    | sed -z 's/^/cat emphasisInput_ltlbgtmp \\\n/g' \
    >tmp.sh
    bash tmp.sh > emphasisOutput_ltlbgtmp
  else
    cat emphasisInput_ltlbgtmp >emphasisOutput_ltlbgtmp
  fi
  cat emphasisOutput_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >${destFile}
  echo "✨ "${destFile}"を出力しました[txtもどし]"
else
  echo "💩 引数1は1(txt→html)か2(html→txt)で指定してください"
  exit 1
fi
pth=$(pwd)
rmstrBase='rm -rf '${pth}'/'
eval $rmstrBase'*_ltlbgtmp'
eval $rmstrBase'tmp.sh'
exit 0