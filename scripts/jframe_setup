#!/bin/bash

# --- Java JFrame Project Setup Script ---
# This script first checks if Java is installed and attempts to install it if not.
# It then creates a directory structure, a sample JFrame application,
# and a Makefile for compilation and execution.

# --- Function to Check and Install Java ---
check_and_install_java() {
  echo "--- Checking for Java installation ---"
  # We check for javac (the compiler) to ensure a JDK is installed, not just a JRE.
  if ! command -v javac &>/dev/null; then
    echo "Java Development Kit (JDK) not found. Attempting to install..."

    # OS-specific installation logic
    if [[ "$(uname)" == "Linux" ]]; then
      if command -v apt-get &>/dev/null; then
        echo "Detected Debian/Ubuntu based system. Using apt-get."
        echo "You may be prompted for your password to install packages."
        sudo apt-get update
        sudo apt-get install default-jdk -y
      elif command -v yum &>/dev/null; then
        echo "Detected RHEL/CentOS/Fedora based system. Using yum."
        echo "You may be prompted for your password to install packages."
        sudo yum install -y java-11-openjdk-devel
      elif command -v pacman &>/dev/null; then
        echo "Detected Arch Linux based system. Using pacman."
        echo "You may be prompted for your password to install packages."
        sudo pacman -S --noconfirm jdk-openjdk
      else
        echo "Could not find a supported package manager (apt-get, yum, pacman) to install the JDK."
        echo "Please install the Java Development Kit (JDK) manually and re-run this script."
        exit 1
      fi
    elif [[ "$(uname)" == "Darwin" ]]; then # This is for macOS
      if command -v brew &>/dev/null; then
        echo "Detected macOS with Homebrew. Using brew to install OpenJDK."
        brew install openjdk
      else
        echo "Homebrew not found on macOS."
        echo "Please install Homebrew (see https://brew.sh/) or install the Java Development Kit (JDK) manually and re-run this script."
        exit 1
      fi
    else
      echo "Unsupported Operating System: $(uname)"
      echo "Please install the Java Development Kit (JDK) manually and re-run this script."
      exit 1
    fi

    # Verify that the installation was successful
    if ! command -v javac &>/dev/null; then
      echo "JDK installation appears to have failed. Please check the output above."
      echo "You may need to install it manually."
      exit 1
    else
      echo "JDK installed successfully!"
    fi
  else
    echo "Java Development Kit (JDK) is already installed."
  fi
  # Print the version for confirmation
  echo -n "Java version: "
  java -version
  echo "" # Add a newline for better formatting
}

# --- Configuration ---
# You can change the project name here if you like.
PROJECT_NAME="MyJFrameApp"
MAIN_CLASS_NAME="Main"

# --- Main Script Logic ---

# Step 1: Check for Java and install if needed.
check_and_install_java

# Step 2: Check if the project directory already exists
if [ -d "$PROJECT_NAME" ]; then
  echo "Error: Directory '$PROJECT_NAME' already exists."
  echo "Please remove it or choose a different PROJECT_NAME in the script."
  exit 1
fi

echo "--- Setting up your new Java JFrame project: $PROJECT_NAME ---"

# 3. Create the main project directory
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# 4. Create the source and build directories
echo "Creating directory structure..."
mkdir src
mkdir bin
echo "  - src/ (for your .java files)"
echo "  - bin/ (for your compiled .class files)"

# 5. Create the main Java source file with a simple JFrame window
echo "Creating a sample JFrame application: src/$MAIN_CLASS_NAME.java..."
cat <<EOF >"src/$MAIN_CLASS_NAME.java"
// Import the necessary Swing library
import javax.swing.*;
import java.awt.BorderLayout;
import java.awt.Dimension;

/**
 * A simple starter JFrame application.
 */
public class ${MAIN_CLASS_NAME} {

    public static void main(String[] args) {
        // Swing operations should be performed on the Event Dispatch Thread (EDT)
        // for thread safety. SwingUtilities.invokeLater ensures this.
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                createAndShowGUI();
            }
        });
    }

    private static void createAndShowGUI() {
        // 1. Create the frame (the main window)
        JFrame frame = new JFrame("My First JFrame App");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); // Exit the app when the window is closed
        frame.setSize(400, 300); // Set the initial size of the window

        // 2. Create components to add to the frame
        JLabel label = new JLabel("Hello, JFrame World!", SwingConstants.CENTER);

        // 3. Add components to the frame's content pane
        frame.getContentPane().add(label, BorderLayout.CENTER);

        // 4. Set the frame's location and make it visible
        frame.setLocationRelativeTo(null); // Center the window on the screen
        frame.setVisible(true); // Make the window visible
    }
}
EOF

# 6. Create a Makefile
echo "Creating Makefile..."
cat <<EOF >"Makefile"
# Makefile for the Java JFrame Project

# --- Variables ---
# Compiler
JC := javac
# JVM
JVM := java
# Main class name
MAIN_CLASS := ${MAIN_CLASS_NAME}

# --- Directories ---
SRCDIR := src
BINDIR := bin

# --- Flags ---
# -d specifies the output directory for class files.
# -cp specifies where to find source files.
JFLAGS := -d \$(BINDIR) -cp \$(SRCDIR)

# --- Files ---
SOURCES := \$(SRCDIR)/\$(MAIN_CLASS).java
CLASSES := \$(BINDIR)/\$(MAIN_CLASS).class

# --- Targets ---

# Default target: compile the code.
all: \$(CLASSES)

# Compile the source files into class files.
\$(CLASSES): \$(SOURCES)
	@echo "Compiling..."
	@# Ensure the binary directory exists before compiling.
	@mkdir -p \$(BINDIR)
	@\$(JC) \$(JFLAGS) \$<

# Run the compiled application.
run: all
	@echo "Running application..."
	@\$(JVM) -cp \$(BINDIR) \$(MAIN_CLASS)

# Clean up by removing the compiled files directory.
clean:
	@echo "Cleaning up project..."
	@rm -rf \$(BINDIR)

# Phony targets are rules that don't produce an output file with the same name.
.PHONY: all run clean

EOF

echo ""
echo "--- Project setup complete! ---"
echo ""
echo "Next Steps:"
echo "1. Navigate into your new project directory:"
echo "   cd $PROJECT_NAME"
echo ""
echo "2. Compile your code:"
echo "   make"
echo ""
echo "3. Run your application:"
echo "   make run"
echo ""
echo "4. To clean up compiled files:"
echo "   make clean"
echo ""
echo "You can now start editing 'src/$MAIN_CLASS_NAME.java' to build your application."
