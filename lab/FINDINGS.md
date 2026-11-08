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

The migration Job and application pods remained stuck with `CreateContainerConfigError`. Kubernetes refused to start containers because the image used the non-numeric username `nonroot`, which Kubernetes could not verify as non-root.

**Cause:**

The chart set `runAsNonRoot: true` but did not specify a numeric user ID. The image's `/etc/passwd` showed that `nonroot` uses UID `65532` and GID `65532`.

**Fix:**

Added `runAsUser: 65532` to the container security context in all six workload templates: backend, gateway, metrics, migrate-job, reporter, and worker. Kept `runAsNonRoot: true` enabled.

The existing migration Job had an immutable pod template, so deleted the old Job with `kubectl delete job migrate -n debug-lab` and reran `scenario.sh up` to recreate it.

**How I found it:**

1. Ran `kubectl get pods -n debug-lab` and observed `CreateContainerConfigError`.
2. Ran `kubectl describe pod -n debug-lab migrate-hkqm5` and found the kubelet error about the non-numeric user `nonroot`.
3. Inspected the six chart templates with `Select-String` and found `runAsNonRoot: true` without `runAsUser`.
4. Inspected the image configuration and history using `docker image inspect` and `docker history`.
5. Exported the image filesystem and inspected `/etc/passwd` using `docker export` and `tar -xOf`, confirming UID/GID `65532:65532`.
6. After adding `runAsUser: 65532`, deleted and recreated the migration Job. `kubectl get jobs -n debug-lab` showed `migrate Complete 1/1`, and `scenario.sh verify` reported `PASS migrate Job completed`.

---

## Defect 3

**Symptom:**

The worker pod entered `CrashLoopBackOff` and its logs reported that it could not initialise its cache because `/var/cache/app` was on a read-only filesystem.

**Cause:**

The worker container had `readOnlyRootFilesystem: true` but no writable volume mounted at `/var/cache/app`.

**Fix:**

Added an `emptyDir` volume named `worker-cache` to the worker pod and mounted it at `/var/cache/app` in the worker container. Kept `readOnlyRootFilesystem: true`.

**How I found it:**

1. Ran `kubectl logs worker-85c774d568-kzvxw -n debug-lab --previous` and found the cache directory error.
2. Inspected the worker pod using `kubectl describe pod`.
3. Added the writable cache volume and mount in `broken-chart/templates/worker.yaml`.
4. Reran `scenario.sh up`.
5. Confirmed the new worker pod started with zero restarts and showed `/var/cache/app` mounted as writable. The pod was still not Ready because its readiness probe checked port 8080 while the application listened on port 8081; this is a separate issue.

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
