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
                    Image("BrandMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(.top, 4)

                    VStack(spacing: 8) {
                        Text("Bhakti Angan Pro")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.plum)
                        Text(loc.s(
                            "A deeper daily practice, with the complete sacred collection.",
                            "एक गहरा दैनिक अभ्यास, संपूर्ण पावन संग्रह के साथ।"
                        ))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.muted)
                    }

                    VStack(spacing: 14) {
                        feature("photo.stack.fill", loc.s("The complete darshan library", "संपूर्ण दर्शन संग्रह"))
                        feature("arrow.down.to.line", loc.s("Unlimited wallpaper saves", "असीमित वॉलपेपर सहेजें"))
                        feature("circle.grid.3x3.fill", loc.s("All deity mantras for japa", "जप के लिए सभी देवताओं के मंत्र"))
                        feature("bell.badge.fill", loc.s("Custom daily reminders", "अनुकूलित दैनिक स्मरण"))
                        feature("sparkles", loc.s("New festival collections", "नए पर्व संग्रह"))
                    }
                    .padding(18)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))

                    productOptions

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

    // MARK: - Product options

    private var productOptions: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                fallbackOption(
                    id: StoreManager.yearlyID,
                    title: loc.s("Annual", "वार्षिक"),
                    price: "$29.99/yr",
                    detail: loc.s("7-day free trial, then about $2.50/mo", "7-दिन का निःशुल्क परीक्षण, फिर लगभग $2.50/माह"),
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
                    detail: loc.s("One-time purchase, no subscription", "एकमुश्त खरीद, कोई सदस्यता नहीं"),
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
            if let perMonth = store.monthlyEquivalentText(for: product) {
                parts.append(loc.s("then \(perMonth)", "फिर \(perMonth)"))
            }
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
            return loc.s("One-time purchase, no subscription", "एकमुश्त खरीद, कोई सदस्यता नहीं")
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

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 26)
            Text(text)
                .font(.body.weight(.medium))
            Spacer()
        }
        .foregroundStyle(AppTheme.ink)
    }
}
