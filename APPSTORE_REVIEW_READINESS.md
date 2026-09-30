# App Store Review Readiness — QueerLoop+

Audit date: 2026-09-30 · Scope: `lib/`, `ios/`, `android/`, `env/`, `pubspec.yaml`

This is a pre-submission risk analysis, ranked by likelihood of causing an App Store rejection. Fix items in **🔴 Critical** before you submit — each one is either a near-certain rejection or a genuine security/legal problem independent of Apple's review. 🟠 High items are strong risk factors specifically *because* this app is a UGC / identity / messaging app. 🟡 Medium items are things to double-check or prepare in App Store Connect. 🟢 items are already in good shape — don't touch them, just confirm they still work in the build you submit.

---

## 🔴 Critical — fix before submitting

### 1. Backend traffic is plaintext HTTP, not HTTPS — this is the #1 issue

- [app_config.dart](lib/core/config/app_config.dart): `baseUrl` fallback is `http://3.208.100.236:3001`, `socketUrl` fallback is `http://3.208.100.236:3018`.
- [env/prod.json](env/prod.json) and [env/staging.json](env/staging.json) both explicitly set `BASE_URL` and `SOCKET_URL` to `http://...` — **this is not a fallback-only issue, your actual production config points at plain HTTP.**
- [ios/Runner/Info.plist](ios/Runner/Info.plist): `NSAppTransportSecurity → NSAllowsArbitraryLoads = true` — a blanket App Transport Security exception that disables Apple's HTTPS enforcement entirely.
- [android/app/src/main/AndroidManifest.xml:16](android/app/src/main/AndroidManifest.xml): `android:usesCleartextTraffic="true"` confirms the same thing on Android.

**Why this matters more than a typical ATS warning:** every login, auth token, private message, sexual-orientation/gender-identity label, and uploaded photo/video is transmitted unencrypted between the app and `3.208.100.236`. Anyone on the same Wi‑Fi/network path (coffee shop, hostile ISP, a country where being LGBTQ+ is criminalized) can intercept it. This isn't hypothetical for this app in particular — it's the exact user population most exposed by a MITM leak of identity data.

The Privacy Policy previously claimed *"Encryption in Transit: ... HTTPS / TLS 1.3"* — that line has since been removed from [privacy_policy_screen.dart](lib/features/profile/screens/privacy_policy_screen.dart) and [legal/PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md) so the policy no longer states something false. **That only fixes the misrepresentation, not the underlying exposure** — the traffic itself is still plaintext, still interceptable, and a blanket ATS exception is still a visible red flag to reviewers regardless of what the policy says. Treat this as unresolved until the backend is actually behind TLS.

