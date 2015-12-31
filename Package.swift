#if os(Linux)
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/joshb/CEpoll.git", majorVersion: 1)
    ]
)
#endif
