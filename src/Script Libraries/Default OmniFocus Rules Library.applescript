use AppleScript version "2.4"
use scripting additions

use domain : script "com.kraigparkinson/OmniFocusDomain"
use rules : script "com.kraigparkinson/Hobson"


(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's name. *)
property name : "Default OmniFocus Rules Library"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's id. *)
property id : "com.kraigparkinson.Default OmniFocus Rules Library"


---------------------------
-- Rules based on Zapier generated tasks. --
---------------------------

script EvernoteTaskClonePreparationRule
	property parent : rules's makeRuleBase()
	property name : "Prepare tasks from TaskClone for processing"
	
	set token to "|EN|"	
	match by (taskName()'s startsWith(token)'s getContents())
	
	command thru (do()'s taskName()'s replace(token & space, "--")'s getContents())
	command thru (do()'s changeNote()'s prepend("INFO: This task was generated from Evernote via TaskClone." & linefeed & linefeed)'s getContents())
end script

script ExpiredMeetingPreparationRule
	property parent : rules's makeRuleBase()
	property name : "Process expired meeting preparation tasks"
	
	--Conditions
	match by (complete()'s isFalse()'s getContents())
	match by (dueDate()'s isBefore(current date)'s getContents())
	
	match by (taskName()'s startsWith("Prepare for your meeting")'s getContents())
	
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

---------------------------
-- Rules based on needs to leverage more liberal date processing from Zapier. --
---------------------------

script OmniFocusTransportTextParsingRule
	property parent : rules's makeRuleBase()
	property name : "Parse task names containing transport text"
	
	script EvaluatorCommand
		property parent : domain's CommandFactory's TaskCommand
		
		on execute(aTask)
			set aService to domain's TransportTextParsingService
		
			tell aService to updateTaskPropertiesFromName(aTask)
		end execute
	end script
		
	match by (taskName()'s startsWith("--")'s getContents())
	
	command thru (EvaluatorCommand)
end script
