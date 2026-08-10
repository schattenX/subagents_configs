# Subagent Routing

Optimize monetary cost above latency and total tokens. Delegate repository exploration by default, and delegate implementation by default—including many one- or two-file edits—when an appropriate cheaper specialized subagent exists, even if delegation duplicates context or increases aggregate token usage. The parent should not perform substantial discovery, implementation, conflict resolution, or review when a suitable cheaper agent is available. Consider repository discovery, separate implementation areas, experiment analysis, and independent review.

At the start of a broad task, delegate qualifying workstreams or state why delegation is not worthwhile. Reassess after significant checkpoints and delegate newly separable work when scope or parent context grows. The user need not request subagents explicitly.

The parent agent retains ownership of task orchestration, integration, experiment selection, local implementation decisions within the accepted architecture and plan, and final acceptance. The accepted architecture, public contracts, module boundaries, persistent schema contracts, and critical plan assumptions are execution constraints; the parent must not silently overturn them. Delegate bounded workstreams, not the overall objective. Keep tightly coupled experiment-selection loops in the parent; delegate experiment execution or result analysis when independently separable. Every delegated implementation task must have explicit, non-overlapping file or module ownership; agents share the workspace, must preserve unrelated edits, and must accommodate concurrent changes.

Execute directly only for truly trivial operations where agent startup would exceed the work: a single known-line edit, one short command, or a factual response. Do not delegate trivial conversation. The parent may run ordinary commands needed for routing, integration, or concise final verification, but should delegate repository execution rather than handling substantial discovery, implementation, conflict resolution, or review itself. A slow command alone is not a reason to delegate runner work; use an execution agent when diagnosis, output analysis, or independent parallel execution is substantial.

When delegation is justified:

- Use `fork_turns="none"` unless parent conversation context is genuinely required.
- Prefer one subagent per task. Add more only for non-overlapping work that materially saves time; never fill concurrency slots automatically.
- For broad exploration with multiple independent discovery questions, run `code-explorer` agents in parallel. Give each explorer a distinct concern or repository boundary and require non-overlapping, decision-ready reports. Prefer two explorers; add more only when the workstreams are clearly independent. Keep exploration sequential when one finding determines the next investigation or when agents would search substantially the same files.
- Reuse agents, completed discovery, and cited evidence for related follow-ups.
- Give task-local prompts and request decision-ready reports of at most 300 words: findings, evidence locations, risks, and next action. Exclude narration, raw dumps, and repeated context.
- For parallel implementation, assign explicit, non-overlapping file or module ownership in every subagent prompt. State that the workspace is shared, other agents may edit concurrently, and each agent must preserve and accommodate others' changes.
- Trust cited findings unless verification is necessary. For weak or failed results, retry with a narrower task before switching roles or repeating discovery.
- Detach behavioral verification from `implementer` by default. After implementation and cheap structural checks, keep the original implementer available and delegate focused test, build, lint, or type-check scopes to `code-validator`. Build a complete affected-test manifest from every added or changed test file plus directly affected existing tests. Every validator prompt must state the exact targeted command, assigned manifest entries, scope, and concurrency plan. Run all manifest entries with test-file, test-class, package, or equivalent selectors instead of substituting a whole-suite command; for example, use Gradle `test --tests ...` selectors. Prefer one validator using up to three test-runner workers when supported and concurrency-safe. Otherwise partition the complete manifest across up to three `code-validator` agents with distinct, non-overlapping shards; each shard may contain multiple test selectors. Three limits concurrent workers or agents, not the number of affected tests that must run. Do not parallelize commands that share mutable databases, fixtures, snapshots, generated files, ports, caches, or coverage outputs unless those resources are isolated.
- When every affected unit-test manifest entry passes, do not rerun the global unit-test suite by default. Treat integration and end-to-end validation as separate scopes only when explicitly required by the task or a later routing policy. The parent classifies validator failures before requesting repairs. Consolidate likely implementation failures and resume the same implementer with `followup_task` so it retains its context and file ownership, then send the affected checks back to a validator. Prefer no more than two repair cycles before escalating unresolved, flaky, environmental, or contract-level failures.
- For a truly trivial change with one fast and obvious check, `quick-implementer` may validate directly instead of spawning a validator.

Select custom agents by their exact `name` from `~/.codex/agents`:

- Broad repository discovery, contract or data-flow tracing -> `code-explorer`
- Mechanical one- or two-file change -> `quick-implementer`
- Multi-file behavior change, debugging, or substantial tests -> `implementer`
- Focused read-only test, build, lint, or type-check execution -> `code-validator`
- Independent review only for high-risk, security-sensitive, architectural, public-API, migration, concurrency, or difficult-to-validate changes -> `code-reviewer`
- Escalation-only deep review — never a default or second pass; only when the standard `code-reviewer` or parent cannot reach a high-confidence verdict, or when deeper architectural, security, concurrency, migration, public-API, or cross-module invariant analysis is explicitly requested -> `code-reviewer-deep`
- Exploratory black-box UX review for qualifying user-facing frontend changes after functional validation -> `ux-reviewer`
- Commit and push, only when the user explicitly requests both -> `commit-pusher`

