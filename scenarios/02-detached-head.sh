#!/usr/bin/env bash
# Scenario 02: Fix a Detached HEAD

scenario_name() {
    echo "Fix a Detached HEAD"
}

scenario_difficulty() {
    echo "easy"
}

scenario_description() {
    cat <<'EOF'
Oh no! You checked out a specific commit and now you're in
"detached HEAD" state. Worse, you've already made a commit here
that you don't want to lose.

Your task:
  1. You are in detached HEAD state with one new commit.
  2. Create a new branch called 'rescue' from your current position
     so the commit is saved.
  3. Then switch back to 'main'.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Run: git branch rescue
   (this creates a branch at your current detached HEAD)
2. Run: git checkout main
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Build some history
    echo "version 1" > data.txt
    git add data.txt
    git commit -m "First commit" --quiet
    git push origin main --quiet

    echo "version 2" > data.txt
    git add data.txt
    git commit -m "Second commit" --quiet
    git push origin main --quiet

    echo "version 3" > data.txt
    git add data.txt
    git commit -m "Third commit" --quiet
    git push origin main --quiet

    # Detach HEAD at the first commit
    local first_commit
    first_commit=$(git rev-list --max-parents=0 HEAD)
    git checkout "$first_commit" --quiet 2>&1

    # Make a new commit in detached state
    echo "important new work" > rescue-me.txt
    git add rescue-me.txt
    git commit -m "Important work done in detached HEAD" --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check 'rescue' branch exists
    if git show-ref --verify --quiet refs/heads/rescue 2>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} Branch 'rescue' exists"
    else
        echo -e "  ${RED}[✘]${NC} Branch 'rescue' does not exist"
        pass=false
    fi

    # Check rescue branch has the rescue-me.txt file
    if git show rescue:rescue-me.txt &>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} Branch 'rescue' contains rescue-me.txt"
    else
        echo -e "  ${RED}[✘]${NC} Branch 'rescue' does not contain rescue-me.txt"
        pass=false
    fi

    # Check we're on main now
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$branch" == "main" ]]; then
        echo -e "  ${GREEN}[✔]${NC} Currently on branch 'main'"
    else
        echo -e "  ${RED}[✘]${NC} Expected to be on 'main', but on '$branch'"
        pass=false
    fi

    $pass
}

