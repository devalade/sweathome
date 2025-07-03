#!/bin/bash
# Check if FFmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
  echo "FFmpeg is not installed. Please install it first."
  exit 1
fi

# Check if at least one argument (file or directory) is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <input_file.webm> OR $0 <directory>"
  echo "Example: $0 video.webm OR $0 ./videos"
  exit 1
fi

# Function to convert a single WebM file
convert_file() {
  local input_file="$1"
  local output_file="${input_file%.webm}.mp4"

  # Check if output file already exists
  if [ -f "$output_file" ]; then
    echo "Skipping $input_file: $output_file already exists."
    return
  fi

  echo "Converting $input_file to $output_file..."

  # Get the original frame rate to preserve it exactly
  local framerate=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")

  # Use high quality settings optimized for animations and preserving ALL frames (including duplicates)
  ffmpeg -i "$input_file" \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -pix_fmt yuv420p \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
    -vsync cfr \
    -fps_mode passthrough \
    -movflags +faststart \
    -c:a aac \
    -b:a 192k \
    "$output_file" -y

  if [ $? -eq 0 ]; then
    echo "Successfully converted $input_file to $output_file with preserved frame rate"
  else
    echo "Error converting $input_file"
  fi
}

# Process input
if [ -f "$1" ]; then
  # Single file case
  if [[ "$1" =~ \.webm$ ]]; then
    convert_file "$1"
  else
    echo "Error: $1 is not a .webm file"
    exit 1
  fi
elif [ -d "$1" ]; then
  # Directory case
  echo "Processing all WebM files in directory: $1"
  found_files=0
  for file in "$1"/*.webm; do
    if [ -f "$file" ]; then
      convert_file "$file"
      found_files=1
    fi
  done

  if [ $found_files -eq 0 ]; then
    echo "No WebM files found in $1"
  fi
else
  echo "Error: $1 is neither a file nor a directory"
  exit 1
fi

echo "Conversion process completed!"
