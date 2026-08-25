#include <xpc/xpc.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

typedef struct {
    time_t mtime;
    off_t size;
    xpc_object_t cachedPlist;
} WhitelistCacheEntry;

static WhitelistCacheEntry whitelistCache = { 0, 0, NULL };

extern xpc_object_t xpc_create_from_plist(const void *buf, size_t len);

bool zqbb_isWhiteListForSystem(const char *path, const char *injectSystemPath) {
    if (!path || !injectSystemPath)
        return false;

    struct stat s = {};
    if (stat(injectSystemPath, &s) != 0 || s.st_size <= 0)
        return false;

    if (!whitelistCache.cachedPlist || whitelistCache.mtime != s.st_mtime ||
        whitelistCache.size != s.st_size) {
        int fd = open(injectSystemPath, O_RDONLY);
        if (fd < 0)
            return false;

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

        if (whitelistCache.cachedPlist)
            xpc_release(whitelistCache.cachedPlist);
        whitelistCache.cachedPlist = xplist;
        whitelistCache.mtime = s.st_mtime;
        whitelistCache.size = s.st_size;
    }

    __block bool found = false;
    xpc_dictionary_apply(whitelistCache.cachedPlist, ^bool(const char *key, xpc_object_t value) {
        if (xpc_get_type(value) == XPC_TYPE_BOOL && xpc_bool_get_value(value) && strstr(path, key)) {
            found = true;
            return false;
        }
        return true;
    });
    return found;
}
