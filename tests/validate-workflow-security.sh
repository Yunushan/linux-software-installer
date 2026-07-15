#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
WORKFLOW_DIR="$ROOT_DIR/.github/workflows"

failures=0
checks=0

pass() {
  printf 'PASS: %s\n' "$1"
  checks=$((checks + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

shopt -s nullglob
workflows=("$WORKFLOW_DIR"/*.yml "$WORKFLOW_DIR"/*.yaml)
shopt -u nullglob

if ((${#workflows[@]} == 0)); then
  printf 'FAIL: no GitHub Actions workflows found under %s\n' "$WORKFLOW_DIR" >&2
  exit 1
fi

printf 'Validating GitHub Actions workflow security invariants...\n'

checkout_count=0
checkout_validation_failed=0
for workflow in "${workflows[@]}"; do
  count=$(awk '
    /^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*actions\/checkout@/ { count++ }
    END { print count + 0 }
  ' "$workflow")
  checkout_count=$((checkout_count + count))

  if ! awk '
    function indentation(text, first_non_space) {
      first_non_space = match(text, /[^ ]/)
      return first_non_space == 0 ? length(text) : first_non_space - 1
    }

    function finish_checkout() {
      if (!in_checkout) {
        return
      }
      if (!credentials_disabled) {
        printf "  %s:%d: actions/checkout must set persist-credentials: false in its with block\n", \
          FILENAME, checkout_line > "/dev/stderr"
        errors++
      }
      in_checkout = 0
    }

    {
      sub(/\r$/, "")
      current_indent = indentation($0)

      if (in_checkout && NR != checkout_line && $0 !~ /^[[:space:]]*$/ && \
          (current_indent < action_indent || \
           (current_indent == action_indent && $0 ~ /^[[:space:]]*-/))) {
        finish_checkout()
      }

      if ($0 ~ /^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*actions\/checkout@/) {
        finish_checkout()
        in_checkout = 1
        checkout_line = NR
        action_indent = current_indent
        credentials_disabled = 0
        next
      }

      if (in_checkout && current_indent > action_indent && \
          $0 ~ /^[[:space:]]*persist-credentials:[[:space:]]*/) {
        value = $0
        sub(/^[[:space:]]*persist-credentials:[[:space:]]*/, "", value)
        sub(/[[:space:]]+#.*$/, "", value)
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        if (value == "false" || value == "\047false\047" || value == "\"false\"") {
          credentials_disabled = 1
        }
      }
    }

    END {
      finish_checkout()
      if (errors > 0) {
        exit 1
      }
    }
  ' "$workflow"; then
    checkout_validation_failed=1
  fi
done

if ((checkout_count == 0)); then
  fail 'no actions/checkout uses were found'
elif ((checkout_validation_failed != 0)); then
  fail 'one or more checkout steps can persist repository credentials'
else
  pass "all $checkout_count checkout steps disable persisted credentials"
fi

workspace_mount_failed=0
for workflow in "${workflows[@]}"; do
  if ! awk '
    {
      sub(/\r$/, "")
      if ($0 ~ /GITHUB_WORKSPACE/ && \
          ($0 ~ /:\/workspace([:[:space:]]|$)/ || \
           $0 ~ /(source|src)[[:space:]]*=/ || \
           $0 ~ /(^|[[:space:]])(-v|--volume)([=[:space:]]|$)/)) {
        printf "  %s:%d: a container source mount must not use GITHUB_WORKSPACE\n", \
          FILENAME, FNR > "/dev/stderr"
        errors++
      }
    }
    END {
      if (errors > 0) {
        exit 1
      }
    }
  ' "$workflow"; then
    workspace_mount_failed=1
  fi
done

if ((workspace_mount_failed != 0)); then
  fail 'a workflow exposes GITHUB_WORKSPACE through a container mount'
else
  pass 'no workflow mounts GITHUB_WORKSPACE into a container'
fi

container_workflow_count=0
container_validation_failed=0
for workflow in "${workflows[@]}"; do
  source_consumer_count=$(awk '
    /:\/workspace([:[:space:]]|$)/ || /target=\/workspace/ || /run-module-evidence\.sh/ { count++ }
    END { print count + 0 }
  ' "$workflow")

  if ((source_consumer_count == 0)); then
    continue
  fi
  container_workflow_count=$((container_workflow_count + 1))

  archive_count=$(awk '
    /git[[:space:]]+archive/ && /GITHUB_SHA/ && /--output=.*RUNNER_TEMP[^[:space:]]*\/source\.tar/ { count++ }
    END { print count + 0 }
  ' "$workflow")
  extract_count=$(awk '
    /tar[[:space:]]+-xf[[:space:]].*RUNNER_TEMP[^[:space:]]*\/source\.tar/ && \
      /-C[[:space:]].*RUNNER_TEMP[^[:space:]]*\/source/ { count++ }
    END { print count + 0 }
  ' "$workflow")
  git_guard_count=$(awk '
    /test[[:space:]]+![[:space:]]+-e[[:space:]].*RUNNER_TEMP[^[:space:]]*\/source\/\.git/ { count++ }
    END { print count + 0 }
  ' "$workflow")

  if ((archive_count < source_consumer_count || \
    extract_count < source_consumer_count || \
    git_guard_count < source_consumer_count)); then
    printf '  %s: %d container source consumer(s), but %d archive(s), %d extraction(s), and %d .git guard(s)\n' \
      "$workflow" "$source_consumer_count" "$archive_count" "$extract_count" \
      "$git_guard_count" >&2
    container_validation_failed=1
  fi

  if ! awk '
    /:\/workspace([:[:space:]]|$)/ || /target=\/workspace/ {
      line = $0
      sub(/\r$/, "", line)
      if (line !~ /RUNNER_TEMP[^[:space:]]*\/source/) {
        printf "  %s:%d: container /workspace source is not the RUNNER_TEMP archive export\n", \
          FILENAME, FNR > "/dev/stderr"
        errors++
      }
    }
    END {
      if (errors > 0) {
        exit 1
      }
    }
  ' "$workflow"; then
    container_validation_failed=1
  fi

  if ! awk '
    function inspect_call_line(text) {
      if (text ~ /GITHUB_WORKSPACE/) {
        call_uses_workspace = 1
      }
      if (text ~ /RUNNER_TEMP[^[:space:]]*\/source/) {
        call_uses_export = 1
      }
    }

    function finish_call() {
      if (!in_call) {
        return
      }
      if (call_uses_workspace || !call_uses_export) {
        printf "  %s:%d: run-module-evidence.sh must receive RUNNER_TEMP/source, never GITHUB_WORKSPACE\n", \
          FILENAME, call_line > "/dev/stderr"
        errors++
      }
      in_call = 0
    }

    {
      sub(/\r$/, "")
      if (in_call) {
        inspect_call_line($0)
        if ($0 !~ /\\[[:space:]]*$/) {
          finish_call()
        }
        next
      }

      if ($0 ~ /run-module-evidence\.sh/) {
        in_call = 1
        call_line = FNR
        call_uses_workspace = 0
        call_uses_export = 0
        inspect_call_line($0)
        if ($0 !~ /\\[[:space:]]*$/) {
          finish_call()
        }
      }
    }

    END {
      finish_call()
      if (errors > 0) {
        exit 1
      }
    }
  ' "$workflow"; then
    container_validation_failed=1
  fi
done

if ((container_workflow_count == 0)); then
  fail 'no workflows with container source consumers were found'
elif ((container_validation_failed != 0)); then
  fail 'one or more container workflows lack a credential-free source export'
else
  pass "all $container_workflow_count container workflows use verified git archive source exports"
fi

upload_targets=(
  "$WORKFLOW_DIR/install-smoke.yml"
  "$WORKFLOW_DIR/module-evidence.yml"
)
upload_count=0
upload_validation_failed=0
for workflow in "${upload_targets[@]}"; do
  if [[ ! -f $workflow ]]; then
    printf '  missing required evidence workflow: %s\n' "$workflow" >&2
    upload_validation_failed=1
    continue
  fi

  count=$(awk '
    /^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*actions\/upload-artifact@/ { count++ }
    END { print count + 0 }
  ' "$workflow")
  upload_count=$((upload_count + count))

  if ! awk '
    function indentation(text, first_non_space) {
      first_non_space = match(text, /[^ ]/)
      return first_non_space == 0 ? length(text) : first_non_space - 1
    }

    function check_path(text, line_number, lowered) {
      lowered = tolower(text)
      if (lowered ~ /(raw-evidence|raw-installer-logs|evidence-raw|lsi_raw_evidence_root)/) {
        printf "  %s:%d: upload-artifact path includes a raw evidence root\n", \
          FILENAME, line_number > "/dev/stderr"
        errors++
      }
    }

    function finish_upload() {
      if (!in_upload) {
        return
      }
      if (!saw_path) {
        printf "  %s:%d: upload-artifact step has no path to validate\n", \
          FILENAME, upload_line > "/dev/stderr"
        errors++
      }
      in_upload = 0
      in_path_block = 0
    }

    {
      sub(/\r$/, "")
      current_indent = indentation($0)

      if (in_upload && FNR != upload_line && $0 !~ /^[[:space:]]*$/ && \
          (current_indent < action_indent || \
           (current_indent == action_indent && $0 ~ /^[[:space:]]*-/))) {
        finish_upload()
      }

      if ($0 ~ /^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*actions\/upload-artifact@/) {
        finish_upload()
        in_upload = 1
        upload_line = FNR
        action_indent = current_indent
        saw_path = 0
        next
      }

      if (!in_upload) {
        next
      }

      if (in_path_block && $0 !~ /^[[:space:]]*$/ && current_indent <= path_indent) {
        in_path_block = 0
      }
      if (in_path_block && current_indent > path_indent) {
        check_path($0, FNR)
        next
      }

      if (current_indent > action_indent && $0 ~ /^[[:space:]]*path:[[:space:]]*/) {
        saw_path = 1
        path_indent = current_indent
        value = $0
        sub(/^[[:space:]]*path:[[:space:]]*/, "", value)
        check_path(value, FNR)
        if (value ~ /^[|>][-+0-9]*[[:space:]]*(#.*)?$/) {
          in_path_block = 1
        }
      }
    }

    END {
      finish_upload()
      if (errors > 0) {
        exit 1
      }
    }
  ' "$workflow"; then
    upload_validation_failed=1
  fi
done

if ((upload_count == 0)); then
  fail 'no evidence upload-artifact steps were found'
elif ((upload_validation_failed != 0)); then
  fail 'an evidence workflow can upload a raw container-controlled tree'
else
  pass "all $upload_count evidence upload paths exclude raw evidence roots"
fi

if ((failures > 0)); then
  printf 'Workflow security validation failed: %d invariant group(s) failed.\n' \
    "$failures" >&2
  exit 1
fi

printf 'Workflow security validation passed: %d invariant groups checked.\n' "$checks"
