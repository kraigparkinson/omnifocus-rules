use AppleScript version "2.4"
use scripting additions

use daemon : script "OmniFocus Rule Processing Daemon"

(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)
property parent : script "com.lifepillar/ASUnit"

property suite : makeTestSuite("OmniFocus Rule Processing Daemon")

my autorun(suite)


script |Hazel Rule Processing|
	property parent : TestSet(me)

	on setUp()
	end setUp

	on tearDown()
	end tearDown

	script |returns output attributes on success|
		property parent : UnitTest(me)
		
		set theFile to missing value
		set inputAttributes to missing value
			
		script MockRuleRepository 
			property name : "MockRuleRepository"
			property handlerCalled : false
			
			on getAll()
				script MockSuite
					on exec()
						set handlerCalled to true
					end exec
				end script
				return MockSuite
			end getAll
		end script
		
		tell daemon's hobson to registerRuleRepository(MockRuleRepository)
		
		daemon's hazelProcessFile(theFile, inputAttributes)
		should(MockRuleRepository's handlerCalled, "Rule suite should have been called")
--		assertMissing(hazelResult, "Expected hazelResult record to come back")		
	end script
	
end script