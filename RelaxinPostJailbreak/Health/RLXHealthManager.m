#import "RLXHealthManager.h"

#import "../Actions/RLXPostJailbreakActionRunner.h"

#include <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_SIMULATOR
#import <CoreServices/LSApplicationProxy.h>
#include <libjailbreak/info.h>
#include <libjailbreak/jbroot.h>
#include <libjailbreak/util.h>
#endif

NSString *const RLXHealthIdentifierBootstrap = @"bootstrap";
NSString *const RLXHealthIdentifierJailbreakApps = @"jailbreak-apps";
NSString *const RLXHealthIdentifierSileo = @"org.coolstar.SileoStore";
NSString *const RLXHealthIdentifierInjection = @"injection";

static NSString *const RLXHealthErrorDomain = @"RLXHealthErrorDomain";

// Relaxin always ships Sileo with the bootstrap, so unlike Dopamine there is no
// user-selected package-manager list to consult — the one entry is fixed.
static NSString *const RLXHealthSileoDebianPackage = @"org.coolstar.sileo";
static NSString *const RLXHealthSileoApplication = @"Sileo.app";
static NSString *const RLXHealthSileoPackageResource = @"sileo";

@interface RLXHealthItem ()
@property(nonatomic, copy, readwrite) NSString *identifier;
@property(nonatomic, copy, readwrite) NSString *title;
@property(nonatomic, copy, readwrite) NSString *detail;
@property(nonatomic, readwrite) RLXHealthState state;
@property(nonatomic, readwrite) BOOL canRepair;
@end

@implementation RLXHealthItem
@end

@implementation RLXHealthManager

- (instancetype)initWithResourceBundle:(NSBundle *)resourceBundle {
    self = [super init];
    if (self) {
        _resourceBundle = resourceBundle;
    }
    return self;
}

- (NSFileManager *)fileManager {
    return NSFileManager.defaultManager;
}

- (RLXHealthItem *)itemWithIdentifier:(NSString *)identifier
                                title:(NSString *)title
                               detail:(NSString *)detail
                                state:(RLXHealthState)state
                            canRepair:(BOOL)canRepair {
    RLXHealthItem *item = [RLXHealthItem new];
    item.identifier = identifier;
    item.title = title;
    item.detail = detail;
    item.state = state;
    item.canRepair = canRepair;
    return item;
}

- (NSError *)errorWithDescription:(NSString *)description {
    return [NSError errorWithDomain:RLXHealthErrorDomain
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey : description}];
}

- (NSArray<RLXHealthItem *> *)unknownHealthItems {
    NSArray<NSArray<NSString *> *> *definitions = @[
        @[ RLXHealthIdentifierBootstrap, @"越狱环境" ],
        @[ RLXHealthIdentifierJailbreakApps, @"应用注册" ],
        @[ RLXHealthIdentifierSileo, @"Sileo商店" ],
        @[ RLXHealthIdentifierInjection, @"插件注入" ],
    ];
    NSMutableArray<RLXHealthItem *> *items = [NSMutableArray new];
    for (NSArray<NSString *> *definition in definitions) {
        [items addObject:[self itemWithIdentifier:definition[0]
                                            title:definition[1]
                                           detail:@"无法读取越狱环境，请确认设备已越狱"
                                            state:RLXHealthStateUnknown
                                        canRepair:NO]];
    }
    return items;
}

#if TARGET_OS_IOS && !TARGET_OS_SIMULATOR

#pragma mark - Path helpers

- (NSString *)canonicalPath:(NSString *)path {
    if (path.length == 0) return @"";
    return [[path stringByResolvingSymlinksInPath] stringByStandardizingPath];
}

- (BOOL)path:(NSString *)left equalsPath:(NSString *)right {
    if (left.length == 0 || right.length == 0) return NO;
    return [[self canonicalPath:left] isEqualToString:[self canonicalPath:right]];
}

