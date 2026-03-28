import subprocess
import os

def run(cmd):
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Warning: {cmd} failed with:\n{result.stderr}\n{result.stdout}")
    else:
        print(result.stdout)
    return result.returncode == 0

# Stash including untracked files
run("git stash -u")

# Checkout branch
success = run("git checkout feature/setup-clean-architecture")
if not success:
    print("Could not checkout branch. Exiting.")
    exit(1)

# Merge main
run("git merge main")

# Apply stash
run("git stash pop")

# Reset staging area so we can stage logically
run("git reset")

# Commit 1: Core and domain layer
run("git add lib/core lib/domain")
run("git commit -m \"feat: implement core and domain layers for clean architecture\"")

# Commit 2: Data layer
run("git add lib/data")
run("git commit -m \"feat: implement data sources and repositories\"")

# Commit 3: Presentation layer
run("git add lib/presentation lib/main.dart")
run("git commit -m \"feat: update presentation layer and DI injection\"")

# Commit 4: Tests
run("git add test lib/test")
run("git commit -m \"test: add and update application tests\"")

# Commit 5: Any other leftovers
run("git add .")
# We only commit if there are actually files staged
res = subprocess.run("git diff --cached --quiet", shell=True)
if res.returncode != 0:
    run("git commit -m \"chore: final polish and minor updates\"")

# Checkout main
run("git checkout main")

# Merge feature branch back to main
# so that I'm not ahead or behind
run("git merge feature/setup-clean-architecture")

print("Done with the automated git workflow.")
