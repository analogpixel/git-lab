Plaintext

# 🔬 Git Laboratory

**An interactive, Docker-based environment for practicing Git scenarios in a safe, disposable sandbox.**

Practice resolving merge conflicts, recovering lost commits, rebasing, cherry-picking, and more — all inside a single container that acts as both your local machine and remote server.

![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-24.04-2496ED?logo=docker&logoColor=white)
![Git](https://img.shields.io/badge/Git-2.x-F05032?logo=git&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## 🎯 What Is This?

Git Lab drops you into real Git messes and asks you to fix them. Each scenario:

1. **Sets up** a realistic Git state (repos, branches, conflicts, bad resets, etc.)
2. **Describes** the problem and what you need to accomplish
3. **Provides hints** on demand if you get stuck
4. **Verifies your solution** automatically with detailed pass/fail checks

Everything runs inside a single Docker container — no network, no SSH, no external servers. The container uses local bare repositories as "remotes," so `git push` and `git pull` work exactly like the real thing.

---

## 📦 Quick Start

```bash
# Clone the repo
git clone https://github.com/yourusername/git-lab.git
cd git-lab

# Build the Docker image
docker build -t git-lab .

# Run it
docker run -it --rm git-lab

Once inside the container:
Bash

git-lab

That's it. Pick a scenario and start fixing.
🖥️ Usage
Command 	Description
git-lab 	Interactive scenario menu
git-lab --list 	List all available scenarios
git-lab --run <N> 	Jump directly to scenario N
git-lab --check 	Check if your solution is correct
git-lab --hint 	Get a hint for the current scenario
git-lab --describe 	Re-read the current task description
git-lab --reset 	Wipe and re-run the current scenario
git-lab --help 	Show help
Example Session
Plaintext

$ git-lab

╔══════════════════════════════════════════╗
║         🔬  GIT LABORATORY  🔬          ║
╠══════════════════════════════════════════╣
║  Practice Git scenarios in a safe space  ║
╚══════════════════════════════════════════╝

Available Scenarios:
──────────────────────────────────────────
   1)  Resolve a Merge Conflict              [easy]
   2)  Fix a Detached HEAD                   [easy]
   3)  Recover a Deleted Branch              [medium]
   4)  Revert a Bad Commit (Pushed)          [easy]
   5)  Squash Commits with Interactive Rebase [hard]
   6)  Cherry-Pick a Hotfix                  [medium]
   7)  Amend a Commit (Unpushed)             [easy]
   8)  Recover a Commit After Hard Reset     [hard]
──────────────────────────────────────────

Select a scenario (1-8), or &#x27;q&#x27; to quit: 3

After working through the problem:
Plaintext

$ git-lab --check

──────────────────────────────────────────
Checking: Recover a Deleted Branch
──────────────────────────────────────────

  [✔] Branch &#x27;feature-login&#x27; exists
  [✔] login.py contains input validation (all commits recovered)
  [✔] Branch has all 3 commits

╔══════════════════════════════════════════╗
║      🎉  SCENARIO SOLVED!  🎉           ║
╚══════════════════════════════════════════╝

🧪 Included Scenarios
# 	Scenario 	Difficulty 	Concepts Practiced
01 	Resolve a Merge Conflict 	Easy 	merge, conflict resolution
02 	Fix a Detached HEAD 	Easy 	checkout, branch, detached HEAD
03 	Recover a Deleted Branch 	Medium 	reflog, branch
04 	Revert a Bad Commit (Pushed) 	Easy 	revert vs. reset
05 	Squash Commits with Interactive Rebase 	Hard 	rebase -i, squash
06 	Cherry-Pick a Hotfix 	Medium 	cherry-pick, selective merging
07 	Amend a Commit (Unpushed) 	Easy 	commit --amend, staging
08 	Recover a Commit After Hard Reset 	Hard 	reflog, reset
🏗️ Architecture
Plaintext

Inside the container:

/opt/git-lab/
├── git-lab.sh              # Main orchestrator script
├── agents.md               # LLM guide for creating new scenarios
└── scenarios/
    ├── _template.sh         # Scenario authoring template
    ├── 01-merge-conflict.sh
    ├── 02-detached-head.sh
    └── ...

/srv/git/                    # &quot;Remote&quot; bare repositories (created per scenario)
/home/student/workspace/     # &quot;Local&quot; working directory (your sandbox)

Each scenario is a self-contained Bash script that implements 6 functions:
Function 	Purpose
scenario_name 	Short title for the menu
scenario_difficulty 	easy, medium, or hard
scenario_description 	Full task instructions shown to the user
scenario_hint 	Help text available on demand
scenario_setup 	All Git commands to build the scenario state
scenario_check 	Validates the user's solution (pass/fail)

The system auto-discovers any file matching [0-9][0-9]-*.sh in the scenarios/ directory — just drop in a new file and it appears in the menu.
✏️ Creating Your Own Scenarios
Quick Start
Bash

# Copy the template
cp scenarios/_template.sh scenarios/09-my-scenario.sh

# Edit it
vim scenarios/09-my-scenario.sh

# Rebuild the image
docker build -t git-lab .

# Test it
docker run -it --rm git-lab

Template Structure

Every scenario script must define these functions:
Bash

scenario_name()        { echo &quot;My Scenario Title&quot;; }
scenario_difficulty()  { echo &quot;medium&quot;; }
scenario_description() { cat &lt;&lt;&#x27;EOF&#x27;
  Describe the problem and the user&#x27;s task here.
EOF
}
scenario_hint()        { cat &lt;&lt;&#x27;EOF&#x27;
  Provide helpful hints here.
EOF
}
scenario_setup()       {
  # Git commands to create the scenario state
  git init --bare &quot;$REMOTE_BASE/repo.git&quot; --quiet
  git clone &quot;$REMOTE_BASE/repo.git&quot; &quot;$WORKSPACE/repo&quot; --quiet
  cd &quot;$WORKSPACE/repo&quot;
  # ... build your scenario ...
}
scenario_check()       {
  # Return 0 if solved, non-zero if not
  cd &quot;$WORKSPACE/repo&quot;
  # ... run assertions ...
}

For AI/LLM Agents

The project includes an `agents.md` file with comprehensive instructions for LLM sessions to author new scenarios, including:

    Complete API reference for all 6 required functions
    Environment variables and path conventions
    A library of common Git check patterns (branch exists, commit count, file contents, etc.)
    Design guidelines and difficulty calibration
    A list of scenario ideas for future implementation

Point your AI coding assistant at agents.md and ask it to create a new scenario — it has everything it needs.
🐳 Docker Details

Base image: Ubuntu 24.04
Installed packages: git, vim, nano, less, tree, bash-completion, man-db
User: student (non-root)
Shell: Bash

The container is fully ephemeral — use --rm and every run starts completely clean. No data persists between sessions.
Customization

Mount a local scenarios directory to develop without rebuilding:
Bash

docker run -it --rm \
  -v ./scenarios:/opt/git-lab/scenarios \
  git-lab

Override the editor:
Bash

docker run -it --rm -e GIT_EDITOR=nano git-lab

🤝 Contributing

Contributions are welcome! The easiest way to contribute is by adding new scenarios.

    Fork the repository
    Copy scenarios/_template.sh to a new file (e.g., scenarios/09-your-scenario.sh)
    Implement all 6 required functions
    Test inside the container:
        Setup completes cleanly
        Description is clear and unambiguous
        Check passes when solved correctly
        Check fails when not solved
        Hints are helpful without giving the answer away
    Submit a pull request

Scenario Ideas

Looking for inspiration? Here are some scenarios that haven't been built yet:

    Stash and apply — save uncommitted changes before switching branches
    Git bisect — find which commit introduced a bug
    Rebase onto updated main — rebase a feature branch after main moved forward
    Resolve a rebase conflict — mid-rebase conflict resolution
    Undo a merge commit — revert a merge with the correct -m parent flag
    Partial staging — use git add -p to stage specific hunks
    Submodule update — fix an out-of-date submodule
    Clean up tags — delete local and remote tags
    Blame investigation — use git blame and git log to find who introduced a bug

📁 Project Structure
Plaintext

git-lab/
├── Dockerfile               # Container definition
├── README.md                # This file
├── agents.md                # Instructions for LLMs to create scenarios
├── git-lab.sh               # Main lab script
└── scenarios/
    ├── _template.sh          # Scenario authoring template
    ├── 01-merge-conflict.sh
    ├── 02-detached-head.sh
    ├── 03-recover-deleted-branch.sh
    ├── 04-undo-bad-commit.sh
    ├── 05-interactive-rebase.sh
    ├── 06-cherry-pick.sh
    ├── 07-amend-commit.sh
    └── 08-find-lost-commit.sh

📄 License

This project is licensed under the MIT License. See LICENSE for details.
💡 Why?

Learning Git by reading docs is one thing. Learning Git by breaking things and fixing them is another. This project gives you a safe, repeatable, zero-consequence playground where you can:

    Build muscle memory for common Git recovery operations
    Prepare for interviews that test Git proficiency
    Experiment freely without fear of destroying real work
    Teach others by assigning specific scenarios as exercises

    "The best way to learn Git is to get into trouble with Git."

