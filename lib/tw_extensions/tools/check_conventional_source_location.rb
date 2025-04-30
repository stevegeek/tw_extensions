# frozen_string_literal: true

module TwExtensions
  class CheckConventionalSourceLocation < Tidewave::Tools::Base
    include TwExtensions::Common

    tool_name 'check_conventional_source_location'

    description <<~DESCRIPTION
      Checks for a module's source file location using Ruby conventions when the module is not loaded.

      When get_source_location fails to find a module because it's not required/loaded yet,
      this tool attempts to locate the module by checking conventional file paths:
      1. In the application directories
      2. In installed gems

      For example, searching for "MyModule::MyThing" will check:
      - "my_module/my_thing.rb" in the application
      - Gem "my_module" and file "my_module/my_thing.rb" inside it
    DESCRIPTION

    arguments do
      required(:module_name).filled(:string).description('The name of the module to find (e.g., \'MyModule::MyThing\')')
    end

    def call(module_name:)
      potential_paths = generate_potential_paths(module_name)
      found_paths = check_paths(potential_paths)

      if found_paths.empty?
        { found: false, message: "No conventional source location found for #{module_name}" }.to_json
      else
        {
          found: true,
          module_name: module_name,
          paths: found_paths
        }.to_json
      end
    end

    private

    def generate_potential_paths(module_name)
      paths = []

      # Convert module name to underscore path
      module_path = module_name_to_path(module_name)

      not_autoloaded = %w[lib test vendor]

      # Application paths to check with glob patterns
      not_autoloaded.each do |base|
        base_dir = Rails.root.join(base).to_s

        # Check exact path match
        exact_path = File.join(base_dir, "#{module_path}.rb")
        paths << exact_path

        # Also glob for the full module path anywhere under the base directory
        glob_pattern = File.join(base_dir, '**', "#{module_path}.rb")
        glob_matches = Dir.glob(glob_pattern)
        paths.concat(glob_matches)
      end

      # For gem paths, split the module name to determine possible gem name
      module_parts = module_name.to_s.split('::')
      if module_parts.size > 1
        potential_gem_name = module_parts.first.underscore
        # Add to the paths to check in gems
        paths << { gem_name: potential_gem_name, path_in_gem: module_path }
      end

      paths.uniq
    end

    def module_name_to_path(module_name)
      # Convert modules like "MyModule::MyThing" to "my_module/my_thing.rb"
      ActiveSupport::Inflector.underscore(module_name)
    end

    def check_paths(potential_paths)
      found_paths = []

      potential_paths.each do |path|
        if path.is_a?(String)
          # Check local application paths
          found_paths << { location: 'application', path: path } if File.exist?(path)
        elsif path.is_a?(Hash) && path[:gem_name] && path[:path_in_gem]
          # Check gem paths
          begin
            gem_paths = check_gem_path(path[:gem_name], path[:path_in_gem])
            found_paths.concat(gem_paths) if gem_paths.any?
          rescue StandardError
            # Skip if gem not found or other errors
          end
        end
      end

      found_paths
    end

    def check_gem_path(gem_name, path_in_gem)
      found_paths = []

      begin
        spec = Gem::Specification.find_by_name(gem_name)

        # Common locations to check in gem
        gem_base_dirs = [
          File.join(spec.gem_dir, 'lib'),
          spec.gem_dir
        ]

        gem_base_dirs.each do |base_dir|
          # Check exact path match
          exact_path = File.join(base_dir, "#{path_in_gem}.rb")
          if File.exist?(exact_path)
            found_paths << {
              location: 'gem',
              gem_name: gem_name,
              gem_version: spec.version.to_s,
              path: exact_path
            }
          end

          # Also glob for the module path in any subdirectory
          glob_pattern = File.join(base_dir, '**', "#{path_in_gem}.rb")
          Dir.glob(glob_pattern).each do |matching_path|
            # Ensure the path is within the gem directory (security check)
            next unless within_gem_dir?(matching_path, spec.gem_dir)

            found_paths << {
              location: 'gem',
              gem_name: gem_name,
              gem_version: spec.version.to_s,
              path: matching_path
            }
          end
        end
      rescue Gem::MissingSpecError
        # Gem not found, return empty array
      end

      found_paths.uniq { |path_data| path_data[:path] }
    end
  end
end
