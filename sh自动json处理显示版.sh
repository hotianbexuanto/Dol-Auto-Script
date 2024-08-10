#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"

read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

# 创建临时文件来保存目录结构
TEMP_FILE=$(mktemp)

# Function to update the progress bar and display task info
update_progress_bar() {
    local task_name=$1
    local progress=$2
    local total=$3
    local current_file=$4

    if [ "$total" -eq 0 ]; then
        percent=100
    else
        percent=$(( progress * 100 / total ))
    fi

    local width=50
    local filled=$(( percent * width / 100 ))
    local unfilled=$(( width - filled ))
    local bar=$(printf "%${filled}s" | tr ' ' '#')
    bar+=$(printf "%${unfilled}s" | tr ' ' '.')

    # 清除屏幕上的行，确保进度条和文件名分别显示在不同的行
    printf "\r\033[K当前文件: %s" "$current_file"
    printf "\n\033[K%s [%-${width}s] %d%%" "$task_name" "$bar" "$percent"
    printf "\n\033[K正在处理: %s" "$task_name"
}

# 扫描文件和目录并显示进度条
scan_files_and_dirs() {
    local files=("$@")
    local total_files=${#files[@]}

    for ((i=0; i<total_files; i++)); do
        update_progress_bar "扫描文件和目录" $((i+1)) "$total_files" "${files[i]}"
    done
}

# 处理图像文件并显示进度条
process_image_files() {
    local files=("$@")
    local total_files=${#files[@]}
    local img_files=()

    for file in "${files[@]}"; do
        if [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.gif ]]; then
            img_files+=("$file")
        fi
    done

    local total_img_files=${#img_files[@]}
    for ((i=0; i<total_img_files; i++)); do
        update_progress_bar "处理图像文件" $((i+1)) "$total_img_files" "${img_files[i]}"
    done
}

# 处理其他文件并显示进度条
process_other_files() {
    local files=("$@")
    local total_files=${#files[@]}
    local other_files=()

    for file in "${files[@]}"; do
        if [[ -f "$file" && "$file" != *.png && "$file" != *.jpg && "$file" != *.gif ]]; then
            other_files+=("$file")
        fi
    done

    local total_other_files=${#other_files[@]}
    for ((i=0; i<total_other_files; i++)); do
        update_progress_bar "处理其他文件" $((i+1)) "$total_other_files" "${other_files[i]}"
    done
}

# 处理目录并显示进度条
process_directories() {
    local files=("$@")
    local total_files=${#files[@]}
    local dir_files=()

    for file in "${files[@]}"; do
        if [[ -d "$file" ]]; then
            dir_files+=("$file")
        fi
    done

    local total_dir_files=${#dir_files[@]}
    for ((i=0; i<total_dir_files; i++)); do
        update_progress_bar "处理目录" $((i+1)) "$total_dir_files" "${dir_files[i]}"
    done
}

# 保存目录结构并显示进度条
save_directory_structure() {
    local files=("$@")
    local img_files=0
    local other_files=0
    local dir_files=0

    for file in "${files[@]}"; do
        if [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.gif ]]; then
            img_files=$((img_files + 1))
        elif [[ -f "$file" && "$file" != *.png && "$file" != *.jpg && "$file" != *.gif ]]; then
            other_files=$((other_files + 1))
        elif [[ -d "$file" ]]; then
            dir_files=$((dir_files + 1))
        fi
    done

    local save_total=$((img_files + other_files + dir_files))
    local save_processed=0

    for file in "${files[@]}"; do
        if [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.gif ]]; then
            save_processed=$((save_processed + 1))
            update_progress_bar "保存图像文件" "$save_processed" "$save_total" "$file"
            echo "    \"$file\"," >> "$OUTPUT_FILE"
        elif [[ -f "$file" && "$file" != *.png && "$file" != *.jpg && "$file" != *.gif ]]; then
            save_processed=$((save_processed + 1))
            update_progress_bar "保存其他文件" "$save_processed" "$save_total" "$file"
            echo "    \"$file\"," >> "$OUTPUT_FILE"
        elif [[ -d "$file" ]]; then
            save_processed=$((save_processed + 1))
            update_progress_bar "保存目录" "$save_processed" "$save_total" "$file"
            echo "    \"$file\"," >> "$OUTPUT_FILE"
        fi
    done

    echo '  ],' >> "$OUTPUT_FILE"
    echo '  "addonPlugin": [],' >> "$OUTPUT_FILE"
    echo '  "dependenceInfo": [' >> "$OUTPUT_FILE"
    echo '    {' >> "$OUTPUT_FILE"
    echo '      "modName": "ModLoader",' >> "$OUTPUT_FILE"
    echo '      "version": "'"$DEP_VERSION"'"' >> "$OUTPUT_FILE"
    echo '    }' >> "$OUTPUT_FILE"

    if [[ -n "$GAME_VERSION" ]]; then
        echo '    ,' >> "$OUTPUT_FILE"
        echo '    {' >> "$OUTPUT_FILE"
        echo '      "modName": "GameVersion",' >> "$OUTPUT_FILE"
        echo '      "version": "'"$GAME_VERSION"'"' >> "$OUTPUT_FILE"
    fi

    echo '  ]' >> "$OUTPUT_FILE"
    echo "}" >> "$OUTPUT_FILE"
}

# 主流程
mapfile -t files < <(find "$SOURCE_DIR" -type d -o -type f)

# 调用函数来处理各个阶段
scan_files_and_dirs "${files[@]}"
process_image_files "${files[@]}"
process_other_files "${files[@]}"
process_directories "${files[@]}"
save_directory_structure "${files[@]}"

# 删除临时文件
rm "$TEMP_FILE"

echo -e "\n目录结构已保存到 $OUTPUT_FILE"