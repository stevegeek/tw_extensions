# frozen_string_literal: true

module TwExtensions
  class ListPackageDocumentation < Tidewave::Tools::Base
    include TwExtensions::Common

    tool_name 'list_package_documentation'

    description <<~DESCRIPTION
      Lists documentation files found in a gem package.

      This works for installed gem dependencies only, not for files in the current project.
      Searches for common documentation files like README, CHANGELOG, docs, examples, etc.
    DESCRIPTION

    arguments do
      required(:gem_name).filled(:string).description('The name of the gem to search for documentation.')
      optional(:include_content).filled(:bool).description('Whether to include the content of documentation files. Default is false.')
    end

    def call(gem_name:, include_content: false)
      spec = Gem::Specification.find_by_name(gem_name)
      doc_files = find_documentation_files(spec)

      response = {
        gem_name: gem_name,
        gem_version: spec.version.to_s,
        gem_path: spec.gem_dir,
        documentation_files: include_content ? files_with_content(doc_files) : doc_files
      }

      response.to_json
    rescue Gem::MissingSpecError
      raise ArgumentError, "Gem '#{gem_name}' is not installed"
    end

    private

    def allowed_extensions
      'md,markdown,rdoc,txt,html'
    end

    def find_documentation_files(spec)
      gem_dir = spec.gem_dir

      # Define patterns for common documentation files with limited extensions
      doc_patterns = [
        'README', "README.{#{allowed_extensions}}",
        'CHANGELOG', "CHANGELOG.{#{allowed_extensions}}",

        # Documentation directories
        "doc/**/*.{#{allowed_extensions}}",
        "docs/**/*.{#{allowed_extensions}}",
        "documentation/**/*.{#{allowed_extensions}}",

        # Examples
        'example*/**/*.rb', 'examples/**/*.rb', 'sample/**/*.rb', 'samples/**/*.rb',

        # Guides
        "guides/**/*.{#{allowed_extensions}}",
        "guide/**/*.{#{allowed_extensions}}"
      ]

      # Find all matching files
      doc_files = []
      doc_patterns.each do |pattern|
        full_pattern = File.join(gem_dir, pattern)
        matches = Dir.glob(full_pattern, File::FNM_CASEFOLD)

        # Ensure all matches are within the gem directory
        matches.each do |file_path|
          doc_files << file_path if File.file?(file_path) && within_gem_dir?(file_path, gem_dir)
        end
      end

      # Remove duplicates and sort
      doc_files.uniq.sort
    end

    def files_with_content(file_paths)
      file_paths.map do |file_path|
        # Skip large files to prevent memory issues
        file_size = File.size(file_path)
        content = if file_size < 1_000_000 # 1MB limit
                    File.read(file_path)
                  else
                    "File too large to include content (#{file_size} bytes)"
                  end

        {
          path: file_path,
          content: content
        }
      rescue StandardError => e
        {
          path: file_path,
          error: "Could not read file: #{e.message}"
        }
      end
    end
  end
end
