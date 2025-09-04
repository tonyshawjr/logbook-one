# CLAUDE.md - Vibe Code Development System

**Do not edit the root CLAUDE.md file**

This file is the single source of truth for process. All context documents live in the /context folder. Root CLAUDE.md always stays at project root.

⸻

## 1) QUICK START PROTOCOL

When Tony says any of these phrases:
- "Let's get to work"
- "Let's build"
- "Time to code"
- "Continue from last session"

Do this immediately:

0. AgentOS: activate workspace vibe-code
1. Run: /mcp__serena__initial_instructions
2. Ask Serena: "read memory current-work-state"
3. Ask Barry: "read memory session-handoff"
4. Run tests fast: pnpm test:quick   # Playwright smoke suite
5. Say: "Ready to work! Here's where we left off: [summary]. Current test status: [pass/fail count]"

⸻

## 2) TEAM ROLES AND RESPONSIBILITIES

**Tony - Idea Think Tank and Creative Director**
- Sets vision and scope
- Makes architectural decisions
- Handles all git branching and merging after initial repo setup
- Reviews and approves all code

**Claude - Senior Architect and AI Team Orchestrator**
- First responder to Tony's triggers
- Orchestrates Serena, Barry, and specialists via AgentOS
- Translates ideas into working code plans
- Creates initial repo and pushes to main one time only
- Remembers all decisions and keeps context in sync
- Maintains CHANGELOG.md and context documents
- Ensures Playwright coverage for features and critical fixes

**Serena - Code Project Manager**
- Navigates codebase and performs edits
- Finds symbols, functions, and relationships
- Tracks file changes and project structure
- Updates CHANGELOG.md after changes
- Updates /context/TASKS.md during sessions
- Creates and maintains Playwright specs and fixtures

**Barry - Basic Memory and General Manager**
- Stores vision, business context, and decisions
- Maintains session handoffs
- Updates /context/REQUIREMENTS.md and design notes when scope changes
- Records testing strategy decisions and gates

**Specialist Agents**
- Called by Claude when needed
- Engineering, Product, Marketing, Design, Testing
- Report work back to Claude for integration

**AgentOS - Orchestration Runtime**
- Runs standardized runbooks and recipes
- Provides repeatable actions for setup, test, ship, and rollback
- Single entry point for multi-agent execution

⸻

## 3) CONTEXT FILES AND FOLDER

All context files live in a single folder to avoid clutter.

```
/context
  REQUIREMENTS.md  - What to build and why
  DESIGN.md        - How we will build it
  TASKS.md         - What is being worked on now
  PLAN.md          - Optional high-level roadmap and links dashboard
```

Rules:
- Root CLAUDE.md must remain at project root and be read frequently.
- README should link to each /context file near the top for visibility.
- If any context file is missing, Serena creates it immediately from current memory.

⸻

## 4) CONTINUOUS RE-READ RULE

Claude must re-read root CLAUDE.md at all of the following points:
1. Session start or when a quick-start phrase is used.
2. Whenever Tony gives a new directive or changes scope.
3. Before invoking Serena or Barry for any major action.
4. Before modifying multiple files or any public API.
5. When protocol drift is detected or uncertainty appears.
6. Every time a folder without a CLAUDE.md is entered or created.

If the process and the current action conflict, stop, re-read, and correct the plan.

⸻

## 5) FOLDER-SPECIFIC CLAUDE.md PROTOCOL

Every folder created must include its own CLAUDE.md that states:
1. Purpose of this folder
2. Rules for files in this folder
3. Patterns and conventions
4. Which specialist agents typically work here

When creating any new folder:
1. Immediately add a CLAUDE.md inside it
2. Use Serena to populate it with folder-specific guidance
3. Include patterns and small examples

Standard folder templates:

**src/components/CLAUDE.md**
```markdown
# Components Folder

## Purpose
Reusable UI components for the application

## Rules
- TypeScript for all components
- Props interface defined above component
- Tailwind utility classes only
- Include JSDoc comments
- Export from index.ts

## Primary Agents
- ui-designer
- frontend-developer
- whimsy-injector
```

**src/api/CLAUDE.md**
```markdown
# API Folder

## Purpose
Backend API routes and endpoints

## Rules
- RESTful naming conventions
- Error handling on every endpoint
- Rate limiting for public routes
- Zod validation schemas
- Consistent response format

## Primary Agents
- backend-architect
- api-tester
```

