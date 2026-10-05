#!/usr/bin/env bash
# Dumps every commit reachable from any local branch as plain-text records, oldest first,
# for the generate-user-stories skill to group into stories.
#
# Why a script rather than letting the model run git ad hoc: the commit URL, the pushed/unpushed
# flag and the branch list must be exact — they are the proof a time tracker gets pointed at —
# and a model re-deriving them per commit is where a hash gets truncated or a link invented.
#
# Usage: collect-commits.sh [author-regex]   (extended regex over name/email; default: git config
# user.email). One person often commits under several identities, e.g. a work and a personal
# address, so pass an alternation such as 'work@corp.com|personal-handle' to catch all of them.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
author="${1:-$(git config user.email || true)}"

# Normalise the origin remote into a browsable web base. Handles https://, http:// and
# scp-style git@host:path. GitLab uses /-/commit/, GitHub and everything else /commit/.
remote="$(git remote get-url origin 2>/dev/null || true)"
web=""
if [[ -n "$remote" ]]; then
  web="$remote"
  web="${web%.git}"
  if [[ "$web" =~ ^git@([^:]+):(.+)$ ]]; then web="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"; fi
  web="${web#ssh://git@}"; [[ "$web" =~ ^https?:// ]] || web="https://$web"
  web="$(sed -E 's#//[^/@]+@#//#' <<<"$web")"   # strip embedded credentials
fi
case "$web" in
  *github.com*) commit_path="commit" ;;
  "")           commit_path="" ;;
  *)            commit_path="-/commit" ;;   # GitLab (self-hosted included)
esac

# A commit is only linkable if the remote has it. Anything not reachable from a remote-tracking
# ref will 404 until pushed, so it is flagged rather than silently given a dead link.
remote_refs="$(git for-each-ref --format='%(refname)' refs/remotes | grep -v '/HEAD$' || true)"
pushed_set="$( [[ -n "$remote_refs" ]] && git rev-list $remote_refs || true )"

echo "REPO: $(basename "$PWD")"
echo "REMOTE_WEB: ${web:-none}"
echo "AUTHOR_FILTER: ${author:-none}"
echo "CURRENT_BRANCH: $(git branch --show-current)"
echo

# %x1e separates records so commit bodies with blank lines survive the loop.
git log --branches --no-merges --reverse --extended-regexp ${author:+--author="$author"} \
    --date=iso-strict --format='%H%x1f%ad%x1f%an%x1f%s%x1f%b%x1e' |
while IFS=$'\x1f' read -r -d $'\x1e' hash date name subject body; do
  hash="${hash//$'\n'/}"
  [[ -z "$hash" ]] && continue
  branches="$(git branch --contains "$hash" --format='%(refname:short)' | paste -sd, -)"
  if grep -qx "$hash" <<<"$pushed_set"; then pushed=yes; else pushed=no; fi
  url=""; [[ -n "$commit_path" ]] && url="$web/$commit_path/$hash"
  stat="$(git show --shortstat --format= "$hash" | sed 's/^ *//')"
  files="$(git show --name-only --format= "$hash" | head -15 | paste -sd' ' -)"
  echo "=== COMMIT ${hash:0:7}"
  echo "hash: $hash"
  echo "date: $date"
  echo "author: $name"
  echo "pushed: $pushed"
  echo "url: ${url:-none}"
  echo "branches: $branches"
  echo "subject: $subject"
  echo "stat: $stat"
  echo "files: $files"
  # Bodies are truncated: enough to explain the why, not a full essay per commit.
  echo "body:"
  grep -vE '^(✨ Generated with|Claude-Session:|Co-Authored-By:)' <<<"$body" | sed '/^$/N;/^\n$/D' | head -25 | sed 's/^/  /'
  echo
done
