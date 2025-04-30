# frozen_string_literal: true

require_relative 'lib/tw_extensions/version'

Gem::Specification.new do |spec|
  spec.name        = 'tw_extensions'
  spec.version     = TwExtensions::VERSION
  spec.authors     = ['Stephen Ierodiaconou']
  spec.email       = ['stevegeek@gmail.com']
  spec.homepage    = 'https://github.com/stevegeek/tw_extensions'
  spec.summary     = 'Unofficial tools/extensions for Tidewave Rails gem'
  spec.description = 'Unofficial additional tools and functionality for the Tidewave Rails gem'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/stevegeek/tw_extensions'
  spec.metadata['changelog_uri'] = 'https://github.com/stevegeek/tw_extensions/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'LICENSE', 'README.md']
  end

  spec.require_paths = ['lib']

  # Add dependency on tidewave_rails
  spec.add_dependency 'tidewave', '~> 0.1.0'
end
