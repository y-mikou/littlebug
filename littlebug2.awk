#!/usr/bin/awk -f
#########################################################
## littlebug.sh内で呼び出されている、
## 独自タグプレーンテキスト→独自クラスhtmlタグ付与を実施する
## gun awk プログラム
#########################################################

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
						class = "ltlbg_ruby-mono"
				} else if (length(ruby) == 2 * length(parent)) {
						class = "ltlbg_ruby-same"
				} else if (length(ruby) > 2 * length(parent)) {
						class = "ltlbg_ruby-long"
				} else {
						class = "ltlbg_ruby-short"
				}

				# 置換後のHTMLを生成
				replacement = "<ruby class=\"" class "\" data-" class "=\"" ruby "\">" parent "<rt>" ruby "</rt></ruby>"
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
	output_buffer = ""   # 出力バッファ
}

##パターンごとに処理を記述###
#空行は出力しない
/^[ 　]*$/ { next; }

# 行末、閉じ括弧直前のゴミスペースを掃除
/[ 　]$/        { $0 = gensub(/[ 　]$/, "", "g", $0)}
/[ 　]([」』）〟])/ { $0 = gensub(/[ 　]([」』）〟])/, "\\1", "g", $0)}

# 特殊な記号を一時置換
"　"          { $0 = gensub("　", "〼", "g", $0) }
" "           { $0 = gensub(" ", "〿", "g", $0) }
/&#047;|\//   { $0 = gensub("＆＃０４７", "&#047;", "g", $0) }
/&#092;|\\/   { $0 = gensub("＆＃０９２", "&#092;", "g", $0) }
/&gt;|>/      { $0 = gensub("＆ｇｔ", "&gt;", "g", $0) }
/&lt;|</      { $0 = gensub("＆ｌｔ", "&lt;", "g", $0) }
/&#39;|'/     { $0 = gensub("＆＃３９", "&#39;", "g", $0) }
/&#quot;|\\"/ { $0 = gensub("＆ｑｕｏｔ", "&#quot;", "g", $0) }
/&amp;|&/     { $0 = gensub("＆ａｍｐ", "&amp;", "g", $0) }

# ユーザが指定する不要な一文字幅化を除去(指定がなくても変換される/指定があると変換が二重に行われる)
/\[-(!!|!\?|\?!|\?\?)-\]/  { $0 = gensub(/\[-(!!|!\?|\?!|\?\?)-\]/, "\\1", "g", $0) }
#§記号とセクション名の間にユーザが入れているかも知れないゴミスペースを掃除
/^(§+)[〿〼]/ { $0 = gensub(/^(§+)[〿〼]/, "\\1", "g", $0) }

# 記号類の統一
/[♡♥❤]/  { $0 = gensub(/[♡♥❤]/, "❤️", "g", $0) }
/☆/        { $0 = gensub(/☆/, "★", "g", $0) }
/□/        { $0 = gensub(/□/, "■", "g", $0) }
/[♫♬]/    { $0 = gensub(/[♫♬]/, "♪", "g", $0) }
/―+/       { $0 = gensub(/―+/, "―", "g", $0) }
/！！/      { $0 = gensub(/！！/, "!!", "g", $0) }
/！？/      { $0 = gensub(/！？/, "!?", "g", $0) }
/？！/      { $0 = gensub(/？！/, "?!", "g", $0) }
/？？/      { $0 = gensub(/？？/, "??", "g", $0) }

# 連続する感嘆符・疑問符・記号類の後に全角スペースを挿入し、
# それを<span class="ltlbg_wSp"></span>に置換
# 対象 ！!?？❤️💞💕♪★💢✨️
/([!\?！？❤️💞💕♪★💢✨️])〼*([^〼」』）!\?！？❤️💞💕♪★💢✨️、。])/ { 
	$0 = gensub(/([!\?！？❤️💞💕♪☆★💢✨️])〼*([^〼」』）!\?！？!\?！？❤️💞💕♪★💢✨️、。])/, "\\1<span class=\"ltlbg_wSp\"></span>\\2", "g", $0) 
}
# 特殊記号類(曖昧幅を持つ可能性がある記号)・縦中横対象を、<span class="ltlbg_wdfix"></span>タグで括る
/([❤️💞💕♪★💢✨️★■♪])/ { $0 = gensub(/([❤️💞💕♪★💢✨️♪])/, "<span class=\"ltlbg_wdfix_auto\">\\1</span>", "g", $0) }
/(!!|!\?|\?!|\?\?)/             { $0 = gensub(/(!!|!\?|\?!|\?\?)/, "<span class=\"ltlbg_wsymbol\">\\1</span>", "g", $0) }

