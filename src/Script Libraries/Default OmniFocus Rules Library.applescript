use AppleScript version "2.4"
use scripting additions

use ddd : script "com.kraigparkinson/ASDomainDrivenDesign"
use domain : script "com.kraigparkinson/OmniFocusDomain"
use rules : script "com.kraigparkinson/Hobson"


(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's name. *)
property name : "Default OmniFocus Rules Library"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's id. *)
property id : "com.kraigparkinson.Default OmniFocus Rules Library"

---------------------------
-- Rules inspired by Kourosh Dini's Creating Flow with OmniFocus --
---------------------------

script AddDailyRepeatRule
	property parent : rules's makeRuleBase()
	property name : "Add Daily Repeat"
	
	set aToken to " (Add daily repeat)"
	match by (taskName()'s doesContain(aToken)'s getContents())
	
	command thru (do()'s repetition()'s deferAnother("DAILY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script AddWeeklyRepeatRule
	property parent : rules's makeRuleBase()
	property name : "Add Weekly Repeat"
	
	set aToken to " (Add weekly repeat)"
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

---------------------------
-- Rules based on needs to leverage more liberal date processing from Zapier. --
---------------------------

script EvernoteTaskClonePreparationRule
	property parent : rules's makeRuleBase()
	property name : "Prepare tasks from TaskClone for processing"
	
	set token to "|EN|"	
	match by (taskName()'s startsWith(token)'s getContents())
	
	command thru (do()'s taskName()'s replace(token & space, "--")'s getContents())
	command thru (do()'s taskName()'s append(space & token)'s getContents())
end script

script ExpiredMeetingPreparationRule
	property parent : rules's makeRuleBase()
	property name : "Process expired meeting preparation tasks"
	
	--Conditions
--	set aSpec to HasChildrenSpecification's constructSpecification()'s notSpec()
--	match by (isChildless())
	match by (complete()'s isFalse())
	match by (dueDate()'s isBefore(current date))
	
	--matchAny by { ¬
	--		taskName()'s match()'s token("|GC| Prepare for your meeting")'s anyText(), ¬
	--		taskName()'s match()'s token("|GC| Prepare for your recurring meeting")'s anyText() }
	match by ¬
		taskName()'s startsWith("|GC| Prepare for your meeting")'s getContents()'s orSpec(¬
			taskName()'s startsWith("|GC| Prepare for your recurring meeting")'s getContents())
	
	--Actions
	command thru (markCompleted())
end script

script ExpiredCheckMeetingParticipationRule
	property parent : rules's makeRuleBase()
	property name : "Process expired preparation tasks for recurring meetings"
		
	match by (taskName()'s startswith("Check participation for your recurring meeting")'s getContents())
	match by (dueDate()'s isBefore(current date)'s getContents())
	
	command thru (markCompleted())		
end script

script OmniFocusTransportTextParsingRule
	property parent : rules's makeRuleBase()
	property name : "Parse task names containing transport text"
	
	script EvaluatorCommand
		property parent : domain's CommandFactory's TaskCommand
		
		on execute(aTask)
			set oftt to domain's TransportTextParsingService
			
			set aService to oftt's OmniFocusTransportTextService
		
			tell aService to updateTaskPropertiesFromName(aTask)
		end execute
	end script
		
	match by (taskName()'s startsWith("--")'s getContents())
	
	command thru (EvaluatorCommand)
end script
