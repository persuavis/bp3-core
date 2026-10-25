# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bp3-core is a Ruby gem providing core ActiveSupport concerns for BP3 (persuavis/black_phoebe_3), a
multi-site multi-tenant Rails application. The concerns handle tenancy, request tracking, sequence
ordering, ransack, feature flags, cookies and system logging, for the application's models and controllers
and for the other bp3 gems, which mix them into third-party classes (noticed, friendly_id, pg_search,
ActionText, ActiveStorage, paper_trail, ActiveAdmin, Rails' mailer previews).

## Commands

The gems run on Ruby 3.4.6 (`.ruby-version`). Prefix commands with `~/.rvm/bin/rvm 3.4.6 do` when the
shell is not already on it; a missing `rspec` means the wrong Ruby, not a missing bundle.

- `bundle exec rake` - specs and RuboCop (the default task)
- `bundle exec rspec spec/path/to/file_spec.rb[:LINE]` - one file or example
- `bundle exec rubocop` / `bundle exec rubocop -a`
- `bin/setup`, `bin/console`, `rake install`, `yard doc`

The specs have no database or Rails app: test a concern's decisions through plain Ruby (e.g.
`Tenantable.reaches_every_site?` with a struct standing in for the request state), and try a change against
the application by putting this repo's `lib` ahead of the bundled gem. `lib/bp3/core/test.rb` is a plain
class that stubs `before_action`, `belongs_to` and the like and includes every concern; the gem does not
require it.

## Architecture

### Model concerns

**Tenantable** (`tenantable.rb`)
- `configure_tenancy` looks at which of `sites_site_id`, `tenant_id` and `workspaces_workspace_id` the
  table has and only sets up those: `belongs_to` (optional when the column is nullable), `site`/`workspace`
  aliases, `before_validation` callbacks that fill the column from the request state's `either_*_id`, and
  validations that tenant and workspace belong to the record's site
- Site and tenant get default scopes from the request state's `either_site`/`either_tenant`. How far they
  reach is decided by the primary login, `current_login`, the least privileged one signed in: a root reaches
  every site and an admin every tenant of theirs, but not when a less privileged login is signed in beside
  them -- see `Tenantable.reaches_every_site?` and `.reaches_every_tenant?`
- Including it calls `connection` to load column metadata, unless `IGNORE_NOTIFICATIONS` is set
- The gem does not know the application's `GlobalRequestState`, only its parent `Bp3::RequestState::Base`
  (gem bp3-request_state): use that API -- `current_login`, `current_root`, `current_admin`, `either_site`
  and the like -- through `Bp3::Core::Tenantable.global_request_state`, never the constant

**Rqid** (`rqid.rb`)
- `before_create` sets `rqid` from the configured request state class and method
- optional `belongs_to` `original_request`, `original_response` and `original_visit` on `rqid` (more than
  one record may share an rqid)
- `Bp3::Core::Rqid.global_request_state_class` is where every bp3 gem gets the request state class

**Sqnr** (`sqnr.rb`): `sqnr` (ascending) and `rnqs` (descending) scopes; `use_sqnr_for_ordering` sets
`implicit_order_column`

**Ransackable** (`ransackable.rb`): `ransackable_attributes` (all columns), `ransackable_associations` (all
associations), `ransackable_scopes` (none), `ransackable_fields` (all three), `ransortable_attributes`,
minus the global `attribute_exceptions` and `association_exceptions`

**Displayable** (`displayable.rb`): `to_dom_id`, `display_name`/`admin_display_name` ("ClassName id"),
`i18n_key`, and `filtered_attributes`, which masks `Rails.application.config.filter_parameters` (also inside
`object`/`object_changes` for versions) with `version_filter_mask`; classes override the mask to tell
sources apart

### Controller concerns

**Actions** (`actions.rb`): the request pipeline. Prepended before actions, in order: `set_rqid`,
`check_site`, `check_workspace`, `check_tenant` (each finds or creates the record and stores it in the
request state); then paper_trail whodunnit, user agent and `Inbound::Request` records (skipped under do not
track), the maintenance-mode check, and `set_global_request_state` for the logins, locale and view context.
Also `info_for_paper_trail`, `user_for_paper_trail`, `pundit_user` and `default_url_options` with the
locale. The order of the prepends matters; do not change it

**Cookies** (`cookies.rb`): the `_bp3_visitor` signed cookie that finds or creates the `Users::Visitor`,
the do-not-track cookie, and migration from the old per-site/tenant cookie name

**Settings** (`settings.rb`): `create_request_record_is_on?`, `multi_tenant_is_on?`

**FeatureFlags** (`feature_flags.rb`): `efon?` (a `Feature::Enabler`), `cfon?` (a record's `configs`),
`efcfon?` (either, the config winning when both are set)

### Anywhere

**SystemLogs** (`system_logs.rb`): `log`, `log_debug`, `log_info`, `log_warn`, `log_error`,
`log_exception`, as instance methods and on the module itself. Each writes to the Rails log and to the
configured log and exception classes (`log_to_io:` and `log_to_db:` switch either off); a failing database
write is logged, not raised

### Configuration

Set in the application's `config/initializers/bp3-core.rb`; the class names are constantized and cached on
first use:
- `Bp3::Core::Rqid.global_request_state_class_name` (`'GlobalRequestState'`) and
  `.global_request_state_method` (`:request_id`)
- `Bp3::Core::SystemLogs.system_log_name` (`'System::Log'`) and `.system_exception_name`
  (`'System::Exception'`)
- `Bp3::Core::Ransackable.attribute_exceptions` and `.association_exceptions`

The concerns also name application classes directly: `Sites::Site`, `Tenant`, `Workspaces::Workspace`,
`Users::Visitor`, `Inbound::Request`, `Inbound::UserAgent`, `Feature::Enabler`, `UserContext`,
`DomainExtractor`.

### Dependencies

- `activesupport ~> 8.1`, `actionview ~> 8.1`
- `bp3-request_state ~> 0.1` - `Bp3::RequestState::Base`, the parent of the application's request state

## Code Style

- RuboCop (`.rubocop.yml`): target Ruby 3.2.2, NewCops, rubocop-rake and rubocop-rspec; AbcSize 26,
  MethodLength 15, ModuleLength 150, BlockLength 66, Cyclomatic/PerceivedComplexity 10; RSpec ExampleLength
  10, MultipleExpectations 4; Style/Documentation off
- Every file starts with `# frozen_string_literal: true`
- American English; no trailing whitespace on any added or modified line

## Release

Bump `lib/bp3/core/version.rb` and add a `CHANGELOG.md` entry. `rake release` tags, pushes and publishes to
rubygems.org; leave releasing and committing to the user.
