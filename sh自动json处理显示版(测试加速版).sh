#!/bin/bash

# 设置目录变量
SOURCE_DIR="img"
OUTPUT_FILE="boot.json"

# 检查 SOURCE_DIR 是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误：目录 $SOURCE_DIR 不存在！"
    exit 1
fi

read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

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
    echo '  "imgFileList": ['
} > "$OUTPUT_FILE"

# 使用 ls 和 xargs 提高扫描速度，并将结果保存在数组中
mapfile -t files < <(ls -R "$SOURCE_DIR" | grep -E '\.png$|\.jpg$|\.gif$|^[^./]' | xargs -I{} echo "$SOURCE_DIR"/{})

total_files=${#files[@]}

# 更新进度条并显示任务信息的函数
update_progress_bar() {
    local task_name=$1
    local progress=$2
    local total=$3
    local current_file=$4

    if [ "$total" -eq 0 ];then
        percent=100
    else
        percent=$(( progress * 100 / total ))
    fi

    local width=50
    local filled=$(( percent * width / 100 ))
    local unfilled=$(( width - filled ))
    local bar=$(printf "%${filled}s" | tr ' ' '#')
    bar+=$(printf "%${unfilled}s" | tr ' ' '.')

    printf "\r\033[K当前文件: %s" "$current_file"
    printf "\n\033[K%s [%-${width}s] %d%%" "$task_name" "$bar" "$percent"
    printf "\n\033[K正在处理: %s" "$task_name"
}

# 处理图像文件并显示进度条
process_image_files() {
    local files=("$@")
    local img_json=""
    local total_files=${#files[@]}

    for ((i=0; i<total_files; i++)); do
        local file="${files[i]}"
        if [[ "$file" == *.png || "$file" == *.jpg || "$file" == *.gif ]]; then
            img_json+="    \"$file\",\n"
        fi
        update_progress_bar "保存图像文件" $((i+1)) "$total_files" "$file"
    done

    # 写入所有图像文件到 JSON 文件，并删除最后一行的逗号
    echo -e "${img_json%,}" >> "$OUTPUT_FILE"
}

# 扫描文件
process_image_files "${files[@]}"

# 关闭 JSON 数组和对象
{
    echo '  ],'
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
    } >> "$OUTPUT_FILE"
fi

{
    echo '  ]'
    echo "}"
} >> "$OUTPUT_FILE"

echo -e "\n目录结构已保存到 $OUTPUT_FILE"