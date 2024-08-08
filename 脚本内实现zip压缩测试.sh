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
find "$SOURCE_DIR" -type d -exec echo '{}' \; > "$TEMP_FILE"
find "$SOURCE_DIR" -type f -exec echo '{}' \; >> "$TEMP_FILE"

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
while IFS= read -r line; do
    if [[ "$line" == *.png || "$line" == *.jpg || "$line" == *.gif ]]; then
        echo "    \"$line\"," >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 删除最后一行的逗号并关闭 JSON 数组
sed -i '$ s/,$//' "$OUTPUT_FILE"
echo '  ],' >> "$OUTPUT_FILE"
echo '  "additionFile": [' >> "$OUTPUT_FILE"

# 读取临时文件并将所有文件和目录路径写入 JSON 文件
while IFS= read -r line; do
    if [[ -f "$line" && "$line" != *.png && "$line" != *.jpg && "$line" != *.gif ]]; then
        echo "    \"$line\"," >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 删除最后一行的逗号并关闭 JSON 数组
sed -i '$ s/,$//' "$OUTPUT_FILE"
echo '  ],' >> "$OUTPUT_FILE"

echo '  "additionBinaryFile": [],' >> "$OUTPUT_FILE"
echo '  "additionDir": [' >> "$OUTPUT_FILE"

# 读取临时文件并将目录路径写入 JSON 文件
while IFS= read -r line; do
    if [[ -d "$line" ]]; then
        echo "    \"$line\"," >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

# 删除最后一行的逗号并关闭 JSON 数组
sed -i '$ s/,$//' "$OUTPUT_FILE"
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

# 创建临时目录用于打包
TEMP_DIR=$(mktemp -d)
cp "$OUTPUT_FILE" "$TEMP_DIR"
cp -r "$SOURCE_DIR" "$TEMP_DIR"

# 辅助函数：将字节写入文件
write_bytes() {
    local data=$1
    echo -n -e "$data" >> "$ZIP_FILE"
}

# 计算文件的 CRC32 值(由于mt管理器的终端里没有)
calculate_crc32() {
    local file=$1
    local sha256=$(sha256sum "$file" | cut -d' ' -f1)
    local crc32=${sha256:0:8}
    echo "$crc32"
}

# 创建本地文件头
create_local_file_header() {
    local file=$1
    local crc32=$2
    local compressed_size=$3
    local uncompressed_size=$4
    local filename=$(basename "$file")
    
    write_bytes "\x50\x4B\x03\x04"           # 本地文件头签名
    write_bytes "\x14\x00"                   # 解压缩所需的版本 (2.0)
    write_bytes "\x00\x00"                   # 通用位标记
    write_bytes "\x00\x00"                   # 压缩方法 (仅存储)
    write_bytes "\x00\x00"                   # 文件最后修改时间
    write_bytes "\x00\x00"                   # 文件最后修改日期
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $((${crc32:0:2} & 0xFF)) $((${crc32:2:2} & 0xFF)) $((${crc32:4:2} & 0xFF)) $((${crc32:6:2} & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($compressed_size >> 24 & 0xFF)) $(($compressed_size >> 16 & 0xFF)) $(($compressed_size >> 8 & 0xFF)) $(($compressed_size & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($uncompressed_size >> 24 & 0xFF)) $(($uncompressed_size >> 16 & 0xFF)) $(($uncompressed_size >> 8 & 0xFF)) $(($uncompressed_size & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x' $((${#filename} >> 8 & 0xFF)) $((${#filename} & 0xFF)))"
    write_bytes "\x00\x00"                   # 额外字段长度
    write_bytes "$filename"                  # 文件名
}

# 创建中央目录头
create_central_directory_header() {
    local file=$1
    local crc32=$2
    local compressed_size=$3
    local uncompressed_size=$4
    local offset=$5
    local filename=$(basename "$file")
    
    write_bytes "\x50\x4B\x01\x02"           # 中央目录文件头签名
    write_bytes "\x14\x00"                   # 版本
    write_bytes "\x14\x00"                   # 解压缩所需的版本 (2.0)
    write_bytes "\x00\x00"                   # 通用位标记
    write_bytes "\x00\x00"                   # 压缩方法 (仅存储)
    write_bytes "\x00\x00"                   # 文件最后修改时间
    write_bytes "\x00\x00"                   # 文件最后修改日期
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $((${crc32:0:2} & 0xFF)) $((${crc32:2:2} & 0xFF)) $((${crc32:4:2} & 0xFF)) $((${crc32:6:2} & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($compressed_size >> 24 & 0xFF)) $(($compressed_size >> 16 & 0xFF)) $(($compressed_size >> 8 & 0xFF)) $(($compressed_size & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($uncompressed_size >> 24 & 0xFF)) $(($uncompressed_size >> 16 & 0xFF)) $(($uncompressed_size >> 8 & 0xFF)) $(($uncompressed_size & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x' $((${#filename} >> 8 & 0xFF)) $((${#filename} & 0xFF)))"
    write_bytes "\x00\x00"                   # 额外字段长度
    write_bytes "\x00\x00"                   # 文件注释长度
    write_bytes "\x00\x00"                   # 磁盘编号
    write_bytes "\x00\x00"                   # 内部文件属性
    write_bytes "\x00\x00\x00\x00"           # 外部文件属性
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($offset >> 24 & 0xFF)) $(($offset >> 16 & 0xFF)) $(($offset >> 8 & 0xFF)) $(($offset & 0xFF)))"
    write_bytes "$filename"                  # 文件名
}

# 创建中央目录结束记录
create_end_of_central_directory_record() {
    local central_directory_size=$1
    local central_directory_offset=$2
    write_bytes "\x50\x4B\x05\x06"           # 中央目录结束签名
    write_bytes "\x00\x00"                   # 磁盘编号
    write_bytes "\x00\x00"                   # 开始的中央目录磁盘编号
    write_bytes "\x01\x00"                   # 本磁盘的中央目录记录数
    write_bytes "\x01\x00"                   # 中央目录总记录数
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($central_directory_size >> 24 & 0xFF)) $(($central_directory_size >> 16 & 0xFF)) $(($central_directory_size >> 8 & 0xFF)) $(($central_directory_size & 0xFF)))"
    write_bytes "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(($central_directory_offset >> 24 & 0xFF)) $(($central_directory_offset >> 16 & 0xFF)) $(($central_directory_offset >> 8 & 0xFF)) $(($central_directory_offset & 0xFF)))"
    write_bytes "\x00\x00"                   # 注释长度
}

# 初始化 ZIP 文件
echo -n > "$ZIP_FILE"

# 变量跟踪偏移量和大小
offset=0
central_directory_size=0
central_directory_offset=0

# 添加文件到 ZIP 文件
for file in "$TEMP_DIR"/*; do
    if [[ -f "$file" ]]; then
        crc32=$(calculate_crc32 "$file")
        compressed_size=$(stat -c%s "$file")
        uncompressed_size=$compressed_size

        create_local_file_header "$file" "$crc32" "$compressed_size" "$uncompressed_size"
        cat "$file" >> "$ZIP_FILE"
        file_size=$(stat -c%s "$ZIP_FILE")
        create_central_directory_header "$file" "$crc32" "$compressed_size" "$uncompressed_size" "$offset"
        
        offset=$file_size
        central_directory_size=$(($central_directory_size + 46 + ${#file}))
    fi
done

central_directory_offset=$offset

# 创建中央目录结束记录
create_end_of_central_directory_record "$central_directory_size" "$central_directory_offset"

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "ZIP 文件创建成功: $ZIP_FILE"
