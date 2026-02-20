agents.md
Plaintext

# agents.md — Guide for LLM Agents: Creating Git Lab Scenarios

This document instructs future LLM sessions on how to create new scenarios
for the Git Laboratory (`git-lab`) system.

## Overview

The Git Lab is a Docker-based interactive environment where users practice
solving Git problems. Each scenario is a self-contained Bash script that:

1. Sets up a Git state (repos, branches, commits, conflicts, etc.)
2. Describes the problem to the user
3. Provides hints on demand
4. Verifies the user's solution programmatically

## Architecture

/opt/git-lab/
├── git-lab.sh # Main menu and orchestrator (DO NOT MODIFY)
├── agents.md # This file
└── scenarios/
├── _template.sh # Scenario template
├── 01-merge-conflict.sh
├── 02-detached-head.sh
└── ...
Plaintext


Key paths available to scenarios as environment variables:

| Variable      | Path                       | Purpose                        |
|---------------|----------------------------|--------------------------------|
| `$REMOTE_BASE`| `/srv/git`                 | "Remote" bare repositories     |
| `$WORKSPACE`  | `/home/student/workspace`  | User's local working directory |

## How to Create a New Scenario

### Step 1: Choose a Filename

Use the format `NN-short-description.sh` where `NN` is a zero-padded number.
Place it in `/opt/git-lab/scenarios/`. The menu auto-discovers files matching
`[0-9][0-9]-*.sh`.

### Step 2: Define the Required Functions

Every scenario MUST implement these 6 functions:

#### `scenario_name`
Returns a short human-readable title (one line, under 45 characters).

