# Scripting & CLI Automation Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §23**

This extension covers shell scripts (bash, zsh, PowerShell, bat), automation scripts (Python, Node, Ruby), and CLI tools built in any language where the primary use case is scripting and automation rather than a full application. The core template assumes application development patterns — test suites with frameworks, CI/CD pipelines, and structured project layouts. Scripts have different failure modes: silent data loss from unhandled errors, brittle assumptions about the execution environment, and one-off tools that quietly become load-bearing production infrastructure.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CLI / scripts layer.

**This extension covers scripts that are the product, not scripts that support a product.** Build scripts, CI config, and Makefiles that exist solely to support application development are covered by the core template and relevant domain extensions. This extension applies when scripts *are* the deliverable — operational automation, data processing scripts, CLI tools, deployment helpers, migration scripts, and cron jobs.

---

## 23.1 Error Handling and Exit Codes

Scripts fail silently by default. In most shells, a failed command does not stop execution — the script continues with corrupted state, missing data, or partial results. A script that runs 10 steps but fails silently on step 3 produces output that looks correct but is wrong. The downstream consumer (human, cron job, or another script) has no way to know.

**Rules:**

- **Fail fast by default.** Use `set -euo pipefail` in bash (or the language-equivalent strict mode). Every script should fail on the first error unless there is a documented reason to continue.

```bash
#!/usr/bin/env bash
set -euo pipefail
```

```python
# Python equivalent: don't catch broad exceptions, let failures propagate
import sys
import subprocess
subprocess.run(["cmd"], check=True)  # raises on non-zero exit
```

- **Exit codes are the API.** Define and document meaningful exit codes: 0 for success, 1 for general error, 2 for usage error, specific codes for specific failure modes. Never exit 0 on failure.

| Exit code | Meaning | Example |
|---|---|---|
| 0 | Success | Script completed normally |
| 1 | General error | Unhandled exception, unexpected state |
| 2 | Usage error | Missing argument, invalid flag |
| 3+ | Domain-specific | 3 = connection failed, 4 = file not found, etc. |

- **Trap and clean up.** Use `trap` (bash) or equivalent to clean up temporary files, release locks, and restore state on both success and failure.

```bash
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# script body — TMPDIR is cleaned up whether the script succeeds or fails
```

- **Distinguish expected from unexpected failures.** A "file not found" when the file is optional is different from "file not found" when the file is required. Handle expected conditions explicitly; let unexpected conditions fail fast.

**Anti-patterns:**
- Piping to `|| true` to suppress errors without understanding them.
- Using `set -e` without understanding its limitations (it does not catch failures in subshells, command substitutions, or the left side of `&&`).
- Scripts with no error handling that "work" because only the happy path has been tested.

---

## 23.2 Input Validation and Argument Parsing

Scripts accept input from arguments, environment variables, stdin, config files, and interactive prompts. Every input path is a boundary (§3 — Type Assumptions at System Boundaries) that needs explicit validation.

**Rules:**

- **Use a proper argument parser.** `getopts` (bash), `argparse` (Python), `commander`/`yargs` (Node), `OptionParser` (Ruby). Hand-parsing `$1`, `$2`, `$3` breaks on arguments with spaces, flags in unexpected positions, and any non-trivial option syntax.

- **Validate early, fail fast.** Check all required arguments, environment variables, and file paths at script startup — before doing any work. A script that processes 90% of a file before discovering a missing output directory has wasted time and potentially left partial results.

- **Provide a `--help` flag.** Every script that accepts arguments must document its usage in a `--help` output. This is the script's interface contract. A script without `--help` is a function without a docstring.

- **Validate environment assumptions.** Check for required commands (`command -v` or `which`), required environment variables, required files/directories, correct permissions, and compatible tool versions before doing work.

- **Default to safe behavior.** Destructive scripts should require explicit `--force` or `--yes` flags rather than defaulting to destructive action. `rm -rf $UNSET_VARIABLE/` has destroyed production servers.

