use AppleScript version "2.4"
use scripting additions
use hobson : script "com.kraigparkinson/OmniFocus Rules Engine"

property name : "Process Inbox"
property version : "1.0.0"
property id : "Process Inbox"

on run	
	
	tell hobson to processInbox()
			
end run