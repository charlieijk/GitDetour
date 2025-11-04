require "thor"
require "tty-prompt"
require "tty-spinner"
require "pastel"

module GitDetour
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "status", "Enhanced status with branch info and upstream tracking"
    def status
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new
      branch = GitWrapper.current_branch

      puts "\n#{pastel.bold.cyan('Branch:')} #{pastel.yellow(branch)}"

      if GitWrapper.has_upstream?
        ahead = GitWrapper.commits_ahead
        behind = GitWrapper.commits_behind

        if ahead > 0 || behind > 0
          status_parts = []
          status_parts << pastel.green("↑#{ahead}") if ahead > 0
          status_parts << pastel.red("↓#{behind}") if behind > 0
          puts "#{pastel.bold.cyan('Upstream:')} #{status_parts.join(' ')}"
        else
          puts "#{pastel.bold.cyan('Upstream:')} #{pastel.green('✓ up to date')}"
        end
      else
        puts "#{pastel.bold.cyan('Upstream:')} #{pastel.dim('no tracking branch')}"
      end

      if GitWrapper.has_changes?
        puts "\n#{pastel.bold.cyan('Changes:')}"
        system("git status --short")
      else
        puts "\n#{pastel.green('✓ Working tree clean')}"
      end

      puts ""
    end

    desc "new-feature NAME", "Create a new feature branch"
    def new_feature(name)
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new
      branch_name = "feature/#{name}"

      if GitWrapper.branch_exists?(branch_name)
        puts pastel.red("✗ Branch '#{branch_name}' already exists")
        exit 1
      end

      spinner = TTY::Spinner.new("[:spinner] Creating branch #{branch_name}...", format: :dots)
      spinner.auto_spin

      output, success = GitWrapper.run("checkout -b #{branch_name}")

      if success
        spinner.success(pastel.green("✓"))
        puts pastel.green("Created and switched to branch '#{branch_name}'")
      else
        spinner.error(pastel.red("✗"))
        puts pastel.red("Failed to create branch: #{output}")
        exit 1
      end
    end

    desc "save [MESSAGE]", "Quick commit with auto-generated or custom message"
    def save(message = nil)
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new

      unless GitWrapper.has_changes?
        puts pastel.yellow("Nothing to save - working tree is clean")
        return
      end

      # Stage all changes
      GitWrapper.run("add -A", capture: false)

      # Generate or use provided message
      commit_message = message || generate_commit_message

      output, success = GitWrapper.run("commit -m \"#{commit_message}\"")

      if success
        puts pastel.green("✓ Saved changes: #{commit_message}")
      else
        puts pastel.red("✗ Failed to commit: #{output}")
        exit 1
      end
    end

    desc "sync", "Fetch and rebase current branch on origin"
    def sync
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new
      branch = GitWrapper.current_branch

      unless GitWrapper.has_upstream?
        puts pastel.yellow("⚠ No upstream branch configured")
        return
      end

      # Fetch updates
      spinner = TTY::Spinner.new("[:spinner] Fetching updates...", format: :dots)
      spinner.auto_spin
      GitWrapper.run("fetch", capture: false)
      spinner.success(pastel.green("✓"))

      # Check if behind
      behind = GitWrapper.commits_behind

      if behind == 0
        puts pastel.green("✓ Already up to date")
        return
      end

      # Rebase
      spinner = TTY::Spinner.new("[:spinner] Rebasing #{branch}...", format: :dots)
      spinner.auto_spin

      output, success = GitWrapper.run("rebase")

      if success
        spinner.success(pastel.green("✓"))
        puts pastel.green("✓ Successfully synced #{branch}")
      else
        spinner.error(pastel.red("✗"))
        puts pastel.red("✗ Rebase failed - you may have conflicts to resolve")
        exit 1
      end
    end

    desc "undo", "Interactive undo for last commit or changes"
    def undo
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new
      prompt = TTY::Prompt.new

      choices = {
        "Undo last commit (keep changes)" => :soft,
        "Undo last commit (discard changes)" => :hard,
        "Discard uncommitted changes" => :discard,
        "Cancel" => :cancel
      }

      choice = prompt.select("What would you like to undo?", choices)

      case choice
      when :soft
        GitWrapper.run("reset --soft HEAD~1", capture: false)
        puts pastel.green("✓ Last commit undone, changes kept")
      when :hard
        if prompt.yes?(pastel.red("This will permanently delete the last commit. Continue?"))
          GitWrapper.run("reset --hard HEAD~1", capture: false)
          puts pastel.green("✓ Last commit removed")
        end
      when :discard
        if prompt.yes?(pastel.red("This will permanently discard all uncommitted changes. Continue?"))
          GitWrapper.run("reset --hard HEAD", capture: false)
          GitWrapper.run("clean -fd", capture: false)
          puts pastel.green("✓ Uncommitted changes discarded")
        end
      when :cancel
        puts "Cancelled"
      end
    end

    desc "cleanup", "Delete merged branches and prune remotes"
    def cleanup
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new
      prompt = TTY::Prompt.new

      # Get merged branches
      output, = GitWrapper.run("branch --merged")
      branches = output.split("\n")
                       .map(&:strip)
                       .reject { |b| b.start_with?("*") || b == "main" || b == "master" }

      if branches.empty?
        puts pastel.green("✓ No merged branches to clean up")
      else
        puts pastel.bold("Merged branches:")
        branches.each { |b| puts "  - #{b}" }

        if prompt.yes?("\nDelete these branches?")
          branches.each do |branch|
            GitWrapper.run("branch -d #{branch}", capture: false)
          end
          puts pastel.green("✓ Deleted #{branches.size} branch(es)")
        end
      end

      # Prune remotes
      if GitWrapper.remote_exists?
        spinner = TTY::Spinner.new("[:spinner] Pruning remote branches...", format: :dots)
        spinner.auto_spin
        GitWrapper.run("remote prune origin", capture: false)
        spinner.success(pastel.green("✓"))
      end
    end

    desc "wip", "Save work-in-progress (stash with message)"
    def wip
      GitWrapper.ensure_git_repo!

      pastel = Pastel.new

      unless GitWrapper.has_changes?
        puts pastel.yellow("Nothing to save - working tree is clean")
        return
      end

      branch = GitWrapper.current_branch
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
      message = "WIP on #{branch} - #{timestamp}"

      output, success = GitWrapper.run("stash push -m \"#{message}\"")

      if success
        puts pastel.green("✓ Work saved: #{message}")
        puts pastel.dim("  Restore with: git stash pop")
      else
        puts pastel.red("✗ Failed to save work: #{output}")
        exit 1
      end
    end

    desc "history [LIMIT]", "Show pretty commit history"
    def history(limit = "10")
      GitWrapper.ensure_git_repo!

      format = "%C(yellow)%h%C(reset) - %C(cyan)%an%C(reset) %C(dim)(%ar)%C(reset)%n  %s%n"
      system("git log -#{limit} --pretty=format:'#{format}'")
      puts ""
    end

    private

    def generate_commit_message
      # Simple commit message based on file changes
      output, = GitWrapper.run("status --porcelain")
      lines = output.split("\n")

      added = lines.count { |l| l.start_with?("A ") || l.start_with?("??") }
      modified = lines.count { |l| l.start_with?("M ") }
      deleted = lines.count { |l| l.start_with?("D ") }

      parts = []
      parts << "Add #{added} file(s)" if added > 0
      parts << "Update #{modified} file(s)" if modified > 0
      parts << "Delete #{deleted} file(s)" if deleted > 0

      parts.any? ? parts.join(", ") : "Quick save"
    end
  end
end
