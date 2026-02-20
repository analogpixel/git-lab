#!/usr/bin/env bash
#
# git-lab.sh — Interactive Git Scenario Laboratory
#
# Usage:
#   git-lab              Show menu and select a scenario
#   git-lab --list       List available scenarios
#   git-lab --run <id>   Run a specific scenario by number
#   git-lab --check      Check if current scenario is solved
#   git-lab --hint       Show a hint for the current scenario
#   git-lab --reset      Re-run the current scenario from scratch
#   git-lab --describe   Re-print the current scenario description
#

set -euo pipefail

##############################
# Configuration
##############################
SCENARIO_DIR="/opt/git-lab/scenarios"
REMOTE_BASE="/srv/git"
WORKSPACE="/home/student/workspace"
STATE_FILE="/home/student/.git-lab-state"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

##############################
# Helper functions
##############################

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         🔬  GIT LABORATORY  🔬          ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║  Practice Git scenarios in a safe space  ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_separator() {
    echo -e "${BLUE}──────────────────────────────────────────${NC}"
}

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✔]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
fail()    { echo -e "${RED}[✘]${NC} $*"; }

# Clean up workspace and remote for a fresh scenario
clean_environment() {
    rm -rf "${WORKSPACE:?}"/*
    rm -rf "${WORKSPACE:?}"/.[!.]*  2>/dev/null || true
    rm -rf "${REMOTE_BASE:?}"/*
    cd "$WORKSPACE"
}

# Save which scenario is currently active
save_state() {
    local scenario_file="$1"
    echo "$scenario_file" > "$STATE_FILE"
}

# Load the currently active scenario
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo ""
    fi
}

# Discover scenario files (anything matching NN-*.sh, excluding _template.sh)
get_scenarios() {
    find "$SCENARIO_DIR" -maxdepth 1 -name '[0-9][0-9]-*.sh' | sort
}

# Extract the human-readable name from a scenario file
get_scenario_name() {
    local file="$1"
    # Source the file and call scenario_name
    (source "$file" && scenario_name)
}

# Extract difficulty from a scenario file
get_scenario_difficulty() {
    local file="$1"
    (source "$file" && scenario_difficulty 2>/dev/null || echo "unknown")
}

##############################
# Core actions
##############################

list_scenarios() {
    print_banner
    echo -e "${BOLD}Available Scenarios:${NC}"
    print_separator

    local i=1
    while IFS= read -r scenario_file; do
        local name
        local difficulty
        name=$(get_scenario_name "$scenario_file")
        difficulty=$(get_scenario_difficulty "$scenario_file")

        local diff_color="$NC"
        case "$difficulty" in
            easy)     diff_color="$GREEN" ;;
            medium)   diff_color="$YELLOW" ;;
            hard)     diff_color="$RED" ;;
        esac

        printf "  ${BOLD}%2d)${NC}  %-40s ${diff_color}[%s]${NC}\n" "$i" "$name" "$difficulty"
        i=$((i + 1))
    done < <(get_scenarios)

    print_separator
}

run_scenario() {
    local scenario_file="$1"

    if [[ ! -f "$scenario_file" ]]; then
        fail "Scenario file not found: $scenario_file"
        exit 1
    fi

    info "Cleaning environment..."
    clean_environment

    info "Setting up scenario..."
    print_separator

    # Source the scenario and run its setup
    # We export key variables so the scenario can use them
    export REMOTE_BASE WORKSPACE
    source "$scenario_file"

    # Run setup (this does all the git commands)
    scenario_setup

    echo ""
    print_separator
    echo -e "${BOLD}${CYAN}SCENARIO: $(scenario_name)${NC}"
    echo -e "${BOLD}Difficulty: $(scenario_difficulty)${NC}"
    print_separator
    echo ""
    scenario_description
    echo ""
    print_separator
    echo -e "${YELLOW}Hints available:${NC}  git-lab --hint"
    echo -e "${YELLOW}Check solution:${NC}   git-lab --check"
    echo -e "${YELLOW}See task again:${NC}   git-lab --describe"
    echo -e "${YELLOW}Start over:${NC}       git-lab --reset"
    print_separator

    # Save state
    save_state "$scenario_file"

    # Make sure we're in the right directory
    cd "$WORKSPACE"
}

check_scenario() {
    local scenario_file
    scenario_file=$(load_state)

    if [[ -z "$scenario_file" || ! -f "$scenario_file" ]]; then
        fail "No active scenario. Run 'git-lab' to select one."
        exit 1
    fi

    export REMOTE_BASE WORKSPACE
    source "$scenario_file"

    echo ""
    print_separator
    echo -e "${BOLD}Checking: $(scenario_name)${NC}"
    print_separator
    echo ""

    # scenario_check should return 0 on success, non-zero on failure
    if scenario_check; then
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║      🎉  SCENARIO SOLVED!  🎉           ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        info "Run 'git-lab' to try another scenario."
    else
        echo ""
        fail "Not quite right yet. Keep trying!"
        echo -e "  Use ${YELLOW}git-lab --hint${NC} if you need help."
    fi
}

show_hint() {
    local scenario_file
    scenario_file=$(load_state)

    if [[ -z "$scenario_file" || ! -f "$scenario_file" ]]; then
        fail "No active scenario. Run 'git-lab' to select one."
        exit 1
    fi

    export REMOTE_BASE WORKSPACE
    source "$scenario_file"

    echo ""
    echo -e "${YELLOW}${BOLD}HINT:${NC}"
    scenario_hint
    echo ""
}

show_description() {
    local scenario_file
    scenario_file=$(load_state)

    if [[ -z "$scenario_file" || ! -f "$scenario_file" ]]; then
        fail "No active scenario. Run 'git-lab' to select one."
        exit 1
    fi

    export REMOTE_BASE WORKSPACE
    source "$scenario_file"

    echo ""
    print_separator
    echo -e "${BOLD}${CYAN}SCENARIO: $(scenario_name)${NC}"
    echo -e "${BOLD}Difficulty: $(scenario_difficulty)${NC}"
    print_separator
    echo ""
    scenario_description
    echo ""
    print_separator
}

reset_scenario() {
    local scenario_file
    scenario_file=$(load_state)

    if [[ -z "$scenario_file" || ! -f "$scenario_file" ]]; then
        fail "No active scenario. Run 'git-lab' to select one."
        exit 1
    fi

    warn "Resetting current scenario..."
    run_scenario "$scenario_file"
}

interactive_menu() {
    list_scenarios

    local scenarios=()
    while IFS= read -r f; do
        scenarios+=("$f")
    done < <(get_scenarios)

    local count=${#scenarios[@]}

    echo ""
    echo -en "${BOLD}Select a scenario (1-${count}), or 'q' to quit: ${NC}"
    read -r choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        info "Goodbye!"
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
        fail "Invalid selection."
        exit 1
    fi

    local selected="${scenarios[$((choice - 1))]}"
    run_scenario "$selected"
}

##############################
# Main entry point
##############################

main() {
    case "${1:-}" in
        --list)
            list_scenarios
            ;;
        --run)
            if [[ -z "${2:-}" ]]; then
                fail "Usage: git-lab --run <scenario_number>"
                exit 1
            fi
            local scenarios=()
            while IFS= read -r f; do
                scenarios+=("$f")
            done < <(get_scenarios)
            local idx=$(( $2 - 1 ))
            if (( idx < 0 || idx >= ${#scenarios[@]} )); then
                fail "Invalid scenario number."
                exit 1
            fi
            run_scenario "${scenarios[$idx]}"
            ;;
        --check)
            check_scenario
            ;;
        --hint)
            show_hint
            ;;
        --describe)
            show_description
            ;;
        --reset)
            reset_scenario
            ;;
        --help|-h)
            echo "Usage:"
            echo "  git-lab              Interactive scenario menu"
            echo "  git-lab --list       List available scenarios"
            echo "  git-lab --run <N>    Run scenario number N"
            echo "  git-lab --check      Check if scenario is solved"
            echo "  git-lab --hint       Show a hint"
            echo "  git-lab --describe   Show scenario description again"
            echo "  git-lab --reset      Reset current scenario"
            ;;
        "")
            interactive_menu
            ;;
        *)
            fail "Unknown option: $1"
            echo "Run 'git-lab --help' for usage."
            exit 1
            ;;
    esac
}

main "$@"

