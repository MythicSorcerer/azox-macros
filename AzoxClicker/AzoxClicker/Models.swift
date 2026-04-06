import Foundation

enum ClickButton: String, Codable, CaseIterable, Identifiable {
    case left
    case right
    case both

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both"
        }
    }
}

enum RateMode: String, Codable, CaseIterable, Identifiable {
    case fixedCPS
    case fixedInterval
    case clicksPerDuration
    case randomInterval
    case randomCPS

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fixedCPS: return "Fixed CPS"
        case .fixedInterval: return "Fixed Interval"
        case .clicksPerDuration: return "Clicks per Duration"
        case .randomInterval: return "Random Interval"
        case .randomCPS: return "Random CPS"
        }
    }
}

enum StopMode: String, Codable, CaseIterable, Identifiable {
    case none
    case afterTime
    case afterClicks
    case randomTimeRange
    case randomClickRange

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "No Auto-Stop"
        case .afterTime: return "Stop After Time"
        case .afterClicks: return "Stop After Clicks"
        case .randomTimeRange: return "Random Time Range"
        case .randomClickRange: return "Random Click Range"
        }
    }
}

enum TimeUnit: String, Codable, CaseIterable, Identifiable {
    case milliseconds
    case seconds
    case minutes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .milliseconds: return "Milliseconds"
        case .seconds: return "Seconds"
        case .minutes: return "Minutes"
        }
    }

    func toSeconds(_ value: Double) -> Double {
        switch self {
        case .milliseconds: return value / 1000.0
        case .seconds: return value
        case .minutes: return value * 60.0
        }
    }
}

struct ClickConfiguration: Codable {
    var rateMode: RateMode = .fixedCPS
    var cps: Double = 20

    var intervalValue: Double = 50
    var intervalUnit: TimeUnit = .milliseconds

    var clicksPerDuration: Double = 10
    var durationValue: Double = 1
    var durationUnit: TimeUnit = .seconds

    var randomIntervalMin: Double = 20
    var randomIntervalMax: Double = 80
    var randomIntervalUnit: TimeUnit = .milliseconds

    var randomCpsMin: Double = 10
    var randomCpsMax: Double = 40

    var stopMode: StopMode = .none
    var stopTimeValue: Double = 10
    var stopTimeUnit: TimeUnit = .seconds
    var stopClicks: Int = 1000

    var randomTimeMin: Double = 5
    var randomTimeMax: Double = 15
    var randomTimeUnit: TimeUnit = .seconds

    var randomClicksMin: Int = 500
    var randomClicksMax: Int = 1500
    
    var bypassSafetyTimeLimit: Bool = false
    var safetyMaxTimeSeconds: Double = 5

    func resolvedIntervalSeconds() -> ClosedRange<Double> {
        switch rateMode {
        case .fixedCPS:
            let interval = max(0.0001, 1.0 / max(0.1, cps))
            return interval...interval
        case .fixedInterval:
            let interval = max(0.0001, intervalUnit.toSeconds(intervalValue))
            return interval...interval
        case .clicksPerDuration:
            let duration = max(0.0001, durationUnit.toSeconds(durationValue))
            let interval = max(0.0001, duration / max(1, clicksPerDuration))
            return interval...interval
        case .randomInterval:
            let minValue = max(0.0001, randomIntervalUnit.toSeconds(randomIntervalMin))
            let maxValue = max(minValue, randomIntervalUnit.toSeconds(randomIntervalMax))
            return minValue...maxValue
        case .randomCPS:
            let minCps = max(0.1, randomCpsMin)
            let maxCps = max(minCps, randomCpsMax)
            let minInterval = 1.0 / maxCps
            let maxInterval = 1.0 / minCps
            return minInterval...maxInterval
        }
    }

    func resolvedStopPlan() -> (maxClicks: Int?, maxTime: Double?) {
        let safetyTime: Double? = bypassSafetyTimeLimit ? nil : max(0.1, safetyMaxTimeSeconds)

        switch stopMode {
        case .none:
            return (nil, safetyTime)
        case .afterClicks:
            return (max(1, stopClicks), safetyTime)
        case .afterTime:
            let configuredTime = max(0.1, stopTimeUnit.toSeconds(stopTimeValue))
            let maxTime = minConfiguredTime(configuredTime, safetyTime: safetyTime)
            return (nil, maxTime)
        case .randomTimeRange:
            let minValue = max(0.1, randomTimeUnit.toSeconds(randomTimeMin))
            let maxValue = max(minValue, randomTimeUnit.toSeconds(randomTimeMax))
            let chosenTime = Double.random(in: minValue...maxValue)
            let maxTime = minConfiguredTime(chosenTime, safetyTime: safetyTime)
            return (nil, maxTime)
        case .randomClickRange:
            let minValue = max(1, randomClicksMin)
            let maxValue = max(minValue, randomClicksMax)
            let chosen = Int.random(in: minValue...maxValue)
            return (chosen, safetyTime)
        }
    }
    
    private func minConfiguredTime(_ configuredTime: Double, safetyTime: Double?) -> Double {
        guard let safetyTime else { return configuredTime }
        return min(configuredTime, safetyTime)
    }

    func maxCPS() -> Double {
        switch rateMode {
        case .fixedCPS:
            return cps
        case .fixedInterval:
            let interval = intervalUnit.toSeconds(intervalValue)
            return interval > 0 ? 1.0 / interval : 10000
        case .clicksPerDuration:
            let duration = durationUnit.toSeconds(durationValue)
            return duration > 0 ? clicksPerDuration / duration : 10000
        case .randomInterval:
            let minInterval = randomIntervalUnit.toSeconds(randomIntervalMin)
            return minInterval > 0 ? 1.0 / minInterval : 10000
        case .randomCPS:
            return randomCpsMax
        }
    }
}
