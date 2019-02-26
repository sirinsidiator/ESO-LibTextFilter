local LuaUnit = require('luaunit')
local assertEquals = LuaUnit.assertEquals
local assertTrue = LuaUnit.assertTrue
local assertNotNil = LuaUnit.assertNotNil
local assertNil = LuaUnit.assertNil

TestLibTextFilter = {}

function TestLibTextFilter:CreateTestCases(prefix, testCases, testFunction)
	for i = 1, #testCases do
		local test = testCases[i]
		self[string.format("test%s%s%d", prefix, i < 10 and "0" or "", i)] = function()
			testFunction(test.input, test.output)
		end
	end
end

local LTF = LibTextFilter

function TestLibTextFilter:setUp()
	LTF:ClearCachedTokens()
end

do -- setup tokenizer tests
	local testCases = {
		-- one operator
		{input = "", output = {}},
		{input = " ", output = {}},
		{input = "+", output = {}},

		-- one operator, one term
		{input = "A", output = {"A"}},
		{input = " A", output = {" ", "A"}},
		{input = "A ", output = {"A"}},
		{input = "  A", output = {" ", "A"}},
		{input = " +A", output = {"A"}},
		{input = "+ A", output = {" ", "A"}},
		{input = " + A", output = {" ", "A"}},
		{input = "+A", output = {"A"}},
		{input = "-A", output = {"-", "A"}},
		{input = "~A", output = {"~", "A"}},

		-- two operators, one term
		{input = "+A+", output = {"A"}},
		{input = "+A +", output = {"A"}},
		{input = "+ A +", output = {" ", "A"}},
		{input = " + A + ", output = {" ", "A"}},

		-- 0-2 operator, two terms
		{input = "A B", output = {"A", " ", "B"}},
		{input = "B A", output = {"B", " ", "A"}},
		{input = "A -B", output = {"A", "-", "B"}},
		{input = "-B A", output = {"-", "B", " ", "A"}},
		{input = "A ~B", output = {"A", " ", "~", "B"}},
		{input = "~B A", output = {"~", "B", " ", "A"}},
		{input = "A +B", output = {"A", "+", "B"}},
		{input = "A+B", output = {"A", "+", "B"}},
		{input = "+A B", output = {"A", " ", "B"}},
		{input = "+A +B", output = {"A", "+", "B"}},
		{input = "+A+B", output = {"A", "+", "B"}},
		{input = "+A -B", output = {"A", "-", "B"}},
		{input = "+A-B", output = {"A-B"}},
		{input = "+A +-B", output = {"A", "-", "B"}},
		{input = "+A !B", output = {"A", " ", "!", "B"}},
		{input = "+A +!B", output = {"A", "+", "!", "B"}},

		-- 0-3 operators, 3 terms
		{input = "A B C", output = {"A", " ", "B", " ", "C"}},
		{input = "  A  B  C  ", output = {" ", "A", " ", "B", " ", "C"}},
		{input = "-A B C", output = {"-", "A", " ", "B", " ", "C"}},
		{input = "A +B -C", output = {"A", "+", "B", "-", "C"}},
		{input = "A -B+C", output = {"A", "-", "B", "+", "C"}},

		-- parentheses
		{input = "(A", output = {"(", "A"}},
		{input = "((A", output = {"(", "(", "A"}},
		{input = ")A", output = {")", "A"}},
		{input = "))A", output = {")", ")", "A"}},
		{input = "(A)", output = {"(", "A", ")"}},
		{input = "((A))", output = {"(", "(", "A", ")", ")"}},
		{input = "A (B+C)", output = {"A", " ", "(", "B", "+", "C", ")"}},
		{input = "A -(B+C)", output = {"A", "-", "(", "B", "+", "C", ")"}},
		{input = "-(B+C) A", output = {"-", "(", "B", "+", "C", ")", " ", "A"}},
		{input = "(A -B) +C", output = {"(", "A", "-", "B", ")", "+", "C"}},
		{input = "(-B A) +C", output = {"(", "!", "B", " ", "A", ")", "+", "C"}},
		{input = "(!B A) +C", output = {"(", "!", "B", " ", "A", ")", "+", "C"}},
		{input = "-A (+B+C)", output = {"-", "A", " ", "(", "B", "+", "C", ")"}},
		{input = "-A (+B +C)", output = {"-", "A", " ", "(", "B", "+", "C", ")"}},
		{input = "-A (+B-C)", output = {"-", "A", " ", "(", "B-C", ")"}},
		{input = "-A (+B -C)", output = {"-", "A", " ", "(", "B", "-", "C", ")"}},

		-- quotes
		{input = "\"A", output = {"A"}},
		{input = "\"A\"", output = {"A"}},
		{input = " \"A\" ", output = {" ", "A"}},
		{input = "\"A \"", output = {"A "}},
		{input = "\" A \"", output = {" A "}},
		{input = "\" A ", output = {" A "}},
		{input = "\"\" A ", output = {" ", "A"}},
		{input = "\"A\"\"B\"", output = {"A", " ", "B"}},
		{input = "\"A\" \"B\"", output = {"A", " ", "B"}},
		{input = "A \"B+C\"", output = {"A", " ", "B+C"}},
		{input = "-\"A\"", output = {"-", "A"}},

		-- complex
		{input = "\"A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A", output = {"A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A"}},
		{input = "\"(A+B)\"", output = {"(A+B)"}},
		{input = "\"(A+\" B)\"", output = {"(A+", " ", "B", ")"}},
		{input = "\"(A+\"B)\"", output = {"(A+", " ", "B", ")"}},
		{input = "\"(A+\"\"B)\"", output = {"(A+", " ", "B)"}},
		{input = "\"(A+\" \"B)\"", output = {"(A+", " ", "B)"}},
		{input = "some-item-name", output = {"some-item-name"}},
		{input = "some~item~name", output = {"some", " ", "~", "item", " ", "~", "name"}},
		{input = "\"some-item-name\"", output = {"some-item-name"}},

		-- itemlinks
		{input = "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", output = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}},
		{input = "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", output = {"~", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}},
		{input = "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h |H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", output = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", " ", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}},
	}

