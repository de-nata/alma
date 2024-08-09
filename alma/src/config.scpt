property name : "config"

(*
This script expects the config.txt to be structured in sections delimited by commented lines, with
each section containing lines of key/value pairs.

In the current version of the script, the config files must have three sections, which will be
parsed into the CONFIG record:

    CONFIG = {PREFS:{...}, SETTINGS:{...}, MAPPING:{...}}

If this changes in the future, the script will need to be updated.
*)

# Properties:
property CONFIG_FILE : "config.txt"
property CONFIG_CHAR_COMMENT : "#"
property CONFIG_CHAR_DELIMITER : ":"
property FLAG_COLORS : { ¬
	{"red", 0}, {"orange", 1}, {"yellow", 2}, {"green", 3}, {"blue", 4}, {"purple", 5}, {"grey", 6} ¬
}

# CONFIG_FILE's prefs:
property LOOKUP_WINDOW : "LOOKUP_WINDOW"
property FLAG_TO_ARCHIVE : "FLAG_TO_ARCHIVE"
property FLAG_IMPORTANT : "FLAG_IMPORTANT"
property FLAG_AS_ARCHIVED : "FLAG_AS_ARCHIVED"

# CONFIG_FILE's settings:
property ARCHIVE_BASE_PATH : "ARCHIVE_BASE_PATH"
property FOLDER_NAME_INBOX : "FOLDER_NAME_INBOX"
property FOLDER_NAME_SENT : "FOLDER_NAME_SENT"
property DATETIME_FORMAT : "DATETIME_FORMAT"

# CONFIG:
property DOMAIN_UNKNOWN_PREFIX : "xx_" # domains not found in the CONFIG's mapping will get this prefix

property PREFS : ¬
	{LOOKUP_WINDOW:"", FLAG_TO_ARCHIVE:"", FLAG_IMPORTANT:"", FLAG_AS_ARCHIVED:""}
property SETTINGS : ¬
	{ARCHIVE_BASE_PATH:"", INBOX_FOLDER:"", SENT_FOLDER:"", DATETIME_FORMAT:""}
property MAPPING : ¬
	{DOMAIN_TO_FOLDER:{}, DOMAIN_UNKNOWN_PREFIX:DOMAIN_UNKNOWN_PREFIX}

property CONFIG : {PREFS:PREFS, SETTINGS:SETTINGS, MAPPING:MAPPING}

-----------------------------------------------------------------------------------------------------------------------

# Run for testing
on run

	# In a direct run, 'path of me' already points to the 'src' folder,
	# however config.txt is in the project's root folder
	set _get_parent_folder_of_me to _get_parent_parent_folder_of_me

	set CONFIG to my load_config()
	log CONFIG's PREFS
	log CONFIG's SETTINGS
	log CONFIG's MAPPING

    return CONFIG

end run

-----------------------------------------------------------------------------------------------------------------------

# Read a config.txt file located in the same folder as the script and return a record of its contents
on load_config() --> record: CONFIG
	try
		# Parse the config.txt file:
		set projectFolder to my _get_parent_folder_of_me() # overridden in a direct run
		set configFile to (projectFolder & CONFIG_FILE)
		set configSections to my _read_config_file(configFile)
		# Load config.txt as a record:
		set CONFIG to my _load_config_record(configSections)

	on error errMsg number errNum
		error "[ERROR] Failed to load config:" & linefeed & errMsg number errNum
	end try

	return CONFIG
end load_config


-- Return a list of lists of key/value pairs for each section of the config file
on _read_config_file(configFile) --> list[list]
	set configSections to {}
	try
		set fileContent to read file configFile
		set currentSection to {}
		repeat with eachLine in paragraphs of fileContent
			if eachLine starts with CONFIG_CHAR_COMMENT then # identify sections using "#" at the beginning of a line
				if (count of currentSection) > 0 then # allow multi-line comments between sections
					set end of configSections to currentSection
				end if
				set currentSection to {}
			else if eachLine contains CONFIG_CHAR_DELIMITER then # identify key/value pairs
				set {configKey, configValue} to my _parse_config(eachLine, CONFIG_CHAR_DELIMITER)
				set end of currentSection to {configKey, configValue}
			end if
		end repeat
		if (count of currentSection) > 0 then
			set end of configSections to currentSection
		end if
	on error errMsg number errNum
		error "[ERROR] Failed to parse config file:" & linefeed & errMsg number errNum
	end try
	return configSections
end _read_config_file


on _load_config_record(configSections) --> record
	set {configPrefs, configSettings, configMapping} to configSections

	# Load the preferences and settings: -- It ain't elegant, but it's honest work.
	set CONFIG's PREFS's LOOKUP_WINDOW to my _get_value(configPrefs, LOOKUP_WINDOW) as number
	set CONFIG's PREFS's FLAG_TO_ARCHIVE to my _get_value(FLAG_COLORS, my _get_value(configPrefs, FLAG_TO_ARCHIVE))
	set CONFIG's PREFS's FLAG_IMPORTANT to my _get_value(FLAG_COLORS, my _get_value(configPrefs, FLAG_IMPORTANT))
	set CONFIG's PREFS's FLAG_AS_ARCHIVED to my _get_value(FLAG_COLORS, my _get_value(configPrefs, FLAG_AS_ARCHIVED))
	set CONFIG's SETTINGS's ARCHIVE_BASE_PATH to my _get_value(configSettings, ARCHIVE_BASE_PATH)
	set CONFIG's SETTINGS's INBOX_FOLDER to my _get_value(configSettings, FOLDER_NAME_INBOX)
	set CONFIG's SETTINGS's SENT_FOLDER to my _get_value(configSettings, FOLDER_NAME_SENT)
	set CONFIG's SETTINGS's DATETIME_FORMAT to my _get_value(configSettings, DATETIME_FORMAT)

	# Load the domain-to-folder mapping:
	set CONFIG's MAPPING's DOMAIN_TO_FOLDER to configMapping

	return CONFIG
end _load_config_record


on _parse_config(configLine, delimiterChar) ---> list[string, string]
	set echoCommand to "echo " & quoted form of configLine
    # Split at the first delimiter and return both parts:
	set awkCommand to "awk -F" & quoted form of delimiterChar & " '{print $1; print substr($0, index($0,$2))}'"
    # Trim leading and trailing spaces and tabs:
	set sedCommand to "sed 's/^[[:space:]]*//; s/[[:space:]]*$//'"
    set {configKey, configValue} to paragraphs of ¬
        (do shell script (echoCommand & " | " & awkCommand & " | " & sedCommand))
	return {configKey, configValue}
end _parse_config


on _get_value(keyValuePairs, theKey) --> any
    repeat with aPair in keyValuePairs
        set {aKey, aValue} to aPair
        if aKey = theKey then return aValue
    end repeat
    return null
end _get_value


on _get_parent_folder_of_me() --> text
	tell application "Finder" to return (container of (path to me) as string)
end _get_parent_folder_of_me


on _get_parent_parent_folder_of_me() --> text
	tell application "Finder" to return (container of (container of (path to me)) as string)
end _get_parent_parent_folder_of_me

