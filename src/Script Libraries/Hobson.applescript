use AppleScript version "2.5"
use scripting additions

use textutil : script "com.kraigparkinson/ASText"
use dateutil : script "com.kraigparkinson/ASDate"
use ddd : script "com.kraigparkinson/ASDomainDrivenDesign"
use domain : script "com.kraigparkinson/OmniFocusDomain"

(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's name. *)
property name : "Hobson"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's id. *)
property id : "com.kraigparkinson.Hobson"

property _ruleRepository : missing value

property dry : false
property debug : true
property verbose : true

--set domain's _taskRepository to domain's DocumentTaskRepository

-----------------------------
-- Output-related handlers --
-----------------------------

(*! @abstract TODO. *)
on ofail(s)
	log "Fail:" & space & s
end ofail

(*! @abstract TODO. *)
on ohai(s)
	log "==>" & space & s
end ohai

(*! @abstract TODO. *)
on odebug(s)
	if my debug then log "DEBUG:" & space & s
end odebug

(*! @abstract Logs a message only in verbose mode. *)
on overb(s as text)
	if my verbose and s is not "" then log s
end overb

(*! @abstract TODO. *)
on owarn(s)
	log "Warn:" & space & s
end owarn

script RuleSentinel
	property parent : AppleScript
end script

on _makeRuleLoader()
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
end _makeRuleLoader

on makeRuleSuite(aName)
	script 
		property name : aName
		property ruleSets : { }
		
		on addRuleSet(aRuleSet)
			odebug("Adding rule set: " & aRuleSet's name)
			set end of ruleSets to aRuleSet
		end addRuleSet		
		
		on exec()
						
			overb("Starting to execute rules for suite: " & name)
			
			repeat with aSet in ruleSets
				overb("Starting to prepare rule set for processing: " & aSet's name)
				tell aSet to run
				overb("Finished preparing rule set for processing: " & aSet's name)
				
				overb("Starting to process rule set: " & aSet's name)
				tell aSet's target to accept(aSet's rules) 
				overb("Finished processing rule set: " & aSet's name)
			end repeat

			tell application "OmniFocus" to compact

			overb("Finished executing rules for suite: " & name)
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
		odebug("Added rule set: " & aRuleSet's name & " to rule suite: " & aSuite's name)
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
			
			overb("Adding rule to evaluate: " & ruleName)
			
			set aRule to aRuleType

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
end RuleSet

script RuleFactory
	on _makeOmniFocusTaskProcessingRule(aName)
		script OmniFocusTaskProcessingRule	
			property name : aName

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
					overb("[" & name & "]" & "Processing task" & space & taskIndex & space & "of" & space & count of tasks)
			
					set inputAttributes to { }
	
					set taskIsMatched to false

					try
						set matchResult to matchTask(aTask, inputAttributes)
	
						if (matchResult's class is boolean) 
							odebug("[" & name & "]" & "Match result: " & matchResult)
							if (matchResult) 
								set taskIsMatched to true
							end if
						else if (matchResult's class is record)
							odebug("[" & name & "]" & "Match result: " & matchResult's passesCriteria)
					
							if (matchResult's passesCriteria)
								set taskIsMatched to true
								set inputAttributes to matchResult's outputAttributes
							end if
						else 
							error "[" & name & "]" & "Unrecognized response from matching handler: " & matchResult
						end if
			
					on error message
						owarn("[" & name & "] Error occurred matching rule: " & message)
					end try
		
			
					if (taskIsMatched)
						overb("[" & name & "]" & "Processing commands.")
						
						try
							set processResult to processTask(aTask, inputAttributes)
						
							if (processResult is not missing value and processResult's class is record)
								if (ruleStop of processResult) then 
									overb("[" & name & "]" & "Rule ended task processing prematurely.")						
									exit repeat
								end if
							else 
								overb("[" & name & "]" & "Finished processing task.")
							end if 
										
						on error message 
							owarn("[" & name & "] Error occurred processing rule: " & message)
						end try				
					end if
			
					set taskIndex to taskIndex + 1
				end repeat		
			end accept
	
		end script
		return OmniFocusTaskProcessingRule
	end _makeOmniFocusTaskProcessingRule
	

	on makeConditionalCommandRule()
		set conditions_list to { }
		set actions_list to { }
		
		script ConditionalCommandRule	
			property parent : RuleFactory's _makeOmniFocusTaskProcessingRule("ConditionalCommandRule")
			property conditions : conditions_list
			property actions : actions_list
		
			on match by aSpec
				addCondition(aSpec)
			end match
	
			on addCondition(aSpec)
				odebug("[" & name & "]" & "Adding condition: " & aSpec's name)
				set conditions's end to aSpec
			end addCondition
	
			on command thru aCommand
				addAction(aCommand)
			end command
	
			on addAction(aCommand)
				try
					odebug("[" & name & "]" & "Adding action: " & aCommand's name)
					set actions's end to aCommand
				on error errMsg
					owarn("Error adding action: " & errMsg)
				end try
			end addAction
	
			(*
			@post Returns boolean or record
			*)
			on matchTask(aTask, inputAttributes)
				--Implement all
				set satisfiedConditions to 0
		
				odebug("[" & name & "]" & "Preparing to evaluate " & count of conditions & " conditions.")
				repeat with condition in conditions
					odebug("[" & name & "]" & "Evaluating condition: " & condition's name)
					set matchResult to condition's isSatisfiedBy(aTask)
			
					if (matchResult's class is boolean)
						odebug("[" & name & "]" & "Task meets condition: " & matchResult)
			
						if (matchResult) then set satisfiedConditions to satisfiedConditions + 1
					else if (matchResult's class is record)
						odebug("[" & name & "]" & "Task meets conditions: " & matchResult's passesCriteria)
						if (matchResult's passesCriteria) then
							set satisfiedConditions to satisfiedConditions + 1					
							set inputAttributes to inputAttributes & matchREsult's outputAttributes
						end if 
					end 
				end repeat
		
				set matched to (satisfiedConditions equals count of conditions)
				odebug("[" & name & "]" & "Finished evaluating conditions for rule. Result: " & matched)
				return matched
			end matchTask
	
			(*
			@post Throws error if there's a problem processing rule.
			*)
			on processTask(aTask, inputAttributes)
				overb("[" & name & "]" & "Preparing to execute " & count of actions & " commands on task.")
				repeat with anAction in actions
					overb("[" & name & "]" & "Executing command: " & anAction's name)
					tell anAction to execute(aTask)
				end repeat
				overb("[" & name & "]" & "Finished executing commands on task.")
				return true
			end processTask
		end script
		return ConditionalCommandRule
	end makeConditionalCommandRule	
end script --RuleFactory

script ValueRetrievalStrategy
	on getValue(obj)
		return obj
	end getValue
end script

script TaskNameRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return aTask's getName()		
	end getValue
end script

script NoteRetrievalStrategy
	property parent : ValueRetrievalStrategy

	on getValue(aTask)
		return aTask's _noteValue()		
	end getValue
end script

script CompletedRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return aTask's _completedValue()
	end getValue
end script

script FlagRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return aTask's _flaggedValue()
	end getValue
end script

script ContextNameRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		using terms from application "OmniFocus"
			return aTask's _contextValue()'s name
		end using terms from
	end getValue
end script

script DueDateRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return aTask's _dueDateValue()
	end getValue
end script

script DeferDateRetrievalStrategy
	property parent : ValueRetrievalStrategy
	
	on getValue(aTask)
		return aTask's _deferDateValue()
	end getValue
end script

script SpecificationFactory
	script TextValidationStrategy
		on matchesText(actual)
		end matchesText
	end 

	on makeTextSpecification(aSourcingStrategy, aValidationStrategy)
		if (aSourcingStrategy is missing value) then error "TextSpecification properties should have a sourcingStrategy."
		if (aValidationStrategy is missing value) then error "TextSpecification properties should have a validationStrategy."

		script TextSpecification
			property parent : ddd's DefaultSpecification
			property sourcingStrategy : aSourcingStrategy
			property validationStrategy : aValidationStrategy
			property name : "TextSpecification"
	
			on isSatisfiedBy(obj)
				return validationStrategy's matchesText(sourcingStrategy's getValue(obj))
			end isSatisfiedBy
		end script

		return TextSpecification
	end makeTextSpecification

	on makeSameAsTextSpecification(expected, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return expected equals actual
			end matchesText
		end script

		set validation to the result
		set aSpec to makeTextSpecification(textFetcher, validation)
		set aSpec's name to "same as " & expected
		return aSpec
	end makeSameAsTextSpecification

	on makeStartsWithTextSpecification(startsWithText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual starts with startsWithText
			end matchesText
		end script

		set validation to the result
		set aSpec to makeTextSpecification(textFetcher, validation)
		set aSpec's name to "starts with >>" & startsWithText & "<<"
		return aSpec
	end makeStartsWithTextSpecification

	on makeEndsWithTextSpecification(endsWithText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual ends with endsWithText
			end matchesText
		end script

		set validation to the result
		set aSpec to makeTextSpecification(textFetcher, validation)
		set aSpec's name to "ends with >>" & endsWithText & "<<"
		return aSpec
	end makeEndsWithTextSpecification

	on makeContainsTextSpecification(containedText, textFetcher)
		script 
			property parent : TextValidationStrategy
			on matchesText(actual)
				return actual contains containedText
			end matchesText
		end script

		set validation to the result
		set aSpec to makeTextSpecification(textFetcher, validation)
		set aSpec's name to "contains >>" & containedText & "<<"
		return aSpec
	end makeContainsTextSpecification
	
	script DateValidationStrategy
		on validateDate(actual)
		end validateDate
	end 

	on makeDateSpecification(aReferenceValue, aSourcingStrategy, aValidationStrategy)
		if (aSourcingStrategy is missing value) then error "Can't create DateSpecification without a sourcing strategy."
		if (aValidationStrategy is missing value) then error "Can't create DateSpecification without a validation strategy."
		
		script DateSpecification
			property parent : ddd's DefaultSpecification
			property sourcingStrategy : aSourcingStrategy
			property validationStrategy : aValidationStrategy
			property class : "DateSpecification"
			property name : "DateSpecification"
	
			on isSatisfiedBy(obj)
				return validationStrategy's validateDate(sourcingStrategy's getValue(obj))
			end isSatisfiedBy
		end script

		return DateSpecification
	end makeDateSpecification

	on makeSameAsDateSpecification(expected, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				return expected equals actual
			end validateDate
		end script

		set validation to the result

		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "same as " & expected
		return aSpec
	end makeSameAsDateSpecification

	on makeIsBeforeDateSpecification(referenceDate, dateFetcher)
		script IsBeforeDateSpecification
			property parent : ddd's Specification
			property reference_date : referenceDate
			on isSatisfiedBy(aDate)
				aDate comes before reference_date
			end isSatisfiedBy
		end script
		
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				actual comes before referenceDate
			end validateDate
		end script

		set validation to the result
		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "is before " & referenceDate
		return aSpec
	end makeIsBeforeDateSpecification

	on makeIsAfterDateSpecification(referenceDate, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				return actual comes after referenceDate
			end validateDate
		end script

		set validation to the result
		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "is after " & referenceDate
		return aSpec
	end makeIsAfterDateSpecification

	on makeInTheNextIntervalDateSpecification(specifiedDays, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				local referenceCalDate
				local dateDifference
				
--				using terms from dateutil
				set referenceCalDate to dateutil's CalendarDateFactory's today at "12:00:00AM"
				set referenceCalDate to referenceCalDate's increment by specifiedDays
				set dateDifference to (referenceCalDate's asDate() - actual) / days
--				end using terms from
		
				return (dateDifference ≤ specifiedDays) and (dateDifference > 0)
			end validateDate
		end script

		set validation to the result
		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "in the next " & specifiedDays & " days"
		return aSpec
	end makeInTheNextIntervalDateSpecification

	on makeInTheLastIntervalDateSpecification(specifiedDays, dateFetcher)
		script 
			property parent : DateValidationStrategy
			on validateDate(actual)
				local referenceCalDate
				set referenceCalDate to (dateutil's CalendarDateFactory's today at "12:00:00AM")'s increment by -specifiedDays
		
				set dateDifference to (actual - referenceCalDate's asDate()) / days
		
				return (dateDifference ≤ specifiedDays) and (dateDifference > 0)
			end validateDate
		end script

		set validation to the result
		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "in the last " & specifiedDays & " days"
		return aSpec
	end makeInTheLastIntervalDateSpecification

	on makeMissingDateSpecification(dateFetcher)
		script 
			property parent : DateValidationStrategy
			property name : "is missing"
	
			on validateDate(actual)
				return actual is missing value
			end validateDate
		end script

		set validation to the result
		set aSpec to makeDateSpecification(missing value, dateFetcher, validation)
		set aSpec's name to "missing date"
		return aSpec
	end makeMissingDateSpecification	
	
	on makeMatchesTextSpecification(aReferenceText, aSourcingStrategy)
		if (conditionProps is missing value) then error "Can't create MatchesTextSpecification with missing properties"

		script MatchesTextSpecification
			property parent : ddd's DefaultSpecification
			property referenceText : aReferenceText
			property sourcingStrategy : aSourcingStrategy
			property name : "matches text (" & referenceText & ") from (" & (sourcingStrategy's name) & ")"
				
			on isSatisfiedBy(obj)
				return sourcingStrategy's getValue(obj) contains referenceText
			end isSatisfiedBy
		end script
		return MatchesTextSpecification
	end makeMatchesTextSpecification
		
	script BooleanValidationStrategy
		on matchesValue(actual)
		end matchesValue
	end 
	
	on makeBooleanSpecification(aSourcingStrategy, aValidationStrategy)
		if (aValidationStrategy is missing value or aSourcingStrategy is missing value) then error "Can't create BooleanSpecification with missing properties"

		script BooleanSpecification
			property parent : ddd's DefaultSpecification
			property sourcingStrategy : aSourcingStrategy
			property validationStrategy : aValidationStrategy
			property class : "BooleanSpecification"
							
			on isSatisfiedBy(obj)
				return validationStrategy's matchesValue(sourcingStrategy's getValue(obj))
			end isSatisfiedBy
		end script
		return BooleanSpecification
	end makeBooleanSpecification
	
	on makeIsEqualSpecification(expected, booleanFetcher)
		script 
			property parent : BooleanValidationStrategy
			on matchesValue(actual)
				return expected equals actual
			end matchesValue
		end script

		set validation to the result
		set aSpec to makeBooleanSpecification(booleanFetcher, validation)
		set aSpec's name to "same as " & expected
		return aSpec
	end makeIsEqualSpecification
	
end script --Specification Factory

on makeBooleanSpecificationBuilder(aBooleanStrategy)
	if (aBooleanStrategy is missing value) then error "Text strategy is missing."
	
	script BooleanSpecificationBuilder
		property booleanStrategy : aBooleanStrategy
		property theValue : missing value
	
		on isTrue()
			set theValue to true
			return me
		end isTrue

		on isFalse()
			set theValue to false
			return me
		end isFalse
	
		on getContents()
			local aCondition
			if (theValue is not missing value) then 
				set aCondition to SpecificationFactory's makeIsEqualSpecification(theValue, booleanStrategy)
			else 
				error "theValue of BooleanSpecificationBuilder needs to be set."
			end if 
			return aCondition
		end getContents
	
	end script
	return BooleanSpecificationBuilder
end makeBooleanSpecificationBuilder

on makeTextMatchPatternConditionBuilder(aTextStrategy)
	if (aTextStrategy is missing value) then error "Can't create a TextMatchPatternConditionBuilder without a text strategy."
	
	set builders_list to { }
	set regex_text to ""
	script TextMatchPatternConditionBuilder
		property textStrategy : aTextStrategy
		property builders : builders_list
		property regex : regex_text
	
		on aLetter()
			set regex to regex & "[[:alpha:]]{1}"
			script 
				on getContents()
					script 
						on isSatisfiedBy(obj as text)
							return textutil's doesMatch(obj, "[[:alpha:]]{1}")
						end isSatisfiedBy
					end script
				end getContents
			end script
		
			set end of builders to the result
		
			return me
		end aLetter
	
		on aDigit()
			set regex to regex & "[[:digit:]]{1}"
			script 
				on getContents()
					script 
						on isSatisfiedBy(obj as text)
							return textutil's doesMatch(obj, "[[:digit:]]{1}")
						end isSatisfiedBy
					end script
				end getContents
			end script
		
			set end of builders to the result
		
			return me
		end aDigit
	
		on letterOrDigit()
			script 
				on getContents()
					script 
						on isSatisfiedBy(obj as text)
							return textutil's doesMatch(obj, "[[:alnum:]]{1}")
						end isSatisfiedBy
					end script
				end getContents
			end script
		
			set end of builders to the result
		
			return me
		
		end letterOrDigit
	
		on aSymbol()
			return me
		end aSymbol
	
		on customDate()
		end customDate
	
		on aWord()
			script 
				on getContents()
					script 
						on isSatisfiedBy(obj as text)
							return textutil's doesMatch(obj, "[[:word:]]{1}")
						end isSatisfiedBy
					end script
				end getContents
			end script
		
			set end of builders to the result
		
			return me
		
		end aWord
	
		on aNumber()
			script 
				on getContents()
					script 
						on isSatisfiedBy(obj as text)
							return textutil's doesMatch(obj, "[[:xdigit:]]{1}")
						end isSatisfiedBy
					end script
				end getContents
			end script
		
			set end of builders to the result
		
			return me
		
		end aNumber
	
		on lettersAndDigits()
		end lettersAndDigits
	
		on symbols()
		end symbols
	
		on customText()
		end customText
	
		on anyText()
		end anyText
	
		on textString()
		end textString
	
		on getContents()
			set aSpec to ddd's DefaultSpecification
		
			repeat with aBuilder in builders
				set aSpec to aSpec's andSpec(aBuilder's getContents())
			end repeat
		
			script 
				on isSatisfiedBy(obj as text)
					return textutil's doesMatch(obj, regex)
				end isSatisfiedBy
			end script
		
			return the result
		end getContents
	end script --TextMatchPatternConditionBuilder	
	return TextMatchPatternConditionBuilder
end makeTextMatchPatternConditionBuilder

on makeCustomTokenBuilder()
	script CustomTokenBuilder
		property tokenName : missing value
	
		on token(tokenName)
			set my tokenName to tokenName
		end token

		on aDay()
		end aDay
	
		on aMonth()
		end aMonth
	
		on aYear()
		end aYear
	
		on anHour()
		end anHour
	
		on aMinute()
		end aMinute
	
		on aSecond()
		end aSecond
	
		on anyText()
		end anyText
	
		on textString()
		end textString
	end script
	return CustomTokenBuilder
end makeCustomTokenBuilder

on makeTextSpecificationBuilder(aTextStrategy)
	if (aTextStrategy is missing value) then error "Text strategy is missing."
	
	script TextSpecificationBuilder
		property textStrategy : aTextStrategy

		property sameAsText : missing value
		property notSameAsText : missing value
		property startingWithText : missing value
		property notStartingWithText : missing value
		property endingWithText : missing value
		property notEndingWithText : missing value
		property containedText : missing value
		property notContainedText : missing value
		property pattern : missing value

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
	
		on match()
			set aBuilder to makeTextMatchPatternConditionBuilder(textStrategy)
			return aBuilder
		end match
	
		on getContents()
			set aCondition to ddd's DefaultSpecification
		
			if (sameAsText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeSameAsTextSpecification(sameAsText, textStrategy))
			if (notSameAsText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeSameAsTextSpecification(notSameAsText, textStrategy)'s notSpec())
			if (startingWithText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeStartsWithTextSpecification(startingWithText, textStrategy))
			if (notStartingWithText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeStartsWithTextSpecification(notStartingWithText, textStrategy)'s notSpec())
			if (endingWithText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeEndsWithTextSpecification(endingWithText, textStrategy))
			if (notEndingWithText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeEndsWithTextSpecification(notEndingWithText, textStrategy)'s notSpec())
			if (containedText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeContainsTextSpecification(containedText, textStrategy))
			if (notContainedText is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeContainsTextSpecification(notContainedText, textStrategy)'s notSpec())
		
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
	return TextSpecificationBuilder
	
end makeTextSpecificationBuilder

on makeDateConditionBuilder(aDateStrategy)

	script DateConditionBuilder
		property dateStrategy : aDateStrategy

		property sameAsDate : missing value
		property notSameAsDate : missing value
		property isBeforeDate : missing value
		property isAfterDate : missing value
		property inTheLastDays : missing value
		property notInTheLastDays : missing value
		property inTheNextDays : missing value
		property notInTheNextDays : missing value
		property isMissingValue : missing value
	
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
			set aCondition to ddd's DefaultSpecification
		
			if (isMissingValue is not (missing value)) then 
				if (isMissingValue) then 
					set aCondition to aCondition's andSpec(SpecificationFactory's makeMissingDateSpecification(dateStrategy))
				else 
					set aCondition to aCondition's andSpec(SpecificationFactory's makeMissingDateSpecification(dateStrategy)'s notSpec())
				end if 
			end if 
		
			if (sameAsDate is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeSameAsDateSpecification(sameAsDate, dateStrategy))
			if (notSameAsDate is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeSameAsDateSpecification(notSameAsDate, dateStrategy)'s notSpec())
			if (isBeforeDate is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeIsBeforeDateSpecification(isBeforeDate, dateStrategy))
			if (isAfterDate is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeIsAfterDateSpecification(isAfterDate, dateStrategy))
			if (inTheLastDays is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeInTheLastIntervalDateSpecification(inTheLastDays, dateStrategy))
			if (notInTheLastDays is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeInTheLastIntervalDateSpecification(notInTheLastDays, dateStrategy)'s notSpec())
			if (inTheNextDays is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeInTheNextIntervalDateSpecification(inTheNextDays, dateStrategy))
			if (notInTheNextDays is not missing value) then set aCondition to aCondition's andSpec(SpecificationFactory's makeInTheNextIntervalDateSpecification(notInTheNextDays, dateStrategy)'s notSpec())

			return aCondition
		end getContents
	
	end script
	return DateConditionBuilder
end makeDateConditionBuilder

on makeContextConditionBuilder()

	script ContextConditionBuilder
		property missingContext : missing value
		property nameConditionBuilder : missing value


		on contextName() 
			set nameConditionBuilder to makeTextSpecificationBuilder(ContextNameRetrievalStrategy)
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
			set aCondition to ddd's DefaultSpecification
		
			if (nameConditionBuilder is not missing value) then set aCondition to aCondition's andSpec(nameConditionBuilder's getContents())
		
			if (missingContext is not missing value) then 
			
				set aSpec to domain's TaskHasContextSpecification
			
				if (missingContext) then set aSpec to aSpec's notSpec()
			
				set aCondition to aCondition's andSpec(aSpec)
			end if 
		
			return aCondition
		end getContents
	
	end script
	return ContextConditionBuilder
end makeContextConditionBuilder




script CommandFactory
	on makeSetTaskNameCommand(aTaskName)
		script SetTaskNameCommand
			property parent : domain's CommandFactory's TaskCommand
			property newTaskName : aTaskName

			on execute(aTask)
				tell aTask to setName(newTaskName)
			end execute
		end script 
		return SetTaskNameCommand
	end makeSetTaskNameCommand
	
	on makeStripTokenFromTaskNameCommand(aToken)
		script StripTokenFromTaskNameCommand
			property parent : domain's CommandFactory's TaskCommand
			property token : aToken
	
			on execute(aTask)
				local taskName
		
				set taskName to aTask's getName()
		
				using terms from script "com.kraigparkinson/ASText"
					set originalTaskNameStr to textutil's makeStringObj(taskName)
					set revisedTaskNameStr to originalTaskNameStr's removeText(token)
					set revisedTaskName to revisedTaskNameStr's asText()
				end using terms from

				tell aTask to setName(revisedTaskName)
			end execute
		end script
	end makeStripTokenFromTaskNameCommand
	
	on makePrependTextToTaskNameCommand(aTextToPrepend)
		script PrependTextToTaskNameCommand
			property parent : domain's CommandFactory's TaskCommand
			property textToPrepend : aTextToPrepend
	
			on execute(aTask)
				local taskName

				set taskName to aTask's getName()
		
				set revisedTaskName to textToPrepend & taskName
				tell aTask to setName(revisedTaskName)
			end execute
		end script
		return PrependTextToTaskNameCommand
	end makePrependTextToTaskNameCommand
	
	on makeReplaceTokenFromTaskNameCommand(aFindToken, aReplaceToken)
		script ReplaceTokenFromTaskNameCommand
			property parent : domain's CommandFactory's TaskCommand
			property findToken : aFindToken
			property replaceToken : aReplaceToken
	
			on execute(aTask)
				local taskName
		
				set taskName to aTask's getName()
		
				local revisedTaskName
				set revisedTaskName to textutil's makeStringObj(taskName)'s replaceText(findToken, replaceToken)'s asText()

				tell aTask to setName(revisedTaskName)
			end execute
		end script
		return ReplaceTokenFromTaskNameCommand
	end makeReplaceTokenFromTaskNameCommand
	
	on makeAppendTextToTaskNameCommand(aTextToAppend)
		script AppendTextToTaskNameCommand
			property parent : domain's CommandFactory's TaskCommand
			property textToAppend : aTextToAppend
	
			on execute(aTask)
				local taskName

				set taskName to aTask's getName()
		
				set revisedTaskName to taskName & textToAppend
				tell aTask to setName(revisedTaskName)
			end execute
		end script
	end makeAppendTextToTaskNameCommand
	
end script --CommandFactory







on makeTaskNameCommandBuilder()
	script TaskNameCommandBuilder
		property newTextValue : missing value
		property textToPrepend : missing value
		property textToAppend : missing value
		property textToFind : missing value
		property textToReplace : missing value
	
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
	
		on replace(original_text, replacement_text)
			set textToFind to original_text
			set textToReplace to replacement_text
			return me
		end replace

		on remove(original_text)
			return replace(original_text, "")
		end remove
	
		on getContents()
			set commandList to { }
		
			if newTextValue is not missing value then 
				set end of commandList to CommandFactory's makeSetTaskNameCommand(newTextValue)
			end if 

			if textToPrepend is not missing value then 
				set end of commandList to CommandFactory's makePrependTextToTaskNameCommand(textToPrepend)
			end if		
		
			if textToAppend is not missing value then 
				set end of commandList to CommandFactory's makeAppendTextToTaskNameCommand(textToAppend)
			end if		

			if (textToFind is not missing value and textToReplace is not missing value) then 
				set end of commandList to CommandFactory's makeReplaceTokenFromTaskNameCommand(textToFind, textToReplace)
			end if		
			
			set aCommand to domain's CommandFactory's makeMacroTaskCommand(commandList)

			return aCommand
		end getContents
	end script
	return TaskNameCommandBuilder
end makeTaskNameCommandBuilder

on makeRepetitionRuleCommandBuilder()
	script RepetitionRuleCommandBuilder
		property frequency : missing value
		property repetitionRule : missing value
	
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
				set aCommand to domain's CommandFactory's makeDeferAnotherCommand(frequency)
			else if (repetitionRule is "due") then
				set aCommand to domain's CommandFactory's makeDueAgainCommand(frequency)
			else if (repetitionRule is "fixed") then
				set aCommand to domain's CommandFactory's makeRepeatEveryCommand(frequency)
			end

			return aCommand
		end getContents
	end script
	return RepetitionRuleCommandBuilder
end makeRepetitionRuleCommandBuilder

script RuleConditionBuilder
end script

on makeRuleCommandBuilder()
	script RuleCommandBuilder
		property nameCommandBuilders : { }
		property repetitionBuilder : missing value

		on taskName()
			set end of nameCommandBuilders to makeTaskNameCommandBuilder()
			return last item of nameCommandBuilders
		end taskName
	
		on repetition()
			set repetitionBuilder to makeRepetitionRuleCommandBuilder()
			return repetitionBuilder
		end repetition
		
		on getContents()
			set commandList to { }
			
			repeat with aBuilder in nameCommandBuilders
				set end of commandList to aBuilder's getContents()
			end repeat
			if repetitionBuilder is not missing value then set end of commandList to repetitionBuilder's getContents()
		 
			set aCommand to domain's CommandFactory's makeMacroTaskCommand(commandList)

			return aCommand
		end getContents
	end script
	return RuleCommandBuilder
end makeRuleCommandBuilder


on makeRuleBase()
	script RuleBase
		property parent : RuleFactory's makeConditionalCommandRule()
	
		property nameConditionBuilder : missing value
		property projectCondBuilder : missing value
		property contextCondBuilder : missing value
		property deferDateConditionBuilder : missing value
		property dueDateConditionBuilder : missing value
		property commandBuilder : missing value
		property completeConditionBuilder : missing value
		property flagConditionBuilder : missing value
	
		on any()
		end any
	
		on all()
		end all
	
		on do()
			set commandBuilder to makeRuleCommandBuilder()
			return commandBuilder
		end command
	
		on taskName()
			set nameConditionBuilder to makeTextSpecificationBuilder(TaskNameRetrievalStrategy)
			return nameConditionBuilder	
		end taskName
	
		on project()
		end project
	
		on context()
			set contextCondBuilder to makeContextConditionBuilder()		
			return contextCondBuilder
		end context
	
		on dueDate()
			set dueDateConditionBuilder to makeDateConditionBuilder(DueDateRetrievalStrategy)
			return dueDateConditionBuilder
		end dueDate
	
		on deferDate()
			set deferDateConditionBuilder to makeDateConditionBuilder(DeferDateRetrievalStrategy)
			return deferDateConditionBuilder
		end deferDate
	
		on flagged()
			set flagConditionBuilder to makeBooleanSpecificationBuilder(FlagRetrievalStrategy)
			return flagConditionBuilder	
		end flagged
	
		on noteValue()
			set noteConditionBuilder to makeTextSpecificationBuilder(NoteRetrievalStrategy)
			return noteConditionBuilder	
		end noteValue
	
		on complete()
			set completeConditionBuilder to makeBooleanSpecificationBuilder(CompletedRetrievalStrategy)
			return completeConditionBuilder	
		end complete
	
		on setContext(contextName)
			set aCommand to domain's CommandFactory's makeSetContextCommand(contextName)
			return aCommand
		end setContext
	
		on rename(newName)
			script 
				on execute(aTask)
					aTask's setName(newName)
				end execute
			end script
			return the result
		end rename
	
		on markCompleted()
			return domain's CommandFactory's makeMarkCompleteCommand()
		end markCompleted
		
		on getContents()
			set aSpec to ddd's DefaultSpecification
		
			if (taskNameConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(taskNameConditionBuilder's getContents())
			if (contextConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(contextConditionBuilder's getContents())
			if (deferDateConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(deferDateConditionBuilder's getContents())
			if (dueDateConditionBuilder is not missing value) then set aSpec to aSpec's andSpec(dueDateConditionBuilder's getContents())
		
			return aSpec
		end getContents
	end script
	return RuleBase
end makeRuleBase

on makeOmniFocusRuleTarget()
	script OmniFocusRuleTarget
		property tasks : { }
		property targetName : missing value
	
		on locateTasks()
			return tasks
		end locateTasks
	
		on defineName()
			error "Name of target must be defined."
		end defineName

		on accept(rules)
			set tasks to locateTasks()
			set targetName to defineName()
			
			overb("Attempting to process " & count of rules & " rules for target, " & targetName & ".")
		
			repeat with aRule in rules
				overb("[OmniFocus rule target: " & targetName & "][" & aRule's name & "] Attempting to process " & count of tasks & " tasks.")
			
				if (count of tasks > 100) then
					--Try in 100 task increments
				
					set remainingUnprocessedTasks to count of tasks
				
					set batchStartIdx to 1
					set batchEndIdx to 100
				
					repeat until (remainingUnprocessedTasks = 0) 
						set taskBatch to items batchStartIdx thru batchEndIdx of tasks

						overb("[OmniFocus rule target: " & targetName & "][" & aRule's name & "] Processing batch " & batchStartIdx & " to " & batchEndIdx & " of " & count of tasks & " tasks.")
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
				overb("[OmniFocus rule target: " & targetName & "][" & aRule's name & "] Finished processing " & count of tasks & " tasks.")
			end repeat
		
			overb("Finished processing " & count of rules & " rules for target, " & targetName & ".")
		end accept
	end script
	return OmniFocusRuleTarget
end makeOmniFocusRuleTarget

-- TARGETS --

script Inbox
	property parent : makeOmniFocusRuleTarget()
	
	on defineName()
		return "Inbox"
	end defineName
	
	on locateTasks()
		return domain's taskRepositoryInstance()'s selectAllInboxTasks()
	end locateTasks
end script

script TransportTextInboxTasks
	property parent : makeOmniFocusRuleTarget()

	on defineName()
		return "Inbox"
	end defineName

	on locateTasks()
		return domain's taskRepositoryInstance()'s selectUnparsedInboxTasks()
	end locateTasks
end script

script DocumentTarget
	property parent : makeOmniFocusRuleTarget()
	
	on defineName()
		return "All Tasks"
	end defineName
	
	on locateTasks()
		return domain's taskRepositoryInstance()'s selectAll()
--		return taskRepositoryInstance()'s selectAll()
	end locateTasks
end script

on target()
	script
		on project(pName)
			script ProjectTarget
				property parent : makeOmniFocusRuleTarget()
				property projectName : pName
				property name : "Project:" & space & ">>" & projectName & "<<"

				on defineName()
					return name
				end defineName

				on locateTasks()
					set aProject to domain's ProjectRepository's findByName(projectName)
					set theTasks to domain's taskRepositoryInstance()'s selectTasksFromProject(aProject)
		
					return theTasks
				end locateTasks
			end script			
			
			return ProjectTarget
		end 
	end script
	
	return the result
end target

script UserSpecifiedTasks
	property parent : makeOmniFocusRuleTarget()
	
	on defineName()
		return "User-Specified Tasks"
	end defineName
	
	on locateTasks()
		return domain's taskRepositoryInstance()'s selectUserSpecifiedTasks()
	end locateTasks
end script

script OmniFocusRuleSet	
	on processAll()
	end processAll
end script

on makeOmniFocusRuleSet()
	script DefaultOmniFocusRuleSet
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
	return DefaultOmniFocusRuleSet
end makeOmniFocusRuleSet


on registerRuleRepository(repo)
	odebug("Registering rule repository, " & repo's name)
	set _ruleRepository to repo
end registerRuleRepository

on initializeRuleRepository()
	odebug("Initializing rule repository.")

	--Set up container	
	set pathToRules to POSIX path of ((path to home folder from user domain) as text)
	set pathToRules to pathToRules & "OmniFocus Rules/"
	set pathToRules to pathToRules & "omnirulefile.scptd"

	script FileLoadingRuleRepository
		property name : "FileLoadingRuleRepository"
		
		
		
		on getAll()
			set suite to _makeRuleLoader()'s loadRulesFromFile(pathToRules)
			return suite
		end getAll
	end script

	registerRuleRepository(FileLoadingRuleRepository)
end initializeRuleRepository

on locateRuleRepository()
	if _ruleRepository is missing value
		owarn("Rule repository has not yet been registered.")
		initializeRuleRepository()
	end if

	odebug("Located rule repository, " & _ruleRepository's name)
	return _ruleRepository
end locateRuleRepository

script RuleProcessingService
	on processInbox()
		odebug("RuleProcessingService: Process Inbox called.")

		set ruleRepository to locateRuleRepository()
		set suite to ruleRepository's getAll()
		tell suite to exec()
	
		odebug("RuleProcessingService: Process Inbox completed.")
	end processInbox

	on processAllRules()
		set repo to locateRuleRepository()

		--Do stuff	
		set suite to repo's getAll()
		tell suite to exec()
	end processAllRules
end script
