# Ring in 15 minutes, part 1: values, text, numbers and comparisons (no .NET here: plain Ring)

# 1. A variable needs no declaration and no type; the type belongs to the value. "?" prints a line.
nCount = 3                    # a number
cName = "Ring"                # a text
lReady = True                 # a yes/no value: True is 1, False is 0
? nCount
? cName
? lReady
? type(nCount) + " " + type(cName) + " " + type(lReady)

# 2. All numbers are doubles. Whole numbers print without decimals, others with at most a few.
? 7 / 2
? 7 % 2                       # the remainder
? floor(7 / 2)                # the whole part
? 2 ** 10                    # power ("^" is a bit operation in Ring)
? 0.1 + 0.2 = 0.3             # 0 (false): binary fractions are inexact

# 3. Text: "+" joins texts. The LEFT side decides: a text on the left joins ("Count: " + 3 is "Count: 3"),
#    a number on the left adds, and then the text must look like a number.
cLine = "Count: " + nCount
? cLine
? "3" + 4                     # joins: 34
? 5 + "5"                     # adds: 10
try
	? nCount + " items"       # a number on the left: " items" is not a number
catch
	? "error: " + cCatchError
done
? string(nCount) + " items"   # string() makes the number a text first

# 4. Text is a list of bytes: indexes start at 1, len() counts bytes
cWord = "Hello, Ring!"
? len(cWord)
? cWord[1]                    # the first letter
? left(cWord,5) + "|" + right(cWord,5)
? substr(cWord,8,4)           # 4 letters from position 8
? upper(cWord) + " " + lower(cWord)
? substr(cWord,"Ring")        # the position of a text inside a text (0: not found)
? substr(cWord,"Ring","World")    # replace
? trim("   padded   ") + "|"

# 5. "=" compares as well as assigns (the context decides); "!=" is different; and / or / not combine tests
? 3 = 3
? "abc" = "ABC"               # texts are compared by bytes
? 3 != 4
? (3 > 2) and (not (1 > 2))
? nl + "the end"              # nl is a new line
