import SwiftUI
import SwiftHaptics
import SwiftUISugar

struct SegmentedControlText: View {
    
    @State var option: String
    @Binding var selectedOption: String
    @Binding var options: [String]
    @Binding var isLongPressingSelectedOption: Bool
    @State var selectedTextColor: Color?
    @State var width: CGFloat

    @State var includeDragGesture: Bool
    
    @State var textColor: Color = Color(.label)
    @State var selectorTextColor: Color

    @GestureState private var isTapped = false
    @State var isLongPressing = false

    @State var draggedForward = false
    @State var draggedBackwards = false

    /*
     SegmentedControlText(
         option: option,
         selectedOption: $selectedOption,
         options: $options,
         isLongPressingSelectedOption: $isLongPressingSelectedOption,
         selectedTextColor: selectedTextColor,
         width: optionWidth
     )
     */
    init(option: String,
         selectedOption: Binding<String>,
         options: Binding<[String]>,
         isLongPressingSelectedOption: Binding<Bool>,
         selectedTextColor: Color? = nil,
         width: CGFloat,
         includeDragGesture: Bool
    ) {
        self._option = State(initialValue: option)
        self._selectedOption = selectedOption
        self._options = options
        self._isLongPressingSelectedOption = isLongPressingSelectedOption
        self._selectedTextColor = State(initialValue: selectedTextColor)
        self._width = State(initialValue: width)
        
        if let selectedTextColor = selectedTextColor {
            self._selectorTextColor = State(initialValue: selectedTextColor)
        } else {
            self._selectorTextColor = State(initialValue: Color(.label))
        }
        
        self._includeDragGesture = State(initialValue: includeDragGesture)
    }
    
    func text(for option: String) -> some View {
        Text(option)
            .font(optionFont)
            .foregroundColor(.white)
            .colorMultiply(textColor)
            .scaleEffect(optionScale(for: option))
            .animation(animation, value: selectedOption)
            .frame(width: width)
            .contentShape(Rectangle())
            .onChange(of: isLongPressing) { newValue in
                withAnimation {
                    handleLongPress(newValue)
                }
            }
            .onChange(of: selectedOption, perform: { newValue in
                setTextColor(isLongPressing)
            })
            .onChange(of: isLongPressingSelectedOption) { newValue in
                withAnimation {
                    handleLongPressOnSelection(newValue)
                }
            }
            .task {
                setTextColor(false)
            }
            .onChange(of: colorScheme) { newValue in
                setTextColor(isLongPressing, newColorScheme: newValue)
            }
    }
    var body: some View {
        if includeDragGesture {
            text(for: option)
                .simultaneousGesture(longPressGesture(for: option))
        } else {
            text(for: option)
                .simultaneousGesture(tapGesture(for: option))
        }
    }

    func handleLongPressOnSelection(_ isLongPressingOnSelection: Bool) {
//        print("handle isLongPressingOnSelection: \(isLongPressingOnSelection)")
    }
    
    func handleLongPress(_ isLongPress: Bool) {
        if !isSelection {
            setTextColor(isLongPress)
        }
    }
    
    func tapped(_ option: String) {
        selectedOption = option
        setTextColor(isLongPressing)
        Haptics.feedback(style: .rigid)
    }

    func optionScale(for option: String) -> CGFloat {
        isSelected(option) ? selectionScale : 1.0
    }

    func isSelected(_ option: String) -> Bool {
        option == selectedOption
    }
    
    var animation: Animation {
        .easeOut(duration: 0.25)
    }
    
    func setTextColor(_ isLongPressing: Bool, newColorScheme: ColorScheme? = nil) {
//        guard !selectorDraggedOff else {
//            return
//        }
//        print("isSelection: \(isSelection), isLongPressing: \(isLongPressing), selectorDraggedOff: \(selectorDraggedOff)")
        if isSelection || (isLongPressing && selectorDraggedOff) {
//            textColor = colorScheme == .dark ? .white : .black
            textColor = selectorTextColor
//            print("selected: \(option) set to \(selectorTextColor)")
        } else if isLongPressing {
//            print("\(option) set to gray")
            textColor = Color(hex: "BEBEBF")
        } else {
//            textColor = selectorTextColor
            textColor = (newColorScheme ?? colorScheme) == .dark ? .white : .black
//            print("regular: \(option) set to \(textColor)")
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var isSelection: Bool {
        selectedOption == option
    }
    
    //MARK: Gestures
    
    @State var selectorDraggedOff: Bool = false
    
    func gestureValueIsOutOfBounds(_ value: DragGesture.Value) -> Bool {
        let x1 = 0.0, y1 = 0.0
        let x2 = abs(value.translation.width), y2 = abs(value.translation.height)
        let distance = sqrt(pow(x2-x1, 2.0)+pow(y2-y1, 2.0))
        return distance > 100.0
    }
    func longPressGesture(for option: String) -> some Gesture {
        DragGesture(minimumDistance: 0)
                    .onChanged { value in
//                        print("Dragging: \(value.location.x)")
                        handleDrag(value)
                        if isSelection || selectorDraggedOff {
                            handleDragOnSelector(value)
                        }
                    }
                    .onEnded { value in
                        selectorDraggedOff = false
                        draggedForward = false
                        draggedBackwards = false
                        isLongPressing = false
                        isLongPressingSelectedOption = false
                        if !gestureValueIsOutOfBounds(value) {
                            tapped(option)
                        }
                    }
    }
    
    func handleDrag(_ value: DragGesture.Value) {
        if gestureValueIsOutOfBounds(value) {
            isLongPressing = false
        } else {
            isLongPressing = true
        }
    }
    
    func handleDragOnSelector(_ value: DragGesture.Value) {
//        print("Dragging: \(value.location.x)")
        let swipePadding: CGFloat = 15
        if selectorDraggedOff {
            if value.location.x < width + swipePadding && draggedForward {
                dragBack()
            } else if value.location.x > -swipePadding && draggedBackwards {
                dragBack()
            }
        } else {
            if value.location.x > width + swipePadding {
                selectNext()
            } else if value.location.x < -swipePadding {
                selectPrevious()
            }
        }
        isLongPressingSelectedOption = true
    }
    
    func dragBack() {
        withAnimation(animation) {
            selectedOption = option
            Haptics.selectionFeedback()
            draggedForward = false
            draggedBackwards = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectorDraggedOff = false
            }
        }
    }
    
    
    //TODO: Next
    //Selected segmented's title should change scale while being dragged across!
    
    func selectNext() {
        guard let selectedIndex = selectedIndex, selectedIndex < options.count - 1 else {
            return
        }
        selectedOption = options[selectedIndex+1]
        Haptics.selectionFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectorDraggedOff = true
            draggedForward = true
        }
//        setTextColor(isLongPressing)
    }
    
    func selectPrevious() {
        guard let selectedIndex = selectedIndex, selectedIndex > 0 else {
            return
        }
        selectedOption = options[selectedIndex-1]
        Haptics.selectionFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectorDraggedOff = true
            draggedBackwards = true
        }
//        setTextColor(isLongPressing)
    }
    
    var selectedIndex: Int? {
        options.firstIndex(of: selectedOption)
    }
    
    func tapGesture(for option: String) -> some Gesture {
        TapGesture().onEnded {
            tapped(option)
        }
    }

}
