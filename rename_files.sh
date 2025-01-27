#!/bin/bash

#help message
help_mess() {
  echo "Usage: $0 [-d path_to_working_directory] [-t path_to_save_directory]"
  exit 1
}

working_dir=$(pwd)
save_dir=""

#args parsing
while getopts ":d:t:" opt; do
  case $opt in
  d)
    working_dir="$(realpath "$OPTARG")"
    ;;
  t)
    save_dir="$(realpath "$OPTARG")"
    ;;
  *)
    help_mess
    ;;
  esac
done

#working directory exitsting test
if [ ! -d "$working_dir" ]; then
  echo "Error! $working_dir is not found"
  exit 1
fi

#select working directory
cd $working_dir

#find files and save in array
mapfile -t files < <(ls | grep -E '^[A-Za-z0-9]{8}\.mp3$')

#check if there is any file
if [ ${#files[@]} -eq 0 ]; then
  echo "Error: there is no files with 8 letters/digits in filename with .mp3 extension'"
  exit 1
fi

#Функция для группировки файлов по времени изменения
group_files_by_mod_time() {
  declare -A file_groups
  for file in ${files[@]}; do
    mod_time=$(stat -c %Y $file)
    file_groups[$mod_time]+="$file "
  done
  echo "${file_groups[@]}"
}

#Функция для обработки группы файлов с одинаковым временем изменения
process_file_group() {
  local group=("$1")
  local count=$2
  local save_dir=$3
  local action=$4 #'ln' или 'mv'

  if [ ${#group[@]} -eq 1 ]; then
    #Если только один файл, выполняем действие
    new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
    if [ "$action" == "ln" ]; then
      ln ${group[0]} $save_dir/$new_name
    else
      mv ${group[0]} $new_name
    fi
    ((count++))
  else
    #Если несколько файлов, запрашиваем выбор
    echo "There are multiple files with the same modification time"
    for i in ${!group[@]}; do
      echo "$((i + 1)): ${group[i]}"
    done

    #Запрашиваем номер для каждого файла
    for i in ${!group[@]}; do
      read -p "Select number for the element '${group[i]}': " choice

      #Проверяем корректность выбора
      while ! [[ $choice =~ ^[1-${#group[@]}]$ ]]; do
        read -p "Error: the number not in [1-${#group[@]}]. Select the number for '${group[i]}': " choice
      done

      new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
      if [ "$action" == "ln" ]; then
        ln ${group[i]} $save_dir/$new_name
      else
        mv ${group[i]} $new_name
      fi
      ((count++))
    done
  fi
}

#Основной код

if [ -n "$save_dir" ]; then
  if [ ! -d "$save_dir" ]; then
    echo "Error: dir '$save_dir' for saving hard links is not found"
    exit 1
  fi
  action="ln" #Используем hard link
else
  action="mv" #Используем переименование
fi

#Группируем файлы по времени изменения
file_groups=$(group_files_by_mod_time)

#Перебираем все группы файлов
count=1
for mod_time in ${!file_groups[@]}; do
  group=(${file_groups[$mod_time]})
  process_file_group "$group" $count $save_dir $action
done

echo "The script completed its work"
