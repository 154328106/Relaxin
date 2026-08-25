//
//  RLXSystemHookActivationTask.m
//  RelaxinEngine
//

#import "RLXSystemHookActivationTask.h"

#import "../../Engine/RLXEngine.h"
#import "../../Diagnostic/RLXEngineDiagnostic.h"
#import "../../Engine/RLXEngineError.h"
#import "../../Log/RLXEngineLog.h"
#import "../../Engine/RLXEngineRunContext.h"

#include <errno.h>
#include <stdlib.h>
#include <unistd.h>

#include <libjailbreak/roothider/common.h>
#include <libjailbreak/util.h>

static const char *const RLXSystemHookActivationLogCategory = "SystemHookActivation";

static NSError *rlx_systemhook_activation_error(NSString *phase, int status) {
    NSString *message = [NSString stringWithFormat:@"failed phase=%@ status=%d", phase, status];
    rlx_engine_log(RLX_ENGINE_LOG_ERROR, RLXSystemHookActivationLogCategory, message.UTF8String);
    RLXEngineDiagnostic *diagnostic = [RLXEngineDiagnostic diagnostic];
    [diagnostic appendPhase:phase];
    [diagnostic appendStatus:status];
    return [RLXEngineError errorWithCode:RLXEngineErrorCodeSystemHookActivationFailed
                             description:@"The SystemHook execution environment could not be " "activated."
                           failureReason:[NSString stringWithFormat:@"%@ failed with status %d.", phase, status]
                      recoverySuggestion:@"Reboot the device before retrying the jailbreak."
                              diagnostic:diagnostic];
}

@interface RLXSystemHookActivationTask ()
- (nullable NSError *)initializeWhitelistConfiguration;
@end

@implementation RLXSystemHookActivationTask

- (instancetype)initWithContext:(RLXEngineRunContext *)context {
    return [super initWithStage:RLXEngineStageSystemHookActivation context:context];
}

- (nullable NSError *)execute {
    const char *systemHookPath = JBROOT_PATH("/basebin/systemhook.dylib");
    rlx_engine_log(RLX_ENGINE_LOG_INFO,
                   RLXSystemHookActivationLogCategory,
                   "activating SystemHook with stock dyld; patched-dyld generation and trust are disabled");

    if (access(systemHookPath, R_OK) != 0) {
        int status = errno ?: ENOENT;
        NSString *message = [NSString
            stringWithFormat:@"SystemHook is unavailable path=%s status=%d", systemHookPath, status];
        rlx_engine_log(RLX_ENGINE_LOG_ERROR, RLXSystemHookActivationLogCategory, message.UTF8String);
        return rlx_systemhook_activation_error(@"locate_systemhook", status);
    }

    NSString *systemHookMessage = [NSString stringWithFormat:@"SystemHook payload ready path=%s", systemHookPath];
    rlx_engine_log(RLX_ENGINE_LOG_INFO, RLXSystemHookActivationLogCategory, systemHookMessage.UTF8String);

    // This flag controls child preparation, not dyld replacement. In the
    // stock-dyld path it suspends children long enough to apply
    // CS_GET_TASK_ALLOW before SystemHook is loaded.
    exec_set_patch(true);
    rlx_engine_log(RLX_ENGINE_LOG_INFO,
                   RLXSystemHookActivationLogCategory,
                   "enabled stock-dyld child preparation via CS_GET_TASK_ALLOW");

    setenv("DYLD_IN_CACHE", "0", 1);
    setenv("DISABLE_TWEAKS", "1", 1);
    setenv("DYLD_INSERT_LIBRARIES", systemHookPath, 1);
    rlx_engine_log(RLX_ENGINE_LOG_INFO,
                   RLXSystemHookActivationLogCategory,
                   "configured stock-dyld SystemHook injection environment; restarting iconservicesagent");

    int status = exec_cmd_trusted(JBROOT_PATH("/usr/bin/killall"), "-9", "iconservicesagent", NULL);
    NSString *restartMessage = [NSString
        stringWithFormat:@"iconservicesagent restart request completed status=%d", status];
    rlx_engine_log(status == 0 ? RLX_ENGINE_LOG_INFO : RLX_ENGINE_LOG_WARNING,
                   RLXSystemHookActivationLogCategory,
                   restartMessage.UTF8String);

    NSError *whitelistError = [self initializeWhitelistConfiguration];
    if (whitelistError) {
        rlx_engine_log(RLX_ENGINE_LOG_WARNING,
                       RLXSystemHookActivationLogCategory,
                       whitelistError.localizedDescription.UTF8String);
    }

    rlx_engine_log(RLX_ENGINE_LOG_INFO,
                   RLXSystemHookActivationLogCategory,
                   "SystemHook activation completed policy=stock-dyld patched_dyld=disabled");
    return nil;
}

