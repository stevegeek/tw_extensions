# frozen_string_literal: true

describe TwExtensions::GetPackageFileSource do
  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('get_package_file_source')
    end
  end

  describe '.description' do
    it 'returns a non-empty description' do
      expect(described_class.description).to be_a(String)
      expect(described_class.description).not_to be_empty
    end
  end

  describe '.arguments' do
    it 'requires path parameter' do
      schema = described_class.input_schema_to_json
      expect(schema[:required]).to include('path')
      expect(schema[:properties][:path][:type]).to eq('string')
    end
  end

  describe '#call' do
    subject { described_class.new }

    let(:path) { '/path/to/gem/file.rb' }
    let(:file_content) { 'This is the file content' }

    before do
      allow(subject).to receive(:validate_gem_source!).with(path).and_return(true)
    end

    context 'when the file is from a gem' do
      it 'reads the file content' do
        allow(File).to receive(:read).with(path).and_return(file_content)
        expect(subject.call(path: path)).to eq(file_content)
      end
    end

    context 'when the file is not from a gem' do
      it 'raises a SecurityError' do
        allow(subject).to receive(:validate_gem_source!).with(path).and_raise(SecurityError.new("File '#{path}' is not sourced from an installed gem dependency."))
        expect { subject.call(path: path) }.to raise_error(SecurityError, "File '#{path}' is not sourced from an installed gem dependency.")
      end
    end
  end

  describe '#validate_gem_source!' do
    subject { described_class.new }
    let(:path) { '/path/to/gem/file.rb' }
    let(:normalized_path) { '/normalized/path/to/gem/file.rb' }
    let(:spec) { instance_double('Gem::Specification') }

    before do
      allow(subject).to receive(:normalize_path).with(path).and_return(normalized_path)
    end

    context 'when the file is from a gem' do
      it 'returns true' do
        allow(subject).to receive(:find_specification_for_path).with(normalized_path).and_return(spec)
        expect(subject.send(:validate_gem_source!, path)).to be true
      end
    end

    context 'when the file is not from a gem' do
      it 'raises a SecurityError' do
        allow(subject).to receive(:find_specification_for_path).with(normalized_path).and_return(nil)
        expect { subject.send(:validate_gem_source!, path) }.to raise_error(SecurityError, "File '#{path}' is not sourced from an installed gem dependency.")
      end
    end
  end
end