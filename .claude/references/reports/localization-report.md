# Localization Report Template

Written to `.temp/tasks/<task_name>/localization.md`.

```markdown
# Localization Report: <task-name>

**Date:** <date>
**Analyzed:** <number> files

## Must Modify
| File | Phase(s) | Reason |
|------|----------|--------|
| src/auth/login.ts | 1, 2 | Core authentication logic |
| src/api/users.ts | 2 | Add new endpoints |

## Might Modify
| File | Risk | Reason |
|------|------|--------|
| src/utils/validation.ts | MEDIUM | Used by auth module |
| src/config/constants.ts | LOW | May need new constants |

## Protected
| File | Reason |
|------|--------|
| package-lock.json | Lock file |
| node_modules/* | Third-party |

## Dependency Graph
```
src/auth/login.ts
├── src/utils/validation.ts (might modify)
├── src/config/constants.ts (might modify)
└── src/api/users.ts (must modify)
```

## Conflict Analysis
| File | Phases | Handoff Required |
|------|--------|-----------------|
| src/auth/login.ts | 1, 2 | YES - sequential with handoff |

## Recommendations
- Phase 1 and 2 should run sequentially (shared files)
- Consider splitting src/auth/login.ts changes to avoid conflicts
```
