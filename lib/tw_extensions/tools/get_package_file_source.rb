# frozen_string_literal: true

module TwExtensions
  class GetPackageFileSource < Tidewave::Tools::Base
    include TwExtensions::Common

    tool_name 'get_package_file_source'

    description <<~DESCRIPTION
      Reads a file for a gem dependency.

      This can be useful to better understand how a gem works and how to use it.

      This works for files in installed gem dependencies only, not for files in the current project.

      This tool only works if you know that the file to read is in the installed gems.
      If that is the case, prefer this tool over reading from the file system using a default tool as this checks to
      make sure the file being read is infact a gem package file.
    DESCRIPTION

    arguments do
      required(:path).filled(:string).description('The path to the file to read. It is an absolute path to the file in the installed gem.')
    end

    def call(path:)
      # Verify the file is from a gem and not from some other location
      validate_gem_source!(path)

      File.read(path)
    end

    private

    def validate_gem_source!(file_path)
      normalized_file_path = normalize_path(file_path)
      found_spec = find_specification_for_path(normalized_file_path)

      raise SecurityError, "File '#{file_path}' is not sourced from an installed gem dependency." unless found_spec

      true
    end
  end
end
