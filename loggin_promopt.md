Add an append-only inbox-processing audit system to this local knowledge-base repository.

First inspect the repository’s existing structure, README, Copilot instructions, curation process, Git history, and inbox conventions. Adapt the implementation to the repository rather than assuming exact file contents.

Requirements:

1. Create `logs/inbox-processing-log.md`.

   It must record one row whenever a file leaves `docs/inbox/`, including when it is:
   - moved;
   - merged into another document;
   - archived;
   - deleted; or
   - intentionally dismissed.

   Each row must contain:
   - processing timestamp with timezone;
   - original inbox filename;
   - action;
   - destination, when applicable; and
   - a short, human-readable, sanitized summary of the result.

   Use an append-only Markdown table. Never silently remove or rewrite historical entries. If an entry is inaccurate, add a correction entry.

2. Create `logs/README.md` explaining:
   - what repository-maintenance logs are;
   - that the inbox log is append-only;
   - what events must be logged; and
   - how corrections are handled.

3. Create `scripts/Write-InboxProcessingLog.ps1`.

   Requirements for the helper:
   - Compatible with Windows PowerShell 5.1 and PowerShell 7+.
   - Parameters:
     - `SourceFile` — required;
     - `Action` — required, restricted to `Moved`, `Merged`, `Archived`, `Deleted`, or `Dismissed`;
     - `Destination` — optional;
     - `Summary` — required;
     - `Commit` — optional;
     - `ProcessedAt` — optional, defaulting to the current time;
     - `LogPath` — optional, defaulting to `logs/inbox-processing-log.md`.
   - Append exactly one Markdown-table row.
   - Store only the source file’s base name, not its absolute path.
   - Replace line breaks in input with spaces.
   - Escape Markdown table delimiters.
   - Refuse to run if the log file does not exist.
   - Do not invent a placeholder commit hash.
   - Include comment-based PowerShell help and an example.

4. Update `.github/copilot-instructions.md`.

   Add a clear “Inbox processing audit” section requiring:
   - one log entry for every file removed from `docs/inbox/`;
   - the log entry to be part of the same change as the curation;
   - sanitized summaries without confidential or identifying information;
   - use of the helper script when practical;
   - verification before committing that every removed inbox file has a matching entry; and
   - correction entries instead of deletion of log history.

5. Update the repository’s capture-and-curation process.

   Add explicit steps to:
   - append the audit entry;
   - refresh the current-state summary when needed;
   - verify every removed inbox file has a corresponding log entry;
   - validate relative Markdown links; and
   - commit the completed curation as one meaningful checkpoint.

6. Update the root README and current-state/navigation document so the log and helper are discoverable.

7. Backfill prior inbox-processing events only when they can be established from Git history or existing documents.

   For each verified prior event:
   - use the actual processing timestamp when available;
   - record the original filename;
   - link to the resulting document;
   - summarize the result without exposing sensitive information; and
   - include the commit hash only if verified.

   Do not guess missing history. If prior processing cannot be reconstructed reliably, add a note saying that logging begins with this implementation.

Safety requirements:

- Do not include personal names, customer names, employer-confidential details, private URLs, internal IDs, credentials, absolute user paths, or other sensitive information.
- Do not configure a Git remote or upload anything.
- Do not modify unrelated user work.
- Preserve existing uncommitted files that are unrelated to this change.
- Treat `.gitignore` as a backstop, not permission to store sensitive data.
- Keep the implementation generic and reusable.

Validation:

- Test the PowerShell helper against a disposable copy of the log, never the real log.
- Confirm a valid action appends the expected row.
- Confirm an invalid action is rejected.
- Confirm test data did not leak into the real log.
- Validate all relative Markdown links.
- Run `git diff --check`.
- Scan changed files for identifying or sensitive content.
- Verify any backfilled entries against Git evidence.
- Remove all disposable test files.
- Show the final Git status.

After validation, create a local commit with this message:

`Add inbox processing audit log`

Do not include unrelated untracked or modified files in the commit. Do not push or configure a remote.

At completion, report:
- files created and updated;
- any history that was backfilled;
- validation performed;
- the local commit hash;
- whether unrelated working-tree changes remain; and
- confirmation that nothing was uploaded.