### 章・中段落系処理 ※必ず処理する ###
/^§+/ {
	# section(中段落)###########################################################
	#行頭に§が登場する場合、セクション名タグを付与し、セクションタグを開始する。
	if ($0 ~ /^§+/) {

		#初回の場合、pタググループは開始されていないので閉じない
		#初回以外では、セクションの境界でpタググループを必ず閉じる
		if (state_p != "none") {
				output_buffer = output_buffer "  </div>" ORS
				state_p = "none"
		}
		#初回の場合、セクションを開始する(セクション状態を開始する)
		#初回以外では、セクションを閉じてから開き直す
		if (state_section != "none") {
			output_buffer = output_buffer "</section>" ORS
		}

		# sectionクラスを決定する
		section_class = "ltlbg_section"
		if ($0 ~ /^§§/) {
			section_class = "ltlbg_section_sukebe"
			# ❤を除去
			sub(/§§/, "§", $0)
		}

		output_buffer = output_buffer "<section class=\"" section_class "\">" ORS
		state_section = "section"

		# §の行自体にもルビなどの置換を適用したい場合はここに記述
		$0 = apply_ruby_classes($0)
		$0 = apply_emphasis_dots($0)
		
		$0 = gensub(/(§+.*)/, "  <h2 class=\"ltlbg_section_name\">\\1</h2>", "g", $0);

		$0 = gensub(/〿/, "<span class=\"ltlbg_sSp\"></span>", "g", $0);
		$0 = gensub(/〼/, "　", "g", $0);

		output_buffer = output_buffer $0 ORS
		next
	}
}

/^[「『（]/ {
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
		if (state_p != "none") { output_buffer = output_buffer "  </div>" ORS }
		output_buffer = output_buffer "  <div class=\"" current_type "\">" ORS
		state_p = current_type
	}
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
/^([「『（])([^」』）]+)([」』）])$/ { $0 = gensub(/^([「『（])([^」』）]+)([」』）])$/, "    <p class=\"ltlbg_bracket\" data-p_header=\"\\1\" data-p_footer=\"\\3\">\\2</p><!--bracket-->", "g", $0) } #括弧両方がある行
/^([「『（])([^」』）]+)$/        { $0 = gensub(/^([「『（])([^」』）]+)$/, "    <p class=\"ltlbg_bracket\" data-p_header=\"\\1\" data-p_footer=\"\">\\2</p><!--bracket-->", "g", $0) } #開括弧のみの行
/^([^「『（]+)([」』）])$/       { $0 = gensub(/^([^「『（]+)([」』）])$/, "    <p class=\"ltlbg_bracket\" data-p_footer=\"\\2\">\\1</p><!--bracket-->", "g", $0) } #閉じ括弧のみの行
/^〼/                  { $0 = gensub(/^〼(.+)$/, "    <p class=\"ltlbg_desciption\" data-p_header=\"〼\">\\1</p><!--descript-->", "g", $0) } #地の文(括弧類グループの内部含む)


