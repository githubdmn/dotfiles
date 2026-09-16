Much tighter script than the last one — the structure is sound, `pipefail` is doing real work, and the `BASH_SOURCE` guard is the right call. The problems here are subtler.

## Real bugs

**A failed `git pull` silently eats your local changes.** In `update_oh_my_bash`, if you have local modifications, the script stashes them. If `git pull` then fails, the `else` branch logs the failure and returns 1 — without ever popping the stash. Your edits are now sitting in a stash entry that nothing tells you about. The stash restore needs to happen on every exit path, not just the success path.

**`set -e` is disabled inside every function you call.** `if ! upgrade; then` puts the function in a condition context, which suspends errexit for its entire body. So inside `upgrade()`:

```bash
upgrade() {
    log "Upgrading installed packages..."
    update                          # if this fails...
    sudo apt upgrade -y | tee -a "$LOG_FILE"   # ...this still runs
}
```

If `apt update` fails (network down, broken source), you go on to upgrade against a stale or partial index. Needs an explicit `update || return 1`.

**`source "$OSH/oh-my-bash.sh"` in a non-interactive script.** Two problems. First it's pointless — it modifies the script's own dying shell, not your terminal. Second it's a hazard: oh-my-bash sets `PS1`, loads themes and completions, and references variables that may be unset. Under `set -u` that's a hard abort, and it happens _after_ you've logged "updated successfully".

## Unattended-run hazards

**No `DEBIAN_FRONTEND=noninteractive`.** `-y` covers apt's own prompts, but not dpkg conffile prompts (`Configuration file '/etc/foo' ... What do you want to do?`) and not needrestart, which on Debian 12+ pops an interactive service-restart dialog by default. Either will hang this script indefinitely — and since it's clearly meant to be a fire-and-forget updater, that's the failure mode you'd hit from a cron job or timer.

**No sudo handling.** The script prompts for a password at the first `sudo`, partway into execution. From cron or a systemd timer it just hangs on a prompt nobody sees.

**No lock.** If `unattended-upgrades` or another instance holds `/var/lib/dpkg/lock-frontend`, apt fails immediately rather than waiting. Worth both a script-level `flock` and `-o DPkg::Lock::Timeout`.

## Correctness / style

**`apt` instead of `apt-get` in a script.** apt itself prints `WARNING: apt does not have a stable CLI interface. Use with caution in scripts.` Its output format changes between releases. `apt-get` is the scripting interface.

**`apt upgrade` vs `full-upgrade`.** `upgrade` refuses to remove packages or install new dependencies, so kernel metapackages and anything with changed deps get held back — they'll show as "the following packages have been kept back" and just accumulate. Your `install.sh` uses `full-upgrade`; these two scripts disagree about what "upgrade" means on the same machine.

**`pushd`/`popd` without a trap.** Every failure path inside the `if` block remembers to `popd`, but a failure in `git diff-index` or `git stash push` doesn't — and the directory stack leaks. A subshell with `cd` is simpler and can't leak.

**`rm -f "${OSH}/log/update.lock"`** unconditionally deletes a lock that might be held by a legitimately running process.

**`log` uses `echo -e`** on an arbitrary message. Any backslash in a message gets interpreted. `printf '%s\n'` is safe.

**`log "⚠️ #Clear cache sudo rm -rf /var/lib/apt/lists/*"`** — this fires on every single run and reads like a warning about something that happened. It's a commented-out note that escaped into the log.

**Unbounded log growth.** `custom-update.log` is append-only forever with no rotation.

**`git pull` without `--ff-only`** can create a merge commit in a repo you don't own.

Let me write the fixed version.I built a throwaway git repo pair to verify the stash bug is real rather than just reasoning about it. Original logic, unreachable remote, one uncommitted file:

```
Stashing local modifications...
Failed to update Oh My Bash
--- after ---
files:        f.txt
stash list:   stash@{0}: On main: orig stash
```

`precious.txt` is gone from the working tree. Same scenario against the rewrite:

```
Stashing...
Restoring stash...
Reapplied.
--- after ---
files:        f.txt  precious.txt
stash list:   (empty)
```

## What changed

**Stash restore moved into a nested function called on every exit path.** Success pops it and fails the task if the pop conflicts; failure pops it and still reports the pull failure. The conflict message points at `git stash list` so nothing looks lost.

**`pushd`/`popd` replaced by a subshell with `cd`.** The directory stack can't leak no matter where it exits, and `restore_stash` closes over `stash_ref` naturally.

**`source "$OSH/oh-my-bash.sh"` removed.** Replaced with a line telling you to open a new shell.

**Explicit failure propagation in `upgrade`.** `update || { log_err ...; return 1; }` — a failed index update now stops the run instead of upgrading against stale data. This matters specifically because calling the function from `if !` suspends errexit inside it.

**`apt-get` throughout, with `-o DPkg::Lock::Timeout=300`**, so a concurrent `unattended-upgrades` makes the script wait rather than fail.

**`DEBIAN_FRONTEND=noninteractive` plus `NEEDRESTART_MODE=a`.** Without the second one, needrestart on Debian 12+ will show its service-restart dialog and hang forever under cron.

**`flock` on `$XDG_RUNTIME_DIR/custom-update.lock`.** Verified with two independent processes — second one gets refused cleanly rather than colliding on the dpkg lock. (Note: nested shells sharing an inherited fd won't show this; two real invocations do.)

**Sudo preflight.** Primes the timestamp up front, and if no password is cached and there's no tty, it fails immediately with a clear message instead of hanging on an invisible prompt. Background keepalive dies with the parent.

**Log rotation at 2 MiB, 3 generations.** Tested against a 3 MB file — rotates to `.1` and starts fresh.

**`log` uses `printf '%s\n'`** instead of `echo -e`, so backslashes in messages survive.

**The `⚠️ #Clear cache` line is now a real `--clear-cache` flag** rather than a note that prints on every run.

**Default is `full-upgrade`**, matching your `install.sh`. `--safe-upgrade` gives you the old `apt-get upgrade` behaviour, and in that mode it reports what got held back so packages don't quietly pile up.

**`--dry-run`, `--skip-omb`, `--help`** added. The `BASH_SOURCE` guard is kept and now passes `"$@"` through.

Also added `/var/run/reboot-required` reporting at the end, `--ff-only` on the pull, and an age check on the oh-my-bash lock file — under an hour old it skips rather than deleting a lock something else may be holding.

One thing to decide: if you want this on a systemd timer, `sudo -v` won't help you, since there's no tty. You'd need a `/etc/sudoers.d/` entry granting NOPASSWD on `/usr/bin/apt-get` for your user. The script detects the situation and tells you rather than hanging, but it won't run unattended until you do that.
