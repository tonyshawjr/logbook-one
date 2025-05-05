import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "appAccent" asset catalog color resource.
    static let appAccent = DeveloperToolsSupport.ColorResource(name: "appAccent", bundle: resourceBundle)

    /// The "appBackground" asset catalog color resource.
    static let appBackground = DeveloperToolsSupport.ColorResource(name: "appBackground", bundle: resourceBundle)

    /// The "cardBackground" asset catalog color resource.
    static let cardBackground = DeveloperToolsSupport.ColorResource(name: "cardBackground", bundle: resourceBundle)

    /// The "danger" asset catalog color resource.
    static let danger = DeveloperToolsSupport.ColorResource(name: "danger", bundle: resourceBundle)

    /// The "noteColor" asset catalog color resource.
    static let note = DeveloperToolsSupport.ColorResource(name: "noteColor", bundle: resourceBundle)

    /// The "paymentColor" asset catalog color resource.
    static let payment = DeveloperToolsSupport.ColorResource(name: "paymentColor", bundle: resourceBundle)

    /// The "primaryText" asset catalog color resource.
    static let primaryText = DeveloperToolsSupport.ColorResource(name: "primaryText", bundle: resourceBundle)

    /// The "secondaryText" asset catalog color resource.
    static let secondaryText = DeveloperToolsSupport.ColorResource(name: "secondaryText", bundle: resourceBundle)

    /// The "success" asset catalog color resource.
    static let success = DeveloperToolsSupport.ColorResource(name: "success", bundle: resourceBundle)

    /// The "taskColor" asset catalog color resource.
    static let task = DeveloperToolsSupport.ColorResource(name: "taskColor", bundle: resourceBundle)

    /// The "warning" asset catalog color resource.
    static let warning = DeveloperToolsSupport.ColorResource(name: "warning", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "appAccent" asset catalog color.
    static var appAccent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appAccent)
#else
        .init()
#endif
    }

    /// The "appBackground" asset catalog color.
    static var appBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBackground)
#else
        .init()
#endif
    }

    /// The "cardBackground" asset catalog color.
    static var cardBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cardBackground)
#else
        .init()
#endif
    }

    /// The "danger" asset catalog color.
    static var danger: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danger)
#else
        .init()
#endif
    }

    /// The "noteColor" asset catalog color.
    static var note: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .note)
#else
        .init()
#endif
    }

    /// The "paymentColor" asset catalog color.
    static var payment: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .payment)
#else
        .init()
#endif
    }

    /// The "primaryText" asset catalog color.
    static var primaryText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primaryText)
#else
        .init()
#endif
    }

    /// The "secondaryText" asset catalog color.
    static var secondaryText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .secondaryText)
#else
        .init()
#endif
    }

    /// The "success" asset catalog color.
    static var success: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .success)
#else
        .init()
#endif
    }

    /// The "taskColor" asset catalog color.
    static var task: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .task)
#else
        .init()
#endif
    }

    /// The "warning" asset catalog color.
    static var warning: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .warning)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "appAccent" asset catalog color.
    static var appAccent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appAccent)
#else
        .init()
#endif
    }

    /// The "appBackground" asset catalog color.
    static var appBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appBackground)
#else
        .init()
#endif
    }

    /// The "cardBackground" asset catalog color.
    static var cardBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .cardBackground)
#else
        .init()
#endif
    }

    /// The "danger" asset catalog color.
    static var danger: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .danger)
#else
        .init()
#endif
    }

    /// The "noteColor" asset catalog color.
    static var note: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .note)
#else
        .init()
#endif
    }

    /// The "paymentColor" asset catalog color.
    static var payment: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .payment)
#else
        .init()
#endif
    }

    /// The "primaryText" asset catalog color.
    static var primaryText: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primaryText)
#else
        .init()
#endif
    }

    /// The "secondaryText" asset catalog color.
    static var secondaryText: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .secondaryText)
#else
        .init()
#endif
    }

    /// The "success" asset catalog color.
    static var success: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .success)
#else
        .init()
#endif
    }

    /// The "taskColor" asset catalog color.
    static var task: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .task)
#else
        .init()
#endif
    }

    /// The "warning" asset catalog color.
    static var warning: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .warning)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "appAccent" asset catalog color.
    static var appAccent: SwiftUI.Color { .init(.appAccent) }

    /// The "appBackground" asset catalog color.
    static var appBackground: SwiftUI.Color { .init(.appBackground) }

    /// The "cardBackground" asset catalog color.
    static var cardBackground: SwiftUI.Color { .init(.cardBackground) }

    /// The "danger" asset catalog color.
    static var danger: SwiftUI.Color { .init(.danger) }

    /// The "noteColor" asset catalog color.
    static var note: SwiftUI.Color { .init(.note) }

    /// The "paymentColor" asset catalog color.
    static var payment: SwiftUI.Color { .init(.payment) }

    /// The "primaryText" asset catalog color.
    static var primaryText: SwiftUI.Color { .init(.primaryText) }

    /// The "secondaryText" asset catalog color.
    static var secondaryText: SwiftUI.Color { .init(.secondaryText) }

    /// The "success" asset catalog color.
    static var success: SwiftUI.Color { .init(.success) }

    /// The "taskColor" asset catalog color.
    static var task: SwiftUI.Color { .init(.task) }

    /// The "warning" asset catalog color.
    static var warning: SwiftUI.Color { .init(.warning) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "appAccent" asset catalog color.
    static var appAccent: SwiftUI.Color { .init(.appAccent) }

    /// The "appBackground" asset catalog color.
    static var appBackground: SwiftUI.Color { .init(.appBackground) }

    /// The "cardBackground" asset catalog color.
    static var cardBackground: SwiftUI.Color { .init(.cardBackground) }

    /// The "danger" asset catalog color.
    static var danger: SwiftUI.Color { .init(.danger) }

    /// The "noteColor" asset catalog color.
    static var note: SwiftUI.Color { .init(.note) }

    /// The "paymentColor" asset catalog color.
    static var payment: SwiftUI.Color { .init(.payment) }

    /// The "primaryText" asset catalog color.
    static var primaryText: SwiftUI.Color { .init(.primaryText) }

    /// The "secondaryText" asset catalog color.
    static var secondaryText: SwiftUI.Color { .init(.secondaryText) }

    /// The "success" asset catalog color.
    static var success: SwiftUI.Color { .init(.success) }

    /// The "taskColor" asset catalog color.
    static var task: SwiftUI.Color { .init(.task) }

    /// The "warning" asset catalog color.
    static var warning: SwiftUI.Color { .init(.warning) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

