local LuaUnit = require('luaunit')
local assertEquals = LuaUnit.assertEquals

TestLibTextFilter = {}

function TestLibTextFilter:CreateTestCases(prefix, testCases, testFunction)
	for i = 1, #testCases do
		local test = testCases[i]
		self[string.format("test%s%s%d", prefix, i < 10 and "0" or "", i)] = function()
			testFunction(test.input, test.output)
		end
	end
end

local LTF = LibStub("LibTextFilter")

function TestLibTextFilter:setUp()
-- set up tests
end

do -- setup tokenizer tests
	local testCases = {
		-- one operator
		{input = "", output = {}},
		{input = " ", output = {}},
		{input = "+", output = {}},

		-- one operator, one term
		{input = "A", output = {" ", "A"}},
		{input = " A", output = {" ", "A"}},
		{input = "A ", output = {" ", "A"}},
		{input = "  A", output = {" ", "A"}},
		{input = " +A", output = {"+", "A"}},
		{input = "+ A", output = {" ", "A"}},
		{input = " + A", output = {" ", "A"}},
		{input = "+A", output = {"+", "A"}},
		{input = "-A", output = {" ", "-", "A"}},
		{input = "~A", output = {" ", "~", "A"}},

		-- two operators, one term
		{input = "+A+", output = {"+", "A"}},
		{input = "+A +", output = {"+", "A"}},
		{input = "+ A +", output = {" ", "A"}},
		{input = " + A + ", output = {" ", "A"}},

		-- 0-2 operator, two terms
		{input = "A B", output = {" ", "A", " ", "B"}},
		{input = "B A", output = {" ", "B", " ", "A"}},
		{input = "A -B", output = {" ", "A", " ", "-", "B"}},
		{input = "-B A", output = {" ", "-", "B", " ", "A"}},
		{input = "A +B", output = {" ", "A", "+", "B"}},
		{input = "A+B", output = {" ", "A", "+", "B"}},
		{input = "+A B", output = {"+", "A", " ", "B"}},
		{input = "+A +B", output = {"+", "A", "+", "B"}},
		{input = "+A+B", output = {"+", "A", "+", "B"}},
		{input = "+A -B", output = {"+", "A", " ", "-", "B"}},
		{input = "+A-B", output = {"+", "A", " ", "-", "B"}},
		{input = "+A +-B", output = {"+", "A", "+", "-", "B"}},

		-- 0-3 operators, 3 terms
		{input = "A B C", output = {" ", "A", " ", "B", " ", "C"}},
		{input = "  A  B  C  ", output = {" ", "A", " ", "B", " ", "C"}},
		{input = "-A B C", output = {" ", "-", "A", " ", "B", " ", "C"}},
		{input = "A +B -C", output = {" ", "A", "+", "B", " ", "-", "C"}},
		{input = "A -B+C", output = {" ", "A", " ", "-", "B", "+", "C"}},

		-- parentheses
		{input = "(A", output = {" ", "(", "A"}},
		{input = "((A", output = {" ", "(", "(", "A"}},
		{input = ")A", output = {" ", ")", "A"}},
		{input = "))A", output = {" ", ")", ")", "A"}},
		{input = "(A)", output = {" ", "(", "A", ")"}},
		{input = "((A))", output = {" ", "(", "(", "A", ")", ")"}},
		{input = "A (B+C)", output = {" ", "A", " ", "(", "B", "+", "C", ")"}},
		{input = "A -(B+C)", output = {" ", "A", " ", "-", "(", "B", "+", "C", ")"}},
		{input = "-(B+C) A", output = {" ", "-", "(", "B", "+", "C", ")", " ", "A"}},

		-- quotes
		{input = "\"A", output = {" ", "A"}},
		{input = "\"A\"", output = {" ", "A"}},
		{input = " \"A\" ", output = {" ", "A"}},
		{input = "\"A \"", output = {" ", "A "}},
		{input = "\" A \"", output = {" ", " A "}},
		{input = "\" A ", output = {" ", " A "}},
		{input = "\"\" A ", output = {" ", "A"}},
		{input = "\"A\"\"B\"", output = {" ", "A", " ", "B"}},
		{input = "\"A\" \"B\"", output = {" ", "A", " ", "B"}},
		{input = "A \"B+C\"", output = {" ", "A", " ", "B+C"}},

		-- complex
		{input = "\"A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A", output = {" ", "A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A+A"}},
		{input = "\"(A+B)\"", output = {" ", "(A+B)"}},
		{input = "\"(A+\" B)\"", output = {" ", "(A+", " ", "B", ")"}},
		{input = "\"(A+\"B)\"", output = {" ", "(A+", " ", "B", ")"}},
		{input = "\"(A+\"\"B)\"", output = {" ", "(A+", " ", "B)"}},
		{input = "\"(A+\" \"B)\"", output = {" ", "(A+", " ", "B)"}},
		{input = "some-item-name", output = {" ", "some-item-name"}},
		{input = "some~item~name", output = {" ", "some", " ", "~", "item", " ", "~", "name"}},
		{input = "\"some-item-name\"", output = {" ", "some-item-name"}},

		-- errors
	}

