# GitDetour

A friendly Git workflow helper that simplifies common Git tasks with intuitive commands.

## Installation

### Local Development

```bash
# Clone the repository
cd GitDetour

# Install dependencies
bundle install

# Run locally
./exe/git-detour [command]
```

### As a Gem (Future)

```bash
gem install git_detour
```

## Features

GitDetour provides simple, human-friendly commands for common Git workflows:

### Commands

#### `git-detour status`
Enhanced status with branch info and upstream tracking.

```bash
git-detour status
```

Shows:
- Current branch name
- Commits ahead/behind upstream
- Working tree status
- Clean, colored output

#### `git-detour new-feature <name>`
Create a new feature branch with consistent naming.

```bash
git-detour new-feature user-authentication
# Creates and switches to: feature/user-authentication
```

#### `git-detour save [message]`
Quick commit with auto-generated or custom message.

```bash
# Auto-generate commit message based on changes
git-detour save

# Use custom message
git-detour save "Add login form validation"
```

Auto-generated messages describe what changed:
- "Add 3 file(s)"
- "Update 2 file(s), Delete 1 file(s)"

#### `git-detour wip`
Save work-in-progress with timestamp.

```bash
git-detour wip
# Stashes changes with message like: "WIP on feature/login - 2025-11-04 14:30"
```

#### `git-detour sync`
Fetch and rebase current branch on origin.

```bash
git-detour sync
# Fetches latest changes and rebases your branch
```

#### `git-detour undo`
Interactive way to undo changes.

```bash
git-detour undo
```

Prompts you to choose:
- Undo last commit (keep changes)
- Undo last commit (discard changes)
- Discard uncommitted changes
- Cancel

Safety confirmations for destructive operations.

#### `git-detour cleanup`
Delete merged branches and prune remotes.

```bash
git-detour cleanup
```

Shows merged branches and asks for confirmation before deleting.

#### `git-detour history [limit]`
Pretty, readable commit history.

```bash
git-detour history     # Last 10 commits
git-detour history 20  # Last 20 commits
```

### Help

```bash
git-detour help
git-detour help [command]
```

## Design Philosophy

- **Human-friendly**: Commands use natural language
- **Safe by default**: Confirms before destructive operations
- **Informative**: Clear feedback with colors and symbols
- **Workflow-focused**: Optimized for common development patterns

## Requirements

- Ruby >= 2.7.0
- Git

## Dependencies

- [thor](https://github.com/rails/thor) - CLI framework
- [tty-prompt](https://github.com/piotrmurach/tty-prompt) - Interactive prompts
- [tty-spinner](https://github.com/piotrmurach/tty-spinner) - Loading indicators
- [pastel](https://github.com/piotrmurach/pastel) - Terminal colors

## Development

To test locally:

```bash
# Install dependencies
bundle install

# Run commands
./exe/git-detour status
./exe/git-detour new-feature test-branch
```

## Future Features

Ideas for future development:

- `git-detour pr` - Push branch and open pull request in browser
- `git-detour release <version>` - Tag, changelog, and push release
- `git-detour conflicts` - Show conflicts in readable format
- `git-detour stats` - Contribution statistics

## License

MIT

## Contributing

Contributions welcome! Feel free to open issues or submit pull requests.
