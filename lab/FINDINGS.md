# Findings — Part 4 debug lab

Fill in one entry per defect you find. Paste the *actual* output you saw —
we cross-check it against your session recording and your git diff, and the
diagnostic path matters more to us than the fix itself.

Before you start investigating, begin recording:
`script -q part4-session.log` (or `asciinema rec part4-session.cast`), and
commit that file alongside this one.

---

## Defect 1

**Symptom** (what you observed — paste the real command output):  scenario.sh up reported that Job.batch "migrate" is invalid because spec.template.spec.restartPolicy must be OnFailure or Never.

**Cause** (the actual root cause, not the symptom restated): broken-chart/templates/migrate-job.yaml sets restartPolicy: Always, which is invalid for a Job.

**Fix** (what you changed, and why this over alternatives): Changed the restartPolicy: Always -> restartPolicy: OnFailure

**How I found it** (the sequence of commands/reasoning that led you here): Ran scenario.sh up, inspected kubectl get jobs -n debug-lab -o yaml, then searched the chart templates for kind: Job and restartPolicy.

---

## Defect 2

**Symptom:**

**Cause:**

**Fix:**

**How I found it:**

---

## Defect 3

**Symptom:**

**Cause:**

**Fix:**

**How I found it:**

---

## Defect 4

**Symptom:**

**Cause:**

**Fix:**

**How I found it:**

---

## Defect 5

**Symptom:**

**Cause:**

**Fix:**

**How I found it:**

---

## Defect 6

**Symptom:**

**Cause:**

**Fix:**

**How I found it:**

---

If you ran out of time on any defect, say so here and describe what you would
have tried next — that section is read carefully and counts in your favour.