TestLibTextFilter:CreateTestCases("Tokenizer", testCases, function(input, expected)
	local actual = LTF:Tokenize(input)
	assertEquals(actual, expected)
end)
end

do -- setup parser tests
	local testCases = {
		{input = {" ", "A"}, output = {"A", " "}},
		{input = {" ", "-", "A"}, output = {"A", "-", " "}},
		{input = {" ", "(", "A"}, output = {"A", " "}},
		{input = {" ", "(", "A", ")"}, output = {"A", " "}},
		{input = {" ", "A", " ", "B"}, output = {"A", "B", " ", " "}},
		{input = {" ", "A", " ", "-", "B"}, output = {"A", "B", "-", " ", " "}},
		{input = {" ", "-", "B", " ", "A"}, output = {"B", "-", "A", " ", " "}},
		{input = {" ", "A", "+", "B"}, output = {"A", "B", "+", " "}},
		{input = {"+", "A", " ", "B"}, output = {"A", "+", "B", " "}},
		{input = {" ", "A", " ", "B", " ", "C"}, output = {"A", "B", "C", " ", " ", " "}},
		{input = {" ", "A", " ", "B", " ", "-", "C"}, output = {"A", "B", "C", "-", " ", " ", " "}},
		{input = {" ", "A", "+", "B", " ", "-", "C"}, output = {"A", "B", "+", "C", "-", " ", " "}},
		{input = {" ", "A", " ", "-", "B", "+", "C"}, output = {"A", "B", "-", "C", "+", " ", " "}},
		{input = {" ", "A", " ", "-", "(", "B", "+", "C", ")"}, output = {"A", "B", "C", "+", "-", " ", " "}},
		{input = {" ", "some", " ", "~", "item", " ", "~", "name"}, output = {"some", "item", "~", "name", "~", " ", " ", " "}},
		{input = {" ", "some-item-name"}, output = {"some-item-name", " "}},
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
		{input = {"A", {"A", " "}}, output = {true, LTF.RESULT_OK}},
		{input = {"B", {"A", " "}}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", {"A", "B", " ", " "}}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", {"A", "D", " ", " "}}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", {"A", "B", "+", " "}}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", {"A", "B", " ", "+"}}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", {"D", "E", "+", " "}}, output = {false, LTF.RESULT_OK}},
		{input = {"ABC", {"D", "E", " ", "+"}}, output = {false, LTF.RESULT_OK}},
		{input = {"A", {"A", "-", " "}}, output = {false, LTF.RESULT_OK}},
		{input = {"B", {"A", "-", " "}}, output = {true, LTF.RESULT_OK}},
		{input = {"ABC", {"A", "B", "C", "-", " ", " ", " "}}, output = {false, LTF.RESULT_OK}},
		{input = {"ABD", {"A", "B", "C", "-", " ", " ", " "}}, output = {true, LTF.RESULT_OK}},
		
		-- errors
		{input = {"ABC", {" ", ")-C"}}, output = {false, LTF.RESULT_INVALID_ARGUMENT_COUNT}},
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
	}

TestLibTextFilter:CreateTestCases("Filter", testCases, function(input, expected)
	local haystack, needle = unpack(input)
	local expectedValue, expectedResultCode = unpack(expected)

	local actual, resultCode = LTF:Filter(haystack, needle)

	assertEquals(resultCode, expectedResultCode)
	assertEquals(actual, expectedValue)
end)
end
