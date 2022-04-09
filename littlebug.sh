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
  iconv -f SHIFT_JIS -t UTF-8 ${tgtFile} > tmp
  cat tmp >${tgtFile}
fi

if [ "${1}" = "1" ] ; then

  ## txt→html ############################################################################################

  destFile=${tgtFile/".txt"/"_tagged.html"} #出力ファイルの指定する
  touch ${destFile}                        #出力先ファイルを生成

    sed -e 's/&amp;/＆ａｍｐ/g' ${tgtFile} \
  | sed -e 's/[\&\|＆ａｍｐ]lt;/＆ｌｔ/g' \
  | sed -e 's/[\&\|＆ａｍｐ]gt;/＆ｇｔ/g' \
  | sed -e 's/[\&\|＆ａｍｐ]#39;/＆＃３９/g' \
  | sed -e 's/[\&\|＆ａｍｐ]#quot;/＆ｑｕｏｔ/g' \
  | sed -e 's/――/―/g' \
  | sed -z 's/\r\n/\n/g' | sed -z 's/\r/\n/g' \
  | sed -e 's/\ /<span class="ltlbg_sSp"><\/span>/g' \
  | sed -e 's/\([！？♥♪☆\!\?]\+\)　\?/\1　/g' \
  | sed -e 's/　\([」）〟゛/n]\)/\1/g' \
  | sed -e 's/\(.\)　/\1<span class="ltlbg_wSp"><\/span>/g' \
  | sed -z 's/\n*\(\[chapter[^]]\+\]\)\n\+/\n\1\n/g' \
  | sed -z '1,/^\n*/s/^\n*//' \
  | LANG=C sed -e 's/\([^a-zA-Z0-9\<\>]\)\([a-zA-Z0-9]\{2\}\)\([^a-zA-Z0-9/</>]\)/\1<span class="ltlbg_tcyA">\2<\/span>\3/g' \
  | LANG=ja_jp.utf-8 sed -e 's/\([^!！?？\&#;]\)\(!!\|！！\)\([^!！?？\&#;]\)/\1<span class="ltlbg_tcyA">!!<\/span>\3/g' \
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
  | sed -e '/\[newpage\]/c <div class="ltlbg_newpage"></div>' \
  | sed -e 's/―/<span class="ltlbg_wSize">―<\/span>/g' \
  | sed -e 's/\*\*\([^\*]\+\)\*\*/<span class="ltlbg_bold">\1<\/span>/g' \
  | sed -e 's/／＼\|〱/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/g' \
  | sed -z 's/-\{3,\}/<br class="ltlbg_hr">/g' >tmp
  cat tmp >emphasisInput
  grep -E -o "《《[^》]*》》" emphasisInput >org

  ## 中間ファイルorg(《《[^》]*》》で抽出したもの)の長さが0の場合、処理しない
  if [ -s org ] ; then 

    sed -e 's/[《》]//g' org >raw
    sed -e 's/\[\-.\-\]/﹅/g' raw | sed -e 's/\[\^.\^\]/﹅/g' | sed -e 's/\[l\[..\]r\]/﹅/g' | sed -e 's/\^.\{1,3\}\^/﹅/g' | sed -e 's/./﹅/g' >emphtmp
    sed -e 's/^/\| sed -e '\''s\//g' org >tgt
    paste -d , raw emphtmp \
    | while read line || [ -n "${line}" ]; do \
      echo -n '/'
      echo ${line##*,} | grep -o . | sed -e 's/^/<ruby class=\\\"ltlbg_emphasis\\\" data-emphasis=\\\"/' | sed -e 's/$/\\\">/' >1
      echo ${line%%,*} | grep -o . >2
      echo ${line##*,} | grep -o . | sed -e 's/^/<rt>/' | sed -e 's/$/<\\\/rt><\\\/ruby>/' >3
      paste 1 2 3 | sed -e 's/\t//g' | sed -z 's/\n//g' | sed -e 's/$/\/g'\'' \\/'
      echo ''
      done \
    >rep
    paste tgt rep | sed -e 's/\t//g' | sed -z 's/^/cat emphasisInput \\\n/' >tmp.sh
    bash  tmp.sh >tmp
  fi
  
  ## {基底文字|ルビ}となっているものを<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ
  ## ついでだから|基底文字《ルビ》も<ruby class="ltlbg_ruby" data-ruby="ルビ">基底文字<rt>ルビ</rt></ruby>へ

cat tmp >rubyInput
    sed -e 's/{\([^\{]\+\)｜\([^\}]\+\)}/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' rubyInput \
  | sed -e 's/｜\([^《]\+\)《\([^》]\+\)》/<ruby class="ltlbg_ruby" data-ruby="\2">\1<rt>\2<\/rt><\/ruby>/g' >rubytmp

  sed -e 's/<\/ruby>/<\/ruby>\n/g' rubytmp | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g' >tgt

  ## 中間ファイルtgt(ルビタグで抽出した結果)の長さが0の場合、処理しない
  if [ -s tgt ] ; then

    sed -e 's/<\/ruby>/<\/ruby>\n/g' rubytmp | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/.\+|//g' | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >1
    sed -e 's/<\/ruby>/<\/ruby>\n/g' rubytmp | grep -o -E "<ruby class=\"ltlbg_ruby\" data-ruby=\".+<\/ruby>" | uniq | sed -e 's/^[^>]\+>//g' | sed -e 's/<rt>/\|/g' | sed -e 's/<.\+//g' | sed 's/|.\+//g' | sed 's/\[l\[..\]r\]/■/g'  | while read line || [ -n "${line}" ]; do echo -n $line | wc -m; done >2
    ### 文字数の関係に従って付与する文字を出力する(該当箇所を置換する)。文字はシェルスクリプトになっている
    paste -d , 1 2 \
    | sed 's/\([0-9]\+\)\,\([0-9]\+\)/ \
      i=$((\2 * 2)); \
      if [ $(( ${i} - \1 )) -gt 0 ] \&\& [ $(( \2 - \1 )) -lt 0 ]; then \
        echo '"'_center'"'; \
      elif [ \1 -eq \2 ]; then \
        echo '"'_mono'"'; \
      elif [ $(( ${i} - \1 )) -lt 0 ] \|\| [ $(( \2 - \1 )) -lt 0 ]; then \
        echo '"'_long'"'; \
      else echo '"'_short'"'; \
      fi/g' \
      >tmp.sh
    bash tmp.sh >ins
    
    sed 's/.\+/<ruby class="ltlbg_ruby" data-ruby/' tgt >3
    sed 's/<ruby class="ltlbg_ruby" data-ruby//' tgt >4
    paste 3 ins 4 | sed 's/\t//g' >rep
    paste -d \| tgt rep | sed 's/\([\"\/]\)/\\\\\1/g' >replaceSeed
    cat  rubytmp >rslt
    ### 変換元文字列|変換先文字列に従って順次パラメータ名置換を行う
    while read line
    do
        from="${line%%\|*}"
        to="${line##*\|}"
        str="sed -e 's/${from}/${to}/g' rslt"
        eval ${str} >rslt2
        cat rslt2 >rslt
    done < ./replaceSeed
    cat rslt >tmp

    cat tmp>monorubyInput
    ## data-ruby_monoのルビタグを、モノルビに変換する
    ## 前段でdata-ruby_monoを付与したものを対象に、モノルビ置換する一時shを作成して実行する。
    ## 後続には当該shの出力をつなげる。モノルビにはshortが指定される
    grep -o '<ruby class="ltlbg_ruby" data-ruby_mono="[^>]\+">[^<]\+<rt>[^<]\+<\/rt><\/ruby>' monorubyInput | uniq >org

    ## 中間ファイルorg(モノルビタグで抽出した結果)の長さが0のとき、処理しない
    if [ -s org ] ; then

      sed -e 's/\//\\\//g' org | sed -e 's/\"/\\\"/g' | sed -e 's/^/\| sed -e '\''s\//g' >tgt
      sed 's/<ruby class="ltlbg_ruby" data-ruby_mono="//g' org | sed 's/<rt>.\+$//g' | sed 's/\">/,/g' | uniq \
      | while read line || [ -n "${line}" ]; do \
        echo -n '/'
        echo ${line%%,*} | grep -o . | sed -e 's/^/<ruby class=\\\"ltlbg_ruby\\\" data-ruby_center=\\\"/' | sed -e 's/$/\\\">/' >1
        echo ${line##*,} | grep -o . >2
        echo ${line%%,*} | grep -o . | sed -e 's/^/<rt>/' | sed -e 's/$/<\\\/rt><\\\/ruby>/' >3
        paste 1 2 3 | sed -e 's/\t//g' | sed -z 's/\n//g' | sed -e 's/$/\/g'\'' \\/'
        echo ''
        done \
      >rep
      paste tgt rep | sed -e 's/\t//g' | sed -z 's/^/cat monorubyInput \\\n/' >tmp.sh
      bash  tmp.sh >tmp
    fi
  fi


    sed -e 's/\[\-\(.\)\(<span class="ltlbg_wSp"><\/span>\)\?\-\]/<span class="ltlbg_wdfix">\1<\/span>\2/g' tmp \
  | sed -e 's/\([^[]\)\^\([^\^]\{1,3\}\)\^\([^]]\)/\1<span class="ltlbg_tcyM">\2<\/span>\3/g' \
  | sed -e 's/\[\(\^\|<span class="ltlbg_tcy.">\)\(.\)\(\^\|<\/span>\)\]/<span class="ltlbg_rotate">\2<\/span>/g' \
  | sed -e 's/\[l\[\(.\)\(.\)\]r\]/<span class="ltlbg_forceGouji1">\1<\/span><span class="ltlbg_forceGouji2">\2<\/span>/g' \
  | sed -e 's/\(；\|\;\)/<span class="ltlbg_semicolon">；<\/span>/g' \
  | sed -e 's/\(：\|\:\)/<span class="ltlbg_colon">：<\/span>/g' \
  | sed -e 's/＆ａｍｐ/\&amp;/g' \
  | sed -e 's/＆ｌｔ/\&lt;/g' \
  | sed -e 's/＆ｇｔ/\&gt;/g' \
  | sed -e 's/＆＃３９/\&#39;/g' \
  | sed -e 's/＆ｑｕｏｔ/\&quot;/g' \
  | sed -e 's/\([！？♥♪☆]\)<span class="ltlbg_wSp"><\/span>゛/<span class="ltlbg_dakuten">\1<\/span><span class="ltlbg_wSp"><\/span>/g' \
  | sed -e 's/\(.\)゛/<span class="ltlbg_dakuten">\1<\/span>/g' \
  | sed -e 's/id="\(.*\)<span class="ltlbg_tcy[^>]\+">\(.*\)<\/span>\(.*\)>/id="\1\2\3">/g' \
  | sed -z 's/^/\<link rel=\"stylesheet\" href=\"\.\.\/littlebugTD\.css"\>\n/' \
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
  | sed -e 's/<section class="ltlbg_section">/[chapter]/g' \
  | sed -e 's/<section class="ltlbg_section" id="\([^"]\+\)">/[chapter:\1]/g' \
  | sed -e 's/\[chapter:\]/\[chapter\]/g'  \
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

  ## モノルビを復旧
  ## <ruby class=\"ltlbg_ruby\" data-ruby_center=\"[^]]\">〜で抽出したものを置換元とする。
  ## 基底文字だけを持つ中間ファイルと、ルビだけを持つ中間ファイルを作成し、置換先とする。
  ## 置換機能を持った中間シェルスクリプトを作成し、実行する。
  cat tmp2 >monorubyInput
  grep -o '\(<ruby class=\"ltlbg_ruby\" data-ruby_center=\"[^]]\">[^<]<rt>[^<]<\/rt><\/ruby>\)\+' monorubyInput | uniq >tgt
  cat tgt \
  | while read line || [ -n "${line}" ]; do \
      echo ${line} \
      | sed -e 's/<ruby class="ltlbg_ruby" data-ruby_center=".">//g' \
      | sed -e 's/<rt>/,/g' \
      | sed -e 's/<\/rt><\/ruby>/\t/g' \
      | sed -e 's/,[^\t]\+\t//g' ; \
 done >1
 cat tgt \
 | while read line || [ -n "${line}" ]; do \
     echo ${line} \
     | sed -e 's/<ruby class="ltlbg_ruby" data-ruby_center=".">//g' \
     | sed -e 's/<rt>/,/g' \
     | sed -e 's/<\/rt><\/ruby>/\t/g' \
     | sed -e 's/\t\?.,//g' ; \
 done >2
  paste 1 2 | sed -e 's/^/{/' | sed -e 's/\t/｜/' | sed -e 's/$/}/' | sed -e 's/\t//g' >rep
  paste tgt rep | sed -e 's/\"/\\\"/g' | sed -e 's/\//\\\//g' | sed -e 's/^/\| sed -e '\''s\//g' | sed -e 's/\t/\//' | sed -e 's/$/\/g'\'' \\/g' | sed -z 's/^/cat monorubyInput \\\n/g' >tmp.sh
  bash tmp.sh >tmp2

  ## モノルビ以外の<span class="ltlbg_ruby" data-ruby_XXX="XXX"></span>を復旧
    sed -e 's/<ruby class="ltlbg_ruby" data-ruby_[^=]\+="\([^"]\+\)">\([^<]\+\)<rt>[^<]\+<\/rt><\/ruby>/{\2｜\1}/g' tmp2 >tmp 

  ## 圏点タグを《《基底文字》》へ復旧する
  ## <ruby class=\"ltlbg_emphasis\" data-ruby_emphasis=\"[^]]\">〜で抽出したものを置換元とする。
  ## 基底文字だけを持つ中間ファイルと、ルビだけを持つ中間ファイルを作成し、置換先とする。
  ## 置換機能を持った中間シェルスクリプトを作成し、実行する。
  cat tmp >emphasisInput
  grep -o '\(<ruby class=\"ltlbg_emphasis\" data-emphasis=\"[^]]\">[^<]<rt>[^<]<\/rt><\/ruby>\)\+' emphasisInput | uniq >tgt
  cat tgt \
  | while read line || [ -n "${line}" ]; do \
      echo ${line} \
      | sed -e 's/<ruby class="ltlbg_emphasis" data-emphasis=".">//g' \
      | sed -e 's/<rt>/,/g' \
      | sed -e 's/<\/rt><\/ruby>/\t/g' \
      | sed -e 's/,[^\t]\+\t//g' \
      | sed -e 's/\(.\+\)/《《\1》》/g' ; \
  done >rep
  paste tgt rep | sed -e 's/\"/\\\"/g' | sed -e 's/\//\\\//g' | sed -e 's/^/\| sed -e '\''s\//g' | sed -e 's/\t/\//' | sed -e 's/$/\/g'\'' \\/g' | sed -z 's/^/cat emphasisInput \\\n/g' >tmp.sh
  bash tmp.sh >tmp

  ## <h2 class="ltlbg_sectionName">\1<\/h2>を行頭◆へ
  sed -e 's/<h2 class="ltlbg_sectionName">\([^<]\+\)<\/h2>/◆\1/g' tmp >tmp2

  ## 「&lt;」  を「<」(半角)へ変換
  ## 「&gt;」  を「>」(半角)へ変換
  ## 「&amp;」 を「&」(半角)へ変換
  ## 「&quot;」を「'」(半角)へ変換
  ## 「&#39;」 を「"」(半角)へ変換
    sed -e 's/&amp;/\&/g' tmp2 \
  | sed -e 's/&lt;/</g' \
  | sed -e 's/&gt;/>/g' \
  | sed -e 's/&quot;/'\''/g' \
  | sed -e 's/&#39;/\"/g' >tmp

  ## ここまで生じているハード空行は副産物なので削除
  ## その上で、<br class="ltlbg_br">、<br class="ltlbg_blankline">を削除
    sed -z 's/^\n//g' tmp \
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
eval $rmstrBase'raw'
eval $rmstrBase'org'
eval $rmstrBase'r'
eval $rmstrBase'emphasisInput'
eval $rmstrBase'rubyInput'
eval $rmstrBase'rubytmp'
eval $rmstrBase'monorubyInput'
eval $rmstrBase'emphtmp'
eval $rmstrBase'replaceSeed'
eval $rmstrBase'rslt'
eval $rmstrBase'rslt2'
eval $rmstrBase'tmp'
eval $rmstrBase'tmp2'
eval $rmstrBase'tmp.sh'

exit 0