# Iterations

An iteration is a fixed window of work that ends in a retro. Every issue belongs to exactly one iteration, and the retro does not close until the iteration is empty.

This is the mechanism that keeps the tracker from turning into a graveyard: work is either finished, or knowingly carried with a reason.

## The model

- One iteration is one **GitHub milestone**, titled `iteration-NN: <theme>`.
- `manifest.json` is the machine-readable list of milestones and the issues each one starts with.
- `scripts/seed-issues.sh` creates them. `scripts/iteration-status.sh` reads them back.
- The project board's `Status` field tracks flow inside an iteration. The milestone tracks which iteration an item belongs to. Do not duplicate the iteration into a label.

## Rules

1. **Every issue has exactly one milestone.** No exceptions, no limbo. If unplanned work arrives, it goes to the current iteration and displaces something — visibly.
2. **An iteration ends at its retro.** At that moment every issue in the milestone is closed or carried. Nothing stays silently open.
3. **Carry-over is bounded.** At most two issues per iteration. Each carry-over gets a comment beginning with `carry-over:` stating why it did not close and what would close it next time. Then move it to the next milestone.
4. **Closing means the checklist is done.** A decision closes with an ADR, not with a comment. A drill closes with a recorded measurement, not with "looks fine".
5. **Never reopen a closed iteration.** If work resurfaces, open a new issue in the current milestone and link back.

## The retro gate

```bash
./scripts/iteration-status.sh          # what is open, per iteration
./scripts/iteration-status.sh --check  # exit non-zero if the current iteration is not empty
```

Run it at the start of `ce-retro`. If it fails, close what can be closed, carry what cannot, then run it again.

The full loop:

1. `./scripts/iteration-status.sh` — see the open set.
2. Close, or carry with a `carry-over:` reason (max two).
3. `./scripts/iteration-status.sh --check` must exit 0.
4. Run `ce-retro`. Its input is the status output plus the carry-over list, not memory.
5. Add the next milestone and its issues to `manifest.json`, then `make seed-issues`.

`ce-retro` also feeds `ce-compound`: a lesson that corrected a belief gets a file in `docs/solutions/`, and the issue that produced it links to it.

## Naming

```
iteration-00: settle decisions
iteration-01: phase 0 bootstrap
iteration-02: optional ROG worker
```

`NN` is zero-padded and monotonic. Never renumber an iteration; the numbers are the history. The theme is two to four words.

If work spans repositories, every repo carries a milestone with the **same title**, so the name stays the join key.

## What belongs in an iteration

- Anything that changes behaviour, cost, or security posture.
- A decision that blocks a build step.
- The drill or measurement that proves a claim in an ADR.

## What does not

- Unbounded "improve X" work. Split it until it has acceptance criteria.
- Optional capacity that is not on the critical path. It gets its own iteration so it can never block a retro. `iteration-02` is exactly this.

## Cadence

No fixed length at this stage. Phase 0 is a single iteration. After the first client, one iteration per one to two weeks, ending in a retro that produces the next milestone.

## Current iterations

| Milestone | Theme | Ends with |
|---|---|---|
| `iteration-00: settle decisions` | Resolve every question in `docs/grill/brief.md` | Every question is an ADR or a deferral with a trigger |
| `iteration-01: phase 0 bootstrap` | Execute `docs/plans/0001-phase-0-bootstrap.md` | One live node, a live tracker, two drills passed |
| `iteration-02: optional ROG worker` | Onboard the ROG as an optional worker | The dependency-guard drill passes with it switched off |

`iteration-02` is deliberately outside the Phase 0 gate. It is allowed to stay open while the platform ships.

## Adding an iteration

1. Append the milestone to `manifest.json`.
2. Append its issues with labels, a summary, acceptance criteria, and a source link.
3. `make seed-issues` (idempotent; safe to re-run).
4. Verify with `./scripts/iteration-status.sh`.
