# frozen_string_literal: true

require 'tidewave'
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