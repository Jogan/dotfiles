# Claude Code Enhanced Dotfiles

A dotfiles repository enhanced with Claude Code templates, prompts, and commands to streamline development workflows.

## Features

- **Traditional Dotfiles**: Git configuration and shell customizations
- **Claude Code Templates**: Pre-configured CLAUDE.md templates for better project context
- **Prompt Library**: Standardized prompts for code review, debugging, refactoring, and documentation
- **Custom Commands**: Executable commands for common development workflows
- **Easy Installation**: Automated setup script with symlink management

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
├── .gitconfig                  # Git configuration
├── install.sh                 # Setup script
├── README.md                  # This file
└── claude/                    # Claude Code enhancements
    ├── templates/
    │   └── CLAUDE.md          # Base project template
    ├── prompts/
    │   ├── code-review.md     # Code review assistance
    │   ├── debugging.md       # Debugging help
    │   ├── refactoring.md     # Refactoring guidance
    │   └── documentation.md   # Documentation generation
    └── .claude/
        └── commands/          # Executable commands
            ├── init-project   # Initialize project with Claude context
            ├── setup-testing  # Configure testing infrastructure
            ├── quality-check  # Run comprehensive quality checks
            └── deploy-prep    # Pre-deployment validation
```

## Claude Code Commands

After installation, these commands are available in any project:

### `init-project`
Initializes a new project with proper Claude Code setup:
- Creates CLAUDE.md from template
- Sets up .claude/commands directory
- Creates basic .gitignore
- Provides project-specific next steps

### `setup-testing`
Configures testing infrastructure based on project type:
- Detects project type (Node.js, Python, Rust, Go)
- Creates appropriate test directory structure
- Sets up example test files
- Provides framework-specific guidance

### `quality-check`
Runs comprehensive quality checks:
- Linting and formatting
- Type checking
- Test execution
- Security audits
- Build validation

### `deploy-prep`
Pre-deployment validation and preparation:
- Git status and branch checks
- Build and test validation
- Security and environment checks
- Deployment readiness summary

## Templates

### CLAUDE.md Template
A comprehensive template for project context including:
- Project overview and tech stack
- Directory structure documentation
- Development commands and workflows
- Code style and conventions
- Testing strategy
- Common issues and solutions

## Prompts Library

Standardized prompts for consistent Claude Code interactions:

- **code-review.md**: Structured code review requests
- **debugging.md**: Systematic debugging assistance
- **refactoring.md**: Code improvement and restructuring
- **documentation.md**: Documentation generation guidance

## Usage Examples

### Setting up a new project
```bash
cd my-new-project
init-project
# Edit CLAUDE.md with project-specific information
```

### Running quality checks
```bash
quality-check
# Reviews code quality, runs tests, checks security
```

### Preparing for deployment
```bash
deploy-prep
# Validates deployment readiness with comprehensive checks
```

### Using prompts with Claude Code
1. Copy content from `~/.dotfiles/claude/prompts/code-review.md`
2. Paste into Claude Code session
3. Fill in the specific details for your use case

## Installation Details

The installer:
1. Backs up existing dotfiles
2. Creates symlinks to your home directory
3. Sets up Claude enhancements in `~/.dotfiles/claude`
4. Makes commands executable
5. Provides PATH setup instructions

## Customization

### Adding new commands
1. Create executable script in `claude/.claude/commands/`
2. Follow existing command patterns
3. Update this README with usage instructions

### Modifying templates
1. Edit files in `claude/templates/`
2. Changes apply to all future `init-project` uses

### Adding prompts
1. Create new .md files in `claude/prompts/`
2. Follow existing prompt structure
3. Include clear instructions and examples

## Supported Project Types

Commands automatically detect and support:
- **Node.js** (package.json)
- **Python** (requirements.txt, pyproject.toml)
- **Rust** (Cargo.toml)
- **Go** (go.mod)

## Benefits

- **Faster Project Setup**: Quick initialization with proper Claude context
- **Consistent Workflows**: Standardized commands across all projects
- **Better Claude Interactions**: Rich context and structured prompts
- **Quality Assurance**: Automated checks and validations
- **Deployment Safety**: Pre-deployment verification

## Contributing

1. Fork the repository
2. Create feature branch
3. Add/modify commands, templates, or prompts
4. Test with the install script
5. Submit pull request

## License

MIT License - see LICENSE file for details