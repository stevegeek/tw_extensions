# frozen_string_literal: true

describe TwExtensions::CheckConventionalSourceLocation do
  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('check_conventional_source_location')
    end
  end

  describe '.description' do
    it 'returns a non-empty description' do
      expect(described_class.description).to be_a(String)
      expect(described_class.description).not_to be_empty
    end
  end

  describe '.arguments' do
    it 'requires module_name parameter' do
      schema = described_class.input_schema_to_json
      expect(schema[:required]).to include('module_name')
      expect(schema[:properties][:module_name][:type]).to eq('string')
    end
  end

  describe '#call' do
    subject { described_class.new }
    let(:module_name) { 'MyModule::MyClass' }

    context 'when potential paths are found' do
      let(:potential_paths) { ['/path/to/app/lib/my_module/my_class.rb', { gem_name: 'my_module', path_in_gem: 'my_module/my_class' }] }
      let(:found_paths) do
        [
          { location: 'application', path: '/path/to/app/lib/my_module/my_class.rb' },
          { location: 'gem', gem_name: 'my_module', gem_version: '1.0.0', path: '/path/to/gems/my_module/lib/my_module/my_class.rb' }
        ]
      end

      before do
        allow(subject).to receive(:generate_potential_paths).with(module_name).and_return(potential_paths)
        allow(subject).to receive(:check_paths).with(potential_paths).and_return(found_paths)
      end

      it 'returns a JSON with found paths' do
        expected_result = {
          found: true,
          module_name: module_name,
          paths: found_paths
        }.to_json

        expect(subject.call(module_name: module_name)).to eq(expected_result)
      end
    end

    context 'when no paths are found' do
      before do
        allow(subject).to receive(:generate_potential_paths).with(module_name).and_return([])
        allow(subject).to receive(:check_paths).with([]).and_return([])
      end

      it 'returns a JSON with found status false' do
        expected_result = {
          found: false,
          message: "No conventional source location found for #{module_name}"
        }.to_json

        expect(subject.call(module_name: module_name)).to eq(expected_result)
      end
    end
  end

  describe '#generate_potential_paths' do
    subject { described_class.new }
    let(:module_name) { 'MyModule::MyClass' }
    let(:module_path) { 'my_module/my_class' }
    let(:rails_root) { Pathname.new('/path/to/app') }
    let(:lib_path) { '/path/to/app/lib' }
    let(:test_path) { '/path/to/app/test' }
    let(:vendor_path) { '/path/to/app/vendor' }

    before do
      allow(subject).to receive(:module_name_to_path).with(module_name).and_return(module_path)
      allow(Rails).to receive_message_chain(:root, :join).with('lib').and_return(Pathname.new(lib_path))
      allow(Rails).to receive_message_chain(:root, :join).with('test').and_return(Pathname.new(test_path))
      allow(Rails).to receive_message_chain(:root, :join).with('vendor').and_return(Pathname.new(vendor_path))
      
      # Exact paths
      allow(File).to receive(:join).with(lib_path, "#{module_path}.rb").and_return("#{lib_path}/#{module_path}.rb")
      allow(File).to receive(:join).with(test_path, "#{module_path}.rb").and_return("#{test_path}/#{module_path}.rb")
      allow(File).to receive(:join).with(vendor_path, "#{module_path}.rb").and_return("#{vendor_path}/#{module_path}.rb")
      
      # Glob patterns
      allow(File).to receive(:join).with(lib_path, '**', "#{module_path}.rb").and_return("#{lib_path}/**/#{module_path}.rb")
      allow(File).to receive(:join).with(test_path, '**', "#{module_path}.rb").and_return("#{test_path}/**/#{module_path}.rb")
      allow(File).to receive(:join).with(vendor_path, '**', "#{module_path}.rb").and_return("#{vendor_path}/**/#{module_path}.rb")
      
      allow(Dir).to receive(:glob).with("#{lib_path}/**/#{module_path}.rb").and_return(["#{lib_path}/nested/#{module_path}.rb"])
      allow(Dir).to receive(:glob).with("#{test_path}/**/#{module_path}.rb").and_return([])
      allow(Dir).to receive(:glob).with("#{vendor_path}/**/#{module_path}.rb").and_return([])
    end

    it 'generates potential paths in application directories and for gems' do
      paths = subject.send(:generate_potential_paths, module_name)
      
      # Should include exact paths
      expect(paths).to include("#{lib_path}/#{module_path}.rb")
      expect(paths).to include("#{test_path}/#{module_path}.rb")
      expect(paths).to include("#{vendor_path}/#{module_path}.rb")
      
      # Should include glob matches
      expect(paths).to include("#{lib_path}/nested/#{module_path}.rb")
      
      # Should include gem path info
      expect(paths).to include({ gem_name: 'my_module', path_in_gem: module_path })
    end
  end

  describe '#check_paths' do
    subject { described_class.new }
    
    let(:app_path) { '/path/to/app/lib/my_module/my_class.rb' }
    let(:gem_path_info) { { gem_name: 'my_module', path_in_gem: 'my_module/my_class' } }
    let(:potential_paths) { [app_path, gem_path_info, '/non/existent/path.rb'] }
    let(:gem_paths) do
      [
        { location: 'gem', gem_name: 'my_module', gem_version: '1.0.0', path: '/path/to/gems/my_module/lib/my_module/my_class.rb' }
      ]
    end
    
    before do
      allow(File).to receive(:exist?).with(app_path).and_return(true)
      allow(File).to receive(:exist?).with('/non/existent/path.rb').and_return(false)
      allow(subject).to receive(:check_gem_path).with('my_module', 'my_module/my_class').and_return(gem_paths)
    end

    it 'checks application and gem paths and returns found paths' do
      results = subject.send(:check_paths, potential_paths)
      
      expect(results.length).to eq(2)
      expect(results[0]).to eq({ location: 'application', path: app_path })
      expect(results[1]).to eq(gem_paths[0])
    end

    context 'when gem check raises an error' do
      before do
        allow(subject).to receive(:check_gem_path).with('my_module', 'my_module/my_class').and_raise(StandardError.new('Some error'))
      end

      it 'skips the error and continues' do
        results = subject.send(:check_paths, potential_paths)
        
        expect(results.length).to eq(1)
        expect(results[0]).to eq({ location: 'application', path: app_path })
      end
    end
  end

  describe '#check_gem_path' do
    subject { described_class.new }
    
    let(:gem_name) { 'my_module' }
    let(:path_in_gem) { 'my_module/my_class' }
    let(:gem_dir) { '/path/to/gems/my_module' }
    let(:lib_dir) { "#{gem_dir}/lib" }
    let(:gem_version) { '1.0.0' }
    let(:exact_path_in_lib) { "#{lib_dir}/#{path_in_gem}.rb" }
    let(:exact_path_in_root) { "#{gem_dir}/#{path_in_gem}.rb" }
    let(:spec) { instance_double('Gem::Specification', gem_dir: gem_dir, version: gem_version) }
    
    before do
      allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_return(spec)
      
      allow(File).to receive(:join).with(lib_dir, "#{path_in_gem}.rb").and_return(exact_path_in_lib)
      allow(File).to receive(:join).with(gem_dir, "#{path_in_gem}.rb").and_return(exact_path_in_root)
      
      # Glob patterns
      allow(File).to receive(:join).with(lib_dir, '**', "#{path_in_gem}.rb").and_return("#{lib_dir}/**/#{path_in_gem}.rb")
      allow(File).to receive(:join).with(gem_dir, '**', "#{path_in_gem}.rb").and_return("#{gem_dir}/**/#{path_in_gem}.rb")
      
      allow(Dir).to receive(:glob).with("#{lib_dir}/**/#{path_in_gem}.rb").and_return(["#{lib_dir}/nested/#{path_in_gem}.rb"])
      allow(Dir).to receive(:glob).with("#{gem_dir}/**/#{path_in_gem}.rb").and_return([])
      
      # File existence
      allow(File).to receive(:exist?).with(exact_path_in_lib).and_return(true)
      allow(File).to receive(:exist?).with(exact_path_in_root).and_return(false)
      
      # Within gem dir checks
      allow(subject).to receive(:within_gem_dir?).with("#{lib_dir}/nested/#{path_in_gem}.rb", gem_dir).and_return(true)
    end

    it 'returns matches in the gem directory with proper metadata' do
      results = subject.send(:check_gem_path, gem_name, path_in_gem)
      
      expect(results.length).to eq(2) # One exact match and one glob match
      
      expect(results[0]).to eq({
        location: 'gem',
        gem_name: gem_name,
        gem_version: gem_version.to_s,
        path: exact_path_in_lib
      })
      
      expect(results[1]).to eq({
        location: 'gem',
        gem_name: gem_name,
        gem_version: gem_version.to_s,
        path: "#{lib_dir}/nested/#{path_in_gem}.rb"
      })
    end

    context 'when the gem does not exist' do
      before do
        allow(Gem::Specification).to receive(:find_by_name).with(gem_name).and_raise(Gem::MissingSpecError.new("Could not find '#{gem_name}' in any repository"))
      end

      it 'returns an empty array' do
        expect(subject.send(:check_gem_path, gem_name, path_in_gem)).to eq([])
      end
    end
  end

  describe '#module_name_to_path' do
    subject { described_class.new }

    it 'converts module names to underscore paths' do
      expect(subject.send(:module_name_to_path, 'MyModule::MyClass')).to eq('my_module/my_class')
      expect(subject.send(:module_name_to_path, 'A::B::C')).to eq('a/b/c')
      expect(subject.send(:module_name_to_path, 'SingleModule')).to eq('single_module')
    end
  end
end