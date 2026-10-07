# Create another personal knowledge base

**Scaffold version:** 1.1.0

This folder contains a sanitized, self-contained PowerShell bootstrapper for
creating a new local personal knowledge-base repository.

## Contents

- [`New-PersonalKnowledgeBase.ps1`](New-PersonalKnowledgeBase.ps1) creates the
  repository structure, supporting files, local Git repository, and initial
  commit.

The bootstrapper contains generic structure and guidance only. It does not copy
the notes, decisions, history, or identifying details from this repository.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Git available on `PATH`
- An empty or nonexistent destination folder
- A configured Git author identity, or a name and email supplied as parameters

## Create a repository

Copy `New-PersonalKnowledgeBase.ps1` to a convenient local folder. It does not
need to be inside the destination repository.

Run:

```powershell
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath "C:\Notes\personal-knowledge-base" `
    -KnowledgeBaseName "My Personal Knowledge Base" `
    -GitUserName "Your Name" `
    -GitUserEmail "you@example.com"
```

If Git author identity is already configured globally:

```powershell
.\New-PersonalKnowledgeBase.ps1 `
    -RepoPath "C:\Notes\personal-knowledge-base" `
    -KnowledgeBaseName "My Personal Knowledge Base"
```

Use a destination that does not exist or is completely empty. The script
refuses to overwrite a non-empty folder.

## What the current bootstrapper does

- Creates the note-organization structure
- Adds templates and maintenance processes
- Adds Copilot repository instructions
- Adds a human-readable current-state summary
- Adds an append-only inbox-processing audit and logging helper
- Initializes local Git on the `main` branch
- Creates the initial commit
- Copies this starter kit into the generated repository by default
- Configures no remote and uploads nothing

Use `-SkipSpawnCopy` to create `docs/spawn/README.md` without copying the
PowerShell bootstrapper into the generated repository.

## After creation

1. Open the generated folder in VS Code.
2. Open `CURRENT-STATE.md`.
3. Start GitHub Copilot Chat.
4. Ask:

   > Explain how this knowledge base is organized and help me capture my first
   > note.

## Safety

The script does not configure a remote, publish files, or upload content.
Review the generated repository before adding personal or sensitive
information.

The generated repository is a starting structure, not a secure storage system.
Do not add passwords, tokens, private keys, confidential information, private
links, restricted material, or unnecessary personal data.

Before sharing a generated repository, inspect both its current files and its
Git history.

## Maintenance

This copy is the canonical bootstrapper for this repository. When repository
structure, templates, curation processes, audit behavior, safety rules, or
Copilot instructions change, review whether the bootstrapper needs the same
generic update.

By default, the bootstrapper copies its running script into the generated
repository's `docs/spawn/` folder and verifies that the source and destination
hashes match. It does not execute the copied script.