| Input source | Validation | Common failure |
|---|---|---|
| Positional arguments | Count check, type check, path existence | Missing arg causes wrong file targeted |
| Named flags | Parser validates, unknown flags rejected | Typo in flag silently ignored |
| Environment variables | Presence check + non-empty check | Unset var expands to empty, changes behavior |
| Stdin | Detect if stdin is a terminal vs pipe | Script hangs waiting for input nobody is sending |
| Config files | Existence + parse validation at startup | Malformed config discovered mid-execution |

---

## 23.3 Output Discipline — stdout, stderr, and Structured Output

Scripts produce output to stdout, stderr, log files, and exit codes. Mixing these channels — putting status messages on stdout, errors on stdout, or machine-readable output on stderr — makes scripts unpipeable, unscriptable, and undebuggable.

**Rules:**

- **stdout is for data. stderr is for humans.** Program output (results, machine-readable data) goes to stdout. Status messages, progress indicators, warnings, and errors go to stderr. This rule enables `script.sh | next_step.sh` without status messages corrupting the pipeline.

```bash
# Correct: data to stdout, status to stderr
echo "processed_result" # stdout — consumed by pipe
echo "Processing file 3 of 10..." >&2 # stderr — visible to human
```

- **Support verbosity levels.** `-q` (quiet: errors only), default (normal: errors + key status), `-v` (verbose: detailed progress). For longer-running scripts, consider `-vv` for debug output.

- **Structured output for machine consumption.** When a script's output is consumed by other tools, offer `--format json` or `--format csv`. Parsing human-readable table output with `awk` and `grep` is fragile. Structured output is the boundary contract (§2, §3) for script-to-script communication.

- **Progress indication for long operations.** If a script takes more than a few seconds, show progress on stderr. Silence during a 30-minute operation is indistinguishable from a hang.

- **Color and formatting only when appropriate.** Use ANSI colors only when stderr is a terminal (check with `[ -t 2 ]`). Never add color to stdout — it corrupts piped output.

---

## 23.4 Idempotency — Scripts Safe to Re-Run

A script should produce the same result whether it runs once or five times. This is the scripting equivalent of §18.2 (Pipeline Idempotency). Without idempotency, re-running a script after a partial failure leaves the system in an unknown state.

Scripts fail partway through. Networks drop, disks fill, processes get killed. When a script fails at step 7 of 10, the operator needs to re-run it. If the script is idempotent, re-running is safe. If it is not, the operator must manually figure out where the script stopped and run steps 7–10 by hand — which is where mistakes happen.

**Rules:**

- **Use create-if-not-exists, not create.** `mkdir -p` instead of `mkdir`. `CREATE TABLE IF NOT EXISTS` instead of `CREATE TABLE`. Check before acting.

- **Use atomic operations where possible.** Write to a temp file, then `mv` to the destination. `mv` on the same filesystem is atomic; writing directly to the target file is not. A script interrupted during a write leaves a partial file; a script interrupted before a `mv` leaves the old file intact.

```bash
# Atomic write pattern
tmpfile=$(mktemp)
process_data > "$tmpfile"
mv "$tmpfile" "$OUTPUT_FILE"
```

- **Track progress with checkpoints.** For multi-step scripts, record which steps have completed (a state file, a database record, a marker file). On re-run, skip completed steps.

- **Make destructive operations reversible or confirmable.** Before deleting, back up. Before overwriting, archive. Before migrating, snapshot. If the script cannot be made idempotent, document the re-run procedure explicitly.

---

## 23.5 Dependency and Environment Management

Scripts make implicit assumptions about their execution environment — which shell version, which commands are available, which Python version is on PATH, which environment variables are set. "It works on my machine" is the defining scripting failure mode.

**Rules:**