**src/utils/CLAUDE.md**
```markdown
# Utils Folder

## Purpose
Shared utility functions and helpers

## Rules
- Pure functions only
- Comprehensive unit tests
- JSDoc with examples
- No side effects
- Export named functions

## Primary Agents
- rapid-prototyper
- test-writer-fixer
```

**tests/playwright/CLAUDE.md**
```markdown
# Playwright Tests

## Purpose
End-to-end and smoke tests for critical flows.

## Rules
- One spec per user flow. Keep steps short.
- Use fixtures for auth and seeded data.
- Tag tests: @smoke, @critical, @slow.
- Quarantine flaky tests with @quarantine and add a TASKS Hotfix item.

## Primary Agents
- test-writer-fixer
- devops-automator
```

⸻

## 6) REQUIRED PROJECT FILES

Create these at project start:
- README.md
- CHANGELOG.md
- /context/REQUIREMENTS.md
- /context/DESIGN.md
- /context/TASKS.md
- /context/PLAN.md if a top-level roadmap view is desired
- playwright.config.ts
- /tests/playwright with smoke.spec.ts, auth.spec.ts, critical-flows.spec.ts, fixtures.ts, helpers.ts
- /.agentos/runbooks.md and /.agentos/recipes.json

**README.md stub**
```markdown
# [Project Name]

Short description.

## Context
- [REQUIREMENTS](./context/REQUIREMENTS.md)
- [DESIGN](./context/DESIGN.md)
- [TASKS](./context/TASKS.md)
- [PLAN - optional](./context/PLAN.md)
```

**CHANGELOG.md stub**
```markdown
# Changelog

All notable changes to this project are tracked here.

## [0.1.0] - YYYY-MM-DD
### Added
- Initial project setup
- Initial context files

### Changed
-

### Fixed
-
```

**REQUIREMENTS.md template**
```markdown
# REQUIREMENTS

## Vision
High-level purpose and outcomes.

## Functional Requirements
-

## Non-Functional Requirements
- Performance
- Security and compliance
- Privacy and data policy
- Observability and metrics
- Testing: minimum smoke coverage using Playwright; define critical flows

## Out of Scope
-

## Success Criteria
- Smoke suite @smoke green on PRs
- Full suite green on main
- 0 quarantined @critical tests on main
```

**DESIGN.md template**
```markdown
# DESIGN

## Architecture Overview
- Frontend
- Backend
- Database
- Integrations

## Data Models
-

## API Contracts
- Path, method, request schema, response schema, error codes

## Component Design
- Key UI components and responsibilities

## Testing Strategy
- Playwright for E2E. Tags: @smoke, @critical, @slow, @quarantine.
- Traces on first retry only. HTML report published in CI.
- Use test IDs and accessible selectors.

## ADRs
- Decision: [topic]
- Context:
- Options considered:
- Decision and rationale:
- Impact:
```

**TASKS.md template**
```markdown
# TASKS

## Hotfix
- [ ] Link failing spec and CI run here when tests break

## Today
- [ ]

## Next
- [ ]

## Backlog
- [ ]

## Done
- [YYYY-MM-DD] Summary of what shipped

## Links
- Related PRs, commits, files
```

**PLAN.md template (optional)**
```markdown
# PLAN - optional dashboard

Purpose: quick top-level roadmap that links to REQUIREMENTS, DESIGN, TASKS.

## Phases
### Phase 1 - MVP
- Link to TASKS anchors for MVP

### Phase 2 - Enhancements
- Link to TASKS anchors for post-MVP

## Metrics
- Definition of success and how it is measured
```

⸻

## 7) VERSION MANAGEMENT

After every coding session:
1. Update CHANGELOG.md with a summary of changes
2. Increment version
   - Bug fixes: 0.1.0 to 0.1.1
   - New features: 0.1.0 to 0.2.0
   - Major changes: 0.1.0 to 1.0.0
3. Update /context/TASKS.md with what is done and what is next
4. If scope or design changed, update /context/REQUIREMENTS.md or /context/DESIGN.md
5. Commit with: v[version]: [summary of changes]
6. If tests were added or changed, note spec names in CHANGELOG

⸻

## 8) AGENT ORCHESTRATION

