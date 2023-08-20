#include "kernel/param.h"
#include "kernel/types.h"
#include "user/user.h"

#define buf_size 512

int main(int argc, char *argv[]) {
    char buf[buf_size + 1] = {0};
    uint occupy = 0;
    char *xargv[MAXARG] = {0};
    int stdin_end = 0;

    for (int i = 1; i < argc; i++) {
        xargv[i - 1] = argv[i];
    }

    while (!(stdin_end && occupy == 0)) {
        // 将标准输入的所有参数读入buf中
        if (!stdin_end) {
            int remain_size = buf_size - occupy;
            int read_bytes = read(0, buf + occupy, remain_size);
            if (read_bytes < 0) {
                fprintf(2, "xargs: read returns -1 error\n");
            }
            if (read_bytes == 0) {
                close(0);
                stdin_end = 1;
            }
            occupy += read_bytes;
        }
        // 找到第一个'\n'的下标
        char *line_end = strchr(buf, '\n');
        while (line_end) {
            char xbuf[buf_size + 1] = {0};
            // 将第一个参数（buf第一个'\n'前的内容）复制到xbuf中
            memcpy(xbuf, buf, line_end - buf);
            xargv[argc - 1] = xbuf;
            // 创建子进程
            int ret = fork();
            if (ret == 0) {
                // 子进程执行第一行命令
                if (!stdin_end) {
                    close(0);
                }
                if (exec(argv[1], xargv) < 0) {
                    fprintf(2, "xargs: exec fails with -1\n");
                    exit(1);
                }
            }
            else {
                // 父进程移除以及执行过的参数（第一个'\n'及其前的内容）
                memmove(buf, line_end + 1, occupy - (line_end - buf) - 1);
                occupy -= line_end - buf + 1;
                memset(buf + occupy, 0, buf_size - occupy);
                // 等等子进程结束
                int pid;
                wait(&pid);

                line_end = strchr(buf, '\n');
            }
        }
    }
    exit(0);
}