- **Shebangs are not decoration.** Use `#!/usr/bin/env bash` (not `#!/bin/bash`) for portability. For Python, use `#!/usr/bin/env python3` to avoid Python 2/3 ambiguity. Document the minimum interpreter version in a comment immediately after the shebang.

```bash
#!/usr/bin/env bash
# Requires bash 4.0+ (associative arrays)
set -euo pipefail
```

- **Check for required commands at startup.** Before using `jq`, `curl`, `aws`, or any non-standard command, verify it exists. Do this at the top of the script, not when the command is first used.

```bash
for cmd in jq curl aws; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Required command not found: $cmd" >&2
    exit 1
  }
done
```

- **Pin interpreter versions for non-trivial scripts.** Python scripts: use virtual environments with pinned dependencies (`requirements.txt` or `pyproject.toml`). Node scripts: use `package.json` + lockfile. Ruby scripts: use `Gemfile` + lockfile. A script that installs to the global environment will break something else.

- **Document the environment contract.** At the top of every script (or in a companion README), state: required interpreter version, required external commands, required environment variables, required file/directory paths.

- **Use `.tool-versions`, `mise`, `nvm`, or equivalent** for projects with multiple scripts requiring specific tool versions. Global installs create invisible version conflicts.

| Assumption | Where it breaks | Fix |
|---|---|---|
| bash is bash 5+ | macOS ships bash 3.2 | Check `$BASH_VERSION`, or use feature detection |
| `python` is Python 3 | Many systems: `python` is 2.7 or missing | Use `python3` explicitly, or virtual env |
| GNU coreutils | macOS uses BSD variants (`sed -i`, `date`, `readlink`) | Use portable flags, or detect OS and adapt |
| `jq`, `yq`, `aws`, `gcloud` present | Minimal containers, fresh installs | Check at startup (§23.2) |
| Timezone is UTC | Developer machines use local time | Set `TZ=UTC` explicitly for time-sensitive operations |

---

## 23.6 Secrets Handling in Scripts

Scripts interact with APIs, databases, remote servers, and cloud services — all requiring credentials. The temptation to hardcode a token or paste a password into a script is high because "it's just a quick script." The §4 rule — "No secrets in code. Ever." — applies to scripts with the same force as to application code.

Scripts are frequently committed to git, shared over Slack, or copied between machines. A hardcoded API key in a "temporary" script ends up in version history, in a colleague's clipboard, or in a public repo.

**Rules:**

- **Never hardcode credentials.** Not in the script, not in a default variable value, not in a comment that says "paste your key here." Use environment variables, a secrets manager, or an encrypted config file excluded from version control.

- **Use credential helpers where available.** `aws configure`, `gcloud auth`, `gh auth`, `1password-cli` — these store credentials securely. A script that reads `$AWS_ACCESS_KEY_ID` from the environment is safer than one with the key inline.

- **Prevent secrets from leaking into logs.** If a script uses `set -x` for debugging, secrets in variables will appear in the trace output. Disable tracing around secret-handling code.

```bash
set +x  # disable trace before handling secrets
API_KEY=$(vault kv get -field=key secret/myapp)
set -x  # re-enable after
```

- **Scrub before sharing.** Before sharing a script, committing it, or copying it to a wiki, search for patterns that look like credentials: 40-character hex strings, `sk_live_`, `AKIA`, base64 blobs. Use `gitleaks` or equivalent in pre-commit hooks.

- **Short-lived credentials over long-lived.** Use `aws sts assume-role`, OIDC tokens, or short-lived API tokens instead of permanent keys. If a long-lived credential is unavoidable, document its rotation schedule.

---

## 23.7 Testing Scripts

The core template (§3) covers testing in the context of application code with test frameworks, assertions, and CI integration. Testing scripts requires different patterns because scripts interact heavily with the filesystem, environment, external commands, and system state.

Scripts are notoriously undertested because they feel too "small" or "simple" to warrant tests. But a script that deploys to production, migrates a database, or processes financial data is not simple — it just looks simple.

