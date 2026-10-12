#import "MenuBarVisibility.h"
#import <dlfcn.h>
#import <objc/message.h>

static const char *MBVFrameworkPath = "/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore";

static NSError *MBVError(NSString *reason) {
    return [NSError errorWithDomain:@"MenuBarVisibility" code:1 userInfo:@{NSLocalizedDescriptionKey: reason}];
}

BOOL MBVIsAvailable(void) {
    if (!dlopen(MBVFrameworkPath, RTLD_NOW | RTLD_LOCAL)) {
        return NO;
    }
    Class configuration = NSClassFromString(@"MBAssessmentModeConfiguration");
    Class assertion = NSClassFromString(@"MBAssessmentModeAssertion");
    return configuration && assertion
        && [configuration instancesRespondToSelector:@selector(initWithAllowedSystemItems:allowedBundleIdentifiers:)]
        && [assertion instancesRespondToSelector:@selector(activateWithConfiguration:completionHandler:)]
        && [assertion instancesRespondToSelector:@selector(invalidate)];
}

void MBVActivate(NSArray<NSNumber *> *allowedSystemItems,
                 NSArray<NSString *> *allowedBundleIdentifiers,
                 void (^completion)(id _Nullable assertion, NSError *_Nullable error)) {
    void (^finish)(id, NSError *) = ^(id assertion, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(assertion, error); });
    };
    if (!MBVIsAvailable()) {
        finish(nil, MBVError(@"MenuBarClientCore is unavailable on this macOS"));
        return;
    }
    @try {
        id configuration = ((id (*)(id, SEL, NSArray *, NSArray *))objc_msgSend)(
            [NSClassFromString(@"MBAssessmentModeConfiguration") alloc],
            @selector(initWithAllowedSystemItems:allowedBundleIdentifiers:),
            [allowedSystemItems copy], [allowedBundleIdentifiers copy]);
        id assertion = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
        if (!configuration || !assertion) {
            finish(nil, MBVError(@"Could not create the visibility configuration"));
            return;
        }
        ((void (*)(id, SEL, id, void (^)(NSError *)))objc_msgSend)(
            assertion, @selector(activateWithConfiguration:completionHandler:), configuration, ^(NSError *error) {
                finish(error ? nil : assertion, error);
            });
    } @catch (NSException *exception) {
        finish(nil, MBVError([NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]));
    }
}

void MBVInvalidate(id assertion) {
    @try {
        if ([assertion respondsToSelector:@selector(invalidate)]) {
            ((void (*)(id, SEL))objc_msgSend)(assertion, @selector(invalidate));
        }
    } @catch (NSException *exception) {
        NSLog(@"MenuBarVisibility: invalidate raised %@: %@", exception.name, exception.reason);
    }
}
