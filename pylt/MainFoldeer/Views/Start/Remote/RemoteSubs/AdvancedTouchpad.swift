import SwiftUI

/// Продвинутый тачпад с визуализацией траектории и скоростью
struct AdvancedTouchpad: View {
    // Callbacks
    var onSwipeUp: (SwipeVelocity) -> Void
    var onSwipeDown: (SwipeVelocity) -> Void
    var onSwipeLeft: (SwipeVelocity) -> Void
    var onSwipeRight: (SwipeVelocity) -> Void
    var onTap: () -> Void
    var onDoubleTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    
    // Настройки
    var backgroundColor: Color = .black
    var indicatorColor: Color = Color(hex: "#E91E63")
    var width: CGFloat = 280
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 20
    var showTrail: Bool = true
    
    @State private var activeDirection: SwipeDirection?
    @State private var isDragging = false
    @State private var touchPoints: [CGPoint] = []
    @State private var lastTapTime: Date?
    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false
    
    enum SwipeDirection {
        case up, down, left, right
    }
    
    enum SwipeVelocity {
        case slow, medium, fast
        
        static func from(distance: CGFloat, time: TimeInterval) -> SwipeVelocity {
            let speed = distance / CGFloat(time)
            if speed > 800 { return .fast }
            if speed > 400 { return .medium }
            return .slow
        }
    }
    
    var body: some View {
        ZStack {
            // Основной тачпад
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isLongPressing ? indicatorColor.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: isLongPressing ? 3 : 1
                        )
                        .animation(.easeInOut(duration: 0.3), value: isLongPressing)
                )
            
            // Сетка (опционально)
            if !isDragging {
                gridPattern
                    .opacity(0.1)
            }
            
            // Индикаторы направлений
            directionalIndicators
            
            // Визуализация траектории
            if showTrail && isDragging {
                trailVisualization
            }
            
