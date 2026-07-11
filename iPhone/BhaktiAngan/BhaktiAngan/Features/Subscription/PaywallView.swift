import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var selectedProductID = StoreManager.yearlyID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    heroCollage
                        .padding(.top, 6)

                    VStack(spacing: 8) {
                        Text("Bhakti Angan Pro")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.plum)
                        Text(loc.s(
                            "The complete collection of the gods, growing with every festival.",
                            "देवताओं का संपूर्ण संग्रह, हर पर्व के साथ बढ़ता हुआ।"
                        ))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.muted)
                    }

                    VStack(spacing: 15) {
                        feature("photo.stack.fill",
                                loc.s("The complete darshan collection", "संपूर्ण दर्शन संग्रह"),
                                loc.s("60+ collectible scenes: Kaliya Mardan, Govardhan, Nataraja, Vishwaroop and more",
                                      "60+ संग्रहणीय दृश्य: कालिय मर्दन, गोवर्धन, नटराज, विश्वरूप और भी बहुत कुछ"))
                        feature("sparkles",
                                loc.s("New art arrives by itself", "नई कला स्वयं आती है"),
                                loc.s("Festival collections and fresh darshans land in your app, no update needed",
                                      "पर्व संग्रह और नए दर्शन सीधे आपके ऐप में, बिना किसी अपडेट के"))
                        feature("book.closed.fill",
                                loc.s("Every katha, shlok and mantra", "हर कथा, श्लोक और मंत्र"),
                                loc.s("All stories, the full Bhagavad Gita shlok library and all japa mantras, unlocked",
                                      "सभी कथाएँ, संपूर्ण भगवद्गीता श्लोक संग्रह और सभी जप मंत्र, अनलॉक"))
                        feature("square.grid.2x2.fill",
                                loc.s("Widgets with the full collection", "विजेट में पूरा संग्रह"),
                                loc.s("Your Home Screen darshan rotates through everything you own",
                                      "आपकी होम स्क्रीन का दर्शन आपके पूरे संग्रह में घूमता है"))
                        feature("mic.fill",
                                loc.s("Voice Japa, hands-free", "वाणी जप, बिना छुए"),
                                loc.s("Chant aloud and the mala counts itself, eyes closed, on your device only",
                                      "बोलकर जप करें और माला स्वयं गिनती है, आँखें बंद, सब कुछ आपके फोन पर"))
                        feature("infinity",
                                loc.s("All future Pro features, included", "आने वाले सभी प्रो फ़ीचर शामिल"),
                                loc.s("Whatever we build next is yours, at no extra cost",
                                      "हम आगे जो भी बनाएँ, वह बिना किसी अतिरिक्त शुल्क के आपका है"))
                    }
                    .padding(18)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))

                    productOptions

                    trialTerms

                    purchaseButton

                    Button(loc.s("Restore Purchases", "खरीद पुनर्स्थापित करें")) {
                        Task { await store.restore() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.vermilion)

                    disclosure

                    legalLinks
                }
                .padding(20)
            }
            .devotionalBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.s("Close", "बंद करें")) { dismiss() }
                }
            }
            .alert(
                "App Store",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button(loc.s("OK", "ठीक है"), role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    // MARK: - Purchase

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    private var ctaTitle: String {
        if let product = selectedProduct, store.hasFreeTrial(product) {
            return loc.s("Start Free Trial", "निःशुल्क परीक्षण शुरू करें")
        }
        if store.products.isEmpty, selectedProductID == StoreManager.yearlyID {
            return loc.s("Start Free Trial", "निःशुल्क परीक्षण शुरू करें")
        }
        if selectedProductID == StoreManager.lifetimeID {
            return loc.s("Unlock Lifetime", "लाइफटाइम अनलॉक करें")
        }
        return loc.s("Continue", "आगे बढ़ें")
    }

    private var purchaseButton: some View {
        Button {
            Task {
                guard let product = store.products.first(where: {
                    $0.id == selectedProductID
                }) else {
                    store.errorMessage = loc.s(
                        "Products are not available yet. Please try again in a moment.",
                        "उत्पाद अभी उपलब्ध नहीं हैं। कृपया थोड़ी देर में पुनः प्रयास करें।"
                    )
                    return
                }
                if await store.purchase(product) {
                    dismiss()
                }
            }
        } label: {
            Group {
                if store.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaTitle)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(AppTheme.plum, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(store.isLoading)
    }

    /// Prominent, plain-language terms shown at the point of purchase for the selected plan:
    /// trial length (if any), the exact amount billed afterward, and that it auto-renews.
    /// Required by App Store Guideline 3.1.2(c).
    private var trialTerms: some View {
        Text(selectedTermsText)
            .font(.footnote.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
    }

    private var selectedTermsText: String {
        // Prefer the live product so the real storefront price/currency is shown.
        if let p = selectedProduct {
            switch p.id {
            case StoreManager.lifetimeID:
                return loc.s(
                    "One-time purchase of \(p.displayPrice). No subscription, no auto-renewal.",
                    "\(p.displayPrice) की एकमुश्त खरीद। कोई सदस्यता या स्वतः नवीनीकरण नहीं।"
                )
            case StoreManager.monthlyID:
                if let days = store.freeTrialDays(for: p) {
                    return loc.s(
                        "\(days) days free, then \(p.displayPrice) per month. Renews automatically until cancelled.",
                        "\(days) दिन निःशुल्क, फिर \(p.displayPrice) प्रति माह। रद्द करने तक स्वतः नवीनीकृत।"
                    )
                }
                return loc.s(
                    "\(p.displayPrice) per month. Renews automatically until cancelled.",
                    "\(p.displayPrice) प्रति माह। रद्द करने तक स्वतः नवीनीकृत।"
                )
            default: // annual
                if let days = store.freeTrialDays(for: p) {
                    return loc.s(
                        "\(days) days free, then \(p.displayPrice) per year. Renews automatically until cancelled.",
                        "\(days) दिन निःशुल्क, फिर \(p.displayPrice) प्रति वर्ष। रद्द करने तक स्वतः नवीनीकृत।"
                    )
                }
                return loc.s(
                    "\(p.displayPrice) per year. Renews automatically until cancelled.",
                    "\(p.displayPrice) प्रति वर्ष। रद्द करने तक स्वतः नवीनीकृत।"
                )
            }
        }
        // Fallback copy when StoreKit products haven't loaded (matches the fallback prices).
        switch selectedProductID {
        case StoreManager.lifetimeID:
            return loc.s(
                "One-time purchase of $39.99. No subscription, no auto-renewal.",
                "$39.99 की एकमुश्त खरीद। कोई सदस्यता या स्वतः नवीनीकरण नहीं।"
            )
        case StoreManager.monthlyID:
            return loc.s(
                "$4.99 per month. Renews automatically until cancelled.",
                "$4.99 प्रति माह। रद्द करने तक स्वतः नवीनीकृत।"
            )
        default:
            return loc.s(
                "7 days free, then $29.99 per year. Renews automatically until cancelled.",
                "7 दिन निःशुल्क, फिर $29.99 प्रति वर्ष। रद्द करने तक स्वतः नवीनीकृत।"
            )
        }
    }

    // MARK: - Product options

    private var productOptions: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                fallbackOption(
                    id: StoreManager.yearlyID,
                    title: loc.s("Annual", "वार्षिक"),
                    price: "$29.99/yr",
                    detail: loc.s("7-day free trial, then $29.99/yr", "7-दिन का निःशुल्क परीक्षण, फिर $29.99/वर्ष"),
                    badge: loc.s("BEST VALUE", "सर्वोत्तम")
                )
                fallbackOption(
                    id: StoreManager.monthlyID,
                    title: loc.s("Monthly", "मासिक"),
                    price: "$4.99/mo",
                    detail: loc.s("Cancel anytime", "कभी भी रद्द करें"),
                    badge: nil
                )
                fallbackOption(
                    id: StoreManager.lifetimeID,
                    title: loc.s("Lifetime", "लाइफटाइम"),
                    price: "$39.99",
                    detail: loc.s("One purchase. Everything, forever, including future features",
                                  "एक खरीद। सब कुछ, हमेशा के लिए, भविष्य के फ़ीचर सहित"),
                    badge: nil
                )
            } else {
                ForEach(store.products, id: \.id) { product in
                    productOption(product)
                }
            }
        }
    }

    private func productOption(_ product: Product) -> some View {
        Button {
            selectedProductID = product.id
        } label: {
            optionContent(
                id: product.id,
                title: title(for: product),
                price: price(for: product),
                detail: detail(for: product),
                badge: product.id == StoreManager.yearlyID ? loc.s("BEST VALUE", "सर्वोत्तम") : nil
            )
        }
        .buttonStyle(.plain)
    }

    private func title(for product: Product) -> String {
        switch product.id {
        case StoreManager.yearlyID: return loc.s("Annual", "वार्षिक")
        case StoreManager.monthlyID: return loc.s("Monthly", "मासिक")
        case StoreManager.lifetimeID: return loc.s("Lifetime", "लाइफटाइम")
        default: return product.displayName
        }
    }

    private func price(for product: Product) -> String {
        switch product.id {
        case StoreManager.yearlyID: return "\(product.displayPrice)/yr"
        case StoreManager.monthlyID: return "\(product.displayPrice)/mo"
        default: return product.displayPrice
        }
    }

    private func detail(for product: Product) -> String {
        if let days = store.freeTrialDays(for: product) {
            var parts = [loc.s("\(days)-day free trial", "\(days)-दिन का निःशुल्क परीक्षण")]
            parts.append(loc.s("then \(price(for: product))", "फिर \(price(for: product))"))
            if let percent = store.annualSavingsPercent {
                parts.append(loc.s("save \(percent)%", "\(percent)% की बचत"))
            }
            return parts.joined(separator: " · ")
        }
        switch product.id {
        case StoreManager.yearlyID:
            if let perMonth = store.monthlyEquivalentText(for: product) {
                return loc.s("Just \(perMonth)", "केवल \(perMonth)")
            }
            return loc.s("Best annual value", "सर्वोत्तम वार्षिक मूल्य")
        case StoreManager.lifetimeID:
            return loc.s("One purchase. Everything, forever, including future features",
                         "एक खरीद। सब कुछ, हमेशा के लिए, भविष्य के फ़ीचर सहित")
        default:
            return loc.s("Cancel anytime", "कभी भी रद्द करें")
        }
    }

    private func fallbackOption(
        id: String,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        Button {
            selectedProductID = id
        } label: {
            optionContent(id: id, title: title, price: price, detail: detail, badge: badge)
        }
        .buttonStyle(.plain)
    }

    private func optionContent(
        id: String,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedProductID == id
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? AppTheme.vermilion : AppTheme.muted)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title).font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.black))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.marigold, in: Capsule())
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text(price)
                .font(.headline)
        }
        .foregroundStyle(AppTheme.ink)
        .padding(15)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? AppTheme.vermilion : Color.black.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        }
    }

    // MARK: - Legal

    private var disclosure: some View {
        Text(loc.s(
            "Subscriptions are billed through your Apple account and renew automatically unless cancelled at least 24 hours before the end of the current period. A free trial, if offered, converts to a paid subscription at the listed price unless cancelled before it ends. Manage or cancel anytime in Settings. Lifetime is a one-time purchase.",
            "सदस्यता का शुल्क आपके Apple खाते से लिया जाता है और यह स्वतः नवीनीकृत होती है, जब तक कि वर्तमान अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न की जाए। निःशुल्क परीक्षण, यदि उपलब्ध हो, समाप्त होने से पहले रद्द न करने पर सूचीबद्ध मूल्य पर सशुल्क सदस्यता में बदल जाता है। आप सेटिंग्स में कभी भी प्रबंधित या रद्द कर सकते हैं। लाइफटाइम एकमुश्त खरीद है।"
        ))
        .font(.caption)
        .multilineTextAlignment(.center)
        .foregroundStyle(AppTheme.muted)
    }

    private var legalLinks: some View {
        HStack(spacing: 6) {
            NavigationLink {
                LegalTextView(title: loc.s("Terms of Use", "उपयोग की शर्तें"), content: LegalCopy.terms)
            } label: {
                Text(loc.s("Terms of Use", "उपयोग की शर्तें"))
            }
            Text("·").foregroundStyle(AppTheme.muted)
            NavigationLink {
                LegalTextView(title: loc.s("Privacy Policy", "गोपनीयता नीति"), content: LegalCopy.privacy)
            } label: {
                Text(loc.s("Privacy Policy", "गोपनीयता नीति"))
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.vermilion)
    }

    private func feature(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 26)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Hero

    /// A fanned triptych of the collectible art: the product itself, in the first
    /// second of the paywall. Prefers the new remote collection (cached by
    /// RemoteCatalog) and falls back to strong bundled darshans on a fresh install,
    /// so the hero is never empty.
    private var heroCollage: some View {
        ZStack {
            heroCard(remote: "r_shiva_nataraja", fallback: "day1_shiv",
                     width: 116, angle: -9, offsetX: -96, offsetY: 12)
            heroCard(remote: "r_vishnu_anantashayana", fallback: "day28_vishnu",
                     width: 116, angle: 9, offsetX: 96, offsetY: 12)
            heroCard(remote: "r_krishna_govardhan", fallback: "day23_krishna",
                     width: 150, angle: 0, offsetX: 0, offsetY: 0)
        }
        .frame(height: 240)
        .accessibilityHidden(true)
    }

    private func heroCard(
        remote: String, fallback: String,
        width: CGFloat, angle: Double, offsetX: CGFloat, offsetY: CGFloat
    ) -> some View {
        let ui = DarshanImageStore.uiImage(named: remote) ?? UIImage(named: fallback)
        return Group {
            if let ui {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [AppTheme.teal, AppTheme.plum],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppTheme.marigold.opacity(0.55), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 6)
        .rotationEffect(.degrees(angle))
        .offset(x: offsetX, y: offsetY)
    }
}
