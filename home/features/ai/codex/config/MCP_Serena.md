# Serena MCP Server

**Purpose**: Semantic code understanding with project memory and session persistence

## Triggers
- Symbol operations: rename, extract, move functions/classes
- Project-wide code navigation and exploration
- Multi-language projects requiring LSP integration
- Large codebase analysis (>50 files, complex architecture)
- Code understanding and semantic search

## Choose When
- **For semantic understanding**: Symbol references, dependency tracking, LSP integration
- **For large projects**: Multi-language codebases requiring architectural understanding
- **For code navigation**: Finding usages, understanding dependencies, exploring codebase
- **Not for simple edits**: Basic text replacements, style enforcement, bulk operations

## Works Best With
- **Sequential**: Serena provides project context → Sequential performs architectural analysis
- **Context7**: Serena identifies patterns → Context7 provides official documentation
- **Sourcebot**: Serena understands structure → Sourcebot finds similar implementations

## Examples
```
"rename getUserData function everywhere" → Serena (symbol operation with dependency tracking)
"find all references to this class" → Serena (semantic search and navigation)
"understand the architecture of this project" → Serena (codebase analysis)
"extract this function to a separate module" → Serena (semantic refactoring)
"update all console.log to logger" → Native Codex (pattern-based replacement)
"create a login form" → Native Codex (UI component generation)
```


