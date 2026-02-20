#!/usr/bin/env bash
# Scenario 03: Recover a Deleted Branch

scenario_name() {
    echo "Recover a Deleted Branch"
}

scenario_difficulty() {
    echo "medium"
}

scenario_description() {
    cat <<'EOF'
A colleague accidentally deleted the 'feature-login' branch which
contained important work that was never merged to main.
The branch was deleted just moments ago.

Your task:
  1. Recover the deleted 'feature-login' branch with ALL its commits.
  2. The recovered branch must be named exactly 'feature-login'.

Hint: Git doesn't immediately garbage-collect deleted branches.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Use: git reflog
   to find the commit that 'feature-login' pointed to before deletion.
   Look for entries mentioning 'feature-login'.

2. Once you find the SHA, run:
   git branch feature-login <SHA>
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Initial commit on main
    echo "# My App" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    git push origin main --quiet

    # Create feature-login branch with several commits
    git checkout -b feature-login --quiet
    echo "def login():" > login.py
    git add login.py
    git commit -m "Add login function stub" --quiet

    echo "def login(user, password):" > login.py
    echo "    return authenticate(user, password)" >> login.py
    git add login.py
    git commit -m "Implement login logic" --quiet

    echo "def login(user, password):" > login.py
    echo "    if not user or not password:" >> login.py
    echo "        raise ValueError('Missing credentials')" >> login.py
    echo "    return authenticate(user, password)" >> login.py
    git add login.py
    git commit -m "Add input validation to login" --quiet

    # Go back to main
    git checkout main --quiet

    # Delete the branch (this is the "accident")
    git branch -D feature-login --quiet 2>&1

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check branch exists
    if git show-ref --verify --quiet refs/heads/feature-login 2>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} Branch 'feature-login' exists"
    else
        echo -e "  ${RED}[✘]${NC} Branch 'feature-login' does not exist"
        pass=false
        $pass
        return
    fi

    # Check it has the login.py with validation
    local content
    content=$(git show feature-login:login.py 2>/dev/null || echo "")
    if echo "$content" | grep -q "raise ValueError"; then
        echo -e "  ${GREEN}[✔]${NC} login.py contains input validation (all commits recovered)"
    else
        echo -e "  ${RED}[✘]${NC} login.py is missing input validation — not all commits recovered"
        pass=false
    fi

    # Check commit count on the branch (should have 3 commits beyond initial)
    local count
    count=$(git rev-list main..feature-login --count 2>/dev/null || echo 0)
    if (( count == 3 )); then
        echo -e "  ${GREEN}[✔]${NC} Branch has all 3 commits"
    else
        echo -e "  ${RED}[✘]${NC} Expected 3 commits on feature-login (beyond main), found $count"
        pass=false
    fi

    $pass
}

