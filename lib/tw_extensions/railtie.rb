# frozen_string_literal: true

module TwExtensions
  # Railtie to integrate with Rails
  class Railtie < Rails::Railtie
    initializer 'tw_extensions.configure_rails_initialization' do |app|
      # Executed during Rails initialization
    end

    # Register all TwExtensions tools with FastMcp after Rails is initialized
    config.after_initialize do |app|
      FastMcp.server.register_tools(*TwExtensions.tools)
    end
  end
end