- (BOOL)isRootHideManagedApplicationPath:(NSString *)path {
    if (path.length == 0) return NO;
    NSString *standardPath = [path stringByStandardizingPath];
    NSString *pattern =
        @"^(?:/private)?/var/containers/Bundle/Application/\\.jbroot-[0-9A-Fa-f]{16}/Applications/[^/]+\\.app(?:/|$)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    return [expression firstMatchInString:standardPath
                                  options:0
                                    range:NSMakeRange(0, standardPath.length)] != nil;
}

- (uint64_t)currentJailbreakBrand {
    uint64_t brand = jbinfo(jbrand);
    if (brand != 0) return brand;

    // After a relaunch the root path is restored from jailbreakd while the
    // in-process jbrand field can still be zero. Derive it from the strictly
    // formatted active RootHide root instead.
    NSString *rootPath = [JBROOT_PATH(@"/") stringByStandardizingPath];
    NSString *pattern = @"(?:^|/)\\.jbroot-([0-9A-Fa-f]{16})(?:/|$)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [expression firstMatchInString:rootPath
                                                         options:0
                                                           range:NSMakeRange(0, rootPath.length)];
    if (!match || match.numberOfRanges < 2) return 0;

    unsigned long long parsedBrand = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[rootPath substringWithRange:[match rangeAtIndex:1]]];
    if (![scanner scanHexLongLong:&parsedBrand] || !scanner.isAtEnd) return 0;
    return (uint64_t)parsedBrand;
}

#pragma mark - LaunchServices

// LSApplicationProxy is private: the header declares it but the SDK exports
// no linkable class symbol, so referencing it directly fails to link. Resolve
// the class at runtime instead.
static Class RLXHealthApplicationProxyClass(void) {
    static Class proxyClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxyClass = NSClassFromString(@"LSApplicationProxy");
    });
    return proxyClass;
}

- (NSString *)registeredPathForBundleIdentifier:(NSString *)bundleIdentifier {
    if (bundleIdentifier.length == 0) return nil;
    Class proxyClass = RLXHealthApplicationProxyClass();
    if (!proxyClass) return nil;
    LSApplicationProxy *proxy = [proxyClass applicationProxyForIdentifier:bundleIdentifier];
    if (!proxy || !proxy.installed || proxy.bundleURL.path.length == 0) return nil;
    return proxy.bundleURL.path;
}

- (BOOL)waitForBundleIdentifier:(NSString *)bundleIdentifier registeredAtPath:(NSString *)expectedPath {
    for (NSUInteger attempt = 0; attempt < 20; attempt++) {
        NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
        BOOL matches = expectedPath.length ? [self path:registeredPath equalsPath:expectedPath]
                                           : (registeredPath.length == 0);
        if (matches) return YES;
        [NSThread sleepForTimeInterval:0.05];
    }
    return NO;
}

