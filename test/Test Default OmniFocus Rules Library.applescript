(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)
use Applescript version "2.4"
use scripting additions

use domain : script "com.kraigparkinson/OmniFocusDomain"
use hoblib : script "com.kraigparkinson/Default OmniFocus Rules Library"

property parent : script "com.lifepillar/ASUnit"
property suite : makeTestSuite("Default OmniFocus Rules Library")


my autorun(suite)


script |Add OmniOutliner Template as Children|
	property parent : TestSet(me)

	property taskFixtures : { }
	property contextFixtures : { }

	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }
	end setUp

	on tearDown()
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

	script |Should load file when present|
		tell application "Finder"
			set aFile to file "build/Rule Sets/omnirulefile.scptd"
		end tell 
		
		assertNotMissing(aFile, "Should have loaded the file.")
	end script
end script

script |Tidy Incomplete Consideration Tasks Rule| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property contextFixtures : { }
	
	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }
	end setUp
	
	on tearDown()
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
		
		set aRule to hoblib's TidyConsiderationsRule
		tell aRule to run
		
		set matchingResult to aRule's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script

	script |matches when context is not set|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		
		set aRule to hoblib's TidyConsiderationsRule
		tell aRule to run
				
		set matchingResult to aRule's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script
	
	script |should update context and repetition rule to defer daily|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Consider foo")
		set aContext to domain's ContextRepository's findByName("Considerations")
		
		set aRule to hoblib's TidyConsiderationsRule
		tell aRule to run
				
		tell aRule to processTask(aTask, { })
		
		assertEqual(aContext, aTask's _contextValue())
		
	end script

end script

script |Add Daily Repeat Rule| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property ruleFixture : hoblib's AddDailyRepeatRule
	
	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }

		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
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
				
		tell ruleFixture to processTask(aTask, { })
		
		tell application "OmniFocus"
			set expectedRepetitionRule to {repetition method:start after completion, recurrence:"FREQ=DAILY"}
			my assertEqual("Consider", aTask's getName())
			my assertEqual(expectedRepetitionRule, aTask's _repetitionRuleValue())
		end tell
		
	end script

end script

script |Expired Meeting Preparation Rule| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property contextFixtures : { }
	
	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }
	end setUp
	
	on tearDown()
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
		
		set aTask to createInboxTask("|GC| Prepare for your meeting 'Foo'")

		aTask's dueOn(current date - 1 * days)
				
		set aRule to hoblib's ExpiredMeetingPreparationRule
		tell aRule to run
		
		set matchingResult to aRule's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script

	script |matches with recurring text in name|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("|GC| Prepare for your recurring meeting 'Foo'")

		aTask's dueOn(current date - 1 * days)
				
		set aRule to hoblib's ExpiredMeetingPreparationRule
		tell aRule to run
		
		set matchingResult to aRule's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
	end script

	script |does not match when task is in the future|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("|GC| Prepare for your meeting 'Doe'")
		
		aTask's dueOn(current date + 1 * days)
		
		set aRule to hoblib's ExpiredMeetingPreparationRule
		tell aRule to run
				
		set matchingResult to aRule's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |marks complete|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("|GC| Prepare for your meeting 'Doe'")
		aTask's dueOn(current date - 1 * days)
		
		set aRule to hoblib's ExpiredMeetingPreparationRule
		tell aRule to run
				
		tell aRule to processTask(aTask, { })
		
		tell application "OmniFocus"
			my assert(aTask's hasBeenCompleted(), "Should have marked completed.")
		end tell
		
	end script

end script

script |Evernote TaskClone Preparation Rule| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property ruleFixture : hoblib's EvernoteTaskClonePreparationRule
	
	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }
		
		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
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
	
	script |matches when token is in front|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("|EN| Catch up with Dave")
		
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
		
	end script	
	
	script |does not match when token isn't in front|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Catch up with Dave |EN|")
				
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |replaces token|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("|EN| Catch up with Dave")
		
		tell ruleFixture to run
				
		tell ruleFixture to processTask(aTask, { })
		
		assertEqual("--Catch up with Dave |EN|", aTask's getName())
		
	end script
	
	
end script

script |OmniFocus Transport Text Parsing Rule| 
	property parent : TestSet(me)
	
	property taskFixtures : { }
	property contextFixtures : { }
	property projectFixtures : { }
	property ruleFixture : hoblib's OmniFocusTransportTextParsingRule
	
	on setUp()
		set taskFixtures to { }
		set contextFixtures to { }
		set projectFixtures to { }
		
		set ruleFixture's conditions to { }
		set ruleFixture's actions to { }
	end setUp
	
	on tearDown()
		repeat with aTask in my taskFixtures
			domain's taskRepositoryInstance()'s removeTask(aTask)
		end repeat
		tell application "OmniFocus"
			repeat with aProject in my projectFixtures
				delete aProject
			end repeat
		end tell
		tell application "OmniFocus"
			repeat with aContext in my contextFixtures
				delete aContext
			end repeat
		end tell
	end tearDown

	on createInboxTask(transportText)
		set newTask to domain's TaskFactory's create()
		newTask's setName(transportText)
		set newTask to domain's taskRepositoryInstance()'s addTask(newTask)
		set end of taskFixtures to newTask 		
		return newTask 		
	end createInboxTask
	
	script |matches when token is in front|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("--Catch up with Dave")
		
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		assert(matchingResult, "Should have matched.")
		
	end script	
	
	script |does not match when token isn't in front|
		property parent : UnitTest(me)
		
		set aTask to createInboxTask("Catch up with Dave |EN|")
				
		tell ruleFixture to run
		
		set matchingResult to ruleFixture's matchTask(aTask, { })
		
		refute(matchingResult, "Should not have matched.")
	end script
	
	script |parses task with task name as transport text|
		property parent : UnitTest(me)
		
		set expectedProjectName to "Test transport text parsing rule"
		set expectedContextName to expectedProjectName
		set aProject to domain's ProjectRepository's create(expectedProjectName)
		set end of projectFixtures to aProject
		set aContext to domain's ContextRepository's create(expectedProjectName)
		set end of contextFixtures to aContext
		set aTask to createInboxTask("--Catch up with Dave ::" & expectedProjectName & " @" & expectedContextName)
		
		tell ruleFixture to run
				
		tell ruleFixture to processTask(aTask, { })
		
		assertEqual("Catch up with Dave", aTask's getName())
		assertEqual(aProject, aTask's _assignedContainerValue())
		assertEqual(aContext, aTask's _contextValue())
	end script
	
	
end script