            // Индикатор long press
            if isLongPressing {
                longPressIndicator
            }
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
    }
    
    // MARK: - Grid Pattern
    
    private var gridPattern: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 20
                
                // Вертикальные линии
                var x: CGFloat = spacing
                while x < geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x += spacing
                }
                
                // Горизонтальные линии
                var y: CGFloat = spacing
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        }
    }
    
    // MARK: - Directional Indicators
    
    private var directionalIndicators: some View {
        ZStack {
            chevronIndicator(direction: .up)
                .offset(y: -height/2 + 20)
            
            chevronIndicator(direction: .down)
                .offset(y: height/2 - 20)
            
            chevronIndicator(direction: .left)
                .offset(x: -width/2 + 20)
            
            chevronIndicator(direction: .right)
                .offset(x: width/2 - 20)
        }
    }
    
    private func chevronIndicator(direction: SwipeDirection) -> some View {
        ZStack {
            // Свечение при активации
            if activeDirection == direction {
                Circle()
                    .fill(indicatorColor.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .blur(radius: 5)
            }
            
            Image(systemName: chevronSymbol(for: direction))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(activeDirection == direction ? indicatorColor : indicatorColor.opacity(0.5))
                .scaleEffect(activeDirection == direction ? 1.3 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: activeDirection)
    }
    
    private func chevronSymbol(for direction: SwipeDirection) -> String {
        switch direction {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
    
    // MARK: - Trail Visualization
    
    private var trailVisualization: some View {
        ZStack {
            // Отрисовка траектории
            ForEach(0..<touchPoints.count, id: \.self) { index in
                if index > 0 {
                    Path { path in
                        path.move(to: touchPoints[index - 1])
                        path.addLine(to: touchPoints[index])
                    }
                    .stroke(
                        indicatorColor.opacity(Double(index) / Double(touchPoints.count) * 0.5),
                        lineWidth: 3
                    )
                }
                
                Circle()
                    .fill(indicatorColor.opacity(Double(index) / Double(touchPoints.count) * 0.6))
                    .frame(width: 8, height: 8)
                    .position(touchPoints[index])
            }
            
            // Текущая точка касания
            if let lastPoint = touchPoints.last {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 20, height: 20)
                    .position(lastPoint)
                    .shadow(color: indicatorColor.opacity(0.5), radius: 5)
            }
        }
    }
    
    // MARK: - Long Press Indicator
    
    private var longPressIndicator: some View {
        ZStack {
            Circle()
                .stroke(indicatorColor, lineWidth: 3)
                .frame(width: 50, height: 50)
            
            Circle()
                .fill(indicatorColor.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 20))
                .foregroundColor(indicatorColor)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLongPressing)
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            touchPoints = [value.location]
            
            // Запуск таймера для long press
            longPressTimer?.invalidate()
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                if !isMovingSignificantly() {
                    triggerLongPress()
                }
            }
        }
        
        // Добавляем точку в траекторию
        touchPoints.append(value.location)
        
        // Ограничиваем количество точек
        if touchPoints.count > 50 {
            touchPoints.removeFirst()
        }
        
        let threshold: CGFloat = 30
        let translation = value.translation
        
        // Определяем направление
        if abs(translation.height) > abs(translation.width) {
            if translation.height < -threshold {
                activeDirection = .up
            } else if translation.height > threshold {
                activeDirection = .down
            }
        } else {
            if translation.width < -threshold {
                activeDirection = .left
            } else if translation.width > threshold {
                activeDirection = .right
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        longPressTimer?.invalidate()
        
        let threshold: CGFloat = 30
        let translation = value.translation
        let distance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
        
        // Вычисляем скорость
        let time = Date().timeIntervalSince(value.time)
        let velocity = SwipeVelocity.from(distance: distance, time: time)
        
        // Если это был свайп
        if distance > threshold && !isLongPressing {
            let impact = UIImpactFeedbackGenerator(style: velocity == .fast ? .heavy : .medium)
            impact.impactOccurred()
            
            if abs(translation.height) > abs(translation.width) {
                if translation.height < -threshold {
                    onSwipeUp(velocity)
                } else if translation.height > threshold {
                    onSwipeDown(velocity)
                }
            } else {
                if translation.width < -threshold {
                    onSwipeLeft(velocity)
                } else if translation.width > threshold {
                    onSwipeRight(velocity)
                }
            }
        } else if distance < 10 && !isLongPressing {
            // Это был тап
            handleTap()
        }
        
        // Сброс состояния
        withAnimation(.easeOut(duration: 0.3)) {
            isDragging = false
            activeDirection = nil
            isLongPressing = false
        }
        
        touchPoints.removeAll()
    }
    
    private func handleTap() {
        let now = Date()
        
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < 0.3 {
            // Двойной тап
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onDoubleTap?()
            lastTapTime = nil
        } else {
            // Одиночный тап
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
            lastTapTime = now
        }
    }
    
    private func triggerLongPress() {
        isLongPressing = true
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        onLongPress?()
    }
    
    private func isMovingSignificantly() -> Bool {
        guard touchPoints.count > 2,
              let first = touchPoints.first,
              let last = touchPoints.last else {
            return false
        }
        
        let distance = sqrt(pow(last.x - first.x, 2) + pow(last.y - first.y, 2))
        return distance > 20
    }
}

// MARK: - Full Remote Control Example

struct FullRemoteControlView: View {
    @State private var currentAction = "Выбери действие"
    @State private var volume = 50
    @State private var brightness = 70
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0F2027"),
                    Color(hex: "#203A43"),
                    Color(hex: "#2C5364")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Статус
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: isPlaying ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "#E91E63"))
                        
                        Text(currentAction)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            Image(systemName: "speaker.wave.3.fill")
                            Text("\(volume)%")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "sun.max.fill")
                            Text("\(brightness)%")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.3))
                )
                
                // Тачпад
                AdvancedTouchpad(
                    onSwipeUp: { velocity in
                        let increment = velocityIncrement(velocity)
                        brightness = min(100, brightness + increment)
                        currentAction = "☀️ Яркость \(velocity == .fast ? "↑↑" : "↑")"
                    },
                    onSwipeDown: { velocity in
                        let increment = velocityIncrement(velocity)
                        brightness = max(0, brightness - increment)
                        currentAction = "🌙 Яркость \(velocity == .fast ? "↓↓" : "↓")"
                    },
                    onSwipeLeft: { velocity in
                        let increment = velocityIncrement(velocity)
                        volume = max(0, volume - increment)
                        currentAction = "🔉 Громкость \(velocity == .fast ? "↓↓" : "↓")"
                    },
                    onSwipeRight: { velocity in
                        let increment = velocityIncrement(velocity)
                        volume = min(100, volume + increment)
                        currentAction = "🔊 Громкость \(velocity == .fast ? "↑↑" : "↑")"
                    },
                    onTap: {
                        isPlaying.toggle()
                        currentAction = isPlaying ? "▶️ Воспроизведение" : "⏸️ Пауза"
                    },
                    onDoubleTap: {
                        currentAction = "⏭️ Следующий трек"
                    },
                    onLongPress: {
                        currentAction = "🏠 Домой"
                        volume = 50
                        brightness = 70
                    },
                    backgroundColor: .black,
                    indicatorColor: Color(hex: "#E91E63"),
                    width: 300,
                    height: 220,
                    cornerRadius: 20,
                    showTrail: true
                )
                
                // Подсказки
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        Label("Свайп = Навигация", systemImage: "hand.draw")
                        Label("Тап = Play/Pause", systemImage: "hand.tap")
                    }
                    HStack(spacing: 20) {
                        Label("Двойной тап = След.", systemImage: "hand.tap.fill")
                        Label("Удержание = Домой", systemImage: "hand.raised.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                
                Text("💡 Быстрый свайп = больше изменений")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#E91E63").opacity(0.7))
            }
            .padding()
        }
    }
    
    private func velocityIncrement(_ velocity: AdvancedTouchpad.SwipeVelocity) -> Int {
        switch velocity {
        case .slow: return 5
        case .medium: return 10
        case .fast: return 20
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AdvancedTouchpad_Previews: PreviewProvider {
    static var previews: some View {
        FullRemoteControlView()
    }
}
