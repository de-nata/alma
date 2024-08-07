property name : "alma"
property version : "0.5.0"

(*
Automated Local Mail Archive
Automatically archive local copies of specific emails and attachments based on sender or recipient.

author: https://github.com/de-nata
url: https://github.com/de-nata/alma
license: Licensed under the MIT License. See https://opensource.org/licenses/MIT for details.
*)

# Import scripts:
property SCRIPT_ARCHIVER : "src:archiver.scpt"
property SCRIPT_CONFIG : "src:config.scpt"
property SCRIPT_FILES : "src:files.scpt"
property SCRIPT_MAIL : "src:mail.scpt"

on load_script(fileName) --> script
	tell application "Finder" to set myPath to (container of (path to me) as string)
	return load script file (myPath & fileName)
end load_script

# Use to get the account mailboxes:
property MAILBOX_INBOX : "INBOX"
property MAILBOX_SENT : "Sent"

-----------------------------------------------------------------------------------------------------------------------

# Run in one of the following cases:
# - automatically on every incoming email that satisfies the defined rule
# - manually with right-click + 'Apply Rules'
using terms from application "Mail"
    on perform mail action with messages theEmails for rule theRule

        my run_script(theEmails, my load_config())

    end perform mail action with messages
end using terms from


# Run in the Script Editor to check the logs:
on run

	tell application "Mail" to set theEmails to selection

	set startTime to my perf_counter()

	if (count of theEmails) > 0 then
		my run_script(theEmails, my load_config())
	else
		display dialog "[WARNING] No emails selected."
	end if

	log "[INFO] done!"

	set elapsedTime to ((my perf_counter()) - startTime) / 1000
	log "[DEBUG] took: " & elapsedTime & " s"

end run

-----------------------------------------------------------------------------------------------------------------------

on run_script(theEmails, loadedConfig) --> nothing
    set scriptArchiver to my load_script(SCRIPT_ARCHIVER)
    set scriptMail to my load_script(SCRIPT_MAIL)

    set PREFS to loadedConfig's PREFS
    set LOOKUP_WINDOW to PREFS's LOOKUP_WINDOW
    set FLAG_TO_ARCHIVE to PREFS's FLAG_TO_ARCHIVE
    set FLAG_IMPORTANT to PREFS's FLAG_IMPORTANT
    set FLAG_AS_ARCHIVED to PREFS's FLAG_AS_ARCHIVED

    try
        using terms from application "Mail"
            set theAccount to account of mailbox of item 1 of theEmails
            set theMailboxes to {mailbox MAILBOX_INBOX of theAccount, mailbox MAILBOX_SENT of theAccount}
        end using terms from

        tell scriptMail
            set flaggedEmails to get_flagged_emails(theMailboxes, LOOKUP_WINDOW)
            log "[DEBUG] Flagged emails: " & (count of flaggedEmails)
            set matchedEmails to filter_by_flag_values(flaggedEmails, {FLAG_TO_ARCHIVE, FLAG_IMPORTANT})
            log "[DEBUG] Matched emails: " & (count of matchedEmails)
        end tell

        log "[INFO] Found a total of " & (count of matchedEmails) & " emails flagged for archiving"

        set archivedEmails to {}
        if (count of matchedEmails) > 0 then
            repeat with eachEmail in matchedEmails
                # emlFileName = {YYYY-MM-DD}_{SUBJECT}.eml
                set emlFileName to my get_eml_file_name(eachEmail)

                tell scriptArchiver
                    # archiveFolder = {ARCHIVE_BASE_PATH}:{DOMAIN_FOLDER}:{INBOX_FOLDER or SENT_FOLDER}:
                    set archiveFolder to get_archive_folder(eachEmail, loadedConfig's SETTINGS, loadedConfig's MAPPING)

                    log "[DEBUG] >>> Archiving: " & emlFileName
                    set successfullyArchived to archive_email(eachEmail, archiveFolder, emlFileName)
                end tell

                if successfullyArchived then
                    tell scriptMail
                        if not is_flagged_with_color(eachEmail, FLAG_IMPORTANT) then
                            flag_as_processed(eachEmail, FLAG_AS_ARCHIVED)
                        end if
                    end tell
                    set end of archivedEmails to eachEmail
                    log "[DEBUG] Email archived successfully: " & emlFileName
                end if

            end repeat
        end if

        log "[INFO] Archived a total of " & (count of archivedEmails) & " emails"

    on error errMsg number errNum
        display dialog errMsg & linefeed & "(Error Number: " & errNum & ")"
        return
    end try

end run_script


-- Build a .eml filename with the received date as prefix: {YYYY-MM-DD}_{SUBJECT}.eml
on get_eml_file_name(theEmail) --> string
    set scriptMail to my load_script(SCRIPT_MAIL)
    set scriptFiles to my load_script(SCRIPT_FILES)

    tell scriptMail
        set emailDate to get_received_date(theEmail)
        set emailSubject to get_subject(theEmail)
    end tell
    tell scriptFiles
        set datePrefix to format_iso_date(emailDate)
        set fileName to sanitize_filename(emailSubject)
    end tell

    return datePrefix & "_" & fileName & ".eml"
end get_eml_file_name


-- CONFIG = {PREFS:{...}, SETTINGS:{...}, MAPPING:{...}}
on load_config() --> record
    try
        set scriptConfig to my load_script(SCRIPT_CONFIG)
        tell scriptConfig to return its load_config()
    on error errMsg number errNum
        display dialog errMsg & linefeed & "(Error Number: " & errNum & ")"
        return
    end try
end load_config


on perf_counter() --> number
	return (do shell script "perl -MTime::HiRes -e 'print int(Time::HiRes::time() * 1000)'") as integer
end perf_counter

