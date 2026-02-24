# frozen_string_literal: true

require_relative "lib/iers/version"

Gem::Specification.new do |spec|
  spec.name = "iers"
  spec.version = IERS::VERSION
  spec.authors = ["Rémy Hannequin"]
  spec.email = ["remy.hannequin@gmail.com"]

  spec.summary = "Earth orientation parameters and time scale values from the International Earth Rotation and Reference Systems Service (IERS)."
  spec.description = "Access to Earth orientation parameters and time scale values from the International Earth Rotation and Reference Systems Service (IERS)."
  spec.homepage = "https://github.com/rhannequin/iers"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "irb"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "webmock"
end
