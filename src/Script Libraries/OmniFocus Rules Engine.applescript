use AppleScript version "2.4"
use scripting additions

(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's name. *)
property name : "OmniFocus Rules Engine"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's id. *)
property id : "com.kraigparkinson.OmniFocus Rules Engine"

--use OmniFocus : application "OmniFocus"
--use domain : script "com.kraigparkinson/OmniFocusDomain"

property textutil : script "com.kraigparkinson/ASText"
property dateutil : script "com.kraigparkinson/ASDate"
property ddd : script "com.kraigparkinson/ASDomainDrivenDesign"
property domain : script "com.kraigparkinson/OmniFocusDomain"

property _ruleRepository : missing value

script TaskProxy
	property originalTask : missing value
	property timeoutValue : 3
	
	on newTaskProxy(aTask)
		copy TaskProxy to aProxy
		set aProxy's originalTask to aTask
		return aProxy
	end newTaskProxy
	
	on getName()
		tell application "OmniFocus"
			with timeout of timeoutValue seconds
				return originalTask's name
			end timeout
		end tell
	end getName
	
	on setName(newName)
		tell application "OmniFocus"
			with timeout of timeoutValue seconds
				set originalTask's name to newName
			end timeout
		end tell
	end setName
end script

script RuleSentinel
	property parent : AppleScript
end script

on makeRuleLoader()
	script RuleLoader
	
		on isSatisfiedBy(aScript)
			return (aScript's suite is not my RuleSentinel)
		end isSatisfiedBy
	
		(*! @abstract Raises a missing suite error. *)
		on MissingSuiteError(sourceName)
			error sourceName & " does not have a suite property"
		end MissingSuiteError
	
		on loadRulesFromScript(aScript)
			set aSuite to aScript's suite
			if not isSatisfiedBy(aScript) then MissingSuiteError(aScript's name)
			return aSuite
		end loadRulesFromScript
		
		on loadRulesFromFile(aFile)
			set aScript to load script aFile --file (aFile as text)
			return loadRulesFromScript(aScript)
		end loadRulesFromFile
		
		on validateScript(aScript)
			set aSuite to aScript's suite
			if aScript's suite is my RuleSentinel then MissingSuiteError(aScript's name)
			return aSuite
		end validateScript
		
		
	end script
	
	return RuleLoader
end makeRuleLoader

on makeRuleSuite(aName)
	script 
		property name : aName
		property ruleSets : { }
		
		on addRuleSet(aRuleSet)
			log "Adding rule set: " & aRuleSet's name
			set end of ruleSets to aRuleSet
		end addRuleSet		
		
		on exec()
			
			
			log "Starting to execute rules for suite: " & name
			
			repeat with aSet in ruleSets
				log "Starting to prepare rule set for processing: " & aSet's name
				tell aSet to run
				log "Finished preparing rule set for processing: " & aSet's name
				
				log "Starting to process rule set: " & aSet's name
				tell aSet's target's construct() to accept(aSet's rules) 
--				tell aSet's target to accept(aSet's rules) 
				log "Finished processing rule set: " & aSet's name

			end repeat

			tell application "OmniFocus" to compact

			log "Finished executing rules for suite: " & name

(*			
			log "evaluate called with rule: " & aRuleType's prettyName()
			set aRule to aRuleType's constructRule()
		
			set aTarget to my target's construct()
		
			tell aTarget to accept({aRule})
*)			
		end exec
	end 
	
	return the result
end makeRuleSuite

script RuleSetBase
	property ruleSets : {}
	property target : missing value
		
	on addRuleSet(aRuleSet)
		set aSuite to aRuleSet's parent's suite			
		tell aSuite to addRuleSet(aRuleSet)
		log "Added rule set: " & aRuleSet's name & " to rule suite: " & aSuite's name
	end addRuleSet
	
end script

on makeRuleSet()
	script _RuleSet
		property parent : RuleSetBase
		property name : missing value 
		property rules : { }
	
		on evaluate by aRuleType
			
			if (aRuleType's name is missing value) then 
				set ruleName to aRuleType's class
			else 
				set ruleName to aRuleType's name
			end if 
			
			log "Adding rule to evaluate: " & ruleName
			
			set aRule to aRuleType's constructRule()
--			set aRule to aRuleType
			--Initialize the actions and commands from the rule			
			tell aRule to run
			
			set end of rules to aRule
		end evaluate		
	end script

	return _RuleSet	
end makeRuleSet

on RuleSet(aRuleSet)
	RuleSetBase's addRuleSet(aRuleSet)

	return makeRuleSet()
end makeRuleSet

script OmniFocusTaskProcessingRule	
	property name : missing value

	on constructRule()
		copy me to aRule
		return aRule
	end constructRule

	on prettyName()
		return name
	end prettyName

	(*
	@pre aTask must be an OmniFocus task
	@post Returns boolean or record
	*)
	on matchTask(aTask, inputAttributes)
	end matchTask
	
	(*
	@post Throws error if there's a problem processing rule.
	*)
	on processTask(aTask, inputAttributes)
	end processTask
	
	on accept(tasks)
		
		set taskIndex to 1
		repeat with aTask in tasks
			log "[" & prettyName() & "]" & "Processing task" & space & taskIndex & space & "of" & space & count of tasks
			
			set inputAttributes to { }
	
			set taskIsMatched to false

			try
				set matchResult to matchTask(aTask, inputAttributes)
	
				if (matchResult's class is boolean) 
					log "[" & prettyName() & "]" & "Match result: " & matchResult
					if (matchResult) 
						set taskIsMatched to true
					end if
				else if (matchResult's class is record)
					log "[" & prettyName() & "]" & "Match result: " & matchResult's passesCriteria
					
					if (matchResult's passesCriteria)
						set taskIsMatched to true
						set inputAttributes to matchResult's outputAttributes
					end if
				else 
					error "[" & prettyName() & "]" & "Unrecognized response from matching handler: " & matchResult
				end if
			
			on error message
				log "[" & prettyName() & "] Error occurred matching rule: " & message
			end try
		
			
			if (taskIsMatched)
				log "[" & prettyName() & "]" & "Processing commands."
						
				try
					set processResult to processTask(aTask, inputAttributes)
						
					if (processResult is not missing value and processResult's class is record)
						if (ruleStop of processResult) then 
							log "[" & prettyName() & "]" & "Rule ended task processing prematurely."						
							exit repeat
						end if
					else 
						log "[" & prettyName() & "]" & "Finished processing task."
					end if 
										
				on error message 
					log "[" & prettyName() & "] Error occurred processing rule: " & message
				end try				
			end if
			
			set taskIndex to taskIndex + 1
		end repeat		
	end accept
	
end script

script ValueRetrievalStrategy
	on getValue(obj)
		return obj
	end getValue
end script

script TaskNameRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return TaskProxy's newTaskProxy(aTask)'s getName()		
	end getValue
end script

script ContextNameRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		tell application "OmniFocus"
			with timeout of 3 seconds
				return aTask's context's name
			end timeout
		end tell
	end getValue
end script

script DueDateRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		tell application "OmniFocus"
			with timeout of 3 seconds
				return aTask's due date
			end timeout
		end tell
	end getValue
end script

script DeferDateRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		tell application "OmniFocus"
			with timeout of 3 seconds
				return aTask's defer date
			end timeout
		end tell
	end getValue
end script

script TextSpecification
	property parent : ddd's AbstractSpecification
	property sourcingStrategy : missing value
	property validationStrategy : missing value
	property name : "TextSpecification"
	
	script TextValidationStrategy
		on matchesText(actual)
		end matchesText
	end 
	
	on make new TextSpecification with properties specProps as record
		if (specProps is missing value) then error "Can't create TextSpecification with missing properties"
		
		if (specProps's sourcingStrategy is missing value) then error "TextSpecification properties should have a sourcingStrategy."
		if (specProps's validationStrategy is missing value) then error "TextSpecification properties should have a validationStrategy."
		
		copy TextSpecification to aSpec
		set aSpec's sourcingStrategy to specProps's sourcingStrategy
		set aSpec's validationStrategy to specProps's validationStrategy
		
		return aSpec		
	end make
	
	on isSatisfiedBy(obj)
		if (sourcingStrategy is missing value) then error "TextSpecification's isSatisfiedBy(obj): missing sourcingStrategy"
		return validationStrategy's matchesText(sourcingStrategy's getValue(obj))
	end isSatisfiedBy

	on sameAsSpecification(expected, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return expected equals actual
			end matchesText
		end script
	
		set validation to the result
		set aSpec to make new TextSpecification with properties { sourcingStrategy:textFetcher, validationStrategy:validation }
		set aSpec's name to "same as " & expected
		return aSpec
	end sameAsSpecification
	
	on startsWithSpecification(startsWithText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual starts with startsWithText
			end matchesText
		end script
	
		set validation to the result
		set aSpec to make new TextSpecification with properties { sourcingStrategy:textFetcher, validationStrategy:validation }
		set aSpec's name to "starts with >>" & startsWithText & "<<"
		return aSpec
	end startsWithSpecification

	on endsWithSpecification(endsWithText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual ends with endsWithText
			end matchesText
		end script
	
		set validation to the result
		set aSpec to make new TextSpecification with properties { sourcingStrategy:textFetcher, validationStrategy:validation }
		set aSpec's name to "ends with >>" & endsWithText & "<<"
		return aSpec
	end endsWithSpecification
	
	on containsSpecification(containedText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual contains containedText
			end matchesText
		end script
	
		set validation to the result
		set aSpec to make new TextSpecification with properties { sourcingStrategy:textFetcher, validationStrategy:validation }
		set aSpec's name to "contains >>" & containedText & "<<"
		return aSpec
	end containsSpecification

end script

script DateSpecification
	property parent : ddd's AbstractSpecification
	property referenceValue : missing value
	property sourcingStrategy : missing value
	property validationStrategy : missing value
	property name : "DateSpecification"
	
	script DateValidationStrategy
		on validateDate(actual)
		end validateDate
	end 
	
	on make new DateSpecification with properties specProps as record
		if (specProps is missing value) then error "Can't create DateSpecification with missing properties"
		
		copy DateSpecification to aSpec
		set aSpec's referenceValue to specProps's referenceValue
		set aSpec's sourcingStrategy to specProps's dateRetrievalStrategy
		set aSpec's validationStrategy to specProps's validationStrategy
		
		return aSpec		
	end make
	
	on isSatisfiedBy(obj)
		set expected to referenceValue
		set actual to sourcingStrategy's getValue(obj)
		
		return validationStrategy's validateDate(actual)
	end isSatisfiedBy

	on sameAsSpecification(expected, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				return expected equals actual
			end validateDate
		end script
	
		set validation to the result

		set aSpec to make new DateSpecification with properties { referenceValue:expected, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "same as " & expected
		return aSpec
	end sameAsSpecification
	
	on isBeforeSpecification(referenceDate, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				set isValid to (actual comes before referenceDate)
				log "Does actual: " & actual & " comes before: " & referenceDate & "? " & isValid
				return isValid
			end validateDate
		end script
	
		set validation to the result
		set aSpec to make new DateSpecification with properties { referenceValue:referenceDate, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "is before " & referenceDate
		return aSpec
	end isBeforeSpecification

	on isAfterSpecification(referenceDate, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				return actual comes after referenceDate
			end validateDate
		end script
	
		set validation to the result
		set aSpec to make new DateSpecification with properties { referenceValue:referenceDate, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "is after " & referenceDate
		return aSpec
	end isAfterSpecification
	
	on inTheNextSpecification(specifiedDays, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				set referenceCalDate to (dateutil's CalendarDate's create on current date)'s increment by specifiedDays
				set dateDifference to (referenceCalDate's asDate() - actual) / days
				
				return (dateDifference ≤ specifiedDays) and (dateDifference > 0)
			end validateDate
		end script
	
		set validation to the result
		set aSpec to make new DateSpecification with properties { referenceValue:specifiedDays, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "in the next " & specifiedDays & " days"
		return aSpec
	end inTheNextSpecification

	on inTheLastSpecification(specifiedDays, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				set referenceCalDate to (dateutil's CalendarDate's create on current date)'s increment by -specifiedDays
				set dateDifference to (actual - referenceCalDate's asDate()) / days
				
				return (dateDifference ≤ specifiedDays) and (dateDifference > 0)
			end validateDate
		end script
	
		set validation to the result
		set aSpec to make new DateSpecification with properties { referenceValue:specifiedDays, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "in the last " & specifiedDays & " days"
		return aSpec
	end inTheLastSpecification

	on missingSpecification(dateFetcher)
		script 
			property parent : DateValidationStrategy
			property name : "is missing"
			
			on validateDate(actual)
				return actual is missing value
			end validateDate
		end script
	
		set validation to the result
		set aSpec to make new DateSpecification with properties { referenceValue:missing value, dateRetrievalStrategy:dateFetcher, validationStrategy:validation }
		set aSpec's name to "missing date"
		return aSpec
	end missingSpecification
	
end script

script MatchesTextSpecification
	property parent : ddd's AbstractSpecification
	property referenceText : missing value
	property sourcingStrategy : missing value
	property name : missing value
	
	on make new MatchesTextSpecification with properties conditionProps as record
		if (conditionProps is missing value) then error "Can't create MatchesTextSpecification with missing properties"
		
		copy MatchesTextSpecification to aCondition
		set aCondition's referenceText to conditionProps's referenceText
		set aCondition's sourcingStrategy to conditionProps's sourcingStrategy
		set aCondition's name to "matches text (" & aCondition's referenceText & ") from (" & (aCondition's sourcingStrategy's name) & ")"
			
		return aCondition		
	end make	
	
	on isSatisfiedBy(obj)
		return sourcingStrategy's getValue(obj) contains referenceText
	end isSatisfiedBy
end script

script TrueSpecification
	property parent : ddd's AbstractSpecification
	property name : "true"
	
	on isSatisfiedBy(obj)
		return true
	end isSatisfiedBy
end script

script TextSpecificationBuilder
	property textStrategy : missing value

	property sameAsText : missing value
	property notSameAsText : missing value
	property startingWithText : missing value
	property notStartingWithText : missing value
	property endingWithText : missing value
	property notEndingWithText : missing value
	property containedText : missing value
	property notContainedText : missing value
	property pattern : missing value

	on make new TextSpecificationBuilder with data aTextStrategy
		copy TextSpecificationBuilder to aBuilder
		set aBuilder's textStrategy to aTextStrategy
		return aBuilder
	end make
	
	on sameAs(referenceText as text)
		set sameAsText to referenceText
		return me
	end sameAs
	
	on notSameAs(referenceText as text)
		set notSameAsText to referenceText
		return me
	end notSameAs
	
	on startsWith(referenceText as text)
		set startingWithText to referenceText
		return me
	end startsWith
	
	on doesNotStartWith(referenceText as text)
		set notStartingWithText to referenceText
		return me
	end doesNotStartWith

	on endsWith(referenceText as text)
		set endingWithText to referenceText
		return me
	end endsWith
	
	on doesNotEndWith(referenceText as text)
		set notEndingWithText to referenceText
		return me
	end doesNotEndWith
	
	on doesContain(referenceText as text)
		set containedText to referenceText
		return me
	end doesContain
	
	on doesNotContain(referenceText as text)
		set notContainedText to referenceText		
		return me
	end doesNotContain
	
	on getContents()
		if (textStrategy is missing value) then error "Text strategy is missing."
		set aCondition to TrueSpecification
		
		if (sameAsText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's sameAsSpecification(sameAsText, textStrategy))
		if (notSameAsText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's sameAsSpecification(notSameAsText, textStrategy)'s notSpec())
		if (startingWithText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's startsWithSpecification(startingWithText, textStrategy))
		if (notStartingWithText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's startsWithSpecification(notStartingWithText, textStrategy)'s notSpec())
		if (endingWithText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's endsWithSpecification(endingWithText, textStrategy))
		if (notEndingWithText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's endsWithSpecification(notEndingWithText, textStrategy)'s notSpec())
		if (containedText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's containsSpecification(containedText, textStrategy))
		if (notContainedText is not missing value) then set aCondition to aCondition's andSpec(TextSpecification's containsSpecification(notContainedText, textStrategy)'s notSpec())
		
		return aCondition
	end getContents
	
	on reset()
		set sameAsText to missing value
		set notSameAsText to missing value
		set startingWithText to missing value
		set notSameAsText to missing value
		set endingWithText to missing value
		set notEndingWithText to missing value
		set containedText to missing value
		set notContainedText to missing value
	end reset
	
end script

script DateConditionBuilder
	property dateStrategy : missing value

	property sameAsDate : missing value
	property notSameAsDate : missing value
	property isBeforeDate : missing value
	property isAfterDate : missing value
	property inTheLastDays : missing value
	property notInTheLastDays : missing value
	property inTheNextDays : missing value
	property notInTheNextDays : missing value
	property isMissingValue : missing value

	on make new DateConditionBuilder with data dateStrategy
		copy DateConditionBuilder to aBuilder
		set aBuilder's sameAsDate to missing value
		set aBuilder's notSameAsDate to missing value
		set aBuilder's isBeforeDate to missing value
		set aBuilder's isAfterDate to missing value
		set aBuilder's inTheLastDays to missing value
		set aBuilder's notInTheLastDays to missing value
		set aBuilder's inTheNextDays to missing value
		set aBuilder's notInTheNextDays to missing value
		set aBuilder's isMissingValue to missing value
		
		set aBuilder's dateStrategy to dateStrategy
		return aBuilder
	end make
	
	on sameAs(matchingDate as date)
		set sameAsdate to matchingDate
		return me
	end sameAs
	
	on notSameAs(matchingDate as date)
		set notSameAsDate to matchingDate
		return me
	end notSameAs
	
	on isBefore(matchingDate as date)
		set isMissingValue to false
		set isBeforeDate to matchingDate
		return me
	end isBefore
	
	on isAfter(matchingDate as date)
		set isMissingValue to false
		set isAfterDate to matchingDate
		return me
	end isAfter

	on inTheLast(matchingDate as date)
		set isMissingValue to false
		set inTheLastDays to matchingDate
		return me
	end inTheLast
	
	on notInTheLast(matchingDate as date)
		set isMissingValue to false
		set notInTheLastDays to matchingDate
		return me
	end notInTheLast
	
	on inTheNext(matchingDate as date)
		set isMissingValue to false
		set inTheNextDays to matchingDate
		return me
	end inTheNext
	
	on notInTheNext(matchingDate as date)
		set isMissingValue to false
		set notInTheNextDays to matchingDate
		return me
	end notInTheNext
	
	on missing()
		set isMissingValue to true
		return me
	end missing
	
	on notMissing()
		set isMissingValue to false
		return me
	end notMissing
	
	on getContents()
		set aCondition to TrueSpecification
		
		if (isMissingValue is not (missing value)) then 
			if (isMissingValue) then 
				set aCondition to aCondition's andSpec(DateSpecification's missingSpecification(dateStrategy))
			else 
				set aCondition to aCondition's andSpec(DateSpecification's missingSpecification(dateStrategy)'s notSpec())
			end if 
		end if 
		
		if (sameAsDate is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's sameAsSpecification(sameAsDate, dateStrategy))
		if (notSameAsDate is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's sameAsSpecification(notSameAsDate, dateStrategy)'s notSpec())
		if (isBeforeDate is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's isBeforeSpecification(isBeforeDate, dateStrategy))
		if (isAfterDate is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's isAfterSpecification(isAfterDate, dateStrategy))
		if (inTheLastDays is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's inTheLastSpecification(inTheLastDays, dateStrategy))
		if (notInTheLastDays is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's inTheLastSpecification(notInTheLastDays, dateStrategy)'s notSpec())
		if (inTheNextDays is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's inTheNextSpecification(inTheNextDays, dateStrategy))
		if (notInTheNextDays is not missing value) then set aCondition to aCondition's andSpec(DateSpecification's inTheNextSpecification(notInTheNextDays, dateStrategy)'s notSpec())

		return aCondition
	end getContents
	
end script

script ContextConditionBuilder
--	property parent : TextSpecificationBuilder
	property missingContext : missing value
	property nameConditionBuilder : missing value


	on contextName() 
		tell TextSpecificationBuilder
			set nameConditionBuilder to make new TextSpecificationBuilder with data ContextNameRetrievalStrategy
		end tell
		return nameConditionBuilder
	end contextName
	
	on missing()
		set missingContext to true
		return me
	end missing
	
	on notMissing()
		set missingContext to false
		return me
	end notMissing
	
	on getContents()
		set aCondition to TrueSpecification
		
		if (nameConditionBuilder is not missing value) then set aCondition to aCondition's andSpec(nameConditionBuilder's getContents())
		
		if (missingContext is not missing value) then 
			
			set aSpec to domain's TaskHasContextSpecification
			
			if (missingContext) then set aSpec to aSpec's notSpec()
			
			set aCondition to aCondition's andSpec(aSpec)
		end if 
		
		return aCondition
	end getContents
	
end script

script ConditionalCommandRule	
	property parent : OmniFocusTaskProcessingRule
	property conditions : { }
	property actions : { }
	
	on constructRule()
		set aRule to continue constructRule()
		set aRule's conditions to { }
		set aRule's actions to { }
		return aRule
	end constructRule
	
	on match by aSpec
		addCondition(aSpec)
	end match
	
	on addCondition(aSpec)
		log "[" & prettyName() & "]" & "Adding condition: " & aSpec's name
		set conditions's end to aSpec
	end addCondition
	
	on command thru aCommand
		addAction(aCommand)
	end command
	
	on addAction(aCommand)
		try
			log "[" & prettyName() & "]" & "Adding action: " & aCommand's name
			set actions's end to aCommand
		on error errMsg
			log "Error!" & errMsg
		end try
	end addAction
	
	(*
	@post Returns boolean or record
	*)
	on matchTask(aTask, inputAttributes)
		--Implement all
		set satisfiedConditions to 0
		
		log "[" & prettyName() & "]" & "Preparing to evaluate " & count of conditions & " conditions."
		repeat with condition in conditions
			log "[" & prettyName() & "]" & "Evaluating condition: " & condition's name
			set matchResult to condition's isSatisfiedBy(aTask)
			
			if (matchResult's class is boolean)
				log "[" & prettyName() & "]" & "Task meets condition: " & matchResult
			
				if (matchResult) then set satisfiedConditions to satisfiedConditions + 1
			else if (matchResult's class is record)
				log "[" & prettyName() & "]" & "Task meets conditions: " & matchResult's passesCriteria
				if (matchResult's passesCriteria) then
					set satisfiedConditions to satisfiedConditions + 1					
					set inputAttributes to inputAttributes & matchREsult's outputAttributes
				end if 
			end 
		end repeat
		
		set matched to (satisfiedConditions equals count of conditions)
		log "[" & prettyName() & "]" & "Finished evaluating conditions for rule. Result: " & matched
		return matched
	end matchTask
	
	(*
	@post Throws error if there's a problem processing rule.
	*)
	on processTask(aTask, inputAttributes)
		log "[" & prettyName() & "]" & "Preparing to execute " & count of actions & " commands on task."
		repeat with anAction in actions
			log "[" & prettyName() & "]" & "Executing command: " & anAction's name
			tell anAction to execute(aTask)
		end repeat
		log "[" & prettyName() & "]" & "Finished executing commands on task."
		return true
	end processTask
end script

script SetTaskNameCommand
	property parent : domain's TaskCommand
	property newTaskName : missing value

	on execute(aTask)
		local taskName
		
		set aTaskProxy to TaskProxy's newTaskProxy(aTask)
		tell aTaskProxy to setName(newTaskName)
	end execute
end script 

script StripTokenFromTaskNameCommand
	property parent : domain's TaskCommand
	property token : missing value
	
	on execute(aTask)
		local taskName
		
		set aTaskProxy to TaskProxy's newTaskProxy(aTask)
		set taskName to aTaskProxy's getName()
		
		tell textutil
			set originalTaskNameStr to textutil's StringObj's makeString(taskName)
			set revisedTaskNameStr to originalTaskNameStr's removeText(token)
			set revisedTaskName to revisedTaskNameStr's asText()
		end tell

		tell aTaskProxy to setName(revisedTaskName)
	end execute
		
end script

script ReplaceTokenFromTaskNameCommand
	property parent : domain's TaskCommand
	property findToken : missing value
	property replaceToken : missing value
	
	on execute(aTask)
		local taskName
		
		set aTaskProxy to TaskProxy's newTaskProxy(aTask)
		set taskName to aTaskProxy's getName()
		
		set revisedTaskName to textutil's StringObj's makeString(taskName)'s replaceText(findToken, replaceToken)'s asText()

		tell aTaskProxy to setName(revisedTaskName)
	end execute
end script

script AppendTextToTaskNameCommand
	property parent : domain's TaskCommand
	property textToAppend : missing value
	
	on execute(aTask)
		local taskName

		set aTaskProxy to TaskProxy's newTaskProxy(aTask)
		set taskName to aTaskProxy's getName()
		
		set revisedTaskName to taskName & textToAppend
		tell aTaskProxy to setName(revisedTaskName)
	end execute
end script

script PrependTextToTaskNameCommand
	property parent : domain's TaskCommand
	property textToPrepend : missing value
	
	on execute(aTask)
		local taskName

		set aTaskProxy to TaskProxy's newTaskProxy(aTask)
		set taskName to aTaskProxy's getName()
		
		set revisedTaskName to textToPrepend & taskName
		tell aTaskProxy to setName(revisedTaskName)
	end execute
end script

script HasChildrenSpecification
	property parent : ddd's AbstractSpecification
	property name : "Has Child Tasks"
	
	on isSatisfiedBy(aTask)
		tell application "OmniFocus"
			with timeout of 3 seconds
				return aTask's number of tasks is greater than 0
			end timeout
		end tell
	end isSatisfiedBy
end script

script TaskNameCommandBuilder
	property newTextValue : missing value
	property textToPrepend : missing value
	property textToAppend : missing value
	property textToFind : missing value
	property textToReplace : missing value
	
	on createBuilder()
		copy TaskNameCommandBuilder to aBuilder
		return aBuilder
	end createBuilder

	on rename(newText)
		set newTextValue to newText
		return me
	end rename
	
	on prepend(theText)
		set textToPrepend to theText
		return me
	end prepend
	
	on append(theText)
		set textToAppend to theText
		return me
	end append
	
	on replace(original, replacement)
		set textToFind to original
		set textToReplace to replacement
		return me
	end replace
	
	on getContents()
		set aCommand to domain's MacroTaskCommand's constructCommand()
		
		if newTextValue is not missing value then 
			set newCommand to SetTaskNameCommand's constructCommand()
			set newCommand's newTaskNAme to newTextValue
			set end of aCommand's commands to newCommand
		end if 

		if textToPrepend is not missing value then 
			set newCommand to PrependTextToTaskNameCommand's constructCommand()
			set newCommand's textToPrepend to textToPrepend
			set end of aCommand's commands to newCommand
		end if		
		
		if textToAppend is not missing value then 
			set newCommand to AppendTextToTaskNameCommand's constructCommand()
			set newCommand's textToAppend to textToAppend
			set end of aCommand's commands to newCommand
		end if		

		if (textToFind is not missing value and textToReplace is not missing value) then 
			set newCommand to ReplaceTokenFromTaskNameCommand's constructCommand()
			set newCommand's findToken to textToFind
			set newCommand's replaceToken to textToReplace
			set end of aCommand's commands to newCommand
		end if		

		return aCommand
	end getContents
end script

script RepetitionRuleCommandBuilder
	property frequency : missing value
	property repetitionRule : missing value
	
	on createBuilder()
		copy RepetitionRuleCommandBuilder to aBuilder
		return aBuilder
	end createBuilder

	on deferAnother(freq)
		set frequency to freq
		set repetitionRule to "defer"
		return me
	end deferAnother

	on dueAgain(freq)
		set frequency to freq
		set repetitionRule to "due"
		return me
	end due

	on repeatEvery(freq)
		set frequency to freq
		set repetitionRule to "fixed"
		return me
	end due
		
	on getContents()
		local aCommand
		
		if (repetitionRule is "defer") then
			set aCommand to domain's DeferAnotherDayCommand's constructCommand()
		end if 

		if (repetitionRule is "due") then
			set aCommand to domain's DueAgainDailyCommand's constructCommand()
		end if 

		if (repetitionRule is "fixed") then
			set aCommand to domain's RepeatEveryDayCommand's constructCommand()
		end if 
				
		return aCommand
	end getContents
end script

script RuleConditionBuilder
end script

script RuleCommandBuilder
	property nameCommandBuilder : missing value
	property repetitionBuilder : missing value

	on make new RuleCommandBuilder
		copy RuleCommandBuilder to aBuilder
		return aBuilder
	end make

	on taskName()
		tell TaskNameCommandBuilder 
			set nameCommandBuilder to TaskNameCommandBuilder's createBuilder()
		end tell 
		
		return nameCommandBuilder
	end taskName
	
	on repetition()
		tell RepetitionRuleCommandBuilder
			set repetitionBuilder to RepetitionRuleCommandBuilder's createBuilder()
		end tell
		return repetitionBuilder
	end repetition
		
	on getContents()
		set aCommand to domain's MacroTaskCommand's constructCommand()
		
		set aCommand to nameCommandBuilder's getContents()
		 
		return aCommand
	end getContents
end script

script RuleBase
	property parent : ConditionalCommandRule
	
	property nameConditionBuilder : missing value
	property projectCondBuilder : missing value
	property contextCondBuilder : missing value
	property deferDateConditionBuilder : missing value
	property dueDateConditionBuilder : missing value
	property commandBuilder : missing value
	
	on any()
	end any
	
	on all()
	end all
	
	on do()
		tell RuleCommandBuilder
			set commandBuilder to make new RuleCommandBuilder
		end tell
		return commandBuilder
	end command
	
	on taskName()
		tell TextSpecificationBuilder 
			set nameConditionBuilder to make new TextSpecificationBuilder with data TaskNameRetrievalStrategy
		end tell
		return nameConditionBuilder	
	end taskName
	
	on project()
	end project
	
	on context()
		tell ContextConditionBuilder
			copy ContextConditionBuilder to contextCondBuilder
		end tell
		
		return contextCondBuilder
	end context
	
	on dueDate()
		tell DateConditionBuilder
			set dueDateConditionBuilder to make new DateConditionBuilder with data DueDateRetrievalStrategy
		end tell
		return dueDateConditionBuilder
	end dueDate
	
	on deferDate()
		tell DateConditionBuilder
			set deferDateConditionBuilder to make new DateConditionBuilder with data DeferDateRetrievalStrategy
		end tell
		return deferDateConditionBuilder
	end deferDate
	
	on flagged()
	end flagged
	
	on notFlagged()
	end notFlagged
	
	on noteValue()
	end noteValue
	
	on setContext(contextName)
		set aCommand to domain's SetContextCommand's constructCommand()
		set aCommand's contextName to contextName
		return aCommand
	end setContext
	
	on rename(newName)
		script 
			on execute(aTask)
				TaskProxy's newTaskProxy(aTask)'s setName(newName)
			end execute
		end script
		return the result
	end rename
	
	on markCompleted()
		return domain's MarkCompleteCommand's constructCommand()
	end markCompleted
	
	on getContents()
		set aSpec to TrueSpecification
		
		if (taskNameConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(taskNameConditionBuilder's getContents())
		if (contextConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(contextConditionBuilder's getContents())
		if (deferDateConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(deferDateConditionBuilder's getContents())
		if (dueDateConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(dueDateConditionBuilder's getContents())
		
		return aSpec
	end getContents
end script

on makeRule(aRule)
--	set suite to aRule's parent
	
--	tell aRuleSet to addRule(aRule)
	
	script _Rule
		property parent : ConditionalCommandRule's constructRule()
		property matchResult : false
		
	end script
	
	return _Rule
end makeRule

on Rule(aRule)
	return makeRule(aRule)
end Rule


script OmniFocusRuleTarget
	property tasks : { }
	property targetName : missing value
	
	on construct()
		copy me to aTarget
		set aTarget's tasks to getTasks() 
		set aTarget's targetName to defineName()
		return aTarget
	end construct
	
	on getTasks()
		--return tasks
	end getTasks
	
	on defineName()
		error "Name of target must be defined."
	end defineName

	on accept(rules)
		log "Attempting to process " & count of rules & " rules for target, " & targetName & "."
		
		repeat with aRule in rules
			log "[OmniFocus rule target: " & targetName & "][" & aRule's prettyName() & "] Attempting to process " & count of tasks & " tasks."
			
			if (count of tasks > 100) then
				--Try in 100 task increments
				
				set remainingUnprocessedTasks to count of tasks
				
				set batchStartIdx to 1
				set batchEndIdx to 100
				
				repeat until (remainingUnprocessedTasks = 0) 
					set taskBatch to items batchStartIdx thru batchEndIdx of tasks

					log "[OmniFocus rule target: " & targetName & "][" & aRule's prettyName() & "] Processing batch " & batchStartIdx & " to " & batchEndIdx & " of " & count of tasks & " tasks." 
					tell aRule to accept(taskBatch)
					
					set remainingUnprocessedTasks to remainingUnprocessedTasks - (count of taskBatch)
					set batchStartIdx to batchEndIdx + 1
					if (remainingUnprocessedTasks > 100)
						set batchEndIdx to batchEndIdx + 100
					else 
						set batchEndIdx to batchStartIdx + remainingUnprocessedTasks - 1
					end
				end repeat
			else
				
				tell aRule to accept(reference to tasks)
			end if
			log "[OmniFocus rule target: " & targetName & "][" & aRule's prettyName() & "] Finished processing " & count of tasks & " tasks."
		end repeat
		
		log "Finished processing " & count of rules & " rules for target, " & targetName & "."		
	end accept
end script

-- TARGETS --

script Inbox
	property parent : OmniFocusRuleTarget
	
	on defineName()
		return "Inbox"
	end defineName
	
	on getTasks()
		return domain's TaskRepository's selectAllInboxTasks()
--		return TaskRepository's selectAllInboxTasks()
	end getTasks
end script

script DocumentTarget
	property parent : OmniFocusRuleTarget
	
	on defineName()
		return "All Tasks"
	end defineName
	
	on getTasks()
		return domain's TaskRepository's selectAll()
--		return TaskRepository's selectAll()
	end getTasks
end script

script ProjectTarget
	property parent : OmniFocusRuleTarget
	property projectName : missing value

	on defineName()
		return "Project: " & projectName
	end defineName

	on getTasks()
		set aProject to domain's ProjectRepository's findByName(projectName)

		local theTasks
		tell application "OmniFocus"
			with timeout of 3 seconds
				set theTasks to aProject's tasks
			end timeout
		end tell

		return theTasks
	end getTasks
end script

on target()
	script
		on project(projectName)
			copy ProjectTarget to aTarget
			set aTarget's projectName to projectName
			return aTarget
		end 
	end script
	
	return the result
end target



script UserSpecifiedTasks
	property parent : OmniFocusRuleTarget
	
	on defineName()
		return "User-Specified Tasks"
	end defineName
	
	on getTasks()
		return domain's TaskRepository's selectUserSpecifiedTasks()
--		return TaskRepository's selectUserSpecifiedTasks()
	end getTasks
end script

script OmniFocusRuleSet
	
	on constructRuleSet()
		copy me to aRuleSet
		return aRuleSet
	end constructRuleSet
	
	on processAll()
	end processAll
	
end script

script AbstractOmniFocusRuleSet
	property parent : OmniFocusRuleSet
	property targetConfigs : { }
	
	on addTargetConfig(aTarget, rules)
		set targetConfigs's end to { target:aTarget, rules:rules }
	end addTargetConfig

	on processAll()
		repeat with configItem in targetConfigs
			set aTarget to configItem's target
			set rules to configItem's rules
			
			tell aTarget to accept(rules)			
		end repeat
	end processAll	
end script 

on initializeRuleRepository()
	log "Initializing rule repository."

	--Set up container	
	set pathToRules to POSIX path of ((path to home folder from user domain) as text)
	set pathToRules to pathToRules & "OmniFocus Rules/"
	set pathToRules to pathToRules & "omnirulefile.scptd"

	script FileLoadingRuleRepository
		property name : "FileLoadingRuleRepository"
		on getAll()
			set suite to makeRuleLoader()'s loadRulesFromFile(pathToRules)
			return suite
		end getAll
	end script
	
	registerRuleRepository(FileLoadingRuleRepository)
end initializeRuleRepository

on registerRuleRepository(repo)
	log "Registering rule repository, " & repo's name
	set _ruleRepository to repo
end registerRuleRepository

on locateRuleRepository()
	if _ruleRepository is missing value
		log "Rule repository has not yet been registered."
		initializeRuleRepository()
	end if
	
	log "Located rule repository, " & _ruleRepository's name
	return _ruleRepository
end locateRuleRepository

on processInbox()
	log "Process Inbox called."

	set ruleRepository to locateRuleRepository()
	set suite to ruleRepository's getAll()
	tell suite to exec()
	
	log "Process Inbox completed."	
end processInbox

on processAllRules()
	set repo to locateRuleRepository()

	--Do stuff	
	set suite to repo's getAll()
	tell suite to exec()
end processAllRules

