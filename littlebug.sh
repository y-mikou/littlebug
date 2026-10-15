#!/bin/bash
export lang=ja_jp.utf-8

: "終了時クリンナップ" && {
	# 作業用一時ディレクトリの後始末用関数とトラップ設定
	function cleanup_tmpdir() {
		echo "⛓️‍💥 中断されました"
		#今は中間ファイルなどを使用していないため特に掃除はない
	}
	trap cleanup_tmpdir INT
}

: ”初期チェック” && {
	#GUN Awkがインストール済みであることを確認する
	if [[ $(gawk --virsion > /dev/null 2>&1 ) =~ 'GNU Awk' ]] ; then
			echo "警告: gun版awk が見つかりません。gun版awk をインストールしてください。" >&2
			return 1
	fi

	declare tgtFile="${1}"   #引数で指定されたファイルを対象とする
	declare tgtFileName="$(basename "${tgtFile}")"   #引数で指定されたファイルを対象とする
	if [[ "${tgtFile/ /}" = '' ]];then
		echo "💩変換元ファイルを指定してください"
		exit 1
	fi

	if [[ ! -e "${tgtFile}" ]]; then
		echo "💩 ${tgtFileName}なんてファイルいないです"
		exit 1
	fi

	if [[ $(file "${tgtFile}") =~ 'with CRLF' ]] ; then
		echo "💩 引数1に指定された${tgtFileName}は改行コードがCRLFです。LFに置換します。"
		sed -i 's/\r//' "${tgtFile}"
	fi

	convMode="${2}"  #'-t2h'でtxt→html、'-h2t'でhtml→txt、それ以外は今の所はエラー

	if [[ "${convMode}" != '' ]] && [[ "${convMode}" != '-t' ]] ; then
		echo "💩 引数1は、無し(txt→html)か、-t(html→txt)で指定してください"
		exit 1
	fi
}

: "初期処理" && {
	# 文字コード確認・変換、作業ディレクトリ、ファイルの定義
	chrset="$(file -i ${tgtFile})"

	SCRIPT_DIR=$(cd $(dirname $0); pwd)

	# 対象ファイルの文字コードを確認し、unknown-8bit(SJIS)ならUTF-8に変換する
	if [[ "${chrset##*charset=}" != 'utf-8' ]] ; then
		echo '入力ファイルのcharset(文字コード)がUTF-8ではありません。処理は続行しますが、変換結果を保証しません。'
		echo '※  ファイル内に日本語文字が一つも含まれていない場合、正しくUTF-8であってもこの警告が表示される可能性があります'
	fi
}

