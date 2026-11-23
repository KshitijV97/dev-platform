# Solutions

Durable learnings captured with `ce-compound` live here. The point is to make the next change easier, not to keep a diary.

## When to write one

- A verified fix corrected a wrong belief about how something behaves.
- A review caught a defect that a test or lint rule could have caught.
- A deployment or restore step failed in a way that will recur.
- A free-tier limit or provider behavior surprised us.

Do not write one for work that went as planned.

## Format

One file per lesson: `YYYY-MM-DD-slug.md`.

```markdown
# <Lesson>

## Context
What were we doing?

## Symptom
What did we see?

## Cause
What was actually true?

## Fix
What changed?

## Verification
How do we know it is fixed?

## Reuse
Where should the next agent look, and what rule or test now prevents it?
```

Prefer the cheapest durable form: a test or lint rule first, then a coding standard, then a note here.
