use AppleScript version "2.4"
use scripting additions

use tidyScript : script "Tidy"
(*!
	@header Test OmniFocus Rule Parsing Daemon self tests.
	@abstract License: GNU GPL, see COPYING for details.
	@author Kraig Parkinson
	@copyright 2015 kraigparkinson
*)

property parent : script "com.lifepillar/ASUnit"

property suite : makeTestSuite("Tidy")

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
		
		tell tidyScript's hobson to registerRuleRepository(MockRuleRepository)
		
		run tidyScript
	end script
	
end script