// TimeBank/TimeBank/Retention/LitCalendarView.swift
//
// 点亮日历（闭环：连续奖励的可见化）。只庆祝点亮，从不审判空白。
// 自动补灯：没存入的那一周显示"留白"成色（柔环），不是"断签"，永不清零。

import SwiftUI

struct LitCalendarView: View {
    let moments: [Moment]

    private var model: StreakModel { StreakModel.build(moments: moments) }
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: TBSpace.s2), count: 7)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                headerCard
                calendarCard
                weeksCard
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s3)
            .padding(.bottom, TBSpace.s7)
        }
        .background(Color.tbBg)
        .navigationTitle("点亮日历")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text("陪伴你的第 \(model.weekNumber) 周")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
            Text("共 \(model.totalMoments) 个瞬间 · 这个月你点亮了 \(model.litDaysThisMonth) 天")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TBSpace.s5)
        .tbThemedSurface()
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text(model.monthTitle)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            LazyVGrid(columns: columns, spacing: TBSpace.s2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(model.monthDays.enumerated()), id: \.offset) { _, date in
                    dayCell(date)
                }
            }
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface()
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let lit = model.isLit(date)
            let isToday = Calendar.current.isDateInToday(date)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 13, weight: lit ? .semibold : .regular))
                .foregroundStyle(lit ? Color.tbSurface : Color.tbInk2)
                .frame(width: 32, height: 32)
                .background {
                    if lit {
                        Circle().fill(Color.tbPrimary)
                    } else if isToday {
                        Circle().strokeBorder(Color.tbInk3.opacity(0.4), lineWidth: 1)
                    }
                }
        } else {
            Color.clear.frame(width: 32, height: 32)
        }
    }

    private var weeksCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("最近八周")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            HStack(spacing: TBSpace.s2) {
                ForEach(model.weekCells) { cell in
                    ZStack {
                        if cell.isLit {
                            Circle().fill(Color.tbPrimary)
                        } else {
                            Circle().strokeBorder(Color.tbHair, lineWidth: 1.4)
                        }
                        if cell.isCurrent {
                            Circle().strokeBorder(Color.tbInk3.opacity(0.5), lineWidth: 1)
                                .padding(-3)
                        }
                    }
                    .frame(width: 20, height: 20)
                    .frame(maxWidth: .infinity)
                }
            }

            Text("断了也没关系，空着的那周我们替你留着。")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface()
    }
}
