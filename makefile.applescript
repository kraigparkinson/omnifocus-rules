#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

use ASMake : script "com.lifepillar/ASMake" version "0.2.1"

property parent : ASMake
property TopLevel : me

on run argv
	continue run argv
end run

------------------------------------------------------------------
-- Tasks
------------------------------------------------------------------

script api
	property parent : Task(me)
	property description : "Build the API documentation"
	property dir : "Documentation"
	
	ohai("Running HeaderDoc, please wait...")
	--Set LANG to get rid of warnings about missing default encoding
	shell for "env LANG=en_US.UTF-8 headerdoc2html" given options:{"-q", "-o", dir, "Hobson.applescript"}
	shell for "env LANG=en_US.UTF-8 gatherheaderdoc" given options:dir
end script

script BuildRulesEngine
	property parent : Task(me)
	property name : "build/rules-engine"
	property description : "Build Rules Engine (alone)"

	property sourceDir : "src/Script Libraries/"
	property destinationDir : "build/Script Libraries/com.kraigparkinson"

	makeScriptBundle from joinPath(sourceDir, "Hobson.applescript") at destinationDir with overwriting
end script

script BuildHobsonRuleLibraries
	property parent : Task(me)
	property name : "build/library"
	property description : "Build Script Libraries"
	
	property sourceDir : "src/Script Libraries/"
	property destinationDir : "build/Script Libraries/com.kraigparkinson"

	tell BuildRulesEngine to exec:{ }
	makeScriptBundle from joinPath(sourceDir, "Default OmniFocus Rules Library.applescript") at destinationDir with overwriting
	makeScriptBundle from joinPath(sourceDir, "Creating Flow with OmniFocus Rules.applescript") at destinationDir with overwriting
end script

script BuildOFApplicationScripts
	property parent : Task(me)
	property name : "build/omnifocus-scripts"
	property description : "Build OmniFocus Application Scripts"
	
	property sourceDir : "src/OmniFocus Scripts/"
	property destinationDir : "build/OmniFocus Scripts"

	tell BuildRulesEngine to exec:{}
	tell BuildHobsonRuleLibraries to exec:{}
	makeScriptBundle from joinPath(sourceDir, "Process Inbox.applescript") at destinationDir with overwriting
	makeScriptBundle from joinPath(sourceDir, "Tidy.applescript") at destinationDir with overwriting
end script

script BuildHazelScripts
	property parent : Task(me)
	property name : "build/hazel"
	property description : "Build Process Inbox"

	property sourceDir : "src/Hazel Scripts/"
	property destinationDir : "build/Hazel Scripts"
	
	tell BuildRulesEngine to exec:{}
	tell BuildHobsonRuleLibraries to exec:{}	
	makeScriptBundle from joinPath(sourceDir, "OmniFocus Rule Processing Daemon.applescript") at destinationDir with overwriting
end script

script BuildRules
	property parent : Task(me)
	
	tell BuildRulesEngine to exec:{}
	tell BuildHobsonRuleLibraries to exec:{}
	makeScriptBundle from "src/Rule Sets/omnirulefile.applescript" at "build/Rule Sets" with overwriting
end script

script build
	property parent : Task(me)
	property description : "Build all source AppleScript scripts"

	tell BuildHobsonRuleLibraries to exec:{}
	osacompile(glob({}), "scpt", {"-x"})
end script

script buildAll
	property parent : Task(me)
	property description : "Build all source AppleScript scripts"
	
	tell BuildRulesEngine to exec:{}
	tell BuildHobsonRuleLibraries to exec:{}
	tell BuildOFApplicationScripts to exec:{}
	tell BuildHazelScripts to exec:{}
	tell BuildRules to exec:{}
	
	osacompile(glob({}), "scpt", {"-x"})
end script

script clean
	property parent : Task(me)
	property description : "Remove any temporary products"
	
	removeItems at {"build"} & glob({"**/*.scpt", "**/*.scptd", "tmp"}) with forcing
end script

script clobber
	property parent : Task(me)
	property description : "Remove any generated file"
	
	tell clean to exec:{}
	removeItems at glob({"Hobson-*", "*.tar.gz", "*.html"}) with forcing
end script

