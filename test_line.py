import os
import subprocess
import sys

def check_extra_file(file_path):
    with open(file_path, "rb") as f:
        lines = f.readlines()
        print("file is getting checked for extra spaces at end")
        if lines  and len(lines) > 1 and lines[-1] == b"\n" and lines[-2].endswith(b'\n'):
            print(f"Error: Extra trailing newline in {file_path}")
            return False
        if lines[-1] == b"\n":
            return True


def main():
    hello()
    """run command and check for all files that are changed or added , subprocess is used to run the commands"""
    changed_files = subprocess.run(
        ["git", "diff", "--name-only", "origin/main..."],
        capture_output=True,
        text=True,
    ).stdout.splitlines()

    trigger=True

    for i in changed_files:
        if ".py" in i:
            print(f"this python file is getting checked {i}")
            trigger=check_extra_file(file_path)
        if trigger==False:
            sys.exit(1)




def hello():
    print("Hello, GitLab CI/CD!")

if __name__ == "__main__":
    main()