# Bp3::Core

bp3-core provides core concerns for BP3, the persuavis/black_phoebe_3 multi-site 
multi-tenant rails application.

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

In all controllers (or their base class), add
```ruby
include Bp3::Core::Actions
include Bp3::Core::Cookies
```
In ActiveRecord models(or their base class) that are displayed to users, add:
```ruby
include Bp3::Core::Displayable
```
In models, controllers, services and helpers that use feature flags, add:
```ruby
include Bp3::Core::FeatureFlags
include Bp3::Core::Settings
```
In ActiveRecord models (or their base class) that are filtered/sorted with ransack, add:
```ruby
include Bp3::Core::Ransackable
```
Then in your application's `config/initializers/bp3-core`, add:
```ruby
Bp3::Core::Ransackable.attribute_exceptions = %w[config config_id settable settable_id]
Bp3::Core::Ransackable.association_exceptions = %w[config settable]
```
In all ActiveRecord models (or their base class) with a request-id attribute :rqid, add:
```ruby
include Bp3::Core::Rqid
```
Then in your application's `config/initializers/bp3-core`, add:
```ruby
Bp3::Core::Rqid.global_request_state_class_name = 'GlobalRequestState'
Bp3::Core::Rqid.global_request_state_method = :request_id
```
In all ActiveRecord models (or their base class) with a sequence number attribute :sqnr, add:
```ruby
include Bp3::Core::Sqnr
```
To use :sqnr for record ordering for a particular model, use the class macro:
```ruby
use_sqnr_for_ordering
```
In all ActiveRecord models (or their base class) that use site, tenant and/or workspace 
attributes that need to be populated from global state, add:
```ruby
include Bp3::Core::Tenantable
```
The specific columns expected by `Tenantable` are:

- site: `sites_site_id`
- tenant: `tenant_id`
- workspace: `workspaces_workspace_id`
Tenantable will use reflection to determine which one(s) exist, and will create associations and callbacks accordingly. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You 
can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `rake install`. To release a new version, 
update the version number in `version.rb`, and then run `rake release`, which will create a git 
tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing
The `Bp3::Core::Test` class is for testing purposes.

Run `rake` to run rspec tests and rubocop linting.

## Documentation
A `.yardopts` file is provided to support yard documentation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
