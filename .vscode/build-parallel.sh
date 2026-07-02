#!/bin/bash

# Parallel LaTeX Build Script for Linux with Tectonic
echo "=== Parallel LaTeX Build Script (Tectonic) ==="

# Create build directory if it doesn't exist
mkdir -p build

# Find all TeX files in main directory
shopt -s nullglob
texFiles=(main/*.tex)
echo "Found ${#texFiles[@]} TeX files to compile in parallel..."

if [ ${#texFiles[@]} -eq 0 ]; then
    echo "No TeX files found in main/ directory."
    exit 0
fi

# Function to compile a single file with tectonic
compile_file() {
    local file="$1"
    local basename=$(basename "$file")
    echo "Compiling ${basename} with tectonic..."
    
    tectonic -o build "$file" 2>&1
    local exitCode=$?
    if [ $exitCode -eq 0 ]; then
        echo "Successfully compiled ${basename}"
    else
        echo "Compilation failed for ${basename} (exit code: ${exitCode})"
        return $exitCode
    fi
    
    return 0
}

# Start compilation for all files in parallel
declare -A pids
for file in "${texFiles[@]}"; do
    compile_file "$file" &
    pids["$file"]=$!
done

# Wait for all compilations to complete
echo "Waiting for compilations to complete..."
all_success=true
for file in "${texFiles[@]}"; do
    wait "${pids[$file]}"
    if [ $? -ne 0 ]; then
        echo "Compilation failed for ${file}"
        all_success=false
    fi
done

if [ "$all_success" = false ]; then
    echo "=== Some compilations failed ==="
    exit 1
fi

# Move PDF files from build/ to main/pdfs/ directory
echo "Moving PDF files to main/pdfs directory..."

# Create main/pdfs directory if it doesn't exist
if [ ! -d "main/pdfs" ]; then
    mkdir -p "main/pdfs"
    echo "Created main/pdfs directory"
fi

# Move PDF files from build directory
for pdf in build/main_*.pdf build/presentation_*.pdf build/print_*.pdf; do
    if [ -f "$pdf" ]; then
        basename_pdf=$(basename "$pdf")
        mv "$pdf" "main/pdfs/${basename_pdf}"
        echo "Moved ${basename_pdf} to main/pdfs/"
    fi
done

# Clean up temporary files in build directory
echo "Cleaning up temporary files..."
find build -maxdepth 1 -type f \( \
    -name "*.aux" -o \
    -name "*.log" -o \
    -name "*.nav" -o \
    -name "*.out" -o \
    -name "*.snm" -o \
    -name "*.toc" -o \
    -name "*.fls" -o \
    -name "*.fdb_latexmk" -o \
    -name "*.synctex.gz" -o \
    -name "*.xdv" -o \
    -name "*.run.xml" -o \
    -name "*.bcf" -o \
    -name "*.lof" -o \
    -name "*.lot" -o \
    -name "*.glo" -o \
    -name "*.gls" -o \
    -name "*.ist" -o \
    -name "*.acn" -o \
    -name "*.acr" -o \
    -name "*.alg" -o \
    -name "*.bbl" -o \
    -name "*.blg" \
\) -delete 2>/dev/null

echo "Cleanup completed!"
echo "=== Build process finished ==="