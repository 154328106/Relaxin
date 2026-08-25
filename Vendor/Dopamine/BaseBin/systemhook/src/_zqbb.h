#pragma once

#include <stdbool.h>

// Implemented in libjailbreak/src/roothider/_whitelist.c, which systemhook
// compiles in directly and launchdhook picks up from libjailbreak.
bool zqbb_wantsInject(const char *execName, const char *injectPath);
bool zqbb_isWhiteListForSystem(const char *path, const char *injectSystemPath);
