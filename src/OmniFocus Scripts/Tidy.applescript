use AppleScript version "2.4"
use scripting additions

use hobson : script "com.kraigparkinson/Hobson"
use cfr : script "com.kraigparkinson/Default OmniFocus Rules Library"

property parent : hobson

property suite : hobson's makeRuleSuite("Creating Flow with OmniFocus")

script StripSourceTokens
	property parent : hobson's RuleBase
	property name : "Strip source tokens"
	
	set aToken to "|GC|" & space
	
	match by (taskName()'s startsWith(aToken)'s getContents())
	
	set aCommand to hobson's StripTokenFromTaskNameCommand's constructCommand()
	set aCommand's token to aToken
	
	command thru (aCommand)	
end script

script TidySet
	property parent : RuleSet(me)
	property name : "Selected Tasks"
	property target : hobson's UserSpecifiedTasks's construct()

	evaluate by cfr's OmniFocusTransportTextParsingRule
	evaluate by StripSourceTokens
	evaluate by cfr's TidyConsiderationsRule
	evaluate by cfr's AddDailyRepeatRule
	evaluate by cfr's ExpiredMeetingPreparationRule
	evaluate by cfr's ExpiredCheckMeetingParticipationRule	
end script		

on run	
	tell suite to exec()	
end run
