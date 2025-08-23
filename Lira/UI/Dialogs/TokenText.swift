import SwiftUI
import UIKit

struct InlineImageText: View {
    let text: String
    var font: UIFont = UIFont.systemFont(ofSize: 18, weight: .regular)
    var imageSize: CGFloat? = nil        // leave nil to match font capHeight
    var imageBaselineOffset: CGFloat? = nil // leave nil for auto baseline
    var textColor: UIColor = .label
    
    var body: some View {
        AttributedLabel(
            attributedText: NSAttributedString.inlineImages(
                from: text,
                font: font,
                imageSize: imageSize,
                imageBaselineOffset: imageBaselineOffset,
                textColor: textColor
            )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// UILabel that automatically wraps to its current width and reports the correct intrinsic height
final class WrappingLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep wrapping width in sync with actual bounds
        if preferredMaxLayoutWidth != bounds.width {
            preferredMaxLayoutWidth = bounds.width
        }
    }

    override var bounds: CGRect {
        didSet {
            if preferredMaxLayoutWidth != bounds.width {
                preferredMaxLayoutWidth = bounds.width
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        // Ask UILabel how tall it wants to be at the wrapping width
        let width = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : UIScreen.main.bounds.width
        let fitting = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitting.height))
    }
}

private struct AttributedLabel: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UILabel {
        let label: UILabel = WrappingLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedText
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
        uiView.invalidateIntrinsicContentSize()
    }
}

extension NSAttributedString {
    /// Converts "Hello [star] world [cat]" into an attributed string with inline images.
    static func inlineImages(
        from source: String,
        font: UIFont,
        imageSize: CGFloat? = nil,
        imageBaselineOffset: CGFloat? = nil,
        textColor: UIColor = .label
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        var uifont = font
        if let descriptor = font.fontDescriptor.withDesign(.rounded) {
            uifont = UIFont(descriptor: descriptor, size: font.pointSize)
        }
        
        let baseAttrs: [NSAttributedString.Key: Any] = [.font: uifont,
                                                        .foregroundColor: textColor]

        // Regex for tokens like [icon_name]
        let pattern = #"\[([^\[\]\s]+)\]"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        var currentIndex = source.startIndex

        func appendText(_ s: Substring) {
            result.append(NSAttributedString(string: String(s), attributes: baseAttrs))
        }

        let nsString = source as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let matches = regex?.matches(in: source, options: [], range: fullRange) ?? []

        if matches.isEmpty {
            // No tokens – just return plain text
            return NSAttributedString(string: source, attributes: baseAttrs)
        }

        for (i, match) in matches.enumerated() {
            // Append text before the match
            let matchRange = Range(match.range, in: source)!
            appendText(source[currentIndex..<matchRange.lowerBound])

            // Extract token name (inside brackets)
            let nameRange = match.range(at: 1)
            let token = nsString.substring(with: nameRange)

            if let image = UIImage(named: token) {
                // Compute size: default to capHeight to look emoji-like
                let targetSide = imageSize ?? font.capHeight
                let scale = max(targetSide / max(image.size.width, image.size.height), 0.01)
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

                let attachment = NSTextAttachment()
                attachment.image = image

                // Align to text baseline: y = (font.descender) helps sit on baseline
                let baseline = imageBaselineOffset ?? (font.descender / 2)
                attachment.bounds = CGRect(x: 0, y: baseline, width: size.width, height: size.height)

                result.append(NSAttributedString(attachment: attachment))
            } else {
                // Fallback: keep original token text if image is missing
                result.append(NSAttributedString(string: "[\(token)]", attributes: baseAttrs))
            }

            // Advance cursor
            currentIndex = matchRange.upperBound

            // Append any trailing text after the last match
            if i == matches.count - 1 {
                appendText(source[currentIndex..<source.endIndex])
            }
        }

        return result
    }
}