**Rules:**

- **Test the contract, not the implementation.** A script's contract is: given this input (arguments, environment, files), it produces this output (stdout, files, exit code, side effects). Test that contract.

- **Use BATS for bash testing.** BATS (Bash Automated Testing System) is the closest thing to a standard test framework for bash scripts. For Python scripts, use `pytest`. For Node scripts, use the project's test runner with `child_process.exec` for integration tests.

- **Test with representative fixtures.** Create small, realistic input files that exercise the script's paths. Include: happy path, empty input, malformed input, files with unusual characters in names, and files larger than expected.

- **Test exit codes explicitly.** The exit code is part of the contract. A test that only checks stdout but not the exit code misses failures where the script outputs correct data but signals an error (or vice versa).

- **Test idempotency.** Run the script twice with the same input. The result should be identical (§23.4). If it is not, that is a bug.

- **Use temporary directories.** Tests should create and operate in a temp directory, not the current working directory. Use `mktemp -d` and clean up in a trap. Tests that modify the working directory are fragile and interfere with each other.

**Testing layers:**

| Layer | What it catches | When to run |
|---|---|---|
| Syntax check | `bash -n`, `python -m py_compile`, `shellcheck --shell=bash` | Pre-commit |
| Lint | Style issues, common bugs, portability problems | Pre-commit / CI |
| Unit (function-level) | Logic errors in individual functions | CI on every change |
| Integration (whole-script) | End-to-end behavior with real (but controlled) inputs | CI on every change |
| Smoke test | Script runs in target environment without errors | After deployment / environment change |

---

## 23.8 Cross-Platform Portability

Scripts written on one platform often need to run on another — Linux CI, macOS developer machines, Windows with WSL or Git Bash, Alpine containers with musl instead of glibc. A developer writes a script on macOS, commits it, and the CI pipeline (Linux) fails. These failures are frustrating because the script "works" on the original machine and the error messages are often cryptic.

**Rules:**

- **Know which shell you are targeting.** If you need bash features (arrays, associative arrays, `[[ ]]`), use `#!/usr/bin/env bash` and test on bash 3.2+ (macOS floor). If you need maximum portability, write POSIX sh (`#!/bin/sh`). Do not use bash features in a script with a `/bin/sh` shebang.

- **Avoid platform-specific flags.** GNU and BSD coreutils differ on key flags: `sed -i ''` (macOS) vs `sed -i` (Linux), `date -d` (GNU) vs `date -j` (BSD), `readlink -f` (GNU) vs no equivalent (macOS without coreutils). Either use portable alternatives or detect the platform and branch.

- **Test line endings.** Scripts created on Windows may have CRLF line endings. A bash script with `\r\n` will fail with `/bin/bash^M: bad interpreter`. Use `.gitattributes` to enforce LF in shell scripts: `*.sh text eol=lf`.

- **Avoid assuming GNU utilities.** In Alpine containers, many tools are BusyBox applets with different flags and behavior. In minimal images, standard tools may be missing entirely.

- **PowerShell for Windows-native.** If the script must run natively on Windows (not WSL), write it in PowerShell. Do not try to make bash work in Git Bash for anything beyond trivial tasks — path translation, lack of signals, and command availability make it unreliable for production scripting.

**Portability decision matrix:**

| Target | Shell | Core utils | Approach |
|---|---|---|---|
| Linux only (CI, servers, containers) | bash 4+ | GNU | Use full bash and GNU features |
| Linux + macOS (developer machines) | bash 3.2+ | GNU/BSD | Avoid BSD-incompatible flags, test on both |
| Any Unix (maximum portability) | POSIX sh | POSIX | Stick to POSIX builtins and flags |
| Windows-native | PowerShell | Windows | Separate PowerShell script |
| Cross-OS (Python/Node/Ruby available) | Python/Node/Ruby | Language runtime | Use the language runtime, avoid shell |

