# Security review policy

The shipped control matrix describes bounded local controls. External review
gates remain pending; this pull request does not record their acceptance or
grant release authorization. See `EXTERNAL-SECURITY-REVIEW-GATES.tsv` and the
public known limitations. The public CI entry point reports its actual scope
and does not claim to rerun historical security campaigns.

## Read-only inspector

Run `python3 -B tools/nebo-security.py --profile PATH --profile-sha256 TRUSTED_PIN`.
The profile defaults to the shipped sdk/nebo-1.0/security directory. Obtain the
pin from a trusted distribution; hashing an untrusted replacement authenticates
nothing. Exit 2 means rejected input. Exit 3 means valid records with final
release gates still blocking. Exit 0 means the recorded final review gates have
accepted receipts; even then `release_authorized` is false.

External state transitions are an authorized maintainer process: OPEN or
PENDING_EXTERNAL to PASS/FAIL; PASS to REVOKED on invalidation. Record the
reviewer role, exact candidate hash, scope, full report and explicit acceptance.
A PASS record requires a separately trusted `<gate>.review.json` receipt and
`--accept-review GATE=TRUSTED_RECEIPT_SHA256 --candidate-sha256 SHA256`.
Receipt fields: gate, decision (PASS), reviewer, role, candidate_sha256, scope,
exclusions (empty). The trusted receipt pin is the host's acceptance boundary;
this tool does not cryptographically authenticate a reviewer. A changed
candidate, scoped exclusion, missing pin, failed/revoked state or stale receipt
cannot satisfy that gate. Tests use plainly synthetic reviewers and receipts
only inside temporary directories, never as project acceptance.

Waivers record scope, owner, rationale, expiry and status. They may document
only an OPTIONAL_EXCLUDED risk; even ACCEPTED waivers never satisfy a review
gate. Mandatory safety/privacy claims cannot be waived. Actual policy edits,
reviews and acceptance remain separately authorized human actions.
