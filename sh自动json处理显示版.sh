#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"

read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

# 创建临时文件来保存目录结构
TEMP_FILE=$(mktemp)

# 批量读取目录内容并存储在内存中
mapfile -t files < <(find "$SOURCE_DIR" -type d -o -type f)

# 计算总文件数
total_files=${#files[@]}

# Function to update the progress bar
update_progress_bar() {
    local bar_index=$1
    local progress=$2
    local total=$3
    local percent=$(( progress * 100 / total ))
    local width=50
    local filled=$(( percent * width / 100 ))
    local unfilled=$(( width - filled ))
    local bar=$(printf "%${filled}s" | tr ' ' '#')
    bar+=$(printf "%${unfilled}s" | tr ' ' '.')

    # Move to the correct line for the specific progress bar
    printf "\r%s [%-${width}s] %d%%" "$bar_index" "$bar" "$percent"
}

# 1. 扫描文件和目录
echo -e "\n扫描文件和目录："
update_progress_bar "扫描文件和目录" 0 "$total_files"
{
    for ((i=0; i<total_files; i++)); do
        echo "${files[i]}"
        update_progress_bar "扫描文件和目录" $((i+1)) "$total_files"
    done
    echo
} > "$TEMP_FILE"

# 图像文件数量
img_files=$(find "$SOURCE_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" \) | wc -l)

# 2. 处理图像文件列表
echo -e "\n处理图像文件："
update_progress_bar "处理图像文件" 0 "$img_files"
{
    img_processed=0
    for ((i=0; i<total_files; i++)); do
        if [[ "${files[i]}" == *.png || "${files[i]}" == *.jpg || "${files[i]}" == *.gif ]]; then
            echo "    \"${files[i]}\","
            img_processed=$((img_processed + 1))
            update_progress_bar "处理图像文件" "$img_processed" "$img_files"
        fi
    done
    echo
} > /dev/null  # 防止输出影响进度条

# 其他文件数量
other_files=$(find "$SOURCE_DIR" -type f ! \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" \) | wc -l)

# 3. 处理其他文件
echo -e "\n处理其他文件："
update_progress_bar "处理其他文件" 0 "$other_files"
{
    other_processed=0
    for ((i=0; i<total_files; i++)); do
        if [[ -f "${files[i]}" && "${files[i]}" != *.png && "${files[i]}" != *.jpg && "${files[i]}" != *.gif ]]; then
            echo "    \"${files[i]}\","
            other_processed=$((other_processed + 1))
            update_progress_bar "处理其他文件" "$other_processed" "$other_files"
        fi
    done
    echo
} > /dev/null

# 目录数量
dir_files=$(find "$SOURCE_DIR" -type d | wc -l)

# 4. 处理目录列表
echo -e "\n处理目录："
update_progress_bar "处理目录" 0 "$dir_files"
{
    dir_processed=0
    for ((i=0; i<total_files; i++)); do
        if [[ -d "${files[i]}" ]]; then
            echo "    \"${files[i]}\","
            dir_processed=$((dir_processed + 1))
            update_progress_bar "处理目录" "$dir_processed" "$dir_files"
        fi
    done
    echo
} > /dev/null

# 5. 保存目录结构到 JSON 文件
echo -e "\n保存目录结构："
save_total=$((img_files + other_files + dir_files))
update_progress_bar "保存目录结构" 0 "$save_total"
{
    save_processed=0

    echo "{"
    echo '  "name": "'"$NAME"'",'
    echo '  "version": "'"$VERSION"'",'
    echo '  "scriptFileList_inject_early": [],'
    echo '  "scriptFileList_earlyload": [],'
    echo '  "scriptFileList_preload": [],'
    echo '  "styleFileList": [],'
    echo '  "scriptFileList": [],'
    echo '  "tweeFileList": [],'
    echo '  "imgFileList": ['

    for ((i=0; i<total_files; i++)); do
        if [[ "${files[i]}" == *.png || "${files[i]}" == *.jpg || "${files[i]}" == *.gif ]]; then
            echo "    \"${files[i]}\","
            save_processed=$((save_processed + 1))
            update_progress_bar "保存目录结构" "$save_processed" "$save_total"
        fi
    done

    echo '  ],'
    echo '  "additionFile": ['

    for ((i=0; i<total_files; i++)); do
        if [[ -f "${files[i]}" && "${files[i]}" != *.png && "${files[i]}" != *.jpg && "${files[i]}" != *.gif ]]; then
            echo "    \"${files[i]}\","
            save_processed=$((save_processed + 1))
            update_progress_bar "保存目录结构" "$save_processed" "$save_total"
        fi
    done

    echo '  ],'
    echo '  "additionBinaryFile": [],'
    echo '  "additionDir": ['

    for ((i=0; i<total_files; i++)); do
        if [[ -d "${files[i]}" ]]; then
            echo "    \"${files[i]}\","
            save_processed=$((save_processed + 1))
            update_progress_bar "保存目录结构" "$save_processed" "$save_total"
        fi
    done

    echo '  ],'
    echo '  "addonPlugin": [],'
    echo '  "dependenceInfo": ['

    echo '    {'
    echo '      "modName": "ModLoader",'
    echo '      "version": "'"$DEP_VERSION"'"'
    echo '    }'

    if [[ -n "$GAME_VERSION" ]]; then
        echo '    ,'
        echo '    {'
        echo '      "modName": "GameVersion",'
        echo '      "version": "'"$GAME_VERSION"'"'
    fi

    echo '  ]'
    echo "}"
} > "$OUTPUT_FILE"

# 删除临时文件
rm "$TEMP_FILE"

echo -e "\n目录结构已保存到 $OUTPUT_FILE"