**Fix:** put the backend behind TLS (an ALB/API Gateway with an ACM cert, or Cloudflare/nginx with Let's Encrypt in front of the EC2 box is enough), switch `BASE_URL`/`SOCKET_URL` to `https://`/`wss://`, then remove `NSAllowsArbitraryLoads` and `usesCleartextTraffic` entirely. This is backend infra work, not just a plist toggle — budget real time for it before submission.

### 2. No age restriction anywhere — this is now a confirmed product decision, not a gap

At your explicit direction, the app has **no stated age restriction and no age-verification mechanism anywhere**: registration ([register_screen.dart](lib/features/auth/screens/register_screen.dart)) collects only email/password (or Apple/Google sign-in) plus a generic ToS checkbox, and all "18+" language has been removed from both [terms_of_service_screen.dart](lib/features/profile/screens/terms_of_service_screen.dart) and [privacy_policy_screen.dart](lib/features/profile/screens/privacy_policy_screen.dart) (and their `legal/` markdown counterparts). This is a deliberate choice, confirmed after I flagged the tradeoff — recording the consequence here rather than re-litigating the decision:

- The app now collects sexual orientation / gender identity and offers direct messaging **with no age floor at all**. Apple's age rating questionnaire in App Store Connect will need to reflect this honestly (mature/suggestive themes questions apply regardless of what your own policy says), and the resulting rating may be higher, not lower, than if you'd kept an 18+ restriction — an app that's honest about collecting sensitive identity data from any age tends to get a *stricter* rating than one that restricts to adults.
- If regulators or Apple later determine the app is reasonably likely to be accessed by minors while collecting sensitive personal data (sexual orientation, precise identity labels) and offering unmoderated-at-signup messaging, that carries real legal exposure (COPPA in the US if under-13 users are foreseeable, plus general minor-safety obligations) independent of whether Apple's review catches it at submission time.
- The CSAM/minor-exploitation prohibition clause in the Terms of Service (§4, Prohibited Content) was deliberately left in place — that's a content rule, not a user-age rule, and removing it would have been a separate and much riskier change than the one you asked for.

No code action needed here beyond what's already done — just make sure whoever fills out the App Store Connect age rating questionnaire and the Privacy Nutrition Label knows there's no age gate, so those declarations are accurate.

### 3. ✅ Fixed — app-level Privacy Manifest (`PrivacyInfo.xcprivacy`)

Previously, `PrivacyInfo.xcprivacy` existed only inside `ios/Pods/*` (Firebase, GoogleSignIn, AppAuth, etc. ship their own) — there was no manifest for the `Runner` app target itself, which Apple's Spring 2024 enforcement requires for any app using "Required Reason APIs."

Added [ios/Runner/PrivacyInfo.xcprivacy](ios/Runner/PrivacyInfo.xcprivacy) and wired it into the `Runner` target's Resources build phase (verified via `plutil -lint` and a diff of `project.pbxproj`, so it will actually be bundled at archive time, not just sit on disk). It declares:

- **Required Reason APIs:** `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`, for `shared_preferences`) and `NSPrivacyAccessedAPICategoryFileTimestamp` (reason `C617.1`, for `flutter_cache_manager`'s disk-cache expiry checks).
- **`NSPrivacyTracking: false`** and empty tracking domains — accurate, since there's no ad/analytics SDK in [pubspec.yaml](pubspec.yaml).
- **`NSPrivacyCollectedDataTypes`**, populated to match what the Privacy Policy documents: Email Address, User ID, Photos/Videos, Other User Content (posts/DMs/comments), Sensitive Info (sexual orientation/gender identity labels), Search History, Device ID, and Crash Data (unlinked).

**Remaining action (not code — yours to keep in sync):** whoever fills out App Store Connect's Privacy Nutrition Label questionnaire must declare the *same* data types as this manifest. If that questionnaire ends up collecting something different, update `NSPrivacyCollectedDataTypes` in the `.xcprivacy` file to match — a mismatch between the two is itself a flaggable inconsistency.

---

## 🟠 High — real risk given this app's category

### 4. ✅ Mostly fixed — UGC safety (Guideline 1.2)

You have real, working infrastructure here, not just policy text —
- Reporting: [report_service.dart](lib/features/reports/services/report_service.dart), plus report flows for posts, comments, and conversations ([report_conversation_bottom_sheet.dart](lib/features/messages/widgets/report_conversation_bottom_sheet.dart), [report_comment_bottom_sheet.dart](lib/features/home/widgets/report_comment_bottom_sheet.dart)).
- An actual moderator queue/admin console ([lib/admin/moderator_view/reports_queue/](lib/admin/moderator_view/reports_queue/)) — this is exactly the kind of evidence Apple wants for "timely response to reports."
- Blocking/muting, and a stated 24-hour moderation commitment in the ToS.
- **Proactive image filtering (new):** per the backend team, uploads (posts, avatars, media in messages) now run through automatic nudity detection server-side — flagged content is blocked from going live and deleted, rather than only being removable after a report. This is not visible from the Flutter codebase (it's backend-only), so noted here as reported rather than independently verified.

**What's now closed:** the "filtering objectionable material before it's posted" requirement, for **image/nudity content specifically**. Combined with reporting, blocking, and contact info, this covers all four things Guideline 1.2 asks for on the media side.

**What's still open:** the same gap for **text** — captions, bios, comments, and DM content have no proactive keyword/hate-speech filter that we've confirmed. If a reviewer posts a slur or harassment in a caption or DM, it still goes live instantly with no proactive filter (reactive reporting is deep and works — reactive to detection before posting is the missing piece). A basic keyword/regex blocklist checked at submission time would close this the same way the image system just did for nudity.

### 5. Confirm the admin/moderator console isn't part of the submitted binary

The moderator dashboard lives behind a **separate entry point**, [lib/main_admin.dart](lib/main_admin.dart) (vs. the consumer app's [lib/main.dart](lib/main.dart)), and its routes aren't registered in the consumer app's router ([lib/app/router.dart](lib/app/router.dart)). That's the right structure — just make sure whoever runs the release build/archive uses the `main.dart` entry point and not `main_admin.dart`, since a hidden admin panel reachable inside the public consumer binary would itself be a rejection risk (undocumented/hidden functionality, Guideline 2.3.1/2.5.2).

### 6. Sign in with Apple — present, just confirm it's fully wired end-to-end

`sign_in_with_apple` is a dependency, `com.apple.developer.applesignin` is in [Runner.entitlements](ios/Runner/Runner.entitlements), and the Privacy Policy documents collecting Apple-provided identifiers. Since you also offer Google Sign-In, Apple **requires** Sign in with Apple to be offered too (Guideline 4.8) — you've done that. Just manually test the full Apple sign-in flow (including "Hide My Email" relay) on a real device before submitting; this is one of the most common last-minute rejection reasons for apps that have the dependency installed but a broken/incomplete flow.

### 7. ✅ Fixed — one unused iOS permission removed, Android confirmed clean

Audited every declared permission on both platforms against actual feature usage in the code (not just what's declared), including permissions plugins silently add via manifest merging:

- **Android:** clean, nothing extra. No `CAMERA` or `RECORD_AUDIO` permission exists — correctly so, since `image_picker`'s camera calls use Android's implicit camera intent (the system camera app owns that permission). Everything in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) traces to a real feature; the only plugin-added extras (`VIBRATE`, `WAKE_LOCK`) are legitimate (notifications, Firebase background delivery).
- **iOS:** [Info.plist](ios/Runner/Info.plist) declared `NSMicrophoneUsageDescription` ("...to record audio when capturing video reels"), but there's no `camera` package, no audio-recording package, and no `pickVideo(source: ImageSource.camera)` call anywhere — every camera call found (`chat_screen.dart`, `step2_add_photo_screen.dart`, `edit_profile_screen.dart`) is `pickImage`, photos only. All video (reels) is picked from the gallery ([create_post_provider.dart:903](lib/features/create_post/provider/create_post_provider.dart)), never touching the microphone. Removed the unused key and corrected `NSCameraUsageDescription`'s wording to stop claiming a video-capture capability that doesn't exist.

If native in-app video/audio recording gets built later (rather than picking existing videos from the gallery), `NSMicrophoneUsageDescription` and Android's `RECORD_AUDIO`/`CAMERA` would need to come back at that point.

---

## 🟡 Medium — App Store Connect / release-config items (not code defects, but will block or slow approval if missed)

- **Age rating questionnaire:** given identity/orientation data, messaging, and UGC, expect to select a 17+ rating. Under-declaring this to get a lower rating is a common and easily-caught rejection reason.
- **Demo/reviewer account:** the app requires real registration (email/password or Apple/Google) to reach most features; guest mode ([guest_profile_tab_screen.dart](lib/features/home/screens/guest_profile_tab_screen.dart)) covers public browsing only. Provide a working test account (or explicit guest-mode walkthrough notes) in the "Notes for Review" field in App Store Connect so the reviewer isn't stuck at a login wall.
- **Support URL / contact info:** you already have `hello@queerloopplus.com` surfaced in-app (Privacy Policy, ToS) — make sure this same address/URL is also entered as the Support URL in App Store Connect; Guideline 1.2 explicitly requires published contact info reachable outside the app too.
- **`aps-environment` entitlement is set to `development`** in [Runner.entitlements](ios/Runner/Runner.entitlements). Xcode normally swaps this to `production` automatically for an Archive build with automatic signing — but explicitly verify this in the archived build's entitlements before upload, since a mismatched push entitlement can cause silent push failures in production (not a rejection, but worth catching now rather than after launch).
- **CSAM reporting workflow:** the Privacy Policy states CSAM is "immediately reported to NCMEC." That's a backend/ops commitment, not something visible in this Flutter codebase — confirm the actual reporting pipeline exists server-side, since this is a specific, checkable claim.

---

## 🟢 Already solid — keep as-is, just re-test before submission

- **Account deletion** is implemented in-app (Settings → Delete account), satisfying Guideline 5.1.1(v) directly — many rejections happen simply because this is missing.
- **No in-app purchase / payment SDK** present in [pubspec.yaml](pubspec.yaml) — no Guideline 3.1.1 payment-flow risk currently. If a paid tier is added later, it must go through StoreKit, not an external payment link.
- **Camera / Photo Library usage strings** in [Info.plist](ios/Runner/Info.plist) are present and now accurately describe actual use (see #7) — this is exactly what Apple wants, don't genericize them.
- **Push notifications** are wired via `firebase_messaging` + `flutter_local_notifications` with the correct `UIBackgroundModes`.

---

## Suggested order of work

1. Fix the HTTPS/TLS issue (#1) — this is both the biggest security exposure and the biggest reviewer red flag if noticed. **Still open.**
2. ~~Resolve the age-gate inconsistency~~ — done; app is deliberately open to all ages (#2), reflect this honestly in App Store Connect's age rating and Privacy Nutrition Label.
3. ~~Add the app-level Privacy Manifest~~ — done (#3); just keep `NSPrivacyCollectedDataTypes` in sync with whatever gets declared in App Store Connect.
4. ~~Add proactive image/nudity filtering~~ — done for media (#4); text (captions/bios/comments/DMs) still has no proactive filter. **Partially open.**
5. ~~Audit permissions for anything unused~~ — done (#7); Android was already clean, one unused iOS permission removed.
6. Do a full manual pass of Sign in with Apple, report flows, and block/mute on a real device.
7. Fill in App Store Connect: age rating, support URL, reviewer notes with test credentials.

Given this is an individual developer account (not an organization), Apple tends to scrutinize completeness a little more closely on first submissions — closing out the 🔴 items above is worth the extra time before you hit submit.
