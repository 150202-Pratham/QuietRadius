import SwiftUI

struct IntroView: View {
    // Brand Colors
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")
    
    @State private var selectedDuration: Int = 25
    @State private var checkpoints: [Checkpoint] = []
    @State private var newCheckpointText: String = ""
    
    // Custom Duration State
    @State private var showingCustomDurationSheet = false
    @State private var customDurationInput: String = ""
    @State private var customDurationValue: Int? = nil // Store custom value if set
    
    // For delete animation
    @State private var isEditing: Bool = false
    
    let durations = [25, 30, 90]
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [tealColor, tealColor.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan Your Session")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(peachColor)
                            
                            Text("Customize your focus time and goals.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Section: Duration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Session Length")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    Spacer().frame(width: 24) // Leading padding
                                    
                                    ForEach(durations, id: \.self) { duration in
                                        DurationCard(
                                            amount: duration,
                                            isSelected: selectedDuration == duration && customDurationValue == nil,
                                            color: peachColor
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                selectedDuration = duration
                                                customDurationValue = nil // Reset custom
                                            }
                                        }
                                    }
                                    
                                    // Custom Option
                                    CustomDurationCard(
                                        color: peachColor,
                                        isSelected: customDurationValue != nil,
                                        customValue: customDurationValue
                                    )
                                    .onTapGesture {
                                        showingCustomDurationSheet = true
                                        if let val = customDurationValue {
                                            customDurationInput = String(val)
                                        } else {
                                            customDurationInput = ""
                                        }
                                    }
                                    
                                    Spacer().frame(width: 24) // Trailing padding
                                }
                            }
                        }
                        
                        // Section: Checkpoints
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Focus Checkpoints")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 24)
                            
                            // Add New Task Input
                            HStack {
                                Image(systemName: "plus")
                                    .foregroundColor(peachColor)
                                
                                TextField("What do you want to achieve?", text: $newCheckpointText)
                                    .foregroundColor(.white)
                                    .accentColor(peachColor)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        addCheckpoint()
                                    }
                                
                                if !newCheckpointText.isEmpty {
                                    Button(action: addCheckpoint) {
                                        Text("Add")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(tealColor)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(peachColor)
                                            .cornerRadius(12)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .padding(.horizontal, 24)
                            
                            // Task List
                            if !checkpoints.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(checkpoints) { checkpoint in
                                        CheckpointRow(
                                            checkpoint: checkpoint,
                                            color: peachColor,
                                            onToggle: {
                                                toggleCheckpoint(id: checkpoint.id)
                                            },
                                            onDelete: {
                                                deleteCheckpoint(id: checkpoint.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .transition(.opacity)
                            } else {
                                // Empty State Hint
                                Text("Add checkpoints to break down your task.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 10)
                            }
                        }
                        
                        // Spacer to allow scrolling past the button area
                        Color.clear.frame(height: 100)
                    }
                    .padding(.bottom, 20)
                }
                
                // Footer: Start Button (Sticky)
                VStack {
                    NavigationLink(destination: TimerView(
                        durationMinutes: customDurationValue ?? selectedDuration,
                        checkpoints: checkpoints
                    )) {
                        HStack {
                            Text("Start Focus Session")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(tealColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(peachColor)
                        .cornerRadius(16)
                        .shadow(color: peachColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10) // Extra padding for SafeArea is handled by background
                }
                .padding(.top, 20)
                .background(
                    VStack {
                        LinearGradient(
                            colors: [tealColor.opacity(0), tealColor.opacity(1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        
                        tealColor
                    }
                    .ignoresSafeArea()
                )
            }
        }
        .sheet(isPresented: $showingCustomDurationSheet) {
            CustomDurationSheet(
                input: $customDurationInput,
                onSet: { value in
                    customDurationValue = value
                    selectedDuration = value
                    showingCustomDurationSheet = false
                },
                onCancel: {
                    showingCustomDurationSheet = false
                },
                tealColor: tealColor,
                peachColor: peachColor
            )
        }
    }
    
    // MARK: - Logic
    func addCheckpoint() {
        guard !newCheckpointText.isEmpty else { return }
        withAnimation(.spring()) {
            checkpoints.append(Checkpoint(title: newCheckpointText))
            newCheckpointText = ""
        }
    }
    
    func toggleCheckpoint(id: UUID) {
        if let index = checkpoints.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring()) {
                checkpoints[index].isCompleted.toggle()
            }
        }
    }
    
    func deleteCheckpoint(id: UUID) {
        withAnimation(.spring()) {
            checkpoints.removeAll(where: { $0.id == id })
        }
    }
}

// MARK: - Components

struct DurationCard: View {
    let amount: Int
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(amount)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
            
            Text("min")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.5))
        }
        .frame(width: 75, height: 95)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? color : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct CustomDurationCard: View {
    let color: Color
    let isSelected: Bool
    let customValue: Int?
    
    var body: some View {
        VStack(spacing: 4) {
            if let value = customValue {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                Text("min")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.5))
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .padding(.bottom, 2)
                
                Text("Custom")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.5))
            }
        }
        .frame(width: 75, height: 95)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? color : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct CheckpointRow: View {
    let checkpoint: Checkpoint
    let color: Color
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    // Brand Color
    let tealColor = Color(hex: "233D4C")
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Delete Background
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(maxHeight: .infinity)
                }
                .background(Color.red.opacity(0.8))
                .cornerRadius(16)
            }
            .padding(.horizontal, 1) // Tiny padding to hide red edge
            
            // Content
            HStack(spacing: 16) {
                Button(action: onToggle) {
                    Circle()
                        .strokeBorder(checkpoint.isCompleted ? color : Color.white.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(checkpoint.isCompleted ? color : Color.clear))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(tealColor)
                                .opacity(checkpoint.isCompleted ? 1 : 0)
                        )
                }
                
                Text(checkpoint.title)
                    .font(.body)
                    .foregroundColor(checkpoint.isCompleted ? .white.opacity(0.4) : .white)
                    .strikethrough(checkpoint.isCompleted)
                
                Spacer()
                
                // Drag indicator hint
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 4, height: 24)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -80 {
                            onDelete()
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}

