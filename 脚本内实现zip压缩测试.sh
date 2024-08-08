#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"
ZIP_FILE="output.zip"

read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

# 创建临时文件来保存目录结构
TEMP_FILE=$(mktemp)

# 递归遍历指定目录的结构并将结果保存到临时文件中
find "$SOURCE_DIR" -type d -print > "$TEMP_FILE"
find "$SOURCE_DIR" -type f -print >> "$TEMP_FILE"

# 准备 JSON 输出
echo "{" > "$OUTPUT_FILE"
echo '  "name": "'"$NAME"'",' >> "$OUTPUT_FILE"
echo '  "version": "'"$VERSION"'",' >> "$OUTPUT_FILE"
echo '  "scriptFileList_inject_early": [],' >> "$OUTPUT_FILE"
echo '  "scriptFileList_earlyload": [],' >> "$OUTPUT_FILE"
echo '  "scriptFileList_preload": [],' >> "$OUTPUT_FILE"
echo '  "styleFileList": [],' >> "$OUTPUT_FILE"
echo '  "scriptFileList": [],' >> "$OUTPUT_FILE"
echo '  "tweeFileList": [],' >> "$OUTPUT_FILE"
echo '  "imgFileList": [' >> "$OUTPUT_FILE"

# 读取临时文件并将图像文件路径转换为 JSON 格式
first=true
while IFS= read -r line; do
    if [[ -f "$line" && ( "$line" == *.png || "$line" == *.jpg || "$line" == *.gif ) ]]; then
        if [ "$first" = true ]; then
            first=false
        else
            echo ',' >> "$OUTPUT_FILE"
        fi
        echo "    \"$line\"" >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 结束 imgFileList 数组
echo '  ],' >> "$OUTPUT_FILE"
echo '  "additionFile": [' >> "$OUTPUT_FILE"

# 读取临时文件并将所有文件路径写入 JSON 文件
first=true
while IFS= read -r line; do
    if [[ -f "$line" && "$line" != *.png && "$line" != *.jpg && "$line" != *.gif ]]; then
        if [ "$first" = true ]; then
            first=false
        else
            echo ',' >> "$OUTPUT_FILE"
        fi
        echo "    \"$line\"" >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 结束 additionFile 数组
echo '  ],' >> "$OUTPUT_FILE"
echo '  "additionBinaryFile": [],' >> "$OUTPUT_FILE"
echo '  "additionDir": [' >> "$OUTPUT_FILE"

# 读取临时文件并将目录路径写入 JSON 文件
first=true
while IFS= read -r line; do
    if [[ -d "$line" ]]; then
        if [ "$first" = true ]; then
            first=false
        else
            echo ',' >> "$OUTPUT_FILE"
        fi
        echo "    \"$line\"" >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 结束 additionDir 数组
echo '  ],' >> "$OUTPUT_FILE"
echo '  "addonPlugin": [],' >> "$OUTPUT_FILE"
echo '  "dependenceInfo": [' >> "$OUTPUT_FILE"
echo '    {' >> "$OUTPUT_FILE"
echo '      "modName": "ModLoader",' >> "$OUTPUT_FILE"
echo '      "version": "'"$DEP_VERSION"'"' >> "$OUTPUT_FILE"
echo '    }' >> "$OUTPUT_FILE"

# 添加 GameVersion 条件
if [[ -n "$GAME_VERSION" ]]; then
    echo '    ,' >> "$OUTPUT_FILE"
    echo '    {' >> "$OUTPUT_FILE"
    echo '      "modName": "GameVersion",' >> "$OUTPUT_FILE"
    echo '      "version": "'"$GAME_VERSION"'"' >> "$OUTPUT_FILE"
    echo '    }' >> "$OUTPUT_FILE"
fi

echo '  ]' >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

# 删除临时文件
rm "$TEMP_FILE"

