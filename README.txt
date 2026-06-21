Author
	-Matthew Visser
	-VISSMJ1
	-Last updated on 26/05/2026
Project details
e-mail,birth date,groups,sharedFolder
linus.torvalds@linux.org,1969/12/28,sudo,staff,/staffData
alice.jones@example.com,1985/07/22,staff,/staffData
bob.brown@example.com,1992/11/08,staff,teachers,/staffData
jane.doe@example.com,1995/13/45,staff,/staffData


user_manager.shMain entry point — parses arguments, validates input, runs processing loopprocess_user.shCore logic — creates user, assigns groups, sets up folder, symlink, and aliasgenerate_username.shDerives username from email (e.g. tLinus from linus.torvalds@linux.org)create_group.shCreates a Linux group if it does not already existsetup_shared_folder.shCreates shared folder with 770 permissions and setgid bitdownload_file.shDownloads a remote CSV and validates it before processingval_local_file.shValidates a local CSV file exists and is readablelog_message.shProvides log_message (to file) and console_message (to stdout)

Each run produces a timestamped log file: user_manager_YYYYMMDD_HHMMSS.log
LevelMeaningINFONormal operation — user created, group added, folder configuredWARNNon-fatal — group or user already exists, safely skippedERRORFatal per-user — invalid date or creation failure, user skipped