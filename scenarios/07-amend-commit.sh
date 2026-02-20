#!/usr/bin/env bash
# Scenario 07: Amend the Last Commit

scenario_name() {
    echo "Amend a Commit (Unpushed)"
}

scenario_difficulty() {
    echo "easy"
}

scenario_description() {
    cat <<'EOF'
You just made a commit but realized you forgot to include a file,
and the commit message has a typo.

Your task:
  1. The file 'utils.py' is in the working directory but was NOT
     included in the last commit. Add it.
  2. Change the last commit message from "Add halper module" to
     "Add helper module".
  3. This should all be done as an amendment to the EXISTING commit
     (not a new commit). There should be exactly 2 commits total.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Stage the forgotten file:
   git add utils.py

2. Amend the commit with a corrected message:
   git commit --amend -m "Add helper module"
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # First commit
    echo "# My Project" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet

    # Second commit — oops, forgot utils.py and typo in message
    echo "def help():" > helper.py
    echo "    pass" >> helper.py
    git add helper.py
    git commit -m "Add halper module" --quiet

    # The forgotten file (not staged, not committed)
    echo "def utility():" > utils.py
    echo "    pass" >> utils.py

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check commit count
    local count
    count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
    if (( count == 2 )); then
        echo -e "  ${GREEN}[✔]${NC} Exactly 2 commits (amended, not new)"
    else
        echo -e "  ${RED}[✘]${NC} Expected 2 commits, found $count"
        pass=false
    fi

    # Check commit message
    local msg
    msg=$(git log -1 --pretty=%s 2>/dev/null)
    if [[ "$msg" == "Add helper module" ]]; then
        echo -e "  ${GREEN}[✔]${NC} Commit message corrected to 'Add helper module'"
    else
        echo -e "  ${RED}[✘]${NC} Commit message is '$msg', expected 'Add helper module'"
        pass=false
    fi

    # Check utils.py is tracked in the last commit
    if git show HEAD:utils.py &>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} utils.py is included in the last commit"
    else
        echo -e "  ${RED}[✘]${NC} utils.py is not in the last commit"
        pass=false
    fi

    $pass
}

