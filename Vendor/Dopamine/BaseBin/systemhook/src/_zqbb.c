#include "_zqbb.h"

#include <libjailbreak/util.h>
#include <xpc/xpc.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

extern xpc_object_t xpc_create_from_plist(const void *buf, size_t len);

static bool plistContainsExecutable(const char *execName, const char *plistPath) {
    if (!execName || !plistPath)
        return false;

    struct stat s = {};
    int fd = open(plistPath, O_RDONLY);
    if (fd < 0)
        return false;
    if (fstat(fd, &s) != 0 || s.st_size <= 0) {
        close(fd);
        return false;
    }

    void *addr = mmap(NULL, s.st_size, PROT_READ, MAP_FILE | MAP_PRIVATE, fd, 0);
    close(fd);
    if (addr == MAP_FAILED)
        return false;

    xpc_object_t xplist = xpc_create_from_plist(addr, s.st_size);
    munmap(addr, s.st_size);
    if (!xplist || xpc_get_type(xplist) != XPC_TYPE_DICTIONARY) {
        if (xplist)
            xpc_release(xplist);
        return false;
    }

    bool result = xpc_dictionary_get_bool(xplist, execName);
    xpc_release(xplist);
    return result;
}

bool zqbb_wantInject(const char *execName, const char *injectPath) {
    return plistContainsExecutable(execName, injectPath);
}

bool zqbb_isWhiteList(const char *path) {
    if (!path)
        return false;

    const char *systemInjectPath =
        JBROOT_PATH("/var/mobile/Library/RootHide/cn.zqbb.inject.system.plist");

    struct stat s = {};
    int fd = open(systemInjectPath, O_RDONLY);
    if (fd < 0)
        return false;
    if (fstat(fd, &s) != 0 || s.st_size <= 0) {
        close(fd);
        return false;
    }

    void *addr = mmap(NULL, s.st_size, PROT_READ, MAP_FILE | MAP_PRIVATE, fd, 0);
    close(fd);
    if (addr == MAP_FAILED)
        return false;

    xpc_object_t xplist = xpc_create_from_plist(addr, s.st_size);
    munmap(addr, s.st_size);
    if (!xplist || xpc_get_type(xplist) != XPC_TYPE_DICTIONARY) {
        if (xplist)
            xpc_release(xplist);
        return false;
    }

    __block bool found = false;
    xpc_dictionary_apply(xplist, ^bool(const char *key, xpc_object_t value) {
        if (xpc_get_type(value) == XPC_TYPE_BOOL && xpc_bool_get_value(value) && strstr(path, key)) {
            found = true;
            return false;
        }
        return true;
    });
    xpc_release(xplist);
    return found;
}
