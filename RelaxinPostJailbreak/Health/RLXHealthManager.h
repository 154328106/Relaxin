#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RLXHealthState) {
    RLXHealthStateUnknown = 0,
    RLXHealthStateHealthy,
    RLXHealthStateWarning,
    RLXHealthStateRepairable,
    RLXHealthStateConflict,
    RLXHealthStateDisabled,
};

FOUNDATION_EXPORT NSString *const RLXHealthIdentifierBootstrap;
FOUNDATION_EXPORT NSString *const RLXHealthIdentifierJailbreakApps;
FOUNDATION_EXPORT NSString *const RLXHealthIdentifierSileo;
FOUNDATION_EXPORT NSString *const RLXHealthIdentifierInjection;

@interface RLXHealthItem : NSObject

@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, copy, readonly) NSString *title;
@property(nonatomic, copy, readonly) NSString *detail;
@property(nonatomic, readonly) RLXHealthState state;
@property(nonatomic, readonly) BOOL canRepair;

@end

@interface RLXHealthManager : NSObject

@property(nonatomic, strong, readonly) NSBundle *resourceBundle;

- (instancetype)initWithResourceBundle:(NSBundle *)resourceBundle NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Inspects LaunchServices and the RootHide filesystem, so it must be called
/// off the main queue.
- (NSArray<RLXHealthItem *> *)scanHealth;

/// Narrowly scoped repair for one item. Returns nil on success.
- (nullable NSError *)repairItemWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
