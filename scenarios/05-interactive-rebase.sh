#!/usr/bin/env bash
# Scenario 05: Clean Up Commits with Interactive Rebase

scenario_name() {
    echo "Squash Commits with Interactive Rebase"
}

scenario_difficulty() {
    echo "hard"
}

scenario_description() {
    cat <<'EOF'
You're on the 'feature' branch and have made 4 messy commits that
should be squashed into a single clean commit before merging.

Your task:
  1. Squash all 4 commits on 'feature' (after the branch point from
     main) into a SINGLE commit.
  2. The single commit message should be: "Add user profile feature"
  3. The final file 'profile.py' should contain all the accumulated work.
  4. Do NOT push (this branch hasn't been shared yet).

Working directory: ~/workspace/repo
EOF
}

scenario_hint() {
    cat <<'EOF'
1. Run: git log --oneline    (see the 4 commits to squash)
2. Run: git rebase -i main   (interactive rebase against main)
3. In the editor, change the first commit to 'pick' (or 'reword')
   and change the remaining 3 to 'squash' (or 's').
4. In the next editor screen, replace all commit messages with:
   Add user profile feature
5. Save and exit.
EOF
}

scenario_setup() {
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # Main branch base
    echo "# App" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    git push origin main --quiet

    # Feature branch with messy commits
    git checkout -b feature --quiet

    echo "class Profile:" > profile.py
    git add profile.py
    git commit -m "wip: start profile" --quiet

    echo "class Profile:" > profile.py
    echo "    def __init__(self, name):" >> profile.py
    echo "        self.name = name" >> profile.py
    git add profile.py
    git commit -m "wip: add constructor" --quiet

    echo "class Profile:" > profile.py
    echo "    def __init__(self, name):" >> profile.py
    echo "        self.name = name" >> profile.py
    echo "    def display(self):" >> profile.py
    echo "        print(self.name)" >> profile.py
    git add profile.py
    git commit -m "fixup add display method" --quiet

    echo "class Profile:" > profile.py
    echo "    def __init__(self, name, email):" >> profile.py
    echo "        self.name = name" >> profile.py
    echo "        self.email = email" >> profile.py
    echo "    def display(self):" >> profile.py
    echo "        print(f'{self.name} <{self.email}>')" >> profile.py
    git add profile.py
    git commit -m "oops fix display and add email" --quiet

    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    # Check we're on feature
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$branch" == "feature" ]]; then
        echo -e "  ${GREEN}[✔]${NC} On branch 'feature'"
    else
        echo -e "  ${RED}[✘]${NC} Expected branch 'feature', got '$branch'"
        pass=false
    fi

    # Check commit count (should be 1 commit beyond main)
    local count
    count=$(git rev-list main..feature --count 2>/dev/null || echo 0)
    if (( count == 1 )); then
        echo -e "  ${GREEN}[✔]${NC} Exactly 1 commit on feature beyond main"
    else
        echo -e "  ${RED}[✘]${NC} Expected 1 commit beyond main, found $count"
        pass=false
    fi

    # Check commit message
    local msg
    msg=$(git log -1 --pretty=%s 2>/dev/null)
    if [[ "$msg" == "Add user profile feature" ]]; then
        echo -e "  ${GREEN}[✔]${NC} Commit message is correct"
    else
        echo -e "  ${RED}[✘]${NC} Commit message should be 'Add user profile feature', got '$msg'"
        pass=false
    fi

    # Check profile.py has all the content
    if grep -q "self.email" profile.py 2>/dev/null && grep -q "def display" profile.py 2>/dev/null; then
        echo -e "  ${GREEN}[✔]${NC} profile.py contains all accumulated work"
    else
        echo -e "  ${RED}[✘]${NC} profile.py is missing some content"
        pass=false
    fi

    $pass
}