---

## 23.9 Script Organization — When to Split

Scripts grow. A 50-line deployment script becomes a 500-line deployment framework. The §11 file size budget applies to scripts, but scripts have an additional challenge: they are often a single file by convention, and splitting a bash script into multiple files is less natural than splitting a Python module into submodules.

**Rules:**

- **Extract functions first, files second.** When a script grows past 200 lines, extract repeated logic into functions within the same file. Functions improve readability and enable testing individual units.

- **Source shared libraries.** When multiple scripts share logic (logging, argument validation, color output), extract it into a shared file and `source` it. Establish a convention: `lib/` directory at the project root for shared script libraries.

- **Recognize the "not a script anymore" threshold.** When a script needs: (a) multiple subcommands, (b) configuration files, (c) state management, (d) error recovery across steps, or (e) tests more complex than BATS can handle — it has outgrown scripting. Convert it to a proper CLI application in Python (click/typer), Go (cobra), Rust (clap), or Node (commander/oclif).

**The escalation ladder:**

| Complexity | Structure | Tooling |
|---|---|---|
| Single task, <100 lines | One script file | Shebang + shellcheck |
| Single task, 100–400 lines | One file with functions | Shebang + shellcheck + BATS |
| Multiple related tasks, shared logic | Directory with scripts + `lib/` | Makefile or wrapper script as entry point |
| Subcommands, config, state | CLI application | Python click/typer, Go cobra, Rust clap |

---

## 23.10 Unattended Execution — Cron, Systemd Timers, and Scheduled Tasks

A script that works interactively can fail silently when run by cron, systemd timers, Windows Task Scheduler, or a CI schedule. Unattended execution strips away everything an interactive session provides: environment variables, PATH, a terminal, and a human watching the output. The result is scripts that fail in ways nobody notices until the damage is done.

**Why unattended scripts deserve their own discipline:** Every other section in this extension applies to all scripts. But scheduled scripts compound the risks — a bad exit code that a human would notice immediately goes unseen for days. An overlapping run that a human would kill manually creates data corruption at 3 AM. The gap between "works when I run it" and "works when cron runs it" is where most production scripting incidents live.

**Rules:**

- **Set the environment explicitly.** Cron does not source `.bashrc`, `.profile`, or `.zshrc`. The `PATH` in a cron job is typically `/usr/bin:/bin` — tools installed via `brew`, `pip`, `npm`, `snap`, or custom paths are not available. Set `PATH` and any required variables at the top of the script or in the crontab.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Explicit environment — don't rely on shell profile
export PATH="/usr/local/bin:/usr/bin:/bin"
export TZ="UTC"
```

For systemd timers, use the `Environment=` directive in the service unit. For Windows Task Scheduler, configure environment variables in the task's action settings.

- **Prevent overlapping runs.** If a job takes longer than its schedule interval, the next invocation starts a second copy. Two copies of the same script writing to the same files, database, or API produce corrupted results. Use `flock` to enforce mutual exclusion.

```bash
# Exit immediately if another instance is already running
exec 200>/var/lock/my-script.lock
flock -n 200 || { echo "Already running, exiting." >&2; exit 0; }
```

For systemd timers, this is built in — set `ExecStart=` without `Type=oneshot` and systemd won't start a new instance while the previous is running. Alternatively, use `flock` in the `ExecStart` command for explicit control.

- **Log to a durable destination.** Cron's default behavior is to email stdout/stderr to the local user's mailbox — which nobody reads. Redirect output to a log file, syslog, or a centralized logging system. Include timestamps.

```bash
# In crontab — redirect both stdout and stderr to a log file
0 * * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Or inside the script — structured logging with timestamps
log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >&2; }
log "Starting backup..."
```

For systemd timers, `journalctl -u my-script.service` captures output automatically. Prefer systemd timers over cron when the system supports them — you get logging, dependency management, and resource controls for free.

- **Alert on failure.** A scheduled script that fails silently is worse than one that doesn't run at all — at least a missing run is detectable. Implement at least one of these alerting patterns:

| Pattern | How it works | Best for |
|---|---|---|
| Exit code monitoring | Wrapper checks exit code, sends alert on non-zero | Simple scripts, small teams |
| Dead-man switch | Script pings a monitoring endpoint on success; missing ping triggers alert | Critical jobs that *must* run on schedule |
| Log-based alerting | Log aggregator watches for error patterns | Teams with existing log infrastructure |
| Systemd `OnFailure=` | Systemd triggers a notification unit when the service fails | Systems using systemd timers |

Dead-man switch services (Healthchecks.io, Cronitor, PagerDuty cron monitoring) are the most reliable pattern for critical jobs — they catch both failures *and* jobs that never started.

```bash
# Dead-man switch: ping on success only
process_data && curl -fsS --retry 3 https://hc-ping.com/your-uuid > /dev/null
```

- **Enforce timeouts.** A script that hangs indefinitely blocks the next scheduled run (if using `flock`) or causes overlapping runs (if not). Wrap long-running scripts with an explicit timeout.

```bash
# In crontab
0 * * * * timeout 3500 /opt/scripts/hourly-job.sh >> /var/log/hourly.log 2>&1

