use AppleScript version "2.4"
use scripting additions

(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's name. *)
property name : "OmniFocus Rule Processing Daemon"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's version. *)
property version : "1.0.0"
(*! @abstract <em>[text]</em> OmniFocus Rule Processing Daemon's id. *)
property id : "OmniFocus Rule Processing Daemon"


use hobson : script "com.kraigparkinson/Hobson"

(*)
property theFile : missing value
property inputAttributes : missing value 

hazelProcessFile(theFile, inputAttributes)
*)
on hazelProcessFile(theFile, inputAttributes)
	log "Starting to process OmniFocus file."
--	tell hobson's RuleProcessingService to processAllRules()
	tell hobson's RuleProcessingService to processInbox()
	
	log "Finished processing OmniFocus file."
end hazelProcessFile

on run
	hazelProcessFile(missing value, missing value)
end run