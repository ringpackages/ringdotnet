# CommonMark.NET: the reference Markdown converter (a static class with Convert), and the CommonMark syntax tree
load "pkg.ring"
pkgUse("commonmark",[["CommonMark.NET","0.15.1"]],[["CommonMark.dll",["CommonMark"]]])
pkgImport("commonmark","CommonMark.dll","CommonMark")

dnAssert("a heading",left(dnStatic("CommonMark.CommonMarkConverter","Convert",["# Hi"]),11),"<h1>Hi</h1>")
dnAssert("emphasis",left(dnStatic("CommonMark.CommonMarkConverter","Convert",["a *b* **c**"]),38),"<p>a <em>b</em> <strong>c</strong></p>")
dnAssert("a list",substr(dnStatic("CommonMark.CommonMarkConverter","Convert",["- one" + nl + "- two"]),"<li>one</li>") > 0,1)
dnAssert("a code span",substr(dnStatic("CommonMark.CommonMarkConverter","Convert",["use `x`"]),"<code>x</code>") > 0,1)
dnAssert("markup in the text is escaped",substr(dnStatic("CommonMark.CommonMarkConverter","Convert",["1 < 2 & 3"]),"1 &lt; 2 &amp; 3") > 0,1)
dnAssert("Arabic text",substr(dnStatic("CommonMark.CommonMarkConverter","Convert",["# مرحبا"]),"<h1>مرحبا</h1>") > 0,1)

dnTestSummary()
