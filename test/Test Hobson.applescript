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

script MockTarget
	property parent : rules's OmniFocusRuleTarget

	on defineName()
		return "Mock Target"
	end defineName
	
	on getTasks()
		return my tasks
	end getTasks
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
			property parent : rules's OmniFocusTaskProcessingRule
			
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
			property target : MockTarget's construct()
	
			evaluate by TestRule
		end script
		
		tell TestRuleScript's suite to addRuleSet(TestRuleSet)
		
		return TestRuleScript
	end createRuleScriptFixture

	script |validates a legit script|
		property parent : UnitTest(me)
		
		set aScript to createRuleScriptFixture()
			
		assert(rules's makeRuleLoader()'s isSatisfiedBy(aScript), "Should be considered valid.")		
	end script
	
	script |loads rules from valid script|
		property parent : UnitTest(me)
		
		set aScript to createRuleScriptFixture()
		set aSuite to rules's makeRuleLoader()'s loadRulesFromScript(aScript)
		
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
		
		set aSuite to rules's makeRuleLoader()'s loadRulesFromFile(aFile)
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
			set aSuite to rules's makeRuleLoader()'s loadRulesFromFile(rulesPath)
			fail()
		on error message
--			ok(message ends with "does not have a suite property")
		end try
	end script

end script

