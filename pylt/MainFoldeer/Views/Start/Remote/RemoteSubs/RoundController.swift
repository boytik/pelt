import SwiftUI

struct CircularDPad: View {
    // Callbacks для каждой кнопки
    var onUp: () -> Void
    var onDown: () -> Void
    var onLeft: () -> Void
    var onRight: () -> Void
    var onCenter: () -> Void
    
    // Размеры
    private let outerRadius: CGFloat = 120
    private let innerRadius: CGFloat = 70
    private let buttonSize: CGFloat = 16
    
    // Состояния нажатий
    @State private var pressedButton: DPadButton?
    
    enum DPadButton {
        case up, down, left, right, center
    }
    
    var body: some View {
        ZStack {
            // Красное кольцо
            Circle()
                .fill(Color.red)
                .frame(width: outerRadius * 2, height: outerRadius * 2)
            
            // Черный центр
            Circle()
                .fill(Color.black)
                .frame(width: innerRadius * 2, height: innerRadius * 2)
            
            // Кнопки направлений
            // Верх
            DirectionalButton(
                direction: .up,
                isPressed: pressedButton == .up
            )
            .offset(y: -outerRadius + buttonSize)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedButton = .up
                }
                onUp()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButton = nil
                    }
                }
            }
            
            // Низ
            DirectionalButton(
                direction: .down,
                isPressed: pressedButton == .down
            )
            .offset(y: outerRadius - buttonSize)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedButton = .down
                }
                onDown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButton = nil
                    }
                }
            }
            
            // Лево
            DirectionalButton(
                direction: .left,
                isPressed: pressedButton == .left
            )
            .offset(x: -outerRadius + buttonSize)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedButton = .left
                }
                onLeft()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButton = nil
                    }
                }
            }
            
            // Право
            DirectionalButton(
                direction: .right,
                isPressed: pressedButton == .right
            )
            .offset(x: outerRadius - buttonSize)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedButton = .right
                }
                onRight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButton = nil
                    }
                }
            }
            
            // Центральная кнопка OK
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedButton = .center
                }
                onCenter()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButton = nil
                    }
                }
            }) {
                Text("OK")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: innerRadius * 1.2, height: innerRadius * 1.2)
                    .background(
                        Circle()
                            .fill(Color.black)
                            .opacity(pressedButton == .center ? 0.6 : 1.0)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: outerRadius * 2, height: outerRadius * 2)
    }
}

// Компонент для направленных кнопок
struct DirectionalButton: View {
    let direction: CircularDPad.DPadButton
    let isPressed: Bool
    
    private let buttonSize: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Белая точка
            Circle()
                .fill(Color.white)
                .frame(width: buttonSize, height: buttonSize)
            
            // Черный контур
            Circle()
                .stroke(Color.black, lineWidth: 3)
                .frame(width: buttonSize + 6, height: buttonSize + 6)
        }
        .opacity(isPressed ? 0.5 : 1.0)
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

// Preview
struct CircularDPad_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            
            CircularDPad(
                onUp: { print("Up pressed") },
                onDown: { print("Down pressed") },
                onLeft: { print("Left pressed") },
                onRight: { print("Right pressed") },
                onCenter: { print("OK pressed") }
            )
        }
    }
}
