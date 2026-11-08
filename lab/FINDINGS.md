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

**Symptom:** Worker crashed because /var/cache/app was on a read-only filesystem
**Cause:** No writable volume was mounted at /var/cache/app
**Fix:** Added an emptyDir volume named worker-cache and mounted it at /var/cache/app
**How I found it:** Worker logs showed the cache initialization error; after the fix, the new pod started with zero restarts and showed the writable mount. 

---

## Defect 4

**Symptom:** The worker container started but remained NotReady because its readiness probe checked port 8080 while the application listened on port 8081.

**Cause:** The image defaults to port 8081 for the worker. The chart configured the container port and readiness probe using the common port 8080 but did not override the application's default port.

**Fix:** Added PORT: "8080" to the worker environment in broken-chart/values.yaml. This makes the application listen on the same port used by the worker container and readiness probe.

**How I found it:** 
1. Ran kubectl logs worker-f749d965c-zcvj2 -n debug-lab and observed that the application listened on port 8081.

2. Ran kubectl describe pod worker-f749d965c-zcvj2 -n debug-lab and found readiness probe failures connecting to port 8080.

3. Inspected broken-chart/values.yaml and broken-chart/templates/worker.yaml.

4. Added PORT: "8080" to the worker environment and reran scenario.sh up.

5. Confirmed the new worker pod became 1/1 Running, and its logs showed /healthz returning HTTP 200.

6. Reran scenario.sh verify; the worker readiness check passed.

---

### Defect 5: Backend port mismatch

- **Symptom:** Backend pod was Running but not Ready; health check failed.
- **Cause:** The application defaulted to port 8081, while the chart's container port and readiness probe used 8080.
- **Fix:** Added `PORT: "8080"` under `backend.env` in `values.yaml`.
- **Verification:** Backend became 1/1 Ready. `scenario.sh verify` passed the backend readiness and health endpoint checks.

---

### Defect 6: Gateway port and backend URL misconfiguration

- **Symptom:** Gateway was Running but not Ready, and `/status` did not report `backend=ok`.
- **Cause:** The application defaulted to port 8081 while the readiness probe checked 8080. The backend URL also pointed to `backend.default.svc` instead of the backend Service in `debug-lab`.
- **Fix:** Set `PORT: "8080"` and `BACKEND_URL: "http://backend:8080"` under `gateway.env` in `values.yaml`.
- **Verification:** Gateway became 1/1 Ready. Verification passed gateway readiness and `gateway /status reports backend=ok`.

---

If you ran out of time on any defect, say so here and describe what you would
have tried next — that section is read carefully and counts in your favour.
