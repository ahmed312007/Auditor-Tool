================================================================
File Auditor & Backup Tool - README
Operating Systems Course - Alexandria National University
================================================================

1. TEAM MEMBERS
----------------------------------------------------------------
- [Ahmed Mahmoud Ahmed] - [2406011]

Distribution of work:
just me


2. PROJECT DESCRIPTION
----------------------------------------------------------------
A menu-driven Bash script that audits a directory (contents,
permissions, extensions) and protects it with timestamped backups.
The tool can be used interactively through a menu, or directly
from the command line for a single action.

Main features:
- Scan a directory and count files / folders.
- Audit read/write/execute permissions for the current user.
- Report file counts per extension (txt, log, sh, jpg, other).
- Search for files by name.
- Back up every readable file with a timestamp.
- List existing backups.
- Restore a chosen backup without overwriting originals.
- Log every action to auditor.log.


3. FILES INCLUDED
----------------------------------------------------------------
auditor.sh      Main script: menu, main logic, all feature functions.
lib.sh          Helper functions: log_info, log_error, log_action,
                require_dir.
README.txt      This file.

Note: The backups/ folder and auditor.log are NOT included in the
submission, as required by the assignment.


4. HOW TO RUN
----------------------------------------------------------------
Requirements:
- Linux with Bash 4+ (associative arrays are used).
- Standard tools: find, ls, cp, date, basename.

Make the scripts executable (one time only):
    chmod +x auditor.sh lib.sh

Run from inside the project folder:

    # Interactive menu (default: current directory)
    ./auditor.sh

    # Interactive menu on a specific directory
    ./auditor.sh ../sample_data

    # Single action, then exit
    ./auditor.sh ../sample_data scan
    ./auditor.sh ../sample_data perm
    ./auditor.sh ../sample_data ext
    ./auditor.sh ../sample_data backup


5. MENU OPTIONS
----------------------------------------------------------------
1) Scan directory       - list [file]/[dir] entries and totals.
2) Permission audit     - show rwx flags per file + totals of
                          unreadable and executable files.
3) Extension report     - count files per extension.
4) Search file          - ask for text, list matching filenames.
5) Backup all           - copy readable files to backups/ with
                          name_YYYYMMDD_HHMMSS.bak.
6) List backups         - show saved backups or "(no backups yet)".
7) Restore backup       - copy a chosen backup back as
                          restored_<name> (never overwrites).
8) Exit


6. EXPECTED OUTPUT EXAMPLES
----------------------------------------------------------------
Scan of sample_data:
    [file] auth.log
    [dir] docs
    [file] notes.txt
    [file] photo1.jpg
    [dir] photos
    [file] readme.md
    [file] run_me.sh
    [file] secret.dat
    [file] system.log
    [file] todo.txt
    Files: 8 Folders: 2

Permission audit:
    rw- auth.log
    rw- notes.txt
    rw- photo1.jpg
    rw- readme.md
    rwx run_me.sh
    --- secret.dat
    rw- system.log
    rw- todo.txt
    Unreadable files: 1 Executable files: 1

Extension report:
    jpg : 1
    log : 2
    other : 2
    sh : 1
    txt : 2


7. DESIGN NOTES
----------------------------------------------------------------
- One function per feature, as required. Variables inside functions
  are declared with 'local'.
- Helper functions live in lib.sh and are loaded with:
      source "$(dirname "$0")/lib.sh"
- require_dir stops the script with an error if the target
  directory does not exist.
- Every feature calls log_action, so auditor.log receives one
  line per operation: "<date> <time> <action>".
- Variables that may contain spaces are always quoted: "$f".
- Original files are never overwritten or deleted:
    * backup_all only copies files (cp), never moves them.
    * restore_backup checks if the target exists before copying
      and refuses to overwrite.
- Error handling:
    * Missing directory      -> require_dir returns 1, script exits.
    * Unreadable file        -> skipped with log_error in backup.
    * Backup name not found  -> log_error + return 1 in restore.
    * Wrong menu choice      -> log_error, menu is shown again.


8. TESTING PERFORMED
----------------------------------------------------------------
We tested the following cases:

- Normal directory (sample_data): scan, perm, ext all produce
  the expected output shown in section 6.
- Non-existent directory: error message, script exits with 1.
- Empty directory: "Files: 0 Folders: 0".
- Unreadable file (secret.dat with chmod 000): counted as
  unreadable and skipped during backup.
- Backup: creates backups/ if missing, saves readable files
  with timestamps, reports saved and skipped counts.
- List backups: shows filenames, or "(no backups yet)" when
  the folder is missing or empty.
- Restore:
    * Valid name      -> creates restored_<name> in the folder.
    * Invalid name    -> error, returns 1.
    * Existing target -> refuses to overwrite.
- Menu: wrong choice shows an error and the menu reappears.
- Syntax check: bash -n auditor.sh passes.


9. KNOWN NOTES
----------------------------------------------------------------
- Permission audit reflects the permissions of the user running
  the script. Running as root will show all files as readable,
  even if their mode is 000.
- Backups use the format name_YYYYMMDD_HHMMSS.bak. If a file
  already has an extension, it is replaced by the timestamp:
      notes.txt -> notes_20260101_120000.bak
- The script must be run from inside its own folder (or use an
  absolute path), because lib.sh is loaded relative to the
  script location.
- On newer coreutils, "cp -n" may print a portability warning.
  We avoid it by checking the target manually before copying.


10. HOW TO VERIFY QUICKLY
----------------------------------------------------------------
From inside the submission folder:

    bash -n auditor.sh
    ./auditor.sh ../sample_data scan
    ./auditor.sh ../sample_data perm
    ./auditor.sh ../sample_data ext
    ./auditor.sh ../sample_data backup
    ./auditor.sh ../sample_data          # open menu, try 6 and 7

Check auditor.log for one line per action.

================================================================
End of README
================================================================
