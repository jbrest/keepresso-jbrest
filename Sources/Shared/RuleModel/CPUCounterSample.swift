// Counter fields follow HostCPULoadReader.Ticks, upstream 7ea73a6.
public struct CPUCounterSample: Equatable, Sendable {
    public var busy: UInt64
    public var total: UInt64

    public init(busy: UInt64, total: UInt64) {
        self.busy = busy
        self.total = total
    }
}
