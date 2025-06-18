# Claude Code Enhanced Dotfiles

A curated library of templates, prompts, and commands designed to streamline development workflows when using Claude Code across any project.

## Purpose

This repository builds up a comprehensive collection of reusable Claude Code resources:
- **Templates**: Standardized project context files (CLAUDE.md) for better AI assistance
- **Prompt Library**: Battle-tested prompts for common development tasks
- **Commands**: Executable workflow automation for project setup and management
- **Dotfiles**: Essential development environment configuration

## Quick Start

```bash
# Clone the repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# Run the installer
./install.sh
```

## Directory Structure

```
dotfiles/
├── .gitconfig                     # Git configuration with useful aliases
├── install.sh                    # Setup script with symlink management
├── README.md                     # This file
└── claude/                       # Claude Code resource library
    ├── templates/
    │   └── CLAUDE.md             # Comprehensive project context template
    ├── prompts/                  # Standardized prompt collection
    │   ├── code-review.md        # Structured code review requests
    │   ├── debugging.md          # Systematic debugging assistance
    │   ├── refactoring.md        # Code improvement guidance
    │   ├── documentation.md      # Documentation generation
    │   └── rubber-duck-debug.md  # Problem-solving discussions
    └── .claude/
        └── commands/             # Development workflow commands
            ├── init-project      # Initialize projects with Claude context
            └── reflection.md     # Meta-prompt for improving instructions
```

## Available Resources

### Commands
After installation, these commands are available in any project:

**`init-project`** - Initialize new projects with Claude Code setup:
- Creates CLAUDE.md from template
- Sets up .claude/commands directory  
- Creates basic .gitignore
- Detects project type (Node.js, Python, Rust, Go)

### Templates
**CLAUDE.md** - Comprehensive project context template including:
- Project overview and tech stack documentation
- Directory structure and architecture notes
- Development commands and workflows
- Code conventions and testing strategy

### Prompt Library
Standardized prompts for consistent Claude Code interactions:

- **code-review.md** - Structured code review requests with quality focus
- **debugging.md** - Systematic debugging assistance with context gathering
- **refactoring.md** - Code improvement guidance with clear goals and constraints
- **documentation.md** - Documentation generation with audience targeting
- **rubber-duck-debug.md** - Persistent problem-solving discussion prompts

## Usage Examples

### Setting up a new project
```bash
cd my-new-project
init-project
# Edit generated CLAUDE.md with project-specific information
```

### Using prompt templates
1. Copy content from `~/.dotfiles/claude/prompts/[prompt-name].md`
2. Paste into Claude Code session
3. Fill in the specific details for your use case
4. Get consistent, structured assistance

## Installation

The installer creates symlinks and sets up the Claude Code resource library:
1. Backs up existing dotfiles
2. Creates symlinks to your home directory
3. Sets up Claude resources in `~/.dotfiles/claude`
4. Makes commands executable
5. Provides PATH setup instructions

## Expanding the Library

### Adding Commands
1. Create executable script in `claude/.claude/commands/`
2. Follow existing patterns for project type detection
3. Test across different project types

### Adding Templates  
1. Create new templates in `claude/templates/`
2. Reference from commands or document usage
3. Include clear customization points

### Adding Prompts
1. Create new .md files in `claude/prompts/`
2. Include structured sections and examples
3. Test for consistency and effectiveness

## Benefits

- **Consistent Setup**: Standardized project initialization across all work
- **Better AI Interactions**: Rich context and proven prompt patterns
- **Faster Development**: Reusable templates and commands reduce setup time
- **Knowledge Sharing**: Capture and reuse effective Claude Code workflows