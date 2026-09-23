//
//  RLXReinstallSileoAction.m
//  RelaxinEngine
//

#import "RLXActions.h"

#import "RLXActionRunner.h"
#import "../../RelaxinPostJailbreak/Actions/RLXPostJailbreakActionRunner.h"
#import "../Bootstrap/RLXBootstrapFinalizer.h"

#include <TargetConditionals.h>
#include <errno.h>

#if !TARGET_OS_SIMULATOR

static NSError *_Nullable rlx_reinstall_package_manager(RLXEngineAction action,
                                                        NSString *packageName,
                                                        NSBundle *resourceBundle,
                                                        NSString *_Nullable __strong *_Nullable failurePhase) {
    NSString *phase = [@"install_" stringByAppendingString:packageName];
    __block NSError *installationError = nil;
    int status = RLXPostJailbreakRunAsEffectiveRoot(
        ^int {
            return RLXPostJailbreakRunUnsandboxed(
                ^int {
                    installationError = [RLXBootstrapFinalizer installBundledPackageNamed:packageName
                                                                           resourceBundle:resourceBundle];
                    if (installationError) {
                        RLXPostJailbreakSetFailurePhase(failurePhase, phase);
                        return EIO;
                    }
                    return 0;
                },
                failurePhase);
        },
        failurePhase);
    if (status == 0) {
        return nil;
    }
    return RLXActionExecutionError(action,
                                   failurePhase && *failurePhase ? *failurePhase : phase,
                                   status,
                                   installationError);
}

NSError *_Nullable RLXReinstallSileo(NSBundle *resourceBundle, NSString *_Nullable __strong *_Nullable failurePhase) {
    return rlx_reinstall_package_manager(RLXEngineActionReinstallSileo, @"sileo", resourceBundle, failurePhase);
}

NSError *_Nullable RLXReinstallIrisin(NSBundle *resourceBundle, NSString *_Nullable __strong *_Nullable failurePhase) {
    return rlx_reinstall_package_manager(RLXEngineActionReinstallIrisin, @"irisin", resourceBundle, failurePhase);
}

#endif /* !TARGET_OS_SIMULATOR */
