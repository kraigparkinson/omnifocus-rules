#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

use Rules : script "com.kraigparkinson/Hobson"

property parent : Rules

--property suite : Rules's makeRuleSuite("Creating Flow with OmniFocus")

on run argv
	continue run argv
end run

---------------------------
-- Rules inspired by Kourosh Dini's Creating Flow with OmniFocus --
---------------------------

script AddDailyRepeatRule
	property parent : rules's makeRuleBase()
	property name : "Add Daily Repeat"
	
	set aToken to " (Add daily repeat)"
	match by (taskName()'s doesContain(aToken)'s getContents())
	
	command thru (do()'s repetition()'s repeatEvery("DAILY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script AddDailyDeferRule
	property parent : rules's makeRuleBase()
	property name : "Add Daily Defer"
	
	set aToken to " (Add daily defer)"
	match by (taskName()'s doesContain(aToken)'s getContents())
	
	command thru (do()'s repetition()'s deferAnother("DAILY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script AddWeeklyRepeatRule
	property parent : rules's makeRuleBase()
	property name : "Add Weekly Repeat"
	
	set aToken to " (Add weekly repeat)"
	match by (taskName()'s doesContain(aToken)'s getContents())
	
	command thru (do()'s repetition()'s repeatEvery("WEEKLY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script AddWeeklyDeferRule
	property parent : rules's makeRuleBase()
	property name : "Add Weekly Defer"
	
	set aToken to " (Add weekly defer)"
	match by (taskName()'s doesContain(aToken)'s getContents())
	
	command thru (do()'s repetition()'s deferAnother("WEEKLY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script TidyConsiderationsRule
	property parent : rules's makeRuleBase()
	property name : "Tidy considerations"
	
	--Conditions
	match by (taskName()'s startsWith("Consider")'s getContents())
	match by (context()'s missing()'s getContents())

	--Actions
	command thru (setContext("Considerations"))
end script

script ConvertToDropRule
	property parent : rules's makeRuleBase()
	property name : "Mark expired @Waiting For tasks complete"
	
	match by (taskName()'s match()'s ¬
		l("[(]")'s ¬
		customDate(setDateAttr("conversion date")'s aShortDate())'s ¬
		l(" -> DROP[)] Waiting for response from ")'s ¬
		customText(setTextAttr("person")'s anyText())'s ¬
		l(" re: ")'s ¬
		customText(setTextAttr("expectation")'s anyText())'s getContents())

	match by getDateAttr("conversion date")'s isBefore(current date)'s getContents()
	
	command thru (markCompleted())	
	command thru (do()'s changeNote()'s prepend("INFO: This task was automatically marked complete by Hobson." & linefeed & linefeed)'s getContents())
end script

