#!/bin/bash
export lang=ja_jp.utf-8

convMode=${1}  #1でtxt→html、2でhtml→txt、それ以外は今の所はエラー
tgtFile=${2}   #引数で指定されたファイルを対象とする

if [ ! -e ${2} ]; then
  echo "💩 そんなファイルいないです"
  exit 1
fi

if [ "${1}" = "1" ] ; then

  ## txt→html ############################################################################################

  destFile=${tgtFile/".txt"/"_tagged.html"} #出力ファイルの指定する
  touch ${destFile}                        #出力先ファイルを生成

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
  | sed -e 's/――/―/g' >tmp

  #特殊文字変換類置換ここまで##############################################################
  #########################################################################################
  # 文章中に登場するスペース類はすべてタグへ置換する。
  # 以降登場するスペース類はhtml上の区切り文字としてのスペースのみで、置換対象ではない
  # 以降でスペースを置換したい場合は、空白クラスのタグを置換すること
  #########################################################################################

  ## 半角SPを<span class="ltlbg_sSp">へ。
  ## 特定の記号(の連続)のあとに全角SPを挿入する。直後に閉じ括弧類、改行、「゛」がある場合は回避する
  ## 行頭以外の全角SPを<span class="ltlbg_wSp">へ。
    sed -e 's/\ /<span class="ltlbg_sSp"><\/span>/g' tmp \
  | sed -e 's/\([！？♥♪☆\!\?]\+\)　\?/\1　/g' \
  | sed -e 's/　\([」）〟゛/n]\)/\1/g' \
  | sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' >tmp2

  # 章区切り前後の空行を削除する
  ## 事前に、作品冒頭に空行がある場合は削除する
    sed -z 's/\n*\(\[chapter[^]]\+\]\)\n\+/\n\1\n/g' tmp2 \
  | sed -z '1,/^\n*/s/^\n*//' >tmp
  ## 文章中スペース類置換ここまで###########################################################


  ## 英数字2文字と、！？!?の重なりを<span class="ltlbg_tcyA">の変換対象にする
    sed -e 's/\([^a-zA-Z0-9\<\>]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9/</>]\)/\1<span class="ltlbg_tcyA">\2<\/span>\3/g' tmp \
  | sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">!!<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">??<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">!?<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">?!<\/span>\3/g' >tmp2

  ## [capter]を<section class="ltlbg_section">に。:XXXXXはid="XXXX"に。
  ## 章区切りのない文章対応で、先頭に必ず章を付与し、重なった章開始を除去
    sed -z 's/^/<section class="ltlbg_section">\n/g' tmp2 \
  | sed -e 's/\[chapter:/[chapter id=/g' \
  | sed -e 's/\[chapter\( id=\([^[]\+\)\)\?\]/<section class="ltlbg_section"\1>/g' \
  | sed -e 's/id=\([^>]\+\)\+>/id="\1">/' \
  | sed -z 's/<section class="ltlbg_section">\n<section class="ltlbg_section"/<section class="ltlbg_section"/g' >tmp

  ## 章を閉じる
  ## 置換の都合上必ず生じる先頭の章閉じは削除
  ## 作品の末尾には必ず章閉じを付与
  ## 章区切りは複数行に渡る可能性があるので閉じタグに<\!--ltlbg_section-->を付与する
    sed -e 's/<section/<\/section><\!--ltlbg_section-->\n<section/g' tmp \
  | sed -z '1,/<\/section><\!--ltlbg_section-->\n/s/<\/section><\!--ltlbg_section-->\n//' \
  | sed -z 's/$/\n<\/section><\!--ltlbg_section-->\n/' >tmp2

  ## 行頭§◆■の次に空白(なくても良い)に続く行を、<h2 class="ltlbg_sectionName">章タイトルに
  ## 順序の都合上直後に</p>が現れる場合、</p>は除去
  sed -e 's/^[§◆■][ 　]*\(.\+\)/<h2 class="ltlbg_sectionName">\1<\/h2>/g' tmp2 >tmp

  ## 行頭全角スペースを<p>タグに
  ## 行頭括弧類の前に<p class="ltlbg_brctGrp">タグ
    sed -e 's/^　/<p class="ltlbg_p">/g' tmp \
  | sed -e 's/^「/<p class="ltlbg_p_brctGrp">\n「/g' \
  | sed -z 's/」\n<p class="ltlbg_p_brctGrp">\n「/」\n「/g' >tmp2

  ## <p>の手前に</p>
  ## 章区切り(終了)の手前でも段落を終了させる
  ## 但し章区切り(開始)、hタグ行がある行の場合は回避する
  ## 段落は複数行に渡る可能性があるため、閉じタグに<\!--ltlbg_p/_brctGrp-->を付与する
    sed -z 's/\n<p class="ltlbg_p">/<\/p><\!--ltlbg_p-->\n<p class="ltlbg_p">/g' tmp2 \
  | sed -z 's/」<\/p><\!--ltlbg_p-->/」\n<\/p><\!--ltlbg_p_brctGrp-->/g' \
  | sed -z 's/\n<\/section><\!--ltlbg_section-->/<\/p><\!--ltlbg_p-->\n<\/section><\!--ltlbg_section-->/g' \
  | sed -z 's/\n<\/section><\!--ltlbg_section-->/<\/p><\!--ltlbg_p_brctGrp-->\n<\/section><\!--ltlbg_section-->/g' \
  | sed -z 's/<\/h2>\n<\/p><\!--ltlbg_p-->/<\/h2>/g' \
  | sed -e 's/\(<section.*>\)<\/p><\!--ltlbg_p-->/\1/g' >tmp

  ## 改行→改行タグ
  ## crlf→lf してから lf→<br class="ltlbg_br">+lfに
  ## 但し直前にブロック要素(章区切り、段落区切り、章タイトル、改ページ)がある場合は回避
    sed -z 's/\r\n/\n/g' tmp \
  | sed -z 's/\n/<br class="ltlbg_br">\n/g' \
  | sed -e 's/\(<section.*>\)<br class="ltlbg_br">/\1/g' \
  | sed -e 's/<\/section><\!--ltlbg_section--><br class="ltlbg_br">/<\/section><\!--ltlbg_section-->/g' \
  | sed -e 's/<\/h2><br class="ltlbg_br">/<\/h2>/g' \
  | sed -e 's/<p class="ltlbg_p"><br class="ltlbg_br">/<p class="ltlbg_p">/g' \
  | sed -e 's/<p class="ltlbg_p_brctGrp"><br class="ltlbg_br">/<p class="ltlbg_p_brctGrp">/g' \
  | sed -e 's/<\/p><\!--ltlbg_p--><br class="ltlbg_br">/<\/p><\!--ltlbg_p-->/g' \
  | sed -e 's/<\/p><\!--ltlbg_p_brctGrp--><br class="ltlbg_br">/<\/p><\!--ltlbg_p_brctGrp-->/g' >tmp2

  ## 行頭<br>を、<br class="ltlbg_blankline">に
  sed -e 's/^<br class="ltlbg_br">/<br class="ltlbg_blankline">/' tmp2 >tmp

  cat tmp >tmp2

  ## 改行付きブロック要素の直前にある空行は一つ余計になるので除去
    sed -z 's/<br class="ltlbg_blankline">\n<p class="ltlbg_p">/<p class="ltlbg_p">/g' tmp2 \
  | sed -z 's/<br class="ltlbg_blankline">\n<p class="ltlbg_p_brctGrp">/<p class="ltlbg_p_brctGrp">/g' >tmp

  ## 行頭「ではじまる、」までを<div class="ltlbg_talk">にする
  ## 行頭（ではじまる、）までを<div class="ltlbg_talk">にする
  ## 行頭〝ではじまる、〟までを<div class="ltlbg_wquote">にする
  ## これらのspanタグは複数行に渡る可能性があるため、閉じタグに<\!--ltlbg_XXX-->を付与する
    sed -e 's/^「\(.\+\)」/<span class="ltlbg_talk">\1<\/span><\!--ltlbg_talk-->/g' tmp \
  | sed -e 's/^（\(.\+\)）/<span class="ltlbg_think">\1<\/span><\!--ltlbg_think-->/g' \
  | sed -e 's/^〝\(.\+\)〟/<span class="ltlbg_wquote">\1<\/span><\!--ltlbg_wquote-->/g' >tmp2

  ## {基底文字|ルビ}となっているものを<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ
  ## ついでだから|基底文字《ルビ》も<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ
  ## [newpage]を、<br class="ltlbg_newpage">に
  ## ―を<br class="ltlbg_wSize">―</span>に
  ## **太字**を<br class="ltlbg_wSize">―</span>に
  ## ／＼もしくは〱を、<span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>に
  ## ---を<span class="ltlbg_hr">へ。
    sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' tmp2 \
  | sed -e 's/｜\([^《]\+\)《\([^》]\+\)》/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' \
  | sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' \
  | sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' \
  | sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' \
  | sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' \
  | sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' >tmp

  ##《《基底文字》》となっているものを基底文字と同文字数の﹅をふるルビへ置換する
  ## <ruby class="ltlbg_emphasis" data-ruby="﹅">基底文字<rt>﹅</rt></ruby>
  ### 圏点用変換元文字列|変換先文字列を作成する
  grep -E -o "《《[^》]*》》" tmp | sed 's/\[/\\\\\[/g' | sed 's/\]/\\\\\]/g' >tgt
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<ruby class=\\\\\"ltlbg_emphasis\\\\\" data-emphasis=\\\\\"/g' >1
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' | sed -e 's/\[\-.\-\]/﹅/g' | sed -e 's/\[\^.\^\]/﹅/g' | sed -e 's/\[l\[..\]r\]/﹅/g' | sed -e 's/\^.\{1,3\}\^/﹅/g' | sed -e 's/./﹅/g' | sed -e 's/$/\\\\\">/g' >2
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' | sed 's/\[/\\\\\[/g' | sed 's/\]/\\\\\]/g' >3
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<rt>/g' >4
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' | sed -e 's/\[\-.\-\]/﹅/g' | sed -e 's/\[\^.\^\]/﹅/g' | sed -e 's/\[l\[..\]r\]/﹅/g' | sed -e 's/\^.\{1,3\}\^/﹅/g' | sed -e 's/./﹅/g' >5
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<\\\\\/rt><\\\\\/ruby>/g' >6
  paste 1 2 3 4 5 6 | sed 's/\t//g' >rep
  paste -d \| tgt rep >replaceSeed
  cat  tmp >rslt.html
  ### 変換元文字列|変換先文字列に従って順次圏点置換を行う
  while read line
  do
      from="${line%%\|*}"
      to="${line##*\|}"
      str="sed -e 's/${from}/${to}/g' rslt.html"
      eval ${str} >rslt2.html
      cat rslt2.html >rslt.html
  done < ./replaceSeed
  cat rslt.html >tmp

  ## <ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>になっているルビのdata-rubyを
  ## ルビ文字数と基底文字数の関係に従いeven/long/shortに分岐させる
  ### 置換元文字列を抽出し、ユニークにする(ルビは同じものが多数出現する)
  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g' >tgt
  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/.\+|//g' | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >1
  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/|.\+//g' | sed 's/\[l\[..\]r\]/■/g'  | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >2

  ### 基底文字数,ルビ文字数 の一時ファイルを作成し、比較結果を出力する一時shを作成する
  ### その実行結果に従ってパラメータ要素名に付与する文字列を格納し、各中間ファイルと結合して置換元|置換先のファイルを作成する
  paste -d , 1 2 | sed 's/\([0-9]\+\)\,\([0-9]\+\)/if [ \1 -eq \2 ]; then echo '"'_even'"'; elif [ \1 -gt \2 ]; then echo '"'_long'"'; else echo '"'_short'"'; fi/g' >cmp.sh
  bash cmp.sh >ins
  cat tgt | sed 's/.\+/<ruby class="ltlbg_ruby" data-ruby/' >3
  cat tgt | sed 's/<ruby class="ltlbg_ruby" data-ruby//' >4
  paste 3 ins 4 | sed 's/\t//g' >rep
  paste -d \| tgt rep | sed 's/\([\"\/]\)/\\\\\1/g' >replaceSeed
  ### 変換元文字列|変換先文字列に従って順次パラメータ名置換を行う
  while read line
  do
      from="${line%%\|*}"
      to="${line##*\|}"
      str="sed -e 's/${from}/${to}/g' rslt.html"
      eval ${str} >rslt2.html
      cat rslt2.html >rslt.html
  done < ./replaceSeed
  cat rslt.html >tmp

  ## [-字-]を<span class="ltlbg_wdfix">へ。特定の文字についてはltlbg_wSpを挿入されている可能性がるのでそれも考慮した置換を行う
  ## ^と^に囲まれた1〜3文字の範囲を、<br class="ltlbg_tcyM">縦中横</span>に。[^字^]は食わないように
  ## [^字^]を<span class="ltlbg_rotate">へ。^字^でtcyになっている可能性があるので考慮する。
  ## [l[偏旁]r]を<span class="ltlbg_forcedGouji1/2">へ
  sed -e 's/\[\-\(.\)\(<span class="ltlbg_wSp"><\/span>\)\?\-\]/<span class="ltlbg_wdfix">\1<\/span>\2/g' tmp \
