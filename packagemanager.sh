#!/bin/bash

set -e

# Step 1: Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    echo "🔧 pre-commit not found. Installing..."
    pip install pre-commit
else
    echo "✅ pre-commit is already installed."
fi

# Step 2: Install Python dependencies for Python-based pre-commit hooks
echo "📦 Installing Python linters..."
pip install --upgrade pyupgrade autopep8 flake8 black cpplint

# Step 3: Install Node.js tools (ESLint, Stylelint, HTMLHint)
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🔧 Node.js or npm not found. Installing..."
    sudo apt update && sudo apt install -y nodejs npm
fi

echo "📦 Installing Node linters globally..."
npm install -g eslint stylelint htmlhint

# Step 4: Install Checkstyle_jar (Java) if not already installed

#!/bin/bash
# Fetch the latest version tag from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/checkstyle/checkstyle/releases/latest | grep -oP '"tag_name":\s*"checkstyle-\K[^"]+')

CHECKSTYLE_VERSION="$LATEST_VERSION"
CHECKSTYLE_JAR="checkstyle-${CHECKSTYLE_VERSION}-all.jar"
CHECKSTYLE_URL="https://github.com/checkstyle/checkstyle/releases/download/checkstyle-${CHECKSTYLE_VERSION}/${CHECKSTYLE_JAR}"
INSTALL_DIR="$HOME/.local/bin"

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Step 4: Install Checkstyle (Java) if not already installed
if [ ! -f "$INSTALL_DIR/$CHECKSTYLE_JAR" ]; then
    echo "🔧 Installing Checkstyle version ${CHECKSTYLE_VERSION}..."
    curl -L -o "$INSTALL_DIR/$CHECKSTYLE_JAR" "$CHECKSTYLE_URL"
else
    echo "✅ Checkstyle ${CHECKSTYLE_VERSION} is already installed."
fi

# Optional: Create or update alias
PROFILE_FILE="$HOME/.bashrc"
if ! grep -q "alias checkstyle=" "$PROFILE_FILE"; then
    echo "📌 Creating alias for checkstyle..."
    echo "alias checkstyle='java -jar $INSTALL_DIR/$CHECKSTYLE_JAR'" >> "$PROFILE_FILE"
    source "$PROFILE_FILE"
else
    echo "🔁 Alias for checkstyle already exists."
fi

# Step 5: Download google_checks.xml if not already present
if [ ! -f "google_checks.xml" ]; then
    echo "⬇️ Downloading google_checks.xml for Checkstyle..."
    curl -L https://raw.githubusercontent.com/checkstyle/checkstyle/master/src/main/resources/google_checks.xml -o google_checks.xml
else
    echo "✅ google_checks.xml already exists."
fi

# Step 6: Install Go if not already installed (for golangci-lint hook)
if ! command -v go &> /dev/null; then
    echo "🔧 Go not found. Installing..."
    sudo apt install -y golang
else
    echo "✅ Go is already installed."
fi

# Step 7: Initialize pre-commit hooks
echo "🔗 Installing pre-commit hooks from config..."
pre-commit install

# Step 8: Set up custom hooks
echo "🔧 Setting up custom hooks..."
mkdir -p custom_hooks

# Custom Python linter script
cat <<'EOF' > custom_hooks/custom_linter.py
#!/usr/bin/env python3
from __future__ import annotations
import sys

def check_code(file_path):
    with open(file_path) as file:
        lines = file.readlines()
        for line_num, line in enumerate(lines, 1):
            if line.startswith("import"):
                print(f"Line {line_num}: Ensure correct import order.")

if __name__ == "__main__":
    for file_path in sys.argv[1:]:
        check_code(file_path)
EOF
chmod +x custom_hooks/custom_linter.py

# Large file checker
cat <<'EOF' > custom_hooks/check_large_files.sh
#!/bin/bash
# Set default max size (20MB) if not defined
: "${MAX_SIZE:=20971520}" # 20MB in bytes

for file in "$@"; do
    if [ "$(stat -c %s "$file")" -gt "$MAX_SIZE" ]; then
        echo "❌ File $file is too large! Size exceeds $(($MAX_SIZE / 20971520)) MB."
        exit 1
    fi
done
EOF
chmod +x custom_hooks/check_large_files.sh

echo "✅ Custom hooks have been created."

echo -e "\n🎉 Pre-commit setup complete and ready to use!"