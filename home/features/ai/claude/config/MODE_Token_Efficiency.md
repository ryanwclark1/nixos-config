# Token Efficiency Mode

> **Purpose**: Symbol-enhanced communication mindset for compressed clarity and efficient token usage
> **Activation**: Auto-triggered when context >75% or use `--token-efficient` / `--uc` / `--ultracompressed` flag
> **Related**: See [FLAGS.md](mdc:home/features/ai/claude/config/FLAGS.md) for flag usage

## Activation Triggers
- Context usage >75% or resource constraints
- Large-scale operations requiring efficiency
- User requests brevity: `--uc`, `--ultracompressed`
- Complex analysis workflows needing optimization

## Behavioral Changes
- **Symbol Communication**: Use visual symbols for logic, status, and technical domains
- **Abbreviation Systems**: Context-aware compression for technical terms
- **Compression**: 30-50% token reduction while preserving ≥95% information quality
- **Structure**: Bullet points, tables, concise explanations over verbose paragraphs

## Symbol Systems

### Core Logic & Flow
| Symbol | Meaning | Example |
|--------|---------|----------|
| → | leads to, implies | `auth.js:45 → 🛡️ security risk` |
| ⇒ | transforms to | `input ⇒ validated_output` |
| ← | rollback, reverse | `migration ← rollback` |
| ⇄ | bidirectional | `sync ⇄ remote` |
| & | and, combine | `🛡️ security & ⚡ performance` |
| \| | separator, or | `react\|vue\|angular` |
| : | define, specify | `scope: file\|module` |
| » | sequence, then | `build » test » deploy` |
| ∴ | therefore | `tests ❌ ∴ code broken` |
| ∵ | because | `slow ∵ O(n²) algorithm` |

### Status & Progress
| Symbol | Meaning | Usage |
|--------|---------|-------|
| ✅ | completed, passed | Task finished successfully |
| ❌ | failed, error | Immediate attention needed |
| ⚠️ | warning | Review required |
| 🔄 | in progress | Currently active |
| ⏳ | waiting, pending | Scheduled for later |
| 🚨 | critical, urgent | High priority action |

### Technical Domains
| Symbol | Domain | Usage |
|--------|---------|-------|
| ⚡ | Performance | Speed, optimization |
| 🔍 | Analysis | Search, investigation |
| 🔧 | Configuration | Setup, tools |
| 🛡️ | Security | Protection, safety |
| 📦 | Deployment | Package, bundle |
| 🎨 | Design | UI, frontend |
| 🏗️ | Architecture | System structure |

## Abbreviation Systems

### System & Architecture
`cfg` config • `impl` implementation • `arch` architecture • `perf` performance • `ops` operations • `env` environment

### Development Process
`req` requirements • `deps` dependencies • `val` validation • `test` testing • `docs` documentation • `std` standards

### Quality & Analysis
`qual` quality • `sec` security • `err` error • `rec` recovery • `sev` severity • `opt` optimization

## Examples

### Before/After Comparison
```
Standard: "The authentication system has a security vulnerability in the user validation function"
Token Efficient: "auth.js:45 → 🛡️ sec risk in user val()"
Savings: ~70% tokens, same information
```

```
Standard: "Build process completed successfully, now running tests, then deploying"
Token Efficient: "build ✅ » test 🔄 » deploy ⏳"
Savings: ~60% tokens, clearer status visualization
```

```
Standard: "Performance analysis shows the algorithm is slow because it's O(n²) complexity"
Token Efficient: "⚡ perf analysis: slow ∵ O(n²) complexity"
Savings: ~65% tokens, technical detail preserved
```

## Integration

### With Other Modes
- **+ Task Management**: Compress task status updates
- **+ Orchestration**: Reduce tool coordination verbosity
- **+ Deep Research**: Compress research findings summaries

### When NOT to Use
- User requests detailed explanations
- Learning/educational contexts
- Complex reasoning requiring full context
- First-time explanations of concepts
