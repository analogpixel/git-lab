#!/usr/bin/env bash
# Scenario 06: Cherry-Pick a Specific Commit

scenario_name() {
    echo "Cherry-Pick a Hotfix"
}

scenario_difficulty() {
    echo "medium"
}

scenario_description() {
    cat <<'EOF'
A critical bug fix was made on the 'develop' branch (the commit
with message "Fix critical security bug"). You need to apply ONLY
that specific fix to 'main' without bringing in the other develop
commits.

Your task:
  1. You are on 'main'.
  2. Cherry-pick the commit with message "Fix critical security bug"
     from the 'develop' branch onto 'main'.
  3. Push main to the remote.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Find the commit SHA:
   git log develop --oneline
   (look for "Fix critical security bug")

2. Cherry-pick it:
   git cherry-pick <SHA>

3. Push:
   git push origin main
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Initial main
    echo "app v1.0" > app.py
    echo "# no bugs here" > security.py
    git add app.py security.py
    git commit -m "Initial release v1.0" --quiet
    git push origin main --quiet

    # Develop branch with multiple commits
    git checkout -b develop --quiet

    echo "app v1.1-dev" > app.py
    git add app.py
    git commit -m "Start v1.1 development" --quiet

    echo "new experimental feature" > experiment.py
    git add experiment.py
    git commit -m "Add experimental feature" --quiet

    # The critical fix
    echo "# security patch applied" > security.py
    echo "def sanitize(input):" >> security.py
    echo "    return escape(input)" >> security.py
    git add security.py
    git commit -m "Fix critical security bug" --quiet

    echo "more dev work" > dev-notes.txt
    git add dev-notes.txt
    git commit -m "Add development notes" --quiet

    git push origin develop --quiet

    # Back to main
    git checkout main --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check on main
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$branch" == "main" ]]; then
        echo -e "  ${GREEN}[✔]${NC} On branch 'main'"
    else
        echo -e "  ${RED}[✘]${NC} Not on 'main'"
        pass=false
    fi

    # Check security.py has the fix
    if grep -q "sanitize" security.py 2>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} security.py contains the security fix"
    else
        echo -e "  ${RED}[✘]${NC} security.py does not contain the security fix"
        pass=false
    fi

    # Check that experiment.py does NOT exist on main (only the fix, not other commits)
    if [[ ! -f "experiment.py" ]]; then
        echo -e "  ${GREEN}[✔]${NC} No unrelated develop files on main (clean cherry-pick)"
    else
        echo -e "  ${RED}[✘]${NC} experiment.py found — you brought more than just the fix"
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

