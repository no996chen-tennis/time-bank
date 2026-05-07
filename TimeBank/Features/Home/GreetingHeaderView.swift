// TimeBank/Features/Home/GreetingHeaderView.swift

import SwiftUI

struct GreetingHeaderView: View {
    var body: some View {
        HStack(alignment: .center) {
            Text(greeting)
                .font(.tbHeadL)
                .foregroundStyle(Color.tbInk)

            Spacer()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)

        switch hour {
        case 5..<10:
            return "早上好"
        case 10..<14:
            return "你好"
        case 14..<18:
            return "下午好"
        case 18..<23:
            return "晚上好"
        default:
            return "夜深了"
        }
    }
}