if [[ "${convMode}" = '' ]]; then
	## txt→html ############################################################################################
	: "txt→html変換処理" && {
		: "AWKコード定義" && {
			# littlebug.awkの内容をヒアドキュメントとして定義
			read -r -d '' AWK_CODE <<- 'AWK_EOF'
			#!/usr/bin/awk -f
			#########################################################
			## littlebug.sh内で呼び出されている、
			## 独自タグプレーンテキスト→独自クラスhtmlタグ付与を実施する
			## gun awk プログラム
			#########################################################

			# ルビタグにクラスを付与して置換する関数。
			# rt の各文字を要素化しておくと、CSS 側で文字単位の均等配置ができる。
			# gawk拡張のmatch()第三引数を使用。
			function apply_ruby_classes(text,    new_text, parent, ruby, parent_count, ruby_count, class, ruby_chars, i, char, replacement) {
					new_text = ""
					# テキスト内にルビパターンがなくなるまでループ
					while (match(text, /｜([^《]+)《([^》]+)》/, m)) {
							# マッチした部分より前のテキストを新しいテキストに追加
							new_text = new_text substr(text, 1, RSTART - 1)

							parent = m[1]
							ruby = m[2]
							parent_count = length(parent)
							ruby_count = length(ruby)

							# 母字とルビの長さの関係を、CSS の配置規則に対応する4分類にする。
							if (parent_count == ruby_count) {
									class = "ltlbg_ruby-mono"
							} else if (ruby_count == 2 * parent_count) {
									class = "ltlbg_ruby-same"
							} else if (ruby_count > 2 * parent_count) {
									class = "ltlbg_ruby-long"
							} else {
									class = "ltlbg_ruby-short"
							}

							# ルビを一文字ずつに分割する。短いルビ1文字だけはCSSで中央寄せにする。
							ruby_chars = ""
							for (i = 1; i <= ruby_count; i++) {
									char = substr(ruby, i, 1)
									ruby_chars = ruby_chars "<span class=\"ltlbg_ruby-char\">" char "</span>"
							}
							if (ruby_count == 1) {
									class = class " ltlbg_ruby-single"
							}

							# Ruby組版エンジンがrtの幅を行幅へ含めないよう、母字とルビは明示的なspanに分ける。
							# data属性には逆変換用の元のルビ文字列を保存する。
							replacement = "<span class=\"ltlbg_ruby " class "\" data-ltlbg-ruby=\"" ruby "\"><span class=\"ltlbg_ruby-base\">" parent "</span><span class=\"ltlbg_ruby-text\">" ruby_chars "</span></span>"
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
				# 全角スペース
				line = gensub("　", "〼", "g", line);
				# 半角スペース
				line = gensub(" ", "〿", "g", line);
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

				#ゴミスペースを掃除
				line = gensub(/[〿〼]$/, "", "g", line);
				line = gensub(/[〿〼]([」』）〟])/, "\\1", "g", line);
				#不要な一文字幅化を除去(指定がなくても変換される/指定があると変換が二重に行われる)
				line = gensub(/\[-(!!|!\?|\?!|\?\?)-\]/, "\\1", "g", line);

				# 記号種類の統一
				## UTF-8合字は置換元に設定するとawkではうまく機能しないため、合字以外の文字に置換して文字分離を回避するする。
				## 置換先として設定する分には機能するため、後続の行末処理で置換先として復帰させる。
				## ※環境のLC_ALLがUTF-8になっていれば問題は誘発されない
				line = gensub(/[❤️♡♥❤]/, "♥", "g", line); #後で❤️に復帰する対象
				line = gensub(/☆/, "★", "g", line);
				line = gensub(/□/, "■", "g", line);
				line = gensub(/[♫♬]/, "♪", "g", line);
				line = gensub(/―+/, "―", "g", line);
				line = gensub(/！！/, "!!", "g", line);
				line = gensub(/！？/, "!?", "g", line);
				line = gensub(/？！/, "?!", "g", line);
				line = gensub(/？？/, "??", "g", line);
				line = gensub(/^(§+)[〿〼]+/, "\\1〼", "g", line);
				
				# 連続する感嘆符・疑問符・記号類の後に全角スペースを挿入し、
				# それを<span class="ltlbg_wSp"></span>に置換
				# 対象 ！!?？♥💞💕♪☆★💢
				line = gensub(/([!\?！？♥💞💕♪☆★💢])〼*([^」』）!\?！？♥💞💕♪☆★💢、。゛゜])/, "\\1<span class=\"ltlbg_wSp\"></span>\\2", "g", line);

				#上記特殊記号(♥,★,■,♪,!!,!?,?!,??)を、<span class="ltlbg_wdfix"></span>タグで括る
				line = gensub(/([♥★■♪])/, "<span class=\"ltlbg_wdfix_auto\">\\1</span>", "g", line);
				line = gensub(/(!!|!\?|\?!|\?\?)/, "<span class=\"ltlbg_wsymbol\">\\1</span>", "g", line);

				#############################################################################
				## 段落系処理
				#############################################################################

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
						sub(/§§/, "§", line)
					}

					output_buffer = output_buffer "<section class=\"" section_class "\">" ORS
					state_section = "section"

					# §の行自体にもルビなどの置換を適用したい場合はここに記述
					line = apply_ruby_classes(line)
					line = apply_emphasis_dots(line)
					
					line = gensub(/(§+.*)/, "  <h2 class=\"ltlbg_section_name\">\\1</h2>", "g", line);

					line = gensub(/〿/, "<span class=\"ltlbg_sSp\"></span>", "g", line);
					line = gensub(/〼/, "　", "g", line);

					output_buffer = output_buffer line ORS
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
					if (state_p != "none") { output_buffer = output_buffer "  </div>" ORS }
					output_buffer = output_buffer "  <div class=\"" current_type "\">" ORS
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
				line = gensub(/^([「『（])([^」』）]+)([」』）])$/, "    <p class=\"ltlbg_bracket\" data-p_header=\"\\1\" data-p_footer=\"\\3\">\\2</p><!--bracket-->", "g", line); #両方
				line = gensub(/^([「『（])([^」』）]+)$/, "    <p class=\"ltlbg_bracket\" data-p_header=\"\\1\" data-p_footer=\"\">\\2</p><!--bracket-->", "g", line); #開括弧のみ
				line = gensub(/^([^「『（]+)([」』）])$/, "    <p class=\"ltlbg_bracket\" data-p_footer=\"\\2\">\\1</p><!--bracket-->", "g", line); #閉じ括弧のみ
				line = gensub(/^〼(.+)$/, "    <p class=\"ltlbg_desciption\" data-p_header=\"〼\">\\1</p><!--descript-->", "g", line); #地の文(括弧類グループの内部含む)

				#############################################################################
				## 通常の変換
				#############################################################################
				# 句読点・記号類のspanタグ化###########################################################  
				#タグで括るタイプの修飾
				line = gensub("([^\"])〼([^\"])", "\\1<span class=\"ltlbg_wSp\"></span>\\2", "g", line); # 全角スペース
				line = gensub(/―/, "<span class=\"ltlbg_wSize\">―</span>", "g", line); #全角ダッシュは常にワイドタグを適用
				line = gensub(/\[-([^\-\[]+)-\]/, "<span class=\"ltlbg_wdfix\">\\1</span>", "g", line); #強制1文字幅タグ
				line = gensub(/\*\*([^\*]+)\*\*/, "<span class=\"ltlbg_bold\">\\1</span>", "g", line); #太字
				line = gensub(/\[\^([^\^\[]+)\^\]/, "<span class=\"ltlbg_rotate\">\\1</span>", "g", line); #回転タグ
				line = gensub(/\^([^\^]+)\^/,"<span class=\"ltlbg_tcy\">\\1</span>", "g",line) #縦中横
				line = gensub(/\[%\[([^\[\]])([^\[\]])\]%\]/, "<span class=\"ltlbg_forceGouji1\">\\1</span><span class=\"ltlbg_forceGouji2\">\\2</span>", "g", line); #強制合字1/2タグ
				line = gensub(/[；;]/, "<span class=\"ltlbg_semicolon\">；</span>", "g", line); #半角セミコロンは全て全角に修正
				line = gensub(/[：:]/, "<span class=\"ltlbg_colon\">：</span>", "g", line); #半角コロンは全て全角に修正
				line = gensub(/\[-[^-\[\]]{1,2}-\]/, "<span class=\"ltlbg_wdfix\">\\1</span>", "g", line); #1文字幅化
				
				# タグに置換するタイプの変換
				# タグを挿入するだけで、改ページの実装はスタイルによる
				line = gensub(/゛/, "<span class=\"ltlbg_dakuten\"></span>", "g", line); #スケベ濁音
				line = gensub(/゜/, "<span class=\"ltlbg_handakuten\"></span>", "g", line); #キチガイ半濁音
				line = gensub(/\[newpage\]/, "<div class=\"ltlbg_newpage\"></div><!--ltlbg_newpage-->", "g", line); # 改ページ
				line = gensub(/---/, "<hr class=\"ltlbg_hr\">", "g", line); # 水平線
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

				#必要があってスペースを使用する必要がある場合に代わりに使用していた以下の特殊文字を元に戻す
				line = gensub(/〿/, "<span class=\"ltlbg_sSp\"></span>", "g", line);
				line = gensub(/〼/, "　", "g", line);

				# 行末 が」 かどうか（終了判定）
				# 行末が」であれば、現在継続中のクオート状態を解除する。
				if ($0 ~ /[」』）]$/) { in_quote = 0 }

				# UTF-8合字の復帰(UTF-8合字の判定煩雑化回避のため)
				## 前段で文字分離を回避したUTF-8合字を復旧する
				line = gensub("♥", "❤️", "g", line);

				# 行の出力（メモリに溜め込む）
				output_buffer = output_buffer line ORS

			}

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
				header = header "    <link rel=\"stylesheet\" href=\"../css/littlebugI.css\">" ORS
				header = header "    <!--<link rel=\"stylesheet\" href=\"../css/littlebugV.css\">-->" ORS
				header = header "    <link rel=\"stylesheet\" href=\"../css/littlebugH.css\">" ORS
				header = header "    <link rel=\"stylesheet\" href=\"../css/littlebugU.css\">" ORS

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
				print header output_buffer footer
			}
			AWK_EOF
		}

		destFile="${tgtFile/'.txt'/'_tagged.html'}" #出力ファイルの指定する
		printf '' > "${destFile}"

		: "警告表示" && {
			##警告表示####################################################################
			# 変換不能なケースを予め抽出する。
			# 処理は中断せず最後まで行うが、警告表示を行う。
			# おそらく変換処理は成功しない。
			##############################################################################
			# タブ文字が存在する
			grep -E -o -n '\t' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑タブ文字が存在します。変換結果は保証されません。' 
			fi
			# 行頭に全角スペース2つ以上の空白文字
			grep -E -o -n '^[ 　]{2,}' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑行頭に全角スペース2つ以上の空白文字があります。変換結果は保証されません。' 
			fi
			# ルビ指定に傍点の同時指定
			# ｜《》の全体か母字部分かのどちらかに、《《》》指定が入れ子されている※ルビ文字部分への特殊指定は後続でチェックしている
			grep -E -o -n '｜[^《]*《《[^》]+》》《[^》]+》|《《[^｜]*｜[^《]+《[^》]+》[^》]*》》' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑でルビと傍点が同時に設定されています。不適切な指定です。変換結果は保証されません。' 
			fi
			#2文字以上に回転指定
			grep -E -o -n '\[\^[^\^]{2,}\^\]' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で2文字以上の範囲に回転が設定されています。不適切な指定です。変換結果は保証されません。' 
			fi
			#ルビ全体への回転指定※母字のみあるいはルビ文字のみは許容する
			grep -E -o -n '\[\^[^｜]*｜[^《]*《《[^》]+》》[^\^]*\^\]' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑でルビと回転が同時に指定されています。不適切な指定です。変換結果は保証されません。' 
			fi
			#ルビ指定全体への縦中横※母字のみあるいはルビ文字のみは許容する
			grep -E -o -n '\^[^｜]*｜[^《]*《《[^》]+》》[^\^]*\^' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑でルビ指定全体への縦中横が指定されています。不適切な指定です。変換結果は保証されません。' 
			fi
			# 縦中横の中に半角英数記号以外(文字コード上「半角スペース」〜「~」の領域)が含まれている
			# ただし、縦中横全体への太字と傍点はは許容するため、《》*もこれらに含めない。
			grep -E -o -n '\^[^\^]*[^ -~《》]+[^\^]*\^' "${tgtFile}" >"${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で縦中横の中に半角英数文字以外が含まれています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
			fi
			# 縦中横指定の一部に太字指定
			# 縦中横指定^文字^の中に、**と**で括られていない文字が1文字以上ある
			grep -E -o -n '\^[^\*]+\*\*[^\*]+\*\*\^|\^\*\*[^\*]+\*\*[^\*]+\^' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で縦中横の一部にだけ太字が指定されています。この変換は非対応です。変換結果は保証されません。' 
			fi
			# 4文字以上の縦中横
			# ただし、縦中横全体への太字と傍点はは許容するため、《》*もこれらに含めない。
			grep -E -o -n '\^(\*\*)*[^《》\^]{4,}(\*\*)*\^' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で4桁以上の縦中横が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
			fi
			# 縦中横指定の一部にのみ傍点指定
			grep -E -o -n '\^[^《]+《《[^》]+》》\^|\^《《[^》]+》》[^》]+\^' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で縦中横の一部にだけ傍点が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
			fi
			# ルビ指定全体に回転指定
			grep -E -o -n '\[\^｜[^《]+《[^》]+》\^\]' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑でルビ指定の全体に回転が指定されています。不適切な指定です。変換は実施しますが結果は保証されません。' 
			fi
			# 強制合字の指定が2文字ではない
			# 1文字か、3文字以上は駄目
			grep -E -o -n '\[l\[[^\]\]r\]|\[l\[[^\]{3}\]r\]' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で強制合字には2文字だけを指定してください。この変換は非対応です。変換は実施しますが結果は保証されません。' 
			fi
			# アへ濁点に回転指定
			grep -E -o -n '\[\^.゛゜\^\]|\[\^.゜\^\]' "${tgtFile}" > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑で強制濁点に回転が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
			fi
			# ルビ文字に特殊指定
			## ルビ文字にルビ
			grep -E -o -n '｜[^《]+《[^》]*｜[^》]*》' "${tgtFile}" > "${destFile}"
			## ルビ文字に太字
			grep -E -o -n '｜[^《]+《[^《》]*《《[^》]+》》[^》]*》' "${tgtFile}" >> "${destFile}"
			## ルビ文字に回転
			grep -E -o -n '｜[^《]+《[^\[》]*\[\^\[^\^]\^\][^》]*》' "${tgtFile}" >> "${destFile}"
			## ルビ文字に合字
			grep -E -o -n '｜[^《]+《[^[》]*[l[[^]]{2}]r][^》]*》' "${tgtFile}" >> "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑でルビ文字に修飾が指定されています。この変換は非対応です。変換は実施しますが結果は保証されません。' 
			fi
			# 不要なスペース(改行直前のスペース、閉じ括弧直前のスペース)
			grep -E -o -n '[ 　]$|[ 　]([」』）〟])|^(§+)[ 　]' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に不要なスペース(改行直前のスペース、閉じ括弧直前のスペース、セクション記号直後のスペース)が含まれています。'
				echo '内部的に除去して変換を実施します（元ファイルは修正しませんが、修正が必要な箇所です）。'
			fi
			#組版時に置換される記号類
			##表記ゆれする可能性がある記号の統一
			grep -E -o -n '[❤️♡❤☆□♫♬]' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる記号は変換後、別の記号に置換されます。（元ファイルは修正しません）'
			fi
			##組版時に置換される連続「―」
			grep -E -o -n '―{2,}' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる、連続する「―」は、倍サイズの一つの「―」へ変換されます(元ファイルは修正しません)'
			fi
			##！？のペア
			grep -E -o -n '！！|！？|？！|？？' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる、！!、！？などのペアは変換後、半角のペアに変換されます(元のファイルは修正しません)'
			fi
			grep -E -o -n '\[-!!-\]|\[-!\?-\]|\[-\?!-\]|\[-\?\?-\]' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる、半角の!？ペアは自動的に一文字幅化されるので[- -]の指定は不要です(元のファイルは修正しません)'
			fi
			grep -E -o -n '^(§+)[ 　]' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる、！!、！？などのペアは変換後、１文字幅に収まるように半角のペアに変換されます(元のファイルは修正しません)'
			fi
			grep -E -o -n '^$' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に含まれる空行は、元ファイルの記述に関わらず、変換規則に則って削除あるいは追加されます(元のファイルは修正しません)'
			fi
			# 記号類の直後のスペースがない
			grep -E -o -n '[!\?！？❤️♡♥❤💞💕♪☆★💢][^　」』）!\?！？❤️♡♥❤💞💕♪☆★💢、。゛゜]' "${tgtFile}" | sort | uniq > "${destFile}"
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑記号類の直後に、それが連続するか行末・括弧内末尾でない限り、スペースを挿入します(元のファイルは修正しません)'
			fi
			# 半角英数記号が単独で存在する
			grep -E -o -n '[0-9a-zA-Z]{2}*[0-9a-zA-Z]' "${tgtFile}" | sort | uniq > "${destFile}"
			sed -i "/newpage/d" "${destFile}" #[newpage]は指定タグなので許容
			if [[ -s "${destFile}" ]]; then 
				cat "${destFile}"
				echo '🤔 ↑に、半角英数記号が単独(または奇数)で登場します。'
			fi
		}

		: "変換実施" && {
			#AWKコードを実行（ヒアドキュメントで定義されたAWK_CODEを使用）
			gawk "$AWK_CODE" "${tgtFile}" > "${destFile}"
		}

		echo "✨ "${destFile}"を出力しました[html化]"

	}

elif [[ "${convMode}" = '-t' ]]; then
  ## html→txt ############################################################################################
	: "html→txt変換処理" && {

		: "AWKコード定義" && {
			# littlebug.awkの内容をヒアドキュメントとして定義
			read -r -d '' AWK_CODE <<- 'AWK_EOF'
			#!/usr/bin/awk -f

			# ルビタグを元の短縮タグに戻す関数。
			# 新形式は rt 内を文字ごとの span にしているため、data属性からルビを復元する。
			# 旧形式（data-ltlbg_ruby-*）も同じ処理で受け付ける。
			function strip_ruby_tags(text,    new_text, attrs, tail, ruby, parent, ruby_start, ruby_length, closing_tag) {
				new_text = ""
				while (match(text, /<(ruby|span) class="([^"]*ltlbg_ruby[^"]*)" ([^>]*)>(<span class="ltlbg_ruby-base">([^<]+)<\/span><span class="ltlbg_ruby-text">|([^<]+)<rt>)/, m)) {
					ruby_start = RSTART
					ruby_length = RLENGTH
					attrs = m[3]
					if (!match(attrs, /data-ltlbg[_-]ruby(-[^=]*)?="([^"]+)"/, a)) {
						# 想定外のrubyは変換せず、検索位置だけ進める。
						new_text = new_text substr(text, 1, ruby_start + ruby_length - 1)
						text = substr(text, ruby_start + ruby_length)
						continue
					}
					tail = substr(text, ruby_start + ruby_length)
					closing_tag = (m[5] != "" ? "</span></span></" m[1] ">" : "</rt></ruby>")
					if (!match(tail, closing_tag)) {
						break
					}
					new_text = new_text substr(text, 1, ruby_start - 1)
					ruby = a[2]
					parent = (m[5] != "" ? m[5] : m[6])
					new_text = new_text "｜" parent "《" ruby "》"
					text = substr(tail, RSTART + RLENGTH)
				}
				new_text = new_text text
				return new_text
			}

			# 圏点（傍点）タグを元の短縮タグに戻す関数
			# <ruby class="emphasis">文<rt>﹅</rt></ruby>... → 《《文...》》
			function strip_emphasis_tags(text) {
				new_text = ""
				# 連続する圏点タグを検出してまとめて処理
				while (match(text, /<ruby class="emphasis">([^<])<rt>﹅<\/rt><\/ruby>/, m)) {
					new_text = new_text substr(text, 1, RSTART - 1)
					
					# 最初の文字を取得
					parent_chars = m[1]
					matched_len = RLENGTH
					outer_rstart = RSTART
					remaining = substr(text, outer_rstart + matched_len)
					
					# 連続する圏点タグを処理
					while (match(remaining, /^<ruby class="emphasis">([^<])<rt>﹅<\/rt><\/ruby>/, m2)) {
						parent_chars = parent_chars m2[1]
						matched_len = matched_len + RLENGTH
						remaining = substr(remaining, RLENGTH + 1)
					}
					
					new_text = new_text "《《" parent_chars "》》"
					text = substr(text, outer_rstart + matched_len)
				}
				new_text = new_text text
				return new_text
			}

			BEGIN {
				output_buffer = ""
				in_content = 0
				is_sukebe_section = 0
			}

			{
				line = $0
				
				# HTMLヘッダー/フッター部分をスキップ
				if (line ~ /^<html>/ || line ~ /^<\/html>/ || 
					line ~ /^  <head>/ || line ~ /^  <\/head>/ ||
					line ~ /^    <link / || line ~ /^    <!--<link / ||
					line ~ /^  <body>/ || line ~ /^<\/body>/ ||
					line ~ /^<div class="ltlbg_container">/ || line ~ /^<\/div><!--ltlbg_container-->/ ||
					line ~ /^<!--文章内容ここから-->/ || line ~ /^<!--文章内容ここまで-->/) {
					next
				}
				
				# sectionタグを処理
				if (match(line, /<section class="([^"]+)">/, m)) {
					if (m[1] == "ltlbg_section_sukebe") {
						is_sukebe_section = 1
					} else {
						is_sukebe_section = 0
					}
					next
				}
				if (line ~ /^<\/section>/) {
					is_sukebe_section = 0
					next
				}
				
				# divタグを除去
				if (line ~ /^  <div class="ltlng_/ || line ~ /^  <\/div>/) {
					next
				}
				
				# 先頭のASCII空白とタブを除去（インデント）
				# 全角スペースは残す
				line = gensub(/^[ \t]+/, "", "g", line)
				
				# セクション名タグを処理
				# <h2 class="ltlbg_section_name">§内容</h2> → §内容 or §§内容
				if (match(line, /<h2 class="ltlbg_section_name">([^<]+)<\/h2>/, m)) {
					line = m[1]
					if (is_sukebe_section == 1) {
						sub(/^§/, "§§", line)
					}
				}
				
				# ルビタグを元に戻す（内側のタグを先に処理）
				line = strip_ruby_tags(line)
				
				# 圏点タグを元に戻す（内側のタグを先に処理）
				line = strip_emphasis_tags(line)
				
				# 一文字幅化のspanタグを戻す
				# <span class="ltlbg_wdfix">内容</span> → [-内容-]
				line = gensub(/<span class="ltlbg_wdfix">([^<]*)<\/span>/, "[-\\1-]", "g", line)
				# <span class="ltlbg_wdfix_auto">内容</span> → 内容
				line = gensub(/<span class="ltlbg_wdfix_auto">([^<]*)<\/span>/, "\\1", "g", line)
								
				# 全角ダッシュのspanタグを除去
				line = gensub(/<span class="ltlbg_wSize">―<\/span>/, "―", "g", line)
				
				# 太字タグを元に戻す
				# <span class="ltlbg_bold">内容</span> → **内容**
				line = gensub(/<span class="ltlbg_bold">([^<]*)<\/span>/, "**\\1**", "g", line)
				
				# 回転タグを元に戻す
				# <span class="ltlbg_rotate">内容</span> → [^内容^]
				line = gensub(/<span class="ltlbg_rotate">([^<]*)<\/span>/, "[^\\1^]", "g", line)
				
				# 縦中横タグを元に戻す
				# <span class="ltlbg_tcy">内容</span> → ^内容^
				line = gensub(/<span class="ltlbg_tcy">([^<]*)<\/span>/, "^\\1^", "g", line)
				
				# 強制合字タグを元に戻す
				# <span class="ltlbg_forceGouji1">字1</span><span class="ltlbg_forceGouji2">字2</span> → [%[字1字2]%]
				line = gensub(/<span class="ltlbg_forceGouji1">([^<]*)<\/span><span class="ltlbg_forceGouji2">([^<]*)<\/span>/, "[%[\\1\\2]%]", "g", line)
				
				# セミコロンタグを元に戻す
				line = gensub(/<span class="ltlbg_semicolon">；<\/span>/, "；", "g", line)
				
				# コロンタグを元に戻す
				line = gensub(/<span class="ltlbg_colon">：<\/span>/, "：", "g", line)
				
				# スケベ濁音タグを元に戻す
				line = gensub(/<span class="ltlbg_dakuten"><\/span>/, "゛", "g", line)
				
				# キチガイ半濁音タグを元に戻す
				line = gensub(/<span class="ltlbg_handakuten"><\/span>/, "゜", "g", line)
				
				# 改ページタグを元に戻す
			    line = gensub(/<div class="ltlbg_newpage"><\/div><!--ltlbg_newpage-->/, "[newpage]", "g", line)
				
				# 水平線タグを元に戻す
				line = gensub(/<hr class="ltlbg_hr">/, "---", "g", line)
				
				# 踊り字タグを元に戻す
				line = gensub(/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/, "／＼", "g", line)

				# 連続する感嘆符・疑問符を元に戻す
				line = gensub(/<span class="ltlbg_wsymbol">([^<]+)<\/span>/, "\\1", "g", line);
				
				# HTML文字参照を元に戻す
				line = gensub(/&amp;/, "\\&", "g", line)
				line = gensub(/&lt;/, "<", "g", line)
				line = gensub(/&gt;/, ">", "g", line)
				line = gensub(/&#39;/, "'", "g", line)
				line = gensub(/&quot;/, "\"", "g", line)
				line = gensub(/&#047;/, "/", "g", line)
				line = gensub(/&#092;/, "\\\\", "g", line)

				# 全角スペースのspanタグを除去
				line = gensub(/<span class="ltlbg_wSp"><\/span>/, "　", "g", line)
				# 半角スペースのspanタグを除去
				line = gensub(/<span class="ltlbg_sSp"><\/span>/, " ", "g", line)
				
				# 段落タグを処理（内部タグの除去後に処理）
				# <p class="ltlbg_bracket" data-p_header="「" data-p_footer="」">内容</p><!--bracket--> → 「内容」
				line = gensub(/<p class="ltlbg_bracket"[^>]*data-p_header="([^"]*)"[^>]*data-p_footer="([^"]*)"[^>]*>(.*)<\/p><!--bracket-->/, "\\1\\3\\2", "g", line)
				
				# 閉じ括弧のみのパターン（全角スペースが含まれる場合）
				line = gensub(/<p class="ltlbg_bracket"[^>]*data-p_footer="([^"]*)"[^>]*>(.*)<\/p><!--bracket-->/, "\\2\\1", "g", line)
				
				# 地の文タグを処理
				# <p class="ltlbg_desciption" data-p_header="　">内容</p><!--descript--> → 　内容
				line = gensub(/<p class="ltlbg_desciption"[^>]*data-p_header="([^"]*)"[^>]*>(.*)<\/p><!--descript-->/, "\\1\\2", "g", line)
				
				# 空行でなければ出力
				if (line != "") {
					print line
				}
			}
			AWK_EOF
		}


		destFile="${tgtFile/'.html'/'_stripped.txt'}" #出力ファイルの指定する
		printf '' > "${destFile}"


		: "変換実施" && {
			#AWKコードを実行（ヒアドキュメントで定義されたAWK_CODEを使用）
			gawk "$AWK_CODE" "${tgtFile}" > "${destFile}"
		}

		echo "✨ "${destFile}"を出力しました[txtもどし]"
	}

fi

exit 0
