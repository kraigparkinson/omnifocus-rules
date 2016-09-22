use Rules : script "com.kraigparkinson/Hobson"

property parent : Rules

script InboxConfig
	property parent : RuleSet(me)
	property name : "Inbox"
	property target : Rules's Inbox
	
end script	
