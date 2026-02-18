# CI/CD Templates for API Client Regeneration

This directory contains CI/CD templates for automatically regenerating the API client when the OpenAPI specification changes.

## Available Templates

### GitHub Actions

1. **`.github/workflows/regenerate-client.yml`**
   - Triggers on changes to spec files in `swagger/`, `openapi/`, or `api/` directories
   - Automatically commits changes or creates a PR
   - Can be triggered manually via `workflow_dispatch`

2. **`.github/workflows/regenerate-client-on-schedule.yml`**
   - Runs on a schedule (daily at 2 AM UTC)
   - Checks if spec has changed before regenerating
   - Useful for keeping client in sync with remote API

3. **`.github/workflows/regenerate-client-from-url.yml`**
   - Downloads OpenAPI spec from a remote URL
   - Runs on schedule (every 6 hours) or manually
   - Useful when spec is hosted externally

### GitLab CI

**`.gitlab-ci.yml`**
- Regenerates client when spec files change
- Supports scheduled regeneration
- Automatically commits changes back to the repository

## Setup Instructions

### GitHub Actions

1. Copy the workflow files to `.github/workflows/` in your repository:
   ```bash
   mkdir -p .github/workflows
   cp .github/workflows/regenerate-client.yml .github/workflows/
   ```

2. Adjust the paths in the workflow file:
   - Update `--input` path to match your spec location
   - Update `--output-dir` paths if needed
   - Update `--config` path if using a custom config file

3. Ensure your repository has the necessary permissions:
   - Go to Settings → Actions → General
   - Enable "Read and write permissions" for workflows
   - Enable "Allow GitHub Actions to create and approve pull requests"

4. (Optional) For remote spec workflows:
   - Update the spec URL in the workflow file
   - Or use workflow inputs to specify the URL

### GitLab CI

1. Copy `.gitlab-ci.yml` to your repository root:
   ```bash
   cp .gitlab-ci.yml ./
   ```

2. Adjust the configuration:
   - Update paths to match your project structure
   - Update the Docker image version if needed
   - Configure branch names (main/master)

3. Ensure CI/CD variables are set:
   - No special variables required for basic setup
   - For private repositories, ensure CI/CD has access

## Customization

### Changing Trigger Paths

In GitHub Actions, modify the `paths` section:
```yaml
on:
  push:
    paths:
      - 'your-spec-dir/**'
      - 'another-dir/**'
```

In GitLab CI, modify the `only.changes` section:
```yaml
only:
  changes:
    - 'your-spec-dir/**/*'
```

### Changing Output Directories

Update the `--output-dir` flags in the generation commands:
```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir your/models/path

dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir your/client/path
```

### Using Environment-Specific Configs

You can use the `--env` flag to generate clients for different environments:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### Skipping CI on Regeneration Commits

The workflows use `[skip ci]` in commit messages to prevent infinite loops. If your CI system doesn't recognize this, you may need to:

1. Configure your CI to skip commits with `[skip ci]`
2. Or remove the `[skip ci]` tag from commit messages

## Best Practices

1. **Review Generated Code**: Always review generated code before merging, especially after major spec changes.

2. **Test After Regeneration**: Run your test suite after regeneration to ensure compatibility.

3. **Use Pull Requests**: Configure workflows to create PRs instead of direct commits for better review process.

4. **Monitor Scheduled Jobs**: Keep an eye on scheduled regeneration jobs to catch issues early.

5. **Version Control Specs**: Keep your OpenAPI specs in version control for reproducibility.

6. **Separate Environments**: Consider generating separate clients for dev/staging/prod if needed.

## Troubleshooting

### Workflow doesn't trigger

- Check that spec files are in the watched directories
- Verify file paths match the `paths` configuration
- Ensure workflow file is in `.github/workflows/` directory

### Permission errors

- Check repository settings for workflow permissions
- Ensure the GITHUB_TOKEN has write access
- For GitLab, check CI/CD settings

### Generation fails

- Check that all dependencies are installed
- Verify the OpenAPI spec is valid
- Check workflow logs for detailed error messages

### Changes not committed

- Verify git user is configured in the workflow
- Check that files are actually being generated
- Ensure the workflow has write permissions

## Examples

See the workflow files in `.github/workflows/` for complete examples with comments explaining each step.
