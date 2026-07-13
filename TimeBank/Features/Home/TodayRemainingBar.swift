// TimeBank/Features/Home/TodayRemainingBar.swift

import SwiftUI

/// 首页最上方常驻的「今天还剩」秒级 ticking 条。
/// 经 DimensionCompute.disposableRemainingText（=唯一真相源）现算，不另写公式。
struct TodayRemainingBar: View {
    var routine: DailyRoutineParams = .default

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            HStack(alignment: .firstTextBaseline, spacing: TBSpace.s3) {
                Text("今天还剩")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)

                Spacer(minLength: TBSpace.s2)

                Text(DimensionCompute.disposableRemainingText(now: ctx.date, routine: routine))
                    .font(.tbNumM)
                    .foregroundStyle(Color.tbInk)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, TBSpace.s4)
            .frame(minHeight: 56)
            .tbThemedSurface()
        }
    }
}
