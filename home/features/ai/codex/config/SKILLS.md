# Codex Skills System

**Purpose**: Share prompts and workflows across teams with advanced capabilities

## What Are Skills?

Skills are more advanced than custom prompts. They can:
- Access external APIs and tools
- Be shared and versioned across teams
- Include complex logic and workflows
- Integrate with third-party services

## Installing Skills

Use `$skill-installer` to install skills:

```
$skill-installer install <skill-name>
```

### Example Installations

```bash
# Install create-plan skill
$skill-installer install create-plan

# Install Linear integration skill
$skill-installer install linear

# Install Notion spec-to-implementation skill
$skill-installer install notion-spec-to-implementation
```

## Available Skills

### create-plan
**Purpose**: Create structured project plans

**Usage**: Helps break down projects into actionable tasks with dependencies and timelines.

**Example**:
```
Use create-plan skill to plan the new authentication system
```

### linear
**Purpose**: Integrate with Linear for issue tracking

**Usage**: Create Linear issues, manage workflows, track progress.

**Example**:
```
Use linear skill to create an issue for the bug we just fixed
```

### notion-spec-to-implementation
**Purpose**: Convert Notion specifications to code

**Usage**: Takes Notion pages with specifications and generates implementation code.

**Example**:
```
Use notion-spec-to-implementation skill to implement the feature from the Notion spec
```

## Skills vs Custom Prompts

| Feature | Custom Prompts | Skills |
|---------|---------------|--------|
| **Location** | `~/.codex/prompts/` | Installed via `$skill-installer` |
| **Complexity** | Simple markdown with placeholders | Can include logic and API access |
| **Sharing** | Manual file sharing | Versioned and shareable |
| **Installation** | Copy files | `$skill-installer install` |
| **Updates** | Manual | Can be updated via installer |

## When to Use Skills

- **Team workflows**: When you need to share prompts across a team
- **External integrations**: When you need to access APIs or external services
- **Complex logic**: When prompts need conditional logic or state
- **Versioning**: When you need to track versions and updates

## When to Use Custom Prompts

- **Personal workflows**: Quick, reusable prompts for your own use
- **Simple tasks**: Straightforward prompts without complex logic
- **Quick iteration**: Easy to modify and test locally
- **Project-specific**: Prompts specific to a single project

## Finding Skills

Skills are typically shared through:
- Team repositories
- Skill registries
- Community collections
- Internal skill stores

## Best Practices

1. **Start with custom prompts**: Use custom prompts for simple, personal workflows
2. **Upgrade to skills**: Convert to skills when you need sharing or complex logic
3. **Document skills**: Document what each skill does and when to use it
4. **Version skills**: Keep skills updated and versioned
5. **Test skills**: Test skills before sharing with team

## Creating Your Own Skills

Skills can be created by:
- Defining skill structure and capabilities
- Packaging for distribution
- Publishing to skill registry
- Installing via `$skill-installer`

For more information on creating skills, see the Codex Skills documentation.

