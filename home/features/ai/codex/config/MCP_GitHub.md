# GitHub MCP Server

**Purpose**: GitHub repository and workflow management via MCP

## Triggers
- Repository operations: creating PRs, managing issues, reviewing code
- Workflow automation: GitHub Actions, CI/CD integration
- Code collaboration: PR reviews, issue tracking, project management
- Repository management: branch operations, releases, tags

## Choose When
- **Over manual git commands**: When you need GitHub-specific features (PRs, issues, workflows)
- **For collaboration**: PR creation, issue management, code reviews
- **For automation**: GitHub Actions, workflow management
- **For project management**: Milestones, projects, discussions

## Works Best With
- **DevOps Architect**: GitHub Actions and CI/CD workflows
- **Technical Writer**: Documentation and PR descriptions
- **Requirements Analyst**: Issue tracking and project management

## Key Capabilities

### Repository Operations
- Create and manage pull requests
- View and manage issues
- Create and manage releases
- Branch and tag operations
- Repository metadata access

### Workflow Management
- GitHub Actions workflow management
- CI/CD pipeline operations
- Workflow run monitoring
- Secret management (with proper permissions)

### Code Collaboration
- PR reviews and comments
- Code search across repositories
- File content access
- Commit history and diffs

## Examples

```
"Create a draft PR for the current branch"
→ GitHub MCP: Create draft PR with current changes

"List open issues in this repository"
→ GitHub MCP: Query issues with filters

"Show me the GitHub Actions workflow for CI"
→ GitHub MCP: Read workflow file and show status

"Create an issue for this bug"
→ GitHub MCP: Create issue with description and labels
```

## Environment Variables

- `GITHUB_PERSONAL_ACCESS_TOKEN`: Required for authentication
- `GITHUB_DYNAMIC_TOOLSETS`: Enable dynamic toolset features (set to "1")

## Best Practices

1. **Use for GitHub-specific features**: PRs, issues, workflows
2. **Respect permissions**: Only request necessary scopes
3. **Use draft PRs**: Create drafts first, then convert to ready
4. **Leverage automation**: Use GitHub Actions for repetitive tasks
5. **Document changes**: Include clear PR descriptions and commit messages


