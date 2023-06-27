# frozen_string_literal: true

require_relative "lib/sidekiq_delegate/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq_delegate"
  spec.version = SidekiqDelegate::VERSION
  spec.authors = ["Taylor Leighton Roozen"]
  spec.email = ["tayleighroo@gmail.com"]

  spec.summary = "Opt in extension to Sidekiq::Worker enabling delegation of work to another class' method"
  spec.description = "Supports Sidekiq::Batch operations (if dependency is present)"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.7"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  #
  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "faker"

  spec.add_dependency 'sidekiq', '>= 5.2', '< 7.0.0'
  spec.add_dependency 'sidekiq-pro', '~> 5.0'

end
