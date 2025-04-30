# frozen_string_literal: true

module TwExtensions
  class FindPackageFiles < Tidewave::Tools::Base
    include TwExtensions::Common

    tool_name 'find_package_files'

    description <<~DESCRIPTION
      Searches for files matching a pattern in a gem package.

      This can be useful to better understand how a gem works and what you need to require.

      This works for installed gem dependencies only, not for files in the current project.
      Returns a list of files matching the pattern in the gem directory.
    DESCRIPTION

    arguments do
      required(:gem_name).filled(:string).description('The name of the gem to search in.')
      required(:pattern).filled(:string).description("The glob pattern to match files against (e.g., '**/*.rb', 'lib/**/*_spec.rb').")
    end

    def call(gem_name:, pattern:)
      spec = Gem::Specification.find_by_name(gem_name)
      matched_files = find_matching_files(spec, pattern)

      {
        gem_name: gem_name,
        gem_version: spec.version.to_s,
        gem_path: spec.gem_dir,
        pattern: pattern,
        matching_files: matched_files
      }.to_json
    rescue Gem::MissingSpecError
      raise ArgumentError, "Gem '#{gem_name}' is not installed"
    end

    private

    def find_matching_files(spec, pattern)
      gem_dir = spec.gem_dir
      full_pattern = File.join(gem_dir, pattern)

      # Find files matching the pattern within the gem directory
      matched_files = Dir.glob(full_pattern)

      # Ensure all files are within the gem directory (security check)
      matched_files.select do |file_path|
        normalized_path = normalize_path(file_path)
        within_gem_dir?(normalized_path, gem_dir)
      end
    end
  end
end
