# NUglify: minify JavaScript, CSS and HTML; a result object with Code and error list
load "pkg.ring"
pkgUse("nuglify",[["NUglify","1.21.9"]],[["NUglify.dll",["NUglify"]]])
pkgImport("nuglify","NUglify.dll","NUglify")

oJs = dnStatic("NUglify.Uglify","Js",["function add(first, second) { var total = first + second; return total; }"])
dnAssert("JavaScript has no errors",oJs.HasErrors,0)
dnAssert("JavaScript is shorter",len(oJs.Code) < 60,1)
dnAssert("names of locals are shortened",substr(oJs.Code,"total"),0)

oCss = dnStatic("NUglify.Uglify","Css",[".a {  color : red ;  margin : 0px ; }"])
dnAssert("CSS",oCss.Code,".a{color:#f00;margin:0}")

oHtml = dnStatic("NUglify.Uglify","Html",["<div>  <p>  hello  </p>  </div>"])
dnAssert("HTML",oHtml.Code,"<div><p>hello</div>")

oBad = dnStatic("NUglify.Uglify","Js",["function ( { "])
dnAssert("a broken script has errors",oBad.HasErrors,1)
dnAssert("and a list of them",len(oBad.Errors.toList()) > 0,1)

dnTestSummary()