# Or with systemd timer
# In the .service unit:
# RuntimeMaxSec=3500
```

Set the timeout shorter than the schedule interval to leave room for cleanup and to prevent overlap.

- **Test in the cron environment.** The "cron test" — run the script with a stripped environment to simulate what cron provides:

```bash
# Simulate cron's minimal environment
env -i HOME="$HOME" /bin/bash /opt/scripts/my-script.sh
```

If the script fails under `env -i` but works normally, it has implicit environment dependencies that need to be made explicit (§23.5).

- **Document the schedule and owner.** Every scheduled script should have a comment (in the crontab, systemd unit, or a companion doc) that states: what the script does, how often it runs, what to do if it fails, and who owns it. Undocumented cron jobs become organizational mysteries when the original author leaves.

```
# /etc/cron.d/backup
# Owner: ops-team@example.com
# Purpose: Nightly database backup to S3
# On failure: Check /var/log/backup.log, re-run manually, alert #ops-alerts
# See: https://wiki.internal/runbooks/db-backup
0 2 * * * appuser /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## Common Scripting Anti-Patterns

Process traps and discipline failures that turn "quick scripts" into long-term liabilities. Flag these during code review.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **"It's just a script"** | The phrase that precedes every unmaintained, untested, undocumented script that becomes load-bearing production infrastructure. No error handling, no tests, no documentation — and then it runs in a cron job for 3 years until it silently breaks. | Every script that runs unattended or is used by more than one person needs: error handling (§23.1), input validation (§23.2), a `--help` flag (§23.2), and at minimum a lint check (§23.7). |
| **Parsing output with regex** | Piping human-readable output through `grep`, `awk`, and `sed` to extract data. The output format changes between tool versions, locales, and platforms. | Use structured output formats (§23.3). If the upstream tool offers `--json`, `--csv`, or an API, use that. If it does not, acknowledge the fragility and pin the upstream tool version. |
| **Global state as communication** | Scripts that communicate through global variables, temp files in fixed paths, or environment variable side effects. Two instances running simultaneously corrupt each other's state. | Use explicit function parameters and return values. Use `mktemp` for temp files (unique paths per invocation). Use locks (`flock`) if mutual exclusion is needed. |
| **Untested deployment scripts** | The most critical script in the repository — the one that deploys to production — has never been tested. Its first real test is the first production deployment. | Test deployment scripts in a staging environment (§23.7). At minimum, run them with `--dry-run` or against a disposable environment. |
| **Shell script does too much** | A 1,000-line bash script with error handling, retry logic, JSON parsing, HTTP calls, and state management. Every line is fighting the language rather than using it. | Recognize the threshold (§23.9). When a script needs data structures, error recovery, or complex logic, rewrite in Python or Go. |
| **No shebang or wrong shebang** | Script uses bash features but has `#!/bin/sh` or no shebang at all. Works when invoked as `bash script.sh` but fails as `./script.sh` because `/bin/sh` is dash on Ubuntu. | Always include a shebang. Match it to the shell features you use (§23.5, §23.8). |

