//
//  ContentView.swift
//  YaoSleep
//
//  睡眠周期计算器 - 基于 R90 睡眠周期理论
//

import SwiftUI
internal import Combine

struct ContentView: View {
    // 起床时间，默认明天早上7点
    @State private var wakeUpTime: Date = {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow)!
    }()
    
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
                VStack(spacing: 24) {
                    // 标题区域
                    headerSection
                    
                    // 起床时间选择卡片
                    wakeUpTimeCard
                    
                    // 睡眠时长显示卡片
                    sleepDurationCard
                    
                    // 推荐入睡时间卡片
                    recommendedTimesCard
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            
            Text("睡眠周期计算器")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("基于 R90 睡眠周期理论")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 起床时间选择卡片
    private var wakeUpTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("明天起床时间")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            DatePicker(
                "",
                selection: $wakeUpTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 睡眠时长显示卡片
    private var sleepDurationCard: some View {
        let duration = calculateSleepDuration()
        
        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("如果现在睡觉")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(duration.hours)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                
                Text("小时")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(duration.minutes)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                
                Text("分钟")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("到起床时间的睡眠时长")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 推荐入睡时间卡片
    private var recommendedTimesCard: some View {
        let recommendedTimes = calculateRecommendedSleepTimes()
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("最佳入睡时间")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("每90分钟一个睡眠周期 + 15分钟入睡准备")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 12) {
                ForEach(recommendedTimes, id: \.time) { recommendation in
                    RecommendedTimeButton(
                        time: recommendation.time,
                        cycles: recommendation.cycles,
                        isOptimal: recommendation.cycles == 5 || recommendation.cycles == 6
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 计算方法
    
    /// 计算从现在到起床时间的睡眠时长
    private func calculateSleepDuration() -> (hours: Int, minutes: Int) {
        var adjustedWakeUpTime = wakeUpTime
        
        // 如果选择的时间已经过了，认为是明天的这个时间
        if adjustedWakeUpTime <= currentTime {
            adjustedWakeUpTime = Calendar.current.date(byAdding: .day, value: 1, to: adjustedWakeUpTime)!
        }
        
        let interval = adjustedWakeUpTime.timeIntervalSince(currentTime)
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        return (hours: max(0, hours), minutes: max(0, minutes))
    }
    
    /// 根据R90理论计算推荐的入睡时间
    private func calculateRecommendedSleepTimes() -> [(time: Date, cycles: Int)] {
        var adjustedWakeUpTime = wakeUpTime
        
        // 如果选择的时间已经过了，认为是明天的这个时间
        if adjustedWakeUpTime <= currentTime {
            adjustedWakeUpTime = Calendar.current.date(byAdding: .day, value: 1, to: adjustedWakeUpTime)!
        }
        
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
    
    var body: some View {
        HStack {
            // 左侧：周期信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "powersleep")
                        .font(.caption)
                        .foregroundColor(isOptimal ? .green : .white.opacity(0.7))
                    
                    Text("\(cycles) 个周期")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("约 \(sleepHours) 小时")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 右侧：时间显示
            HStack(spacing: 8) {
                if isOptimal {
                    Text("推荐")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
                
                Text(timeString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isOptimal ? .green : .white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isOptimal
                    ? Color.green.opacity(0.15)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
