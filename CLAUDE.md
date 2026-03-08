# CLAUDE.md — iOS Development (iOS 17+)

## Tech Stack
- **Environment:** Swift 6 (Strict Concurrency), SwiftUI, iOS 17+. Use async/await. Prefer structured concurrency; use Task.detached only for offloading CPU-bound work.
- **Architecture:** MVVM + Observation Framework (`@Observable`).
- **Data:** SwiftData for persistence; `UserDefaults` for simple flags.

## Architecture Rules
- **Views:** Passive UI only. Use `.task` for async lifecycle. No `Task { }` unless necessary.
- **ViewModels:** Always `@MainActor`. Minimize SwiftUI usage in ViewModels; use `import Observation`.
- **Models:** Value types (`struct`) for data. `@Model` classes for SwiftData only.
- **DI:** Use Initializer Injection or `@Environment`. No global singletons.

## Code Standards
- **Clarity:** Prefer `guard` over nested `if`. No force unwraps (`!`) or `try!`.
- **Composition:** Extract subviews if `body` exceeds 30 lines.
- **Resources:** Use Asset Catalog symbols; no magic strings or numbers.
- **Error Handling:** Use custom `Error` enums. No `fatalError`.

## Testing Guidelines
- **Coverage:** Add unit tests for all non-trivial logic (branching, async, state, errors).
- **Async-first:** Prefer `async`/`await` tests; avoid `XCTestExpectation` unless required.
- **Behavioral:** Test observable behavior, not implementation details.
- **Deterministic:** Inject time, randomness, and external dependencies.
- **Isolated:** No real network, file system, or persistent store I/O.

## Output Guidelines
- Provide complete, compilable code.
- Skip basic explanations or alternative architecture suggestions.
- Ensure all logic is unit-testable.