# AGENT.md Template for External Repositories

> ⚠️ **TEMPLATE NOTICE**: This is a template file from Greg's dotfiles repository. When using this in another repository:
> 1. Copy this file to `AGENT.md` in the target repository
> 2. Remove this notice section
> 3. Customize the project-specific sections below
> 4. Keep the "Greg's System Context" section for access to his personal tooling

---

# [PROJECT NAME] - AI Assistant Guide

## Project Overview
<!-- Describe what this project is, its purpose, tech stack, etc. -->

## Development Workflow
<!-- Project-specific workflow, testing approach, deployment process, etc. -->

## Code Style & Conventions
<!-- Language-specific style guides, naming conventions, file organization, etc. -->

## Testing Requirements
<!-- What level of testing is expected, test frameworks used, coverage requirements, etc. -->

## Architecture & Patterns
<!-- Key architectural decisions, design patterns, folder structure, etc. -->

---

## Greg's System Context

> This section provides context about Greg's personal development environment, enabling use of his custom tools and aliases while working on this project.

### Available CLI Tools & Aliases

**File Operations:**
- `ls`, `ll`, `la`, `lt`, `lx` - Enhanced directory listing with icons (eza-based)
- `cd` → `z` - Smart directory jumping with frecency (zoxide)

**Search & Navigation:**
- `ff` → `fuzzy-find` - Custom fuzzy file finder
- `frg` → `fuzzy-ripgrep` - Fuzzy search within file contents  
- `fh` → `fuzzy-history` - Fuzzy command history search
- `falias` - Fuzzy search and execute available aliases

**Development Tools:**
- `v` → `nvim` - Primary editor
- `vl` - Edit last opened file in nvim
- `vtmp` - Open temporary nvim buffer
- `voil` - Open nvim with Oil file manager
- `g` → `gmux` - Custom tmux session manager

**Modern CLI Replacements:**
- `rg` (ripgrep) - Use instead of `grep`
- `bat` - Use instead of `cat` (syntax highlighting)
- `fd` - Use instead of `find`
- `eza` - Use instead of `ls` (with icons)

### Available Binary Commands
Custom scripts available in `~/.local/bin/`:
- `fuzzy-find` - Interactive file finder
- `fuzzy-ripgrep` - Interactive content search
- `compress-video-hevc` - Video compression utility
- `download-media` - Media downloading tool
- `remux-video` - Video format conversion

### Environment Setup
- **Shell:** zsh with oh-my-zsh and powerlevel10k
- **Editor:** Neovim with extensive configuration
- **Terminal:** Alacritty with theme switching (`kt` command)
- **Multiplexer:** tmux with custom session management

### Preferred Practices
- **Iterative development:** Small, incremental changes
- **Extensive testing:** Changes should be tested since Greg dogfoods his configs
- **Modern tooling:** Prefer the enhanced CLI tools listed above
- **Error handling:** Scripts should include comprehensive error checking

### Tool Preferences for AI Assistants
- Use `bat` instead of `cat` for reading files
- Use `rg` instead of `grep` for searching
- Use `fd` instead of `find` for file discovery
- Use `eza` instead of `ls` for directory listing
- Leverage fuzzy finder tools (`ff`, `frg`, `fh`) when appropriate

---

## Project-Specific AI Guidelines

<!-- Add any project-specific instructions for AI assistants here -->

### Communication Style
<!-- Preferred communication approach: ask questions vs. just implement, level of explanation needed, etc. -->

### Scope & Boundaries  
<!-- What the AI should/shouldn't modify, areas requiring explicit permission, etc. -->

### External Dependencies
<!-- Project-specific dependencies, services, APIs that the AI should be aware of -->