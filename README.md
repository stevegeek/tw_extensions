# TwExtensions

Unofficial extensions for the [Tidewave](https://tidewave.ai/) [`tidewave` gem](https://github.com/tidewave-ai/tidewave_rails) providing additional tools for working with gem dependencies and source code analysis.

## Installation

Add it to your Gemfile:

```ruby
gem 'tw_extensions', github: 'stevegeek/tw_extensions'
```

Then execute:

```bash
$ bundle install
```

It's a Rails plugin so it will automatically register itself with the Tidewave when you start your Rails application.

## Tools

TwExtensions provides the following tools:

### GetPackageFileSource

Reads a file from a gem dependency. Useful to better understand how a gem works and how to use it.

```ruby
tidewave:get_package_file_source(path: '/path/to/gem/file.rb')
```

### ListPackageFiles

Returns a list of files in a gem package.

```ruby
tidewave:list_package_files(gem_name: 'rails')
# or
tidewave:list_package_files(module_name: 'Rails')
```

### FindPackageFiles

Searches for files matching a pattern in a gem package.

```ruby
tidewave:find_package_files(gem_name: 'rails', pattern: '**/*.rb')
```

### ListPackageDocumentation

Lists documentation files found in a gem package.

```ruby
tidewave:list_package_documentation(gem_name: 'rails')
# or with content
tidewave:list_package_documentation(gem_name: 'rails', include_content: true)
```

### CheckConventionalSourceLocation

Checks for a module's source file using Ruby conventions when the module is not loaded.

```ruby
tidewave:check_conventional_source_location(module_name: 'MyModule::MyClass')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/tw_extensions. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/tw_extensions/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TwExtensions project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tw_extensions/blob/main/CODE_OF_CONDUCT.md).
