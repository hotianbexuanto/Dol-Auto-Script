#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"

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

rm "$TEMP_FILE"

echo "目录结构已保存到 $OUTPUT_FILE"
