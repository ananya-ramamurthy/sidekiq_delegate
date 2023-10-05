## [5.0.0]

- Beginning of the rails version specific support.

## [0.2.0]

### Added 

- Full rspec coverage

### Changed

- Modified Method::WithArgs module to support splatted arguments, and privatized what should be non-public methods
- Modified SidekiqDelegate::Job#perform_bulk to allow for yield to return nil or an array of Method::WithArgs, adding flexibility when bulk enqueueing using the "single loop" functionality.
- Removed unnecessary complexity in SidekiqDelegate::Validator by consolidating the validation into a single (non-redundant) method: validate_delegate!
- Modified sidekiq gem version reqs. to allow for broader range of versions.

## [0.1.2]

- Require sidekiq pro as dependency to avoid load race condition

## [0.1.0] - 2022-12-15

- Initial release

## [Unreleased]