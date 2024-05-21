#include <stdlib.h>
#include <sys/stat.h>

#include <riscv/config.h>

// Stubs for C stdlib syscalls
// Most of this functions do nothing

void exit(int status) {
    EXIT_STATUS_REG = status;
    while(1) {}
}

void _exit() {
    exit(-1);
}

unsigned _sbrk(int inc) {
    (void) inc;
    return 0;
}

int _kill(int pid, int sig) {
    (void) pid;
    (void) sig;
    return -1;
}

int _getpid(void) {
    return 1;
}

int _read(int file, char *ptr, int len) {
    (void) file;
    (void) ptr;
    (void) len;
    return 0;
}

int _close(int file) {
    (void) file;
    return -1;
}

int _fstat(int file, struct stat *st) {
    (void) file;
    (void) st;
    return -1;
}

int _isatty(int file) {
    (void) file;
    return 1;
}

int _open(const char* name, int flags, int mode) {
    (void) name;
    (void) flags;
    (void) mode;
    return -1;
}

int _lseek(int file, int ptr, int dir) {
    (void) file;
    (void) ptr;
    (void) dir;
    return 0;
}

int _write(int fd, const void* buf, size_t count) {

    size_t bytes_written = 0;

    // stdout and stderr
    if (fd == 1 || fd == 2) {
        char* char_buf = (char*) buf;
        for(int i = 0; i < count; i++) {
            PRINT_REG = char_buf[i];
            bytes_written++;
        }
    } 

    return bytes_written;
}
