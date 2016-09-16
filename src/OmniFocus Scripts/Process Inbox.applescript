property rules : script "com.kraigparkinson/OmniFocus Rules Engine"

on main()	
	log "Process Inbox called."
		
--	set rules to script "com.kraigparkinson/OmniFocus Rules Engine"

	set pathToRules to POSIX path of ((path to home folder from user domain) as text)
	set pathToRules to pathToRules & "OmniFocus Rules/"
	set pathToRules to pathToRules & "omnirulefile.scptd"

	set aFile to pathToRules
	
	set suite to rules's makeRuleLoader()'s loadRulesFromFile(pathToRules)
	tell suite to exec()
	
	log "Process Inbox completed."			
end main

main()