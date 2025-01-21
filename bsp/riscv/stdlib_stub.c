#include <stdlib.h>
#include <sys/stat.h>
#include <stdio.h>

#include <errno.h>
#undef errno
extern int errno;

#include <rvtarget.h>

#define ALIGNMENT 4
#define ALIGN(x) (((x) + (ALIGNMENT - 1)) & ~(ALIGNMENT - 1))

// Stubs for C stdlib syscalls
// Most of this functions do nothing

void _exit(int status) {
    EXIT_STATUS_REG = status;
    while(1) {}
}

// Overwrites sbrk from libc
void* _sbrk(int inc) {
    extern char _heap_start; // Defined by the linker
    extern char _heap_end; //Defined by the linker
    static char *heap_top = 0;
    char *prev_heap_top;

    if (heap_top == 0) {
        heap_top = &_heap_start;
    }

    prev_heap_top = heap_top;
    
    if ((heap_top + inc) > &_heap_end) {
        errno = ENOMEM;
        return (void*)-1;
    }
    
    heap_top += ALIGN(inc);
    return (void*)prev_heap_top;
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
        for(size_t i = 0; i < count; i++) {
            PRINT_REG = char_buf[i];
            bytes_written++;
        }
    } 

    return bytes_written;
}
