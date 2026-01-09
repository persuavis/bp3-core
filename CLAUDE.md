# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bp3-core is a Ruby gem providing core ActiveSupport concerns for BP3 (persuavis/black_phoebe_3), a multi-site multi-tenant Rails application. The gem provides reusable modules that handle common patterns like tenancy, feature flags, ransack integration, request tracking, and sequence numbering.

## Common Commands

### Testing and Linting
- Run tests: `bundle exec rspec` or `rake spec`
- Run linting: `bundle exec rubocop` or `rake rubocop`
- Run both tests and linting (default): `rake`
- Run a single test file: `bundle exec rspec spec/path/to/file_spec.rb`
- Run a specific test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`

### Development
- Install dependencies: `bundle install`
- Interactive console: `bin/console`
- Install gem locally: `rake install`
- Generate documentation: `yard doc`

### Release
- Update version in `lib/bp3/core/version.rb`
- Run `rake release` to create git tag, push commits/tags, and publish to rubygems.org

## Architecture

### Core Concerns

The gem provides several ActiveSupport::Concern modules that are included in ActiveRecord models and controllers:

**Tenantable** (`lib/bp3/core/tenantable.rb`)
- Handles multi-tenant architecture with sites, tenants, and workspaces
- Automatically sets foreign keys from GlobalRequestState
- Creates associations: `sites_site_id` → Sites::Site, `tenant_id` → Tenant, `workspaces_workspace_id` → Workspaces::Workspace
- Provides aliases: `site`/`site=`, `workspace`/`workspace=`
- Implements default scopes based on current site/tenant context
- Validates tenant and workspace belong to correct site
- Uses reflection to determine which columns exist and only creates relevant associations
- GlobalRequestState is expected to be defined in the consuming application

**Ransackable** (`lib/bp3/core/ransackable.rb`)
- Provides ransack integration for searchable/sortable models
- Implements `ransackable_attributes`, `ransackable_associations`, `ransackable_scopes`
- Uses global configuration for exceptions: `Bp3::Core::Ransackable.attribute_exceptions` and `Bp3::Core::Ransackable.association_exceptions`
- Must be configured in `config/initializers/bp3-core.rb` in consuming application

**Rqid** (`lib/bp3/core/rqid.rb`)
- Tracks request ID (rqid) for all records
- Automatically sets rqid on record creation from GlobalRequestState
- Creates associations to original request, response, and visit records
- Requires configuration of `Bp3::Core::Rqid.global_request_state_class_name` and `Bp3::Core::Rqid.global_request_state_method`

**Sqnr** (`lib/bp3/core/sqnr.rb`)
- Provides sequence number (sqnr) ordering
- Adds `sqnr` (ascending) and `rnqs` (descending) scopes
- Class macro `use_sqnr_for_ordering` sets `implicit_order_column` to sqnr

**Actions**, **Cookies**, **Displayable**, **FeatureFlags**, **Settings**, **SystemLogs**
- Additional concerns for controllers and models
- See README.md for usage patterns

### Module Organization

The gem follows standard Ruby gem structure:
- `lib/bp3-core.rb` - Main entry point, requires `lib/bp3/core.rb`
- `lib/bp3/core.rb` - Requires all concern modules, defines `Bp3::Core` namespace
- `lib/bp3/core/*.rb` - Individual concern modules
- Module attributes use `mattr_accessor` for configuration points that must be set by consuming applications

### Configuration Pattern

Concerns that need application-specific configuration use `mattr_accessor` and class methods:
- `Bp3::Core.system_exception_name` / `.system_log_name`
- `Bp3::Core::Ransackable.attribute_exceptions` / `.association_exceptions`
- `Bp3::Core::Rqid.global_request_state_class_name` / `.global_request_state_method`

These are set in the consuming application's `config/initializers/bp3-core.rb`.

### Dependencies

The gem depends on:
- `activesupport ~> 8.1` - For ActiveSupport::Concern and core extensions
- `actionview ~> 8.1` - For view helpers
- Development: `rspec`, `rubocop`, `rubocop-rake`, `rubocop-rspec`

## Code Style

RuboCop configuration (`.rubocop.yml`):
- Target Ruby version: 3.2.2
- Custom metrics: AbcSize max 26, MethodLength max 15, ModuleLength max 150
- RSpec: ExampleLength max 10, MultipleExpectations max 4
- Style/Documentation disabled
- Uses `rubocop-rake` and `rubocop-rspec` plugins

All files use `# frozen_string_literal: true`.
