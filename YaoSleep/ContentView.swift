//
//  ContentView.swift
//  YaoSleep
//
//  睡眠周期计算器 - 基于 R90 睡眠周期理论
//

import SwiftUI
internal import Combine

struct ContentView: View {
    // 保存起床时间的小时和分钟到本地（使用 @AppStorage）
    @AppStorage("wakeUpHour") private var wakeUpHour: Int = 7
    @AppStorage("wakeUpMinute") private var wakeUpMinute: Int = 0
    
    // 用于 DatePicker 绑定的计算属性
    private var wakeUpTime: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
                return calendar.date(bySettingHour: wakeUpHour, minute: wakeUpMinute, second: 0, of: tomorrow)!
            },
            set: { newValue in
                let calendar = Calendar.current
                wakeUpHour = calendar.component(.hour, from: newValue)
                wakeUpMinute = calendar.component(.minute, from: newValue)
            }
        )
    }
    
    // 用于刷新"现在时间"的计时器
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // R90周期常量
    private let sleepCycleDuration: TimeInterval = 90 * 60  // 90分钟
    private let fallAsleepTime: TimeInterval = 15 * 60      // 15分钟入睡准备
    
    var body: some View {
        ZStack {
            // 渐变背景 - 夜空蓝到深紫色
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.25),
                    Color(red: 0.15, green: 0.08, blue: 0.35),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区域
                    headerSection
                    
                    // 起床时间选择卡片
                    wakeUpTimeCard
                    
                    // 睡眠时长显示卡片
                    sleepDurationCard
                    
                    // 推荐入睡时间卡片
                    recommendedTimesCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            
            Text("猪猪的催睡小助手")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("哄你乖乖睡觉的秘密武器 💤")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - 起床时间选择卡片
    private var wakeUpTimeCard: some View {
        HStack {
            Image(systemName: "alarm.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("明天几点要爬起来呀？")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            DatePicker(
                "",
                selection: wakeUpTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .colorScheme(.dark)
            .accentColor(.orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 睡眠时长显示卡片
    private var sleepDurationCard: some View {
        let duration = calculateSleepDuration()
        
        return VStack(spacing: 10) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title3)
                    .foregroundColor(.cyan)
                
                Text("现在去睡的话...")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("能睡")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(duration.hours)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                
                Text("小时")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(duration.minutes)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                
                Text("分钟")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(getSleepComment(hours: duration.hours))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 推荐入睡时间卡片
    private var recommendedTimesCard: some View {
        let recommendedTimes = calculateRecommendedSleepTimes()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("猪猪建议你这个时间睡觉")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("（每90分钟一个睡眠周期 + 15分钟入睡）")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 10) {
                ForEach(recommendedTimes, id: \.time) { recommendation in
                    RecommendedTimeButton(
                        time: recommendation.time,
                        cycles: recommendation.cycles,
                        isOptimal: recommendation.cycles == 5 || recommendation.cycles == 6
                    )
                }
            }
            
            Text("乖，听猪猪的话早点睡哦~ 🐷💕")
                .font(.caption)
                .foregroundColor(.pink.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 计算方法
    
    /// 获取调整后的起床时间
    private func getAdjustedWakeUpTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 创建今天的起床时间
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = wakeUpHour
        components.minute = wakeUpMinute
        components.second = 0
        
        var wakeUp = calendar.date(from: components)!
        
        // 如果时间已经过了，设为明天
        if wakeUp <= now {
            wakeUp = calendar.date(byAdding: .day, value: 1, to: wakeUp)!
        }
        
        return wakeUp
    }
    
    /// 计算从现在到起床时间的睡眠时长
    private func calculateSleepDuration() -> (hours: Int, minutes: Int) {
        let adjustedWakeUpTime = getAdjustedWakeUpTime()
        
        let interval = adjustedWakeUpTime.timeIntervalSince(currentTime)
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        return (hours: max(0, hours), minutes: max(0, minutes))
    }
    
    /// 根据R90理论计算推荐的入睡时间
    private func calculateRecommendedSleepTimes() -> [(time: Date, cycles: Int)] {
        let adjustedWakeUpTime = getAdjustedWakeUpTime()
        
        var recommendations: [(time: Date, cycles: Int)] = []
        
        // 计算4-6个周期的推荐入睡时间
        for cycles in (4...6).reversed() {
            let sleepDuration = TimeInterval(cycles) * sleepCycleDuration
            let totalTimeNeeded = sleepDuration + fallAsleepTime
            let bedtime = adjustedWakeUpTime.addingTimeInterval(-totalTimeNeeded)
            
            // 只显示还没过去的时间
            if bedtime > currentTime {
                recommendations.append((time: bedtime, cycles: cycles))
            }
        }
        
        return recommendations
    }
    
    /// 根据睡眠时长返回有趣的评语
    private func getSleepComment(hours: Int) -> String {
        switch hours {
        case 0..<4:
            return "啊这...猪猪会心疼的！快去睡！😭"
        case 4..<6:
            return "有点少哦，但猪猪相信你能撑住！💪"
        case 6..<7:
            return "勉强够用，明天别打瞌睡哦～"
        case 7..<8:
            return "不错不错，是健康的小宝贝！✨"
        case 8..<9:
            return "完美！猪猪给你比个心 💕"
        default:
            return "哇塞睡这么多，养猪呢？😂"
        }
    }
}

// MARK: - 推荐时间按钮组件
struct RecommendedTimeButton: View {
    let time: Date
    let cycles: Int
    let isOptimal: Bool
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    private var sleepHours: String {
        let hours = Double(cycles) * 1.5
        return String(format: "%.1f", hours)
    }
    
    private var cycleEmoji: String {
        switch cycles {
        case 6: return "😴"
        case 5: return "😊"
        case 4: return "😅"
        default: return "💤"
        }
    }
    
    var body: some View {
        HStack {
            // 左侧：周期信息
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(cycleEmoji)
                        .font(.caption)
                    
                    Text("\(cycles) 个周期")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("约 \(sleepHours) 小时")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 右侧：时间显示
            HStack(spacing: 6) {
                if isOptimal {
                    Text(cycles == 6 ? "超棒" : "刚好")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
                
                Text(timeString)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isOptimal ? .green : .white)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isOptimal
                    ? Color.green.opacity(0.15)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isOptimal
                            ? Color.green.opacity(0.3)
                            : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - 预览
#Preview {
    ContentView()
}
