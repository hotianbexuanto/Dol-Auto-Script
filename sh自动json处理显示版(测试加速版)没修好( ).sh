#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"
THREADS=8  # 设置线程数

read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 2.30 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

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
    local processed=0

    export -f update_progress_bar
    export total_files
    export processed

    echo "${files[@]}" | xargs -n 1 -P $THREADS -I {} bash -c '
        file="{}"
        ((processed++))
        update_progress_bar "扫描文件和目录" $processed $total_files "$file"
    '
}

# 处理图像文件并显示进度条
process_image_files() {
    local files=("$@")
    local img_files=()
    local total_files=${#files[@]}
    local processed=0

    for file in "${files[@]}"; do
        if [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.gif ]]; then
            img_files+=("$file")
        fi
    done

    local total_img_files=${#img_files[@]}
    
    for ((i=0; i<total_img_files; i++)); do
        update_progress_bar "保存图像文件" $((i+1)) "$total_img_files" "${img_files[i]}"
    done

    # 一次性将图像文件写入到 JSON 文件中
    echo '  "imgFileList": [' >> "$OUTPUT_FILE"
    for img_file in "${img_files[@]}"; do
        echo "    \"$img_file\"," >> "$OUTPUT_FILE"
    done

    # 删除最后一行的逗号并关闭 JSON 数组
    sed -i '$ s/,$//' "$OUTPUT_FILE"
    echo '  ],' >> "$OUTPUT_FILE"
}

# 初始化 JSON 输出文件
{
    echo "{"
    echo '  "name": "'"$NAME"'",'
    echo '  "version": "'"$VERSION"'",'
    echo '  "scriptFileList_inject_early": [],'
    echo '  "scriptFileList_earlyload": [],'
    echo '  "scriptFileList_preload": [],'
    echo '  "styleFileList": [],'
    echo '  "scriptFileList": [],'
    echo '  "tweeFileList": [],'
} > "$OUTPUT_FILE"

# 扫描文件
mapfile -t files < <(find "$SOURCE_DIR" -type d -o -type f)

# 多线程处理文件
scan_files_and_dirs "${files[@]}"
process_image_files "${files[@]}"

# 关闭 JSON 对象
{
    echo '  "additionFile": [],'
    echo '  "additionBinaryFile": [],'
    echo '  "additionDir": [],'
    echo '  "addonPlugin": [],'
    echo '  "dependenceInfo": ['
    echo '    {'
    echo '      "modName": "ModLoader",'
    echo '      "version": "'"$DEP_VERSION"'"'
    echo '    }'
} >> "$OUTPUT_FILE"

# 添加 GameVersion 条件
if [[ -n "$GAME_VERSION" ]]; then
    {
        echo '    ,'
        echo '    {'
        echo '      "modName": "GameVersion",'
        echo '      "version": "'"$GAME_VERSION"'"'
        echo '    }'
    } >> "$OUTPUT_FILE"
fi

echo '  ]' >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo -e "\n目录结构已保存到 $OUTPUT_FILE"