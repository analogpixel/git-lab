#!/usr/bin/env bash
# Scenario 04: Undo a Bad Commit (already pushed)

scenario_name() {
    echo "Revert a Bad Commit (Pushed)"
}

scenario_difficulty() {
    echo "easy"
}

scenario_description() {
    cat <<'EOF'
Someone pushed a bad commit to 'main' that broke the config file.
Since this has already been pushed and shared, you should NOT
rewrite history (no reset / force push).

Your task:
  1. Use 'git revert' to undo the bad commit (the most recent commit
     with message "Break config with bad values").
  2. The file 'config.ini' should be restored to its correct state:
       [database]
       host=localhost
       port=5432
  3. Push the revert commit to the remote.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Run: git log --oneline   (find the bad commit)
2. Run: git revert HEAD     (revert the most recent commit)
3. Run: git push origin main
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Good commit
    cat > config.ini <<'CONF'
[database]
host=localhost
port=5432
CONF
    git add config.ini
    git commit -m "Add database config" --quiet
    git push origin main --quiet

    # Bad commit
    cat > config.ini <<'CONF'
[database]
host=BROKEN
port=WRONG
CONF
    git add config.ini
    git commit -m "Break config with bad values" --quiet
    git push origin main --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check config file is restored
    local expected
    expected=$(printf "[database]\nhost=localhost\nport=5432\n")
    local actual
    actual=$(cat config.ini 2>/dev/null || echo "")
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${GREEN}[✔]${NC} config.ini has correct values"
    else
        echo -e "  ${RED}[✘]${NC} config.ini does not have the expected content"
        pass=false
    fi

    # Check that the bad commit still exists in history (no rewrite)
    if git log --oneline | grep -q "Break config with bad values"; then
        echo -e "  ${GREEN}[✔]${NC} Bad commit preserved in history (not rewritten)"
    else
        echo -e "  ${RED}[✘]${NC} Bad commit missing from history — use 'revert', not 'reset'"
        pass=false
    fi

    # Check there's a revert commit
    if git log --oneline | grep -qi "revert"; then
        echo -e "  ${GREEN}[✔]${NC} Revert commit found"
    else
        echo -e "  ${RED}[✘]${NC} No revert commit found in history"
        pass=false
    fi

    # Check pushed
    local local_sha remote_sha
    local_sha=$(git rev-parse main 2>/dev/null)
    remote_sha=$(git -C "$REMOTE_BASE/repo.git" rev-parse main 2>/dev/null)
    if [[ "$local_sha" == "$remote_sha" ]]; then
        echo -e "  ${GREEN}[✔]${NC} Changes pushed to remote"
    else
        echo -e "  ${RED}[✘]${NC} Changes not yet pushed to remote"
        pass=false
    fi

    $pass
}

