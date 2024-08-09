// 结构体定义头文件

#ifndef STRUCTS_H
#define STRUCTS_H

#include <sys/types.h>
#include <dirent.h>
#include <sys/time.h>

// 确保 struct dirent 已定义

#endif // STRUCTS_H


struct direct {
    ino_t d_ino;       // inode number
    off_t d_off;       // offset to the next dirent
    unsigned short d_reclen; // length of this record
    unsigned char d_type;     // type of file
    char d_name[256]; // filename
};
