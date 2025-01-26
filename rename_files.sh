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

#check save dir exitsting
if [ -n "$save_dir" ]; then
  if [ ! -d "$save_dir" ]; then
    echo "Error: dir '$save_dir' for saving hard links is not found"
    exit 1
  fi

  #variable to save the number of file
  count=1

  # Создаем ассоциативный массив для хранения файлов с одинаковым временем изменения
  declare -A file_groups

  # Сортируем файлы по времени изменения и группируем их по времени
  for file in ${files[@]}; do
    mod_time=$(stat -c %Y $file)
    file_groups[$mod_time]+="$file "
  done

  # Создаем хардлинки, учитывая возможные дубликаты по времени изменения
  for mod_time in ${!file_groups[@]}; do
    group=(${file_groups[$mod_time]})

    if [ ${#group[@]} -eq 1 ]; then
      # Если только один файл в группе, создаем хардлинк напрямую
      new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
      ln $file $save_dir/$new_name
      ((count++))
    else
      # Если несколько файлов с одинаковым временем, запрашиваем у пользователя выбор
      echo "There is some files with the same change time"
      for i in ${!group[@]}; do
        echo "$((i + 1)): ${group[i]}"
      done

      # Запрашиваем номер для каждого файла в группе
      for i in ${!group[@]}; do
        read -p "Select number for the element '${group[i]}': " choice

        # Проверяем корректность выбора (должен быть в пределах группы)
        while ! [[ $choice =~ ^[1-${#group[@]}]$ ]]; do
          read -p "Error: the number not in [1-${#group[@]}]. Select the number for '${group[i]}': " choice
        done

        new_name=$(printf "Война_и_мир_Часть_%03d.mp3" "$count")
        ln ${group[i]} $save_dir/$new_name
        ((count++))
      done
    fi
  done

else
  # Переименовываем файлы, если не указана директория для сохранения хардлинков
  count=1

  # Создаем ассоциативный массив для хранения файлов с одинаковым временем изменения
  declare -A file_groups

  # Сортируем файлы по времени изменения и группируем их по времени
  for file in ${files[@]}; do
    mod_time=$(stat -c %Y $file)
    file_groups[$mod_time]+="$file "
  done

  # Переименовываем файлы, учитывая возможные дубликаты по времени изменения
  for mod_time in ${!file_groups[@]}; do
    group=(${file_groups[$mod_time]})

    if [ ${#group[@]} -eq 1 ]; then
      # Если только один файл в группе, переименовываем его напрямую
      new_name=$(printf "Война_и_мир_Часть_%03d.mp3" $count)
      mv ${group[0]} $new_name
      ((count++))
    else
      # Если несколько файлов с одинаковым временем, запрашиваем у пользователя выбор
      echo "There is some files with the same change time"
      for i in ${!group[@]}; do
        echo "$((i + 1)): ${group[i]}"
      done

      # Запрашиваем номер для каждого файла в группе
      for i in ${!group[@]}; do
        read -p "Выберите номер для '${group[i]}': " choice

        # Проверяем корректность выбора (должен быть в пределах группы)
        while ! [[ $choice =~ ^[1-${#group[@]}]$ ]]; do
          read -p "Error: the number not in [1-${#group[@]}]. Select the number for '${group[i]}': " choice
        done

        new_name=$(printf "Война_и_мир_Часть_%03d.mp3" $count)
        mv ${group[i]} $new_name
        ((count++))
      done
    fi
  done
fi

echo "The skript completed its work"
