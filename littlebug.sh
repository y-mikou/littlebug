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

    sed -e 's/&/\&amp;/g' ${tgtFile} \
  | sed -e 's/</\&lt;/g' \
  | sed -e 's/>/\&gt;/g' \
  | sed -e "s/'/\&quot;/g" \
  | sed -e 's/\"/\&#39;/g' \
  | sed -e 's/――/―/g' \
  | sed -e 's/\ /<span class="ltlbg_sSp"><\/span>/g' \
  | sed -e 's/\([！？♥♪☆\!\?]\+\)　\?/\1　/g' \
  | sed -e 's/　\([」）〟゛/n]\)/\1/g' \
  | sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' \
  | sed -z 's/\n*\(\[chapter[^]]\+\]\)\n\+/\n\1\n/g' \
  | sed -z '1,/^\n*/s/^\n*//' \
  | sed -e 's/\([^a-zA-Z0-9\<\>]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9/</>]\)/\1<span class="ltlbg_tcyA">\2<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">!!<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(??\|？？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">??<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(!?\|！？\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">!?<\/span>\3/g' \
  | sed -e 's/\([^!！?？\&#;]\)\(?!\|？！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">?!<\/span>\3/g' \
  | sed -z 's/^/<section class="ltlbg_section">\n/g' \
  | sed -e 's/\[chapter:/[chapter id=/g' \
  | sed -e 's/\[chapter\( id=\([^[]\+\)\)\?\]/<section class="ltlbg_section"\1>/g' \
  | sed -e 's/id=\([^>]\+\)\+>/id="\1">/' \
  | sed -z 's/<section class="ltlbg_section">\n<section class="ltlbg_section"/<section class="ltlbg_section"/g' \
  | sed -e 's/<section/<\/section><\!--ltlbg_section-->\n<section/g' \
  | sed -z '1,/<\/section><\!--ltlbg_section-->\n/s/<\/section><\!--ltlbg_section-->\n//' \
  | sed -z 's/$/\n<\/section><\!--ltlbg_section-->\n/' \
  | sed -e 's/^[§◆■][ 　]*\(.\+\)/<h2 class="ltlbg_sectionName">\1<\/h2>/g' \
  | sed -e 's/^　/<p class="ltlbg_p">/g' \
  | sed -e 's/^「/<p class="ltlbg_p_brctGrp">\n「/g' \
  | sed -z 's/」\n<p class="ltlbg_p_brctGrp">\n「/」\n「/g' \
  | sed -z 's/\n<p class="ltlbg_p">/<\/p><\!--ltlbg_p-->\n<p class="ltlbg_p">/g' \
  | sed -z 's/」<\/p><\!--ltlbg_p-->/」\n<\/p><\!--ltlbg_p_brctGrp-->/g' \
  | sed -z 's/\n<\/section><\!--ltlbg_section-->/<\/p><\!--ltlbg_p-->\n<\/section><\!--ltlbg_section-->/g' \
  | sed -z 's/\n<\/section><\!--ltlbg_section-->/<\/p><\!--ltlbg_p_brctGrp-->\n<\/section><\!--ltlbg_section-->/g' \
  | sed -z 's/<\/h2>\n<\/p><\!--ltlbg_p-->/<\/h2>/g' \
  | sed -e 's/\(<section.*>\)<\/p><\!--ltlbg_p-->/\1/g' \
  | sed -z 's/\r\n/\n/g' \
  | sed -z 's/\n/<br class="ltlbg_br">\n/g' \
  | sed -e 's/\(<section.*>\)<br class="ltlbg_br">/\1/g' \
  | sed -e 's/<\/section><\!--ltlbg_section--><br class="ltlbg_br">/<\/section><\!--ltlbg_section-->/g' \
  | sed -e 's/<\/h2><br class="ltlbg_br">/<\/h2>/g' \
  | sed -e 's/<p class="ltlbg_p"><br class="ltlbg_br">/<p class="ltlbg_p">/g' \
  | sed -e 's/<p class="ltlbg_p_brctGrp"><br class="ltlbg_br">/<p class="ltlbg_p_brctGrp">/g' \
  | sed -e 's/<\/p><\!--ltlbg_p--><br class="ltlbg_br">/<\/p><\!--ltlbg_p-->/g' \
  | sed -e 's/<\/p><\!--ltlbg_p_brctGrp--><br class="ltlbg_br">/<\/p><\!--ltlbg_p_brctGrp-->/g' \
  | sed -e 's/^<br class="ltlbg_br">/<br class="ltlbg_blankline">/' \
  | sed -z 's/<br class="ltlbg_blankline">\n<p class="ltlbg_p">/<p class="ltlbg_p">/g' \
  | sed -z 's/<br class="ltlbg_blankline">\n<p class="ltlbg_p_brctGrp">/<p class="ltlbg_p_brctGrp">/g' \
  | sed -e 's/^「\(.\+\)」/<span class="ltlbg_talk">\1<\/span><\!--ltlbg_talk-->/g' \
  | sed -e 's/^（\(.\+\)）/<span class="ltlbg_think">\1<\/span><\!--ltlbg_think-->/g' \
  | sed -e 's/^〝\(.\+\)〟/<span class="ltlbg_wquote">\1<\/span><\!--ltlbg_wquote-->/g' \
  | sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' \
  | sed -e 's/｜\([^《]\+\)《\([^》]\+\)》/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' \
  | sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' \
  | sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' \
  | sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' \
  | sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' \
  | sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' >tmp

  grep -E -o "《《[^》]*》》" tmp >tgt
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<ruby class=\\\\\"ltlbg_emphasis\\\\\" data-emphasis=\\\\\"/g' >1
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' | sed -e 's/\[\-.\-\]/﹅/g' | sed -e 's/\[\^.\^\]/﹅/g' | sed -e 's/\^.\{1,3\}\^/﹅/g' | sed -e 's/./﹅/g' | sed -e 's/$/\\\\\">/g' >2
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' >3
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<rt>/g' >4
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/[《》]//g' | sed -e 's/./﹅/g' >5
  grep -E -o "《《[^》]*》》" tmp | sed -e 's/.*/<\\\\\/rt><\\\\\/ruby>/g' >6
  paste 1 2 3 4 5 6 | sed 's/\t//g' >rep
  paste -d \| tgt rep >replaceSeed
  cat  tmp >rslt.html
  while read line
  do
      from="${line%%\|*}"
      to="${line##*\|}"
      str="sed -e 's/${from}/${to}/g' rslt.html"
      eval ${str} >rslt2.html
      cat rslt2.html >rslt.html
  done < ./replaceSeed
  cat rslt.html >tmp

  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq >tgt
  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/.\+|//g' | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >1
  cat tmp | sed -e 's/<\/ruby>/<\/ruby>\n/g' | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/|.\+//g' | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >2

  paste -d , 1 2 | sed 's/\([0-9]\+\)\,\([0-9]\+\)/if [ \1 -eq \2 ]; then echo '"'_even'"'; elif [ \1 -gt \2 ]; then echo '"'_long'"'; else echo '"'_short'"'; fi/g' >cmp.sh
  bash cmp.sh >ins
  cat tgt | sed 's/.\+/<ruby class="ltlbg_ruby" data-ruby/' >3
  cat tgt | sed 's/<ruby class="ltlbg_ruby" data-ruby//' >4
  paste 3 ins 4 | sed 's/\t//g' >rep
  paste -d \| tgt rep | sed 's/\([\"\/]\)/\\\\\1/g' >replaceSeed
  while read line
  do
      from="${line%%\|*}"
      to="${line##*\|}"
      str="sed -e 's/${from}/${to}/g' rslt.html"
      eval ${str} >rslt2.html
      cat rslt2.html >rslt.html
  done < ./replaceSeed
  cat rslt.html >tmp

    sed -e 's/\[\-\(.\)\(<span class="ltlbg_wSp"><\/span>\)\?\-\]/<span class="ltlbg_wdfix">\1<\/span>\2/g' tmp \
  | sed -e 's/\([^[]\)\^\([^\^]\{1,3\}\)\^\([^]]\)/\1<span class="ltlbg_tcyM">\2<\/span>\3/g' \
  | sed -e 's/\[l\[\(.\)\(.\)\]r\]/<span class="ltlbg_forceGouji1">\1<\/span><span class="ltlbg_forceGouji2">\2<\/span>/g' \
  | sed -e 's/\[\(\^\|<span class="ltlbg_tcy.">\)\(.\)\(\^\|<\/span>\)\]/<span class="ltlbg_rotate">\2<\/span>/g' \
  | sed -e 's/\(；\|\;\)/<span class="ltlbg_semicolon">；<\/span>/g' \
  | sed -e 's/\(：\|\:\)/<span class="ltlbg_colon">：<\/span>/g' \
  | sed -e 's/\([！？♥♪☆]\)<span class="ltlbg_wSp"><\/span>゛/<span class="ltlbg_dakuten">\1<\/span><span class="ltlbg_wSp"><\/span>/g' \
  | sed -e 's/\(.\)゛/<span class="ltlbg_dakuten">\1<\/span>/g' \
  | sed -e 's/id="\(.*\)<span class="ltlbg_tcy[^>]\+">\(.*\)<\/span>\(.*\)>/id="\1\2\3">/g' \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugTD\.css"\>\n/' \
  | sed -z 's/^/\<\!--\<link rel=\"stylesheet\" href=\"\.\.\/littlebugTD\.css"\>-->\n/' \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugU\.css"\>\n/' >${destFile}

  echo "✨ "${destFile}"を出力しました[html化]"

