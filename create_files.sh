#!/bin/bash
examples_path=$(pwd)/examples
if [ -d $examples_path ]; then
  echo "Error! The examples dir is already exists at the path \"$examples_path\"!"
  exit 1
fi

#creating dirs for the testing situations
mkdir $examples_path
mkdir $examples_path/{no_files,files_x5,files_x100,created_at_the_same_time,incorrect_names,incorrect_extension,files_x1,files_x1000, no_match}

#function to generate correct filenames
#arg1 = length of name, base = 8
#arg2 = file extention, base = .mp3
generate_name() {
  #variables
  length=8
  extention="mp3"

  #get args
  case $# in
  1)
    length=$1
    ;;
  2)
    length=$1
    extention=$2
    ;;
  esac

  #using urandom data with deleted symbols except \d\w take first 8 bytes
  echo "$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $length).$extention"
}

#function to generate some files with one extention in one dir
#arg1 = the number of files to created_at_the_same_time
#arg2 = target dir
#arg3 = length of names, base = 8
#arg4 = extention of files, base = mp3
generate_files() {
  for ((i = 0; i < $1; i++)); do
    touch $examples_path/$2/$(
      case $# in
      2)
        generate_name
        ;;
      3)
        generate_name $3
        ;;
      4)
        generate_name $3 $4
        ;;
      esac
    )
    sleep 1
  done
}

#for no_files there is no need to generate any files

#for no_match generate files with errors
generate_files 5 no_match 7 wav

#for files_x1 generate 1 file with correct name
touch $examples_path/files_x1/$(generate_name)

#for files_x5 generate 5 files with correct name
generate_files 5 files_x5

#for files_x100 generate 100 files with correct name
generate_files 100 files_x100

#for files_x1000 generate 1000 files with correct name
generate_files 1000 files_x1000

#creating some files with diff timestamps
generate_files 3 created_at_the_same_time
#creating files with the same timestamps
touch $examples_path/created_at_the_same_time/{$(generate_name),$(generate_name),$(generate_name)}

#creating correct files
generate_files 3 incorrect_names
#creating some files with incorrect names
touch $examples_path/incorrect_names/incorrrect_file_name.mp3
touch $examples_path/incorrect_names/just_a_file.mp3
touch $examples_path/incorrect_names/a1b2c3.mp3
#creating some files with incorrect names (length = 4)
generate_files 3 incorrect_names 4

#creating correct files
generate_files 3 incorrect_extension
#creating some files with incorrect extension
generate_files 2 incorrect_extension 8 mp4
generate_files 3 incorrect_extension 8 png
generate_files 3 incorrect_extension 8 wav
