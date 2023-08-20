#include "kernel/types.h"
#include "user/user.h"

void prime(int *fd)
{
    // 关闭输入fd
    close(fd[1]);
    int n;
    // 一个整型变量的size
    int int_bytes = sizeof(int);
    // 创建新管道
    int next_pipefd[2];
    pipe(next_pipefd);
    // 从fd读取一个整形数据n
    if (read(fd[0], &n, int_bytes) == int_bytes)
    {
        // 从管道读到的第一个数n一定是素数
        printf("prime %d\n", n);
        // 创建子进程
        int child_pid = fork();
        // 子进程进入递归
        if (child_pid == 0)
        {
            prime(next_pipefd);
            exit(0);
        }
        // 父进程循环从fd左侧读取
        else
        {
            // 关闭新管道输出端
            close(next_pipefd[0]);
            int temp;
            // 从fd左侧逐一读取数字，如果不是n的倍数，就把他从新管道右侧输入
            while (read(fd[0], &temp, int_bytes) == int_bytes)
            {
                if ((temp % n) != 0)
                {
                    write(next_pipefd[1], &temp, int_bytes);
                }
            }
            // 关闭新管道输入端
            close(next_pipefd[1]);
            wait(0);
        }
    }
}

int main(int argc, char *argv[])
{
    // 创建管道fd
    int pipefd[2];
   pipe(pipefd);
    
    // 创建子进程
    int c_pid = fork();
    if (c_pid == 0)
    {
        prime(pipefd);
        exit(0);
    }
    close(pipefd[0]);

    // 依次写入2-35至管道fd
    int limit = 35;
    for (int i = 2; i <= limit; i++)
    {
        write(pipefd[1], &i, 4);
    }
    close(pipefd[1]);
    wait(0);

    exit(0);
}