elif [ "${1}" = "2" ] ; then

  ## html→txt ############################################################################################

  destFile=${tgtFile/".html"/"_removed.txt"} #出力ファイルの指定する
  touch ${destFile}                          #出力先ファイルを生成

  sed -z 's/<link rel=\"stylesheet\" href=\".\+littlebug.\+css\">//' ${tgtFile} >tmp

    sed -e 's/<\/section><!--ltlbg_section-->//g' tmp \
  | sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
  | sed -e 's/\[chapter:\]/\[chapter\]/g' \
  | sed -e 's/<\/p><!--ltlbg_p-->//g' \
  | sed -e 's/<p class="ltlbg_p">/<span class="ltlbg_wSp"><\/span>/g' \
  | sed -z 's/<span class="ltlbg_wSp"><\/span>\n<span class="ltlbg_talk">/\n<span class="ltlbg_talk">/g' \
  | sed -e 's/<\/span><!--ltlbg_talk-->/」/g' \
  | sed -e 's/<\/span><!--ltlbg_think-->/）/g' \
  | sed -e 's/<\/span><!--ltlbg_wquote-->/〟/g' \
  | sed -e 's/<span class="ltlbg_talk">/「/g' \
  | sed -e 's/<span class="ltlbg_think">/（/g' \
  | sed -e 's/<span class="ltlbg_wquote">/〝/g' \
  | sed -e 's/<span class="ltlbg_tcyA">\([^<]\{2\}\)<\/span>/\1/g' \
  | sed -e 's/<span class="ltlbg_wdfix">\([^<]\)<\/span>/\1/g' \
  | sed -e 's/<span class="ltlbg_semicolon">；<\/span>/；/g' \
  | sed -e 's/<span class="ltlbg_colon">：<\/span>/：/g' \
  | sed -e 's/<p class="ltlbg_p_brctGrp">//g' \
  | sed -e 's/<\/p><\!--ltlbg_p_brctGrp-->//g' \
  | sed -e 's/<span class="ltlbg_dakuten">\(.\)<\/span>/\1゛/g' \
  | sed -e 's/<span class="ltlbg_tcyM">\([^<]\{1,3\}\)<\/span>/^\1^/g' \
  | sed -e 's/<span class="ltlbg_wSize">\(.\)<\/span>/\1\1/g' \
  | sed -e 's/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/／＼/g' \
  | sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' \
  | sed -e 's/<ruby class="ltlbg_emphasis" data-emphasis="[^"]\+">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/《《\1》》/g' \
  | sed -e 's/<h2 class="ltlbg_sectionName">\([^<]\+\)<\/h2>/◆\1/g' \
  | sed -e 's/\&amp;/&/g' \
  | sed -e 's/\&lt;/</g' \
  | sed -e 's/\&gt;/>/g' \
  | sed -e "s/\&quot;/'/g" \
  | sed -e 's/\&#39;/\"/g' \
  | sed -z 's/^\n//g' \
  | sed -e 's/<br class="ltlbg_br">//g' \
  | sed -e 's/^<br class="ltlbg_blankline">//g' \
  | sed -e 's/<span class="ltlbg_wSp"><\/span>/　/g' \
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
