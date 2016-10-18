(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)
use Applescript version "2.4"
use scripting additions

use domain : script "com.kraigparkinson/OmniFocusDomain"
use collections : script "com.kraigparkinson/ASCollections"
use cfwof : script "com.kraigparkinson/Creating Flow with OmniFocus Rules"

property parent : script "com.lifepillar/ASUnit"
property suite : makeTestSuite("Creating Flow with OmniFocus Rules")


my autorun(suite)

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

script |Tidy Incomplete Consideration Tasks Rule| 
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	property contextFixtures : { }
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		set contextFixtures to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in my taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
		tell application "OmniFocus"
			repeat with aContext in my contextFixtures
				delete aContext
			end repeat
		end tell
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	on createContext(name)
		set newContext to domain's ContextRepository's create(name)
		set end of contextFixtures to newContext
		return newContext
	end createContext
	
	script |does not match when context is already set|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		set aContext to createContext("Test Context")
		
		tell application "OmniFocus"
			tell aTask to assignToContext(aContext)
		end tell
		
		set aRule to cfwof's TidyConsiderationsRule
		tell aRule to run
		
		set matchingResult to aRule's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script

	script |matches when context is not set|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		
		set aRule to cfwof's TidyConsiderationsRule
		tell aRule to run
				
		set matchingResult to aRule's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script
	
	script |should update context and repetition rule to defer daily|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		set aContext to createContext("Considerations")
		
		set aRule to cfwof's TidyConsiderationsRule
		tell aRule to run
				
		tell aRule to processTask(aTask, missing value)
		
		assertEqual(aContext, aTask's _contextValue())
		
	end script

end script

script |Add Daily Repeat Rule| 
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property ruleFixture : cfwof's AddDailyRepeatRule
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		set contextFixtures to { }

		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in my taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
		tell application "OmniFocus"
			repeat with aContext in my contextFixtures
				delete aContext
			end repeat
		end tell
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	on createContext(name)
		set newContext to domain's ContextRepository's create(name)
		set end of contextFixtures to newContext
		return newContext
	end createContext
	
	script |matches with text in name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider (Add daily repeat)")
				
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script

	script |does not match when text is not set|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		
		tell ruleFixture to run
				
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |updates repetition rule to defer daily|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider (Add daily repeat)")
		
		tell ruleFixture to run
				
		tell ruleFixture to processTask(aTask, missing value)
		
		tell application "OmniFocus"
			set expectedRepetitionRule to {repetition method:fixed repetition, recurrence:"FREQ=DAILY"}
			my assertEqual("Consider", aTask's getName())
			my assertEqual(expectedRepetitionRule, aTask's _repetitionRuleValue())
		end tell
		
	end script

end script

script |Add Daily Defer Rule| 
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property ruleFixture : cfwof's AddDailyDeferRule
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		set contextFixtures to { }

		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in my taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
		tell application "OmniFocus"
			repeat with aContext in my contextFixtures
				delete aContext
			end repeat
		end tell
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	on createContext(name)
		set newContext to domain's ContextRepository's create(name)
		set end of contextFixtures to newContext
		return newContext
	end createContext
	
	script |matches with text in name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider (Add daily defer)")
				
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script

	script |does not match when text is not set|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		
		tell ruleFixture to run
				
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |updates repetition rule to defer daily|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider (Add daily defer)")
		
		tell ruleFixture to run
				
		tell ruleFixture to processTask(aTask, missing value)
		
		tell application "OmniFocus"
			set expectedRepetitionRule to {repetition method:start after completion, recurrence:"FREQ=DAILY"}
			my assertEqual("Consider", aTask's getName())
			my assertEqual(expectedRepetitionRule, aTask's _repetitionRuleValue())
		end tell
		
	end script

end script

script |Convert To Drop Rule| 
	property parent : registerFixtureOfKind(me, |OmniFocus Document Fixture|)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property ruleFixture : cfwof's ConvertToDropRule
	
	on setUp()
		continue setUp()
		set taskFixtures to { }
		set contextFixtures to { }

		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
		continue tearDown()
		repeat with aTask in my taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
		tell application "OmniFocus"
			repeat with aContext in my contextFixtures
				delete aContext
			end repeat
		end tell
	end tearDown

	on createInboxTask(transportText)
		set newTasks to domain's taskRepositoryInstance()'s addTaskFromTransportText(transportText)
		set newTask to first item of newTasks
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	on createContext(name)
		set newContext to domain's ContextRepository's create(name)
		set end of contextFixtures to newContext
		return newContext
	end createContext
	
	script |Should match the task with matching text and the conversion date is passed|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("(2016-01-01 -> DROP) Waiting for response from Jeffrey re: stepping down from the throne")
				
		tell ruleFixture to run
		
		set attrs to collections's makeMap()
		set matchingResult to ruleFixture's matchTask(aTask, attrs)
		
		assert(matchingResult, "Should have matched.")
		assert(attrs's containsValue("conversion date"), "Should contain a conversion date value")
		assert(attrs's containsValue("person"), "Should contain a person value")
		assert(attrs's containsValue("expectation"), "Should contain an expectation value")
		
	end script

	script |Should not match the task with matching text and the conversation date is not passed|
		property parent : UnitTest(me)
		
		--TODO make this more robust in case anyone is crazy enough to set their clock forward or we actually pass this date.
		set aTask to createInboxTask("(2025-01-01 -> DROP) Waiting for response from Jeffrey re: stepping down from the throne")
		
		tell ruleFixture to run
				
		set attrs to collections's makeMap()
		set matchingResult to ruleFixture's matchTask(aTask, attrs)
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |Should mark the task complete and add comment|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("(2016-01-01 -> DROP) Waiting for response from Jeffrey re: stepping down from the throne")
		
		tell ruleFixture to run
				
		set attrs to collections's makeMap()
		tell ruleFixture to processTask(aTask, attrs)
		
		assert(aTask's hasBeenCompleted(), "Should have marked completed.")
		assert(aTask's _noteValue() starts with "INFO: This task was automatically marked complete by Hobson." & linefeed & linefeed, "Nite should ave started with expexted value.")		
	end script

end script