script |TextSpecification|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown

	script |Should find same text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's TextSpecification's sameAsSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should be the same")
		refute(rules's TextSpecification's sameAsSpecification("not a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
	end script

	script |Should find starts with text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's TextSpecification's startsWithSpecification("a", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should start with letter")
		assert(rules's TextSpecification's startsWithSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should start with whole phrase")
		refute(rules's TextSpecification's startsWithSpecification("matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not start with end of phrase")
	end script

	script |Should find ends with text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's TextSpecification's endsWithSpecification("k", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with last letter")
		assert(rules's TextSpecification's endsWithSpecification("task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with last word")
		assert(rules's TextSpecification's endsWithSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should end with whole phrase")
		refute(rules's TextSpecification's endsWithSpecification("a matching", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not end with start of phrase")
	end script

	script |Should find contained text|
		property parent : UnitTest(me)
		
		set actual to "a matching task"

		assert(rules's TextSpecification's containsSpecification("k", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain last letter")
		assert(rules's TextSpecification's containsSpecification("task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain last word")
		assert(rules's TextSpecification's containsSpecification("matching", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain middle word")
		assert(rules's TextSpecification's containsSpecification("a", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain first word")
		assert(rules's TextSpecification's containsSpecification("a matching task", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should contain whole phrase")
		refute(rules's TextSpecification's containsSpecification(" a matching task ", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
		refute(rules's TextSpecification's containsSpecification("other", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Text should not be the same")
	end script
end script

script |DateSpecification|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown

	script |Should find same date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		assert(rules's DateSpecification's sameAsSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be the same")
		refute(rules's DateSpecification's sameAsSpecification(date "2015-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be the same")
	end script

	script |Should find before date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		refute(rules's DateSpecification's isBeforeSpecification(date "2016-01-01", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be before")
		refute(rules's DateSpecification's isBeforeSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be before same date")
		assert(rules's DateSpecification's isBeforeSpecification(date "2016-01-03", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be before next date")
	end script

	script |Should find after date|
		property parent : UnitTest(me)
		
		set actual to date "2016-01-02"

		assert(rules's DateSpecification's isAfterSpecification(date "2016-01-01", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should be after")
		refute(rules's DateSpecification's isAfterSpecification(date "2016-01-02", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be after same date")
		refute(rules's DateSpecification's isAfterSpecification(date "2016-01-03", rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual), "Date should not be after next date")
	end script

	script |Should find dates in the next range|
		property parent : UnitTest(me)
		
		local actual
		set actual to (dateutil's CalendarDate's create on current date)

		assert(rules's DateSpecification's inTheNextSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual's asDate()), "Date should be in the next day")
		assert(rules's DateSpecification's inTheNextSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy(((actual's increment by 7)'s asDate()) - 1), "Date should be in the next week")
		refute(rules's DateSpecification's inTheNextSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by 2)'s asDate()), "Date should not be in the next day")
		refute(rules's DateSpecification's inTheNextSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by 7)'s asDate()), "Date should not be in the next week")
	end script

	script |Should find dates in the last range|
		property parent : UnitTest(me)
		
		local actual
		set actual to dateutil's CalendarDate's create on current date

		assert(rules's DateSpecification's inTheLastSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy(actual's asDate()), "Date should be in the next day")
		assert(rules's DateSpecification's inTheLastSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy(((actual's increment by -7)'s asDate()) + 1), "Date should be in the last week")
		refute(rules's DateSpecification's inTheLastSpecification(1, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by -2)'s asDate()), "Date should not be in the last day")
		refute(rules's DateSpecification's inTheLastSpecification(7, rules's ValueRetrievalStrategy)'s isSatisfiedBy((actual's increment by -7)'s asDate()), "Date should not be in the last week")
	end script

	script |Should find missing dates|
		property parent : UnitTest(me)
		
		assert(rules's DateSpecification's missingSpecification(rules's ValueRetrievalStrategy)'s isSatisfiedBy(missing value), "Date should be missing")
		refute(rules's DateSpecification's missingSpecification(rules's ValueRetrievalStrategy)'s isSatisfiedBy(current date), "Date should not be missing value")
	end script


end script

script |TaskNameRetrievalStrategy|
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property builder : missing value
	
	on setUp()
		set taskFixtures to { }
		
		tell rules's TextSpecificationBuilder
			set builder to make new rules's TextSpecificationBuilder with data rules's TaskNameRetrievalStrategy
		end tell
		
		set domain's _taskRepository to domain's DocumentTaskRepository
	end setUp
	
	on tearDown()
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

		assert(builder's sameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (sameAs)")
		tell builder to reset()
		refute(builder's sameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (sameAs)")
		tell builder to reset()
		refute(builder's notSameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (notSameAs)")
		tell builder to reset()
		assert(builder's notSameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (notSameAs)")
		tell builder to reset()
	end script
	
	script |Should find taskName starts with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(builder's startsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's startsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's startsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		tell builder to reset()
		refute(builder's doesNotStartWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should start with (doesNotStartWith)")
		tell builder to reset()
		assert(builder's doesNotStartWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (doesNotStartWith)")
		tell builder to reset()
	end script

	script |Should find taskName ends with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(builder's endsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's endsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesNotEndWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		tell builder to reset()
		assert(builder's doesNotEndWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
		tell builder to reset()
	end script

	script |Should find taskName contains|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(builder's doesContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		tell builder to reset()
		refute(builder's doesNotContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		tell builder to reset()
		assert(builder's doesNotContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
		tell builder to reset()
	end script
end script

# SYNOPIS
#   doesMatch(text, regexString) -> Boolean
# DESCRIPTION
#   Matches string s against regular expression (string) regex using bash's extended regular expression language *including* 
#   support for shortcut classes such as `\d`, and assertions such as `\b`, and *returns a Boolean* to indicate if
#   there is a match or not.
#    - AppleScript's case sensitivity setting is respected; i.e., matching is case-INsensitive by default, unless inside
#      a 'considering case' block.
#    - The current user's locale is respected.
# EXAMPLE
#    my doesMatch("127.0.0.1", "^(\\d{1,3}\\.){3}\\d{1,3}$") # -> true
on doesMatch(s, regex)
    local ignoreCase, extraGrepOption
    set ignoreCase to "a" is "A"
    if ignoreCase then
        set extraGrepOption to "i"
    else
        set extraGrepOption to ""
    end if
    # Note: So that classes such as \w work with different locales, we need to set the shell's locale explicitly to the current user's.
    #       Rather than let the shell command fail we return the exit code and test for "0" to avoid having to deal with exception handling in AppleScript.
    tell me to return "0" = (do shell script "export LANG='" & user locale of (system info) & ".UTF-8'; egrep -qx" & extraGrepOption & " " & quoted form of regex & " <<< " & quoted form of s & "; printf $?")
end doesMatch

# SYNOPSIS
#   getMatch(text, regexString) -> { overallMatch[, captureGroup1Match ...] } or {}
# DESCRIPTION
#   Matches string s against regular expression (string) regex using bash's extended regular expression language and
#   *returns the matching string and substrings matching capture groups, if any.*
#   
#   - AppleScript's case sensitivity setting is respected; i.e., matching is case-INsensitive by default, unless this subroutine is called inside
#     a 'considering case' block.
#   - The current user's locale is respected.
#   
#   IMPORTANT: 
#   
#   Unlike doesMatch(), this subroutine does NOT support shortcut character classes such as \d.
#   Instead, use one of the following POSIX classes (see `man re_format`):
#       [[:alpha:]] [[:word:]] [[:lower:]] [[:upper:]] [[:ascii:]]
#       [[:alnum:]] [[:digit:]] [[:xdigit:]]
#       [[:blank:]] [[:space:]] [[:punct:]] [[:cntrl:]] 
#       [[:graph:]]  [[:print:]] 
#   
#   Also, `\b`, '\B', '\<', and '\>' are not supported; you can use `[[:<:]]` for '\<' and `[[:>:]]` for `\>`
#   
#   Always returns a *list*:
#    - an empty list, if no match is found
#    - otherwise, the first list element contains the matching string
#       - if regex contains capture groups, additional elements return the strings captured by the capture groups; note that *named* capture groups are NOT supported.
#  EXAMPLE
#       my getMatch("127.0.0.1", "^([[:digit:]]{1,3})\\.([[:digit:]]{1,3})\\.([[:digit:]]{1,3})\\.([[:digit:]]{1,3})$") # -> { "127.0.0.1", "127", "0", "0", "1" }
on getMatch(s, regex)
    local ignoreCase, extraCommand
    set ignoreCase to "a" is "A"
    if ignoreCase then
        set extraCommand to "shopt -s nocasematch; "
    else
        set extraCommand to ""
    end if
    # Note: 
    #  So that classes such as [[:alpha:]] work with different locales, we need to set the shell's locale explicitly to the current user's.
    #  Since `quoted form of` encloses its argument in single quotes, we must set compatibility option `shopt -s compat31` for the =~ operator to work.
    #  Rather than let the shell command fail we return '' in case of non-match to avoid having to deal with exception handling in AppleScript.
    tell me to do shell script "export LANG='" & user locale of (system info) & ".UTF-8'; shopt -s compat31; " & extraCommand & "[[ " & quoted form of s & " =~ " & quoted form of regex & " ]] && printf '%s\\n' \"${BASH_REMATCH[@]}\" || printf ''"
    return paragraphs of result
end getMatch

script TextMatchPatternConditionBuilder
	property builders : { }
	property regex : ""

	on aLetter()
		set regex to regex & "[[:alpha:]]{1}"
		script 
			on getContents()
				script 
					on isSatisfiedBy(obj as text)
						return doesMatch(obj, "[[:alpha:]]{1}")
					end isSatisfiedBy
				end script
			end getContents
		end script
		
		set end of builders to the result
		
		return me
	end aLetter
	
	on aDigit()
		set regex to regex & "[[:digit:]]{1}"
		script 
			on getContents()
				script 
					on isSatisfiedBy(obj as text)
						return doesMatch(obj, "[[:digit:]]{1}")
					end isSatisfiedBy
				end script
			end getContents
		end script
		
		set end of builders to the result
		
		return me
	end aDigit
	
	on letterOrDigit()
		script 
			on getContents()
				script 
					on isSatisfiedBy(obj as text)
						return doesMatch(obj, "[[:alnum:]]{1}")
					end isSatisfiedBy
				end script
			end getContents
		end script
		
		set end of builders to the result
		
		return me
		
	end letterOrDigit
	
	on aSymbol()
		return me
	end aSymbol
	
	on customDate()
	end customDate
	
	on aWord()
		script 
			on getContents()
				script 
					on isSatisfiedBy(obj as text)
						return doesMatch(obj, "[[:word:]]{1}")
					end isSatisfiedBy
				end script
			end getContents
		end script
		
		set end of builders to the result
		
		return me
		
	end aWord
	
	on aNumber()
		script 
			on getContents()
				script 
					on isSatisfiedBy(obj as text)
						return doesMatch(obj, "[[:xdigit:]]{1}")
					end isSatisfiedBy
				end script
			end getContents
		end script
		
		set end of builders to the result
		
		return me
		
	end aNumber
	
	on lettersAndDigits()
	end lettersAndDigits
	
	on symbols()
	end symbols
	
	on customText()
	end customText
	
	on anyText()
	end anyText
	
	on textString()
	end textString
	
	on getContents()
		set aSpec to rules's TrueSpecification
		
		repeat with aBuilder in builders
			set aSpec to aSpec's andSpec(aBuilder's getContents())
		end repeat
--		return aSpec
		
		script 
			on isSatisfiedBy(obj as text)
				return doesMatch(obj, regex)
			end isSatisfiedBy
		end script
		
		return the result
	end getContents
end script

script CustomTokenBuilder
	property tokenName : missing value
	
	on token(tokenName)
		set my tokenName to tokenName
	end token

	on aDay()
	end aDay
	
	on aMonth()
	end aMonth
	
	on aYear()
	end aYear
	
	on anHour()
	end anHour
	
	on aMinute()
	end aMinute
	
	on aSecond()
	end aSecond
	
	on anyText()
	end anyText
	
	on textString()
	end textString
end script

script |TextMatchPatternConditionBuilder|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown
	
	script |Should find matching letter|
		property parent : UnitTest(me)
		
		copy TextMatchPatternConditionBuilder to builder
		set aSpec to builder's aLetter()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("a"), "Should match with single letter (a).")
		assert(aSpec's isSatisfiedBy("A"), "Should match with single letter (A).")
		assert(aSpec's isSatisfiedBy("b"), "Should match with single letter (b).")
		refute(aSpec's isSatisfiedBy("2"), "Should not match a number")
		refute(aSpec's isSatisfiedBy("bb"), "Should not match multiple letters.")
	end script

	script |Should find matching number|
		property parent : UnitTest(me)
		
		copy TextMatchPatternConditionBuilder to builder
		set aSpec to builder's aDigit()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1"), "Should match with single number (1).")
		assert(aSpec's isSatisfiedBy("2"), "Should match with single number (2).")
		refute(aSpec's isSatisfiedBy("b"), "Should not match with single letter (b).")
		refute(aSpec's isSatisfiedBy("22"), "Should not match multiple numbers.")
	end script

	script |Should find matching pattern|
		property parent : UnitTest(me)
		
		copy TextMatchPatternConditionBuilder to builder
		set aSpec to builder's aDigit()'s aLetter()'s getContents()
		refute(aSpec's isSatisfiedBy(""), "Should not match empty string.")
		assert(aSpec's isSatisfiedBy("1a"), "Should match number and letter.")
		refute(aSpec's isSatisfiedBy("a1"), "Should not match letter and number.")
		refute(aSpec's isSatisfiedBy("22"), "Should not match multiple numbers.")
	end script

end script


script |TaskRenaming|
	property parent : TestSet(me)
	
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
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
		
		set aBuilder to rules's TaskNameCommandBuilder's createBuilder()
		
		set aCommand to aBuilder's rename("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("Bar", aTask's getName())
	end script
	
	script |Should prepend text to name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's TaskNameCommandBuilder's createBuilder()

		set aCommand to aBuilder's prepend("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("BarFoo", aTask's getName())
		
	end script

	script |Should append text to name|
		property parent : UnitTest(me)
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's TaskNameCommandBuilder's createBuilder()
		set aCommand to aBuilder's append("Bar")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("FooBar", aTask's getName())

	end script
	
	script |Should replace token in name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Foo")
		
		set aBuilder to rules's TaskNameCommandBuilder's createBuilder()
		set aCommand to aBuilder's replace("oo", "aa")'s getContents()
		tell aCommand to execute(aTask)
		
		assertEqual("Faa", aTask's getName())
	end script
end script

script |ContextConditionBuilder|
	property parent : TestSet(me)
	
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
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
		
		copy rules's ContextConditionBuilder to builder
		
		set aSpec to builder's missing()'s getContents()
		
		assert(aSpec's isSatisfiedBy(aTask), "Should have found a missing context.")
		
	end script
		
		
end script

script |DateConditionBuilder|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown

	script |is before|
		property parent : UnitTest(me)
		
		tell rules's DateConditionBuilder
			set dueDate to make new rules's DateConditionBuilder with data rules's ValueRetrievalStrategy
		end tell
		
		set aSpec to dueDate's isBefore(date "2015-01-01")'s getContents()
--		log "Spec name: " & aSpec's name
		
		assert(aSpec's isSatisfiedBy(date "2014-12-31"), "Should match date that comes the day before")
		refute(aSpec's isSatisfiedBy(date "2015-01-01"), "Should not match date that comes on same date")
		refute(aSpec's isSatisfiedBy(date "2015-01-02"), "Should not match date that comes after")
		refute(aSpec's isSatisfiedBy(missing value), "Should not match missing value")
	end script
	
	script |is after|
		property parent : UnitTest(me)
		
		tell rules's DateConditionBuilder
			set dueDate to make new rules's DateConditionBuilder with data rules's ValueRetrievalStrategy
		end tell
		
		set aSpec to dueDate's isAfter(date "2015-01-01")'s getContents()
--		log "Spec name: " & aSpec's name
		
		refute(aSpec's isSatisfiedBy(date "2014-12-31"), "Should not match date that comes the day before")
		refute(aSpec's isSatisfiedBy(date "2015-01-01"), "Should not match date that comes on same date")
		assert(aSpec's isSatisfiedBy(date "2015-01-02"), "Should match date that comes after")
		refute(aSpec's isSatisfiedBy(missing value), "Should not match missing value")
	end script
end script

script |RuleBase|
	property parent : TestSet(me)
	
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
		
		set domain's _taskRepository to domain's DocumentTaskRepository
	end setUp
	
	on tearDown()
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

		
		assert(rules's RuleBase's taskName()'s sameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (sameAs)")
		refute(rules's RuleBase's taskName()'s sameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (sameAs)")
		refute(rules's RuleBase's taskName()'s notSameAs("a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should be the same (notSameAs)")
		assert(rules's RuleBase's taskName()'s notSameAs("not a matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not be the same (notSameAs)")
	end script
	
	script |Should find taskName starts with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's RuleBase's taskName()'s startsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		refute(rules's RuleBase's taskName()'s startsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (startsWith)")
		refute(rules's RuleBase's taskName()'s doesNotStartWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should start with (doesNotStartWith)")
		assert(rules's RuleBase's taskName()'s doesNotStartWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not start with (doesNotStartWith)")
	end script

	script |Should find taskName ends with|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's RuleBase's taskName()'s endsWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's RuleBase's taskName()'s endsWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's RuleBase's taskName()'s doesNotEndWith("matching task")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		assert(rules's RuleBase's taskName()'s doesNotEndWith("a matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
	end script

	script |Should find taskName contains|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
		assert(rules's RuleBase's taskName()'s doesContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's RuleBase's taskName()'s doesContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
		refute(rules's RuleBase's taskName()'s doesNotContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
		assert(rules's RuleBase's taskName()'s doesNotContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
	end script

	script |Should find taskName matches|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("a matching task")
		
--		assert(rules's RuleBase's taskName()'s matches()'s token("a")'s anyText()'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
--		assert(rules's RuleBase's taskName()'s matches()'s anyText()'s token("matching")'s anyText()'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
--		assert(rules's RuleBase's taskName()'s matches()'s anyText()'s token("task")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
--		refute(rules's RuleBase's taskName()'s doesContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (endsWith)")
--		refute(rules's RuleBase's taskName()'s doesNotContain("matching")'s getContents()'s isSatisfiedBy(aTask), "Task name should end with (doesNotEndWith)")
--		assert(rules's RuleBase's taskName()'s doesNotContain("another")'s getContents()'s isSatisfiedBy(aTask), "Task name should not end with (doesNotEndWith)")
	end script

end script --RuleBase

script |RuleSuite|

end script --|RuleSuite|


script |Rule Runner|
	property parent : TestSet(me)
	
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
		
		set domain's _taskRepository to domain's DocumentTaskRepository
	end setUp
	
	on tearDown()
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
			property parent : rules's OmniFocusTaskProcessingRule
			
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
			property target : MockTarget's construct()
	
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
			property parent : rules's RuleBase
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
			property target : MockTarget's construct()
	
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

script |AbstractOmniFocusRuleSet| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
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
	
		copy rules's AbstractOmniFocusRuleSet to aRuleSet
		tell aRuleSet to addTargetConfig(MockTarget, { })
				
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
	script FailedProcessingRule
		property parent : rules's OmniFocusTaskProcessingRule
		
		on matchTask(aTask, inputAttributes)
			return true
		end matchTask
		
		on processTask(aTask, inputAttributes)
			error "Intentionally failing rule"
		end processTask
	end script
	
	script SuccessfulMatchRule
		property parent : rules's OmniFocusTaskProcessingRule
		
		on matchTask(aTask, inputAttributes)
			return true
		end matchTask
		
		on processTask(aTask, inputAttributes)
			return { ruleStop:false }
		end processTask
	end script

	script FailedMatchRule
		property parent : rules's OmniFocusTaskProcessingRule
		
		on matchTask(aTask, inputAttributes)
			return false
		end matchTask
		
		on processTask(aTask, inputAttributes)
			fail()
		end processTask
	end script

	script StopProcessingRule
		property parent : rules's OmniFocusTaskProcessingRule
		
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
				
		copy rules's AbstractOmniFocusRuleSet to aRuleSet
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
				
		copy rules's AbstractOmniFocusRuleSet to aRuleSet
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
			
		copy rules's AbstractOmniFocusRuleSet to aRuleSet
		tell aRuleSet to addTargetConfig(aTarget, theRules)
	
		try
			tell aRuleSet to processAll()
		on error message
			fail("Should have completed without error: " & message)
		end try
	end script
	
end script --|AbstractOmniFocusRuleSet|

script |OmniFocus Rule Processing Daemon|
	property parent : TestSet(me)
	property taskFixtures : { }
	
	on setUp()
		set taskFixtures to { }
	end setUp
	
	on tearDown()
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
		

end script --|OmniFocus Rule Processing Daemon|