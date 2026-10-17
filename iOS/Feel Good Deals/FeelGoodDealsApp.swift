// From Claude AI on 21 August 2026
//
// Unlisted App Distribution
//
// Apple's newer option: the app goes through full App Review and
//  lives on the App Store infrastructure, but it's not searchable,
//  browsable, or listed anywhere — accessible only via a direct link you control.
//  This is closest to "permanent TestFlight replacement" with normal App Store update mechanics.
//  However, Apple explicitly states it's discoverable only with a direct link,
//  meaning anyone with the link could install it — it's hidden, not access-restricted.
//  You'd also need to first submit the app as a normal public-distribution app
//  and be ready for final distribution before requesting unlisted status
//  — requests will be declined... if your app is in a beta or prerelease state.
//
// 1 Confirm distribution method is set to Public
// In App Store Connect, on your app's Pricing and Availability page, make sure the distribution method is set to 'Public Distribution' (not Private/Apple Business Manager). Unlisted status is only reachable from the public path — if it's currently set to private, you'd need to create a new app record instead.
//
// 2 Build out the store listing
// Even though it won't be browsable, Apple still requires the normal App Store metadata: description, screenshots, privacy policy URL, support URL, age rating, etc. Treat this like a real public submission.
//
// 3 Submit the build to App Review
// Upload your build (the one you've been running through TestFlight) and submit it for App Review as if it were going fully public. This is required — Apple will decline unlisted requests for apps still in a beta/prerelease state.
//
// 4 Add a note in Review Notes
// In the Review Notes field of that submission, explicitly state that the app is intended for Unlisted App Distribution and briefly explain why (e.g. 'this app is built for a specific small group of users, not the general public'). This helps the reviewer evaluate it correctly instead of rejecting it under Guideline 3.2 for being too narrow an audience.
//
// 5 Submit the official unlisted distribution request
// Separately, fill out Apple's request form at developer.apple.com/contact/request/unlisted-app/. This is the formal request that actually triggers the switch to Unlisted status — the Review Notes alone don't do it.
//
// 6 Wait for both approvals
// App Review will evaluate the build normally. The unlisted request is evaluated separately. Once both are approved, your app's distribution method in Pricing and Availability will change to 'Unlisted App,' and this applies to all future versions too.
//
// 7 Get and share your direct link
// Apple generates a direct App Store link once approved. Share that link with your 4-5 people (and anyone else in the future) — it won't appear in search, browsing, or charts, but anyone with the link can install it.
//
// 8 Consider adding in-app access control
// Since the link isn't truly private (anyone who gets it can install), Apple recommends building in your own gate — a login screen, invite code, or allow-list — so only your intended users can actually use the app even if the link leaks.
//
// Android testing tracks don't have anything like TestFlight's 90-day build expiration

import SwiftUI  // import SwiftUI

@main
struct FeelGoodDealsApp: App {  // struct FeelGoodDealsApp: App
    var body: some Scene {  // var body: some Scene
        WindowGroup {  // WindowGroup
            ContentView()  // ContentView()
        }  // WindowGroup
    }  // var body: some Scene
}  // struct FeelGoodDealsApp: App