script doc
	property parent : Task(me)
	property description : "Build an HTML version of the old manual and the README"
	property markdown : missing value
	
	set markdown to which("markdown")
	if markdown is not missing value then
		shell for markdown given options:{"-o", "README.html", "README.md"}
	else
		error markdown & space & "not found." & linefeed & ¬
			"PATH: " & (do shell script "echo $PATH")
	end if
end script

script dist
	property parent : Task(me)
	property description : "Prepare a directory for distribution"
	property dir : missing value
	
	tell clobber to exec:{}
	tell BuildHobsonRuleLibraries to exec:{}
	tell BuildOFApplicationScripts to exec:{}
	tell BuildHazelScripts to exec:{}
	
	tell api to exec:{}
	tell doc to exec:{}
	
	set {n, v} to {name, version} of ¬
		(run script POSIX file (joinPath(workingDirectory(), "src/Hobson.applescript")))
	set dir to n & "-" & v
	makePath(dir)
	copyItems at {"build/Hobson.scptd", "build/Default OmniFocus Rules Library.scptd", "build/OmniFocus Scripts/OmniFocusDomain.scptd", "build/OmniFocusTransportTextParsingService.scptd", "build/Process Inbox.scptd", "COPYING", "Documentation", ¬
		"README.html"} into dir
end script

