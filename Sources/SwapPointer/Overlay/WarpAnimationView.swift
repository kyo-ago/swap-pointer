import AppKit

/// A view that displays a brief expanding ring animation at the warp destination.
final class WarpAnimationView: NSView {
    private var completionHandler: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation(completion: @escaping () -> Void) {
        self.completionHandler = completion

        guard let layer = self.layer else {
            completion()
            return
        }

        // Create expanding ring
        let ringLayer = CAShapeLayer()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let initialRadius: CGFloat = 4
        let finalRadius: CGFloat = bounds.width / 2

        let initialPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - initialRadius,
                y: center.y - initialRadius,
                width: initialRadius * 2,
                height: initialRadius * 2
            ),
            transform: nil
        )
        let finalPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - finalRadius,
                y: center.y - finalRadius,
                width: finalRadius * 2,
                height: finalRadius * 2
            ),
            transform: nil
        )

        ringLayer.path = initialPath
        ringLayer.fillColor = nil
        ringLayer.strokeColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        ringLayer.lineWidth = 3
        layer.addSublayer(ringLayer)

        // Animate path expansion
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = initialPath
        pathAnimation.toValue = finalPath
        pathAnimation.duration = 0.3
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        // Animate opacity fade-out
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 0.3
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [pathAnimation, opacityAnimation]
        group.duration = 0.3

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            ringLayer.removeFromSuperlayer()
            self?.completionHandler?()
        }
        ringLayer.add(group, forKey: "warpAnimation")
        ringLayer.path = finalPath
        ringLayer.opacity = 0
        CATransaction.commit()
    }
}
