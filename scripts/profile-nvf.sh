#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/profile-nvf.sh [options] [minimal|standard|full|all]

Build and profile flake-native external Sandvim Neovim packages without
activating Home Manager.

Options:
  -f, --flake PATH    Flake path or URI to profile (default: repository root)
  -r, --runs N        Number of headless --startuptime runs per preset (default: 5)
  -h, --help          Show this help text

Examples:
  scripts/profile-nvf.sh minimal --runs 3
  scripts/profile-nvf.sh --flake . all
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flake="path:$repo_root"
runs=5
preset="all"

while (($#)); do
  case "$1" in
    -f|--flake)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 2; }
      flake="$2"
      shift 2
      ;;
    -r|--runs)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 2; }
      runs="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    minimal|standard|full|all)
      preset="$1"
      shift
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! [[ "$runs" =~ ^[1-9][0-9]*$ ]]; then
  printf 'runs must be a positive integer: %s\n' "$runs" >&2
  exit 2
fi

case "$preset" in
  minimal) presets=(minimal) ;;
  standard) presets=(standard) ;;
  full) presets=(full) ;;
  all) presets=(minimal standard full) ;;
esac

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

median_from_timings() {
  local -a sorted
  mapfile -t sorted < <(printf '%s\n' "$@" | sort -n)
  printf '%s' "${sorted[$(((${#sorted[@]} - 1) / 2))]}"
}

for selected in "${presets[@]}"; do
  case "$selected" in
    minimal) attr="sandvimMinimal" ;;
    standard) attr="sandvimStandard" ;;
    full) attr="sandvimFull" ;;
  esac
  printf '==> Building %s (%s#%s)\n' "$selected" "$flake" "$attr"
  out_path="$(nix build --no-write-lock-file --no-link --print-out-paths "$flake#$attr")"
  printf 'closure: '
  nix path-info -Sh "$out_path"

  timings=()
  for ((run = 1; run <= runs; run++)); do
    export HOME="$tmpdir/$selected-home-$run"
    export XDG_CACHE_HOME="$tmpdir/$selected-cache-$run"
    export XDG_CONFIG_HOME="$tmpdir/$selected-config-$run"
    export XDG_DATA_HOME="$tmpdir/$selected-data-$run"
    export XDG_STATE_HOME="$tmpdir/$selected-state-$run"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

    log="$tmpdir/$selected-startuptime-$run.log"
    "$out_path/bin/nvim" --headless -n -i NONE --startuptime "$log" -c 'qa!' >/dev/null 2>&1
    if ! elapsed_ms="$(awk '
      /^[0-9]+[.][0-9]+/ { elapsed = $1; seen = 1 }
      END { if (!seen) exit 1; printf "%.0f", elapsed }
    ' "$log")"; then
      printf 'no startup timing rows found for %s run %d\n' "$selected" "$run" >&2
      exit 1
    fi
    timings+=("$elapsed_ms")
    printf 'run %d/%d: %sms\n' "$run" "$runs" "$elapsed_ms"
  done

  min_ms="$(printf '%s\n' "${timings[@]}" | sort -n | head -n1)"
  max_ms="$(printf '%s\n' "${timings[@]}" | sort -n | tail -n1)"
  median_ms="$(median_from_timings "${timings[@]}")"
  printf 'summary %s: min=%sms median=%sms max=%sms runs=%s\n' \
    "$selected" "$min_ms" "$median_ms" "$max_ms" "$runs"
  printf '\n'
done
