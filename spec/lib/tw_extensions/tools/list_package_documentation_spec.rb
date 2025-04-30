# frozen_string_literal: true

describe TwExtensions::ListPackageDocumentation do
  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('list_package_documentation')
    end
  end

  describe '.description' do
    it 'returns a non-empty description' do
      expect(described_class.description).to be_a(String)
      expect(described_class.description).not_to be_empty
    end
  end

  describe '.arguments' do
    it 'requires gem_name parameter' do
      schema = described_class.input_schema_to_json
      expect(schema[:required]).to include('gem_name')
      expect(schema[:properties][:gem_name][:type]).to eq('string')
    end

    it 'has an optional include_content parameter' do
      schema = described_class.input_schema_to_json
      expect(schema[:properties][:include_content][:type]).to eq('boolean')
    end
  end

  describe '#call' do
    subject { described_class.new }

    let(:gem_name) { 'rails' }
    let(:gem_dir) { '/path/to/rails' }
    let(:gem_version) { '6.1.4' }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, version: gem_version) }
    let(:doc_files) { ['/path/to/rails/README.md', '/path/to/rails/CHANGELOG.md'] }

    before do
      allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_return(spec)
      allow(subject).to receive(:find_documentation_files).with(spec).and_return(doc_files)
    end

    context 'when include_content is false' do
      it 'returns a JSON with gem info and doc files' do
        expected_result = {
          gem_name: gem_name,
          gem_version: gem_version.to_s,
          gem_path: gem_dir,
          documentation_files: doc_files
        }.to_json

        expect(subject.call(gem_name: gem_name, include_content: false)).to eq(expected_result)
      end
    end

    context 'when include_content is true' do
      let(:files_with_content) do
        [
          { path: doc_files[0], content: 'README content' },
          { path: doc_files[1], content: 'CHANGELOG content' }
        ]
      end

      before do
        allow(subject).to receive(:files_with_content).with(doc_files).and_return(files_with_content)
      end

      it 'returns a JSON with gem info and doc files with content' do
        expected_result = {
          gem_name: gem_name,
          gem_version: gem_version.to_s,
          gem_path: gem_dir,
          documentation_files: files_with_content
        }.to_json

        expect(subject.call(gem_name: gem_name, include_content: true)).to eq(expected_result)
      end
    end

    context 'when the gem does not exist' do
      before do
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_raise(Gem::MissingSpecError.new("Could not find '#{gem_name}' in any repository"))
      end

      it 'raises an ArgumentError' do
        expect { subject.call(gem_name: gem_name) }.to raise_error(ArgumentError, "Gem '#{gem_name}' is not installed")
      end
    end
  end

  describe '#find_documentation_files' do
    subject { described_class.new }
    
    let(:gem_dir) { '/path/to/gem' }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir) }
    let(:doc_patterns) do
      [
        'README', 'README.md',
        'CHANGELOG', 'CHANGELOG.md',
        'doc/**/*.md', 'docs/**/*.md',
        'documentation/**/*.md',
        'example*/**/*.rb', 'examples/**/*.rb',
        'sample/**/*.rb', 'samples/**/*.rb',
        'guides/**/*.md', 'guide/**/*.md'
      ]
    end
    
    let(:matches) do
      {
        'README': ['/path/to/gem/README'],
        'README.md': ['/path/to/gem/README.md'],
        'docs/**/*.md': ['/path/to/gem/docs/guide.md', '/path/to/gem/docs/api.md'],
        'examples/**/*.rb': ['/path/to/gem/examples/sample.rb']
      }
    end

    before do
      allow(subject).to receive(:allowed_extensions).and_return('md,markdown,rdoc,txt,html')
      
      # Setup expectations for each pattern
      doc_patterns.each do |pattern|
        full_pattern = File.join(gem_dir, pattern)
        
        if matches.key?(pattern.to_sym)
          allow(Dir).to receive(:glob).with(full_pattern, File::FNM_CASEFOLD).and_return(matches[pattern.to_sym])
          
          # Setup file existence and within_gem_dir checks
          matches[pattern.to_sym].each do |file_path|
            allow(File).to receive(:file?).with(file_path).and_return(true)
            allow(subject).to receive(:within_gem_dir?).with(file_path, gem_dir).and_return(true)
          end
        else
          allow(Dir).to receive(:glob).with(full_pattern, File::FNM_CASEFOLD).and_return([])
        end
      end
    end

    it 'returns unique doc files sorted' do
      expected_files = [
        '/path/to/gem/README',
        '/path/to/gem/README.md',
        '/path/to/gem/docs/api.md',
        '/path/to/gem/docs/guide.md',
        '/path/to/gem/examples/sample.rb'
      ].sort

      expect(subject.send(:find_documentation_files, spec)).to eq(expected_files)
    end
  end

  describe '#files_with_content' do
    subject { described_class.new }
    
    let(:file_paths) { ['/path/to/file1.md', '/path/to/file2.md', '/path/to/large_file.md'] }
    
    before do
      allow(File).to receive(:size).with(file_paths[0]).and_return(100)
      allow(File).to receive(:size).with(file_paths[1]).and_return(500)
      allow(File).to receive(:size).with(file_paths[2]).and_return(2_000_000) # Over 1MB limit
      
      allow(File).to receive(:read).with(file_paths[0]).and_return('Content 1')
      allow(File).to receive(:read).with(file_paths[1]).and_return('Content 2')
    end

    it 'returns files with content or error messages' do
      result = subject.send(:files_with_content, file_paths)
      
      expect(result.length).to eq(3)
      expect(result[0][:path]).to eq(file_paths[0])
      expect(result[0][:content]).to eq('Content 1')
      
      expect(result[1][:path]).to eq(file_paths[1])
      expect(result[1][:content]).to eq('Content 2')
      
      expect(result[2][:path]).to eq(file_paths[2])
      expect(result[2][:content]).to eq('File too large to include content (2000000 bytes)')
    end

    context 'when file reading fails' do
      before do
        allow(File).to receive(:read).with(file_paths[1]).and_raise(StandardError.new('Permission denied'))
      end

      it 'returns an error message for the failed file' do
        result = subject.send(:files_with_content, file_paths)
        
        expect(result[1][:path]).to eq(file_paths[1])
        expect(result[1][:error]).to eq('Could not read file: Permission denied')
      end
    end
  end
end