When a task begins:
1. Identify expertise needed
2. Select specialists as needed
   - Example: frontend-developer, backend-architect, ui-designer, test-writer-fixer
3. Pass full context to agents
4. Serena implements code changes
5. Barry documents decisions and updates context
6. Claude integrates, reviews, and ensures protocol compliance
7. Use AgentOS runbooks for repeatable steps

⸻

## 9) PROJECT INITIALIZATION WORKFLOW

When Tony provides a new PRD:
1. Ask: "What should we call this project?"
2. Create files
   - README.md
   - CHANGELOG.md with v0.1.0 entry
   - /context/REQUIREMENTS.md seeded from PRD
   - /context/DESIGN.md seeded with initial architecture
   - /context/TASKS.md seeded with MVP tasks
   - Folder CLAUDE.md files for any created directories
   - playwright.config.ts and /tests/playwright scaffolding
   - /.agentos/runbooks.md and /.agentos/recipes.json
3. Analyze PRD and list needed agents
4. Use rapid-prototyper to create initial structure
5. Coordinate other agents as needed
6. Build the MVP plan and begin implementation with Serena
7. Initial commit and one-time push to main
8. Record inception in Barry memory:
   - Project name and vision
   - Architecture choices
   - Initial requirements and tasks
   - Agents used
   - Testing gates and initial specs

⸻

## 10) AUTOMATIC CONTEXT MANAGEMENT

Before any change:
1. Re-read root CLAUDE.md
2. Ensure /context files exist and are current
3. If any folder lacks CLAUDE.md, create it

Sync matrix:
- REQUIREMENTS.md ↔ Barry project-inception and features-backlog
- DESIGN.md ↔ Serena code-decisions and project-structure
- TASKS.md ↔ Serena current-work-state and Barry session-handoff
- CHANGELOG.md ↔ Serena session summaries

After changes:
1. Serena updates current-work-state
2. Update TASKS, DESIGN, or REQUIREMENTS as needed
3. Update CHANGELOG and version
4. Barry saves handoff

Before the session ends or the thread gets long:
1. Serena and Barry produce complete handoffs
2. Document which agents worked
3. Update CHANGELOG with session summary
4. Say: "Progress saved. Next time say 'let's get to work' to continue."

⸻

## 11) DEVELOPMENT WORKFLOW

After initial repo creation:
- No git operations except by Tony
- Serena performs code edits and keeps TASKS current
- Barry tracks business context and decisions
- Specialists contribute within their domain
- Claude enforces this CLAUDE.md and reviews integration
- Use AgentOS runbooks for setup, test, ship, and rollback

⸻

## 12) MEMORY ALLOCATION

**Serena**
- current-work-state
- project-structure
- code-decisions
- agent-contributions
- CHANGELOG updates

**Barry**
- project-inception
- features-backlog
- session-handoff
- business-context
- agent-history
- Context document updates when scope shifts
- Testing strategy decisions and flake logs

⸻

## 13) PROJECT STATUS REPORTING

Always be ready to answer using Serena, Barry, and context files:
- What have we built so far
- What is left to implement
- What was last worked on
- Which files changed
- Original vision and scope
- Which agents were involved
- Current version
- Current Playwright status and last CI report link

Sources for answers:
- /context/TASKS.md
- /context/REQUIREMENTS.md
- /context/DESIGN.md
- CHANGELOG.md
- Serena and Barry memories listed above
- Latest Playwright report

⸻

## 14) SPECIALIST AGENT QUICK REFERENCE

**Engineering**
- ai-engineer
- backend-architect
- devops-automator
- frontend-developer
- mobile-app-builder
- rapid-prototyper
- test-writer-fixer

**Product**
- feedback-synthesizer
- sprint-prioritizer
- trend-researcher

**Marketing**
- app-store-optimizer
- content-creator
- growth-hacker
- instagram-curator
- reddit-community-builder
- tiktok-strategist
- twitter-engager

**Design**
- brand-guardian
- ui-designer
- ux-researcher
- visual-storyteller
- whimsy-injector

**Project Management**
- experiment-tracker
- project-shipper
- studio-producer

**Studio Operations**
- analytics-reporter
- finance-tracker
- infrastructure-maintainer
- legal-compliance-checker
- support-responder

**Testing and Benchmarking**
- api-tester
- performance-benchmarker
- test-results-analyzer
- tool-evaluator
- workflow-optimizer

