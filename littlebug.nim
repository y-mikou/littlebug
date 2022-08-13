import strutils,nre
var tgtFile : File = open("sample/test.txt" ,FileMode.fmRead)
var tmpText : string = tgtFile.readAll
close(tgtFile)

tmpText = tmpText.replace(re"(*UTF8)(?s)　","〼")
tmpText = tmpText.replace(re"(*UTF8)(?s) ","〿")
tmpText = tmpText.replace(re"(*UTF8)(?s)[&＆]","＆ａｍｐ")
tmpText = tmpText.replace(re"(*UTF8)(?s)[<＜]","＆ｌｔ")
tmpText = tmpText.replace(re"(*UTF8)(?s)[>＞]","＆ｇｔ")
tmpText = tmpText.replace(re"(*UTF8)(?s)[""”]","＆＃３９")
tmpText = tmpText.replace(re"(*UTF8)(?s)['’]","＆ｑｕｏｔ")
tmpText = tmpText.replace(re"(*UTF8)(?s)/","＆＃０４")
tmpText = tmpText.replace(re"(*UTF8)(?s)[:：]","<span class=\"ltlbg_colon\">：</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)[;；]","<span class=\"ltlbg_semicolon\">；</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)^[〿〼]*\n/","<br class=\"ltlbg_blankline\">")
tmpText = tmpText.replace(re"(*UTF8)(?s)\n","<br class=\"ltlbg_br\">")
tmpText = tmpText.replace(re"(*UTF8)(?s)([！？♥♪☆!?]〼*)(\w)","$1〼$2")



tmpText = tmpText.replace(re"(*UTF8)(?s)([^a-zA-Z0-9_<>])([a-zA-Z0-9]{2})([^a-zA-Z0-9_<>])","$1<span class=\"ltlbg_tcyA\">$2</span>$3")

tmpText = tmpText.replace(re"(*UTF8)(?s)([^a-zA-Z0-9_<>])([a-zA-Z0-9]{2})([^a-zA-Z0-9_<>])","$1<span class=\"ltlbg_tcyA\">$2</span>$3")
tmpText = tmpText.replace(re"(*UTF8)(?s)([！!]{2})","<span class=\"ltlbg_tcyA\">!!</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)([？?]{2})","<span class=\"ltlbg_tcyA\">??</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)([！!][？?])","<span class=\"ltlbg_tcyA\">!?</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)([？?][！!])","<span class=\"ltlbg_tcyA\">?!</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)(―{1,2})","<span class=\"ltlbg_wSize\">―</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)(／＼|〱)","<span class=\"ltlbg_odori1\"></span><span class=\"ltlbg_odori2\"></span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)\^(.{2,3})\^","<span class=\"ltlbg_tcyM\">$1</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)\[\^(.)\^\]","<span class=\"ltlbg_rotate\">$1</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)\[-([^-])-\]","<span class=\"ltlbg_wdfix\">$1</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)\[l\[(.)(.)\]r\]","<span class=\"ltlbg_forceGouji1\">$1</span><span class=\"ltlbg_forceGouji2\">$2</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)゛","<span class=\"ltlbg_dakuten\"></span>")


tmpText = tmpText.replace(re"(*UTF8)(?s)《《([^》]+)》》","<span class=\"ltlbg_emphasis\">$1</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s)\*\*([^\*]+)\*\*","<span class=\"ltlbg_bold\">$1</span>")
tmpText = tmpText.replace(re"(*UTF8)(?s){([^｜]+)｜([^}]+)","｜$1《$2》")
tmpText = tmpText.replace(re"(*UTF8)(?s)｜([^《]+)《([^》]+)》","<ruby>$1<rt>$2</rt></ruby>")

tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<!--<link rel=\"stylesheet\" href=\"../littlebugRL.css\">-->\n")
tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<link rel=\"stylesheet\" href=\"../littlebugTD.css\">\n")
tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<link rel=\"stylesheet\" href=\"../littlebugU.css\">\n")
tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<link href=\"https://fonts.googleapis.com/css2?family=Noto+Serif+JP:wght@300&display=swap\" rel=\"stylesheet\">\n")
tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n")
tmpText = tmpText.replace(re"(*UTF8)(?s)^", "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n")

tmpText = tmpText.replace(re"""(*UTF8)(?s)<br class="ltlbg_br">""", "<br class=\"ltlbg_br\">\n")

var outFile : File = open("sample/test_ltlbg.html" ,FileMode.fmReadWrite)
outFile.write tmpText
