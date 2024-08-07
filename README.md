# alma

Automated Local Mail Archive

_alma_ is an AppleScript designed to automate the local archiving of specific emails and their attachments using the Mail app on macOS.

## Why _alma_?

Managing email archiving and storage can be challenging, especially in an office environment with shared project-specific email accounts accessed via IMAP on multiple computers.
The task of manually keeping an organized and up-to-date local archive of important emails is not only tedious but also feels _soul_-less.

_alma_ addresses this by completely automating the archiving process, helping maintain an organized and easily accessible archive of important emails.
This not only replaces the manual task but also helps manage limited mail server storage by indicating which emails have been archived locally and can therefore be safely deleted from the mail server.

The local archive should be stored in a shared location accessible by all computers using the script if they want it to work with the same local archive.
If not, it is perfectly possible to generate different local archives, even for the same account, if different computers use different settings.

## How It Works

### Configuration

Set up the config.txt file to define archiving preferences.

### Flag Emails

Flag emails accordingly in the Mail app.

### Archiving Scenarios

1. Mail Rule

   Set up a rule in the Mail app that executes the script for emails satisfying the rule. Ensure the rule filters at least by `Account`.

2. Apply Rules

   Select an email, right-click, and choose `Apply Rules` to manually run the script on the selected account. For this to work, the rule must be pre-configured for the selected account.

3. Script Editor (debug mode)

   Run the script directly in the Script Editor app to inspect logs and debug. For this, it is not necessary to define any rules as the script will run on the account of the last selected email.

   NOTE: Run the script in debug mode with caution, as this type of manual execution may affect the local archive, for example by archiving mails from a wrong account by mistake.

In all three cases:

- The script loads the configurations and inspects the account mailboxes to detect emails to archive.

- It avoids re-archiving emails that have already been processed and skips saving small attachment files like logos and other icons.

- The emails are stored chronologically as .eml files, which allows them to be easily previewed and inspected in Finder.

- Archived emails are re-flagged in the Mail app as feedback to indicate which emails already have a local copy.

- The final result is a simple and automatically organized local folder structure based on your configuration mapping.

## Example

### 1. Setup

#### Emails:

- Email 1: No flag

  - Subject: I'm running late
  - Sender: white.rabbit@follow.me
  - Mailbox: Inbox
  - Received: 1 hour ago
  - Attachments: none

- Email 2: Green flag

  - Subject: Notes from last meeting
  - Sender: alice@wonderland.com
  - Mailbox: Inbox
  - Received: 27 Dec 2024
  - Attachments: tea_party_notes.docx

- Email 3: Red flag

  - Subject: Fwd: Next To-Dos
  - Sent-to: red.queen@royal-mail.com
  - Mailbox: Sent
  - Sent: 26 Nov 2024
  - Attachments: royal-mail-logo.png

#### Config:

Archive any emails from the last 14 days with red and green flags based on their mailboxes and email addresses, placing them in the corresponding folders specified in the folder mapping section of the configuration file.

For example:

```
# Preferences:
LOOKUP_WINDOW : 14
FLAG_TO_ARCHIVE : green
FLAG_IMPORTANT : red
FLAG_AS_ARCHIVED : grey

# Settings:
ARCHIVE_BASE_PATH : /Archive/base/path
FOLDER_NAME_INBOX : Inbox
FOLDER_NAME_SENT : Sent

# Folder mapping:
@wonderland.com : 01_Wonderland
@royal-mail : 02_Royal_Mail
@follow.me : 03_Follow
```

### 2. Result

#### Folder Structure:

When any of the archiving scenarios are met, the flagged emails will be processed and stored.

```
/Archive/base/path/
│
├── 01_Wonderland/
│   ├── Inbox/
│   │   ├── 2024-12-27_Notes from last meeting.eml  <- Email 2
│   │   └── 2024-12-27_Notes from last meeting/
│   │       └── tea_meeting_notes.docx              <- Email 2 attachments
│   └── Sent/...
│
└── 02_Royal_Mail/
    ├── Inbox/...
    └── Sent/
        └── 2024-11-26_Fwd_ Next To-Dos.eml  <- Email 3, don't archive logos
```

#### Emails:

- Email 1: No flag -- untouched

- Email 2: Grey flag -- green flag turned grey indicates successful archiving

- Email 3: Red flag -- very important emails are archived, but remain flagged

## Installation

1.  Download and copy files:

    Download the code, go to the `alma` folder and copy its contents to `/Users/your-user-name/Library/Application Scripts/com.apple.mail` to make it accessible to the Mail app.

2.  Compile the AppleScript files:

    Open a terminal at the `com.apple.mail` folder and compile the script files using `osacompile -o` by running the following command:

         find ./ -name "*.scpt" | while read -r file; do osacompile -o "$file" "$file"; done

3.  Create Mail Rule:

    Create a new rule in the Mail app defining at least an `Account` condition.

4.  Set Rule Action:

    Define the rule to perform the action `Run AppleScript` and select to run `alma.scpt`

From now on, the script will run automatically on every new incoming mail that satisfies the rule or by following one of the other methods mentioned above (running `Apply Rules` or in _debug mode_).

## Notes

- Simultaneous use with multiple accounts archiving to different locations is not supported yet. The script uses a single configuration and archives all emails to the specified location. Ensure the script is configured for one account at a time to maintain separate archives for different accounts.
- This script is an early version and, while it appears to work fine, it hasn't been thoroughly tested. Some errors or bugs should be expected.
- Developed for Mail app Version 16.0 on macOS 14.5.
