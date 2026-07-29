# AI Development Workflow

This repository follows Context Engineering.

AI MUST understand the project context before making any implementation decisions.

Never skip the required reading process.

---

# Required Reading Order

Before making any changes, AI MUST read the following documents in order:

1. docs/architecture.md
2. docs/modules.md
3. docs/design.md
4. docs/database.md (only if data is involved)

Do NOT begin implementation until sufficient context has been gathered.

---

# AI Workflow

Every task follows this workflow.

Requirements
    ↓
Planning
    ↓
Context Validation
    ↓
Implementation
    ↓
Self Review
    ↓
Completion

Never skip any stage.

---

# Stage 1 — Planning

Before writing code, AI must determine:

- What feature is being modified?
- Which module does it belong to?
- Which existing files are affected?
- Can existing components be reused?
- Are database changes required?
- Are API changes required?
- Does the requested feature already exist?

If information is missing, ask for clarification instead of making assumptions.

Never start coding immediately.

---

# Stage 2 — Context Validation

Before creating anything new, AI must search the existing project.

Search for:

- Existing screens
- Existing widgets
- Existing models
- Existing repositories
- Existing services
- Existing providers/state management
- Existing utilities

Reuse existing implementations whenever possible.

Creating duplicate functionality is considered a failure.

---

# Stage 3 — Implementation

When implementing features:

Follow the project architecture exactly.

Respect the folder structure.

Follow the coding standards defined in docs/design.md.

Use existing design patterns.

Do not introduce a new architecture.

Do not introduce a different state management solution.

Do not introduce unnecessary dependencies.

---

# Stage 4 — Self Review

Before finishing, AI must review its own work.

Checklist:

□ Existing components reused

□ No duplicated code

□ Naming follows conventions

□ Business logic separated from UI

□ Responsive layout maintained

□ Error handling implemented

□ Loading state implemented

□ Empty state implemented

□ Null safety respected

□ Theme used instead of hardcoded values

□ No dead code

□ No unnecessary files

If any item fails, improve the implementation before responding.

---

# Development Principles

## Reuse First

Always extend existing code before creating new code.

Priority:

Reuse
→ Extend
→ Create

Creating duplicate files is discouraged.

---

## Keep Changes Small

Modify the minimum number of files necessary.

Avoid large refactors unless explicitly requested.

---

## Consistency Over Creativity

Match the existing coding style.

Do not invent a new coding style.

Do not rename existing structures unless required.

Consistency is more important than personal preference.

---

## Production Ready

Every implementation should be suitable for production.

Avoid placeholder implementations.

Avoid TODO comments unless requested.

Avoid mock logic unless requested.

---

# Flutter Guidelines

AI should:

- Build reusable widgets
- Keep widgets focused on a single responsibility
- Separate UI from business logic
- Use asynchronous operations safely
- Use const constructors whenever possible
- Respect responsive layouts
- Minimize unnecessary widget rebuilds
- Follow the project's state management approach
- Use repository/service layers for data access

---

# What AI Must NOT Do

AI must NOT:

- Create duplicate widgets
- Create duplicate services
- Create duplicate repositories
- Create duplicate models
- Ignore existing architecture
- Hardcode colors
- Hardcode strings
- Mix UI with business logic
- Call APIs directly from UI unless architecture allows it
- Create utility classes without checking existing utilities
- Introduce new dependencies without justification
- Modify unrelated files
- Refactor unrelated code
- Guess requirements

---

# File Creation Rules

Before creating a new file, AI must verify:

1. A similar file does not already exist.
2. The file is necessary.
3. Existing code cannot be extended instead.

Only then should a new file be created.

---

# Documentation Awareness

AI should use the project documentation continuously.

architecture.md
→ Source of architectural truth.

modules.md
→ Source of feature behavior.

design.md
→ Source of coding standards.

database.md
→ Source of data relationships.

If implementation conflicts with documentation, documentation takes priority.

---

# Reviewer Mindset

Before completing a task, AI should ask:

"Would another developer immediately understand this implementation?"

If the answer is no, simplify it.

---

# Success Criteria

A task is complete only when:

✓ Architecture is respected

✓ Existing code is reused

✓ Documentation is followed

✓ No unnecessary complexity is introduced

✓ Code is maintainable

✓ Code is readable

✓ Code is production ready

# Quality Gate

✓ Read all relevant docs
        ↓
✓ Reused existing code
        ↓
✓ Followed architecture
        ↓
✓ Followed coding standards
        ↓
✓ Kept changes minimal
        ↓
✓ Self-reviewed implementation
        ↓
✓ Ready for production