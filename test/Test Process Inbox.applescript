(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)
property processInboxScript : script "Process Inbox"
property parent : script "com.lifepillar/ASUnit"

property suite : makeTestSuite("Process Inbox")

my autorun(suite)

script |Runs as Expected|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown

	script |returns output attributes on success|
		property parent : UnitTest(me)
		
		script MockRuleRepository 
			property name : "MockRuleRepository"
			
			on getAll()
				script MockSuite
					on exec()
					end exec
				end script
				return MockSuite
			end getAll
		end script
		
		tell processInboxScript's hobson to registerRuleRepository(MockRuleRepository)
		
		run processInboxScript		
	end script
	
end script