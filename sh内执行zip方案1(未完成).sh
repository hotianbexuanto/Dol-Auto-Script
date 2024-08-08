#!/bin/bash

SOURCE_DIR="img"
OUTPUT_FILE="boot.json"
ZIP_FILE="output.zip"

# 创建临时文件来保存目录结构
TEMP_FILE=$(mktemp)

# 递归遍历指定目录的结构并将结果保存到临时文件中
find "$SOURCE_DIR" -type d -exec echo '{}' \; > "$TEMP_FILE"
find "$SOURCE_DIR" -type f -exec echo '{}' \; >> "$TEMP_FILE"

# 读取用户输入
read -p "请输入名称: " NAME
read -p "请输入模组版本 (参考 0.0.1): " VERSION
read -p "请输入支持的 ModLoader 版本 (参考 =1.2.3, <2.0.0, >1.0.0, ^1.2.3): " DEP_VERSION
read -p "请输入游戏版本 (可选, 参考 0.0.0.1, 如果不输入则不在 JSON 中添加此字段): " GAME_VERSION

# 准备 JSON 输出
{
    echo "{"
    echo "  \"name\": \"$NAME\","
    echo "  \"version\": \"$VERSION\","
    echo "  \"scriptFileList_inject_early\": [],"
    echo "  \"scriptFileList_earlyload\": [],"
    echo "  \"scriptFileList_preload\": [],"
    echo "  \"styleFileList\": [],"
    echo "  \"scriptFileList\": [],"
    echo "  \"tweeFileList\": [],"
    echo "  \"imgFileList\": ["
    
    # 读取临时文件并将图像文件路径转换为 JSON 格式
    first=true
    while IFS= read -r line; do
        if [[ "$line" == *.png || "$line" == *.jpg || "$line" == *.gif ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    \"$line\""
        fi
    done < "$TEMP_FILE"
    
    echo ""
    echo "  ],"
    echo "  \"additionFile\": ["
    
    # 读取临时文件并将所有文件和目录路径写入 JSON 文件
    first=true
    while IFS= read -r line; do
        if [[ -f "$line" && "$line" != *.png && "$line" != *.jpg && "$line" != *.gif ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    \"$line\""
        fi
    done < "$TEMP_FILE"
    
    echo ""
    echo "  ],"
    echo "  \"additionBinaryFile\": [],"
    echo "  \"additionDir\": ["
    
    # 读取临时文件并将目录路径写入 JSON 文件
    first=true
    while IFS= read -r line; do
        if [[ -d "$line" ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    \"$line\""
        fi
    done < "$TEMP_FILE"
    
    echo ""
    echo "  ],"
    echo "  \"addonPlugin\": [],"
    echo "  \"dependenceInfo\": ["
    echo "    {"
    echo "      \"modName\": \"ModLoader\","
    echo "      \"version\": \"$DEP_VERSION\""
    echo "    }"
    
    # 添加 GameVersion 条件
    if [[ -n "$GAME_VERSION" ]]; then
        echo ","
        echo "    {"
        echo "      \"modName\": \"GameVersion\","
        echo "      \"version\": \"$GAME_VERSION\""
        echo "    }"
    fi
    
    echo "  ]"
    echo "}"
} > "$OUTPUT_FILE"

# 删除临时文件
rm "$TEMP_FILE"

# 下面是嵌入的静态 zip 工具的 Base64 编码
# 你需要先获取 zip 工具的可执行文件，然后执行 base64 编码得到以下字符串
# 这里是个示例字符串，你需要替换为真实的 zip 工具的 base64 编码
static_zip_base64="base64_encoded_zip_tool_here"

# 解码并保存为文件
echo "$static_zip_base64" | base64 -d > ./zip_tool

# 给解压缩工具添加可执行权限
chmod +x ./zip_tool

# 使用嵌入的 zip 工具压缩文件
./zip_tool -r "$ZIP_FILE" "$OUTPUT_FILE" "$SOURCE_DIR"

# 删除释放出来的工具
rm -f ./zip_tool
