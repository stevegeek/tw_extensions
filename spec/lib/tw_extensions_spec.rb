# frozen_string_literal: true

RSpec.describe TwExtensions do
  it 'has a version number' do
    expect(TwExtensions::VERSION).not_to be nil
  end

  let(:all_tool_classes) do
    [
      TwExtensions::GetPackageFileSource,
      TwExtensions::ListPackageFiles,
      TwExtensions::FindPackageFiles,
      TwExtensions::ListPackageDocumentation,
      TwExtensions::CheckConventionalSourceLocation
    ]
  end

  describe '.tools' do
    it 'returns a list of tool classes' do
      tools = TwExtensions.tools

      # Check that we got an array of classes
      expect(tools).to be_an(Array)
      expect(tools).not_to be_empty
      expect(tools).to all(be_a(Class))

      # All tools should inherit from Tidewave::Tools::Base
      expect(tools).to all(be < Tidewave::Tools::Base)

      # Check for specific tools
      tool_names = tools.map(&:tool_name)
      expected_tools = all_tool_classes.map(&:tool_name)

      expected_tools.each do |tool_name|
        expect(tool_names).to include(tool_name)
      end
    end
  end
end
