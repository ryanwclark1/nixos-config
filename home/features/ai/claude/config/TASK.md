# Task Management

> **Purpose**: Current tasks, priorities, and backlog for this NixOS configuration project.
> **Read**: Daily before starting work, update as tasks progress

## Active Tasks (In Progress)

### 🔄 Current Session
- **Migrate SuperClaude Settings** (Branch: `claude/migrate-superclause-settings-011CUy8uVwUk1LmG1DSA5yj7`)
  - [ ] Create essential documentation files (PLANNING, TASK, KNOWLEDGE, CONTRIBUTING)
  - [ ] Activate high-priority agents from backup
  - [ ] Update default.nix configuration
  - [ ] Test and validate changes

## High Priority (Next Up)

### System Configuration
- [ ] Review and optimize system package selections
- [ ] Audit enabled services for unused components
- [ ] Optimize boot time (analyze systemd-analyze)

### AI Tooling Enhancement
- [ ] Validate all MCP server configurations
- [ ] Test agent routing and activation
- [ ] Create custom /sc: commands for common NixOS tasks
- [ ] Document AI workflow patterns in KNOWLEDGE.md

### Secrets Management
- [ ] Audit all SOPS secrets for necessity
- [ ] Implement secret rotation strategy
- [ ] Document secret access patterns

## Medium Priority (Backlog)

### Home Manager Refinements
- [ ] Consolidate duplicate shell configurations
- [ ] Optimize zsh/bash startup time
- [ ] Review and prune unused dotfiles

### Development Environment
- [ ] Create development shell templates for common stacks
- [ ] Add project-specific direnv configurations
- [ ] Document development workflow in CONTRIBUTING.md

### Documentation
- [ ] Create README for each major feature module
- [ ] Document the flake structure and design decisions
- [ ] Add troubleshooting guide to KNOWLEDGE.md

## Low Priority (Nice to Have)

### Quality of Life
- [ ] Add automated backup verification
- [ ] Create system health monitoring dashboard
- [ ] Implement configuration drift detection

### Exploration
- [ ] Research impermanence patterns (tmpfs root)
- [ ] Evaluate NixOS containers for isolated services
- [ ] Investigate declarative GNOME/KDE theming

## Completed Tasks ✅

### Recent Completions
- ✅ Added Omarchy-inspired keybindings and utilities (PR #34)
- ✅ Fixed SUPER+K keybinding conflict
- ✅ Added battery and time notification utilities
- ✅ Refactored shebang lines for better portability
- ✅ Set up SOPS-nix for secrets management
- ✅ Configured Claude Code with custom agents and commands
- ✅ Established MCP server integrations

## Deferred / On Hold

### Waiting for Decisions
- Review NixOS vs Home Manager boundaries for certain tools
- Decide on monitoring solution (Prometheus, netdata, etc.)
- Choose desktop environment direction (GNOME, Hyprland, etc.)

### Blocked
- *No currently blocked tasks*

## Task Categories & Labels

### By Type
- **System**: NixOS system-level configurations
- **Home**: Home Manager user-level configurations
- **AI**: Claude Code, MCP servers, agents, commands
- **Secrets**: SOPS and credential management
- **Docs**: Documentation and knowledge base
- **DevExp**: Developer experience improvements

### By Complexity
- **Simple**: < 30 min, straightforward implementation
- **Medium**: 30 min - 2 hours, requires research/planning
- **Complex**: > 2 hours, multiple components affected

### By Risk
- **Low**: User-level changes, easily reversible
- **Medium**: System changes, needs testing
- **High**: Boot/filesystem/secrets, needs careful validation

## Task Workflow

### Adding New Tasks
1. Identify task type and priority
2. Add to appropriate section (High/Medium/Low)
3. Add complexity and risk labels
4. Link to related issues/PRs if applicable

### Working on Tasks
1. Move task to "Active Tasks (In Progress)"
2. Create feature branch: `claude/{task-name}-{session-id}`
3. Update task with checkboxes for subtasks
4. Mark complete when done and tested

### Completing Tasks
1. Move to "Completed Tasks" with date
2. Archive monthly to keep list manageable
3. Document learnings in KNOWLEDGE.md

## Sprint Planning (Optional)

### Week of [Current Week]
- **Goal**: Enhance AI tooling and documentation
- **Tasks**: Complete SuperClaude migration, validate configurations
- **Success Metrics**: All agents working, documentation complete

### Next Week
- **Goal**: System optimization and cleanup
- **Tasks**: Service audit, boot time optimization
- **Success Metrics**: Faster boot, reduced service count

## Notes & Reminders

### Development Notes
- Always test changes locally before committing
- Keep commits atomic and well-described
- Update flake.lock in separate commits from features

### Configuration Notes
- Secrets require SOPS decryption service active
- MCP servers need API keys from SOPS secrets
- Claude Code agents auto-activate based on context

### Maintenance Schedule
- **Weekly**: Review active tasks, plan next week
- **Monthly**: Archive completed tasks, update priorities
- **Quarterly**: Major dependency updates, security audit
