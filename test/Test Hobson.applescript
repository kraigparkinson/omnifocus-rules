use AppleScript version "2.4"
use scripting additions

(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)

use textutil : script "com.kraigparkinson/ASText"
use dateutil : script "com.kraigparkinson/ASDate"
use collections : script "com.kraigparkinson/ASCollections"
use domain : script "com.kraigparkinson/OmniFocusDomain"
use rules : script "com.kraigparkinson/Hobson"

property parent : script "com.lifepillar/ASUnit"

property suite : makeTestSuite("Hobson")

my autorun(suite)


(*
script |RuleRepository|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown
	
	script MockRuleService
		property parent : RuleService
		
	end script
	
	script RuleRepository
		on findAll()
		end findAll				
	end script
	
	script FileBasedRuleRepository
		property parent : RuleRepository

		on findAll()
		end findAll			
	end script
	
	script MockRuleRepository
		property parent : RuleRepository

		on findAll()
			return { }
		end findAll			
	end script

	script |Repository returns list of rules|
		property parent : UnitTest(me)

		set ruleRepo to container's resolve("Rule")
		
		RuleRepository's ruleService to MockRuleService
		
	end script
	
	
end script
*)
script |OmniFocus Document Fixture|
	property parent : makeFixture()
	
	property documentFixture : missing value
	property taskFixtures_list : missing value
	
	on setUp()
		set taskFixtures_list to { }

		tell application "OmniFocus"
			set document_list to documents whose name is "Test"
			set documentFixture to first item of document_list			
		end tell

		tell domain 
			set aRegistry to getRegistryInstance()
			tell aRegistry to registerDocumentInstance(documentFixture)
		end tell
	end setUp
	
	on tearDown()
		repeat with aTask in taskFixtures_list
			tell application "OmniFocus"
				delete aTask
			end tell
		end repeat
	end tearDown
	
	on createTask(name_text)
		local aTask
		tell application "OmniFocus"
			tell documentFixture
				set aTask to (make new inbox task with properties {name:name_text})
			end tell
		end tell
		
		set end of taskFixtures_list to aTask
		
		return aTask		
	end create
end script --OmniFocus Document Fixture

script MockTarget
	property parent : rules's makeOmniFocusRuleTarget()

	on defineName()
		return "Mock Target"
	end defineName
	
	on locateTasks()
		return my tasks
	end locateTasks
end script

