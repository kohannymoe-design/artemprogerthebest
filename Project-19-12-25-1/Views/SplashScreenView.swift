import SwiftUI

struct SplashScreenView: View {
    @State private var bubble1Opacity: Double = 0
    @State private var bubble2Opacity: Double = 0
    @State private var lineOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Speech bubbles with connecting line
                ZStack {
                    // Connecting line
                    Path { path in
                        path.move(to: CGPoint(x: -60, y: 0))
                        path.addLine(to: CGPoint(x: 60, y: 0))
                    }
                    .stroke(AppColors.trustBlue.opacity(0.3), lineWidth: 2)
                    .opacity(lineOpacity)
                    
                    HStack(spacing: 120) {
                        // Left bubble
                        Image(systemName: "bubble.left")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.trustBlue)
                            .opacity(bubble1Opacity)
                            .scaleEffect(scale)
                        
                        // Right bubble
                        Image(systemName: "bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.calmGreen)
                            .opacity(bubble2Opacity)
                            .scaleEffect(scale)
                    }
                }
                
                // App title
                Text("Money Conversation Manager")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(titleOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                bubble1Opacity = 1.0
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.8)) {
                    bubble2Opacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.6)) {
                    lineOpacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.8)) {
                    titleOpacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

