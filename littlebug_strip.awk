#!/usr/bin/awk -f

# littlebug_strip.awk
# littlebug.awkで生成されたHTMLファイルを元のテキスト形式に戻す逆変換スクリプト
# gawk拡張のmatch()第三引数を使用

# ルビタグを元の短縮タグに戻す関数
# <ruby class="ltlbg_ruby-*" data-*="ルビ">親文字<rt>ルビ</rt></ruby> → ｜親文字《ルビ》
function strip_ruby_tags(text) {
    new_text = ""
    # ルビタグパターンがなくなるまでループ
    while (match(text, /<ruby class="ltlbg_ruby-[^"]*" data-ltlbg_ruby-[^"]*="([^"]+)">([^<]+)<rt>[^<]+<\/rt><\/ruby>/, m)) {
        new_text = new_text substr(text, 1, RSTART - 1)
        ruby = m[1]
        parent = m[2]
        new_text = new_text "｜" parent "《" ruby "》"
        text = substr(text, RSTART + RLENGTH)
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
    
    # sectionタグを除去
    if (line ~ /^<section class="ltlbg_section">/ || line ~ /^<\/section>/) {
        next
    }
    
    # divタグを除去
    if (line ~ /^  <div class="ltlng_/ || line ~ /^  <\/div>/) {
        next
    }
    
    # セクション名タグを処理
    # <h2 class="ltlbg_section_name">§内容</h2> → §内容
    if (match(line, /<h2 class="ltlbg_section_name">([^<]+)<\/h2>/, m)) {
        line = m[1]
    }
    
    # 段落タグを処理
    # <p class="ltlbg_bracket" data-p_header="「" data-p_footer="」">内容</p><!--bracket--> → 「内容」
    if (match(line, /<p class="ltlbg_bracket" data-p_header="([^"]*)" data-p_footer="([^"]*)">([^<]*)<\/p><!--bracket-->/, m)) {
        line = m[1] m[3] m[2]
    }
    # 閉じ括弧のみのパターン（全角スペースが含まれる場合）
    if (match(line, /<p class="ltlbg_bracket"　data-p_footer="([^"]*)">([^<]*)<\/p><!--bracket-->/, m)) {
        line = m[2] m[1]
    }
    
    # 地の文タグを処理
    # <p class="ltlbg_desciption" data-p_header="〼">内容</p><!--descript--> → 　内容
    if (match(line, /<p class="ltlbg_desciption" data-p_header="〼">([^<]*)<\/p><!--descript-->/, m)) {
        line = "　" m[1]
    }
    
    # 先頭のスペースを除去（インデント）
    line = gensub(/^    /, "", "g", line)
    line = gensub(/^  /, "", "g", line)
    
    # ルビタグを元に戻す（内側のタグを先に処理）
    line = strip_ruby_tags(line)
    
    # 圏点タグを元に戻す（内側のタグを先に処理）
    line = strip_emphasis_tags(line)
    
    # 特殊記号のspanタグを除去
    # <span class="ltlbg_wdfix">内容</span> → 内容
    line = gensub(/<span class="ltlbg_wdfix">([^<]*)<\/span>/, "\\1", "g", line)
    
    # 全角スペースのspanタグを除去
    line = gensub(/<span class="ltlbg_wSp"><\/span>/, "　", "g", line)
    
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
    # <span class="ltlbg_forcedGouji1/2">内容</span> → [l[内容]r]
    line = gensub(/<span class="ltlbg_forcedGouji1\/2">([^<]*)<\/span>/, "[l[\\1]r]", "g", line)
    
    # セミコロンタグを元に戻す
    line = gensub(/<span class="ltlbg_semicolon">；<\/span>/, "；", "g", line)
    
    # コロンタグを元に戻す
    line = gensub(/<span class="ltlbg_colon">：<\/span>/, "：", "g", line)
    
    # スケベ濁音タグを元に戻す
    line = gensub(/<span class="ltlbg_dakuten"><\/span>/, "゛", "g", line)
    
    # キチガイ半濁音タグを元に戻す
    line = gensub(/<span class="ltlbg_handakuten"><\/span>/, "゜", "g", line)
    
    # 改ページタグを元に戻す
    line = gensub(/<br class="ltlbg_newpage">/, "[newpage]", "g", line)
    
    # 水平線タグを元に戻す
    line = gensub(/<span class="ltlbg_hr"><\/span>/, "---", "g", line)
    
    # 踊り字タグを元に戻す
    line = gensub(/<span class="ltlbg_odori1"><\/span><span class="ltlbg_odori2"><\/span>/, "／＼", "g", line)
    
    # HTML文字参照を元に戻す
    line = gensub(/&amp;/, "\\&", "g", line)
    line = gensub(/&lt;/, "<", "g", line)
    line = gensub(/&gt;/, ">", "g", line)
    line = gensub(/&#39;/, "'", "g", line)
    line = gensub(/&quot;/, "\"", "g", line)
    line = gensub(/&#047;/, "/", "g", line)
    line = gensub(/&#092;/, "\\\\", "g", line)
    
    # 空行でなければ出力
    if (line != "") {
        print line
    }
}
