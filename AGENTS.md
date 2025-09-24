# Repository Guidelines

## Environment & Tooling
Develop on macOS 14+ with Xcode 16 or newer and the iOS 18 SDK. Install Tuist 4.65.6 (`brew install tuist/tuist/tuist`) and run `tuist install` before generating the workspace. Swift 6 strict concurrency is enforced; verify toolchain upgrades locally before proposing them.

## Project Structure & Modules
Tuist manages modules under `Projects/*/Project.swift`. `Kingthereum.xcworkspace` aggregates the App target with feature kits: `Projects/Core` (services & utilities), `Projects/Entity` (domain models), `Projects/WalletKit` (Ethereum flows), `Projects/SecurityKit` (crypto & biometrics), and `Projects/DesignSystem` (SwiftUI components & tokens). UI scenes reside in `Sources/Scenes/Wallet`, while scripts and automation live in `Scripts/`. Place module-specific assets inside each target’s `Resources/` directory so Tuist keeps build settings in sync.

## Architecture & Design System
The app follows Clean Architecture with VIP layers; keep `View`, `Interactor`, `Presenter`, and `Worker` folders isolated per feature and respect the dependency chain `App → WalletKit/SecurityKit/DesignSystem → Core → Entity`. Reuse the gold-forward visual language defined in `KingDesignTokens` (`Projects/DesignSystem/Sources`) and prefer token-based colors (`Color.gold`, `Color.slate`) instead of hard-coded values. When adding flows, document the data path in `graph.png` if dependencies shift.

## Build, Test & Development Commands
After cloning, run `tuist install && tuist generate`, then open the workspace with `open Kingthereum.xcworkspace`. Execute a local smoke run with `tuist test`; narrow scope by passing a module name (`tuist test SecurityKit`). For full Swift Testing coverage and HTML/markdown reports, use `Scripts/run_tests.sh`, which provisions an iPhone 15 Pro simulator and writes artifacts to `TestResults/`. Regenerate Tuist projects whenever manifests change, and rely on Xcode’s run action for device deployment.

## Coding Style & Naming Conventions
Use four-space indentation, PascalCase for types, camelCase for methods, and suffix async functions with verbs (`loadBalances()`). Annotate UI entry points `@MainActor`, prefer value types, and organize extensions with `// MARK:` blocks. VIP presenters should stay formatting-only; route business logic through interactors and workers.

## Testing Guidelines
Swift Testing (`@Suite`, `@Test`) is required for new code; mirror production namespaces like `Projects/Core/Tests/ConfigurationServiceTests.swift`. Maintain ≥75% line coverage overall and higher for security-critical paths. Provide both success and failure cases, tag long-running specs with `.timeLimit` or `.serialized`, and commit generated reports when CI requests evidence.

## Commit & Pull Request Guidelines
Follow `<type>: <짧은 설명>` (e.g., `feat: 지갑 생성 기능 구현`). One feature per PR with a concise summary, screenshots for UI changes, affected modules list, and test proof (`tuist test` output or a `TestResults/summary.md` excerpt). Link issues, call out breaking changes, and request security review when touching biometric or key management flows.

## Security & Configuration Tips
Secrets stay outside the repo: use `ConfigurationService`’s async accessors for Infura, Etherscan, and RPC credentials. Enforce PBKDF2-HMAC-SHA256 PIN storage and AES-256-GCM keychain operations when touching `Projects/SecurityKit`. Validate rate limiting, constant-time comparisons, and biometric enrollment on real hardware before promotion.