script gzip
	property parent : Task(me)
	property description : "Build a compressed archive for distribution"
	
	tell dist to exec:{}
	do shell script "tar czf " & quoted form of (dist's dir & ".tar.gz") & space & quoted form of dist's dir & "/*"
end script

script installRulesEngine
	property parent : Task(me)
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Script Libraries"
	property description : "Install Hobson in" & space & dir
	property packageName : "com.kraigparkinson"

	on installWithOverwriteAlert(scriptname, targetDirName)
		set targetDir to joinPath(dir, targetDirName)
		set targetPath to joinPath(targetDir, scriptname & ".scptd")

		copyItem at "build/Script Libraries/" & packageName & "/" & scriptname & ".scptd" into targetDir with overwriting
		ohai(scriptname & " installed at" & space & targetPath)
	end installWithOverwriteAlert

	tell BuildRulesEngine to exec:{}
	installWithOverwriteAlert("Hobson", packageName)	
end script 

script installScriptLibraries
	property parent : Task(me)
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Script Libraries"
	property description : "Install Hobson in" & space & dir
	property packageName : "com.kraigparkinson"

	on installWithOverwriteAlert(scriptname, targetDirName)
		set targetDir to joinPath(dir, targetDirName)
		set targetPath to joinPath(targetDir, scriptname & ".scptd")

		copyItem at "build/Script Libraries/" & packageName & "/" & scriptname & ".scptd" into targetDir with overwriting
		ohai(scriptname & " installed at" & space & targetPath)
	end installWithOverwriteAlert

	tell BuildHobsonRuleLibraries to exec:{}
	installWithOverwriteAlert("Default OmniFocus Rules Library", "com.kraigparkinson")	
	installWithOverwriteAlert("Creating Flow with OmniFocus Rules", "com.kraigparkinson")	
end script

script installHazelScript
	property parent : Task(me)
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Scripts/Hazel"
		
	property sourceDir : { "build/Hazel Scripts" }
	property description : "Install Hazel Scripts in" & space & dir
	
	on installWithOverwriteAlert(scriptname, targetDirName)
		set targetDir to joinPath(dir, targetDirName)
		set targetPath to joinPath(targetDir, scriptname & ".scptd")

		copyItems at "build/Hazel Scripts/" & scriptname & ".scptd" into targetDir with overwriting
		ohai(scriptname & " installed at" & space & targetPath)
	end installWithOverwriteAlert

	tell BuildHazelScripts to exec:{}
	
--	copyItems at sourceDir into joinPath(dir, "com.kraigparkinson") with overwriting
--	copyItems at sourceDir & glob({"**/*.scptd"}) into joinPath(dir, "com.kraigparkinson") with overwriting
--	ohai("Hazel scripts installed at" & space & joinPath(dir, "com.kraigparkinson"))
	installWithOverwriteAlert("OmniFocus Rule Processing Daemon", "com.kraigparkinson")	
	
end script

script InstallOFApplicationScripts
	property parent : Task(me)
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Application Scripts/com.omnigroup.OmniFocus2"
	property description : "Install Application Scripts in" & space & dir
	
	on installWithOverwriteAlert(scriptname, targetDirName)
		set targetDir to joinPath(dir, targetDirName)
		set targetPath to joinPath(targetDir, scriptname & ".scptd")

		copyItem at "build/OmniFocus Scripts/" & scriptname & ".scptd" into targetDir with overwriting
		ohai(scriptname & " installed at" & space & targetPath)
	end installWithOverwriteAlert
	
	tell BuildOFApplicationScripts to exec:{}
	installWithOverwriteAlert("Process Inbox", "")	
	installWithOverwriteAlert("Tidy", "")	
end script

script installRules
	property parent : Task(me)
--	property targetDir : POSIX path of ((path to library folder from user domain) as text) & "Script Libraries"
	property targetDir : POSIX path of ((path to home folder from user domain) as text) & "OmniFocus Rules"

	tell BuildRules to exec:{}
	copyItem at "build/Rule Sets/" & "omnirulefile.scptd" into targetDir with overwriting
end script

script installServer
	property parent : Task(me)
	property name : "install/server"
	property description : "Install everything you need to create a server instance."

	tell installRulesEngine to exec:{}
	tell installScriptLibraries to exec:{}
	tell installRules to exec:{}	
	tell installHazelScript to exec:{}
end script

script installClient
	property parent : Task(me)
	property name : "install/client"
	property description : "Install everything you need to create a working client instance."

	tell installRulesEngine to exec:{}
	tell installScriptLibraries to exec:{}
	tell installRules to exec:{}	
	tell InstallOFApplicationScripts to exec:{}
end script

script install
	property parent : Task(me)

	tell installRulesEngine to exec:{}
	tell installScriptLibraries to exec:{}
	tell installHazelScript to exec:{}
	tell InstallOFApplicationScripts to exec:{}
	tell installRules to exec:{}	
end script

script BuildUnitTests
	property parent : Task(me)
	property name : "test/build-unit"
	property description : "Build unit tests, but do not run them"
	
	owarn("Due to bugs in OS X Yosemite, building tests requires ASUnit to be installed.")
	tell BuildRulesEngine to exec:{}
	
	makeScriptBundle from "test/Test Hobson.applescript" at "test" with overwriting
end script

script BuildHobsonRuleLibrariesTests
	property parent : Task(me)
	property name : "test/build-script-library"
	property description : "Build script library tests, but do not run them"
	
	owarn("Due to bugs in OS X Yosemite, building tests requires ASUnit to be installed.")
	tell BuildHobsonRuleLibraries to exec:{}
	
	makeScriptBundle from "test/Test Default OmniFocus Rules Library.applescript" at "test" with overwriting
	makeScriptBundle from "test/Test Creating Flow with OmniFocus Rules.applescript" at "test" with overwriting
end script

script BuildOFApplicationScriptTests
	property parent : Task(me)
	property name : "test/build-omnifocus-scripts"
	property description : "Build tests, but do not run them"
	
	owarn("Due to bugs in OS X Yosemite, building tests requires ASUnit to be installed.")
	tell BuildOFApplicationScripts to exec:{}
	
	makeScriptBundle from "test/Test Process Inbox.applescript" at "test" with overwriting
	makeScriptBundle from "test/Test Tidy.applescript" at "test" with overwriting
end script

script BuildHazelScriptTests
	property parent : Task(me)
	property name : "test/build-hazel-scripts"
	property description : "Build tests, but do not run them"
	
	owarn("Due to bugs in OS X Yosemite, building tests requires ASUnit to be installed.")
	tell BuildHazelScripts to exec:{}
	
	makeScriptBundle from "test/Test OmniFocus Rule Processing Daemon.applescript" at "test" with overwriting
end script

script BuildTests
	property parent : Task(me)
	property name : "test/build"
	property description : "Build tests, but do not run them"
	
	owarn("Due to bugs in OS X Yosemite, building tests requires ASUnit to be installed.")

	tell BuildUnitTests to exec:{}
	tell BuildHobsonRuleLibrariesTests to exec:{}
	tell BuildOFApplicationScriptTests to exec:{}
	tell BuildHazelScriptTests to exec:{}	
end script

script RunUnitTests
	property parent : Task(me)
	property name : "test/run-unit"
	property description : "Build and run unit tests"
	property printSuccess : false

	shell for "open" & space & POSIX path of ((path to home folder) as text) & "test.ofocus"

	tell BuildUnitTests to exec:{}
	-- The following causes a segmentation fault unless ASUnit in installed in a shared location

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test Hobson.scptd"))
	run testSuite
end script

script RunRuleTests
	property parent : Task(me)
	property name : "test/run-rules"
	property description : "Build and run unit tests"
	property printSuccess : false

	shell for "open" & space & POSIX path of ((path to home folder) as text) & "test.ofocus"

	tell BuildHobsonRuleLibrariesTests to exec:{}

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test Default OmniFocus Rules Library.scptd"))
	run testSuite

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test Creating Flow with OmniFocus Rules.scptd"))
	run testSuite
end script


script RunFunctionalTests
	property parent : Task(me)
	property name : "test/run-func"
	property description : "Build and run unit tests"
	property printSuccess : false

	shell for "open" & space & POSIX path of ((path to home folder) as text) & "test.ofocus"

	tell BuildOFApplicationScriptTests to exec:{}
	tell BuildHazelScriptTests to exec:{}

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test OmniFocus Rule Processing Daemon.scptd"))
	run testSuite

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test Process Inbox.scptd"))
	run testSuite

	set testSuite to load script POSIX file (joinPath(workingDirectory(), "test/Test Tidy.scptd"))
	run testSuite
end script

script RunTests
	property parent : Task(me)
	property name : "test/run"
	property description : "Build and run all tests"
	property printSuccess : false
	
	shell for "open" & space & POSIX path of ((path to home folder) as text) & "test.ofocus"
	
	tell RunUnitTests to exec:{}
	tell RunRuleTests to exec:{}
	tell RunFunctionalTests to exec:{}	
end script

script uninstallRulesEngine
	property parent : Task(me)
	property name : "uninstall/engine"
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Script Libraries"
	property description : "Remove OmniFocus Rule Engine related libraries from" & space & dir
	
	set targetPath to joinPath(dir, "com.kraigparkinson/Hobson.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")

	set targetPath to joinPath(dir, "com.kraigparkinson/Default OmniFocus Rules Library.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")		

	set targetPath to joinPath(dir, "com.kraigparkinson/Creating Flow with OmniFocus Rules.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")		
end script

script uninstallRuleSets
	property parent : Task(me)
	property name : "uninstall/rules"
	property dir : POSIX path of ((path to home folder from user domain) as text) & "OmniFocus Rules"
	property description : "Remove installed rules from current user directory, " & space & dir
	
	set targetPath to joinPath(dir, "omnirulefile.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")
end script

script uninstallOFApplicationScripts
	property parent : Task(me)
	property name : "uninstall/app-scripts"
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Application Scripts/com.omnigroup.OmniFocus2"
	property description : "Remove OmniFocus Rule Engine related application scripts from" & space & dir
	
	set targetPath to joinPath(dir, "Process Inbox.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")

	set targetPath to joinPath(dir, "Tidy.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")		
end script

script uninstallHazelScripts
	property parent : Task(me)
	property name : "uninstall/hazel"
	property dir : POSIX path of ¬
		((path to library folder from user domain) as text) & "Scripts/Hazel"
	property description : "Remove OmniFocus Rule Engine related application scripts from" & space & dir
	
	set targetPath to joinPath(dir, "OmniFocus Rule Processing Daemon.scptd")
	if pathExists(targetPath) then
		removeItem at targetPath
	end if
	ohai(targetPath & space & "deleted.")
end script

script uninstall
	property parent : Task(me)
	property name : "uninstall"
	property description : "Uninstall all artifacts related to the Hobson"
	property printSuccess : false

	tell uninstallRulesEngine to exec:{}
	tell uninstallRuleSets to exec:{}
	tell uninstallOFApplicationScripts to exec:{}
	tell uninstallHazelScripts to exec:{}
end script 

script VersionTask
	property parent : Task(me)
	property name : "version"
	property description : "Print OmniFocusTransportTextParsingService's version and exit"
	property printSuccess : false
	
	set {n, v} to {name, version} of ¬
		(run script POSIX file (joinPath(workingDirectory(), "Hobson.applescript")))
	ohai(n & space & "v" & v)
end script
