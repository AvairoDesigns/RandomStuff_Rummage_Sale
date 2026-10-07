<#
.SYNOPSIS
Creates a private, local personal knowledge-base repository.

.DESCRIPTION
Writes a generic note-organization scaffold, initializes a local Git repository
on the main branch, configures repository-local author identity, and creates the
initial commit. By default, it copies this starter into the generated
repository so the structure can be recreated elsewhere. The script never
configures a remote.

.EXAMPLE
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath "C:\Notes\personal-knowledge-base" `
    -KnowledgeBaseName "My Personal Knowledge Base" `
    -GitUserName "Your Name" `
    -GitUserEmail "you@example.com"

.EXAMPLE
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath ".\personal-notes" `
    -KnowledgeBaseName "Personal Notes"

The second example uses an existing global Git author identity.

.EXAMPLE
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath ".\personal-notes" `
    -SkipSpawnCopy

Creates the repository and spawn instructions without copying the bootstrapper.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,

    [ValidateNotNullOrEmpty()]
    [string]$KnowledgeBaseName = "Personal Knowledge Base",

    [string]$GitUserName,

    [string]$GitUserEmail,

    [switch]$SkipSpawnCopy
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0
$ScaffoldVersion = "1.1.0"

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $previousLocation = Get-Location
    try {
        Set-Location -LiteralPath $WorkingDirectory
        & git @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Git command failed: git $($Arguments -join ' ')"
        }
    }
    finally {
        Set-Location -LiteralPath $previousLocation
    }
}

function Get-GitConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $value = & git config --global --get $Key 2>$null
    if ($LASTEXITCODE -eq 0 -and $null -ne $value) {
        return ($value | Select-Object -First 1).Trim()
    }

    return $null
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8WithoutBom)
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required but was not found on PATH. Install Git and rerun this script."
}

if ([string]::IsNullOrWhiteSpace($GitUserName) -xor [string]::IsNullOrWhiteSpace($GitUserEmail)) {
    throw "Provide both -GitUserName and -GitUserEmail, or omit both to use existing global Git configuration."
}

if ([string]::IsNullOrWhiteSpace($GitUserName)) {
    $GitUserName = Get-GitConfigValue -Key "user.name"
    $GitUserEmail = Get-GitConfigValue -Key "user.email"

    if ([string]::IsNullOrWhiteSpace($GitUserName) -or [string]::IsNullOrWhiteSpace($GitUserEmail)) {
        throw @"
Git author identity is not configured.

Rerun with both parameters:
  -GitUserName "Your Name" -GitUserEmail "you@example.com"

The identity will be stored only in the new repository's local Git configuration.
"@
    }
}

$resolvedRepoPath = [System.IO.Path]::GetFullPath($RepoPath)
$resolvedParent = Split-Path -Parent $resolvedRepoPath
$leafName = Split-Path -Leaf $resolvedRepoPath
if ([string]::IsNullOrWhiteSpace($leafName)) {
    throw "RepoPath must identify a repository folder, not a filesystem root."
}

if (-not (Test-Path -LiteralPath $resolvedParent)) {
    New-Item -ItemType Directory -Path $resolvedParent -Force | Out-Null
}

if (Test-Path -LiteralPath $resolvedRepoPath) {
    $existingItems = @(Get-ChildItem -LiteralPath $resolvedRepoPath -Force)
    if ($existingItems.Count -gt 0) {
        throw "Destination already exists and is not empty: $resolvedRepoPath"
    }
}
else {
    New-Item -ItemType Directory -Path $resolvedRepoPath | Out-Null
}

$safeTitle = $KnowledgeBaseName.Replace("`r", " ").Replace("`n", " ").Trim()
if ([string]::IsNullOrWhiteSpace($safeTitle)) {
    throw "KnowledgeBaseName must contain visible text."
}

$files = [ordered]@{
    "README.md" = @'
# {{KNOWLEDGE_BASE_NAME}}

A private, local, Git-versioned home for ideas, research, plans, decisions,
reference material, and repeatable processes.

## Start here

1. Open [`CURRENT-STATE.md`](CURRENT-STATE.md) for a quick memory refresh and
   the most important next actions.
2. Capture unorganized notes in [`docs/inbox/`](docs/inbox/).
3. Use a starter from [`templates/`](templates/) for substantial notes.
4. Ask Copilot to curate the inbox when several notes accumulate.
5. Commit meaningful checkpoints so earlier thinking remains recoverable.

## Structure

| Path | Purpose |
| --- | --- |
| `CURRENT-STATE.md` | Human-readable overview and ranked next actions |
| `docs/inbox/` | Fast capture before classification |
| `docs/ideas/` | Concepts, hypotheses, and opportunities |
| `docs/research/` | Source-backed findings and reading notes |
| `docs/plans/` | Roadmaps, experiments, and implementation plans |
| `docs/decisions/` | Important choices and their rationale |
| `docs/topics/` | Durable topic overviews connecting related notes |
| `docs/spawn/` | Instructions and optional copy of the portable bootstrapper |
| `logs/` | Append-only knowledge-processing audit logs |
| `processes/` | Repeatable knowledge-management workflows |
| `scripts/` | Local repository-maintenance helpers |
| `templates/` | Starter documents for consistent notes |
| `assets/images/` | Images and diagrams referenced by notes |
| `assets/attachments/` | Supporting files that are safe to retain |
| `archive/` | Superseded material preserved for context |
| `.github/copilot-instructions.md` | Repository guidance for Copilot |

## Working conventions

- Prefer Markdown for text.
- Use descriptive lowercase kebab-case file names.
- Add a `YYYY-MM-DD-` prefix when chronology matters.
- Link related notes with relative Markdown links.
- Distinguish facts, interpretations, assumptions, and open questions.
- Cite sources close to the claims they support.
- Never store passwords, tokens, private keys, personal data, confidential
  business information, private links, or restricted material.

## Local Git workflow

```powershell
git status
git add .
git commit -m "Describe the knowledge update"
```

No remote is configured by the setup script. Before ever publishing this
repository, review both current files and Git history for sensitive content.
'@

    "CURRENT-STATE.md" = @'
# Current State

**Last refreshed:** {{CURRENT_DATE}}
**Scope:** Repository contents only
**Current emphasis:** Establishing the knowledge base

## In brief

This is a new personal knowledge base. It currently contains the organizational
structure, templates, safety guidance, and maintenance processes needed to
begin capturing useful material.

This page is a memory aid and navigation layer. Detailed notes, plans, and
decision records remain authoritative.

## Current initiatives

No initiatives have been documented yet.

## Recommended next actions

1. **Capture the first useful note.** Put an unstructured thought, question, or
   link in [`docs/inbox/`](docs/inbox/).
2. **Create the first topic page.** When several notes concern one subject,
   summarize and connect them under [`docs/topics/`](docs/topics/).
3. **Record consequential choices.** Use
   [`templates/decision.md`](templates/decision.md) so rationale is not lost.

## Decisions needed

- Which subjects should this knowledge base emphasize?
- How often should the inbox be curated?
- What material should remain outside the repository for privacy or security?

## Confirmed decisions

- The repository is local-only unless its owner explicitly decides otherwise.
- Sensitive or confidential content does not belong here.
- `CURRENT-STATE.md` is the human-readable front door, not a separate source of
  truth.

## Watch items

- Update this page when meaningful plans, decisions, topics, or priorities
  change.
- Treat `.gitignore` as a backstop, not as permission to save secrets.
- Review repository history as well as current files before any future sharing.

## Repository map

- [Repository guide](README.md)
- [Inbox](docs/inbox/README.md)
- [Ideas](docs/ideas/README.md)
- [Research](docs/research/README.md)
- [Plans](docs/plans/README.md)
- [Decisions](docs/decisions/README.md)
- [Topics](docs/topics/README.md)
- [Capture and curation process](processes/capture-and-curate.md)
- [Inbox processing log](logs/inbox-processing-log.md)
- [Research and citation process](processes/research-and-citations.md)
- [Portable scaffold](docs/spawn/README.md)
'@

    ".gitignore" = @'
# Operating system and editor files
.DS_Store
Thumbs.db
Desktop.ini
*.swp
*.swo
*~
.vscode/
.idea/

# Temporary and generated files
*.tmp
*.temp
*.bak
*.log
~$*
scratch/
tmp/
temp/

# Credentials and sensitive local configuration
.env
.env.*
!.env.example
*.key
*.pem
*.pfx
*.p12
secrets/
private/
local/

# Common generated document artifacts
*.autosave
'@

    ".github/copilot-instructions.md" = @'
# Copilot repository instructions

## Purpose

This repository is a private personal knowledge base. Help actively curate
ideas, research, plans, decisions, topic summaries, and repeatable processes.

## Working style

- Improve organization, titles, structure, clarity, grammar, and cross-links
  when useful.
- Consolidate obvious duplication while preserving unique information.
- Reorganize or rename content when it improves findability; repair affected
  relative links and summarize significant moves.
- Preserve the author's meaning and voice. Do not turn uncertainty into fact.
- Prefer concise Markdown with informative headings, lists, and tables.
- Use existing templates and folder conventions.
- Add or update nearby index links when creating durable content.
- Do not delete substantive content. Archive superseded material with a short
  explanation instead.
- Before changing files, inspect enough related material to preserve context.

## Current-state summary

- Treat `CURRENT-STATE.md` as the human-readable front door, not as a separate
  source of truth.
- Refresh it whenever inbox curation or a meaningful change to a plan,
  decision, recommendation, topic, or initiative makes it stale.
- Summarize the full knowledge base, emphasizing the current primary subject.
- Keep a ranked list of three to five recommended next actions. Give a brief
  rationale and link each action to its authoritative source.
- Clearly distinguish confirmed decisions, proposals, open decisions, dated
  observations, and watch items.
- Base the summary only on repository contents unless the user explicitly asks
  for external research.
- Keep it readable in approximately three to five minutes.
- Update its `Last refreshed` date whenever its substance changes.

## Inbox processing audit

- Every file removed from `docs/inbox/` must receive one append-only entry in
  `logs/inbox-processing-log.md` in the same change.
- This includes moves, merges, archives, deletions, and intentional dismissals.
- Record the processing timestamp, original inbox file name, action,
  destination when applicable, and a short sanitized result.
- Use `scripts/Write-InboxProcessingLog.ps1` when practical.
- Never remove a log entry. Add a correction entry if an earlier record is
  inaccurate.
- Before committing inbox curation, verify that every removed inbox file is
  represented in the log.

## Portable scaffold

- Treat `docs/spawn/New-PersonalKnowledgeBase.ps1` as the portable bootstrapper
  when it is present.
- Review the bootstrapper whenever repository-wide structure, templates,
  curation processes, audit behavior, safety rules, or Copilot instructions
  change.
- Keep generated scaffold content generic. Never copy actual notes, decisions,
  inbox-processing history, names, private links, internal IDs, absolute user
  paths, or operational details into it.
- Keep `docs/spawn/README.md` accurate for the bootstrapper version recorded
  there.
- Preserve local-only defaults: no remote configuration, upload, publication,
  or external sharing.
- Test bootstrapper changes in explicitly named disposable folders and remove
  those folders after validation.

## Knowledge integrity

- Clearly label facts, interpretations, assumptions, hypotheses, and open
  questions.
- Never invent sources, quotations, dates, authors, URLs, research results, or
  confidence levels.
- For time-sensitive claims, include an access date or state that verification
  is needed.
- Prefer primary sources and record enough detail to find each source again.
- When sources disagree, preserve and explain the disagreement.

## Safety and privacy

- Do not add credentials, secrets, personal data, confidential information,
  private links, proprietary material, or restricted content.
- If supplied content appears sensitive, stop and flag it rather than saving it.
- Treat `.gitignore` as a backstop, not as permission to store sensitive files.
- Do not configure a remote, publish, upload, send, or share repository content
  unless the user explicitly requests it.
- When sanitizing, remove identifying details without erasing the useful idea.

## File conventions

- Use lowercase kebab-case file names.
- Add a `YYYY-MM-DD-` prefix when chronology matters.
- Store reusable images in `assets/images/` and supporting files in
  `assets/attachments/`; link with relative paths.
- Avoid binary duplicates. Prefer authoritative links when a local copy is
  unnecessary.
- Use ASCII by default unless names, quotations, or subject matter require
  Unicode.

## Validation

- Check relative Markdown links after reorganizing content.
- Review pending changes for accidental sensitive information.
- Keep commits focused and describe the knowledge change they contain.
'@

    "docs/README.md" = @'
# Documents

This is the main knowledge area:

- [`inbox/`](inbox/) for quick capture
- [`ideas/`](ideas/) for concepts and hypotheses
- [`research/`](research/) for source-backed investigation
- [`plans/`](plans/) for intended work and experiments
- [`decisions/`](decisions/) for consequential choices and rationale
- [`topics/`](topics/) for durable subject overviews and navigation
- [`spawn/`](spawn/) for the portable repository bootstrapper and instructions

Start with the inbox when classification would slow down capture. During a
review, move each worthwhile note to its natural home and add useful links.

The spawn folder is maintenance infrastructure rather than knowledge content.
Keep it generic and free of actual notes, private references, and processing
history.
'@

    "docs/inbox/README.md" = @'
# Inbox

Capture first; organize later.

Use this folder for rough notes, pasted links, questions, and incomplete
thoughts. Give each note a recognizable title even if the body is messy.

During curation:

1. Remove material that has no continuing value.
2. Split unrelated ideas when that improves reuse.
3. Move useful content into `ideas`, `research`, `plans`, `decisions`, or
   `topics`.
4. Add links to related notes.
5. Add one entry to `logs/inbox-processing-log.md` for every file removed from
   this folder.
6. Refresh `CURRENT-STATE.md` when priorities or understanding change.
'@

    "docs/ideas/README.md" = @'
# Ideas

Early concepts, hypotheses, opportunities, and possible experiments belong
here. Use [`templates/idea.md`](../../templates/idea.md) when helpful.

An idea does not need to be proven. State assumptions and open questions so
later research can test them.

## Ideas under evaluation

No ideas have been added yet.
'@

    "docs/research/README.md" = @'
# Research

Store source-backed notes, comparisons, reading notes, and research syntheses
here. Use [`templates/research-note.md`](../../templates/research-note.md) and
follow [`processes/research-and-citations.md`](../../processes/research-and-citations.md).

Separate what a source says from your interpretation of it.
'@

    "docs/plans/README.md" = @'
# Plans

Store roadmaps, experiments, project outlines, and next-step documents here.
Use [`templates/plan.md`](../../templates/plan.md) for work that benefits from
goals, scope, milestones, and success criteria.

## Active plans

No plans have been added yet.
'@

    "docs/decisions/README.md" = @'
# Decisions

Record choices that may need to be understood or revisited later. Use
[`templates/decision.md`](../../templates/decision.md).

Keep superseded decisions. Mark their status and link to the replacement so the
history remains understandable.

## Decision log

No decisions have been recorded yet.
'@

    "docs/topics/README.md" = @'
# Topics

Topic pages are durable overviews. They should summarize the current
understanding of a subject and link to the strongest related ideas, research,
plans, decisions, sources, and assets.

Create a topic page when several notes begin to form a reusable body of
knowledge.

## Topics

No topic pages have been added yet.
'@

    "processes/README.md" = @'
# Processes

Repeatable workflows for keeping this knowledge base useful:

- [`capture-and-curate.md`](capture-and-curate.md)
- [`research-and-citations.md`](research-and-citations.md)

Update these processes when actual working habits evolve.
'@

    "processes/capture-and-curate.md" = @'
# Capture and curate

## Capture

1. Create a short Markdown note in `docs/inbox/`.
2. Use a descriptive file name; add a date prefix when chronology matters.
3. Record the thought, why it matters, and any obvious next question.
4. Save safe source links immediately rather than relying on memory.

## Curate

Review the inbox periodically:

1. **Clarify:** improve the title and make the core point visible near the top.
2. **Classify:** move the note to the best document folder.
3. **Connect:** link related notes and relevant topic pages.
4. **Validate:** label assumptions and add citations for factual claims.
5. **Advance:** identify a next step or mark the note as intentionally parked.
6. **Archive:** move superseded material to `archive/` instead of erasing useful
   history.
7. **Log processing:** for every file removed from `docs/inbox/`, append one
   entry to the
   [`inbox processing log`](../logs/inbox-processing-log.md). Record the
   timestamp, original file name, action, destination, and a short sanitized
   result. Use
   [`Write-InboxProcessingLog.ps1`](../scripts/Write-InboxProcessingLog.ps1)
   when practical.
8. **Refresh current state:** update
   [`CURRENT-STATE.md`](../CURRENT-STATE.md) when the repository summary,
   decisions, actions, watch items, or navigation change.
9. **Verify:** confirm every removed inbox file has a matching log entry, check
   links, and scan changed files for sensitive information.
10. **Commit:** create a meaningful local Git checkpoint.

## Repository health

Occasionally ask Copilot to:

- curate the inbox;
- review the inbox processing log;
- refresh the current-state summary;
- find broken relative links;
- identify duplicate or disconnected notes;
- suggest topic pages from clusters of notes;
- find unsupported factual claims; and
- summarize changes since an earlier commit.
'@

    "processes/research-and-citations.md" = @'
# Research and citations

## Source preference

Prefer sources in this order when practical:

1. Original research, official documentation, standards, or first-party data
2. Peer-reviewed analysis or established technical publications
3. Credible expert commentary
4. Secondary summaries used for discovery

## Recording a source

Capture:

- author or organization;
- title;
- publication date, if known;
- public URL or safe local attachment path;
- access date for changeable web content; and
- the claim or question for which the source is relevant.

Example:

```text
Organization, "Title of source," 2026-01-15.
https://example.com/source (accessed 2026-10-02).
Supports: Brief description of the relevant claim.
```

## Attachments

Use `assets/attachments/` only when a source must remain available offline or
its exact version matters. Use a descriptive file name and cite the original
source in the related note. Do not save restricted, confidential, personal, or
copyright-infringing copies.

## Synthesis rules

- Put citations close to supported claims.
- Use direct quotations sparingly and preserve exact wording.
- Label inference and opinion.
- Note conflicting evidence rather than forcing consensus.
- Include a verification note for claims likely to change.
- Never create a citation for a source that was not inspected.
'@

    "templates/idea.md" = @'
# Idea: Short descriptive title

**Status:** Draft

## Summary

Describe the idea in one paragraph.

## Why it may matter

- 

## Hypothesis

What do you expect to be true?

## Assumptions

- 

## Open questions

- 

## Possible next step

- 

## Related notes and sources

- 
'@

    "templates/research-note.md" = @'
# Research: Question or topic

**Status:** In progress  
**Last reviewed:** YYYY-MM-DD

## Research question

What are you trying to learn or verify?

## Summary

State the current answer and important uncertainty.

## Findings

### Finding

Evidence, interpretation, and confidence.

## Conflicting evidence or limitations

- 

## Open questions

- 

## Sources

1. Author or organization, "Title," publication date. URL (accessed
   YYYY-MM-DD). Relevance: ...

## Related notes

- 
'@

    "templates/plan.md" = @'
# Plan: Short descriptive title

**Status:** Draft  
**Owner:**  
**Target date:**  

## Goal

What outcome should this plan produce?

## Context

Why is this worth doing now?

## Scope

### Included

- 

### Not included

- 

## Milestones

- [ ] Milestone

## Risks and assumptions

- 

## Success criteria

- 

## Related notes

- 
'@

    "templates/decision.md" = @'
# Decision: Short descriptive title

**Date:** YYYY-MM-DD  
**Status:** Proposed

## Context

What prompted this decision?

## Decision

What was or will be chosen?

## Rationale

Why is this the best choice given current information?

## Alternatives considered

### Alternative

- Benefits:
- Drawbacks:

## Consequences

- Positive:
- Negative or risky:
- Follow-up:

## Related notes and sources

- 
'@

    "logs/README.md" = @'
# Logs

Repository-maintenance audit logs live here.

- [`inbox-processing-log.md`](inbox-processing-log.md) records every note
  removed from `docs/inbox/` through curation, merging, archiving, deletion, or
  dismissal.

Logs are append-only. Correct an inaccurate entry with a new correction entry
rather than silently rewriting history.
'@

    "logs/inbox-processing-log.md" = @'
# Inbox Processing Log

This append-only log records when a file leaves `docs/inbox/`, what happened to
it, and the useful result. It tracks knowledge-processing activity, not the
full content of the source note.

## Rules

- Add one row for every file removed from the inbox.
- Record moves, merges, archives, deletions, and intentional dismissals.
- Use the original inbox file name.
- Link or name the destination when one exists.
- Keep the summary brief and free of sensitive information.
- Never delete a row. Add a correction row if needed.

## Entries

| Processed at | Inbox file | Action | Destination | Result |
| --- | --- | --- | --- | --- |
'@

    "scripts/Write-InboxProcessingLog.ps1" = @'
<#
.SYNOPSIS
Appends one sanitized entry to the inbox processing log.

.EXAMPLE
.\scripts\Write-InboxProcessingLog.ps1 `
    -SourceFile "docs\inbox\2026-01-15-example.md" `
    -Action Moved `
    -Destination "docs\ideas\2026-01-15-example.md" `
    -Summary "Promoted the note to an idea and clarified its open questions."
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Moved", "Merged", "Archived", "Deleted", "Dismissed")]
    [string]$Action,

    [string]$Destination,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Summary,

    [string]$Commit,

    [datetime]$ProcessedAt = (Get-Date),

    [string]$LogPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "logs\inbox-processing-log.md")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

function ConvertTo-TableText {
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return (($Value -replace "(`r`n|`n|`r)", " ") -replace "\|", "\|").Trim()
}

$sourceName = Split-Path -Leaf $SourceFile
if ([string]::IsNullOrWhiteSpace($sourceName)) {
    throw "SourceFile must contain an inbox file name."
}

if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
    throw "Inbox processing log was not found: $LogPath"
}

$destinationText = if ([string]::IsNullOrWhiteSpace($Destination)) {
    "-"
}
else {
    "``$(ConvertTo-TableText -Value $Destination)``"
}

$result = ConvertTo-TableText -Value $Summary
$commitText = ConvertTo-TableText -Value $Commit
if (-not [string]::IsNullOrWhiteSpace($commitText)) {
    $result = "$result Commit ``$commitText``."
}

$timestamp = $ProcessedAt.ToString("yyyy-MM-ddTHH:mm:ssK")
$entry = "| $timestamp | ``$(ConvertTo-TableText -Value $sourceName)`` | $Action | $destinationText | $result |"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$existing = [System.IO.File]::ReadAllText($LogPath)
if (-not $existing.EndsWith("`n")) {
    $existing += "`n"
}
[System.IO.File]::WriteAllText($LogPath, $existing + $entry + "`n", $utf8WithoutBom)

