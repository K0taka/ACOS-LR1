#!/bin/bash

#help message
help_mess() {
  echo "Usage: $0 [-t path_to_save_directory] path_to_working_directory"
  echo "  -t path_to_save_directory"
  echo "     change the method of how the script works: it will create hard links in path_to_save_directory insted of rename files"
  exit 1
}

#initialize path variables
save_dir=""
working_dir=""

#argument parsing
while getopts ":t:" opt; do #pars -t
  case $opt in
  t)
    save_dir="$(realpath "$OPTARG")"
    ;;
  *)
    help_mess
    ;;
  esac
done

#shift positional parameters to get the working directory
shift $((OPTIND - 1))

#get the working directory from the positional argument
if [ "$#" -ne 1 ]; then
  help_mess #should be 1 arg or it's an error
fi

working_dir="$(realpath "$1")"

#check if the working directory exists
if [ ! -d "$working_dir" ]; then
  echo "Error! $working_dir is not found"
  exit 1
fi

#select working directory
cd "$working_dir" || {
  echo "Error: can't get access to working directory. Permission denied"
  exit 1
} #if can't open working_dir show error exit

#check if it is an empty dir
if [ $(ls -l | tail -n +2 | grep -v ^d | wc -l) -eq 0 ]; then
  echo "Error: directory $working_dir is empty"
  exit 1
fi

#find files and save in array
mapfile -t files < <(ls | grep -E '^[A-Za-z0-9]{8}\.mp3$')

#check if there are any files
if [ ${#files[@]} -eq 0 ]; then
  echo "Error: there are no files with 8 letters/digits in filename with .mp3 extension."
  exit 1
fi

#function to process a group of files with the same modification time
process_file_group() {
  local save_dir=$1
  local action=$2 #'ln' or 'mv'

  if [ "$action" == "ln" ]; then
    shift 2
  else
    shift 1
  fi
  local group=("$@")

  if [ ${#group[@]} -eq 1 ]; then
    #if only one file, perform the action directly
    if [ $count -le 999 ]; then
      new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
    else
      new_name=$(printf "Война_и_мир_Часть_%d.mp3" "$count")
    fi

    if [ "$action" == "ln" ]; then
      ln "${group[0]}" "$save_dir/$new_name"
    else
      mv "${group[0]}" "$new_name"
    fi
    ((count++))
  else
    #if multiple files, ask for selection
    echo "There are multiple files with the same modification time."
    for i in "${!group[@]}"; do
      echo "$((i + 1)): ${group[i]}"
    done

    #ask for a number for each file in the group
    for i in "${!group[@]}"; do
      read -p "Select number for the element '${group[i]}': " choice

      #check validity of selection
      while ! [[ $choice =~ ^[1-${#group[@]}]$ ]]; do
        read -p "Error: the number not in [1-${#group[@]}]. Select the number for '${group[i]}': " choice
      done

      if [ $count -le 999 ]; then
        new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
      else
        new_name=$(printf "Война_и_мир_Часть_%d.mp3" "$count")
      fi

      if [ "$action" == "ln" ]; then
        ln "${group[i]}" "$save_dir/$new_name"
      else
        mv "${group[i]}" "$new_name"
      fi
      ((count++))
    done
  fi
}

#main code

if [ -n "$save_dir" ]; then
  if [ ! -d "$save_dir" ]; then
    echo "Error: dir '$save_dir' for saving hard links is not found."
    exit 1
  fi

  action="ln" #use hard link

else
  action="mv" #use rename
fi

#group files by modification time
declare -A file_groups
for file in "${files[@]}"; do
  mod_time=$(stat -c %Y "$file")
  file_groups[$mod_time]+="$file "
done

#iterate over all groups of files
count=1
for mod_time in ${!file_groups[@]}; do
  group=(${file_groups[$mod_time]})
  process_file_group $save_dir $action "${group[@]}"
done

echo "The script completed its work."
