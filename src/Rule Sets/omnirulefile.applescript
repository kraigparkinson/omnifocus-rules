#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

property id : "omnirulefile"
property name : "omnirulefile"

use Rules : script "com.kraigparkinson/Hobson"
use hoblib : script "com.kraigparkinson/Default OmniFocus Rules Library"
use cfwof : script "com.kraigparkinson/Creating Flow with OmniFocus Rules"

property parent : Rules

property suite : Rules's makeRuleSuite("Creating Flow with OmniFocus")

on run argv
	continue run argv
end run

script MarkCompletePastDueTasks
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
	evaluate by cfwof's TidyConsiderationsRule
	evaluate by cfwof's AddDailyRepeatRule
	evaluate by hoblib's ExpiredMeetingPreparationRule
	evaluate by hoblib's ExpiredCheckMeetingParticipationRule	
end script

script MeetingsToPlanScript
	property parent : RuleSet(me)
	property name : "Meetings to Plan"
	property target : target()'s project("Meetings to plan")
	
	evaluate by hoblib's ExpiredMeetingPreparationRule		
	evaluate by hoblib's ExpiredCheckMeetingParticipationRule	
	evaluate by MarkCompletePastDueTasks
end script

