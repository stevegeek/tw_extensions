# frozen_string_literal: true

module TwExtensions
  class ListPackageFiles < Tidewave::Tools::Base
    include TwExtensions::Common

    tool_name 'list_package_files'

    description <<~DESCRIPTION
      Returns a list of files in a gem package.

      This can be useful to better understand how a gem works and what you need to require.

      This works for installed gem dependencies only, not for files in the current project.

      The tool can accept either a gem name directly or a module name that resolves to a gem.
    DESCRIPTION

    arguments do
      optional(:gem_name).filled(:string).description('The name of the gem to list files for.')
      optional(:module_name).filled(:string).description('A module name that resolves to a gem. The tool will determine which gem contains this module.')
    end

    def call(gem_name: nil, module_name: nil)
      raise ArgumentError, 'Either gem_name or module_name must be provided' if gem_name.nil? && module_name.nil?

      gem_name = get_gem_name_from_module(module_name) if gem_name.nil? && module_name.present?

      spec = Gem::Specification.find_by_name(gem_name)
      files = list_gem_files(spec)

      {
        gem_name: gem_name,
        gem_version: spec.version.to_s,
        gem_path: spec.gem_dir,
        files: files
      }.to_json
    rescue Gem::MissingSpecError
      raise ArgumentError, "Gem '#{gem_name}' is not installed"
    end

    private

    def get_gem_name_from_module(module_name)
      begin
        module_ref = module_name.constantize
      rescue NameError
        raise NameError, "Module #{module_name} not found"
      end

      # Try to find the source location of the module
      source_location = get_module_source_location(module_ref, module_name)

      # Get the gem name from the source location
      validate_gem_source!(source_location.first)
    end

    def get_module_source_location(module_ref, module_name)
      source_location = module_ref.const_source_location(module_name)
      raise NameError, "Source location for module #{module_name} not found" if source_location.nil?

      source_location
    end

    def validate_gem_source!(file_path)
      normalized_file_path = normalize_path(file_path)
      found_spec = find_specification_for_path(normalized_file_path)

      raise SecurityError, "File '#{file_path}' is not sourced from an installed gem dependency." unless found_spec

      found_spec.name
    end

    def list_gem_files(spec)
      # Get all files from the gem specification
      files = spec.files.map do |file|
        File.join(spec.gem_dir, file)
      end

      # Filter to only include files that actually exist
      files.select { |file| File.exist?(file) }
    end
  end
end
