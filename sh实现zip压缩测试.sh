#!/bin/bash

# 计算CRC32
crc32() {
  local file=$1
  local crc=0xffffffff
  local buf
  local data

  while IFS= read -r -n 1 char; do
    data=$(printf "%d" "'$char")
    crc=$(( (crc >> 8) ^ crc_table[((crc ^ data) & 0xff)] ))
  done < "$file"

  printf "%08x" $((crc ^ 0xffffffff & 0xffffffff))
}

# 生成CRC32表
generate_crc_table() {
  local poly=0xedb88320
  for ((i=0; i<256; i++)); do
    local crc=$i
    for ((j=8; j; j--)); do
      if ((crc & 1)); then
        crc=$(( (crc >> 1) ^ poly ))
      else
        crc=$(( crc >> 1 ))
      fi
    done
    crc_table[i]=$crc
  done
}

# 简单的文件压缩函数（RLE 压缩）
compress_file() {
  local file=$1
  local compressed_file=$2

  # 使用简单的RLE算法进行压缩
  awk '{
    for (i=1; i<=length; i++) {
      c = substr($0, i, 1)
      if (c == prev) {
        count++
      } else {
        if (count > 1) {
          printf "%d%s", count, prev >> compressed_file
        } else if (count == 1) {
          printf "%s", prev >> compressed_file
        }
        prev = c
        count = 1
      }
    }
  }
  END {
    if (count > 1) {
      printf "%d%s", count, prev >> compressed_file
    } else if (count == 1) {
      printf "%s", prev >> compressed_file
    }
  }' "$file" > "$compressed_file"
}

# 初始化CRC32表
declare -A crc_table
generate_crc_table

# 检查参数
if [ "$#" -lt 2 ]; then
  echo "用法: $0 <输出的zip文件名> <要压缩的文件或目录>"
  exit 1
fi

# 获取输出ZIP文件名
output_zip_file=$1
shift

# 获取需要压缩的文件或目录
files_to_compress="$@"

# 创建临时目录
temp_dir=$(mktemp -d)
if [ ! -d "$temp_dir" ]; then
  echo "无法创建临时目录"
  exit 1
fi

# 处理每个文件
for file in $files_to_compress; do
  temp_compressed_file="$temp_dir/$(basename "$file").rle"
  compress_file "$file" "$temp_compressed_file"

  # 获取文件信息
  compressed_size=$(stat -c%s "$temp_compressed_file")
  uncompressed_size=$(stat -c%s "$file")
  compressed_name=$(basename "$file")
  crc32_value=$(crc32 "$file")

  # 生成ZIP文件头部
  {
    # 本地文件头
    echo -ne '\x50\x4b\x03\x04'    # 本地文件头签名
    echo -ne '\x14\x00'            # 提取所需的版本（20）
    echo -ne '\x00\x00'            # 通用目的位标志
    echo -ne '\x08\x00'            # 压缩方法（RLE压缩，非标准）
    echo -ne '\x00\x00\x00\x00'    # 最后修改时间和日期
    echo -ne "$(printf '%08x' "0x$crc32_value")"  # CRC-32
    echo -ne "$(printf '%08x' "$compressed_size")"  # 压缩大小
    echo -ne "$(printf '%08x' "$uncompressed_size")"  # 解压后的大小
    echo -ne "$(printf '%04x' "${#compressed_name}")" # 文件名长度
    echo -ne '\x00\x00'            # 附加字段长度
    echo -ne "$compressed_name"    # 文件名

    # 文件数据
    cat "$temp_compressed_file"

    # 中央目录记录
    echo -ne '\x50\x4b\x01\x02'    # 中央目录文件头签名
    echo -ne '\x14\x00'            # 创建版本
    echo -ne '\x14\x00'            # 提取所需版本（20）
    echo -ne '\x00\x00'            # 通用目的位标志
    echo -ne '\x08\x00'            # 压缩方法（RLE压缩，非标准）
    echo -ne '\x00\x00\x00\x00'    # 最后修改时间和日期
    echo -ne "$(printf '%08x' "0x$crc32_value")"  # CRC-32
    echo -ne "$(printf '%08x' "$compressed_size")"  # 压缩大小
    echo -ne "$(printf '%08x' "$uncompressed_size")"  # 解压后的大小
    echo -ne "$(printf '%04x' "${#compressed_name}")" # 文件名长度
    echo -ne '\x00\x00'            # 附加字段长度
    echo -ne '\x00\x00'            # 文件注释长度
    echo -ne '\x00\x00'            # 磁盘号起始
    echo -ne '\x00\x00'            # 内部文件属性
    echo -ne '\x00\x00\x00\x00'    # 外部文件属性
    echo -ne '\x00\x00\x00\x00'    # 本地头相对偏移
    echo -ne "$compressed_name"    # 文件名

    # ZIP文件结尾记录
    end_of_central_dir_offset=$(stat -c%s "$output_zip_file")
    echo -ne '\x50\x4b\x05\x06'    # 中央目录记录结尾签名
    echo -ne '\x00\x00'            # 本磁盘号
    echo -ne '\x00\x00'            # 中央目录开始磁盘号
    echo -ne '\x01\x00'            # 本磁盘上的中央目录记录数
    echo -ne '\x01\x00'            # 总中央目录记录数
    echo -ne "$(printf '%08x' "$end_of_central_dir_offset")"  # 中央目录大小
    echo -ne "$(printf '%08x' "$end_of_central_dir_offset")"  # 中央目录起始偏移
    echo -ne '\x00\x00'            # .ZIP文件注释长度
  } >> "$output_zip_file"
done

# 清理临时文件
rm -rf "$temp_dir"

# 输出成功消息
echo "压缩成功: $output_zip_file"
