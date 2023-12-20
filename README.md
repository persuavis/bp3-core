# Bp3::Core

bp3-core provides core includes for black_phoebe_3.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bp3-core'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bp3-core

## Usage

In models that are filtered/sorted with ransack, add:
```ruby
include Bp3::Ransackable
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/persuavis/bp3-core.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
