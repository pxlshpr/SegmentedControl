import SwiftUI
import SwiftHaptics

public struct SegmentedControl: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedOption: String
    @Binding var options: [String]
    
    @State var selectorOffset: CGFloat = 0
    @State var tappedTextColor: Color = Color.black
    @State var isLongPressingSelectedOption: Bool = false
    
    @State var selectorScale: CGFloat = 1.0
    @State var longPressingOffset: CGFloat = 0
    
    @State var selectedTextColor: Color?
    @State var selectedBackgroundColor: Color?
    
    var backgroundColor: Color {
        Color(.tertiarySystemFill)
    }
    
    var selectorBackgroundColor: Color {
        if let selectedBackgroundColor = selectedBackgroundColor {
            return selectedBackgroundColor
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.275) : Color.white
        }
    }
    
    public init(_ selectedOption: Binding<String>,
         options: Binding<[String]>,
         selectedTextColor: Color? = nil,
         selectedBackgroundColor: Color? = nil)
    {
        self._selectedOption = selectedOption
        self._options = options
        self._selectedTextColor = State(initialValue: selectedTextColor)
        self._selectedBackgroundColor = State(initialValue: selectedBackgroundColor)
    }
    
    public init(_ selectedOption: Binding<String>,
         options: [String],
         selectedTextColor: Color? = nil,
         selectedBackgroundColor: Color? = nil)
    {
        self._selectedOption = selectedOption
        self._options = .constant(options)
        self._selectedTextColor = State(initialValue: selectedTextColor)
        self._selectedBackgroundColor = State(initialValue: selectedBackgroundColor)
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            background
            selector
            texts
        }
        .clipped()
        .task {
            setSelectorOffset()
        }
        .onChange(of: selectedOption) { newValue in
            withAnimation(animation) {
                setSelectorOffset()
                setLongPressingOffset()
            }
        }
        .onChange(of: isLongPressingSelectedOption) { newValue in
            withAnimation(animation) {
                selectorScale = isLongPressingSelectedOption ? 0.95 : 1.0
                setLongPressingOffset()
            }
        }
    }
    
    var animation: Animation {
        .easeOut(duration: 0.25)
    }
    
    var background: some View {
        backgroundColor
            .cornerRadius(cornerRadiusBackground)
            .frame(width: totalWidth, height: height)
    }
    
    var selector: some View {
        selectorBackgroundColor
            .frame(width: selectorWidth, height: selectorHeight)
            .cornerRadius(cornerRadiusSelector)
            .offset(x: selectorOffset + longPressingOffset)
            .shadow(color: Color.black.opacity(0.125),
                    radius: 3.0,
                    x: 0, y: 3.0)
            .scaleEffect(selectorScale, anchor: scaleAnchor)
    }
    
    var scaleAnchor: UnitPoint {
        guard let index = selectedIndex else {
            return .center
        }
        if index == 0 {
            return .leading
        } else if index == options.count - 1 {
            return .trailing
        } else {
            return .center
        }
    }
    
    var texts: some View {
        HStack(spacing: spacing) {
            ForEach(options, id: \.self) { option in
                SegmentedControlText(
                    option: option,
                    selectedOption: $selectedOption,
                    options: $options,
                    isLongPressingSelectedOption: $isLongPressingSelectedOption,
                    selectedTextColor: selectedTextColor,
                    width: optionWidth
                )
                    .scaleEffect(option == selectedOption ? selectorScale : 1.0, anchor: scaleAnchor)
            }
        }
        .offset(x: paddingBackgroundX)
    }
    
    //MARK: Dimensions
    
    var selectedIndex: Int? {
        options.firstIndex(of: selectedOption)
    }
    
    func setSelectorOffset() {
        guard let selectedIndex = selectedIndex else {
            return
        }
        let extra = (
            (paddingSelectorX * 2.0)
            + largestWidth
            + spacing
        ) * CGFloat(selectedIndex)
        
        selectorOffset = paddingBackgroundX + extra
    }
    
    func setLongPressingOffset() {
        guard let selectedIndex = selectedIndex, isLongPressingSelectedOption else {
            longPressingOffset = 0
            return
        }
        
        if selectedIndex == 0 {
            longPressingOffset = 1
        } else if selectedIndex == options.count - 1 {
            longPressingOffset = 3 + 3 + 3 - 1
        }
    }
    
    var selectorWidth: CGFloat {
        largestWidth
        + (paddingSelectorX * 2.0)
    }
    
    var largestWidth: CGFloat {
        (options.map({ widthForOptionString($0) }).max() ?? 0.0)
        * selectionScale
    }
    
    var optionWidth: CGFloat {
        (paddingSelectorX * 2.0)
        + largestWidth
    }
    
    var totalWidth: CGFloat {
        (paddingBackgroundX * 2.0)
        + (paddingSelectorX * 2.0 * count)
        + (spacing * (count - 1.0))
        + (largestWidth * count)
    }
    
    //    func widthForOptionString(_ string: String, font: UIFont) -> CGFloat {
    //        string.size(withAttributes:[.font: font]).width
    //    }
    
    func widthForOptionString(_ string: String) -> CGFloat {
        //        let font = isSelected(string) ? selectedOptionUIFont : optionUIFont
        //        return widthForOptionString(string, font: font)
        string.size(withAttributes:[.font: optionUIFont]).width
    }
    
    var count: CGFloat {
        CGFloat(options.count)
    }
    //MARK: - Magic Numbers
    let paddingSelectorX: CGFloat = 8
    let paddingBackgroundX: CGFloat = 2
    let cornerRadiusSelector: CGFloat = 6
    let cornerRadiusBackground: CGFloat = 8
    let height: CGFloat = 32.0
    let spacing: CGFloat = 5.0
    
    let paddingSelectorY: CGFloat = 2
    
    var selectorHeight: CGFloat {
        height
        - (2.0 * paddingSelectorY)
    }
}

let selectionScale = 1.03

var optionFont: Font {
    Font.system(size: FontSize, weight: FontWeight, design: .default)
}
var optionUIFont: UIFont {
    UIFont.systemFont(ofSize: FontSize, weight: UIFontWeight)
}

let FontSize = 13.0
let FontWeight: Font.Weight = .medium
let UIFontWeight: UIFont.Weight = .medium
