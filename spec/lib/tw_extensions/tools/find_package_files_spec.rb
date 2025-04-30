# frozen_string_literal: true

describe TwExtensions::FindPackageFiles do
  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('find_package_files')
    end
  end

  describe '.description' do
    it 'returns a non-empty description' do
      expect(described_class.description).to be_a(String)
      expect(described_class.description).not_to be_empty
    end
  end

  describe '.arguments' do
    it 'requires gem_name and pattern parameters' do
      schema = described_class.input_schema_to_json
      expect(schema[:required]).to include('gem_name', 'pattern')
      expect(schema[:properties][:gem_name][:type]).to eq('string')
      expect(schema[:properties][:pattern][:type]).to eq('string')
    end
  end

  describe '#call' do
    subject { described_class.new }

    let(:gem_name) { 'rails' }
    let(:pattern) { '**/*.rb' }
    let(:gem_dir) { '/path/to/rails' }
    let(:gem_version) { '6.1.4' }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, version: gem_version) }
    let(:matched_files) { ['/path/to/rails/lib/file1.rb', '/path/to/rails/lib/file2.rb'] }

    context 'when the gem exists' do
      before do
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_return(spec)
        allow(subject).to receive(:find_matching_files).with(spec, pattern).and_return(matched_files)
      end

      it 'returns a JSON with gem info and matching files' do
        expected_result = {
          gem_name: gem_name,
          gem_version: gem_version.to_s,
          gem_path: gem_dir,
          pattern: pattern,
          matching_files: matched_files
        }.to_json

        expect(subject.call(gem_name: gem_name, pattern: pattern)).to eq(expected_result)
      end
    end

    context 'when the gem does not exist' do
      before do
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_raise(Gem::MissingSpecError.new("Could not find '#{gem_name}' in any repository"))
      end

      it 'raises an ArgumentError' do
        expect { subject.call(gem_name: gem_name, pattern: pattern) }.to raise_error(ArgumentError, "Gem '#{gem_name}' is not installed")
      end
    end
  end

  describe '#find_matching_files' do
    subject { described_class.new }
    
    let(:gem_dir) { '/path/to/gem' }
    let(:pattern) { '**/*.rb' }
    let(:full_pattern) { "#{gem_dir}/#{pattern}" }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir) }
    let(:glob_matches) { ['/path/to/gem/lib/file1.rb', '/path/to/gem/lib/file2.rb', '/different/path/file3.rb'] }
    
    before do
      allow(File).to receive(:join).with(gem_dir, pattern).and_return(full_pattern)
      allow(Dir).to receive(:glob).with(full_pattern).and_return(glob_matches)
      
      # Setup within_gem_dir? mocks
      allow(subject).to receive(:normalize_path).with(glob_matches[0]).and_return(glob_matches[0])
      allow(subject).to receive(:normalize_path).with(glob_matches[1]).and_return(glob_matches[1])
      allow(subject).to receive(:normalize_path).with(glob_matches[2]).and_return(glob_matches[2])
      allow(subject).to receive(:within_gem_dir?).with(glob_matches[0], gem_dir).and_return(true)
      allow(subject).to receive(:within_gem_dir?).with(glob_matches[1], gem_dir).and_return(true)
      allow(subject).to receive(:within_gem_dir?).with(glob_matches[2], gem_dir).and_return(false)
    end

    it 'returns only files within the gem directory' do
      expect(subject.send(:find_matching_files, spec, pattern)).to eq([glob_matches[0], glob_matches[1]])
    end
  end
end