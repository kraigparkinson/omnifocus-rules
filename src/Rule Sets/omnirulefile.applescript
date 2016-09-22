use AppleScript version "2.4"
use scripting additions

property Rules : script "com.kraigparkinson/Hobson"
--use Rules : script "com.kraigparkinson/Hobson"
use cf : script "com.kraigparkinson/Default OmniFocus Rules Library"

property parent : Rules

property suite : Rules's makeRuleSuite("Creating Flow with OmniFocus")


script EvernoteTaskClonePreparationRule
--	property parent : Rule(me)
	property parent : Rules's RuleBase
	property name : "Evernote TaskClone Preprocessing Rule"
	
	set token to "|EN|"
	
	match by (taskName()'s startsWith(token)'s getContents())
	
	set aCommand to rules's ReplaceTokenFromTaskNameCommand's constructCommand()
	set aCommand's findToken to token & space
	set aCommand's replaceToken to "--[EN]"
	command thru aCommand	
end script

(*
script TidyConsiderationsRule
	property parent : Rule(me)
	
	--Conditions
	match by (taskName()'s startsWith("Consider")'s getContents())
	match by (context()'s missing()'s getContents())

	--Actions
	command thru (setContext("Considerations"))
end script
*)
(*
script AddDailyRepeatRule
	property parent : Rule(me)
	
	--Conditions
	set aToken to "(Add daily repeat)"
	match by (taskName()'s doesContain(aToken))
	match by (repetitionRule()'s missing())

	--Actions
	command thru (do()'s repetition()'s deferAnother("daily")'s getContents())	
	command thru (rename(textutil's replaceChars(taskName(), aToken, "")))
end script
*)
(*
script ExpiredMeetingPreparationRule
	property parent : Rule(me)
	
	--Conditions
	match by (incomplete())
	match by (dueDate()'s isBefore()'s now())
	matchAny by { ¬
		taskName()'s match()'s token("|GC| Prepare for your meeting")'s anyText(), ¬
		taskName()'s match()'s token("|GC| Prepare for your recurring meeting")'s anyText() }
--	match by (project()'s projectName()'s sameAs("Meetings to plan")'s anyText())	

	--Actions
	command thru (markComplete())
end script
*)

--script MarkCompletePastDueTasks
script |Mark complete any past due tasks|
	property parent : Rules's RuleBase
	property name : "Mark complete past due tasks"
		
--	match by (dueDate()'s isBefore(current date)'s getContents())
	match by (taskName()'s startsWith("Prepare for your recurring meeting")'s getContents())
--	set aDate to current date
	match by (dueDate()'s isBefore(current date)'s getContents())
	
	command thru markCompleted()
end script

script ProcessBcc
	property parent : Rules's RuleBase
	property name : "Process Bcc"
	
	match by (taskName()'s startsWith("Re:")'s getContents())

	command thru (do()'s taskName()'s prepend("Follow up ")) 
end script

script InboxConfigScript
	property parent : RuleSet(me)
	property name : "Process Inbox Tasks"
	property target : Rules's Inbox
	
	evaluate by EvernoteTaskClonePreparationRule
--	evaluate by cf's EvernoteTaskClonePreparationRule
	evaluate by cf's OmniFocusTransportTextParsingRule
	evaluate by cf's TidyConsiderationsRule
	evaluate by cf's AddDailyRepeatRule
	evaluate by cf's ExpiredMeetingPreparationRule
	evaluate by cf's ExpiredCheckMeetingParticipationRule	
end script

script MeetingsToPlanScript
	property parent : RuleSet(me)
	property name : "Meetings to Plan"
	property target : target()'s project("Meetings to plan")
	
	evaluate by cf's ExpiredMeetingPreparationRule		
--	evaluate by cf's ExpiredCheckMeetingParticipationRule	
--	evaluate by |Mark complete any past due tasks|
end script

