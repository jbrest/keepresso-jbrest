// Condition cases follow Keepresso PowerSourceTrigger.Match, upstream 7ea73a6.
/// Runtime condition values. Product-owned DTOs provide their own Codable shape.
public enum PowerSourceCondition: String, CaseIterable, Sendable {
    case onACPower
    case onBattery
    case charging
}
