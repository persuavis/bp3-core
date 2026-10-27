## [Unreleased]

- Breaking: Tenantable default scopes reach as far as the primary login, the request state's
  `current_login` (the least privileged one signed in), rather than as far as any root or admin signed
  in. A root signed in beside a user or an admin no longer reaches every site, and an admin signed in
  beside a user no longer reaches every tenant; with one login signed in, nothing changes
- Breaking: Tenantable reads the request state through `Bp3::Core::Rqid.global_request_state_class`
  rather than a `GlobalRequestState` constant, so `Bp3::Core::Rqid.global_request_state_class_name`
  must be configured wherever Tenantable is used
- Add `Bp3::Core::Tenantable.reaches_every_site?`, `.reaches_every_tenant?` and `.global_request_state`
- Fix `efon?` and `cfon?` returning the default when the flag is explicitly off; `cfon` returns the
  default when the config is not set

## [0.2.0] - 2026-01-09

- Add bp3-request_state dependency
- Add SystemLogs concern
- Update gems
- Update ruby version to 3.4.6

## [0.1.5] - 2024-11-18

- Use ruby 3.3.5 and relax gem constraints

## [0.1.3] - 2024-07-31

- Ensure use of common global request state

## [0.1.2] - 2024-05-30

- Explicit require active_support/parameter_filter

## [0.1.1] - 2024-05-30

- Tweaks and documentation

## [0.1.0] - 2023-12-19

- Initial release
