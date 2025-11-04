module GitDetour
  class GitWrapper
    class GitError < StandardError; end

    def self.in_git_repo?
      system("git rev-parse --git-dir > /dev/null 2>&1")
    end

    def self.ensure_git_repo!
      unless in_git_repo?
        raise GitError, "Not a git repository. Run 'git init' first."
      end
    end

    def self.run(command, capture: true)
      if capture
        output = `git #{command} 2>&1`
        success = $?.success?
        return [output, success]
      else
        system("git #{command}")
      end
    end

    def self.current_branch
      run("rev-parse --abbrev-ref HEAD").first.strip
    end

    def self.has_changes?
      output, = run("status --porcelain")
      !output.strip.empty?
    end

    def self.remote_exists?(remote = "origin")
      run("remote get-url #{remote}").last
    end

    def self.branch_exists?(branch)
      run("rev-parse --verify #{branch}").last
    end

    def self.commits_ahead
      output, = run("rev-list --count @{u}..HEAD 2>/dev/null")
      output.strip.to_i
    rescue
      0
    end

    def self.commits_behind
      output, = run("rev-list --count HEAD..@{u} 2>/dev/null")
      output.strip.to_i
    rescue
      0
    end

    def self.has_upstream?
      run("rev-parse --abbrev-ref @{u}").last
    end
  end
end
