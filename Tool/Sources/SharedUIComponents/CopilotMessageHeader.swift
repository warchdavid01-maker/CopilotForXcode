import SwiftUI

public struct CopilotMessageHeader: View {
    let spacing: CGFloat
    
    public init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ZStack {
                Circle()
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    .frame(width: 24, height: 24)
                
                Image("CopilotLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            }
            
            Text("GitHub Copilot")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .padding(.leading, 4)
                
            Spacer()
        }
    }
}
