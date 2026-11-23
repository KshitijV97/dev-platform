# ADR-0006: Toronto as the Oracle home region

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** ADR-0001, `docs/grill/brief.md` Q1

## Context

The OCI home region is chosen at account creation and **cannot be changed**. Always Free compute only runs there, so this is a permanent decision made before any capacity can be measured.

Both Canadian regions have one availability domain and no meaningful feature difference. The real difference is A1 capacity, which is a lottery.

The original brief recommended "Toronto, with Montreal as fallback". That fallback does not actually exist: you cannot test A1 capacity without owning an account, and creating a second account to try the other region violates Oracle's one-account-per-person rule. The choice is a bet, not a test.

Latency is not the deciding factor. Toronto → Montreal is roughly 10 ms, which is invisible next to a two-day capacity stall.

## Decision

Use **`ca-toronto-1`** as the home region for the single Oracle tenancy.

## Consequences

**Positive**

- Lowest latency to the operator and to Ontario clients.
- One region to reason about in Terraform, DNS, and the rebuild runbook.
- Canadian data residency for Phase 1 and 2.

**Negative**

- A1 capacity in Toronto is historically tighter than Montreal.
- If provisioning fails, the only exits are waiting, or upgrading the account — a new region means a new account, which is not allowed.
- The decision cannot be revisited without abandoning the tenancy.

**Mitigations**

- Treat capacity as an operational task with retries, not a one-shot `apply`.
- The documented lever is an upgrade to Pay As You Go: Always Free resources stay free, but capacity stops being a lottery. **Provisional, pending explicit confirmation** — see `docs/grill/brief.md` Q1b.
- A budget alarm is mandatory the moment a payment method exists, so the upgrade cannot produce a surprise bill.
- `infra/oracle/` keeps the region in one variable with a Canadian-region validation, so a deliberate change is a one-line diff plus a new tenancy.

## Alternatives rejected

- **`ca-montreal-1`:** slightly better capacity history, ~10 ms worse latency, same one-AD shape. Rejected because capacity is not reliably better and the latency touches every request. Reconsider only if Toronto cannot provision at all.
- **Azure Canada Central:** 12-month free VM, not a home.
- **Defer the decision:** impossible; the region is fixed at signup.

## Revisit triggers

- A1 provisioning fails in Toronto for more than 72 hours.
- A client requires Quebec data residency.
- Oracle changes the Always Free terms or regional availability again.
