#!/bin/bash
export lang=ja_jp.utf-8

tgtFile=${2}   #引数で指定されたファイルを対象とする

if [[ "${tgtFile/ /}" = "" ]];then
  echo "💩対象ファイルを指定してください"
  exit 1
fi

tgtFile_AfterCD='../'${tgtFile}   #一時ディレクトリの内側から参照するとき用

if [ ! -e ${tgtFile} ]; then
  echo "💩 ${tgtFile}なんてファイルいないです"
  exit 1
fi

convMode=${1}  #'-t2h'でtxt→html、'-h2t'でhtml→txt、それ以外は今の所はエラー

if [[ "${convMode}" != '-t2h' ]] && [[ "${convMode}" != '-h2t' ]] ; then
  echo "💩 引数1は-t2h(txt→html)か-h2t(html→txt)で指定してください"
  exit 1
fi

chrset=$(file -i ${tgtFile})
tmpDirName=$(mktemp -u ltlbgtmpDir_XXXXX)  #作業用ディレクトリを作成し
mkdir ${tmpDirName}                        #その中で作業する。
cd ${tmpDirName}                           #最後にディレクトリごと削除する。

if [ "${chrset##*charset=}" = "unknown-8bit" ]; then
  iconv -f SHIFT_JIS -t UTF-8 ${tgtFile_AfterCD} > tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >${tgtFile_AfterCD}
fi

if [ "${convMode}" = '-t2h' ] ; then

  ## txt→html ############################################################################################

  destFile=${tgtFile_AfterCD/".txt"/"_tagged.html"} #出力ファイルの指定する
  touch ${destFile}                        #出力先ファイルを生成

  ##警告表示####################################################################
  # 変換不能なケースを予め抽出する。
  # 処理は中断せず最後まで行うが、警告表示を行う。
  # おそらく変換処理は成功しない。
  ##############################################################################
  ## ルビ指定の基底文字に圏点の同時指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '(\{《《[^》]+》》｜[^\}]+\})|(《《{[^｜]+｜[^\}]+}》》)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑でルビと圏点が同時に設定されています。不適切な指定です。変換結果は保証されません。' 
  fi
  ## 縦中横指定の一部に太字指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '(\^[^\*]+\*\*10\*\*[^\^]?\^)|(\^[^\*]?\*\*10\*\*[^\^]+\^)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で縦中横の一部にだけ太字が指定されています。この変換は非対応です。変換結果は保証されません。' 
  fi
  # 4文字以上の縦中横
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '\^[a-zA-Z0-9]{4,}\^' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で4桁以上の縦中横が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # 縦中横指定の一部にのみ圏点指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '(\^[a-zA-Z0-9]?《《[a-zA-Z0-9]+》》[a-zA-Z0-9]+\^)|\^[a-zA-Z0-9]+《《[a-zA-Z0-9]+》》[a-zA-Z0-9]?\^' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で縦中横の一部に圏点が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # ルビ指定全体に回転指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '\[\^\{[^｜]+｜[^\}]+\}\^\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑でルビ指定の全体に回転が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # 強制合字の一部を太字指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '\[l\[\*\*.\*\*.\]r\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で合字生成指定の一部にのみ太字が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
  fi
  # 強制合字の一部に回転指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '(\[l\[.\^.\^\]r\])|(\^\[l\[[^]]{2}\]r\]\^)' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で合字生成と回転が同時に指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # アへ濁点に回転指定
  cat ${tgtFile_AfterCD} \
  | grep -E -o -n '\[\^.゛\^\]' \
  >warn_ltlbgtmp
  if [ -s warn_ltlbgtmp ] ; then 
    cat warn_ltlbgtmp
    echo '🤔 ↑で濁点合字と回転が同時に指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
  fi
  # ルビ文字に特殊指定
  cat ${tgtFile_AfterCD} \
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
  cat ${tgtFile_AfterCD} \
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
  >tmp1_ltlbgtmp
  ## 文章中スペース類置換ここまで###########################################################

  ##########################################################################################
  ##先行変換： 圏点の中に自動縦中横が含まれるものの対応対応
  ##########################################################################################
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp

  ## 英数字2文字と、！？!?の重なりを<span class="ltlbg_tcyA">の変換対象にする
  cat tmp1_ltlbgtmp \
  | LANG=C sed -e 's/\([^a-zA-Z0-9\<\>\^]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9\<\>\^]\)/\1~\2~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1~!!~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1~??~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1~!?~\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1~?!~\3/g' \
  >tmp2_ltlbgtmp

