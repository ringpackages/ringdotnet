# DotNetEnv: .env files (KEY=value lines, comments, quotes, export, variables inside values) loaded into the environment and read with typed getters
load "pkg.ring"
pkgUse("dotnetenv",[["DotNetEnv","3.2.0"]],[["DotNetEnv.dll",["DotNetEnv"]]])
pkgImport("dotnetenv","DotNetEnv.dll","DotNetEnv")

oEnv = new Env()
cText = "# a comment" + nl + "RING_TEST_NAME=RingDotNet" + nl + "RING_TEST_PORT=8080" + nl + "RING_TEST_DEBUG=true" + nl + "RING_TEST_RATIO=0.25" + nl + 'RING_TEST_QUOTED="two words"' + nl + "export RING_TEST_EXPORTED=yes" + nl + 'RING_TEST_GREETING="hello ${RING_TEST_NAME}"' + nl
oEnv.LoadContents([ :contents = cText ])

dnAssert("a text value",oEnv.GetString([ :key = "RING_TEST_NAME" ]),"RingDotNet")
dnAssert("a number",oEnv.GetInt([ :key = "RING_TEST_PORT" ]),8080)
dnAssert("a boolean",oEnv.GetBool([ :key = "RING_TEST_DEBUG" ]),1)
dnAssert("a decimal number",oEnv.GetDouble([ :key = "RING_TEST_RATIO" ]),0.25)
dnAssert("a quoted value keeps its space",oEnv.GetString([ :key = "RING_TEST_QUOTED" ]),"two words")
dnAssert("an export line",oEnv.GetString([ :key = "RING_TEST_EXPORTED" ]),"yes")
dnAssert("a variable inside a value",oEnv.GetString([ :key = "RING_TEST_GREETING" ]),"hello RingDotNet")
dnAssert("a missing key gives the fallback",oEnv.GetString([ :key = "RING_TEST_MISSING", :fallback = "none" ]),"none")
dnAssert("a missing number gives the fallback",oEnv.GetInt([ :key = "RING_TEST_MISSING", :fallback = 7 ]),7)

# the values are in the environment of the process: .NET's Environment sees them
dnAssert("the environment has the value",new Environment().GetEnvironmentVariable("RING_TEST_NAME"),"RingDotNet")

dnTestSummary()