- (nullable NSError *)initializeWhitelistConfiguration {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *rootHideDirectory = JBROOT_PATH(@"/var/mobile/Library/RootHide");
    NSError *error = nil;

    if (![fileManager createDirectoryAtPath:rootHideDirectory
                withIntermediateDirectories:YES
                                 attributes:@{
                                     NSFileOwnerAccountID: @501,
                                     NSFileGroupOwnerAccountID: @501,
                                     NSFilePosixPermissions: @0755,
                                 }
                                      error:&error]) {
        return error;
    }
    if (![fileManager setAttributes:@{
            NSFileOwnerAccountID: @501,
            NSFileGroupOwnerAccountID: @501,
            NSFilePosixPermissions: @0755,
        }
                          ofItemAtPath:rootHideDirectory
                                 error:&error]) {
        return error;
    }

    NSDictionary<NSString *, NSNumber *> *systemWhitelist = @{
        @"/.jbroot": @YES,
        @"/xpcproxy": @YES,
        @"/Relaxin": @YES,
        @"/SpringBoard": @YES,
        @"/Preferences": @YES,
        @"/amfid": @YES,
        @"/cfprefsd": @YES,
        @"/lsd": @YES,
        @"/transitd": @YES,
        @"/watchdogd": @YES,
        @"/SafariViewService": @YES,
        @"/iconservicesagent": @YES,
        @"/mobileassetd": @YES,
        @"/MobileGestaltHelper": @YES,
        @"/useractivityd": @YES,
    };
    NSDictionary<NSString *, NSNumber *> *wantsBlacklist = @{
        @"QQ": @YES,
        @"WeChat": @YES,
        @"Runner": @YES,
        @"AppStore": @YES,
    };

    NSArray<NSDictionary<NSString *, id> *> *files = @[
        @{
            @"path": [rootHideDirectory stringByAppendingPathComponent:@"cn.zqbb.inject.system.plist"],
            @"contents": systemWhitelist,
        },
        @{
            @"path": [rootHideDirectory
                stringByAppendingPathComponent:@"cn.zqbb.inject.wantsblacklist.plist"],
            @"contents": wantsBlacklist,
        },
    ];

    for (NSDictionary<NSString *, id> *entry in files) {
        NSString *path = entry[@"path"];
        NSDictionary *contents = entry[@"contents"];
        if (![fileManager fileExistsAtPath:path] && ![contents writeToFile:path atomically:YES]) {
            return [NSError errorWithDomain:NSCocoaErrorDomain
                                       code:NSFileWriteUnknownError
                                   userInfo:@{
                                       NSFilePathErrorKey: path,
                                       NSLocalizedDescriptionKey:
                                           [NSString stringWithFormat:@"Unable to initialize %@.",
                                                                      path.lastPathComponent],
                                   }];
        }

        if (![fileManager setAttributes:@{
                NSFileOwnerAccountID: @501,
                NSFileGroupOwnerAccountID: @501,
                NSFilePosixPermissions: @0644,
            }
                              ofItemAtPath:path
                                     error:&error]) {
            return error;
        }
    }

    rlx_engine_log(RLX_ENGINE_LOG_INFO,
                   RLXSystemHookActivationLogCategory,
                   "RootHide whitelist configuration is ready");
    return nil;
}

@end
