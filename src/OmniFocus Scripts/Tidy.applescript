use AppleScript version "2.4"
use scripting additions

use hobson : script "com.kraigparkinson/Hobson"
use hoblib : script "com.kraigparkinson/Default OmniFocus Rules Library"
use cfwof : script "com.kraigparkinson/Creating Flow with OmniFocus Rules"

property parent : hobson

property suite : hobson's makeRuleSuite("Creating Flow with OmniFocus")

script StripSourceTokens
	property parent : hobson's makeRuleBase()
	property name : "Strip source tokens"
	
	set aToken to "|GC|" & space
	
	match by (taskName()'s startsWith(aToken)'s getContents())
	
	command thru (hobson's CommandFactory's makeStripTokenFromTaskNameCommand(aToken))	
end script

script TidySet
	property parent : RuleSet(me)
	property name : "Selected Tasks"
	property target : hobson's UserSpecifiedTasks

	evaluate by hoblib's OmniFocusTransportTextParsingRule
	evaluate by StripSourceTokens
	evaluate by cfwof's TidyConsiderationsRule
	evaluate by cfwof's AddDailyRepeatRule
	evaluate by hoblib's ExpiredMeetingPreparationRule
	evaluate by hoblib's ExpiredCheckMeetingParticipationRule	
end script		

on run	
	tell suite to exec()	
	display notification "Finished tidying selected task(s)." with title "OmniFocus" subtitle "Tidy" sound name "Sosumi"

end run