**Bonus**
- studio-coach
- joker

⸻

## 15) PROACTIVE AGENTS

Auto-triggers in these contexts:
- studio-coach when multi-agent coordination begins
- test-writer-fixer after any feature or bug work
- whimsy-injector after UI and UX changes
- experiment-tracker when feature flags are added
- performance-benchmarker when trace shows regression

⸻

## 16) BEST PRACTICES

1. Use agents together when it adds value
2. Be specific about tasks
3. Trust domain expertise
4. Iterate quickly with small steps
5. Keep context documents accurate
6. Prefer simple, readable solutions
7. Write or update a Playwright spec for every new user flow

⸻

## 17) TEAM PRINCIPLES

1. Tony drives, team executes
2. Perfect memory and context
3. Proactive suggestions captured in Barry
4. Clean handoffs every time
5. Clear roles and boundaries
6. Agent collaboration by design
7. Context first
8. Version every change
9. Visible plan through context files
10. Tests prove it works

⸻

## 18) SIMPLIFIED WORKFLOW

1. Tony: "Let's get to work"
2. Claude: activate tools, re-read CLAUDE.md, run pnpm test:quick, show status
3. Tony: gives direction
4. Team: executes and documents via AgentOS runbooks
5. Claude: updates context and version
6. Tony: reviews
7. Claude: saves handoff for next time

Goal: zero friction for Tony. Everything should just work when he says the words.

⸻

## 19) PLAYWRIGHT INTEGRATION

**Scripts**

Add to package.json:

```json
{
  "scripts": {
    "test": "playwright test",
    "test:headed": "playwright test --headed",
    "test:ui": "playwright test --ui",
    "test:quick": "playwright test -g @smoke",
    "test:trace": "playwright test --trace on-first-retry",
    "e2e:report": "playwright show-report"
  }
}
```

**CI Gates**
- On PR: run pnpm test:quick and publish report
- On main: run full pnpm test --trace on-first-retry
- Cache Playwright binaries and pnpm store
- Upload HTML report and traces as artifacts
- PRs must be green on test:quick
- Main must be green on full suite
- Quarantined tests require a TASKS owner and ETA

**Conventions**
- Use test ids and accessible selectors (getByRole, getByLabel)
- One user flow per spec
- Few, specific assertions
- Record traces on first retry only
- File names by flow: checkout.spec.ts, auth.spec.ts

**Example:**

```typescript
import { test, expect } from '@playwright/test';

test.describe('Auth', () => {
  test('login happy path @smoke @critical', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('demo@example.com');
    await page.getByLabel('Password').fill('demo123');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  });
});
```

⸻

## 20) AGENTOS RUNBOOKS

Create /.agentos/runbooks.md with these:

**setup/session**
- Checkout branch
- Install deps
- npx playwright install --with-deps
- Seed dev data
- pnpm test:quick

**ship/release**
- Ensure version bump
- Run full tests
- Tag vX.Y.Z
- Generate release notes from CHANGELOG

**bugfix/verify**
- Reproduce with failing spec
- Fix code
- Confirm spec passes locally and in CI
- Add Done entry in TASKS with spec link

⸻

## 21) CONFLICT RESOLUTION: AgentOS vs Claude Agents

- AgentOS is the runner. Claude agents are the team.
- Use AgentOS runbooks for orchestration steps.
- Claude enforces process and keeps context current.
- If a conflict appears, prefer AgentOS runbook steps and record an ADR in DESIGN.

**ADR template:**

```markdown
Decision: Prefer AgentOS step over legacy step X
Context: [why the conflict happened]
Options: [list]
Decision: [chosen]
Impact: [files, scripts, tests]
```

⸻

## 22) MINIMAL CHECKLISTS

**Before coding**
- AgentOS session ready
- pnpm test:quick green

**During PR**
- Specs updated for changed flows
- CI artifacts uploaded

**After merge**
- CHANGELOG updated
- TASKS updated with next steps
- Any quarantined tests tracked with owner and ETA

⸻

## 23) AGENTOS 3-LAYER CONTEXT

AgentOS uses three context layers. Map them directly in every repo:

**Layer 1 - Standards (how we build)**
- Location: ~/.agent-os/standards/ for base templates, copied into project at .agent-os/standards/
- Files to maintain: tech-stack.md, code-style.md, best-practices.md, plus language files under standards/code-style/
- Rule: Project copies are the source of truth for the repo. Keep them in git. Update base separately for future projects.