# 函数：计算CRC32
crc32() {
    local file=$1
    local crc=0xFFFFFFFF
    local polynomial=0xEDB88320
    local i
    local byte
    local table=()

    # 生成CRC32表
    for i in {0..255}; do
        local crc_val=$i
        for ((j = 0; j < 8; j++)); do
            if ((crc_val & 1)); then
                crc_val=$((crc_val >> 1))
                crc_val=$((crc_val ^ polynomial))
            else
                crc_val=$((crc_val >> 1))
            fi
        done
        table[i]=$crc_val
    done

    # 计算CRC32
    while IFS= read -r -n1 byte; do
        local byte_val=$(printf '%d' "'$byte")
        crc=$((crc ^ byte_val))
        for ((i = 0; i < 8; i++)); do
            if ((crc & 1)); then
                crc=$((crc >> 1))
                crc=$((crc ^ polynomial))
            else
                crc=$((crc >> 1))
            fi
        done
    done < "$file"

    printf '%08x\n' $((crc ^ 0xFFFFFFFF))
}

# 函数：创建ZIP文件
create_zip() {
    local zip_file=$1
    local base_dir=$2

    local temp_zip_file=$(mktemp)
    local central_directory_offset=0

    # 写入ZIP文件头
    echo -ne "PK\x03\x04\x14\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > "$temp_zip_file"
    
    # 获取文件和目录的总数
    local total_items=$(find "$base_dir" -type f -o -type d | wc -l)
    local current_item=0

    # 遍历文件并写入ZIP内容
    local total_files=0
    local total_directories=0
    local file_offset=0

    echo "开始压缩文件中..."

    while IFS= read -r file; do
        current_item=$((current_item + 1))
        local progress=$((current_item * 100 / total_items))
        printf "\r压缩进度: [%-50s] %d%%" "$(head -c $((progress / 2)) < /dev/zero | tr '\0' '#')" "$progress"

        if [[ -f "$file" ]]; then
            local name=$(basename "$file")
            local size=$(stat -c%s "$file")
            local crc=$(crc32 "$file")
            local name_length=${#name}

            # 文件头
            echo -ne "PK\x01\x02\x14\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$temp_zip_file"
            printf "%04x%04x%08x%08x%08x%04x%04x%04x%04x" "$name_length" 0 0 "$size" "$size" 0 0 0 0 >> "$temp_zip_file"
            echo -ne "$name" >> "$temp_zip_file"
            cat "$file" >> "$temp_zip_file"
            
            # 更新中心目录位置
            central_directory_offset=$(stat -c%s "$temp_zip_file")
            total_files=$((total_files + 1))
        elif [[ -d "$file" ]]; then
            local dir_name=$(basename "$file")
            local name_length=${#dir_name}
            echo -ne "PK\x01\x02\x14\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$temp_zip_file"
            printf "%04x%04x%08x%08x%08x%04x%04x%04x%04x" "$name_length" 0 0 0 0 0 0 0 0 >> "$temp_zip_file"
            echo -ne "$dir_name" >> "$temp_zip_file"
            total_directories=$((total_directories + 1))
        fi
    done < <(find "$base_dir" -print)

    # 写入中心目录记录
    echo -ne "PK\x05\x06\x00\x00\x00\x00\x00\x00\x00\x00" >> "$temp_zip_file"
    printf "%04x%04x%08x%08x%08x" 0 0 "$total_directories" "$total_files" "$central_directory_offset" >> "$temp_zip_file"
    
    mv "$temp_zip_file" "$zip_file"
    echo
    echo "压缩完成。ZIP 文件已创建: $ZIP_FILE"
}

# 创建临时目录用于打包
TEMP_DIR=$(mktemp -d)
cp "$OUTPUT_FILE" "$TEMP_DIR"
cp -r "$SOURCE_DIR" "$TEMP_DIR"

# 创建 ZIP 文件
create_zip "$ZIP_FILE" "$TEMP_DIR"

# 删除临时目录
rm -r "$TEMP_DIR"