| sed -e 's/\([^[]\)\^\([^\^]\{1,3\}\)\^\([^]]\)/\1<span class="ltlbg_tcyM">\2<\/span>\3/g' \
| sed -e 's/\[\(\^\|<span class="ltlbg_tcy.">\)\(.\)\(\^\|<\/span>\)\]/<span class="ltlbg_rotate">\2<\/span>/g' \
| sed -e 's/\[l\[\(.\)\(.\)\]r\]/<span class="ltlbg_forceGouji1">\1<\/span><span class="ltlbg_forceGouji2">\2<\/span>/g' >tmp2

  ## 「;」「；」に<span ltlbg_semicolon>を適用する
  ## 「:」「：」に<span ltlbg_colon>を適用する
    sed -e 's/\(；\|\;\)/<span class="ltlbg_semicolon">；<\/span>/g' tmp2 \
  | sed -e 's/\(：\|\:\)/<span class="ltlbg_colon">：<\/span>/g' >tmp

  ## 「゛」を、<span class="ltlbg_dakuten">に変換する
  ## 後ろスペース挿入されているケースを考慮する
    sed -e 's/\([！？♥♪☆]\)<span class="ltlbg_wSp"><\/span>゛/<span class="ltlbg_dakuten">\1<\/span><span class="ltlbg_wSp"><\/span>/g'  tmp \
  | sed -e 's/\(.\)゛/<span class="ltlbg_dakuten">\1<\/span>/g' >tmp2


  ##########################################################################################
  # 退避的復旧。置換対象文字に抵触するが、特例的に置換したくない箇所のみ復旧する
  ##########################################################################################
  ## chapter:XXXX には英数字が使えるのでtcyタグの当て込みがある可能性がある。それを削除する
  ## ここでの復旧は想定外に壊れて当て込まれているものが対象なので、除去置換はほぼ個別対応
    sed -e 's/id="\(.*\)<span class="ltlbg_tcy[^>]\+">\(.*\)<\/span>\(.*\)>/id="\1\2\3">/g' tmp2 >tmp 

  ##########################################################################################
  # デバッグ用。先頭にlittlebugU.css、littlebugTD.cssを読み込むよう追記する
  ##########################################################################################
    sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugTD\.css"\>\n/' tmp \
  | sed -z 's/^/\<\!--\<link rel=\"stylesheet\" href=\"\.\.\/littlebugRL\.css"\>-->\n/' \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugU\.css"\>\n/' >${destFile}

  echo "✨ "${destFile}"を出力しました[html化]"

