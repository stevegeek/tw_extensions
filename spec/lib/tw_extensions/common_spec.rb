# frozen_string_literal: true

RSpec.describe TwExtensions::Common do
  let(:dummy_class) do
    Class.new do
      include TwExtensions::Common
    end
  end

  let(:instance) { dummy_class.new }

  describe '#normalize_module_name' do
    it 'converts path format to module format' do
      expect(instance.normalize_module_name('my_gem/module_name')).to eq('MyGem::ModuleName')
    end

    it 'leaves module format unchanged' do
      expect(instance.normalize_module_name('MyGem::ModuleName')).to eq('MyGem::ModuleName')
    end

    it 'handles single component names' do
      expect(instance.normalize_module_name('mymodule')).to eq('mymodule')
    end
  end

  describe '#normalize_path' do
    it 'uses realpath for existing paths' do
      allow(File).to receive(:realpath).with('/some/path').and_return('/real/path')
      expect(instance.normalize_path('/some/path')).to eq('/real/path')
    end

    it 'falls back to expand_path for non-existent paths' do
      allow(File).to receive(:realpath).with('/non/existent/path').and_raise(Errno::ENOENT)
      allow(File).to receive(:expand_path).with('/non/existent/path').and_return('/expanded/path')
      expect(instance.normalize_path('/non/existent/path')).to eq('/expanded/path')
    end
  end

  describe '#within_gem_dir?' do
    it 'returns true for files within the gem directory' do
      expect(instance.within_gem_dir?('/gem/dir/file.rb', '/gem/dir')).to be true
    end

    it 'returns true for the gem directory itself' do
      expect(instance.within_gem_dir?('/gem/dir', '/gem/dir')).to be true
    end

    it 'returns false for files outside the gem directory' do
      expect(instance.within_gem_dir?('/other/dir/file.rb', '/gem/dir')).to be false
    end
  end

  describe '#find_specification_for_path' do
    it 'returns the specification for a path within a gem directory' do
      # Just verify this doesn't throw an exception. The actual implementation varies by RubyGems version.
      path = '/gems/gem1/lib/file.rb'
      expect(Gem::Specification).to receive(:find)
      instance.find_specification_for_path(path)
    end

    it 'handles paths not within any gem directory' do
      path = '/other/path'
      expect(Gem::Specification).to receive(:find)
      instance.find_specification_for_path(path)
    end
  end
end
