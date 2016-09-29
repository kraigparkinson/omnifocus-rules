--use AppleScript version "2.4"
--use scripting additions

property ddd : script "com.kraigparkinson/ASDomainDrivenDesign"
property domain : script "com.kraigparkinson/OmniFocusDomain"
property rules : script "com.kraigparkinson/Hobson"


(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's name. *)
property name : "Default OmniFocus Rules Library"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> Creating Flow with OmniFocus's id. *)
property id : "com.kraigparkinson.Default OmniFocus Rules Library"


script TidyConsiderationsRule
	property parent : rules's RuleBase
	property class : "TidyConsiderationsRule"
	
	on prettyName()
		return "Tidy Considerations Rule"
	end prettyName
		
	match by (taskName()'s startsWith("Consider ")'s getContents())
	match by (context()'s missing()'s getContents())
	
	command thru (setContext("Considerations"))
	command thru (do()'s repetition()'s deferAnother("DAILY")'s getContents())
end script

script AddDailyRepeatRule
	property parent : rules's RuleBase
	property class : "AddDailyRepeatRule"
	
	on prettyName()
		return "Add Daily Repeat Rule"
	end prettyName
		
	set aToken to " (Add daily repeat)"
	match by (taskName()'s endsWith(aToken)'s getContents())
	
	command thru (do()'s repetition()'s deferAnother("DAILY")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script

script AddWeeklyRepeatRule
	property parent : rules's RuleBase
	property class : "AddWeeklyRepeatRule"
	
	on prettyName()
		return "Add Weekly Repeat Rule"
	end prettyName
		
	set aToken to " (Add weekly repeat)"
	match by (taskName()'s endsWith(aToken)'s getContents())
	
	command thru (do()'s repetition()'s deferAnother("weekly")'s getContents())
	command thru (do()'s taskName()'s replace(aToken, "")'s getContents())
	
end script
script ExpiredMeetingPreparationRule
	property parent : rules's RuleBase
	property class : "ExpiredMeetingPreparationRule"
	
	on prettyName()
		return "Expired Meeting Preparation Rule"
	end prettyName
		
	set aSpec to taskName()'s startsWith("Prepare for your meeting")'s getContents()
	set aSpec to aSpec's orSpec(taskName()'s startsWith("Prepare for your recurring meeting")'s getContents())
	match by (aSpec)
	match by (dueDate()'s isBefore(current date)'s getContents())

	--	set aSpec to HasChildrenSpecification's constructSpecification()'s notSpec()
	--	match by (aSpec)
	
	command thru (markCompleted())
end script

script ExpiredCheckMeetingParticipationRule
	property parent : rules's RuleBase
	property class : "ExpiredCheckMeetingParticipationRule"
	
	on prettyName()
		return "Expired Check Meeting Participation Rule"
	end prettyName
	
	match by (taskName()'s startswith("Check participation for your recurring meeting")'s getContents())
	match by (dueDate()'s isBefore(current date)'s getContents())
	
	command thru (markCompleted())		
end script

script EvernoteTaskClonePreparationRule
	property parent : rules's RuleBase
	property class : "EvernoteTaskClonePreparationRule"
	
	on prettyName()
		return "Evernote TaskClone Preparation Rule"
	end prettyName
		
	set token to "|EN|"
	
	match by (taskName()'s startsWith(token)'s getContents())
	
	command thru (do()'s taskName()'s replace(token & space, "--")'s getContents())
	command thru (do()'s taskName()'s append(space & token)'s getContents())
end script

script ProjectTarget
	property parent : rules's OmniFocusRuleTarget
	property projectName : missing value 

	on defineName()
		return "Project: Meetings to Prepare"
	end defineName
	
	on getTasks()
		set aProject to domain's ProjectRepository's findByName(projectName)
		set theTasks to domain's taskRepositoryInstance()'s selectTasksFromProject(aProject)
				
		return theTasks
	end getTasks

end script

script MeetingsToPrepareTarget
	property parent : rules's OmniFocusRuleTarget
	
	on defineName()
		return "Project: Meetings to Prepare"
	end defineName
	
	on getTasks()
		set aProject to domain's ProjectRepository's findByName("Meetings to plan")
		set theTasks to domain's taskRepositoryInstance()'s selectTasksFromProject(aProject)
		
		return theTasks
	end getTasks
end script

script OmniFocusTransportTextParsingRule
	property parent : rules's RuleBase
	property class : "OmniFocusTransportTextParsingRule"
	
	on prettyName()
		return "OmniFocus Transport Text Parsing Rule"
	end prettyName
	
	script EvaluatorCommand
		property parent : domain's TaskCommand
		
		on execute(aTask)
			set oftt to domain's TransportTextParsingService
			
			set aService to oftt's OmniFocusTransportTextService
		
			tell aService to updateTaskPropertiesFromName(aTask)
		end execute
	end script
		
	match by (taskName()'s startsWith("--")'s getContents())
	
	command thru (EvaluatorCommand's constructCommand())
end script
