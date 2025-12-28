#!/usr/bin/awk -f

# ルビタグにクラスを付与して置換する関数
# gawk拡張のmatch()第三引数を使用
function apply_ruby_classes(text) {
    new_text = ""
    # テキスト内にルビパターンがなくなるまでループ
    while (match(text, /｜([^《]+)《([^》]+)》/, m)) {
        # マッチした部分より前のテキストを新しいテキストに追加
        new_text = new_text substr(text, 1, RSTART - 1)

        parent = m[1]
        ruby = m[2]

        # クラスの決定
        class = ""
        if (length(parent) == length(ruby)) {
            class = "mono"
        } else if (length(ruby) == 2 * length(parent)) {
            class = "same"
        } else if (length(ruby) > 2 * length(parent)) {
            class = "long"
        } else {
            class = "short"
        }

        # 置換後のHTMLを生成
        replacement = "<ruby class=\"" class "\">" parent "<rt>" ruby "</rt></ruby>"
        # 新しいテキストに置換部分を追加
        new_text = new_text replacement

        # 未処理のテキスト部分を更新
        text = substr(text, RSTART + RLENGTH)
    }
    # 残りのテキスト部分を追加
    new_text = new_text text
    return new_text
}

# 圏点（傍点）を文字ごとのルビに変換する関数
function apply_emphasis_dots(text) {
    new_text = ""
    # 《《...》》 パターンがなくなるまでループ
    while (match(text, /《《([^》]+)》》/, m)) {
        # マッチ部分より前を new_text に追加
        new_text = new_text substr(text, 1, RSTART - 1)

        parent_text = m[1]
        
        replacement = ""
        
        # 親文字を1文字ずつループ
        for (i = 1; i <= length(parent_text); i++) {
            char = substr(parent_text, i, 1)
            replacement = replacement "<ruby class=\"emphasis\">" char "<rt>﹅</rt></ruby>"
        }
        
        new_text = new_text replacement
        
        text = substr(text, RSTART + RLENGTH)
    }
    new_text = new_text text
    return new_text
}

BEGIN {
  state_p = "none"     # none, discript, bracket
  state_section = "none"     # none, section
  in_quote = 0       # 1 = 「」の内部を処理中
}

