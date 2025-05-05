#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.logbookone.LogbookOne";

/// The "appAccent" asset catalog color resource.
static NSString * const ACColorNameAppAccent AC_SWIFT_PRIVATE = @"appAccent";

/// The "appBackground" asset catalog color resource.
static NSString * const ACColorNameAppBackground AC_SWIFT_PRIVATE = @"appBackground";

/// The "cardBackground" asset catalog color resource.
static NSString * const ACColorNameCardBackground AC_SWIFT_PRIVATE = @"cardBackground";

/// The "danger" asset catalog color resource.
static NSString * const ACColorNameDanger AC_SWIFT_PRIVATE = @"danger";

/// The "noteColor" asset catalog color resource.
static NSString * const ACColorNameNoteColor AC_SWIFT_PRIVATE = @"noteColor";

/// The "paymentColor" asset catalog color resource.
static NSString * const ACColorNamePaymentColor AC_SWIFT_PRIVATE = @"paymentColor";

/// The "primaryText" asset catalog color resource.
static NSString * const ACColorNamePrimaryText AC_SWIFT_PRIVATE = @"primaryText";

/// The "secondaryText" asset catalog color resource.
static NSString * const ACColorNameSecondaryText AC_SWIFT_PRIVATE = @"secondaryText";

/// The "success" asset catalog color resource.
static NSString * const ACColorNameSuccess AC_SWIFT_PRIVATE = @"success";

/// The "taskColor" asset catalog color resource.
static NSString * const ACColorNameTaskColor AC_SWIFT_PRIVATE = @"taskColor";

/// The "warning" asset catalog color resource.
static NSString * const ACColorNameWarning AC_SWIFT_PRIVATE = @"warning";

#undef AC_SWIFT_PRIVATE
