require_relative "lib/git_detour/version"

Gem::Specification.new do |spec|
  spec.name          = "git_detour"
  spec.version       = GitDetour::VERSION
  spec.authors       = ["Charlie"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "A friendly Git workflow helper"
  spec.description   = "Simplify your Git workflow with intuitive commands for common tasks"
  spec.homepage      = "https://github.com/yourusername/git_detour"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.glob("{lib,exe}/**/*") + ["README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = ["git-detour"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "pastel", "~> 0.8"
end
