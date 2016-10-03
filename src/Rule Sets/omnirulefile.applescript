#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

use Rules : script "com.kraigparkinson/Hobson"
use hoblib : script "com.kraigparkinson/Default OmniFocus Rules Library"

property parent : Rules

property suite : Rules's makeRuleSuite("Creating Flow with OmniFocus")

on run argv
	continue run argv
end run

script |Mark complete any past due tasks|
	property parent : Rules's makeRuleBase()
	property name : "Mark complete past due tasks"
		
	match by (taskName()'s startsWith("Prepare for your recurring meeting")'s getContents())
	match by (dueDate()'s isBefore(current date)'s getContents())
	
	command thru markCompleted()
end script

script ProcessBcc
	property parent : Rules's makeRuleBase()
	property name : "Process Bcc"
	
	match by (taskName()'s startsWith("Re:")'s getContents())

	command thru (do()'s taskName()'s prepend("Follow up ")) 
end script

script InboxConfigScript
	property parent : RuleSet(me)
	property name : "Process Inbox Tasks"
	property target : Rules's Inbox
	
	evaluate by hoblib's EvernoteTaskClonePreparationRule
	evaluate by hoblib's OmniFocusTransportTextParsingRule
	evaluate by hoblib's TidyConsiderationsRule
	evaluate by hoblib's AddDailyRepeatRule
	evaluate by hoblib's ExpiredMeetingPreparationRule
	evaluate by hoblib's ExpiredCheckMeetingParticipationRule	
end script

script MeetingsToPlanScript
	property parent : RuleSet(me)
	property name : "Meetings to Plan"
	property target : target()'s project("Meetings to plan")
	
	evaluate by hoblib's ExpiredMeetingPreparationRule		
	evaluate by hoblib's ExpiredCheckMeetingParticipationRule	
	evaluate by |Mark complete any past due tasks|
end script

