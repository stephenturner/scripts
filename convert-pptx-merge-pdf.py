#!/usr/bin/env -S uv run
# /// script
# dependencies = [
#   "pypdf",
# ]
# ///
"""
Convert all PPTX files in a folder to PDF and merge them using Microsoft PowerPoint.
This preserves formatting perfectly by using PowerPoint's native export.

Requirements:
- uv (install with: curl -LsSf https://astral.sh/uv/install.sh | sh)
- Microsoft PowerPoint for Mac must be installed

Usage: ./convert_merge_pptx_mac.py <input_folder> <output_pdf>
Example: ./convert_merge_pptx_mac.py ./presentations merged_output.pdf
"""

import os
import sys
import glob
import subprocess
import tempfile
from pathlib import Path

from pypdf import PdfWriter, PdfReader


def check_powerpoint_installed():
    """Check if Microsoft PowerPoint is installed."""
    powerpoint_paths = [
        "/Applications/Microsoft PowerPoint.app",
        "/Applications/Microsoft Office/Microsoft PowerPoint.app"
    ]
    
    for path in powerpoint_paths:
        if os.path.exists(path):
            return True
    return False


def convert_pptx_to_pdf_with_powerpoint(pptx_file, output_pdf):
    """Convert PPTX to PDF using Microsoft PowerPoint via AppleScript."""
    
    # Convert to absolute paths
    pptx_abs = os.path.abspath(pptx_file)
    pdf_abs = os.path.abspath(output_pdf)
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(pdf_abs), exist_ok=True)
    
    # Use a more robust AppleScript that references the document differently
    applescript = f'''
    set inputFile to POSIX file "{pptx_abs}"
    set outputFile to POSIX file "{pdf_abs}"
    
    tell application "Microsoft PowerPoint"
        activate
        delay 2
        
        try
            open inputFile
            delay 3
            
            -- Get the active presentation
            set activeDoc to active presentation
            
            -- Save as PDF
            save activeDoc in outputFile as save as PDF
            
            -- Close without saving changes
            close activeDoc saving no
            
            return "success"
        on error errMsg number errNum
            try
                close active presentation saving no
            end try
            return "error: " & errMsg & " (error " & errNum & ")"
        end try
    end tell
    '''
    
    try:
        result = subprocess.run(
            ['osascript'],
            input=applescript,
            capture_output=True,
            text=True,
            timeout=180
        )
        
        output = result.stdout.strip()
        
        if "success" in output and os.path.exists(output_pdf):
            return True
        else:
            if result.stderr:
                print(f"  stderr: {result.stderr}")
            if output and "error:" in output:
                print(f"  {output}")
            elif output:
                print(f"  Output: {output}")
            return False
            
    except subprocess.TimeoutExpired:
        print(f"  Error: Conversion timeout")
        return False
    except Exception as e:
        print(f"  Error: {e}")
        return False


def merge_pdfs(pdf_files, output_file):
    """Merge multiple PDF files into a single PDF."""
    print(f"\nMerging {len(pdf_files)} PDFs...")
    
    writer = PdfWriter()
    
    for pdf_file in pdf_files:
        try:
            reader = PdfReader(pdf_file)
            for page in reader.pages:
                writer.add_page(page)
            print(f"  Added {os.path.basename(pdf_file)} ({len(reader.pages)} pages)")
        except Exception as e:
            print(f"Error reading {pdf_file}: {e}")
    
    with open(output_file, "wb") as output:
        writer.write(output)
    
    print(f"\nMerged PDF saved to: {output_file}")


def quit_powerpoint():
    """Quit PowerPoint to clean up."""
    try:
        subprocess.run(
            ['osascript', '-e', 'tell application "Microsoft PowerPoint" to quit'],
            capture_output=True,
            timeout=10
        )
    except:
        pass


def main():
    if len(sys.argv) != 3:
        print("Usage: ./convert_merge_pptx_mac.py <input_folder> <output_pdf>")
        print("Example: ./convert_merge_pptx_mac.py ./presentations merged.pdf")
        sys.exit(1)
    
    input_folder = sys.argv[1]
    output_pdf = sys.argv[2]
    
    # Validate input folder
    if not os.path.isdir(input_folder):
        print(f"Error: {input_folder} is not a valid directory")
        sys.exit(1)
    
    # Check if PowerPoint is installed
    if not check_powerpoint_installed():
        print("Error: Microsoft PowerPoint for Mac is not installed.")
        print("\nAlternative solutions:")
        print("1. Install Microsoft PowerPoint")
        print("2. Use the Keynote version (convert_merge_pptx_keynote.py)")
        print("3. Use an online converter (not automated)")
        sys.exit(1)
    
    # Find all PPTX files
    pptx_pattern = os.path.join(input_folder, "*.pptx")
    pptx_files = sorted(glob.glob(pptx_pattern))
    
    if not pptx_files:
        print(f"No PPTX files found in {input_folder}")
        sys.exit(1)
    
    print(f"Found {len(pptx_files)} PPTX file(s)")
    print("Converting using Microsoft PowerPoint...")
    
    # Create temporary directory for intermediate PDFs
    with tempfile.TemporaryDirectory() as temp_dir:
        # Convert all PPTX files to PDF
        pdf_files = []
        for i, pptx_file in enumerate(pptx_files, 1):
            print(f"\n[{i}/{len(pptx_files)}] Converting {os.path.basename(pptx_file)}...")
            
            base_name = os.path.splitext(os.path.basename(pptx_file))[0]
            temp_pdf = os.path.join(temp_dir, f"{base_name}.pdf")
            
            if convert_pptx_to_pdf_with_powerpoint(pptx_file, temp_pdf):
                pdf_files.append(temp_pdf)
                print(f"  ✓ Success")
            else:
                print(f"  ✗ Failed to convert {os.path.basename(pptx_file)}")
        
        if not pdf_files:
            print("\nError: No PDFs were successfully created")
            sys.exit(1)
        
        # Merge all PDFs
        merge_pdfs(pdf_files, output_pdf)
        
        print(f"\n✓ Success! {len(pdf_files)} presentations merged into {output_pdf}")
    
    # Clean up PowerPoint
    quit_powerpoint()


if __name__ == "__main__":
    main()
