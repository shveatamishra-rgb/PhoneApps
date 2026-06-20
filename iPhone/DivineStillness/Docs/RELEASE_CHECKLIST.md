# Release Checklist

## Product

- [ ] Review all 60 images using `CONTENT_STANDARD.md`.
- [ ] Confirm Free access: daily darshan, first 12 images, and 3 japa mantras.
- [ ] Confirm Pro access: all 60 images, all mantras, and unlimited saves.
- [ ] Verify favorites, daily japa count, and darshan streak survive relaunch.
- [ ] Verify the streak increments across consecutive days and resets after a gap.
- [ ] Verify the mala-completion banner and success haptic fire at the goal.
- [ ] Verify the welcome paywall appears once after onboarding (and never for subscribers).
- [ ] Verify notification opt-in, time changes, and opt-out.
- [ ] Verify photo saving on a physical iPhone.
- [ ] Verify share sheet on a physical iPhone.

## StoreKit

- [ ] Create all three products with exact identifiers.
- [ ] Add the 7-day free introductory offer on the annual subscription.
- [ ] Attach products to the first app version.
- [ ] Test monthly, annual, lifetime, restore, cancellation, and expiration.
- [ ] Test the free trial: start, convert, and cancel-before-conversion.
- [ ] Confirm the paywall button reads "Start Free Trial" while the offer is live.
- [ ] Test Ask to Buy or pending purchase behavior.
- [ ] Verify localized prices in the US and India storefronts.
- [ ] Confirm Terms of Use and Privacy Policy links work on the paywall itself.

## App Store

- [ ] Replace placeholder contact text in the privacy policy.
- [ ] Publish privacy and support pages over HTTPS.
- [ ] Complete App Privacy answers.
- [ ] Complete age-rating questionnaire.
- [ ] Upload screenshots for current required device sizes.
- [ ] Add app description, subtitle, keywords, support URL, and marketing URL.
- [ ] Archive with Release configuration and validate in Xcode Organizer.
- [ ] Upload to TestFlight and complete internal testing.
- [ ] Add App Review notes explaining Free and Pro access.

## Final device matrix

- [ ] Small supported iPhone
- [ ] Current standard iPhone
- [ ] Current Pro Max iPhone
- [ ] Light mode
- [ ] Large Dynamic Type
- [ ] VoiceOver labels and navigation
- [ ] Offline launch
- [ ] Fresh install and upgrade install
