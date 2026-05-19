---
name: test-driven-development
description: Use when planning or implementing code with test-driven development, writing failing tests before implementation, creating regression tests, improving testability, designing unit/integration test boundaries, or following red-green-refactor workflows.
---

# Test-Driven Development

Apply a red-green-refactor loop.

## Workflow

1. Clarify observable behavior and acceptance criteria.
2. Identify the smallest test that should fail for the missing behavior.
3. Add or update the test before implementation.
4. Run the targeted test and confirm it fails for the expected reason.
5. Implement the smallest change that makes the test pass.
6. Run the targeted test again.
7. Refactor only after tests pass.
8. Run adjacent tests or checks appropriate to the change.

## Test selection

Prefer tests at the lowest level that proves the behavior:

- Unit tests for pure logic, parsing, formatting, validation, and branching behavior.
- Integration tests for persistence, CLI boundaries, process execution, or cross-module behavior.
- Regression tests for specific bugs, named after the issue or failure mode.

## Test quality

- Test behavior, not implementation details.
- Use explicit arrange-act-assert structure when helpful.
- Keep fixtures minimal and named by intent.
- Avoid snapshots unless stable structure matters more than exact prose.
- Cover failure paths and edge cases that caused the change.
- Do not weaken assertions to make tests pass.

## Implementation discipline

- Do not implement broad speculative changes before the failing test exists.
- If a test fails for the wrong reason, fix the test setup before implementation.
- If implementation reveals the test was wrong, update the test and explain why.
- Keep each red-green cycle small enough to review.
