property name : "mail"

property MAILBOX_INBOX : "INBOX"
property MAILBOX_SENT : "Sent"


-- Return the list of all flagged emails in the mailboxes in 'mailboxList', within the past 'lookupWindow' days
on get_flagged_emails(mailboxList, lookupWindow) --> list[email]
    set flaggedEmails to {}
    set lookupDate to (current date - (lookupWindow * days))
    tell application "Mail"
        repeat with eachMailbox in mailboxList
            set flaggedEmails to flaggedEmails & ¬
                (messages of eachMailbox whose date received > lookupDate and flagged status is true)
        end repeat
    end tell
    return flaggedEmails
end get_flagged_emails


-- Filter a list of flagged emails with the given flag values
on filter_by_flag_values(emailList, flagValues) --> list[email]
    set matchedEmails to {}
    tell application "Mail"
        repeat with eachEmail in emailList
            if flag index of eachEmail is in flagValues then
                set end of matchedEmails to eachEmail
            end if
        end repeat
    end tell
    return matchedEmails
end filter_by_flag_values


on is_flagged_with_color(theEmail, theFlag) --> boolean
    tell application "Mail" to return (flagged status of theEmail is true and flag index of theEmail is theFlag)
end is_flagged_with_color


on flag_as_processed(theEmail, theFlag) --> nothing
    tell application "Mail" to set flag index of theEmail to theFlag
end flag_as_processed


on get_received_date(theEmail) --> date
    tell application "Mail" to return date received of theEmail
end get_received_date


on get_subject(theEmail) --> text
    tell application "Mail" to return subject of theEmail
end get_subject


-- Return true if the email is in the sent mailbox
on mailbox_is_sent(theEmail) --> boolean
    tell application "Mail" to set mailboxName to name of mailbox of theEmail as string
    return mailboxName contains MAILBOX_SENT
end mailbox_is_sent


on get_first_recipient(theEmail) --> text
    -- tell application "Mail" to return item 1 of (address of to recipients of theEmail)
    tell application "Mail" to set allRecipients to (address of to recipients of theEmail)
    return item 1 of allRecipients
end get_first_recipient


on get_sender(theEmail) --> text
    tell application "Mail" to return sender of theEmail
end get_sender


-- Extract the domain name of an email address (between the "@" and the last ".")
on extract_domain(emailAddress) --> text
	set stringLength to length of emailAddress
	set reversedAddress to (reverse of characters of emailAddress) as string
	set indexAt to (stringLength - (offset of "@" in reversedAddress))
	set indexDot to (stringLength - (offset of "." in reversedAddress))
	return text (indexAt + 2) thru indexDot of emailAddress
end extract_domain


on get_source(theEmail) --> text
    # this loads the source, can be slow for large attachments
    tell application "Mail" to return source of theEmail
end get_source


on get_attachments(theEmail) --> list[mail attachments]
    tell application "Mail" to return mail attachments of theEmail
end get_attachments

