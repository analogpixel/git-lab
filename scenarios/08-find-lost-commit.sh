#!/usr/bin/env bash
# Scenario 08: Find and Restore a Lost Commit After Reset

scenario_name() {
    echo "Recover a Commit After Hard Reset"
}

scenario_difficulty() {
    echo "hard"
}

scenario_description() {
    cat <<'EOF'
Disaster! Someone ran 'git reset --hard' on main and lost the
most recent commit. The branch has been rewound by one commit.

The lost commit had the message "Add payment processing module"
and contained a file called 'payment.py'.

Your task:
  1. Find the lost commit using the reflog.
  2. Restore 'main' so that it points to the lost commit again.
     (main should include "Add payment processing module" as the tip)
  3. Verify that 'payment.py' exists in your working directory.

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Run: git reflog
   Look for the entry with "Add payment processing module".
   Note the SHA.

2. Run: git reset --hard <SHA>
   This moves main back to the lost commit.

Alternative:
   git reset --hard HEAD@{1}
   (if the reset was the most recent reflog action)
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Build history
    echo "# E-Commerce App" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet

    echo "def add_to_cart(item):" > cart.py
    echo "    pass" >> cart.py
    git add cart.py
    git commit -m "Add shopping cart module" --quiet

    echo "def process_payment(amount):" > payment.py
    echo "    # integrate with payment gateway" >> payment.py
    echo "    return True" >> payment.py
    git add payment.py
    git commit -m "Add payment processing module" --quiet

    git push origin main --quiet

    # Simulate the disaster: hard reset back one commit
    git reset --hard HEAD~1 --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check HEAD commit message
    local msg
    msg=$(git log -1 --pretty=%s 2>/dev/null)
    if [[ "$msg" == "Add payment processing module" ]]; then
        echo -e "  ${GREEN}[✔]${NC} HEAD is at 'Add payment processing module'"
    else
        echo -e "  ${RED}[✘]${NC} HEAD commit is '$msg', expected 'Add payment processing module'"
        pass=false
    fi

    # Check payment.py exists
    if [[ -f "payment.py" ]]; then
        echo -e "  ${GREEN}[✔]${NC} payment.py exists in working directory"
    else
        echo -e "  ${RED}[✘]${NC} payment.py is missing"
        pass=false
    fi

    # Check file is tracked
    if git show HEAD:payment.py &>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} payment.py is tracked in the commit"
    else
        echo -e "  ${RED}[✘]${NC} payment.py is not in the commit tree"
        pass=false
    fi

    $pass
}

