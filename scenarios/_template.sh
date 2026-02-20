#!/usr/bin/env bash
#
# SCENARIO TEMPLATE
#
# Copy this file and rename it with a numeric prefix:
#   cp _template.sh 09-my-scenario.sh
#
# Every scenario MUST define these functions:
#   scenario_name        -> short human-readable title
#   scenario_difficulty   -> "easy", "medium", or "hard"
#   scenario_description -> printed instructions for the user
#   scenario_hint        -> one or more hints
#   scenario_setup       -> all git commands to build the scenario state
#   scenario_check       -> return 0 if solved, non-zero if not
#
# Available environment variables:
#   $REMOTE_BASE  — path for bare repos, e.g., /srv/git
#   $WORKSPACE    — user's working directory, e.g., /home/student/workspace
#
# Conventions:
#   - Create bare remote(s) under $REMOTE_BASE/  (e.g., $REMOTE_BASE/repo.git)
#   - Clone / init the local repo inside $WORKSPACE/
#   - At the end of setup, `cd` into the working repo so the user lands there
#   - Use `git -C <path>` when operating on repos outside the current dir
#   - All output during setup is visible to the user — keep it clean
#   - scenario_check should print clear pass/fail messages for each assertion
#

scenario_name() {
    echo "Template Scenario (rename me)"
}

scenario_difficulty() {
    echo "easy"   # easy | medium | hard
}

scenario_description() {
    cat <<'EOF'
Describe the situation the user is in and what they need to accomplish.

Be specific about the desired end state so scenario_check can verify it.

Your task:
  1. Do something specific
  2. Do something else specific
EOF
}

scenario_hint() {
    cat <<'EOF'
Try: git <some-command>
Read: git <some-command> --help
EOF
}

scenario_setup() {
    # --------------------------------------------------
    # 1. Create the "remote" bare repository
    # --------------------------------------------------
    git init --bare "$REMOTE_BASE/repo.git" --quiet

    # --------------------------------------------------
    # 2. Clone it into the workspace as the "local" repo
    # --------------------------------------------------
    git clone "$REMOTE_BASE/repo.git" "$WORKSPACE/repo" --quiet
    cd "$WORKSPACE/repo"

    # --------------------------------------------------
    # 3. Build whatever history / state is needed
    # --------------------------------------------------
    echo "hello" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    git push origin main --quiet

    # --------------------------------------------------
    # 4. Leave the user in the working repo
    # --------------------------------------------------
    cd "$WORKSPACE/repo"
}

scenario_check() {
    cd "$WORKSPACE/repo"

    local pass=true

    # Example check
    if [[ -f "file.txt" ]]; then
        echo -e "  ${GREEN}[✔]${NC} file.txt exists"
    else
        echo -e "  ${RED}[✘]${NC} file.txt is missing"
        pass=false
    fi

    $pass
}