struct Checkpoint: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}

// MARK: - First Responder TextField (UIViewRepresentable)
// Needed because @FocusState is unreliable in Swift Playgrounds

struct FirstResponderTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        tf.textColor = .white
        tf.tintColor = UIColor(Color(hex: "FD802E"))
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
        )
        tf.backgroundColor = .clear
        // Become first responder after a short delay so the sheet is fully presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            tf.becomeFirstResponder()
        }
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FirstResponderTextField
        init(_ parent: FirstResponderTextField) { self.parent = parent }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            if let r = Range(range, in: current) {
                parent.text = current.replacingCharacters(in: r, with: string)
            }
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onCommit()
            return true
        }
    }
}

// MARK: - Custom Duration Sheet

struct CustomDurationSheet: View {
    @Binding var input: String
    let onSet: (Int) -> Void
    let onCancel: () -> Void
    let tealColor: Color
    let peachColor: Color

    var isValid: Bool { (Int(input) ?? 0) > 0 }

    var body: some View {
        ZStack {
            tealColor.ignoresSafeArea()

            VStack(spacing: 28) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                Text("Set Custom Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(peachColor)

                // Native UITextField wrapper — keyboard always appears
                FirstResponderTextField(
                    text: $input,
                    placeholder: "0",
                    onCommit: {
                        if isValid { onSet(Int(input)!) }
                    }
                )
                .frame(height: 70)
                .padding(.horizontal, 40)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 40)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)

                    Button(action: {
                        if isValid { onSet(Int(input)!) }
                    }) {
                        Text("Set Time")
                            .fontWeight(.bold)
                            .foregroundColor(tealColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(isValid ? peachColor : peachColor.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                }

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.hidden)
    }
}