Write-Output "Logged inbox processing for $sourceName"
'@

    "docs/spawn/README.md" = @'
# Create another personal knowledge base

**Scaffold version:** {{SCAFFOLD_VERSION}}

This folder contains the instructions for recreating this generic personal
knowledge-base structure in another location.

## Contents

{{SPAWN_CONTENTS}}

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Git available on `PATH`
- An empty or nonexistent destination folder
- A configured Git author identity, or a name and email supplied as parameters

## Create another repository

When `New-PersonalKnowledgeBase.ps1` is present, copy it to a convenient local
folder or run it directly from this folder:

```powershell
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath "C:\Notes\another-knowledge-base" `
    -KnowledgeBaseName "Another Personal Knowledge Base" `
    -GitUserName "Your Name" `
    -GitUserEmail "you@example.com"
```

If Git author identity is already configured globally, omit `GitUserName` and
`GitUserEmail`.

Use `-SkipSpawnCopy` when the generated repository should contain these
instructions but not another copy of the bootstrapper.

## What the bootstrapper does

- Creates the note-organization structure
- Adds templates and maintenance processes
- Adds Copilot repository instructions
- Adds the current-state summary and inbox-processing audit
- Initializes local Git on `main`
- Creates the initial commit
- Copies itself here by default
- Configures no remote and uploads nothing

## After creation

1. Open the generated folder in VS Code.
2. Read `CURRENT-STATE.md`.
3. Ask Copilot:

   > Explain how this knowledge base is organized and help me capture my first
   > note.

## Safety

The bootstrapper refuses to overwrite a non-empty destination. It does not
configure a remote, publish files, or upload content. Do not add passwords,
tokens, confidential information, private links, restricted material, or
unnecessary personal data.
'@

    "assets/README.md" = @'
# Assets

- Put reusable images and diagrams in [`images/`](images/).
- Put safe supporting files in [`attachments/`](attachments/).

Use descriptive lowercase file names and link assets from the note that
provides their context. Avoid duplicates and do not store confidential,
restricted, personal, or unnecessary files.
'@

    "assets/images/.gitkeep" = ""
    "assets/attachments/.gitkeep" = ""

    "archive/README.md" = @'
# Archive

Store superseded or inactive material that remains useful for historical
context. Prefer moving content here over deleting it.

At the top of an archived document, state why it was archived and link to its
replacement when one exists.
'@
}

$spawnContents = if ($SkipSpawnCopy) {
    "The bootstrapper copy was intentionally omitted with ``-SkipSpawnCopy``. Copy a trusted bootstrapper into this folder before following the creation example."
}
else {
    "- [``New-PersonalKnowledgeBase.ps1``](New-PersonalKnowledgeBase.ps1) recreates this scaffold in another empty folder."
}

$currentDate = Get-Date -Format "yyyy-MM-dd"
foreach ($relativePath in $files.Keys) {
    $content = $files[$relativePath]
    $content = $content.Replace("{{KNOWLEDGE_BASE_NAME}}", $safeTitle)
    $content = $content.Replace("{{CURRENT_DATE}}", $currentDate)
    $content = $content.Replace("{{SCAFFOLD_VERSION}}", $ScaffoldVersion)
    $content = $content.Replace("{{SPAWN_CONTENTS}}", $spawnContents)
    $destination = Join-Path $resolvedRepoPath $relativePath
    Write-Utf8File -Path $destination -Content ($content.TrimStart("`r", "`n") + $(if ($content.Length -gt 0) { "`n" } else { "" }))
}