---

## Mapping to Core Guardrail Sections

This extension does not replace core guardrails — it extends them for the scripting context:

| Core Section | Scripting Equivalent |
|---|---|
| §2 Specs | §23.2 Input validation (argument contract as the script's spec), §23.3 Structured output (output contract) |
| §3 Testing | §23.7 Testing scripts (syntax check, lint, unit, integration, smoke test layers) |
| §3 Type Assumptions | §23.2 Input validation + §23.5 Environment assumptions (boundary contracts for scripts) |
| §3b Process Discipline | §23.1 Error handling (fail fast), §23.4 Idempotency (safe re-run) |
| §4 Security | §23.6 Secrets handling (no hardcoded credentials, credential helpers, log scrubbing) |
| §4 Observability | §23.3 Output discipline (stdout/stderr separation, verbosity levels, structured output) |
| §6 Consistency | §23.5 Dependency management (shebangs, version pinning, environment contracts), §23.8 Cross-platform portability |
| §11 File Size | §23.9 Script organization (when to split, the escalation ladder) |
| §13 Dead Code | §23.9 "Not a script anymore" threshold — recognize when maintenance cost exceeds script simplicity benefit |
| §15 Checklists | §23.10 Unattended execution — scheduled script discipline (locking, logging, alerting, timeouts) |

---

## Scripting Checklist (extends §15)

### Before Every Script Change
- [ ] `set -euo pipefail` (or language equivalent) present — script fails fast on errors (§23.1).
- [ ] All inputs validated at startup — arguments, environment variables, required commands (§23.2).
- [ ] `--help` output current and accurate (§23.2).
- [ ] stdout/stderr separation correct — data on stdout, status/errors on stderr (§23.3).
- [ ] No hardcoded secrets — credentials from environment or secrets manager (§23.6).

### Before Every Script PR
- [ ] Linter passes — `shellcheck` for bash, language-appropriate linter for Python/Node/Ruby (§23.7).
- [ ] Exit codes tested — success and failure paths verified (§23.1, §23.7).
- [ ] Idempotency verified — script safe to re-run on same input (§23.4).
- [ ] Environment dependencies documented — required tools, versions, and variables listed (§23.5).
- [ ] Cross-platform behavior verified if script runs on multiple OSes (§23.8).
- [ ] Shebang matches shell features used (§23.5, §23.8).

### Before Scheduling a Script (Cron / Systemd Timer / Task Scheduler)
- [ ] Script works under `env -i` — no implicit environment dependencies (§23.10).
- [ ] Locking in place — overlapping runs prevented with `flock` or equivalent (§23.10).
- [ ] Output logged to a durable destination — not relying on cron mail (§23.10).
- [ ] Failure alerting configured — exit code monitoring, dead-man switch, or log-based alert (§23.10).
- [ ] Timeout enforced — script cannot hang indefinitely (§23.10).
- [ ] Schedule, owner, and failure runbook documented in crontab comment or companion doc (§23.10).

### Periodic
- [ ] Audit scripts for growth — any script over 400 lines evaluated for splitting or rewrite (§23.9, quarterly).
- [ ] Credential rotation — scripts using long-lived tokens verified against rotation schedule (§23.6, per §4 cadence).
- [ ] Dependency check — required external tools still available and compatible in target environments (§23.5, after environment updates).
- [ ] Unused script sweep — scripts that no longer serve a purpose identified and removed (§13, quarterly).
