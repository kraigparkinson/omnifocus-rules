(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's name. *)
property name : "OmniFocus Rule Processing Daemon"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's id. *)
property id : "OmniFocus Rule Processing Daemon"

--use AppleScript version "2.4"
--use scripting additions

property hobson : script "com.kraigparkinson/Hobson"

(*)
property theFile : missing value
property inputAttributes : missing value 

hazelProcessFile(theFile, inputAttributes)
*)
on hazelProcessFile(theFile, inputAttributes)
	tell hobson's RuleProcessingService to processAllRules()
	
	return {hazelStop:false, hazelSwitchFile:missing value, hazelOutputAttributes:{ }}
end hazelProcessFile