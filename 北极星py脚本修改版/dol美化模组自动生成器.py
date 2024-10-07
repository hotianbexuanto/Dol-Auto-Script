os.remove('boot.json')
print(f'模组生成完成: {zip_name}')import os
import json
import zipfile

def zip_files_and_folders(file_paths, zip_name):
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in file_paths:
            if os.path.isdir(file_path):
                for root, dirs, files in os.walk(file_path):
                    for file in files:
                        zipf.write(os.path.join(root, file), os.path.relpath(os.path.join(root, file), os.path.dirname(file_path)))
            else:
                zipf.write(file_path, os.path.basename(file_path))

def list_files_and_subdirectories(directory, output_dict):
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.relpath(os.path.join(root, file), directory)
            relative_path = 'img/' + file_path.replace("\\", "/")

            if file.endswith('.png') or file.endswith('.gif'):
                output_dict["imgFileList"].append(relative_path)
            elif file.endswith('.css'):
                output_dict["styleFileList"].append(relative_path)
            elif file.endswith('.js'):
                output_dict["scriptFileList"].append(relative_path)
            elif file.endswith('.twee'):
                output_dict["tweeFileList"].append(relative_path)
            else:
                output_dict["additionFile"].append(relative_path)

os.makedirs('img', exist_ok=True)
output_dict = {}
output_dict['name'] = input('请输入模组名称:')
output_dict['version'] = input('请输入类似于1.0.0的模组版本号:')
game_version_input = input('是否添加游戏版本号（输入y添加，直接回车不添加）:')
game_version = ""

if game_version_input.lower() == 'y':
    game_version = input('请输入游戏版本号（默认^0.5.1.3，直接回车使用默认）:')
    if not game_version:  # 如果直接回车，则使用默认版本
        game_version = "^0.5.1.3"

is_ready_to_print = True

if not is_ready_to_print:
    print("未准备完成，请稍等")
else:
    print(f'模组生成中请稍等...')

output_dict['scriptFileList_inject_early'] = []
output_dict['scriptFileList_earlyload'] = []
output_dict['scriptFileList_preload'] = []
output_dict['styleFileList'] = []
output_dict['scriptFileList'] = []
output_dict['tweeFileList'] = []
output_dict['additionFile'] = []
output_dict['imgFileList'] = []
output_dict['additionBinaryFile'] = []
output_dict['additionDir'] = []

# 列出 img 文件夹下的文件并分类
list_files_and_subdirectories('img', output_dict)

output_dict['addonPlugin'] = []

output_dict['dependenceInfo'] = [
    {
      "modName": "ModLoader DoL ImageLoaderHook",
      "version": "^2.3.0"
    },
    {
      "modName": "ModLoader",
      "version": "^2.3.0"
    }
]

# 只有确认输入了游戏版本时才添加 GameVersion 字段
if game_version:
    output_dict['dependenceInfo'].append({
      "modName": "GameVersion",
      "version": game_version
    })

# 将内容输出到文本文件
with open('boot.json', 'w', encoding='utf-8') as file:
    json.dump(output_dict, file, indent=2, ensure_ascii=False)

# 要压缩的文件和文件夹路径列表
file_paths = ['img', 'boot.json']
# 压缩后的文件名
zip_name = output_dict['name'] + '.zip'

zip_files_and_folders(file_paths, zip_name)
os.remove('boot.json')
print(f'模组生成完成: {zip_name}')