- (NSDictionary<NSString *, NSString *> *)userApplicationPathsForBundleIdentifiers:
    (NSSet<NSString *> *)bundleIdentifiers {
    if (bundleIdentifiers.count == 0) return @{};

    NSMutableDictionary<NSString *, NSString *> *matches = [NSMutableDictionary new];
    NSString *userApplicationsPath = @"/var/containers/Bundle/Application";
    NSArray<NSString *> *containers =
        [self.fileManager contentsOfDirectoryAtPath:userApplicationsPath error:nil] ?: @[];

    for (NSString *containerName in containers) {
        // The RootHide root itself lives here behind a hidden .jbroot-* entry.
        // It is not a user app container and must never be treated as one.
        if ([containerName hasPrefix:@"."]) continue;

        NSString *containerPath = [userApplicationsPath stringByAppendingPathComponent:containerName];
        NSArray<NSString *> *contents = [self.fileManager contentsOfDirectoryAtPath:containerPath error:nil] ?: @[];
        for (NSString *candidate in contents) {
            if (![candidate.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
            NSString *appPath = [containerPath stringByAppendingPathComponent:candidate];
            NSDictionary *info =
                [NSDictionary dictionaryWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"]];
            NSString *bundleIdentifier = info[@"CFBundleIdentifier"];
            if ([bundleIdentifiers containsObject:bundleIdentifier] && !matches[bundleIdentifier]) {
                matches[bundleIdentifier] = appPath;
            }
        }
    }
    return matches;
}

- (NSArray<NSDictionary *> *)jailbreakApplicationRecords {
    NSString *applicationsPath = JBROOT_PATH(@"/Applications");
    NSArray<NSString *> *contents = [self.fileManager contentsOfDirectoryAtPath:applicationsPath error:nil] ?: @[];
    NSMutableArray<NSDictionary *> *records = [NSMutableArray new];

    for (NSString *candidate in contents) {
        if (![candidate.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
        NSString *appPath = [applicationsPath stringByAppendingPathComponent:candidate];
        BOOL isDirectory = NO;
        if (![self.fileManager fileExistsAtPath:appPath isDirectory:&isDirectory] || !isDirectory) continue;

        NSDictionary *info =
            [NSDictionary dictionaryWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"]];
        [records addObject:@{
            @"Path" : appPath,
            @"Name" : candidate.stringByDeletingPathExtension,
            @"BundleIdentifier" : info[@"CFBundleIdentifier"] ?: @"",
        }];
    }
    return records;
}

#pragma mark - dpkg

- (NSDictionary *)installedPackageInfoForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) return nil;
    NSString *status = [NSString stringWithContentsOfFile:JBROOT_PATH(@"/var/lib/dpkg/status")
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    status = [status stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    NSString *packageLine = [NSString stringWithFormat:@"Package: %@", identifier];
    for (NSString *paragraph in [status componentsSeparatedByString:@"\n\n"]) {
        NSArray<NSString *> *lines = [paragraph componentsSeparatedByString:@"\n"];
        if (![lines containsObject:packageLine]) continue;

        NSMutableDictionary *result = [NSMutableDictionary new];
        for (NSString *line in lines) {
            NSRange separator = [line rangeOfString:@": "];
            if (separator.location == NSNotFound) continue;
            NSString *field = [line substringToIndex:separator.location];
            NSString *value = [line substringFromIndex:NSMaxRange(separator)];
            if (field.length && value.length) result[field] = value;
        }
        return result;
    }
    return nil;
}

- (BOOL)isPackageInstalled:(NSDictionary *)packageInfo {
    return [packageInfo[@"Status"] isEqualToString:@"install ok installed"];
}

#pragma mark - Checks

- (RLXHealthItem *)bootstrapHealthItem {
    NSMutableArray<NSString *> *missing = [NSMutableArray new];
    // Value == YES means the path also has to be executable.
    NSDictionary<NSString *, NSNumber *> *requiredPaths = @{
        @".installed_relaxin" : @NO,
        @"basebin/.version" : @NO,
        @"basebin/jbctl" : @YES,
        @"usr/bin/dpkg" : @YES,
        @"usr/bin/uicache" : @YES,
    };

    NSString *root = [JBROOT_PATH(@"/") stringByStandardizingPath];
    if (root.length == 0 || ![self.fileManager fileExistsAtPath:root]) {
        [missing addObject:@"JBROOT"];
    }
    [requiredPaths enumerateKeysAndObjectsUsingBlock:^(NSString *relativePath, NSNumber *mustBeExecutable, BOOL *stop) {
        NSString *path = [root stringByAppendingPathComponent:relativePath];
        BOOL present = mustBeExecutable.boolValue ? [self.fileManager isExecutableFileAtPath:path]
                                                  : [self.fileManager fileExistsAtPath:path];
        if (!present) [missing addObject:relativePath.lastPathComponent];
    }];

    if (missing.count) {
        return [self itemWithIdentifier:RLXHealthIdentifierBootstrap
                                  title:@"越狱环境"
                                 detail:[NSString stringWithFormat:@"缺少关键组件：%@",
                                                                   [missing componentsJoinedByString:@"、"]]
                                  state:RLXHealthStateWarning
                              canRepair:NO];
    }
    return [self itemWithIdentifier:RLXHealthIdentifierBootstrap
                              title:@"越狱环境"
                             detail:@"rootfs 与 basebin 组件齐全"
                              state:RLXHealthStateHealthy
                          canRepair:NO];
}

- (RLXHealthItem *)jailbreakApplicationsHealthItem {
    NSArray<NSDictionary *> *records = [self jailbreakApplicationRecords];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *pathsByIdentifier = [NSMutableDictionary new];
    NSUInteger invalidCount = 0;

    for (NSDictionary *record in records) {
        NSString *bundleIdentifier = record[@"BundleIdentifier"];
        if (bundleIdentifier.length == 0) {
            invalidCount++;
            continue;
        }
        if (!pathsByIdentifier[bundleIdentifier]) pathsByIdentifier[bundleIdentifier] = [NSMutableArray new];
        [pathsByIdentifier[bundleIdentifier] addObject:record[@"Path"]];
    }

    NSDictionary<NSString *, NSString *> *userConflicts =
        [self userApplicationPathsForBundleIdentifiers:[NSSet setWithArray:pathsByIdentifier.allKeys]];
    __block NSUInteger duplicateCount = 0;
    __block NSUInteger conflictCount = userConflicts.count;
    __block NSUInteger missingCount = 0;
    __block NSUInteger staleCount = 0;

    [pathsByIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *bundleIdentifier,
                                                           NSMutableArray<NSString *> *paths, BOOL *stop) {
        if (paths.count > 1) {
            duplicateCount++;
            return;
        }
        NSString *expectedPath = paths.firstObject;
        NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
        if (registeredPath.length == 0) {
            missingCount++;
        } else if (![self path:registeredPath equalsPath:expectedPath]) {
            if ([self isRootHideManagedApplicationPath:registeredPath]) {
                staleCount++;
            } else if (!userConflicts[bundleIdentifier]) {
                conflictCount++;
            }
        }
    }];

    if (duplicateCount || conflictCount) {
        return [self itemWithIdentifier:RLXHealthIdentifierJailbreakApps
                                  title:@"应用注册"
                                 detail:[NSString stringWithFormat:@"重复 %lu 个、与非越狱应用冲突 %lu 个，需手动处理",
                                                                   (unsigned long)duplicateCount,
                                                                   (unsigned long)conflictCount]
                                  state:RLXHealthStateConflict
                              canRepair:NO];
    }
    if (invalidCount) {
        return [self itemWithIdentifier:RLXHealthIdentifierJailbreakApps
                                  title:@"应用注册"
                                 detail:[NSString stringWithFormat:@"%lu 个应用缺少有效的 Info.plist",
                                                                   (unsigned long)invalidCount]
                                  state:RLXHealthStateWarning
                              canRepair:NO];
    }
    if (missingCount || staleCount) {
        return [self itemWithIdentifier:RLXHealthIdentifierJailbreakApps
                                  title:@"应用注册"
                                 detail:[NSString stringWithFormat:@"未注册 %lu 个、注册路径过期 %lu 个，可修复",
                                                                   (unsigned long)missingCount,
                                                                   (unsigned long)staleCount]
                                  state:RLXHealthStateRepairable
                              canRepair:YES];
    }

    if (records.count == 0) {
        return [self itemWithIdentifier:RLXHealthIdentifierJailbreakApps
                                  title:@"应用注册"
                                 detail:@"未找到任何越狱应用"
                                  state:RLXHealthStateWarning
                              canRepair:NO];
    }
    return [self itemWithIdentifier:RLXHealthIdentifierJailbreakApps
                              title:@"应用注册"
                             detail:[NSString stringWithFormat:@"%lu 个越狱应用均已正确注册",
                                                               (unsigned long)records.count]
                              state:RLXHealthStateHealthy
                          canRepair:NO];
}

- (RLXHealthItem *)sileoHealthItem {
    NSString *key = RLXHealthIdentifierSileo;
    NSString *expectedPath =
        [JBROOT_PATH(@"/Applications") stringByAppendingPathComponent:RLXHealthSileoApplication];
    NSDictionary *packageInfo = [self installedPackageInfoForIdentifier:RLXHealthSileoDebianPackage];
    BOOL packageInstalled = [self isPackageInstalled:packageInfo];
    BOOL appExists = [self.fileManager fileExistsAtPath:expectedPath];
    NSDictionary *appInfo =
        appExists
            ? [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]]
            : nil;
    BOOL bundleValid = [appInfo[@"CFBundleIdentifier"] isEqualToString:key];
    NSString *registeredPath = [self registeredPathForBundleIdentifier:key];

    NSUInteger matchingJailbreakApps = 0;
    BOOL unexpectedJailbreakOwner = NO;
    for (NSDictionary *record in [self jailbreakApplicationRecords]) {
        if ([record[@"BundleIdentifier"] isEqualToString:key]) {
            matchingJailbreakApps++;
            if (![self path:record[@"Path"] equalsPath:expectedPath]) unexpectedJailbreakOwner = YES;
        }
    }
    NSDictionary *userConflicts = [self userApplicationPathsForBundleIdentifiers:[NSSet setWithObject:key]];

    if (userConflicts[key] || matchingJailbreakApps > 1 || unexpectedJailbreakOwner ||
        (registeredPath.length && ![self path:registeredPath equalsPath:expectedPath] &&
         ![self isRootHideManagedApplicationPath:registeredPath])) {
        return [self itemWithIdentifier:key
                                  title:@"Sileo商店"
                                 detail:@"检测到重复或冲突的 Sileo 安装，需手动处理"
                                  state:RLXHealthStateConflict
                              canRepair:NO];
    }

    NSMutableArray<NSString *> *problems = [NSMutableArray new];
    if (!packageInstalled) [problems addObject:@"dpkg 未记录"];
    if (!appExists) {
        [problems addObject:@"应用缺失"];
    } else if (!bundleValid) {
        [problems addObject:@"Bundle 标识不符"];
    }
    if (bundleValid && registeredPath.length == 0) {
        [problems addObject:@"未注册到桌面"];
    } else if (bundleValid && ![self path:registeredPath equalsPath:expectedPath]) {
        [problems addObject:@"注册路径过期"];
    }

    if (problems.count) {
        return [self itemWithIdentifier:key
                                  title:@"Sileo商店"
                                 detail:[problems componentsJoinedByString:@" · "]
                                  state:RLXHealthStateRepairable
                              canRepair:YES];
    }

    return [self itemWithIdentifier:key
                              title:@"Sileo商店"
                             detail:[NSString stringWithFormat:@"已安装 %@", packageInfo[@"Version"] ?: @"?"]
                              state:RLXHealthStateHealthy
                          canRepair:NO];
}

- (RLXHealthItem *)injectionHealthItem {
    if ([self.fileManager fileExistsAtPath:JBROOT_PATH(@"/basebin/.safe_mode")]) {
        return [self itemWithIdentifier:RLXHealthIdentifierInjection
                                  title:@"插件注入"
                                 detail:@"安全模式已开启，插件注入被停用"
                                  state:RLXHealthStateDisabled
                              canRepair:NO];
    }

    uint64_t brand = [self currentJailbreakBrand];
    NSString *brandedName = [NSString stringWithFormat:@"systemhook-%016llX.dylib", brand];
    NSString *brandedPath = [JBROOT_PATH(@"/basebin") stringByAppendingPathComponent:brandedName];
    if (brand != 0 && [self.fileManager fileExistsAtPath:brandedPath]) {
        return [self itemWithIdentifier:RLXHealthIdentifierInjection
                                  title:@"插件注入"
                                 detail:[NSString stringWithFormat:@"运行中：%@", brandedName]
                                  state:RLXHealthStateHealthy
                              canRepair:NO];
    }

    BOOL hasFixedHook = [self.fileManager fileExistsAtPath:JBROOT_PATH(@"/basebin/systemhook.dylib")];
    return [self itemWithIdentifier:RLXHealthIdentifierInjection
                              title:@"插件注入"
                             detail:hasFixedHook ? @"systemhook 已就位，等待下次用户空间重启后生效"
                                                 : @"未找到 systemhook.dylib"
                              state:RLXHealthStateWarning
                          canRepair:NO];
}

#pragma mark - Repair

- (NSError *)repairRegistrationForPath:(NSString *)expectedPath bundleIdentifier:(NSString *)bundleIdentifier {
    NSDictionary *info =
        [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]];
    if (![info[@"CFBundleIdentifier"] isEqualToString:bundleIdentifier]) {
        return [self errorWithDescription:@"应用的 Bundle 标识与预期不符，已中止修复"];
    }

    NSDictionary *userConflicts =
        [self userApplicationPathsForBundleIdentifiers:[NSSet setWithObject:bundleIdentifier]];
    if (userConflicts[bundleIdentifier]) {
        return [self errorWithDescription:@"同标识的非越狱应用已安装，请先手动卸载"];
    }

    NSString *registeredPath = [self registeredPathForBundleIdentifier:bundleIdentifier];
    if (registeredPath.length && ![self path:registeredPath equalsPath:expectedPath]) {
        if (![self isRootHideManagedApplicationPath:registeredPath]) {
            return [self errorWithDescription:@"同标识的非越狱应用已安装，请先手动卸载"];
        }
        int unregisterStatus = RLXPostJailbreakWaitStatus(exec_cmd(
            JBROOT_PATH("/usr/bin/uicache"), "-u", registeredPath.fileSystemRepresentation, NULL));
        if (unregisterStatus != 0) {
            return [self errorWithDescription:[NSString stringWithFormat:@"注销旧注册失败（%d）", unregisterStatus]];
        }
    }

    int registerStatus = RLXPostJailbreakWaitStatus(
        exec_cmd(JBROOT_PATH("/usr/bin/uicache"), "-p", expectedPath.fileSystemRepresentation, NULL));
    if (registerStatus != 0 || ![self waitForBundleIdentifier:bundleIdentifier registeredAtPath:expectedPath]) {
        return [self errorWithDescription:[NSString stringWithFormat:@"重新注册失败（%d）", registerStatus]];
    }
    return nil;
}

- (NSError *)repairJailbreakApplications {
    RLXHealthItem *current = [self jailbreakApplicationsHealthItem];
    if (current.state == RLXHealthStateConflict || current.state == RLXHealthStateWarning) {
        return [self errorWithDescription:current.detail];
    }
    if (!current.canRepair) return nil;

    for (NSDictionary *record in [self jailbreakApplicationRecords]) {
        NSString *bundleIdentifier = record[@"BundleIdentifier"];
        NSString *expectedPath = record[@"Path"];
        if (bundleIdentifier.length == 0) continue;
        if ([self path:[self registeredPathForBundleIdentifier:bundleIdentifier] equalsPath:expectedPath]) continue;
        NSError *error = [self repairRegistrationForPath:expectedPath bundleIdentifier:bundleIdentifier];
        if (error) return error;
    }
    return nil;
}

- (NSError *)repairSileo {
    RLXHealthItem *current = [self sileoHealthItem];
    if (current.state == RLXHealthStateHealthy) return nil;
    if (!current.canRepair) return [self errorWithDescription:current.detail];

    NSString *expectedPath =
        [JBROOT_PATH(@"/Applications") stringByAppendingPathComponent:RLXHealthSileoApplication];
    NSDictionary *packageInfo = [self installedPackageInfoForIdentifier:RLXHealthSileoDebianPackage];
    NSDictionary *appInfo =
        [NSDictionary dictionaryWithContentsOfFile:[expectedPath stringByAppendingPathComponent:@"Info.plist"]];
    BOOL requiresInstall = ![self isPackageInstalled:packageInfo] ||
                           ![appInfo[@"CFBundleIdentifier"] isEqualToString:RLXHealthIdentifierSileo];

    if (requiresInstall) {
        NSString *packagePath = [self.resourceBundle pathForResource:RLXHealthSileoPackageResource ofType:@"deb"];
        if (packagePath.length == 0 || ![self.fileManager fileExistsAtPath:packagePath]) {
            return [self errorWithDescription:@"安装包内未找到 sileo.deb"];
        }
        // dpkg runs inside the jbroot, where the real filesystem is mounted
        // at /rootfs — a bare host path does not resolve there. jbctl also
        // trusts the binary first. Mirrors the engine's installBundledPackageNamed:.
        NSString *rootfsPackage = [@"/rootfs" stringByAppendingPathComponent:packagePath];
        int installStatus = RLXPostJailbreakWaitStatus(
            exec_cmd(JBROOT_PATH("/basebin/jbctl"), "internal", "install_pkg",
                     rootfsPackage.fileSystemRepresentation, NULL));
        if (installStatus != 0) {
            return [self errorWithDescription:[NSString stringWithFormat:@"安装 Sileo 失败（%d）", installStatus]];
        }
    }

    return [self repairRegistrationForPath:expectedPath bundleIdentifier:RLXHealthIdentifierSileo];
}

#pragma mark - Entry points

- (NSArray<RLXHealthItem *> *)scanHealth {
    NSString *failurePhase = nil;
    if (RLXPostJailbreakLoadRoot(&failurePhase) != 0) {
        return [self unknownHealthItems];
    }

    __block NSArray<RLXHealthItem *> *items = nil;
    (void)RLXPostJailbreakRunAsEffectiveRoot(
        ^int {
            return RLXPostJailbreakRunUnsandboxed(
                ^int {
                    items = @[
                        [self bootstrapHealthItem],
                        [self jailbreakApplicationsHealthItem],
                        [self sileoHealthItem],
                        [self injectionHealthItem],
                    ];
                    return 0;
                },
                NULL);
        },
        NULL);
    return items ?: [self unknownHealthItems];
}

- (NSError *)repairItemWithIdentifier:(NSString *)identifier {
    if (![identifier isEqualToString:RLXHealthIdentifierJailbreakApps] &&
        ![identifier isEqualToString:RLXHealthIdentifierSileo]) {
        return [self errorWithDescription:@"该项目前不支持自动修复"];
    }

    NSString *failurePhase = nil;
    if (RLXPostJailbreakLoadRoot(&failurePhase) != 0) {
        return [self errorWithDescription:@"无法接入越狱环境"];
    }

    __block NSError *repairError = nil;
    __block BOOL didRun = NO;
    (void)RLXPostJailbreakRunAsEffectiveRoot(
        ^int {
            return RLXPostJailbreakRunUnsandboxed(
                ^int {
                    didRun = YES;
                    if ([identifier isEqualToString:RLXHealthIdentifierJailbreakApps]) {
                        repairError = [self repairJailbreakApplications];
                    } else {
                        repairError = [self repairSileo];
                    }
                    return 0;
                },
                NULL);
        },
        NULL);

    if (!didRun) return [self errorWithDescription:@"提权失败，无法执行修复"];
    return repairError;
}

#else /* !(TARGET_OS_IOS && !TARGET_OS_SIMULATOR) */

- (NSArray<RLXHealthItem *> *)scanHealth {
    return [self unknownHealthItems];
}

- (NSError *)repairItemWithIdentifier:(NSString *)identifier {
    return [self errorWithDescription:@"当前平台不支持健康检测"];
}

#endif

@end
