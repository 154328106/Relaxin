#import "RLXPostJailbreakActions.h"

#import "RLXPostJailbreakActionRunner.h"

#include <errno.h>
#include <unistd.h>

// iOS SDK strips <sys/reboot.h> — forward-declare the libSystem-exported
// syscall wrapper and the RB_AUTOBOOT flag directly.
#ifndef RB_AUTOBOOT
#define RB_AUTOBOOT 0
#endif
extern int reboot(int howto);

#if !TARGET_OS_SIMULATOR

int RLXPostJailbreakRebootDevice(NSString *_Nullable __strong *_Nullable failurePhase) {
    return RLXPostJailbreakRunAsEffectiveRoot(
        ^int {
            return RLXPostJailbreakRunUnsandboxed(
                ^int {
                    sync();
                    errno = 0;
                    int rc = reboot(RB_AUTOBOOT);
                    if (rc != 0) {
                        RLXPostJailbreakSetFailurePhase(failurePhase, @"reboot_syscall");
                        return errno ?: EIO;
                    }
                    return 0;
                },
                failurePhase);
        },
        failurePhase);
}

#endif /* !TARGET_OS_SIMULATOR */