#############################################################################
## 通常の変換
#############################################################################
### タグで括るタイプの修飾 ###
/[^"]〼[^"]/                 { $0 = gensub("([^\"])〼([^\"])", "\\1<span class=\"ltlbg_wSp\"></span>\\2", "g", $0) } # 全角スペース
/―/                           { $0 = gensub(/―/, "<span class=\"ltlbg_wSize\">―</span>", "g", $0) } #全角ダッシュは常にワイドタグを適用
/\[-([^\-\[]+)-\]/             { $0 = gensub(/\[-([^\-\[]+)-\]/, "<span class=\"ltlbg_wdfix\">\\1</span>", "g", $0) } #強制1文字幅タグ
/\*\*([^\*]+)\*\*/             { $0 = gensub(/\*\*([^\*]+)\*\*/, "<span class=\"ltlbg_bold\">\\1</span>", "g", $0) } #太字
/\[\^([^\^\[]+)\^\]/           { $0 = gensub(/\[\^([^\^\[]+)\^\]/, "<span class=\"ltlbg_rotate\">\\1</span>", "g", $0) } #回転タグ
/\[\^([^\^]+)\^/               { $0 = gensub(/\^([^\^]+)\^/,"<span class=\"ltlbg_tcy\">\\1</span>", "g",$0) } #縦中横
/\[%\[([^\[\]])([^\[\]])\]%\]/ { $0 = gensub(/\[%\[([^\[\]])([^\[\]])\]%\]/, "<span class=\"ltlbg_forceGouji1\">\\1</span><span class=\"ltlbg_forceGouji2\">\\2</span>", "g", $0) } #強制合字1/2タグ
/[；;]/                        { $0 = gensub(/[；;]/, "<span class=\"ltlbg_semicolon\">；</span>", "g", $0) } #半角セミコロンは全て全角に修正
/[：:]/                        { $0 = gensub(/[：:]/, "<span class=\"ltlbg_colon\">：</span>", "g", $0) } #半角コロンは全て全角に修正
/\[-[^-\[\]]{1,2}-\]/          { $0 = gensub(/\[-[^-\[\]]{1,2}-\]/, "<span class=\"ltlbg_wdfix\">\\1</span>", "g", $0) } #1文字幅化
	
# タグに置換するタイプの変換
# タグを挿入するだけで、改ページの実装はスタイルによる
/゛/          { $0 = gensub(/゛/, "<span class=\"ltlbg_dakuten\"></span>", "g", $0) } #スケベ濁音
/゜/          { $0 = gensub(/゜/, "<span class=\"ltlbg_handakuten\"></span>", "g", $0) } #キチガイ半濁音
/\[newpage\]/ { $0 = gensub(/\[newpage\]/, "<div class=\"ltlbg_newpage\"></div><!--ltlbg_newpage-->", "g", $0) } # 改ページ
/---/         { $0 = gensub(/---/, "<hr class=\"ltlbg_hr\">", "g", $0) } # 水平線
/／＼|〱/     { $0 = gensub(/／＼|〱/, "<span class=\"ltlbg_odori1\"></span><span class=\"ltlbg_odori2\"></span>", "g", $0) } #踊り字。

# ルビ・圏点……上部の関数で実装
/｜([^《]+)《([^》]+)》/ { $0 = apply_ruby_classes($0) }
/《《([^》]+)》》/         { $0 = apply_emphasis_dots($0) }

#############################################################################
## 行末処理
#############################################################################
## 特殊文字の復旧

{
	# タグに置換するタイプの変換
	# タグを挿入するだけで、改ページの実装はスタイルによる
	# line = gensub(/゛/, "<span class=\"ltlbg_dakuten\"></span>", "g", line); #スケベ濁音
	# line = gensub(/゜/, "<span class=\"ltlbg_handakuten\"></span>", "g", line); #キチガイ半濁音
	# line = gensub(/\[newpage\]/, "<div class=\"ltlbg_newpage\"></div><!--ltlbg_newpage-->", "g", line); # 改ページ
	# line = gensub(/---/, "<hr class=\"ltlbg_hr\">", "g", line); # 水平線
	# line = gensub(/／＼|〱/, "<span class=\"ltlbg_odori1\"></span><span class=\"ltlbg_odori2\"></span>", "g", line); #踊り字。
	
	###########################################################
	# ルビ・圏点……上部の関数で実装
	###########################################################
	# line = apply_ruby_classes(line)
	# line = apply_emphasis_dots(line)

	
	#############################################################################
	## 行末処理
	#############################################################################
	# 特殊文字の復旧
	$0 = gensub(/＆ａｍｐ/, "\\&amp;", "g", $0);
	$0 = gensub(/＆ｌｔ/, "\\&lt;", "g", $0);
	$0 = gensub(/＆ｇｔ/, "\\&gt;", "g", $0);
	$0 = gensub(/＆＃３９/, "\\&#39;", "g", $0);
	$0 = gensub(/＆ｑｕｏｔ/, "\\&quot;", "g", $0);
	$0 = gensub(/＆＃０４７/, "\\&#047;", "g", $0);
	$0 = gensub(/＆＃０９２/, "\\&#092;", "g", $0);

	#必要があってスペースを使用する必要がある場合に代わりに使用していた以下の特殊文字を元に戻す
	$0 = gensub(/〿/, "<span class=\"ltlbg_sSp\"></span>", "g", $0);
	$0 = gensub(/〼/, "　", "g", $0);

	# 行末 が」 かどうか（終了判定）
	# 行末が」であれば、現在継続中のクオート状態を解除する。
	if ($0 ~ /[」』）]$/) { in_quote = 0 }

}

# 行の出力（メモリに溜め込む）
{ output_buffer = output_buffer $0 ORS }

END {
	#一度もpタグが登場していない場合、閉じる必要がない(ほぼあり得ないが)
	if (state_p != "none") { output_buffer = output_buffer "  </div>" ORS }

	#一度もsectionタグが登場していない場合、閉じる必要がない(割とあり得る)
	if (state_section != "none") { output_buffer = output_buffer "</section>" ORS }

	##########################################################################################
	# htmlになるように先頭と末尾に必要なタグを付与する。
	# またlittlebugXXX.css読み込むよう追記する
	##########################################################################################
	header =        "<html>" ORS
	header = header "  <head>" ORS
	header = header "    <link rel=\"stylesheet\" href=\"./css/littlebugI.css\">" ORS
	header = header "    <!--<link rel=\"stylesheet\" href=\"./css/littlebugV.css\">-->" ORS
	header = header "    <link rel=\"stylesheet\" href=\"./css/littlebugH.css\">" ORS
	header = header "    <link rel=\"stylesheet\" href=\"./css/littlebugU.css\">" ORS

	#vvvv google fonts vvvvvvv
    header = header "    <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">" ORS
    header = header "    <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>" ORS
    header = header "    <link href=\"https://fonts.googleapis.com/css2?family=BIZ+UDMincho&display=swap\" rel=\"stylesheet\">" ORS
	#^^^^^ google fonts ^^^^^^

	header = header "  </head>" ORS
	header = header "  <body>" ORS
	header = header "<div class=\"ltlbg_container\">" ORS
	header = header "<!--文章内容ここから-->" ORS

	footer =        "<!--文章内容ここまで-->" ORS
	footer = footer "</div><!--ltlbg_container-->" ORS
	footer = footer "</body>" ORS
	footer = footer "</html>" ORS

	# メモリに溜め込んだ全ての出力を一度に出力
	printf "%s", header output_buffer footer
}
