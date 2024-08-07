property name : "files"


-- Format a slash-delimited path to an HFS colon-delimited path
on get_hfs_path(pathString) --> text
    if pathString does not end with "/" then set pathString to pathString & "/"
    set pathHFS to (POSIX file pathString) as text
    return pathHFS
end get_hfs_path


-- Check if a HFS path to a file or folder exists
on does_path_exist(pathHFS) --> boolean
	try
		set fileAlias to file pathHFS as alias
		return true
	on error
		return false
	end try
end does_file_exist


-- Create a folder if it doesn't exist, including any intermediate folders
on create_folder(pathHFS) --> nothing
    try
        do shell script "mkdir -p " & quoted form of (POSIX path of pathHFS)
    on error errMsg number errNum
        error "[ERROR] Failed to create the folder:" & linefeed & errMsg number errNum
    end try
end create_folder


-- Get the parent folder of a HFS colon-delimited path (or a POSIX file object)
on get_parent_folder(pathHFS) --> text
    return do shell script "dirname " & quoted form of (POSIX path of pathHFS)
end get_parent_folder


on get_file_extension(fileName) --> text
    set {ASTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "."}
    set fileExtension to "." & (last text item of fileName)
    set AppleScript's text item delimiters to ASTID
    return fileExtension
end get_file_extension


-- Replace invalid characters from an email subject, like '/' or ':', to use it in a filename
on sanitize_filename(fileName) --> text
    set illegalChars to quoted form of "/:"
    set replaceWith to quoted form of "_"
    try
        return do shell script "echo " & quoted form of fileName & " | tr " & illegalChars & space & replaceWith
    on error errMsg number errNum
        error "[ERROR] Failed to sanitize the email subject:" & linefeed & errMsg number errNum
    end try
end sanitize_filename


-- Convert a date to an ISO 8601 string "YYYY-MM-DD" to use as prefix in a filename
on format_iso_date(theDate) --> text
    set isoDate to (theDate as «class isot» as string)
    return text 1 thru 10 of isoDate
end format_iso_date

