use AppleScript version "2.4"
use scripting additions
use hobson : script "com.kraigparkinson/OmniFocus Rules Engine"

on run	
	
	tell hobson to processInbox()
			
end run