# Email Verifier - Swift Library

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/EnrowAPI/email-verifier-swift)](https://github.com/EnrowAPI/email-verifier-swift)
[![Last commit](https://img.shields.io/github/last-commit/EnrowAPI/email-verifier-swift)](https://github.com/EnrowAPI/email-verifier-swift/commits)

Verify email addresses in real time. Check deliverability, detect disposable and catch-all domains, and clean your email lists before sending.

Powered by [Enrow](https://enrow.io) -- real-time SMTP-level verification with high accuracy on catch-all domains.

## Installation

Add the package with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/EnrowAPI/email-verifier-swift", from: "1.0.0"),
]
```

Requires Swift 5.9+. Zero dependencies -- uses only Foundation `URLSession`.

## Simple Usage

```swift
import EmailVerifier

let verification = try await EmailVerifier.verify(
    apiKey: "your_api_key",
    email: "tcook@apple.com"
)

let result = try await EmailVerifier.getResult(apiKey: "your_api_key", id: verification.id)

print(result.email)         // tcook@apple.com
print(result.qualification) // valid
```

`verify` returns a verification ID. The verification runs asynchronously on the server -- call `getResult` to retrieve the result once it is ready. You can also pass a `webhook` URL to get notified automatically.

## Bulk verification

```swift
let batch = try await EmailVerifier.verifyBulk(
    apiKey: "your_api_key",
    verifications: [
        BulkVerification(email: "tcook@apple.com"),
        BulkVerification(email: "satya@microsoft.com"),
        BulkVerification(email: "jensen@nvidia.com"),
    ]
)

// batch.batchId, batch.total, batch.status

let results = try await EmailVerifier.getBulkResults(apiKey: "your_api_key", id: batch.batchId)
// results.results -- array of VerificationResult
```

Up to 5,000 verifications per batch. Pass a `webhook` URL to get notified when the batch completes.

## Error handling

```swift
do {
    let _ = try await EmailVerifier.verify(
        apiKey: "bad_key",
        email: "test@test.com"
    )
} catch let error as EmailVerifierError {
    print(error.statusCode) // HTTP status code
    print(error.message)    // API error description
    // Common errors:
    // - "Invalid or missing API key" (401)
    // - "Your credit balance is insufficient." (402)
    // - "Rate limit exceeded" (429)
}
```

## Getting an API key

Register at [app.enrow.io](https://app.enrow.io) to get your API key. You get **50 free credits** (= 200 verifications) with no credit card required. Each verification costs **0.25 credits**.

Paid plans start at **$17/mo** for 1,000 credits up to **$497/mo** for 100,000 credits. See [pricing](https://enrow.io/pricing).

## Documentation

- [Enrow API documentation](https://docs.enrow.io)
- [Full Enrow SDK](https://github.com/EnrowAPI/enrow-swift) -- includes email finder, phone finder, reverse email lookup, and more

## License

MIT -- see [LICENSE](LICENSE) for details.