#TODO:[capter]による章指定を廃止。なくて問題なさそうなら永続的に削除する
#
#  ## [capter]を<section class="ltlbg_section">に。:XXXXXはid="XXXX"に。
#  ## 章区切りのない文章対応で、先頭に必ず章を付与し、重なった章開始を除去
#  cat tmp2_ltlbgtmp \
#  | sed -z 's/^/<section class=\"ltlbg_section\">\n/g' \
#  | sed -e 's/\[chapter:/[chapter id=/g' \
#  | sed -e 's/\[chapter\( id=\([^[]\+\)\)\?\]/<section class="ltlbg_section"\1>/g' \
#  | sed -e 's/id=\([^>]\+\)\+>/id=\"\1\">/' \
#  | sed -z 's/<section class=\"ltlbg_section\">\n<section class=\"ltlbg_section\"/<section class=\"ltlbg_section\"/g' \
#  >tmp1_ltlbgtmp
#
#  ## 章を閉じる
#  ## 置換の都合上必ず生じる先頭の章閉じは削除
#  ## 作品の末尾には必ず章閉じを付与
#  ## 章区切りは複数行に渡る可能性があるので閉じタグに<\!--ltlbg_section-->を付与する
#  cat tmp1_ltlbgtmp \
#  | sed -e 's/<section/<\/section><\!--ltlbg_section-->\n<section/g' \
#  | sed -z '1,/<\/section><\!--ltlbg_section-->\n/s/<\/section><\!--ltlbg_section-->\n//' \
#  | sed -z 's/$/\n<\/section><\!--ltlbg_section-->\n/' \
#  >tmp2_ltlbgtmp

  ## 行頭§§§の次に空白(なくても良い)に続く行を、<h2 class="ltlbg_sectionName" style="page: sukebe;">章タイトルに
  ### style="page: sukebe;"はCSS側で、当該セクション(に属すページ)がエッチシーンであることを示す
  ### ':'';'は当スクリプト内で特殊文字として操作しているため、ここには含めず、スクリプトの最後に付与し直している
  ### 印刷上は§１つだけになる
  ## 行頭§の次に空白(なくても良い)に続く行を、<h2 class="ltlbg_sectionName">章タイトルに
  ## 章タイトル付与時に、<section>の閉じ＋開始タグを付与する。
  ## 1行目が</section><!--ltlbg_section-->になるので、削除する
  ## 今は§で節を表示している
  cat tmp2_ltlbgtmp \
  | sed -e 's/^\(§§§\)\(.\{0,\}\)/<\/section><\!--ltlbg_section-->\n<section class=\"ltlbg_section\" style=\"page sukebe\"><h2 class=\"ltlbg_sectionName\">§ \2<\/h2>/g' \
  | sed -e 's/^\(§\)\(.\{0,\}\)/<\/section><\!--ltlbg_section-->\n<section class=\"ltlbg_section\"><h2 class=\"ltlbg_sectionName\">§ \2<\/h2>/g' \
  | sed -e '1d' \
  >tmp1_ltlbgtmp

  ## 行頭全角スペースで始まる行を<p>タグに
  ## 行頭括弧類の前に<p class="ltlbg_brctGrp">タグ
  cat tmp1_ltlbgtmp \
  | sed -e 's/^　\(.\+\)/<p class=\"ltlbg_p\">\1<\/p><\!--ltlbg_p-->/g' \
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
  | sed -z 's/<\/section><\!--ltlbg_section--><br class=\"ltlbg_br\">/<\/section><\!--ltlbg_section--\>/g' \
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

  ## 中間ファイルreplaceSeed(《《[^》]*》》で抽出したもの)の長さが0の場合、処理しない
  if [ -s tgt_ltlbgtmp ]; then 

    # 圏点の基底文字列のみの中間ファイルを作成する
    # ・マークアップの記号を外す
    # ・スペース類を一時的に希少な退避文字へ置換する
    cat tgt_ltlbgtmp \
    | sed -e 's/[《》]//g' \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/〼/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/〿/g' \
    >raw_ltlbgtmp

    # ルビとして振る「﹅」を、rawと同じ文字だけもった中間ファイルを作成する。
    # [^字^](回転)、[l\[左右\]r\](強制合字)、^^(縦中横)、~~(自動縦中横)は
    # 傍点観点では1文字として扱う。
    cat raw_ltlbgtmp \
    | sed -e 's/\*\*//g' \
    | sed -e 's/゛//g' \
    | sed -e 's/\[\^.\^\]/﹅/g' \
    | sed -e 's/\[l\[..\]r\]/﹅/g' \
    | sed -e 's/\^.\{1,3\}\^/﹅/g' \
    | sed -e 's/~.\{2\}~/﹅/g' \
    | sed -e 's/./﹅/g' \
    >emphtmp_ltlbgtmp
  
    # 上記で作った基底文字ファイルとルビ文字ファイルを列単位に結合する
    # その後、各行ごとに置換処理を行い、
    # 中間ファイルtgtの各行を置換元とする置換先文字列を作成する。
    ## →置換先文字列
    ## 　各行ごとに「,」の前が基底文字、「,」の後がルビ文字となっているので、
    ## 　これを利用してルビタグの文字列を作成する。
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
  ############################圏点対応

  cat tmp1_ltlbgtmp >rubyInput_ltlbgtmp
  ############################ルビ対応
  ## {基底文字|ルビ}となっているものを<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ
  ## ついでだから|基底文字《ルビ》も<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ

  ## ルビタグで抽出した結果がなければスキップ
  cat rubyInput_ltlbgtmp \
  | grep -E -o "\{[^｜]+｜[^}]+\}|｜[^《]+《[^》]+》" \
  | uniq \
  > tgt_ltlbgtmp

  if [ -s tgt_ltlbgtmp ]; then

    ## 事前にスペース類を一時退避文字へ。
    ## ルビのマークアップ表現を{｜}に統一
    cat tgt_ltlbgtmp \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/〼/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/〿/g' \
    | sed -e 's/｜\([^《]\+\)《\([^》]\+\)》/{\1｜\2}/g' \
    >rubytmp_ltlbgtmp

    ## 基底文字の長さを抽出。
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

    ## ルビ文字の長さを抽出。
    cat rubytmp_ltlbgtmp \
    | sed -e 's/[\{\}]//g' \
    | while read line || [ -n "${line}" ]; do 
        echo -n "${line##*｜}" \
        | sed -e 's/\~//g' \
        | wc -m;
      done \
    >2_ltlbgtmp

    ## 文字数の関係に従って付与する文字を出力する(該当箇所を置換する)。文字はシェルスクリプトになっている
    ## 1は基底文字の文字数、2はルビの文字数
    ## 
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

    #     sed/ {b｜r} /
    paste head_ltlbgtmp tgtStr_ltlbgtmp slash_ltlbgtmp >RepStr1_ltlbgtmp

    #     <ruby... mono..=" STR     ">
    paste rubyTag1_ltlbgtmp rubyType_ltlbgtmp rubyStr_ltlbgtmp rubyTag2_ltlbgtmp >RepStr2_ltlbgtmp

    #     Base<rt> Ruby    </rt></ruby>
    paste rubyBase_ltlbgtmp rubyStr_ltlbgtmp rubyTag3_ltlbgtmp >RepStr3_ltlbgtmp

    # sed文をtmp.shへ
    paste RepStr1_ltlbgtmp RepStr2_ltlbgtmp RepStr3_ltlbgtmp \
    | sed -e 's/\t//g' \
    | sed -e 's/$/\/g'\'' \\/g' \
    | sed -z 's/^/cat rubyInput_ltlbgtmp \\\n/g' \
    >tmp.sh
    bash tmp.sh >rubyOutput_ltlbgtmp

    cat rubyOutput_ltlbgtmp >monorubyInput_ltlbgtmp
    ## data-ruby_monoのルビタグを、モノルビに変換する
    ## 前段でdata-ruby_monoを付与したものを対象に、モノルビ置換する一時shを作成して実行する。
    ## 後続には当該shの出力をつなげる。モノルビにはshortが指定される
    cat monorubyInput_ltlbgtmp \
    | grep -o '<ruby class=\"ltlbg_ruby\" data-ruby_mono=\"[^>]\+\">[^<]\+<rt>[^<]\+<\/rt><\/ruby>' \
    | uniq \
    >org_ltlbgtmp

    ## 中間ファイルorg(モノルビタグで抽出した結果)の長さが0のとき、処理しない
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
          | sed -e 's/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\(.\)\\\">\([^\*]\)\\\*\\\*<rt>.<\\\/rt><\\\/ruby>/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"\1\\\">\2<rt>\1<\\\/rt><\\\/ruby>\\\*\\\*/g' \

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

    ## ここでdata-ruby_monoが置換されていない場合、内部にタグが含まれているなどの理由で変換がうまくできていない。
    ## data-ruby_centerへ縮退変換する。
    cat monorubyOutput_ltlbgtmp \
    | sed -e 's/<ruby class=\"ltlbg_ruby\" data-ruby_mono=\"\([^"]\{2,\}\)\">/<ruby class=\"ltlbg_ruby\" data-ruby_center=\"\1\">/g' \
    >rubyOutput_ltlbgtmp

  else
    cat rubyInput_ltlbgtmp >rubyOutput_ltlbgtmp
  fi

  #################################ルビ対応ここまで
  cat rubyOutput_ltlbgtmp >tmp1_ltlbgtmp

  # マークアップのない自動置換
  ## 「;」「；」に<span ltlbg_semicolon>を適用する
  ## 「:」「：」に<span ltlbg_colon>を適用する
  ## ―を<br class="ltlbg_wSize">―</span>に
  cat tmp1_ltlbgtmp \
  | sed -e 's/\(；\|\;\)/<span class=\"ltlbg_semicolon\">；<\/span>/g' \
  | sed -e 's/\(：\|\:\)/<span class=\"ltlbg_colon\">：<\/span>/g' \
  | sed -e 's/―/<span class=\"ltlbg_wSize\">―<\/span>/g' \
  >tmp2_ltlbgtmp

  #タグで括るタイプの修飾_1文字
  ## [-字-]を<span class="ltlbg_wdfix">へ。特定の文字についてはltlbg_wSpを挿入されている可能性がるのでそれも考慮した置換を行う
  ## [^字^]を<span class="ltlbg_rotate">へ。
  ## [l[偏旁]r]を<span class="ltlbg_forcedGouji1/2">へ
  cat tmp2_ltlbgtmp \
  | sed -e 's/\[\-\(.\)\-\]/<span class=\"ltlbg_wdfix\">\1<\/span>/g' \
  | sed -e 's/\[\^\(.\)\^\]/<span class=\"ltlbg_rotate\">\1<\/span>/g' \
  | sed -e 's/\[l\[\(.\)\(.\)\]r\]/<span class=\"ltlbg_forceGouji1\">\1<\/span><span class=\"ltlbg_forceGouji2\">\2<\/span>/g' \
  >tmp1_ltlbgtmp

  #タグで括るタイプの修飾_複数文字
  ## ~と~に囲まれた2文字の範囲を<br class="ltlbg_tcyA">縦中横</span>に
  ## **太字**を<br class="ltlbg_wSize">―</span>に
  ## ^と^に囲まれた1〜3文字の範囲を、<br class="ltlbg_tcyM">縦中横</span>に。[^字^]は食わないように
  cat tmp1_ltlbgtmp \
  | sed -e 's/~\([a-zA-Z0-9!?]\{2\}\)~/<span class=\"ltlbg_tcyA\">\1<\/span>/g' \
  | sed -e 's/\*\*\([^\*]\+\)\*\*/<span class=\"ltlbg_bold\">\1<\/span>/g' \
  | sed -e 's/\^<span class="ltlbg_sSp"><\/span>\(..\)\^/^〿\1^/g' \
  | sed -e 's/\^\(.\)<span class=\"ltlbg_sSp\"><\/span>\(.\)\^/^\1〿\2^/g' \
  | sed -e 's/\(..\)\^<span class=\"ltlbg_sSp\"><\/span>\^/^\1〿^/g' \
  | sed -e 's/\^\([^\^]\{1,3\}\)\^/<span class=\"ltlbg_tcyM\">\1<\/span>/g' \
  > tmp2_ltlbgtmp

  #タグに置換するタイプの変換
  ## [newpage]を、<br class="ltlbg_newpage">に
  ## ---を<span class="ltlbg_hr">へ。但し直後の改行は除去
  ## ／＼もしくは〱を、<span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>に。モノルビ化しているものも対応
  ## 「゛」を、<span class="ltlbg_dakuten">に変換する。 後ろスペース挿入されているケースを考慮する
  cat tmp2_ltlbgtmp \
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
  | sed -e 's/style="page sukebe"/style="page: sukebe;"/g' \
  | sed -z 's/\n\n/\n/g' \
  >tmp_converted_content_ltlbgtmp

  cp ../雛形.html tmp_template_ltlbgtmp
  sed -i 's/{{LITTLEBUG_CONTENT_PLACEHOLDER}}/TEMP_MARKER_FOR_CONTENT/' tmp_template_ltlbgtmp
  awk '
  /TEMP_MARKER_FOR_CONTENT/ {
    while ((getline line < "tmp_converted_content_ltlbgtmp") > 0) {
      print line
    }
    close("tmp_converted_content_ltlbgtmp")
    next
  }
  { print }
  ' tmp_template_ltlbgtmp >${destFile}
  rm tmp_template_ltlbgtmp

  #>tmp2_ltlbgtmp
  ##########################################################################################
  # 先頭にlittlebugXXX.css読み込むよう追記する
  ##########################################################################################
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  #cat tmp1_ltlbgtmp \
  #| sed -z 's/^/<link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugI\.css">\n/' \
  #| sed -z 's/^/<link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugTD\.css">\n/' \
  #| sed -z 's/^/<\!--\<link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugRL\.css">-->\n/' \
  #| sed -z 's/^/<link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugU\.css">\n/' \
  #| sed -z 's/^/<link rel=\"preconnect\" href=\"https:\/\/fonts\.googleapis\.com\">\n/' \
  #| sed -z 's/^/<link rel=\"preconnect\" href=\"https:\/\/fonts\.gstatic\.com\" crossorigin>\n/' \
  #| sed -z 's/^/<link href=\"https:\/\/fonts\.googleapis\.com\/css2\?family=Noto\+Serif\+JP:wght\@300\&display=swap\" rel=\"stylesheet">\n/' \
  #>${destFile}

  echo "✨ "${destFile}"を出力しました[html化]"

