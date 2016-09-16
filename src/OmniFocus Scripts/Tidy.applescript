use AppleScript version "2.4"
use Rules : script "com.kraigparkinson/OmniFocus Rules Engine"
use cfr : script "com.kraigparkinson/Default OmniFocus Rules Library"

property parent : Rules

property suite : Rules's makeRuleSuite("Creating Flow with OmniFocus")

script StripSourceTokens
	property parent : Rules's RuleBase
	property name : "Strip source tokens"
	
	set aToken to "|GC|" & space
	
	match by (taskName()'s startsWith(aToken)'s getContents())
	
	set aCommand to Rules's StripTokenFromTaskNameCommand's constructCommand()
	set aCommand's token to aToken
	
	command thru (aCommand)	
end script

script TidySet
	property parent : RuleSet(me)
	property name : "Selected Tasks"
	property target : Rules's UserSpecifiedTasks's construct()

	evaluate by cfr's OmniFocusTransportTextParsingRule
	evaluate by StripSourceTokens
	evaluate by cfr's TidyConsiderationsRule
	evaluate by cfr's AddDailyRepeatRule
	evaluate by cfr's ExpiredMeetingPreparationRule
	evaluate by cfr's ExpiredCheckMeetingParticipationRule	
end script		

on main()	
	tell suite to exec()	
end main

main()
