# frozen_string_literal: true

describe TwExtensions::ListPackageFiles do
  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('list_package_files')
    end
  end

  describe '.description' do
    it 'returns a non-empty description' do
      expect(described_class.description).to be_a(String)
      expect(described_class.description).not_to be_empty
    end
  end

  describe '.arguments' do
    it 'defines optional gem_name and module_name parameters' do
      schema = described_class.input_schema_to_json
      expect(schema[:properties][:gem_name][:type]).to eq('string')
      expect(schema[:properties][:module_name][:type]).to eq('string')
    end

    it 'does not require any specific parameter' do
      schema = described_class.input_schema_to_json
      expect(schema[:required]).to be_nil
    end
  end

  describe '#call' do
    subject { described_class.new }

    context 'when neither gem_name nor module_name is provided' do
      it 'raises an ArgumentError' do
        expect { subject.call }.to raise_error(ArgumentError, 'Either gem_name or module_name must be provided')
      end
    end

    context 'when gem_name is provided' do
      let(:gem_name) { 'rails' }
      let(:gem_dir) { '/path/to/rails' }
      let(:gem_version) { '6.1.4' }
      let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, version: gem_version) }
      let(:files) { ['/path/to/rails/file1.rb', '/path/to/rails/file2.rb'] }
      
      before do
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_return(spec)
        allow(subject).to receive(:list_gem_files).with(spec).and_return(files)
      end

      it 'returns a JSON with gem info and files' do
        expected_result = {
          gem_name: gem_name,
          gem_version: gem_version.to_s,
          gem_path: gem_dir,
          files: files
        }.to_json

        expect(subject.call(gem_name: gem_name)).to eq(expected_result)
      end
    end

    context 'when module_name is provided' do
      let(:module_name) { 'Rails' }
      let(:gem_name) { 'rails' }
      let(:gem_dir) { '/path/to/rails' }
      let(:gem_version) { '6.1.4' }
      let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, version: gem_version) }
      let(:files) { ['/path/to/rails/file1.rb', '/path/to/rails/file2.rb'] }
      let(:source_location) { ['/path/to/rails/lib/rails.rb', 10] }

      before do
        module_ref = Module.new
        allow(Module).to receive(:const_get).with('Rails').and_return(module_ref)
        allow(subject).to receive(:get_gem_name_from_module).with(module_name).and_return(gem_name)
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_return(spec)
        allow(subject).to receive(:list_gem_files).with(spec).and_return(files)
      end

      it 'finds the gem name from the module and returns a JSON with gem info and files' do
        expected_result = {
          gem_name: gem_name,
          gem_version: gem_version.to_s,
          gem_path: gem_dir,
          files: files
        }.to_json

        expect(subject.call(module_name: module_name)).to eq(expected_result)
      end
    end
  end

  describe '#get_gem_name_from_module' do
    subject { described_class.new }
    let(:module_name) { 'Rails' }
    let(:module_ref) { Module.new }
    let(:source_location) { ['/path/to/rails/lib/rails.rb', 10] }
    let(:gem_name) { 'rails' }

    context 'when the module is found' do
      before do
        allow(module_name).to receive(:constantize).and_return(module_ref)
        allow(subject).to receive(:get_module_source_location).with(module_ref, module_name).and_return(source_location)
        allow(subject).to receive(:validate_gem_source!).with(source_location.first).and_return(gem_name)
      end

      it 'returns the gem name' do
        expect(subject.send(:get_gem_name_from_module, module_name)).to eq(gem_name)
      end
    end

    context 'when the module is not found' do
      before do
        allow(module_name).to receive(:constantize).and_raise(NameError.new("Module #{module_name} not found"))
      end

      it 'raises a NameError' do
        expect { subject.send(:get_gem_name_from_module, module_name) }.to raise_error(NameError, "Module #{module_name} not found")
      end
    end
  end

  describe '#list_gem_files' do
    subject { described_class.new }
    let(:gem_dir) { '/path/to/gem' }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, files: ['file1.rb', 'file2.rb', 'non_existent.rb']) }
    let(:full_paths) { ['/path/to/gem/file1.rb', '/path/to/gem/file2.rb', '/path/to/gem/non_existent.rb'] }
    
    before do
      allow(File).to receive(:join).with(gem_dir, 'file1.rb').and_return(full_paths[0])
      allow(File).to receive(:join).with(gem_dir, 'file2.rb').and_return(full_paths[1])
      allow(File).to receive(:join).with(gem_dir, 'non_existent.rb').and_return(full_paths[2])
      
      allow(File).to receive(:exist?).with(full_paths[0]).and_return(true)
      allow(File).to receive(:exist?).with(full_paths[1]).and_return(true)
      allow(File).to receive(:exist?).with(full_paths[2]).and_return(false)
    end

    it 'returns only existing files with full paths' do
      expect(subject.send(:list_gem_files, spec)).to eq([full_paths[0], full_paths[1]])
    end
  end
end