## Escalation-Only Deep Review

`code-reviewer-deep` is an escalation path only — never a default reviewer, and never a second-pass reviewer run automatically after `code-reviewer`. `code-reviewer` remains the default for independent review of qualifying high-risk, security-sensitive, architectural, public-API, migration, concurrency, or difficult-to-validate changes.

Use `code-reviewer-deep` only when at least one of the following holds:

1. The standard `code-reviewer` or the parent explicitly concludes that a high-confidence verdict is not achievable without deeper review.
2. An unresolved material risk requires deeper architectural, security, concurrency, migration, public-API, or cross-module invariant reasoning than the standard reviewer performs.
3. The user or orchestrator explicitly requests a deep review.

Never escalate automatically. In particular, do not invoke `code-reviewer-deep`:

- after `code-reviewer` as a routine second pass;
- because a change is high-risk, security-sensitive, architectural, public-API, migration, or concurrency-related;
- merely because the review surfaced P0/P1 findings.

When the standard `code-reviewer` can reach a confident verdict, stop there — do not escalate solely because the change is high-stakes.

## Architecture Deviation Gate

The parent may decide freely on implementation details that do not change the accepted architecture or its contracts, including private/internal implementation details, helper/function/class organization, local naming, test fixture details, and other local implementation choices.

If implementation would require changing an accepted architecture boundary, module ownership, public API or published port, persistent schema contract, critical data flow, concurrency/transaction model, security/trust boundary, explicit architectural invariant, or critical architecture/plan assumption, the Architecture Deviation Gate is triggered.

When the gate is triggered:

1. Stop the affected workstream immediately.
2. Do not implement the deviation first and then request approval.
3. Report the accepted decision or constraint, the evidence showing why it is problematic, the proposed deviation, the affected modules/contracts, and viable alternatives.
4. Escalate to the architecture/planning authority.
5. Resume the affected workstream only after the deviation is explicitly accepted and the relevant architecture/plan has been updated.

If `code-reviewer-deep` reports `ARCHITECTURE_DEVIATION`, it enters the same gate. Reviewers discover and report deviations; they do not approve architecture.

## Plan Completion Gate Compliance

When executing an implementation plan, every completion gate, acceptance gate, final verification command, and completion criterion written into the plan is mandatory. Passing every task-level `code-validator` check does not by itself mark the plan complete.

A plan is complete only when all of the following hold:

1. All required task-level validation passes.
2. All plan-defined completion and final-verification gates pass.
3. All explicit behavioral and acceptance criteria are met.

Routing defines the validation policy; the plan defines the specific validation scope. Do not substitute a generic affected-test policy for the plan's final gate.

Conversely, when a plan already defines sufficient final verification, do not unconditionally re-run the whole-suite, integration, or E2E checks again. Add extra validation only when another accepted plan, a release gate, a task requirement, or a new risk explicitly requires it.

Distinguish clearly between task validation, plan completion, and version/release acceptance. Completing a plan proves only that plan's scope. If the plan is one workstream of a larger version or release, do not declare the whole version release-ready on its basis; follow the governing version/release acceptance plan.

## Frontend UX Acceptance Gate

Trigger `ux-reviewer` only for qualifying user-facing frontend changes, for example:

- new or significantly changed user journey;
- navigation, routing, or hierarchy changes;
- modal, drawer, assistant, or panel lifecycle changes;
- stateful interactions;
- multi-step workflows;
- reversible interactions;
- persistent UI state;
- error/recovery paths;
- a frontend plan/workstream with material interaction changes;
- the user or plan explicitly requests UX review.

Do not trigger UX review by default for: typos, simple copy changes, trivial style-only changes, non-interactive icon replacements, internal refactors, or behavior-preserving mechanical frontend changes.

Execution order:

Implementation -> functional/task validation -> required E2E/build -> `ux-reviewer` -> plan acceptance

When a UX finding is an implementation defect:

`ux-reviewer` -> parent classifies -> `implementer`/`quick-implementer` -> deterministic regression test when appropriate -> `code-validator` -> targeted UX re-review

When a correct fix requires changing accepted UX design:

`ux-reviewer` -> `UX_DESIGN_REVIEW_REQUIRED` -> stop the affected UX workstream -> design/planning authority -> update the accepted UX/plan -> resume implementation

The Main Agent must not silently redesign accepted UX on its own.

Regression closure: for confirmed deterministic UX0/UX1 findings, add a focused automated regression test when feasible. For issues that are primarily UX requirements, discoverability, or wording, do not force brittle E2E coverage; update the accepted UX requirement when necessary.

Cost control: do not run UX review for every frontend change; do not re-run a full exploratory sweep after every fix; default to a targeted re-review of the affected journey; re-run a full UX sweep only when there is cross-journey impact, a new risk, or the plan explicitly requires it.

Do not use a fixed command-count threshold for exploration. Use `code-explorer` only when discovery is expected to cross several files, require meaningful tracing, or add substantial raw evidence to the parent context. Do not use it to reread known files.

Use the cheapest role and reasoning effort that can reliably complete the work. Do not substitute built-in generic agents when the matching custom agent is available. Avoid parallel write-heavy delegation.