if (-not $SkipSpawnCopy) {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or -not (Test-Path -LiteralPath $PSCommandPath -PathType Leaf)) {
        throw "The running bootstrapper path could not be resolved for the spawn copy."
    }

    $spawnScriptPath = Join-Path $resolvedRepoPath "docs\spawn\New-PersonalKnowledgeBase.ps1"
    Copy-Item -LiteralPath $PSCommandPath -Destination $spawnScriptPath

    $sourceHash = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    $spawnHash = (Get-FileHash -LiteralPath $spawnScriptPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $spawnHash) {
        throw "The copied bootstrapper failed hash verification."
    }
}

Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @("init")
Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @("branch", "-M", "main")
Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @("config", "--local", "user.name", $GitUserName)
Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @("config", "--local", "user.email", $GitUserEmail)
Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @("add", ".")
Invoke-Git -WorkingDirectory $resolvedRepoPath -Arguments @(
    "commit",
    "-m",
    "Initialize personal knowledge base"
)

$remotes = & git -C $resolvedRepoPath remote
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify Git remotes."
}
if (@($remotes).Count -ne 0) {
    throw "Unexpected Git remote detected. Review the repository before use."
}

$status = & git -C $resolvedRepoPath status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify repository status."
}
if (@($status).Count -ne 0) {
    throw "Repository was created, but the working tree is not clean."
}

Write-Host ""
Write-Host "Personal knowledge base created successfully." -ForegroundColor Green
Write-Host "Path: $resolvedRepoPath"
Write-Host "Scaffold version: $ScaffoldVersion"
Write-Host "Branch: main"
Write-Host "Remote: none"
Write-Host "Spawn copy: $(if ($SkipSpawnCopy) { 'omitted' } else { 'included and hash-verified' })"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open the folder in VS Code."
Write-Host "  2. Read CURRENT-STATE.md."
Write-Host "  3. Ask Copilot: 'Explain how this knowledge base is organized and help me capture my first note.'"
