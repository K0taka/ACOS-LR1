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
    echo "Error! Non existed key argument"
    help_mess
    ;;
  esac
done

#shift positional parameters to get the working directory
shift $((OPTIND - 1))

#check if less then 1 arg
if [ "$#" -lt 1 ]; then
  echo "Error! 1 argument: path_to_working_directory required"
  help_mess
fi

#get the working directory from the positional argument
if [ "$#" -ne 1 ]; then
  echo "Error! should be only 1 path_to_working_directory"
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
total_files=$(ls -l | tail -n +2 | grep -v ^d | wc -l)
if [ $total_files -eq 0 ]; then
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

if [ ${#files[@]} -ne $total_files ]; then
  echo "WARNING! There are files that not math the mask of 8 letters/digits in filename with .mp3 extension:"
  ls | grep -Ev '^[A-Za-z0-9]{8}\.mp3'
  echo "They will be ignored"
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
    declare -A selections
    echo "There are multiple files with the same modification time."
    for i in "${!group[@]}"; do
      echo "$((i + 1)): ${group[i]}"
    done

    #request number for each file
    for i in "${!group[@]}"; do
      while true; do
        read -p "Select number for the element '${group[i]}': " choice

        #validate number
        if [[ $choice =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#group[@]}" ]; then
          #check it wasn't chosen earlier
          if [[ -z ${selections[$choice]} ]]; then
            selections[$choice]=${group[i]}
            break
          else
            echo "Error: The number $choice has already been assigned to '${selections[$choice]}'. Please choose a different number."
          fi
        else
          echo "Error: The number is not in [1-${#group[@]}]."
        fi
      done
    done

    positions=$(printf "%s\n" "${!selections[@]}" | sort -n)
    for i in ${positions[@]}; do
      if [ $count -le 999 ]; then
        new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
      else
        new_name=$(printf "Война_и_мир_Часть_%d.mp3" "$count")
      fi

      if [ "$action" == "ln" ]; then
        ln "${selections[$i]}" "$save_dir/$new_name"
      else
        mv "${selections[$i]}" "$new_name"
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
  if [ $(ls -l $save_dir | tail -n +2 | grep -v ^d | wc -l) -ne 0 ]; then
    echo "Error: dir '$save_dir' is not empty!"
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

#array to save a sorted modification
sorted_mod_times=($(printf "%s\n" "${!file_groups[@]}" | sort -n))

#iterate over all groups of files
count=1
for mod_time in ${sorted_mod_times[@]}; do
  group=(${file_groups[$mod_time]})
  process_file_group $save_dir $action "${group[@]}"
done

echo "The script completed its work."
