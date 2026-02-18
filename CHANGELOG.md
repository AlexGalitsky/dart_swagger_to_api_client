## 1.1.0

### Added
- **Multiple content types support for requestBody**: Added support for multiple content types in requestBody with automatic priority-based selection
  - Support for `text/plain` content type (body type: `String`)
  - Support for `text/html` content type (body type: `String`)
  - Support for `application/xml` content type (body type: `String` for simple types, `Map<String, dynamic>` for complex types)
  - Support for custom content types (fallback to `String` or `Map<String, dynamic>`)
  - Priority order for content type selection: `multipart/form-data` > `application/x-www-form-urlencoded` > `application/json` > `text/plain` > `text/html` > `application/xml` > others

### Changed
- Improved requestBody type resolution to handle multiple content types correctly
- Enhanced body serialization logic to support text and XML content types

## 1.0.0

- Initial version.
