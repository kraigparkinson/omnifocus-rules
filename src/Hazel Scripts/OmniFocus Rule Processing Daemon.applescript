property Rules : script "com.kraigparkinson/OmniFocus Rules Engine"

(*)
property theFile : missing value
property inputAttributes : missing value 

hazelProcessFile(theFile, inputAttributes)
*)
on hazelProcessFile(theFile, inputAttributes)
	set pathToRules to POSIX path of ((path to home folder from user domain) as text)
	set pathToRules to pathToRules & "OmniFocus Rules/"
	set pathToRules to pathToRules & "omnirulefile.scptd"

	set aFile to pathToRules
	
	set suite to rules's makeRuleLoader()'s loadRulesFromFile(pathToRules)
	tell suite to exec()
end hazelProcessFile