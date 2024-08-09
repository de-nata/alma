property name : "archiver"

# Import scripts:
property SCRIPT_FILES : "src:files.scpt"
property SCRIPT_MAIL : "src:mail.scpt"

on load_script(fileName)
	tell application "Finder" to set myPath to (container of (path to me) as string)
	return load script file (myPath & fileName)
end load_script


# Do not archive attachments of these file types if they are smaller than the minimum size:
property FILTER_FILES : {".png", ".jpg", ".ics"}
property FILTER_MIN_SIZE : 1024 * 1024 * 0.5 # 0.5 MB in bytes


-- Return a HFS colon-delimited path to the archive folder
on get_archive_folder(theEmail, configSettings, configMapping) --> text
    set scriptFiles to my load_script(SCRIPT_FILES)
    set scriptMail to my load_script(SCRIPT_MAIL)

    tell scriptFiles to set archiveBasePath to get_hfs_path(configSettings's ARCHIVE_BASE_PATH)

    tell scriptMail
        if mailbox_is_sent(theEmail) then
            set emailAddress to get_first_recipient(theEmail)
            set mailboxFolder to configSettings's SENT_FOLDER
        else
            set emailAddress to get_sender(theEmail)
            set mailboxFolder to configSettings's INBOX_FOLDER
        end if
        set emailDomain to extract_domain(emailAddress)
    end tell

    set domainFolder to my _get_domain_folder(emailDomain, configMapping)

    return (archiveBasePath & domainFolder & ":" & mailboxFolder & ":") # HFS colon-delimited path
end get_archive_folder


-- Return the corresponding folder name for an email address using the DOMAIN_TO_FOLDER
on _get_domain_folder(emailDomain, configMapping) --> text
	repeat with domainToFolder in configMapping's DOMAIN_TO_FOLDER
		set {domainName, folderName} to domainToFolder
		if domainName contains emailDomain then return folderName
	end repeat
	return (configMapping's DOMAIN_UNKNOWN_PREFIX & emailDomain)
end _get_domain_folder


-- Save an email as .eml and its attachments (if any) and return the result of the operation
on archive_email(theEmail, archiveFolder, emlFileName) --> boolean
    set emlFilePath to (archiveFolder & emlFileName)

    # Exit early if the email is already archived:
    if my _is_already_archived(emlFilePath) then return false

    set scriptFiles to my load_script(SCRIPT_FILES)
    set scriptMail to my load_script(SCRIPT_MAIL)

    # Proceed with archiving:
    tell scriptFiles to if not (does_path_exist(archiveFolder)) then create_folder(archiveFolder)
    tell scriptMail # this can be slow if the email is big
        set emailSource to get_source(theEmail)
        set emailAttachments to get_attachments(theEmail)
    end tell
    try
        set wasArchived to my save_as_eml(emailSource, emlFilePath) # faster
        -- set wasArchived to my save_as_eml_in_chunks(emailSource, emlFilePath) # slower
        set wantedAttachments to my filter_attachments(emailAttachments, FILTER_FILES, FILTER_MIN_SIZE)
        if wasArchived and (count of wantedAttachments) > 0 then
            set wasArchived to my save_attachments(wantedAttachments, emlFilePath)
        end if

    on error errMsg number errNum
        error "[ERROR] Failed to archive the email:" & linefeed & errMsg number errNum
    end try

    return wasArchived
end archive_email


on _is_already_archived(emlFilePath) --> boolean
    set scriptFiles to my load_script(SCRIPT_FILES)

    tell scriptFiles to set alreadyArchived to does_path_exist(emlFilePath)
    if alreadyArchived then
        log "[DEBUG] Email already archived"
    end if
    return alreadyArchived
end _is_already_archived


# This is slow when saving big emails, but saving in chunks seems to be even slower
on save_as_eml(emailSource, emlFilePath)
    set wasSaved to false

    try
        set fileDescriptor to open for access emlFilePath with write permission
        set eof of fileDescriptor to 0
        write emailSource to fileDescriptor starting at eof

        close access fileDescriptor
        set wasSaved to true
        log "[DEBUG] Saved email: " & (POSIX path of emlFilePath)

    on error errMsg number errNum
        try
            close access fileDescriptor
        end try
        error "[ERROR] Failed to save the email:" & linefeed & errMsg number errNum
    end try

    return wasSaved
end save_as_eml


# See 'save_as_eml'
on save_as_eml_in_chunks(emailSource, emlFilePath)
    set wasSaved to false
    set emlFilePOSIX to POSIX path of emlFilePath

    try
        set fileDescriptor to open for access (POSIX file emlFilePOSIX) with write permission
        set eof of fileDescriptor to 0

        set chunkSize to 1024 * 1024 * 32 -- in 32 Mb chunks ??
        set dataLength to length of emailSource
        set startPosition to 1

        repeat while startPosition < dataLength
            set endPosition to (startPosition + chunkSize - 1)
            if endPosition > dataLength then set endPosition to dataLength

            set dataChunk to text startPosition thru endPosition of emailSource
            write dataChunk to fileDescriptor starting at eof
            set startPosition to endPosition + 1
        end repeat

        close access fileDescriptor
        set wasSaved to true
        log "[DEBUG] Saved email: " & emlFilePOSIX

    on error errMsg number errNum
        try
            close access fileDescriptor
        end try
        error "[ERROR] Failed to save the email:" & linefeed & errMsg number errNum
    end try

    return wasSaved
end save_as_eml_in_chunks


-- Remove unwanted attachments (like logos and other junk)
on filter_attachments(emailAttachments, filterFileTypes, filterMinFileSize) --> list[mail attachments]
    set scriptFiles to my load_script(SCRIPT_FILES)
    set filteredAttachments to {}

    try
        repeat with eachFile in emailAttachments
            set fileName to name of eachFile

            tell scriptFiles to set fileExtension to get_file_extension(fileName)

            if fileExtension is not in filterFileTypes then # exit early
                set end of filteredAttachments to eachFile
            else
                tell application "Mail" to set fileSize to (file size of eachFile)
                if fileSize > filterMinFileSize then # filter out smaller files
                    set end of filteredAttachments to eachFile
                end if
            end if
        end repeat

        set countOriginal to count of emailAttachments
        set countFiltered to count of filteredAttachments
        log "[DEBUG] Found " & countFiltered & " of " & countOriginal & " attachments to archive"

    on error errMsg number errNum
        error "[ERROR] Failed filter attachments:" & linefeed & errMsg number errNum
    end try

    return filteredAttachments
end filter_attachments


on save_attachments(emailAttachments, emlFilePath) --> boolean
    set scriptFiles to my load_script(SCRIPT_FILES)
    set wereSaved to false
    set attachmentsFolder to (text 1 thru -5 of emlFilePath) # remove ".eml"

    try
        tell scriptFiles
            create_folder(attachmentsFolder) # /{archiveFolder}/{emlFileName}
			repeat with eachFile in emailAttachments
				set fileName to sanitize_filename(name of eachFile)
				set filePath to POSIX path of (attachmentsFolder & ":" & fileName)

				try # BUG: this seems to be failing with some attachments, we log and let it continue for now
					save eachFile in POSIX file filePath
				on error errMsg number errNum
					set errDetails to errDetails & "fileName: " & fileName & linefeed
					set errDetails to errDetails & "filePath: " & filePath & linefeed
					set errMsg to "[ERROR] Failed to save attachment:" & linefeed & errDetails & errMsg
					display dialog errMsg & linefeed & "(Error Number: " & errNum & ")"
				end try

			end repeat
        end tell

        set wereSaved to true
        log "[DEBUG] Saved " & count of emailAttachments & " attachments"

    on error errMsg number errNum
        error "[ERROR] Failed to save attachments:" & linefeed & errMsg number errNum
    end try

    return wereSaved
end save_attachments

