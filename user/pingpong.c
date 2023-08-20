#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    int pid;
    // two-way delivery needs two pipes 
    int pipe1[2], pipe2[2];
    char buf[] = {'a'};
    // pipe
    pipe(pipe1);
    pipe(pipe2);
    // create child proccess
    int ret = fork();

    // parent sends in pipe1[1], child receives in pipe1[0]
    // child sends in pipe2[1], parent receives in pipe2[0]
    
    if (ret == 0) {
        // it is child process
        // receives in pipe1[0]
        // sends in pipe2[1]
        pid = getpid();
        close(pipe1[1]);
        close(pipe2[0]);
        read(pipe1[0], buf, 1);
        printf("%d: received ping\n", pid);
        write(pipe2[1], buf, 1);
        exit(0);
    }
    else {
        // it is parent process
        // sends in pipe1[1]
        // receives in pipe2[0]
        pid = getpid();
        close(pipe1[0]);
        close(pipe2[1]);
        write(pipe1[1], buf, 1);
        read(pipe2[0], buf, 1);
        printf("%d: received pong\n", pid);
        exit(0);
    }
}