import SwiftUI

// Shake effect for animated UI elements
struct ShakeEffect: GeometryEffect {
    static var sinceStart = Double.random(in: 1000...10000)
    var animatableData: Double
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ShakeEffect.sinceStart += 0.01
        let angle = sin(animatableData * 2) * 0.02
        let translation = CGFloat(sin(animatableData * 3)) * 0.5
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(angle))
        let translationTransform = CGAffineTransform(translationX: translation, y: 0)
        return ProjectionTransform(rotationTransform.concatenating(translationTransform))
    }
} 