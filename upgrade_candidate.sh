#!/usr/bin/env bash
#
# Unattended system + Oh My Bash updater.
#
# Usage:
#   ./upgrade.sh                 full run (apt full-upgrade, autoremove, omb)
#   ./upgrade.sh --dry-run       show what would happen, change nothing
#   ./upgrade.sh --safe-upgrade  use `apt-get upgrade` instead of full-upgrade
#   ./upgrade.sh --skip-omb      system packages only
#   ./upgrade.sh --clear-cache   wipe /var/lib/apt/lists before updating
#
# Safe to run from cron or a systemd timer: never prompts, holds a lock,
# and waits for apt rather than failing if another process owns it.
#
# Can also be sourced to use the individual functions interactively.

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

# apt's own -y does not cover dpkg conffile prompts or needrestart.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a          # auto-restart services, never prompt
export NEEDRESTART_SUSPEND=1       # belt and braces for older needrestart

LOG_FILE="${LOG_FILE:-$HOME/custom-update.log}"
LOCK_FILE="${LOCK_FILE:-${XDG_RUNTIME_DIR:-/tmp}/custom-update.lock}"
LOG_MAX_BYTES=$(( 2 * 1024 * 1024 ))   # rotate at 2 MiB
LOG_KEEP=3                             # keep this many rotated logs

APT_LOCK_TIMEOUT=300                   # seconds to wait for the dpkg lock

DRY_RUN=0
SKIP_OMB=0
CLEAR_CACHE=0
UPGRADE_CMD="full-upgrade"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

rotate_log() {
    [[ -f "$LOG_FILE" ]] || return 0
    local size
    size=$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)
    (( size < LOG_MAX_BYTES )) && return 0

    local i
    for (( i = LOG_KEEP - 1; i >= 1; i-- )); do
        [[ -f "${LOG_FILE}.${i}" ]] && mv -f "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
    done
    mv -f "$LOG_FILE" "${LOG_FILE}.1"
    rm -f "${LOG_FILE}.$((LOG_KEEP+1))"
}

# printf, not `echo -e` — an arbitrary message must not be escape-interpreted.
log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

log_err() {
    printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2
}

on_error() {
    local code=$? line=$1
    log_err "Unhandled failure at line ${line} (exit ${code})."
}
trap 'on_error $LINENO' ERR

# ---------------------------------------------------------------------------
# apt wrappers
# ---------------------------------------------------------------------------

# apt-get, not apt: apt prints "does not have a stable CLI interface" and its
# output format is not guaranteed between releases.
#
# DPkg::Lock::Timeout makes apt wait for unattended-upgrades or another apt
# instead of failing instantly with "could not get lock".
apt_run() {
    if (( DRY_RUN )); then
        log "[dry-run] sudo apt-get $*"
        return 0
    fi
    sudo apt-get -o "DPkg::Lock::Timeout=${APT_LOCK_TIMEOUT}" "$@" 2>&1 | tee -a "$LOG_FILE"
}

update() {
    log "Updating package index..."
    apt_run update -qq
}

upgrade() {
    # Explicit failure propagation. When this function is called from an `if`
    # condition, errexit is suspended for its whole body, so a failing
    # `update` would otherwise fall through to the upgrade.
    update || { log_err "Package index update failed; refusing to upgrade against a stale index."; return 1; }

    log "Upgrading installed packages (apt-get ${UPGRADE_CMD})..."
    apt_run "$UPGRADE_CMD" -y || return 1

    # Surface held-back packages — `upgrade` silently defers anything needing
    # a new dependency or a removal.
    if [[ "$UPGRADE_CMD" == "upgrade" ]]; then
        local held
        held=$(apt-get --just-print upgrade 2>/dev/null | awk '/^Inst /{print $2}' | tr '\n' ' ')
        [[ -n "${held// }" ]] && log "Note: still upgradable (try --full): ${held}"
    fi
    return 0
}

autoremove() {
    log "Removing unnecessary packages..."
    apt_run autoremove --purge -y
}