script |FileRuleLoader|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown
	
	on createRuleScriptFixture()
		--Set up the test rule
		script TestRule
			property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("FileRuleLoaderRule")
			
			on prettyName()
				return "TestRule"
			end prettyName
			
			on matchTask(aTask, inputAttributes)
				aTest's refuteMissing(aTask) 
				return true
			end matchTask
	
			on processTask(aTask, inputAttributes)
				aTest's refuteMissing(aTask) 
				return missing value
			end processTask		
			
			on run()
			end run	
		end script
		
		--Set up the top-level script object 
		 
		script TestRuleScript
			property parent : Rules
			property suite : Rules's makeRuleSuite("Test Rule Suite")					
		end script		
		
		script TestRuleSet
			property parent : rules's makeRuleSet()
			property name : "Test Rule Set"
			property target : MockTarget
	
			evaluate by TestRule
		end script
		
		tell TestRuleScript's suite to addRuleSet(TestRuleSet)
		
		return TestRuleScript
	end createRuleScriptFixture

	script |validates a legit script|
		property parent : UnitTest(me)
		
		set aScript to createRuleScriptFixture()
			
		assert(rules's _makeRuleLoader()'s isSatisfiedBy(aScript), "Should be considered valid.")		
	end script
	
	script |loads rules from valid script|
		property parent : UnitTest(me)
		
		set aScript to createRuleScriptFixture()
		set aSuite to rules's _makeRuleLoader()'s loadRulesFromScript(aScript)
		
		refuteMissing(aSuite, "Should have loaded the suite.")
		assertEqual("Test Rule Suite", aSuite's name)
		assertEqual(1, count of aSuite's ruleSets)
	end script
(*	
	script |loads rules from existing file|
		property parent : UnitTest(me)
		
		set rulesPath to POSIX path of ((path to home folder from user domain) as text)
		set rulesPath to rulesPath & "Repositories/omnifocus-rules/build/Rule Sets/"
		set rulesPath to rulesPath & "omnirulefile.scptd"
		
		set aFile to rulesPath
		
		set aSuite to rules's _makeRuleLoader()'s loadRulesFromFile(aFile)
		refuteMissing(aSuite, "Should have loaded the suite")
		assertEqual("Creating Flow with OmniFocus", aSuite's name)
		
		assertEqual(2, count of aSuite's ruleSets)		
	end script
*)
	script |throws file missing error from non-existing file|
		property parent : UnitTest(me)
		
		set rulesPath to POSIX path of ((path to home folder from user domain) as text)
		set rulesPath to rulesPath & "Repositories/omnifocus-rules/build/Rule Sets/"
		set rulesPath to rulesPath & "missingsuite.scptd"
		
		try
			set aSuite to rules's _makeRuleLoader()'s loadRulesFromFile(rulesPath)
			fail()
		on error message
--			ok(message ends with "does not have a suite property")
		end try
	end script

end script --FileRuleLoader

script |TextSpecification|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown

	script |Should find same text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's SpecificationFactory's makeSameAsTextSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should be the same")
		refute(rules's SpecificationFactory's makeSameAsTextSpecification("not a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
	end script

	script |Should find starts with text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's SpecificationFactory's makeStartsWithTextSpecification("a", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should start with letter")
		assert(rules's SpecificationFactory's makeStartsWithTextSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should start with whole phrase")
		refute(rules's SpecificationFactory's makeStartsWithTextSpecification("matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not start with end of phrase")
	end script

	script |Should find ends with text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's SpecificationFactory's makeEndsWithTextSpecification("k", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with last letter")
		assert(rules's SpecificationFactory's makeEndsWithTextSpecification("task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with last word")
		assert(rules's SpecificationFactory's makeEndsWithTextSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with whole phrase")
		refute(rules's SpecificationFactory's makeEndsWithTextSpecification("a matching", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not end with start of phrase")
	end script

	script |Should find contained text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's SpecificationFactory's makeContainsTextSpecification("k", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain last letter")
		assert(rules's SpecificationFactory's makeContainsTextSpecification("task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain last word")
		assert(rules's SpecificationFactory's makeContainsTextSpecification("matching", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain middle word")
		assert(rules's SpecificationFactory's makeContainsTextSpecification("a", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain first word")
		assert(rules's SpecificationFactory's makeContainsTextSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain whole phrase")
		refute(rules's SpecificationFactory's makeContainsTextSpecification(" a matching task ", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
		refute(rules's SpecificationFactory's makeContainsTextSpecification("other", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
	end script
end script --TextSpecification

script |DateSpecification|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown

	script |Should find same date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		assert(rules's SpecificationFactory's makeSameAsDateSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be the same")
		refute(rules's SpecificationFactory's makeSameAsDateSpecification(date "2015-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be the same")
	end script

	script |Should find before date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		refute(rules's SpecificationFactory's makeIsBeforeDateSpecification(date "2016-01-01", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be before")
		refute(rules's SpecificationFactory's makeIsBeforeDateSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be before same date")
		assert(rules's SpecificationFactory's makeIsBeforeDateSpecification(date "2016-01-03", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be before next date")
	end script

	script |Should find after date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		assert(rules's SpecificationFactory's makeIsAfterDateSpecification(date "2016-01-01", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be after")
		refute(rules's SpecificationFactory's makeIsAfterDateSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be after same date")
		refute(rules's SpecificationFactory's makeIsAfterDateSpecification(date "2016-01-03", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be after next date")
	end script

	script |Should find dates in the next range|
		property parent : UnitTest(me)
		
		local actual
		set actual to (dateutil's CalendarDateFactory's today at "12:00:00AM")

		assert(rules's SpecificationFactory's makeInTheNextIntervalDateSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual's asDate()), "Date should be in the next day")
		assert(rules's SpecificationFactory's makeInTheNextIntervalDateSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy(((actual's increment by 7)'s asDate()) - 1), "Date should be in the next week")
		refute(rules's SpecificationFactory's makeInTheNextIntervalDateSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by 2)'s asDate()), "Date should not be in the next day")
		refute(rules's SpecificationFactory's makeInTheNextIntervalDateSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by 7)'s asDate()), "Date should not be in the next week")
	end script

	script |Should find dates in the last range|
		property parent : UnitTest(me)
		
		local actual
		set actual to dateutil's CalendarDateFactory's today at "12:00:00AM"

		assert(rules's SpecificationFactory's makeInTheLastIntervalDateSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual's asDate()), "Date should be in the next day")
		assert(rules's SpecificationFactory's makeInTheLastIntervalDateSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy(((actual's increment by -7)'s asDate()) + 1), "Date should be in the last week")
		refute(rules's SpecificationFactory's makeInTheLastIntervalDateSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by -2)'s asDate()), "Date should not be in the last day")
		refute(rules's SpecificationFactory's makeInTheLastIntervalDateSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by -7)'s asDate()), "Date should not be in the last week")
	end script

	script |Should find missing dates|
		property parent : UnitTest(me)
		
		assert(rules's SpecificationFactory's makeMissingDateSpecification(rules's ValueRetrievalStrategy)'s isSatisfiedBy(missing value), "Date should be missing")
		refute(rules's SpecificationFactory's makeMissingDateSpecification(rules's ValueRetrievalStrategy)'s isSatisfiedBy(current date), "Date should not be missing value")
	end script


end script --DateSpecification

script |TextSpecificationBuilder|
	property parent : TestSet(me)
	
	property builder : missing value
	
	on setUp()
		set builder to rules's makeTextSpecificationBuilder(rules's ValueRetrievalStrategy)
	end setUp
	
	on tearDown()
	end tearDown

	script |Should find same text|
		property parent : UnitTest(me)
		
		assert(builder's sameAs("a matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should be the same (sameAs)")
		tell builder to reset()
		refute(builder's sameAs("not a matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not be the same (sameAs)")
		tell builder to reset()
		refute(builder's notSameAs("a matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should be the same (notSameAs)")
		tell builder to reset()
		assert(builder's notSameAs("not a matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not be the same (notSameAs)")
		tell builder to reset()
	end script
	
	script |Should find text starts with|
		property parent : UnitTest(me)
		
		assert(builder's startsWith("a matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's startsWith("matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's startsWith("matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's doesNotStartWith("a matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should start with (doesNotStartWith)")
		tell builder to reset()
		assert(builder's doesNotStartWith("matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not start with (doesNotStartWith)")
		tell builder to reset()
	end script

	script |Should find text ends with|
		property parent : UnitTest(me)
		
		assert(builder's endsWith("matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's endsWith("a matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesNotEndWith("matching task")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should end with (doesNotEndWith)")
		tell builder to reset()
		assert(builder's doesNotEndWith("a matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (doesNotEndWith)")
		tell builder to reset()
	end script

	script |Should find text contains|
		property parent : UnitTest(me)
		
		assert(builder's doesContain("matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesContain("another")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesNotContain("matching")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should end with (doesNotEndWith)")
		tell builder to reset()
		assert(builder's doesNotContain("another")'s getContents()'s isSatisfiedBy("a matching task"), "Task name should not end with (doesNotEndWith)")
		tell builder to reset()
	end script
	
	script |Should find text matches|
		property parent : UnitTest(me)
		
		assert(builder's match()'s l("a")'s anyText()'s getContents()'s isSatisfiedBy("a matching task"), "Task name should start with 'a'")
	end script
	
	script |Should find text that does not match|
		property parent : UnitTest(me)
		
		assert(builder's doesNotMatch()'s l("a matching task")'s getContents()'s isSatisfiedBy("da matching task"), "Task name should not match")
	end script
end script --TextSpecificationBuilder

script |TextMatchPatternConditionBuilder|
	property parent : TestSet(me)
	property builderFixture : missing value
	property inputAttributes : missing value
	
	on setUp()		
		set inputAttributes to collections's makeMap()
		set builderFixture to rules's makeTextMatchPatternConditionBuilder(inputAttributes, missing value, rules's ValueRetrievalStrategy, true, rules's ItemGroupingPolicy)
	end setUp
	
	on tearDown()
	end tearDown
	
	script |Should find text that's only a letter|
		property parent : UnitTest(me)
				
		set aSpec to builderFixture's aLetter()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("a"), "Should match with single letter (a).")
		assert(aSpec's isSatisfiedBy("A"), "Should match with single letter (A).")
		assert(aSpec's isSatisfiedBy("b"), "Should match with single letter (b).")
		refute(aSpec's isSatisfiedBy("2"), "Should not match a digit")
		refute(aSpec's isSatisfiedBy("23"), "Should not match a number")
		refute(aSpec's isSatisfiedBy("bb"), "Should not match multiple letters.")
	end script

	script |Should find text that's a whole word|
		property parent : UnitTest(me)
				
		set aSpec to builderFixture's aWord()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("alphabet"), "Should match with a word.")
		assert(aSpec's isSatisfiedBy("a"), "Should match with single letter.")
		refute(aSpec's isSatisfiedBy("2"), "Should match with a single digit")
		refute(aSpec's isSatisfiedBy("34"), "Should not match a number")
		assert(aSpec's isSatisfiedBy("bb"), "Should match multiple letters, even if they aren't a word.")
	end script

	script |Should find text that's only a digit|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's aDigit()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match with single number (1).")
		assert(aSpec's isSatisfiedBy("2"), "Should match with single number (2).")
		refute(aSpec's isSatisfiedBy("b"), "Should not match with single letter (b).")
		refute(aSpec's isSatisfiedBy("22"), "Should not match multiple numbers.")
	end script

	script |Should find text that's either a letter or a digit|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's letterOrDigit()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match with single digit (1).")
		assert(aSpec's isSatisfiedBy("a"), "Should match with single letter (a).")
		refute(aSpec's isSatisfiedBy("ab"), "Should not match multiple letters.")
		refute(aSpec's isSatisfiedBy("22"), "Should not match multiple digits.")
	end script

	script |Should find text that's a combo of letters and digits|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's lettersAndDigits()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match with single digit (1).")
		assert(aSpec's isSatisfiedBy("a"), "Should match with single letter (a).")
		assert(aSpec's isSatisfiedBy("ab"), "Should not match multiple letters.")
		assert(aSpec's isSatisfiedBy("22"), "Should not match multiple digits.")
		assert(aSpec's isSatisfiedBy("a2"), "Should not match a letter and digit combo.")
		assert(aSpec's isSatisfiedBy("1b"), "Should not match a digit and letter combo.")
	end script

	script |Should find text that's a number|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's aNumber()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match with single number (1).")
		assert(aSpec's isSatisfiedBy("22"), "Should match with multi-digit number (22).")
		refute(aSpec's isSatisfiedBy("b"), "Should not match with single letter (b).")
	end script

	script |Should find text that's only a single symbol|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's aSymbol()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("?"), "Should match with single symbol (?).")
		assert(aSpec's isSatisfiedBy("|"), "Should match with single number (|).")
		refute(aSpec's isSatisfiedBy("b"), "Should not match with single letter (b).")
		refute(aSpec's isSatisfiedBy("1"), "Should not match with single digit (1).")
		refute(aSpec's isSatisfiedBy("??"), "Should not match multiple symbols.")
	end script

	script |Should find text that's a set of symbols|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's symbols()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("?"), "Should match with single symbol (?).")
		assert(aSpec's isSatisfiedBy("--"), "Should match with multiple symbols (--).")
	end script
	
	script |Should find literal text|
		property parent : UnitTest(me)
				
		set aSpec to builderFixture's l("[|]EN[|]")'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		refute(aSpec's isSatisfiedBy("alphabet"), "Should not match with a word.")
		assert(aSpec's isSatisfiedBy("|EN|"), "Should match with text provided.")
		refute(aSpec's isSatisfiedBy("|EN|EN|"), "Should not match even if text is present")
		refute(aSpec's isSatisfiedBy("|EN||EN|"), "Should not match when text is present twice")
	end script

	script |Should find anything|
		property parent : UnitTest(me)
				
		set aSpec to builderFixture's anyText()'s getContents()
		assert(aSpec's isSatisfiedBy(""), "Should match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match digit.")
		assert(aSpec's isSatisfiedBy("a"), "Should match letter.")
		assert(aSpec's isSatisfiedBy("?"), "Should match symbox.")
		assert(aSpec's isSatisfiedBy("alphabet"), "Should match with a word.")
		assert(aSpec's isSatisfiedBy("|EN|"), "Should match with text with special characters.")
		assert(aSpec's isSatisfiedBy("123abc"), "Should match letters and digits")
		assert(aSpec's isSatisfiedBy("123"), "Should not match numbers")
		assert(aSpec's isSatisfiedBy("abc"), "Should not match a word")
	end script
	
	script |Should find custom text pattern|
		property parent : UnitTest(me)
				
		set t to rules's makeCustomTextBuilder(inputAttributes, "source token", rules's ValueRetrievalStrategy, true)
		set aSpec to builderFixture's customText(¬
			t's l("[|]")'s anyText()'s l("[|]")¬
				)'s getContents()
		
		-- NOTE: Below is the one I want to see in practice.
		-- match by (taskname()'s match()'s customText(token("source token")'s l("[|]")'s anyText()'s l("[|]")))
		assert(aSpec's isSatisfiedBy("|EN|"), "Should match the token.")
		assert(inputAttributes's containsValue("source token"), "Should contain a value for 'source token'")
		assertEqual("|EN|", inputAttributes's getValue("source token"))
	end script

	(*
	script |Should find custom date pattern|
		property parent : UnitTest(me)
				
		set t to rules's makeCustomDateBuilder(inputAttributes, "start date", rules's ValueRetrievalStrategy, true)
		set aSpec to builderFixture's customDate(¬
			t's aYear("yyyy")'s l("-")'s aMonth("mm")'s l("-")'s aDay("dd")'s l("T")'s anHour("hh")'s l(":")'s aMinute("mm")'s l(":")'s aSecond("ss"))'s getContents()
		
		-- NOTE: Below is the one I want to see in practice.
		-- match by (taskname()'s match()'s customText(token("source token")'s l("[|]")'s anyText()'s l("[|]")))
		assert(aSpec's isSatisfiedBy("2016-05-12T13:02:12"), "Should match the token.")
		assert(inputAttributes's containsValue("start date"), "Should contain a value for 'start date'")
		set expectedDate to date "2016-05-12"
		set expectedDate to date "1:02:12pm" of expectedDate
		assertEqual(expectedDate, inputAttributes's getValue("start date"))
	end script
	*)
	
	script |Should find custom 'short date' pattern|
		property parent : UnitTest(me)
			
		set t to rules's makeCustomDateBuilder(inputAttributes, "start date", rules's ValueRetrievalStrategy, true)
		set aSpec to builderFixture's customDate(¬
			t's aShortDate())'s getContents()
	
		-- NOTE: Below is the one I want to see in practice.
		-- match by (taskname()'s match()'s customText(token("source token")'s l("[|]")'s anyText()'s l("[|]")))
		assert(aSpec's isSatisfiedBy("2016-05-12"), "Should match the token.")
		assert(inputAttributes's containsValue("start date"), "Should contain a value for 'start date'")
		set expectedDate to date "2016-05-12"
--		set expectedDate to date "1:02:12pm" of expectedDate
		assertEqual(expectedDate, inputAttributes's getValue("start date"))
			
	end script

	
	script |Should find compound patterns|
		property parent : UnitTest(me)
		
		set aSpec to builderFixture's aDigit()'s aLetter()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1a"), "Should match number and letter.")
		refute(aSpec's isSatisfiedBy("a1"), "Should not match letter and number.")
		refute(aSpec's isSatisfiedBy("22"), "Should not match multiple numbers.")

		--Need to reset builder as we're reusing the instance.
		set builderFixture's builders to { }
		set builderFixture's regex to ""
		set aSpec to builderFixture's aSymbol()'s aWord()'s aSymbol()'s anyText()'s getContents()
		assert(aSpec's isSatisfiedBy("|EN| A task!"), "Should match a pattern as expected when provided by pattern.")
		refute(aSpec's isSatisfiedBy("--|EN| A task!"), "Should not match the pattern with extra characters in front.")
		assert(aSpec's isSatisfiedBy("|GC|"), "Should not match initial symbol-word-symbol combo without additional text.")

		--Need to reset builder as we're reusing the instance.
		set builderFixture's builders to { }
		set builderFixture's regex to ""
		set aSpec to builderFixture's l("[|]EN[|]")'s anyText()'s getContents()
		assert(aSpec's isSatisfiedBy("|EN| A task!"), "Should match a pattern as expected when provided literally.")
		refute(aSpec's isSatisfiedBy("--|EN| A task!"), "Should not match the pattern with extra characters in front when most text is expressed literally.")
		assert(aSpec's isSatisfiedBy("|EN|"), "Should match symbol-word-symbol combo without additional text.")

		--Need to reset builder as we're reusing the instance.
		set builderFixture's builders to { }
		set builderFixture's regex to ""
		set aSpec to builderFixture's anyText()'s l("[|]EN[|]")'s anyText()'s getContents()
		assert(aSpec's isSatisfiedBy("|EN| A task!"), "Should match a pattern as expected when provided literally with any text in front.")
		assert(aSpec's isSatisfiedBy("--|EN| A task!"), "Should match the pattern with extra characters in front when most text is expressed literally.")
		assert(aSpec's isSatisfiedBy("|EN|"), "Should match symbol-word-symbol combo without additional text with any text in front.")

	end script

end script --TextMatchPatternConditionBuilder

script |CustomTextBuilder|
	property parent : TestSet(me)
	property builderFixture : missing value

	on setUp()		
	end setUp

	on tearDown()
	end tearDown
	
	script |Should find custom text pattern|
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomTextBuilder(¬
			inputAttributes_map, "source token", rules's ValueRetrievalStrategy, true)
		
		set aSpec to aBuilder's l("[|]")'s anyText()'s l("[|]")'s getContents()
		
		-- NOTE: Below is the one I want to see in practice.
		-- match by (taskname()'s match()'s customText(token("source token")'s l("[|]")'s anyText()'s l("[|]")))

		assert(aSpec's isSatisfiedBy("|EN|"), "Should match the token.")
		assert(inputAttributes_map's containsValue("source token"), "Should contain a value for 'source token'")
		assertEqual("|EN|", inputAttributes_map's getValue("source token"))
	end script

end script

script |CustomDateBuilder|
	property parent : TestSet(me)
	property builderFixture : missing value

	on setUp()		
	end setUp

	on tearDown()
	end tearDown	
	
	script |Should find short dates |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's aShortDate()'s getContents()

		assert(aSpec's isSatisfiedBy("2006-02-01"), "Should match the token.")
		refute(aSpec's isSatisfiedBy("2006-2-1"), "Should not match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("1/2/2006"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		assertEqual(date "2006-02-01", inputAttributes_map's getValue("start date/time"))
	end script
	
	script |Should find dates with zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			aYear("yyyy")'s l("[-]")'s aMonth("_mm_")'s l("[-]")'s aDay("_dd_")'s getContents()

		assert(aSpec's isSatisfiedBy("2006-02-01"), "Should match the token.")
		refute(aSpec's isSatisfiedBy("2006-2-1"), "Should not match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("1/2/2006"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		assertEqual(date "2006-02-01", inputAttributes_map's getValue("start date/time"))
	end script
	
	script |Should find dates without zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			aYear("yyyy")'s l("[-]")'s aMonth("mm")'s l("[-]")'s aDay("dd")'s getContents()

		assert(aSpec's isSatisfiedBy("2006-02-01"), "Should match the token (nothing wrong with zeros).")
--		assert(aSpec's isSatisfiedBy("2006-2-1"), "Should match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("2/1/2006"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		assertEqual(date "2006-02-01", inputAttributes_map's getValue("start date/time"))
	end script

	(*
	script |Should find 12-hour time with zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			anHour("_hh_")'s l(":")'s aMinute("_MM_")'s l(":")'s aSecond("_ss_")'s AMPM()'s getContents()
				
		assert(aSpec's isSatisfiedBy("01:01:30pm"), "Should match the token.")
		refute(aSpec's isSatisfiedBy("1:01:30"), "Should not match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("1.1.30"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		set expectedDate to current date
		set expectedDate to date "1:01:30pm" of expectedDate
		assertEqual(expectedDate, inputAttributes_map's getValue("start date/time"))
	end script
	
	script |Should find 12-hour time without zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			anHour("hh")'s l(":")'s aMinute("MM")'s l(":")'s aSecond("ss")'s AMPM()'s getContents()		
		
--		assert(aSpec's isSatisfiedBy("01:02:03pm"), "Should match the token.")
		assert(aSpec's isSatisfiedBy("1:2:3pm"), "Should not match the token (needs zeros).")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		set expectedDate to current date
		set expectedDate to date "13:02:03" of expectedDate
		assertEqual(expectedDate, inputAttributes_map's getValue("start date/time"))
	end script

	script |Should find 24-hour time with zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			anHour("_HH_")'s l(":")'s aMinute("_MM_")'s l(":")'s aSecond("_ss_")'s getContents()
				
		assert(aSpec's isSatisfiedBy("01:02:03"), "Should match the token.")
		refute(aSpec's isSatisfiedBy("1:2:3"), "Should not match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("1.2.3"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		set expectedDate to current date
		set expectedDate to date "01:01:03AM" of expectedDate
		assertEqual(expectedDate, inputAttributes_map's getValue("start date/time"))
	end script
	
	script |Should find 24-hour time without zero padding |
		property parent : UnitTest(me)
				
		set inputAttributes_map to collections's makeMap()
		set aBuilder to rules's makeCustomDateBuilder(¬
			inputAttributes_map, "start date/time", rules's ValueRetrievalStrategy, true)

		set aSpec to aBuilder's ¬
			anHour("HH")'s l(":")'s aMinute("MM")'s l(":")'s aSecond("ss")'s getContents()		
		
--		assert(aSpec's isSatisfiedBy("01:02:03"), "Should match the token (nothing wrong with zeros).")
		assert(aSpec's isSatisfiedBy("1:2:3"), "Should match the token (needs zeros).")
		refute(aSpec's isSatisfiedBy("01.02.03"), "Should not match with wrong formatting.")
		assert(inputAttributes_map's containsValue("start date/time"), "Should contain a value for 'source token'")
		set expectedDate to current date
		set expectedDate to date "01:02:03AM" of expectedDate
		assertEqual(expectedDate, inputAttributes_map's getValue("start date/time"))
	end script
	*)


end script

script |ContextConditionBuilder|
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask

	script |Should find context missing|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set builder to rules's makeContextConditionBuilder()
		
		set aSpec to builder's missing()'s getContents()
		
		assert(aSpec's isSatisfiedBy(aTask), "Should have found a missing context.")
		
	end script
		
		
end script --ContextConditionBuilder

script |DateConditionBuilder|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown

	script |is before|
		property parent : UnitTest(me)
		
		set dueDate to rules's makeDateConditionBuilder(rules's ValueRetrievalStrategy)
		
		set aSpec to dueDate's isBefore(date "2015-01-01")'s getContents()
		
		assert(aSpec's isSatisfiedBy(date "2014-12-31"), "Should match date that comes the day before")
		refute(aSpec's isSatisfiedBy(date "2015-01-01"), "Should not match date that comes on same date")
		refute(aSpec's isSatisfiedBy(date "2015-01-02"), "Should not match date that comes after")
		refute(aSpec's isSatisfiedBy(missing value), "Should not match missing value")
	end script
	
	script |is after|
		property parent : UnitTest(me)
		
		set dueDate to rules's makeDateConditionBuilder(rules's ValueRetrievalStrategy)
		
		set aSpec to dueDate's isAfter(date "2015-01-01")'s getContents()
		
		refute(aSpec's isSatisfiedBy(date "2014-12-31"), "Should not match date that comes the day before")
		refute(aSpec's isSatisfiedBy(date "2015-01-01"), "Should not match date that comes on same date")
		assert(aSpec's isSatisfiedBy(date "2015-01-02"), "Should match date that comes after")
		refute(aSpec's isSatisfiedBy(missing value), "Should not match missing value")
	end script
end script --DateConditionBuilder

script |TaskNameCommandBuilder|
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	script |Should replace name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's makeTaskNameCommandBuilder()
		
		set aCommand to aBuilder's rename("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("Bar", aTask's getName())
	end script
	
	script |Should prepend text to name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's makeTaskNameCommandBuilder()

		set aCommand to aBuilder's prepend("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("BarFoo", aTask's getName())
		
	end script

	script |Should append text to name|
		property parent : UnitTest(me)
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's makeTaskNameCommandBuilder()
		set aCommand to aBuilder's append("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("FooBar", aTask's getName())

	end script
	
	script |Should replace token in name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's makeTaskNameCommandBuilder()
		set aCommand to aBuilder's replace("oo", "aa")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("Faa", aTask's getName())
	end script
end script --TaskNameCommandBuilder

script |RuleBase|
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		
		set domain's _taskRepository to domain's DocumentTaskRepository
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask

	script |Should find same taskName|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")

		
		assert(rules's makeRuleBase()'s taskName()'s sameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (sameAs)")
		refute(rules's makeRuleBase()'s taskName()'s sameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (sameAs)")
		refute(rules's makeRuleBase()'s taskName()'s notSameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (notSameAs)")
		assert(rules's makeRuleBase()'s taskName()'s notSameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (notSameAs)")
	end script
	
	script |Should find taskName starts with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's makeRuleBase()'s taskName()'s startsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		refute(rules's makeRuleBase()'s taskName()'s startsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		refute(rules's makeRuleBase()'s taskName()'s doesNotStartWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should start with (doesNotStartWith)")
		assert(rules's makeRuleBase()'s taskName()'s doesNotStartWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (doesNotStartWith)")
	end script

	script |Should find taskName ends with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's makeRuleBase()'s taskName()'s endsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's makeRuleBase()'s taskName()'s endsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's makeRuleBase()'s taskName()'s doesNotEndWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		assert(rules's makeRuleBase()'s taskName()'s doesNotEndWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
	end script

	script |Should find taskName contains|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's makeRuleBase()'s taskName()'s doesContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's makeRuleBase()'s taskName()'s doesContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's makeRuleBase()'s taskName()'s doesNotContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		assert(rules's makeRuleBase()'s taskName()'s doesNotContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
	end script

	script |Should find taskName matches|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		--TODO: Enable this test and get functionality working.
		assert(rules's makeRuleBase()'s taskName()'s match()'s l("a")'s anyText()'s getContents()'s isSatisfiedBy(aTask), "Task name should start with 'a'")
		assert(rules's makeRuleBase()'s taskName()'s match()'s anyText()'s l("matching")'s anyText()'s getContents()'s isSatisfiedBy(aTask), "Task name should include 'matching'")
		assert(rules's makeRuleBase()'s taskName()'s match()'s anyText()'s l("task")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with 'task'")
	end script

end script --RuleBase

script |RuleSuite|

end script --|RuleSuite|

script |Rule Runner|
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		
		set domain's _taskRepository to domain's DocumentTaskRepository
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	
	script |Should run rules|
		property parent : UnitTest(me)
		property aTest : me
		
		--Set up the test rule
		script TestRule
			property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("Test should run rules rule")
			
			on prettyName()
				return "TestRule"
			end prettyName
			
			on matchTask(aTask, inputAttributes)
				aTest's refuteMissing(aTask) 
				return true
			end matchTask
	
			on processTask(aTask, inputAttributes)
				aTest's refuteMissing(aTask) 
				return missing value
			end processTask		
			
			on run()
			end run	
		end script
		
		--Set up the top-level script object 
		 
		script TestRuleScript
			property parent : Rules
			property suite : rules's makeRuleSuite("Test Rule Suite")					
		end script		
		
		script TestRuleSet
			property parent : rules's makeRuleSet()
			property name : "Test Rule Set"
			property target : MockTarget
	
			evaluate by TestRule
		end script

		set TestRuleSet's target's tasks to { createInboxTask("Foo") }
		
		tell TestRuleScript's suite to addRuleSet(TestRuleSet)
		tell TestRuleScript's suite to exec()

		assertEqual(2, numberOfAssertions())
	end script
	
	script |Should leverage [Task]RuleBase grammar|
		property parent : UnitTest(me)
		
		--Set up the test rule
		script TestRule
			property parent : rules's makeRuleBase()
			property name : "RuleBase Testing Rule"
			
			--Conditions
			match by (taskName()'s startsWith("Consider")'s getContents())
			match by (context()'s missing()'s getContents())
			
			--Actions
--			addAction(setContext("Considerations"))
			command thru (setContext("Considerations"))
		end script
		
		--Set up the top-level script object 
		 
		script TestRuleScript
			property parent : Rules
			property suite : Rules's makeRuleSuite("Test Rule Suite")					
		end script		
		
		script TestRuleSet
			property parent : rules's makeRuleSet()
			property name : "Test Rule Set"
			property target : MockTarget
	
			evaluate by TestRule
		end script
		
		set aTask to createInboxTask("Consider this task")
		set TestRuleSet's target's tasks to { aTask }
		
		tell TestRuleScript's suite to addRuleSet(TestRuleSet)
		tell TestRuleScript's suite to exec()
		
		set aContext to domain's ContextRepository's findByName("Considerations")

		assertEqual(aContext, aTask's _contextValue())
	end script
end script --|Rule Runner|

script |DefaultOmniFocusRuleSet| 
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	script |test process empty set does nothing|
		property parent : UnitTest(me)
	
		set aRuleSet to rules's makeOmniFocusRuleSet()
		tell aRuleSet to addTargetConfig(MockTarget, { })
				
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
	script FailedProcessingRule
		property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("Failed Processing Rule")
		
		on matchTask(aTask, inputAttributes)
			return true
		end matchTask
		
		on processTask(aTask, inputAttributes)
			error "Intentionally failing rule"
		end processTask
	end script
	
	script SuccessfulMatchRule
		property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("Successful Match Rule")
		
		on matchTask(aTask, inputAttributes)
			return true
		end matchTask
		
		on processTask(aTask, inputAttributes)
			return { ruleStop:false }
		end processTask
	end script

	script FailedMatchRule
		property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("Failed Match Rule")
		
		on matchTask(aTask, inputAttributes)
			return false
		end matchTask
		
		on processTask(aTask, inputAttributes)
			fail()
		end processTask
	end script

	script StopProcessingRule
		property parent : rules's RuleFactory's _makeOmniFocusTaskProcessingRule("Stop Processing Rule")
		
		on matchTask(aTask, inputAttributes)
			return true
		end matchTask
		
		on processTask(aTask, inputAttributes)
			return { ruleStop:true }
		end processTask
	end script
			
	script |test process all completes even when rules throw errors|
		property parent : UnitTest(me)
	
		set aTarget to MockTarget
		set theRules to { FailedProcessingRule }
				
		set aRuleSet to rules's makeOmniFocusRuleSet()
		tell aRuleSet to addTargetConfig(aTarget, theRules)
		
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
	script |test process all stops future rules when is told to stop|
		property parent : UnitTest(me)

		set aTarget to MockTarget
		set theRules to { StopProcessingRule, FailedProcessingRule }
				
		set aRuleSet to rules's makeOmniFocusRuleSet()
		tell aRuleSet to addTargetConfig(aTarget, theRules)
		
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
	script |test rule skips processing at failed match|
		property parent : UnitTest(me)

		set aTarget to MockTarget
		set theRules to { FailedMatchRule }
			
		set aRuleSet to rules's makeOmniFocusRuleSet()
		tell aRuleSet to addTargetConfig(aTarget, theRules)
	
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
end script --|DefaultOmniFocusRuleSet|