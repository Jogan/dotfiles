# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Claude Code Enhanced Dotfiles repository that combines traditional dotfiles management with specialized tooling for Claude Code AI assistant interactions. It streamlines development workflows by providing consistent project setup, structured prompts, and automated commands.

## Key Commands

### Installation
```bash
./install.sh
```
Installs dotfiles by creating symlinks and setting up Claude enhancements. Backs up existing files before installation.

### Available Commands (after installation)
- `init-project` - Initialize new projects with CLAUDE.md template and proper directory structure
- `reflection.md` - Meta-prompt for analyzing and improving Claude instructions based on chat history
- Access prompt templates from `~/.dotfiles/claude/prompts/` for consistent Claude interactions

## Architecture

### Core Components
- **Traditional Dotfiles**: `.gitconfig` with comprehensive Git aliases and settings
- **Claude Templates**: `claude/templates/CLAUDE.md` - comprehensive project context template
- **Prompt Library**: `claude/prompts/` - standardized prompts for:
  - `code-review.md` - structured code review requests
  - `debugging.md` - systematic debugging assistance  
  - `refactoring.md` - code improvement guidance
  - `documentation.md` - documentation generation
  - `rubber-duck-debug.md` - persistent problem-solving discussions
- **Commands**: `claude/.claude/commands/` - executable development workflow commands

### Project Detection
The `init-project` command automatically detects project types:
- Node.js (package.json)
- Python (requirements.txt, pyproject.toml) 
- Rust (Cargo.toml)
- Go (go.mod)

## Development Workflow

### Setting up new projects
1. Run `init-project` in project directory
2. Edit generated CLAUDE.md with project-specific information
3. Use standardized prompts from `~/.dotfiles/claude/prompts/` for consistent AI interactions

### Using the reflection process
1. When Claude's performance could be improved, use the `reflection.md` prompt
2. Copy content from `claude/.claude/commands/reflection.md`
3. Paste into Claude Code session to analyze current instructions and chat history
4. Follow the structured analysis → feedback → implementation process
5. Update CLAUDE.md files based on approved improvements

### Using prompt templates
**For code reviews:**
```
Copy claude/prompts/code-review.md → Customize with:
- Specific files/functions to review
- Areas of concern (performance, security, etc.)
- Project context and constraints
```

**For debugging:**
```
Copy claude/prompts/debugging.md → Fill in:
- Problem description and symptoms
- Steps already tried
- Relevant code snippets and logs
- Environment details
```

**For refactoring:**
```
Copy claude/prompts/refactoring.md → Specify:
- Code section to improve
- Refactoring goals (readability, performance, etc.)
- Constraints and requirements
- Success criteria
```

## File Structure Notes

- Templates live in `claude/templates/` 
- Commands are executable scripts in `claude/.claude/commands/`
- Installation creates symlinks from home directory to repository files
- Git configuration includes useful aliases: `st` (status), `lg` (pretty log), `dif` (diff)

## Important Notes

- README.md documents planned commands (`setup-testing`, `quality-check`, `deploy-prep`) that are not yet implemented
- Only `init-project` and `reflection.md` currently exist in commands directory
- The `.gitconfig` requires manual configuration of user name and email