elif [ "${convMode}" = '-h2t' ] ; then
  ## html→txt ############################################################################################

  destFile=${tgtFile_AfterCD/".html"/"_removed.txt"} #出力ファイルの指定する
  touch ${destFile}                          #出力先ファイルを生成

  cat ${tgtFile_AfterCD} \
  | sed -z 's/<html lang="ja">\n//' \
  | sed -z 's/<head>\n//' \
  | sed -z 's/<\/head>\n//' \
  | sed -z 's/<body>\n//' \
  | sed -z 's/<\/body>\n//' \
  | sed -z 's/<\/html>\n\?//' \
  | sed -z 's/<link rel=\"stylesheet\" href=\".\+littlebug.\+css\">//' \
  | sed -z 's/<link rel=\"preconnect\" href=\"https:\/\/fonts\.googleapis\.com\">\n//' \
  | sed -z 's/<link rel=\"preconnect\" href=\"https:\/\/fonts\.gstatic\.com\" crossorigin>\n//' \
  | sed -z 's/<link href=\"https:\/\/fonts\.googleapis\.com\/css2?family=Noto+Serif+JP:wght@300&display=swap\" rel=\"stylesheet\">\n\?//' \
  | sed -z 's/{{LITTLEBUG_CONTENT_PLACEHOLDER}}//' \
  | sed -z 's/<\/section>\n\?$//' \
  >tmp1_ltlbgtmp
  
  ############################################################################################
  #入れ子構造になりうるタグの復旧1。外側。修飾は最大3なので、復旧処理を3回反復する
  ############################################################################################
  for i in $(seq 0 2); do
    ############################################################################################
    #入れ子構造になりうるタグの復旧2。内側。修飾は最大3なので、復旧処理を3回反復する
    ############################################################################################
    for i in $(seq 0 2); do
      ## 章区切りを[chapter:XXXX]に
      ### 閉じタグ</section><!--ltlbg_section-->を除去
      ### <section class="ltlbg_section" id="XXX">を[chapter:]へ
      cat tmp1_ltlbgtmp \
      | sed -e 's/<\/section><!--ltlbg_section-->//g' \
      | sed -e 's/<section class="ltlbg_section">/[chapter]/g' \
      | sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
      | sed -e 's/\[chapter:\]/\[chapter\]/g' \
      >tmp2_ltlbgtmp

      ## 閉じpタグを消し、pタグを全角空白へ置換する
      ## 全角空白直後の改行は削除する(元のpタグが直後に改行しているため)
      cat tmp2_ltlbgtmp \
      | sed -e 's/<\/p><!--ltlbg_p-->//g' \
      | sed -e 's/<p class="ltlbg_p">/<span class="ltlbg_wSp"><\/span>/g' \
      | sed -z 's/<span class="ltlbg_wSp"><\/span>\n<span class="ltlbg_talk">/\n<span class="ltlbg_talk">/g' \
      >tmp1_ltlbgtmp

      ## 括弧類を復旧
      cat tmp1_ltlbgtmp \
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
      >tmp2_ltlbgtmp

      ## 縦中横と横幅修正を除去
      cat tmp2_ltlbgtmp \
      | sed -e 's/<span class=\"ltlbg_tcyA\">\([^<]\{2\}\)<\/span>/\1/g' \
      | sed -e 's/<span class=\"ltlbg_wdfix\">\([^<]\)<\/span>/\1/g' \
      >tmp1_ltlbgtmp

      ## コロンとセミコロンを復旧
      cat tmp1_ltlbgtmp \
      | sed -e 's/<span class="ltlbg_semicolon">；<\/span>/；/g' \
      | sed -e 's/<span class="ltlbg_colon">：<\/span>/：/g' \
      >tmp2_ltlbgtmp

      ## 括弧類の擬似段落記号を除去
      cat tmp2_ltlbgtmp \
      | sed -e 's/<p class="ltlbg_p_brctGrp">//g' \
      | sed -e 's/<\/p><\!--ltlbg_p_brctGrp-->//g' \
      >tmp1_ltlbgtmp

      ## <span class="ltlbg_dakuten">を「゛」に復旧
      ## <span class="ltlbg_tcyM">XX</span>を復旧
      ## <span class="ltlbg_wSize">字</span>を復旧
      ## <span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>を復旧
      cat tmp1_ltlbgtmp \
      | sed -e 's/<span class=\"ltlbg_dakuten\">\(.\)<\/span>/\1゛/g' \
      | sed -e 's/<span class=\"ltlbg_tcyM\">\([^<]\{1,3\}\)<\/span>/^\1^/g' \
      | sed -e 's/<span class=\"ltlbg_wSize\">\(.\)<\/span>/\1\1/g' \
      | sed -e 's/<span class=\"ltlbg_odori1\"><\/span>/／/g' \
      | sed -e 's/<span class=\"ltlbg_odori2\"><\/span>/＼/g' \
      >tmp2_ltlbgtmp

      ## 強制合字<span class="ltlbg_forceGouji1">、<span class="ltlbg_forceGouji2">を[l[]r]へ復旧
      cat tmp2_ltlbgtmp \
      | sed -e 's/<span class=\"ltlbg_forceGouji1\">\(.\)<\/span><span class=\"ltlbg_forceGouji2\">\(.\)<\/span>/[l[\1\2]r]/g' \
      >tmp1_ltlbgtmp

      ## 回転指定<span class="ltlbg_rotate"></span>を[^字^]へ復旧
      ## 太字指定<span class="ltlbg_bold"></span>を**字**へ復旧
      cat tmp1_ltlbgtmp \
      | sed -e 's/<span class=\"ltlbg_rotate\">\(.\)<\/span>/\[\^\1\^\]/g' \
      | sed -e 's/<span class=\"ltlbg_bold\">\([^<]\+\)<\/span>/\*\*\1\*\*/g' \
      >tmp2_ltlbgtmp

      ## <h2 class="ltlbg_sectionName">\1<\/h2>を行頭◆へ
      ## <hr class="ltlbg_hr">を---へ。
      cat tmp2_ltlbgtmp \
      | sed -e 's/<h2 class=\"ltlbg_sectionName\">\([^<]\+\)<\/h2>/\1/g' \
      | sed -e 's/<hr class=\"ltlbg_hr\">/---/g' \
      >tmp1_ltlbgtmp

      ## モノルビを復旧
      cat tmp1_ltlbgtmp >tmp2_ltlbgtmp
      #3回繰り返すのでループ末尾で出力している中間ファイルから開始されるよう調整する
      cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
    done

    ############################################################################################
    #複数回の置換を必要としない(途中で戻ると不都合のある)復旧
    ############################################################################################
    ## 「&lt;」  を「<」(半角)へ変換
    ## 「&gt;」  を「>」(半角)へ変換
    ## 「&amp;」 を「&」(半角)へ変換
    ## 「&quot;」を「'」(半角)へ変換
    ## 「&#39;」 を「"」(半角)へ変換
    cat tmp2_ltlbgtmp \
    | sed -e 's/&amp;/\&/g' \
    | sed -e 's/&lt;/</g' \
    | sed -e 's/&gt;/>/g' \
    | sed -e 's/&quot;/'\''/g' \
    | sed -e 's/&#39;/\"/g' \
    >tmp1_ltlbgtmp

    ## ここまで生じているハード空行は副産物なので削除
    ## その上で、<br class="ltlbg_br">、<br class="ltlbg_blankline">を削除
    cat tmp1_ltlbgtmp \
    | sed -z 's/^\n//g' \
    | sed -e 's/<br class=\"ltlbg_br\">//g' \
    | sed -e 's/^<br class=\"ltlbg_blankline\">//g' \
    | sed -e 's/<span class=\"ltlbg_wSp\"><\/span>/　/g' \
    | sed -e 's/<span class=\"ltlbg_sSp\"><\/span>/ /g' \
    | sed -z 's/　\n/\n/g' \
    >tmp2_ltlbgtmp

    #################################################################################
    #ルビと圏点の復旧は最後。圏点とモノルビは特殊な戻し作業を要する。
    #################################################################################
    ## モノルビ以外の<span class="ltlbg_ruby" data-ruby_XXX="XXX"></span>を復旧
    cat tmp2_ltlbgtmp \
    | sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' \
    >tmp1_ltlbgtmp

    #順序の入れ替え
    cat tmp1_ltlbgtmp \
    | sed -e 's/\*\*{\([^｜]\+\)｜\([^\}]\+\)}\*\*/{\*\*\1\*\*｜\2}/g' \
    > tmp2_ltlbgtmp

    ## 圏点タグを《《基底文字》》へ復旧する
    ## <ruby class=\"ltlbg_emphasis\" data-ruby_emphasis=\"[^]]\">〜で抽出したものを置換元とする。
    ## 基底文字だけを持つ中間ファイルと、ルビだけを持つ中間ファイルを作成し、置換先とする。
    ## 置換機能を持った中間シェルスクリプトを作成し、実行する。
    cat tmp2_ltlbgtmp \
    | sed -e 's/<ruby class=\"ltlbg_emphasis\" data-emphasis=\".\">\([^<]\+\)<rt>.<\/rt><\/ruby>/《《\1》》/g' \
    >tmp1_ltlbgtmp

    #3回繰り返すのでループ末尾で出力している中間ファイルから開始されるよう調整する
    #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  done
  # ループ終了後の結果もtmp1_ltlbgtmpに出力される

  # モノルビ対応。#######################################################
  # モノルビは、ここまでの処理では{モノルビ｜ものるび}ではなく
  # {モ｜も}{ノ｜の}{ル｜る}{ビ｜び}となっているのでこれを復旧する。
  # 入力はtmp1_ltlbgtmpの想定。
  #######################################################################
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
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
            | sed -e 's/\"/\\\"/g' \

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
            | sed -e 's/\"/\\\"/g' \

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
  ########################モノルビ対応ここまで。出力はtmp1_ltlbgtmp

  #圏点対応#################################################################################
  # 圏点は1字ずつ設定されているのでここまでの処理では
  # 《モノルビ》ではなく《モ》《ノ》《ル》《ルビ》となっているのでこれを復旧する
  # 入力はtmp1_ltlbgtmpの想定
  ##########################################################################################
  #cat tmp2_ltlbgtmp >tmp1_ltlbgtmp
  cat tmp1_ltlbgtmp >emphasisInput_ltlbgtmp 
  cat emphasisInput_ltlbgtmp \
  | grep -E -o '(《《[^》]+》》[ 　]?){2,}' \
  | uniq \
  >emphtmp_ltlbgtmp

  #《《》》が連続している(複数文字の圏点)が存在しなければ実施しない
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
  ########################圏点対応ここまで。出力はtmp1_ltlbgtmpの想定

  cat tmp1_ltlbgtmp >${destFile}
  echo "✨ "${destFile}"を出力しました[txtもどし]"
fi

##########################################################################################
# ファイルが上書きできないため使用している中間ファイルのゴミ掃除。なんとかならんか…
##########################################################################################
cd ../

if [ ! "${tmpDirName}" = '' ]; then 
  rm -rf ${tmpDirName}
fi
exit 0
