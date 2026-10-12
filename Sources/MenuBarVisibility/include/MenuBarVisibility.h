#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Boundary to macOS 27's private MenuBarClientCore. Objective-C so that an
// exception from a changed private API is caught instead of crashing the app.
BOOL MBVIsAvailable(void);

// Keeps only the given system items and apps visible; MenuBarAgent hides every
// other status item until the returned assertion is invalidated or the process exits.
void MBVActivate(NSArray<NSNumber *> *allowedSystemItems,
                 NSArray<NSString *> *allowedBundleIdentifiers,
                 void (^completion)(id _Nullable assertion, NSError *_Nullable error));

void MBVInvalidate(id assertion);

NS_ASSUME_NONNULL_END
