# Open Source Compliance Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create essential open-source governance and community files (Code of Conduct, Security, Issue/PR templates) to make Health Forge public-ready.

**Architecture:** Standard GitHub Community standards and Contributor Covenant templates.

**Tech Stack:** Markdown, GitHub Templates.

---

## Chunk 1: Governance Files

### Task 1: Create CODE_OF_CONDUCT.md

**Files:**
- Create: `CODE_OF_CONDUCT.md`

- [ ] **Step 1: Write CODE_OF_CONDUCT.md with Contributor Covenant v2.1**
  Include the standard template and replace the email placeholder with `mandarnilange@gmail.com`.

- [ ] **Step 2: Commit**

```bash
git add CODE_OF_CONDUCT.md
git commit -m "docs: add CODE_OF_CONDUCT.md (Contributor Covenant v2.1)"
```

### Task 2: Create SECURITY.md

**Files:**
- Create: `SECURITY.md`

- [ ] **Step 1: Write SECURITY.md**
  Include:
  - Supported Versions (v0.1.x)
  - Reporting Process (send to mandarnilange@gmail.com)
  - Commitment to response within 48 hours.

- [ ] **Step 2: Commit**

```bash
git add SECURITY.md
git commit -m "docs: add SECURITY.md"
```

---

## Chunk 2: GitHub Templates

### Task 3: Create Bug Report Issue Template

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.md`

- [ ] **Step 1: Create directory**
  `mkdir -p .github/ISSUE_TEMPLATE`

- [ ] **Step 2: Write bug_report.md**
  Include sections:
  - Bug Description
  - To Reproduce (Steps)
  - Expected Behavior
  - Screenshots (if applicable)
  - Environment (OS, Dart/Flutter version)
  - Additional Context

- [ ] **Step 3: Commit**

```bash
git add .github/ISSUE_TEMPLATE/bug_report.md
git commit -m "docs: add bug report issue template"
```

### Task 4: Create Feature Request Issue Template

**Files:**
- Create: `.github/ISSUE_TEMPLATE/feature_request.md`

- [ ] **Step 1: Write feature_request.md**
  Include sections:
  - Problem Statement (Is your feature request related to a problem?)
  - Proposed Solution
  - Alternatives Considered
  - Additional Context

- [ ] **Step 2: Commit**

```bash
git add .github/ISSUE_TEMPLATE/feature_request.md
git commit -m "docs: add feature request issue template"
```

### Task 5: Create Pull Request Template

**Files:**
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1: Write PULL_REQUEST_TEMPLATE.md**
  Include sections:
  - Description of changes
  - Related Issue
  - Type of change (fix, feature, breaking, docs)
  - Checklist:
    - [ ] TDD followed
    - [ ] Tests pass
    - [ ] Lints pass
    - [ ] Formatting checked
    - [ ] ADR updated (if applicable)

- [ ] **Step 2: Commit**

```bash
git add .github/PULL_REQUEST_TEMPLATE.md
git commit -m "docs: add pull request template"
```
