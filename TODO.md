# SwiftUtils TODO

> 来源：Ordira 影序（2026-10）开发中反复手写、适合沉淀的通用件。
> 原则：只收**平台无关、无业务语义**的小工具；不引入 Photos / SwiftData / Core ML / AppKit 依赖；每条配测试。
> Ordira 目前仍保持零依赖，这些件先在 App 内实现，稳定后再抽过来并锁版本。

## 待实现

### 1. `Array.chunked(into:)`

- 场景：SwiftData 批量 upsert / 删除按 500、1000 分块，Ordira 里手写了一份。
- API：`func chunked(into size: Int) -> [[Element]]`
- 明确边界：`size <= 0` 的行为（建议返回 `[]`，不要死循环）；空数组返回 `[]`。
- 测试：空、整除、不整除、`size > count`、`size <= 0`。

### 2. `ResumeOnceGate`（回调桥接只 resume 一次）

- 场景：PhotoKit 的 `requestImage` 可能多次回调；`withCheckedContinuation` 二次 resume 直接崩。Ordira 里复制了三份 `NSLock` gate。
- API 草案：

```swift
public final class ResumeOnceGate: @unchecked Sendable {
    public init()
    public func tryResume() -> Bool
}
```

- 测试：并发 100 次只有一次返回 `true`。
- 注意：只做 gate，不封装具体 continuation，避免把 Photos 依赖带进库。

### 3. `withTimeout`

- 场景：索引单张资产卡在 Vision / Core ML；Ordira 手写了 unstructured task + token 的 60 秒超时。
- API 草案：

```swift
public struct TimeoutError: Error {}
public func withTimeout<T: Sendable>(
    _ duration: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T
```

- 必须写清楚：超时后只能**请求取消**；卡在非协作系统调用里的任务不保证停。调用方若要阻止超时后的写入，需要自己的 token（Ordira 就是这么做的）。
- 测试：正常返回、超时抛错、取消传播。

### 4. `AsyncDebouncer`（高频事件合并）

- 场景：`photoLibraryDidChange` 一次新增触发多条，Ordira 每条都整页 reload；需要 300–500ms 合并。
- API 草案：actor，`schedule(delay:operation:)` 后到覆盖先到，`cancel()`。
- 只负责「最后一次执行」；事件内容怎么合并由调用方决定。
- 测试：连续 schedule 只执行最后一次；cancel 后不执行；跨 actor 调用不崩。

### 5. `RetryPolicy`（次数 + 指数退避）

- 场景：失败索引重试上限 3 次、仅云端 7 天 / 5 次，Ordira 手写了一套。
- API 草案：

```swift
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public func delay(forAttempt attempt: Int) -> TimeInterval?
}
```

- 纯函数，不碰存储/网络；`nil` 表示不再重试。
- 测试：0/1/2/3 次、达到上限、极端 attempt 不溢出。

## 已知问题（不急着改）

- `DateUtil` 硬编码 `Asia/Shanghai`，跨时区项目会静默错。建议默认 `TimeZone.current`，需要固定时区的调用方显式传。
- `UserDefaultUtil` 用默认值吞掉「没数据 vs 数据坏了」。建议区分 optional 读取与默认值。
- `LogUtil` 与 `os.Logger` / swift-log 的关系需要统一；Ordira 现在直接用 `os.Logger`。

## 不做

- 照片、权限、Vision、向量、SwiftData 相关：留在 App 或 `OrdiraShared`，不进通用库。
- 任何默认开启网络的能力。
