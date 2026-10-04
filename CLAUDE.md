# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Mood Tracker

A simple, dependency-free mood tracker for bipolar mood charting. Intended to run in a desktop browser now and on a phone later (likely as an installable PWA).

## Project rules

1. **Personal data never leaves this computer.** No mood entries, notes, exports, backups, screenshots of real data, or anything else specific to the person using the app may be committed or pushed to GitHub (or sent to any other server).
   - Entries live only in the browser's local storage. Don't add code that uploads, syncs, or phones home (no analytics, remote logging, or third-party scripts/CDNs).
   - Exported files (`mood-log-*.csv`, `mood-backup-*.json`) and anything under `data/` are git-ignored. Keep it that way; check `git status` before every commit.
   - Use made-up sample data for tests, demos, and examples.

2. **No PII in the repo.** Personally identifiable information stays local and never goes into anything pushed to GitHub — code, comments, docs, test fixtures, file names, commit messages, branch names, PR text, or issues. That includes:
   - real names, email addresses, phone numbers, street addresses, birth dates
   - names of doctors, clinics, pharmacies, medications tied to a person, or insurance details
   - usernames, machine names, and absolute paths that reveal them (e.g. `/home/<user>/...`) — use relative paths
   - API keys, tokens, or passwords
   - Commit author identity: use the GitHub-provided `noreply` email for this repo, not a personal address.
   - Before committing, scan the staged diff for anything on this list; when in doubt, leave it out and ask.
   - A local `pre-commit`/`commit-msg` hook in `.git/hooks/` enforces rules 1–2 (noreply author, data files, home paths, emails, secrets, and personal terms listed in `.git/pii-patterns`). These live only in `.git/` and aren't pushed — never add the patterns file to the repo, and don't bypass the hook with `--no-verify` without asking.

3. **Commit, pull, and push after every completed task.** Once a task is done, commit it, then `git pull --rebase` and `git push` so `main` on GitHub stays current.

## Commands

There is no build step, package manager, linter, or test suite. The only runtime dependency is `python3` (for its built-in web server).

- Run the app: `./start.sh` — serves the folder on http://127.0.0.1:8765 and opens the browser; Ctrl+C stops it. If it's already running, it just opens the page.
- Syntax-check the inline JavaScript:
  `sed -n '/<script>/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/app.js && node --check /tmp/app.js`

## Architecture

- **`index.html` is the entire app** — markup, CSS, and one inline `<script>`, no frameworks or external resources. Keep it that way unless there's a strong reason (rule 1 forbids CDNs anyway).
- **The port is fixed on purpose.** `localStorage` is scoped per origin (scheme + host + port), so changing `PORT` in `start.sh` — or opening `index.html` via `file://` — shows an empty app. Data only moves between origins via the JSON backup/restore buttons.
- **Storage:** one `localStorage` key, `moodtracker.v1`, holding an object keyed by local date `YYYY-MM-DD` → entry `{date, mood, sleep, energy, anxiety, irritability, meds, notes, updated}`. One entry per day; saving a date overwrites it. `mood` is an integer −5..+5; `energy`/`anxiety`/`irritability` are 0–3 or null; `meds` is `yes|partial|no|na` or null; `sleep` is hours or null. If the shape changes, bump the key/version and migrate old data in `load()` rather than breaking existing entries.
- **Dates are local-time strings**, built with `fmt()`/`parse()`/`addDays()` — never `toISOString()` for dates, which would shift days across the UTC boundary.
- **Rendering:** every save/delete/import calls `persist()` then `render()`, which rebuilds the warnings, chart, and history from `entries`. The chart is hand-built SVG (`renderChart`), with missing days breaking the mood line.
- **Pattern warnings** (`renderWarnings`) look at entries from the last 7 calendar days: last 3 entries all ≥ +3; last 2 entries with sleep < 5h and mood ≥ +1; last 5 entries all ≤ −3; meds `no` on ≥ 2 days. Wording is deliberately non-diagnostic ("pattern to watch", suggest care team/wellness plan).
- **Import** (`importJson`) merges into existing entries and accepts either the backup format `{app, version, entries}` or a bare entries object; rows with a bad date key or out-of-range mood are skipped. User-supplied text is always rendered via `textContent`, never `innerHTML`.
