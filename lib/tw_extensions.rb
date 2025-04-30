# frozen_string_literal: true

require 'fast_mcp'
require 'tidewave/tools/base'
require_relative 'tw_extensions/version'
require_relative 'tw_extensions/common'

# Load all tools
Dir[File.join(__dir__, 'tw_extensions', 'tools', '*.rb')].sort.each { |file| require file }

# Load railtie
require_relative 'tw_extensions/railtie' if defined?(Rails)

module TwExtensions
  # Returns all tool classes defined in the TwExtensions module
  def self.tools
    constants.map { |const| const_get(const) }
             .select { |const| const.is_a?(Class) && const < Tidewave::Tools::Base }
  end
end

module Tidewave
  class ToolResolver
    # Monkey patch this to ensure we load our tools too
    def register_non_file_system_tools
      reset_server_tools
      tools = NON_FILE_SYSTEM_TOOLS + TwExtensions.tools
      @server.register_tools(*tools)
    end

    def register_all_tools
      reset_server_tools
      tools = ALL_TOOLS + TwExtensions.tools
      @server.register_tools(*tools)
    end
  end
end
