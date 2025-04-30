# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'

module TwExtensions
  # Common helper methods for all tools
  module Common
    def normalize_module_name(module_name)
      # Check if the module name is in path format (contains '/' but not '::')
      if module_name.include?('/') && !module_name.include?('::')
        # Convert path format to Ruby module format
        # e.g., 'my_gem/module_name' -> 'MyGem::ModuleName'
        module_name.split('/').map(&:camelize).join('::')
      else
        module_name
      end
    end

    def normalize_path(path)
      # Use File.realpath to resolve symlinks for maximum accuracy.
      # Fall back to expand_path if the file doesn't exist yet (e.g., checking
      # a potential path structure) or if realpath fails for other reasons.
      File.realpath(path)
    rescue Errno::ENOENT
      File.expand_path(path)
    end

    def within_gem_dir?(file_path, gem_dir)
      normalized_file_path = normalize_path(file_path)
      normalized_gem_dir = normalize_path(gem_dir)
      normalized_file_path.start_with?(normalized_gem_dir + File::SEPARATOR) || normalized_file_path == normalized_gem_dir
    end

    def find_specification_for_path(absolute_file_path)
      Gem::Specification.find do |spec|
        # Normalize the gem directory path for consistent comparison.
        gem_dir = normalize_path(spec.gem_dir)

        # Check if the file path starts with the gem directory path, ensuring
        # it matches the directory boundary. Also handles the case where the
        # path *is* the gem directory itself.
        absolute_file_path.start_with?(gem_dir + File::SEPARATOR) || absolute_file_path == gem_dir
      end
    end
  end
end