```bash
scenario_name() {
    echo &quot;Resolve a Merge Conflict&quot;
}

scenario_difficulty

Returns one of: easy, medium, hard.
Bash

scenario_difficulty() {
    echo &quot;medium&quot;
}

scenario_description

Prints the full task description shown to the user. Must include:

    Context: what happened and why it's a problem
    Numbered task list: exactly what the user must do
    Specific expected end state (so scenario_check can verify it)
    Working directory path

Bash

scenario_description() {
    cat &lt;&lt;&#x27;EOF&#x27;
&lt;Context paragraph&gt;

Your task:

1. &lt;specific instruction&gt;
2. &lt;specific instruction&gt;
  ...

Working directory: ~/workspace/repo
EOF
}

scenario_hint

Prints hints. Can be multi-level (basic hint first, more specific after).
Reference specific git commands.
Bash

scenario_hint() {
    cat &lt;&lt;&#x27;EOF&#x27;

1. Try: git &lt;command&gt;
2. Then: git &lt;other-command&gt;
EOF
}

scenario_setup

Runs all Git commands to construct the scenario. This is the core of
the scenario. Rules:

    Always start by creating a bare remote:

Bash

git init --bare &quot;$REMOTE_BASE/repo.git&quot; --quiet

    Clone into workspace:

Bash

git clone &quot;$REMOTE_BASE/repo.git&quot; &quot;$WORKSPACE/repo&quot; --quiet
cd &quot;$WORKSPACE/repo&quot;

    Build the git state — commits, branches, conflicts, etc.
        Use --quiet on git commands to reduce noise
        Use realistic file names and content
        Each commit should have a clear, distinct message

    End in the correct directory so the user starts in the right place:

Bash

cd &quot;$WORKSPACE/repo&quot;

    Multiple remotes / repos: If needed, create additional bare repos
    under $REMOTE_BASE (e.g., $REMOTE_BASE/upstream.git) or additional
    clones under $WORKSPACE.

scenario_check

Validates the user's solution. Must:

    Return exit code 0 if solved, non-zero if not
    Print per-check pass/fail messages using colored output
    Use this pattern:

Bash

scenario_check() {
    cd &quot;$WORKSPACE/repo&quot;

    local pass=true
    local RED=&#x27;\033[0;31m&#x27;
    local GREEN=&#x27;\033[0;32m&#x27;
    local NC=&#x27;\033[0m&#x27;

    # Check 1: description
    if &lt;condition&gt;; then
        echo -e &quot;  ${GREEN}[✔]${NC} Assertion description&quot;
    else
        echo -e &quot;  ${RED}[✘]${NC} Failure description&quot;
        pass=false
    fi

    # Check 2: ...

    $pass  # returns true (0) or false (1)
}

Step 3: Test Your Scenario

Build and run the container:
Bash

docker build -t git-lab .
docker run -it --rm git-lab

Inside the container:
Bash

git-lab --run &lt;number&gt;     # Run your scenario
# ... attempt to solve it ...
git-lab --check            # Verify
git-lab --reset            # Start over if needed

Verify:

    [ ] Setup completes without errors
    [ ] Description is clear and unambiguous
    [ ] Hint is helpful but doesn't give it away entirely
    [ ] Check passes when solved correctly
    [ ] Check fails when not solved (test with partial solutions)
    [ ] Check messages clearly explain what's wrong

Scenario Design Guidelines
Difficulty Levels
Level 	Criteria
easy 	1–2 git commands, common operations (add, commit, merge)
medium 	3–5 commands, requires understanding of git internals
hard 	Complex multi-step, interactive rebase, reflog, recovery
Principles

    One concept per scenario. Don't mix unrelated Git concepts.
    Deterministic state. The setup must produce the same state every time.
    Realistic context. Use plausible file names, commit messages, and
    situations a developer would actually encounter.
    Verifiable end state. Every requirement in the description must be
    checkable in scenario_check. If you can't check it, don't require it.
    No side effects. Don't modify anything outside $REMOTE_BASE and
    $WORKSPACE.
    Suppress setup noise. Use --quiet on git commands. The user should
    see the description, not a wall of git output.

Common Checks Reference
Bash

# Current branch name
git rev-parse --abbrev-ref HEAD

# Branch exists
git show-ref --verify --quiet refs/heads/&lt;branch&gt;

# File exists in a commit
git show &lt;ref&gt;:&lt;file&gt; &amp;&gt;/dev/null

# Commit count between two refs
git rev-list &lt;base&gt;..&lt;tip&gt; --count

# Latest commit message
git log -1 --pretty=%s

# Check remote is up to date
local_sha=$(git rev-parse &lt;branch&gt;)
remote_sha=$(git -C &quot;$REMOTE_BASE/repo.git&quot; rev-parse &lt;branch&gt;)
[[ &quot;$local_sha&quot; == &quot;$remote_sha&quot; ]]

# No merge in progress
[[ ! -f &quot;.git/MERGE_HEAD&quot; ]]

# No conflict markers in file
! grep -qE &#x27;^(&lt;&lt;&lt;&lt;&lt;&lt;&lt;|=======|&gt;&gt;&gt;&gt;&gt;&gt;&gt;)&#x27; &lt;file&gt;

# Check a string exists in a file
grep -q &quot;pattern&quot; &lt;file&gt;

# Stash is empty
[[ $(git stash list | wc -l) -eq 0 ]]

# Tag exists
git tag -l &quot;&lt;tagname&gt;&quot; | grep -q &quot;&lt;tagname&gt;&quot;

# Working tree is clean
git diff --quiet &amp;&amp; git diff --cached --quiet

Scenario Ideas for Future Implementation

    Stash and apply: User has uncommitted changes and needs to switch
    branches
    Bisect a bug: Find which commit introduced a bug using git bisect
    Rebase onto updated main: Feature branch needs to be rebased after
    main moved forward
    Resolve a rebase conflict: Mid-rebase conflict resolution
    Set up tracking branch: Configure upstream tracking
    Undo a merge: Revert a merge commit with the correct parent
    Submodule update: Fix a submodule that's out of date
    Clean up tags: Delete local and remote tags
    Partial staging: Stage only parts of a file with git add -p
    Blame and log investigation: Find who introduced a specific line

File Naming Convention
Plaintext

NN-short-kebab-case-description.sh

    NN = two-digit number (01–99), determines menu order
    Keep descriptions to 3–5 words
    Use hyphens, not underscores

Troubleshooting

    If scenario_check uses color variables ($RED, $GREEN, $NC),
    define them locally inside the function — they are NOT inherited from
    git-lab.sh because the scenario is sourced in a subshell context
    during check.
    Always cd "$WORKSPACE/repo" at the start of scenario_check.
    Use 2>/dev/null on git commands that may fail during checking.
    Remember that $pass at the end works because true exits 0 and
    false exits 1 in Bash.

Plaintext


---

## Build &amp; Run Instructions

```bash
# From the git-lab/ project directory:
docker build -t git-lab .
docker run -it --rm git-lab

Once inside the container:
Bash

# Launch the scenario menu
git-lab

# Or use specific commands:
git-lab --list        # See all scenarios
git-lab --run 1       # Jump to scenario 1
git-lab --check       # Check your solution
git-lab --hint        # Get a hint
git-lab --reset       # Start the scenario over
git-lab --describe    # Re-read the task


