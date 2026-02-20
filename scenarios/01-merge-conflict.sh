#!/usr/bin/env bash
# Scenario 01: Resolve a Merge Conflict

scenario_name() {
    echo "Resolve a Merge Conflict"
}

scenario_difficulty() {
    echo "easy"
}

scenario_description() {
    cat <<'EOF'
Two branches have made conflicting changes to the same file.
You need to merge the 'feature' branch into 'main' and resolve
the conflict.

Your task:
  1. You are on the 'main' branch.
  2. Merge the 'feature' branch into 'main'.
  3. Resolve the conflict in 'app.txt' so that BOTH changes
     are kept — the main line first, then the feature line.
     The file should contain exactly:
       main change
       feature change
  4. Complete the merge commit.
  5. Push to the remote.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Run: git merge feature
2. Open app.txt and remove the conflict markers (<<<<<<<, =======, >>>>>>>).
   Make the file contain both lines.
3. Run: git add app.txt
4. Run: git commit   (accept or edit the merge message)
5. Run: git push origin main
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Initial commit on main
    echo "initial content" > app.txt
    git add app.txt
    git commit -m "Initial commit" --quiet
    git push origin main --quiet

    # Create feature branch and make a change
    git checkout -b feature --quiet
    echo "feature change" > app.txt
    git add app.txt
    git commit -m "Feature: update app.txt" --quiet
    git push origin feature --quiet

    # Back to main and make a conflicting change
    git checkout main --quiet
    echo "main change" > app.txt
    git add app.txt
    git commit -m "Main: update app.txt" --quiet
    git push origin main --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check we're on main
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$branch" == "main" ]]; then
        echo -e "  ${GREEN}[✔]${NC} On branch 'main'"
    else
        echo -e "  ${RED}[✘]${NC} Expected branch 'main', got '$branch'"
        pass=false
    fi

    # Check no merge in progress
    if [[ ! -f ".git/MERGE_HEAD" ]]; then
        echo -e "  ${GREEN}[✔]${NC} No merge in progress (merge completed)"
    else
        echo -e "  ${RED}[✘]${NC} Merge is still in progress — complete the merge commit"
        pass=false
    fi

    # Check file contents
    local expected
    expected=$(printf "main change\nfeature change\n")
    local actual
    actual=$(cat app.txt 2>/dev/null || echo "")
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${GREEN}[✔]${NC} app.txt has correct contents"
    else
        echo -e "  ${RED}[✘]${NC} app.txt contents are incorrect"
        echo "       Expected:"
        echo "         main change"
        echo "         feature change"
        pass=false
    fi

    # Check no conflict markers
    if ! grep -qE '^(<<<<<<<|=======|>>>>>>>)' app.txt 2>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} No conflict markers in app.txt"
    else
        echo -e "  ${RED}[✘]${NC} Conflict markers still present in app.txt"
        pass=false
    fi

    # Check pushed to remote
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