TestLibTextFilter:CreateTestCases("Tokenizer", testCases, function(input, expected)
	local actual = LTF:Tokenize(input)
	assertEquals(actual, expected)
end)
end

do -- setup parser tests
	local testCases = {
		{input = LTF:Tokenize("A"), output = {"A"}},
		{input = LTF:Tokenize("-A"), output = {"A", "-"}},
		{input = LTF:Tokenize("!A"), output = {"A", "!"}},
		{input = LTF:Tokenize("(A"), output = {"A"}},
		{input = LTF:Tokenize("(A)"), output = {"A"}},
		{input = LTF:Tokenize("A B"), output = {"A", "B", " "}},
		{input = LTF:Tokenize("A -B"), output = {"A", "B", "-"}},
		{input = LTF:Tokenize("A !B"), output = {"A", "B", "!", " "}},
		{input = LTF:Tokenize("-B A"), output = {"B", "-", "A", " "}},
		{input = LTF:Tokenize("!B A"), output = {"B", "!", "A", " "}},
		{input = LTF:Tokenize("A +B"), output = {"A", "B", "+"}},
		{input = LTF:Tokenize("+A +B"), output = {"A", "B", "+"}},
		{input = LTF:Tokenize("+A B"), output = {"A", "B", " "}},
		{input = LTF:Tokenize("A B C"), output = {"A", "B", " ", "C", " "}},
		{input = LTF:Tokenize("A +B +C"), output = {"A", "B", "+", "C", "+"}},
		{input = LTF:Tokenize("A B -C"), output = {"A", "B", "C", "-", " "}},
		{input = LTF:Tokenize("A +B -C"), output = {"A", "B", "+", "C", "-"}},
		{input = LTF:Tokenize("A -B +C"), output = {"A", "B", "-", "C", "+"}},
		{input = LTF:Tokenize("A -(B +C)"), output = {"A", "B", "C", "+", "-"}},
		{input = LTF:Tokenize("A +B +C D"), output = {"A", "B", "+", "C", "+", "D", " "}},
		{input = LTF:Tokenize("some~item~name"), output = {"some", "item", "~", "name", "~", " ", " "}},
		{input = LTF:Tokenize("some-item-name"), output = {"some-item-name"}},

		-- itemlinks
		{input = LTF:Tokenize("|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"), output = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}},
		{input = LTF:Tokenize("~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"), output = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~"}},
		{input = LTF:Tokenize("|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h |H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"), output = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", " "}},
	}

TestLibTextFilter:CreateTestCases("Parser", testCases, function(input, expected)
	local actual = LTF:Parse(input)
	for i = 1, #actual do
		if(actual[i].token) then actual[i] = actual[i].token end
	end
	assertEquals(actual, expected)
end)
end

do -- setup evaluation tests
	local testCases = {
		{input = {"A", LTF:Parse(LTF:Tokenize("A"))}, output = {true, LTF.RESULT_OK}},
		{input = {"A", LTF:Parse(LTF:Tokenize("-A"))}, output = {false, LTF.RESULT_OK}},
		{input = {"A", LTF:Parse(LTF:Tokenize("!A"))}, output = {false, LTF.RESULT_OK}},
		{input = {"B", LTF:Parse(LTF:Tokenize("A"))}, output = {false, LTF.RESULT_OK}},
		{input = {"B", LTF:Parse(LTF:Tokenize("-A"))}, output = {true, LTF.RESULT_OK}},
		{input = {"B", LTF:Parse(LTF:Tokenize("!A"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A B"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A -B"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("-A B"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A !B"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("!A B"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A D"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A +B"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("D +E"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A +E"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("E +A"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A B C"))}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A B C D"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("A B -C"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABD", LTF:Parse(LTF:Tokenize("A B -C"))}, output = {true, LTF.RESULT_OK}},

		-- itemlinks
		{input = {"ABC", LTF:Parse(LTF:Tokenize("|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"))}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", LTF:Parse(LTF:Tokenize("|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h |H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"))}, output = {false, LTF.RESULT_OK}},

		-- errors
		{input = {"ABD", LTF:Parse(LTF:Tokenize(")-C"))}, output = {false, LTF.RESULT_OK}},
	}

TestLibTextFilter:CreateTestCases("Evaluation", testCases, function(input, expected)
	local haystack, needle = unpack(input)
	for i = 1, #needle do needle[i] = LTF.OPERATORS[needle[i]] or needle[i] end
	local actual, resultCode = LTF:Evaluate(haystack, needle)

	local expectedValue, expectedResultCode = unpack(expected)
	assertEquals(resultCode, expectedResultCode)
	assertEquals(actual, expectedValue)
end)
end

do -- setup filter tests
	local testCases = {
		{input = {"camlorn sweet brown ale recipe", "ale"}, output = {true, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale"}, output = {false, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ale -brown"}, output = {false, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale -brown"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale -brown"}, output = {false, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale -brown"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ale brown"}, output = {true, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale brown"}, output = {false, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale brown"}, output = {false, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale brown"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ale -recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale -recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale -recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale -recipe"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ale recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale recipe"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ale +recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ale +recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ale +recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ale +recipe"}, output = {true, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "recipe"}, output = {true, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "tonal +vigilance"}, output = {false, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "tonal +vigilance"}, output = {true, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "tonal +vigilance"}, output = {true, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "tonal +vigilance"}, output = {false, LTF.RESULT_OK}},

		{input = {"camlorn sweet brown ale recipe", "ton"}, output = {false, LTF.RESULT_OK}},
		{input = {"stendarr's vigilance ginger ale recipe", "ton"}, output = {false, LTF.RESULT_OK}},
		{input = {"tonal architect tonic recipe", "ton"}, output = {true, LTF.RESULT_OK}},
		{input = {"rosy disposition tonic recipe", "ton"}, output = {true, LTF.RESULT_OK}},

		{input = {"motif 5: chapter 1: something", "chapter (1+2)"}, output = {true, LTF.RESULT_OK}},
		{input = {"motif 5: chapter 2: something", "chapter (1+2)"}, output = {true, LTF.RESULT_OK}},
		{input = {"motif 5: chapter 3: something", "chapter (1+2)"}, output = {false, LTF.RESULT_OK}},
		{input = {"motif 22: chapter 1: something", "chapter (1+\" 2:\")"}, output = {true, LTF.RESULT_OK}},
		{input = {"motif 22: chapter 2: something", "chapter (1+\" 2:\")"}, output = {true, LTF.RESULT_OK}},
		{input = {"motif 22: chapter 3: something", "chapter (1+\" 2:\")"}, output = {false, LTF.RESULT_OK}},

		{input = {"chevre-radish salad with pumpkin seeds recipe", "-(with+rabbit) recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"imperial stout recipe", "-(with+rabbit) recipe"}, output = {true, LTF.RESULT_OK}},
		{input = {"braised rabbit with spring vegetables recipe", "-(with+rabbit) recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"garlic cod with potato crust recipe", "-(with+rabbit) recipe"}, output = {false, LTF.RESULT_OK}},
		{input = {"imperial stout", "-(with+rabbit) recipe"}, output = {false, LTF.RESULT_OK}},

		{input = {"chevre-radish salad with pumpkin seeds recipe", "recipe -(with+rabbit)"}, output = {false, LTF.RESULT_OK}},
		{input = {"imperial stout recipe", "recipe -(with+rabbit)"}, output = {true, LTF.RESULT_OK}},
		{input = {"braised rabbit with spring vegetables recipe", "recipe -(with+rabbit)"}, output = {false, LTF.RESULT_OK}},
		{input = {"garlic cod with potato crust recipe", "recipe -(with+rabbit)"}, output = {false, LTF.RESULT_OK}},
		{input = {"imperial stout", "recipe -(with+rabbit)"}, output = {false, LTF.RESULT_OK}},

		{input = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "-|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:10:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:10:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H0:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H0:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "-|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|H0:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H0:item:64948:362:10:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|H0:item:64948:362:10:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"robe of the arch-mage |H0:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h arch mage", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"robe of the arch-mage |H0:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h arch mage", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},

		-- upper/lower case links
		{input = {"|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|h1:item:64948:362:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {false, LTF.RESULT_OK}},
		{input = {"|h1:item:64948:362:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|H1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},
		{input = {"|H1:item:64948:362:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", "~|h1:item:64948:362:50:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"}, output = {true, LTF.RESULT_OK}},

		-- problem case #1: partial matches
		{input = {"oko", "oko -okoma"}, output = {true, LTF.RESULT_OK}},
		{input = {"okoma", "oko -okoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"okori", "oko -okoma"}, output = {true, LTF.RESULT_OK}},
		{input = {"oko", "-okoma oko"}, output = {true, LTF.RESULT_OK}},
		{input = {"okoma", "-okoma oko"}, output = {false, LTF.RESULT_OK}},
		{input = {"okori", "-okoma oko"}, output = {true, LTF.RESULT_OK}},
		{input = {"oko", "-oko okoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"okoma", "-oko okoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"okori", "-oko okoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"oko", "okoma -oko"}, output = {false, LTF.RESULT_OK}},
		{input = {"okoma", "okoma -oko"}, output = {false, LTF.RESULT_OK}},
		{input = {"okori", "okoma -oko"}, output = {false, LTF.RESULT_OK}},

		--	 problem case #2a: order of terms
		{input = {"repora", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"rejera", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makkoma", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {false, LTF.RESULT_OK}},
		{input = {"meip", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makderi", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"taderi", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"rakeipa", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"kuta", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"rekuta", "repora +rejera +makko -makkoma +meip +makderi +taderi +rakeipa +kuta"}, output = {true, LTF.RESULT_OK}},

		-- problem case #2b: order of terms
		{input = {"rekuta", "+kuta +meip +makderi +repora -rekuta"}, output = {false, LTF.RESULT_OK}},
		{input = {"kuta", "kuta +meip +makderi +repora -rekuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"rekuta", "meip +makderi +repora +kuta -rekuta"}, output = {false, LTF.RESULT_OK}},
		{input = {"kuta", "meip +makderi +repora +kuta -rekuta"}, output = {true, LTF.RESULT_OK}},

		--		 problem case #2c: order of terms
		{input = {"makko", "+kuta +makko -makkoma"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "+kuta -makkoma +makko"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "+makko +kuta -makkoma"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "+makko -makkoma +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "-makkoma +makko +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makko", "-makkoma +kuta +makko"}, output = {true, LTF.RESULT_OK}},
		{input = {"makkoma", "+kuta +makko -makkoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"makkoma", "+kuta -makkoma makko"}, output = {false, LTF.RESULT_OK}},
		{input = {"makkoma", "+makko +kuta -makkoma"}, output = {false, LTF.RESULT_OK}},
		{input = {"makkoma", "+makko -makkoma +kuta"}, output = {false, LTF.RESULT_OK}},
		{input = {"makkoma", "-makkoma +makko +kuta"}, output = {true, LTF.RESULT_OK}},
		{input = {"makkoma", "-makkoma +kuta +makko"}, output = {true, LTF.RESULT_OK}},

		-- problem case #3: whitespace only
		{input = {"Oko", " "}, output = {false, LTF.RESULT_INVALID_INPUT}},
	}

TestLibTextFilter:CreateTestCases("Filter", testCases, function(input, expected)
	local haystack, needle = unpack(input)
	local expectedValue, expectedResultCode = unpack(expected)

	local actual, resultCode = LTF:Filter(haystack, needle)

	assertEquals(resultCode, expectedResultCode)
	assertEquals(actual, expectedValue)
end)
end

function TestLibTextFilter:TestTokenCache()
	local needle = "test +test"
	assertNil(LTF.cache[needle])
	local value1, result1 = LTF:Filter("test", needle)
	assertNotNil(LTF.cache[needle])
	assertEquals(#LTF.cache[needle], 3)
	local value2, result2 = LTF:Filter("test", needle)
	assertEquals(#LTF.cache[needle], 3)
	assertNotNil(LTF.cache[needle])
	assertEquals(result1, LTF.RESULT_OK)
	assertEquals(result2, LTF.RESULT_OK)
	assertTrue(value1)
	assertTrue(value2)
end