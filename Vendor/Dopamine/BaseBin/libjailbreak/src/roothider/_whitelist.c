#include <fcntl.h>
#include <os/lock.h>
#include <stdbool.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <xpc/xpc.h>

extern xpc_object_t xpc_create_from_plist(const void *buf, size_t len);

typedef struct {
    os_unfair_lock lock;
    off_t size;
    struct timespec mtime;
    xpc_object_t plist;
} PlistCache;

static PlistCache gInjectCache = { OS_UNFAIR_LOCK_INIT, 0, { 0, 0 }, NULL };
static PlistCache gSystemCache = { OS_UNFAIR_LOCK_INIT, 0, { 0, 0 }, NULL };

// Returns a +1 reference the caller has to release, or NULL. The parse result is
// cached until the file changes; nanosecond timestamps are used so that edits
// made within the same second are still picked up.
static xpc_object_t copyPlist(PlistCache *cache, const char *path) {
    struct stat s = {};
    if (stat(path, &s) != 0 || s.st_size <= 0)
        return NULL;

    os_unfair_lock_lock(&cache->lock);
    if (cache->plist && cache->size == s.st_size &&
        cache->mtime.tv_sec == s.st_mtimespec.tv_sec &&
        cache->mtime.tv_nsec == s.st_mtimespec.tv_nsec) {
        xpc_object_t cached = xpc_retain(cache->plist);
        os_unfair_lock_unlock(&cache->lock);
        return cached;
    }
    os_unfair_lock_unlock(&cache->lock);

    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return NULL;
    void *addr = mmap(NULL, s.st_size, PROT_READ, MAP_FILE | MAP_PRIVATE, fd, 0);
    close(fd);
    if (addr == MAP_FAILED)
        return NULL;

    xpc_object_t plist = xpc_create_from_plist(addr, s.st_size);
    munmap(addr, s.st_size);
    if (!plist)
        return NULL;
    if (xpc_get_type(plist) != XPC_TYPE_DICTIONARY) {
        xpc_release(plist);
        return NULL;
    }

    os_unfair_lock_lock(&cache->lock);
    if (cache->plist)
        xpc_release(cache->plist);
    cache->plist = xpc_retain(plist);
    cache->size = s.st_size;
    cache->mtime = (struct timespec){ s.st_mtimespec.tv_sec, s.st_mtimespec.tv_nsec };
    os_unfair_lock_unlock(&cache->lock);

    return plist;
}

// A key such as "/SpringBoard" matches a whole path component, so that "/lsd"
// no longer selects every executable whose path merely contains that text. Keys
// naming a hidden directory ("/.jbroot") also match components that only start
// with them, because the bootstrap randomises them into ".jbroot-<hex>".
static bool pathHasComponent(const char *path, const char *key) {
    if (!path || !key || key[0] != '/' || key[1] == '\0')
        return false;

    const char *name = key + 1;
    size_t nameLength = strlen(name);
    bool allowSuffix = (name[0] == '.');

    for (const char *cursor = path; (cursor = strchr(cursor, '/')) != NULL;) {
        const char *component = ++cursor;
        const char *end = strchr(component, '/');
        size_t length = end ? (size_t)(end - component) : strlen(component);
        if (length >= nameLength && strncmp(component, name, nameLength) == 0 &&
            (length == nameLength || allowSuffix))
            return true;
    }
    return false;
}

bool zqbb_wantsInject(const char *execName, const char *injectPath) {
    if (!execName || !injectPath)
        return false;

    xpc_object_t plist = copyPlist(&gInjectCache, injectPath);
    if (!plist)
        return false;

    bool wanted = xpc_dictionary_get_bool(plist, execName);
    xpc_release(plist);
    return wanted;
}

bool zqbb_isWhiteListForSystem(const char *path, const char *injectSystemPath) {
    if (!path || !injectSystemPath)
        return false;

    xpc_object_t plist = copyPlist(&gSystemCache, injectSystemPath);
    if (!plist)
        return false;

    __block bool found = false;
    xpc_dictionary_apply(plist, ^bool(const char *key, xpc_object_t value) {
        if (xpc_get_type(value) == XPC_TYPE_BOOL && xpc_bool_get_value(value) &&
            pathHasComponent(path, key)) {
            found = true;
            return false;
        }
        return true;
    });
    xpc_release(plist);
    return found;
}