clear_cache() {
    log "Clearing apt lists cache..."
    if (( DRY_RUN )); then
        log "[dry-run] sudo rm -rf /var/lib/apt/lists/*"
        return 0
    fi
    sudo rm -rf /var/lib/apt/lists/*
}

check_reboot_required() {
    if [[ -f /var/run/reboot-required ]]; then
        local pkgs=""
        [[ -f /var/run/reboot-required.pkgs ]] && pkgs=$(tr '\n' ' ' < /var/run/reboot-required.pkgs)
        log "REBOOT REQUIRED${pkgs:+ (}${pkgs}${pkgs:+)}"
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Oh My Bash
# ---------------------------------------------------------------------------

update_oh_my_bash() {
    local OSH="${OSH:-$HOME/.oh-my-bash}"

    if [[ ! -d "$OSH/.git" ]]; then
        log "Oh My Bash not found (or not a git checkout) at ${OSH}. Skipping."
        return 0
    fi

    log "Updating Oh My Bash..."

    if (( DRY_RUN )); then
        log "[dry-run] would git pull --ff-only in ${OSH}"
        return 0
    fi

    # Only clear a stale lock, not one a live process is holding.
    local lock="${OSH}/log/update.lock"
    if [[ -f "$lock" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$lock" 2>/dev/null || echo 0) ))
        if (( age > 3600 )); then
            log "Removing stale update lock (${age}s old)."
            rm -f "$lock"
        else
            log "Recent update lock present (${age}s old); another update may be running. Skipping."
            return 0
        fi
    fi

    # Subshell + cd instead of pushd/popd: the directory stack cannot leak,
    # whatever happens inside.
    (
        cd "$OSH" || exit 1

        local stash_ref=""

        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log "Stashing local Oh My Bash modifications..."
            if git stash push -u -m "upgrade.sh $(date +%Y-%m-%dT%H:%M:%S)" >>"$LOG_FILE" 2>&1; then
                stash_ref=$(git rev-parse -q --verify stash@{0} || true)
            else
                log_err "Could not stash local changes. Aborting Oh My Bash update."
                exit 1
            fi
        fi

        # Restore the stash on EVERY exit path. The original only popped it
        # on success, so a failed pull silently swallowed local edits.
        restore_stash() {
            [[ -z "$stash_ref" ]] && return 0
            log "Restoring stashed changes..."
            if git stash pop >>"$LOG_FILE" 2>&1; then
                log "Stashed changes reapplied."
            else
                log_err "Stash pop conflicted. Your changes are safe in: git stash list"
                log_err "Resolve manually in ${OSH}"
                return 1
            fi
        }

        # --ff-only: never create a merge commit in a repo you don't own.
        if git pull --ff-only >>"$LOG_FILE" 2>&1; then
            log "Oh My Bash updated to $(git rev-parse --short HEAD)."
            restore_stash || exit 1
        else
            log_err "git pull failed (diverged history, or network)."
            restore_stash || true
            exit 1
        fi
    ) || return 1

    # Deliberately NOT sourcing oh-my-bash.sh. It would only affect this
    # script's shell, not your terminal, and it sets PS1 / references
    # variables that abort under `set -u`.
    log "Open a new shell to pick up the updated Oh My Bash."
    return 0
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

preflight() {
    if [[ $EUID -eq 0 ]]; then
        log_err "Do not run as root; this writes into \$HOME and calls sudo itself."
        return 1
    fi

    command -v sudo >/dev/null 2>&1 || { log_err "sudo not installed."; return 1; }

    (( DRY_RUN )) && return 0

    # Prime the sudo timestamp up front. Without this the script blocks on a
    # password prompt partway through — invisible under cron or a timer.
    if ! sudo -n true 2>/dev/null; then
        if [[ ! -t 0 ]]; then
            log_err "sudo needs a password and there is no terminal to ask on."
            log_err "Configure NOPASSWD for apt-get, or run this interactively."
            return 1
        fi
        log "Requesting sudo..."
        sudo -v || return 1
    fi

    # Keep the timestamp alive; die with the parent.
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

usage() {
    sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

main() {
    while (( $# )); do
        case "$1" in
            --dry-run)      DRY_RUN=1; shift ;;
            --safe-upgrade) UPGRADE_CMD="upgrade"; shift ;;
            --full)         UPGRADE_CMD="full-upgrade"; shift ;;
            --skip-omb)     SKIP_OMB=1; shift ;;
            --clear-cache)  CLEAR_CACHE=1; shift ;;
            -h|--help)      usage; return 0 ;;
            *)              log_err "Unknown option: $1"; usage; return 1 ;;
        esac
    done

    rotate_log

    # Script-level lock: two concurrent runs would fight over the dpkg lock.
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        log_err "Another run is already in progress (${LOCK_FILE}). Exiting."
        return 1
    fi

    log "=== Update run started ==="
    (( DRY_RUN )) && log "DRY RUN — nothing will be changed."

    preflight || return 1

    local status=0

    (( CLEAR_CACHE )) && { clear_cache || status=1; }

    if ! upgrade;    then log_err "Package upgrade failed."; status=1; fi
    if ! autoremove; then log_err "Autoremove failed.";      status=1; fi

    if (( SKIP_OMB )); then
        log "Skipping Oh My Bash (--skip-omb)."
    elif ! update_oh_my_bash; then
        log_err "Oh My Bash update failed."
        status=1
    fi

    check_reboot_required || true

    if (( status == 0 )); then
        log "=== All updates completed successfully. ==="
    else
        log "=== Some steps failed. See ${LOG_FILE} ==="
    fi

    return "$status"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi