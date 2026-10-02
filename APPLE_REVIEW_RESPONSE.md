# Reply to Apple — Guideline 2.1 Information Request

## Ready to paste (2,137 chars — fits both the Resolution Center reply and the Notes field, which cap around 4,000)

Fill in the `[EMAIL]` / `[PASSWORD]` placeholder in item 3 with real, working demo credentials before pasting anywhere.

```
1. Screen recording: will be provided separately (filmed on a physical device), showing: app launch, account registration (email/OTP/profile setup), browsing Discover/Home/Reels, creating a post, content reporting (Safety icon on a post), blocking a user, Direct Messages, and the full account deletion flow (Settings > Delete Account) through to completion. No paid content exists in the app.

2. Purpose & audience: QueerLoop+ is a social app for the LGBTQ+ community. It lets members share posts and video content, discover other members/communities with shared identities and interests, and message each other directly, with privacy controls (per-post audience visibility, DM permissions, private accounts) built around this community's specific safety needs. Target audience: LGBTQ+ individuals and allies seeking community and connection.

3. Setup & access: No special setup needed; account creation happens in-app (email/password, Sign in with Apple, or Google). Public content can also be browsed without an account via "Continue as Guest." Demo login: [EMAIL] / [PASSWORD]. Main features: Discover, Home feed, posting, Direct Messages, Profile (optional pronouns/identity labels), Settings. Reporting is available on any post/comment/conversation; blocking is available from any profile or post menu.

4. External services: Firebase Cloud Messaging (push notifications), Google Sign-In and Sign in with Apple (authentication), AWS S3 (media storage), Amazon CloudFront (CDN), our own backend API over HTTPS/TLS with Socket.IO for real-time messaging, and automated server-side image moderation (nudity detection) on all uploaded media. No AI, payment, analytics, or advertising services are used.

5. Regional differences: None. The app functions identically in all regions; no region-gated content or pricing (no in-app purchases). Available in English, with partial Spanish localization.

6. Regulated industry / protected content: Not applicable. QueerLoop+ is a general-purpose social app, not in a regulated industry (no financial, medical, or legal functionality), and uses no licensed or protected third-party material.
```

---

## Expanded version (background reference — the condensed one above is what to actually submit)

## 1. Screen recording

**I can't produce this for you — it has to be filmed on your physical device.** Here's exactly what to capture, in order, so it covers everything Apple asked for in one take:

1. Launch the app from the home screen (cold launch, not already running).
2. Register a **new** account on camera: email → password → the email OTP verification screen → complete profile setup (photo, interests).
3. Browse the main app: Discover tab, Home feed, open a post, open a Reel.
4. Create a post (photo or caption).
5. **Content reporting:** open any post → tap the Safety/report icon → show the report flow through to submission.
6. **Blocking:** open a user's profile → show the block action.
7. Open Direct Messages, send a message to demonstrate the messaging feature.
8. Go to Settings → **show the full account deletion flow**: the consequences screen, the reason dropdown, and the final confirmation dialog, through to actual deletion completing.
9. (No paid content/IAP exists in this app, so there's nothing to show for that part — skip it.)

**Important:** use a **disposable test account** for the deletion demo in step 8 (since it gets permanently deleted on camera), and provide **separate, working credentials** in the Notes field (see #3) that remain valid for the reviewer to actually log in with — don't hand Apple an account you just deleted in the video.

---

## 2. App's purpose and target audience

QueerLoop+ is a social app built specifically for the LGBTQ+ community. It gives members a dedicated space to share posts and video content, discover other members and communities with shared identities and interests, and message each other directly — without having to navigate a mainstream platform not built with their context in mind. The core problem it solves is the lack of a social platform where pronouns, identity labels, and community affiliation are first-class, optional profile features rather than an afterthought, combined with privacy controls (audience-per-post visibility, DM permission controls, private accounts) built around the specific safety needs of this community. The target audience is LGBTQ+ individuals and allies seeking community, connection, and content relevant to them.

---

## 3. Setup instructions, main features, and login credentials

- **Login credentials:** *(fill in a real, currently-working demo account here before submitting — email + password)*. This account should be fully registered, verified, and have a completed profile, so reviewers aren't dropped into onboarding.
- **No special setup required** — the app is available immediately after download; account creation happens entirely in-app (email/password, or Sign in with Apple / Google).
- **Guest access:** public content (Discover, posts) can also be viewed without an account via "Continue as Guest" on the welcome screen.
- **Main features to explore:** Discover tab (browse/search posts and communities), Home feed, posting (photo/video), Direct Messages, Profile (pronouns, identity labels, bio — all optional), Settings (privacy controls, notification preferences, account deletion).
- **Safety features:** reporting is available from any post (Safety icon), comment ("Report" option), or conversation (Chat Options → Report Conversation). Blocking is available from any user's profile or post options menu.

---

## 4. External services, tools, and platforms used

- **Firebase** (Google) — Cloud Messaging for push notifications.
- **Google Sign-In** and **Sign in with Apple** — third-party authentication options (in addition to native email/password).
- **AWS S3** — media (photo/video) storage.
- **Amazon CloudFront** — CDN for media delivery.
- **Our own backend API** (`api.queerloopplus.com`, HTTPS/TLS) — account, content, messaging, and moderation services, including a real-time connection (Socket.IO) for direct messaging.
- **Automated image moderation** — uploaded media (posts, avatars, message attachments) is automatically scanned server-side for nudity before being made visible to other users.
- No AI/generative services, no payment processor, no analytics or advertising SDKs are used.

---

## 5. Regional differences

The app functions consistently across all regions — there is no region-gated content, no region-specific feature set, and no regional pricing (the app has no in-app purchases). The interface is available in English, with partial Spanish localization.

---

## 6. Regulated industry / protected third-party material

Not applicable. QueerLoop+ is a general-purpose social networking app and does not operate in a regulated industry (no financial, medical, legal, or telehealth functionality). It does not contain, display, or rely on any licensed or protected third-party material — all media assets (images, animations, fonts) are either originally created for the app or used under open licenses (e.g., the Hanken Grotesk typeface, a freely-licensed Google Font).

---

## Before you submit this

- [ ] Fill in real, working demo credentials in section 3 (and in the Sign-In Information fields in App Store Connect).
- [ ] Record and upload the screen recording described in section 1.
- [ ] Double check the demo account used in the video is **not** the same one you hand to the reviewer as credentials.