{
  #############################################################################
  ## 初期処理、行全体的な処理
  #############################################################################
  #空行は出力しない
  if ($0 ~ /^$/) { next; }

  #置換後・出力用の文言を創出しつつ
  #判定自体は元の行の形を用いるため、$0とlineを別に設ける
  line = $0

  ###########################################################
  # 処理中に問題になる特殊文字の一次置換(最後に元に戻す)
  # htmlを意識して既に文字参照型で記述されているものも含む
  # スラッシュ
  line = gensub(/&#047;|\//, "＆＃０４７", "g", line);
  # バックスラッシュ
  line = gensub(/&#092;|\\/, "＆＃０９２", "g", line);
  # 半角の>
  line = gensub(/&gt;|>/, "＆ｇｔ", "g", line);
  #半角の<
  line = gensub(/&lt;|</, "＆ｌｔ", "g", line);
  # シングルクォーテーション
  line = gensub(/&#39;|'/, "＆＃３９", "g", line);
  # ダブルクォーテーション
  line = gensub(/&#quot;|\\"/, "＆ｑｕｏｔ", "g", line);
  # 残ったアンパサンド
  line = gensub(/&amp;|&/, "＆ａｍｐ", "g", line);

  # 全角スペースを<span class="ltlbg_sSp"></span>に置換
  line = gensub("　", "<span class=\"ltlbg_sSp\"></span>", "g", line);

  # 連続する感嘆符・疑問符・記号類の後に全角スペースを挿入し、
  # それを<span class="ltlbg_wSp"></span>に置換
  # 対象 ！!?？❤💞💕♪☆★💢
  line = gensub(/([!?！？❤💞💕♪☆★💢]+)([^」』）])/, "\\1<span class=\"ltlbg_wSp\"></span>\\2", "g", line);

  #############################################################################
  ## 段落系処理
  #############################################################################

  # section(中段落)###########################################################
  #行頭に§が登場する場合、セクション名タグを付与し、セクションタグを開始する。
  if ($0 ~ /^§+/) {

    #初回の場合、pタググループは開始されていないので閉じない
    #初回以外では、セクションの境界でpタググループを必ず閉じる
    if (state_p != "none") {
        print "  </div>"
        state_p = "none"
    }
    #初回の場合、セクションを開始する(セクション状態を開始する)
    #初回以外では、セクションを閉じてから開き直す
    if (state_section != "none") {
      print "</section>"
    }
    print "<section class=\"ltlbg_section\">"
    state_section = "section"

    # §の行自体にもルビなどの置換を適用したい場合はここに記述
    line = apply_ruby_classes(line)
    line = apply_emphasis_dots(line)
    
    line = gensub(/(§+.*)/, "  <h2 class=\"ltlbg_section_name\">\\1</h2>", "g", line);

    print line
    next
  }

  # div(中段落)  ################################################################
  # 当形式では「地の文の塊」と「セリフの塊」を分けて管理し、その塊を意味段落の一種としてdivで括る。
  # 地の文の塊……discript-groupクラス
  # セリフの塊……bracket-groupクラス
  # この意味段落をレイアウトにどう落とし込むか(例えば地の文とセリフの間には空行を挟む形式など)は、スタイル(css)によって決定する。

  # 現在の行に開き括弧類が含まれるか（開始判定）
  # 含まれていれば、以降をクオート状態とし、次に行末閉じ括弧類が現れるまでクオート中を維持する
  if ($0 ~ /^[「『（]/) { in_quote = 1}

  # 判定：現在、クオート状態が継続中であるか、もしくは行頭開き括弧類か
  # もしそうであれば、pタグのクラスをbracketにする。
  # これに該当しない場合はクラスはdiscriptとなる
  if ( in_quote == 1 || $0 ~ /^[「『（]/) {
    current_type = "ltlng_bracket-group"
  } else {
    current_type = "ltlng_discript-group"
  }

  # 状態が変わった（または最初の行）場合のタグ挿入
  if (state_p != current_type) {
    if (state_p != "none") { print "  </div>" }
    print "  <div class=\"" current_type "\">"
    state_p = current_type
  }
  
  # p(小段落)###########################################################
  # 行頭が全角スペースの行は「地の文の形式段落」とする。
  # 行頭が開き括弧類の行はセリフだが、セリフの行も形式段落として扱う。
  # 当形式では、セリフ内に更に形式段落を含むことを許容する。
  # セリフ内形式段落を実現するため、セリフ段落は以下の４つに分類する。
  # １．開き括弧と閉じ括弧の両方を含む行(一般的なセリフ行)
  # ２．開き括弧のみ(セリフ内形式段落につながる行)
  # ３．閉じ括弧のみ (セリフ内形式段落から戻る行)
  # ４．全角スペースで始まる行(地の文形式段落と同じ扱い。セリフ内であるか否かを問わない)
  # それぞれに対応するpタグを生成する。
  line = gensub(/^([「『（])([^」』）]+)([」』）])$/, "    <p class=\"bracket\" data-header=\"\\1\" data-footer=\"\\3\">\\2</p><!--bracket-->", "g", line);
  line = gensub(/^([「『（])([^」』）]+)$/, "    <p class=\"bracket\" data-header=\"\\1\" data-footer=\"-\">\\2</p><!--bracket-->", "g", line);
  line = gensub(/^[^「『（](.+)[」』）]$/, "    <p class=\"bracket\" data-header=\"-\" data-footer=\"」\">\\1</p><!--bracket-->", "g", line);
  line = gensub(/^　(.+)$/, "    <p class=\"discript\" data-header=\"　\" data-footer=\"-\">\\1</p><!--descript-->", "g", line);


  #############################################################################
  ## 通常の変換
  #############################################################################
  # 句読点・記号類のspanタグ化###########################################################  
  #タグで括るタイプの修飾_1文字
  line = gensub(/―/, "<span class=\"ltlbg_wSize\">―</span>", "g", line); #全角ダッシュは常にワイドタグを適用
  line = gensub(/\[-(.)-\]/, "<span class=\"ltlbg_wdfix\">\\1</span>", "g", line); #強制1文字幅タグ
  line = gensub(/\[\^(.)\^\]/, "<span class=\"ltlbg_rotate\">\\1</span>", "g", line); #回転タグ
  line = gensub(/\[l\[(.)\]r\]/, "<span class=\"ltlbg_forcedGouji1/2\">\\1</span>", "g", line); #強制合字1/2タグ
  line = gensub(/[；;]/, "<span class=\"ltlbg_semicolon\">；</span>/g", "g", line); #半角セミコロンは全て全角に修正
  line = gensub(/[：:]/, "<span class=\"ltlbg_colon\">：</span>/g", "g", line); #半角コロンは全て全角に修正

  #   #タグで括るタイプの修飾_複数文字
  line = gensub(/~..~/,"<span class=\"ltlbg_tcy\">//1</span>", "g",line) #縦中横
  line = gensub(/\*\*\([^\*]+\)\*\*/, "<span class=\"ltlbg_bold\">\\1</span>", "g", line); #太字
  
  # タグに置換するタイプの変換
  # タグを挿入するだけで、改ページの実装はスタイルによる
  line = gensub(/゛/, "<span class=\"ltlbg_dakuten\"></span>", "g", line); #スケベ濁音
  line = gensub(/゜/, "<span class=\"ltlbg_handakuten\"></span>", "g", line); #キチガイ半濁音
  line = gensub(/\[newpage\]/, "<br class=\"ltlbg_newpage\">", "g", line); # 改ページ
  line = gensub(/---/, "<span class=\"ltlbg_hr\"></span>", "g", line); # 水平線
  line = gensub(/／＼|〱/, "<span class=\"ltlbg_odori1\"></span><span class=\"ltlbg_odori2\"></span>", "g", line); #踊り字。
  

  
  ###########################################################
  # ルビ・圏点……上部の関数で実装
  ###########################################################
  line = apply_ruby_classes(line)
  line = apply_emphasis_dots(line)

  
  #############################################################################
  ## 行末処理
  #############################################################################
  ## 特殊文字の復旧
  line = gensub(/＆ａｍｐ/, "\\&amp;", "g", line);
  line = gensub(/＆ｌｔ/, "\\&lt;", "g", line);
  line = gensub(/＆ｇｔ/, "\\&gt;", "g", line);
  line = gensub(/＆＃３９/, "\\&#39;", "g", line);
  line = gensub(/＆ｑｕｏｔ/, "\\&quot;", "g", line);
  line = gensub(/＆＃０４７/, "\\&#047;", "g", line);
  line = gensub(/＆＃０９２/, "\\&#092;", "g", line);
  # line = gensub(/〿/, "<span class=\"ltlbg_sSp\"></span>", "g", line);
  # line = gensub(/〼/, "<span class=\"ltlbg_wSp\"></span>", "g", line);

  # 行末 が」 かどうか（終了判定）
  # 行末が」であれば、現在継続中のクオート状態を解除する。
  if ($0 ~ /[」』）]$/) { in_quote = 0 }

  # 行の出力
  print line

}

END {
  #一度もpタグが登場していない場合、閉じる必要がない(ほぼあり得ないが)
  if (state_p != "none") { print "  </div>" }

  #一度もsectionタグが登場していない場合、閉じる必要がない(割とあり得る)
  if (state_section != "none") { print "</section>" }


  ##########################################################################################
  # 先頭にlittlebugXXX.css読み込むよう追記する
  ##########################################################################################
  ## <html>
  ##   <head>
  ##     <link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugI\.css">\n/' \
  ##     <link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugV\.css">\n/' \
  ##     <\!--\<link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugH\.css">-->\n/' \
  ##     <link rel=\"stylesheet\" href=\"\.\.\/css\/littlebugU\.css">\n/' \
  ##   </head>
  ## <html>
  # print "<html>"
  # print "  <head>"
  # print "    <link rel=\"stylesheet\" href=\"../css/littlebugI.css\">"
  # print "    <link rel=\"stylesheet\" href=\"../css/littlebugV.css\">"
  # print "    <!--<link rel=\"stylesheet\" href=\"../css/littlebugH.css\">-->"
  # print "    <link rel=\"stylesheet\" href=\"../css/littlebugU.css\">"
  # print "  </head>"
  # print "  <body>"
  # print "    <div class=\"ltlbg_container\">"
}