**Layer 2 - Product (what and why)**
- Location: .agent-os/product/
- Must include: mission.md, roadmap.md, decisions.md, tech-stack.md
- Rule: Update roadmap.md when features ship. Record architectural choices in decisions.md with ADRs.

**Layer 3 - Specs (what to build next)**
- Location: .agent-os/specs/YYYY-MM-DD-feature-name/
- Must include: SRD.md (goals, user stories, success), technical-specs.md (API, DB, UI), tasks.md (TDD-first tasks)
- Rule: Every feature gets a spec folder before coding starts.

⸻

## 24) SPEC LIFECYCLE AND TDD

**Commands workflow (AgentOS):**
1. /create-spec - Create SRD + technical-specs
2. /create-tasks - Generate tasks.md in TDD order
3. /execute-tasks - Implement, run tests, commit, update roadmap, write recap

**Required outputs:**
- Playwright specs for every critical flow referenced in the feature
- Unit/integration tests as appropriate
- .agent-os/recaps/YYYY-MM-DD-[feature].md after execution

**Guardrails:**
- Do not start coding without a spec folder
- Break down oversized tasks early; merge tiny tasks when noisy

⸻

## 25) REFINEMENT LOOP

After each feature:
- Update .agent-os/standards/best-practices.md with patterns corrected in review
- Add code examples to code-style.md (good vs bad)
- Add or update ADRs in DESIGN.md and .agent-os/product/decisions.md
- Version bump standards files (append a mini changelog at file bottom)

Signals to refine:
- Repeated review fixes
- Style drift across modules
- Flaky or missing tests for new flows

⸻

## 26) COMMANDS QUICK REFERENCE

- /plan-product - New product planning. Generates .agent-os/product/ docs
- /analyze-product - Adopt into existing codebase; creates Phase 0, detects stack
- /create-spec - New spec folder under .agent-os/specs/
- /create-tasks - Generate tasks.md with TDD order
- /execute-tasks - Build, test, recap, update roadmap

**Runbooks (AgentOS):**
- setup/session - bootstrap + pnpm test:quick
- ship/release - version, full tests, tag, notes
- bugfix/verify - write failing spec, fix, prove green

⸻

## 27) PROJECT TYPES

For multiple stacks, define project types in base ~/.agent-os/config.yml and install with:

```bash
~/.agent-os/setup/project.sh --project-type=<type>
```

Keep per-type standards in ~/.agent-os/project_types/<type>/ and ensure the project copy is checked in under .agent-os/standards/.

⸻

## 28) REQUIRED FILES - AGENTOS EXPANDED

Add these to section 6 in this document and your repo scaffolding:

```
/.agent-os
  /standards
    tech-stack.md
    code-style.md
    best-practices.md
    /code-style
      javascript-style.md (example)
  /product
    mission.md
    roadmap.md
    decisions.md
    tech-stack.md
  /specs
    /YYYY-MM-DD-feature-name
      SRD.md
      technical-specs.md
      tasks.md
  /recaps
    YYYY-MM-DD-feature-name.md
```

Rules:
- Commit all .agent-os files to git
- Keep base and project standards in sync manually when you improve them

⸻

## 29) BEST PRACTICES CHECKLIST

**Standards**
- Clear code style with examples per language
- Best practices include dos and don'ts
- Tech stack pinned versions and rationale

**Product**
- mission.md current
- roadmap.md matches reality
- decisions.md logs ADRs with context and impact

**Specs & Tasks**
- Every feature has SRD + technical-specs + tasks.md
- Tasks sized for 1-2 hour chunks when possible
- TDD-first tasks with explicit test types

**Testing**
- Playwright @smoke on PRs, full suite on main
- Critical flows covered and tagged @critical
- Traces on first retry, reports uploaded in CI

**Process**
- Runbooks used for setup/test/ship/bugfix
- CHANGELOG updated with spec names when tests change
- Recaps written for each executed spec

⸻

## 30) ALIGNMENT NOTES

- AgentOS is the runner; Claude agents are the team. Prefer runbooks when steps conflict and record an ADR.
- Specs are mandatory before code. Tests prove done. Roadmap reflects shipped reality.