elif [ "${1}" = "2" ] ; then

  ## html→txt ############################################################################################

  destFile=${tgtFile/".html"/"_removed.txt"} #出力ファイルの指定する
  touch ${destFile}                          #出力先ファイルを生成

  ## littlebugXX.cssの読み込みを除去する
  sed -z 's/<link rel=\"stylesheet\" href=\".\+littlebug.\+css\">//' ${tgtFile} >tmp

  ## 章区切りを[chapter:XXXX]に
  ### 閉じタグ</section><!--ltlbg_section-->を除去
  ### <section class="ltlbg_section" id="XXX">を[chapter:]へ
    sed -e 's/<\/section><!--ltlbg_section-->//g' tmp \
  | sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
  | sed -e 's/\[chapter:\]/\[chapter\]/g'  >tmp2

  ## 段落区切りを行頭空白に
  ### 閉じタグ</p><!--ltlbg-->を除去
  ### <p class="ltlbg_p">を一旦<span class="ltlbg_wSp"></span>へ
  ### 直後が<span class="ltlbg_talk/think/wquote">の場合、「<span class="ltlbg_wSp"></span>」を除去
    sed -e 's/<\/p><!--ltlbg_p-->//g' tmp2 \
  | sed -e 's/<p class="ltlbg_p">/<span class="ltlbg_wSp"><\/span>/g' \
  | sed -z 's/<span class="ltlbg_wSp"><\/span>\n<span class="ltlbg_talk">/\n<span class="ltlbg_talk">/g' >tmp

  ## </span><!--ltlbg_talk/think/wquote"-->をそれぞれの閉じ括弧へ
  ## <span class="ltlbg_talk/think/wquote">をそれぞれの開き括弧へ
    sed -e 's/<\/span><!--ltlbg_talk-->/」/g' tmp \
  | sed -e 's/<\/span><!--ltlbg_think-->/）/g' \
  | sed -e 's/<\/span><!--ltlbg_wquote-->/〟/g' \
  | sed -e 's/<span class="ltlbg_talk">/「/g' \
  | sed -e 's/<span class="ltlbg_think">/（/g' \
  | sed -e 's/<span class="ltlbg_wquote">/〝/g' >tmp2

  ## <span class="ltlbg_tcyA">XX</span>を除去
  ## <span class="ltlbg_wdfix">XX</span>を除去
  ## <span ltlbg_semicolon>；</span>を除去
  ## <span ltlbg_colon>：</span>を除去
    sed -e 's/<span class="ltlbg_tcyA">\([^<]\{2\}\)<\/span>/\1/g' tmp2 \
  | sed -e 's/<span class="ltlbg_wdfix">\([^<]\)<\/span>/\1/g' \
  | sed -e 's/<span class="ltlbg_semicolon">；<\/span>/；/g' \
  | sed -e 's/<span class="ltlbg_colon">：<\/span>/：/g' >tmp

  ## 括弧類段落記号を除去
    sed -e 's/<p class="ltlbg_p_brctGrp">//g' tmp \
  | sed -e 's/<\/p><\!--ltlbg_p_brctGrp-->//g' >tmp2

  cat tmp2 >tmp

  ## <span class="ltlbg_dakuten">を「゛」に復旧
  ## <span class="ltlbg_tcyM">XX</span>を復旧
  ## <span class="ltlbg_wSize">字</span>を復旧
  ## <span class="ltlbg_odori1"></span><span class="ltlbg_odori2"></span>を復旧
    sed -e 's/<span class="ltlbg_dakuten">\(.\)<\/span>/\1゛/g' tmp \
  | sed -e 's/<span class="ltlbg_tcyM">\([^<]\{1,3\}\)<\/span>/^\1^/g' \
  | sed -e 's/<span class="ltlbg_wSize">\(.\)<\/span>/\1\1/g' \
  | sed -e 's/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/／＼/g' >tmp2

  ## <span class="ltlbg_ruby" data-ruby_XXX="XXX"></span>を復旧
    sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' tmp2 \
  | sed -e 's/<ruby class="ltlbg_emphasis" data-emphasis="[^"]\+">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/《《\1》》/g' >tmp

  ## <h2 class="ltlbg_sectionName">\1<\/h2>を行頭◆へ
  sed -e 's/<h2 class="ltlbg_sectionName">\([^<]\+\)<\/h2>/◆\1/g' tmp >tmp2

  ## 「<」(半角)を「&lt;」へ変換
  ## 「>」(半角)を「&gt;」へ変換
  ## 「&」(半角)を「&amp;」へ変換
  ## 「'」(半角)を「&quot;」へ変換
  ## 「"」(半角)を「&#39;」へ変換
    sed -e 's/\&amp;/&/g' tmp2 \
  | sed -e 's/\&lt;/</g' \
  | sed -e 's/\&gt;/>/g' \
  | sed -e "s/\&quot;/'/g" \
  | sed -e 's/\&#39;/\"/g' >tmp

  ## ここまで生じているハード空行は副産物なので削除
  ## その上で、<br class="ltlbg_br">、<br class="ltlbg_blankline">を削除
    sed -z 's/^\n//g' tmp \
  | sed -e 's/<br class="ltlbg_br">//g' \
  | sed -e 's/^<br class="ltlbg_blankline">//g' >tmp2

  ## <span class="ltlbg_wSp"></span>を「　」へ
    sed -e 's/<span class="ltlbg_wSp"><\/span>/　/g' tmp2 \
  | sed -z 's/　\n/\n/g' >${destFile}

  echo "✨ "${destFile}"を出力しました[txtもどし]"

else

  echo "💩 引数1は1(txt→html)か2(html→txt)で指定してください"
  exit 1
fi

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
eval $rmstrBase'ins'
eval $rmstrBase'replaceSeed'
eval $rmstrBase'rslt.html'
eval $rmstrBase'rslt2.html'
eval $rmstrBase'tmp'
eval $rmstrBase'tmp2'
eval $rmstrBase'cmp.sh'

exit 0