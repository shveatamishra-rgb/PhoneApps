package app.bhaktiangan.core.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Play Billing wrapper. Products must be created in Play Console with these IDs
 * before purchases work; until then queries return empty and the paywall shows
 * its fallback prices. Entitlement = owning any of the three products.
 */
class BillingManager(context: Context) : PurchasesUpdatedListener {

    companion object {
        const val MONTHLY = "pro_monthly"
        const val YEARLY = "pro_yearly"
        const val LIFETIME = "pro_lifetime"
        val ALL_IDS = listOf(MONTHLY, YEARLY, LIFETIME)
    }

    private val owned = mutableSetOf<String>()
    val hasPro = MutableStateFlow(false)

    private val _products = MutableStateFlow<Map<String, ProductDetails>>(emptyMap())
    val products: StateFlow<Map<String, ProductDetails>> = _products.asStateFlow()

    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .build()

    fun start() {
        if (client.isReady) return
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProducts()
                    queryOwned()
                }
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun queryProducts() {
        val list = ALL_IDS.map { id ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(id)
                .setProductType(if (id == LIFETIME) BillingClient.ProductType.INAPP else BillingClient.ProductType.SUBS)
                .build()
        }
        val params = QueryProductDetailsParams.newBuilder().setProductList(list).build()
        client.queryProductDetailsAsync(params) { result, details ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                _products.value = details.associateBy { it.productId }
            }
        }
    }

    private fun queryOwned() {
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()) { _, subs ->
            client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { _, inapp ->
                handlePurchases(subs + inapp)
            }
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            handlePurchases(purchases)
        }
    }

    private fun handlePurchases(purchases: List<Purchase>) {
        for (p in purchases) {
            if (p.purchaseState == Purchase.PurchaseState.PURCHASED) {
                owned.addAll(p.products)
                if (!p.isAcknowledged) {
                    client.acknowledgePurchase(
                        AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build(),
                    ) {}
                }
            }
        }
        hasPro.value = owned.isNotEmpty()
    }

    fun purchase(activity: Activity, productId: String) {
        val pd = _products.value[productId] ?: return
        val pParams = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(pd)
        if (productId != LIFETIME) {
            val offerToken = pd.subscriptionOfferDetails?.firstOrNull()?.offerToken ?: return
            pParams.setOfferToken(offerToken)
        }
        val flow = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(pParams.build())).build()
        client.launchBillingFlow(activity, flow)
    }

    /** Display price for a product, or null if not loaded yet. */
    fun formattedPrice(productId: String): String? {
        val pd = _products.value[productId] ?: return null
        return if (productId == LIFETIME) {
            pd.oneTimePurchaseOfferDetails?.formattedPrice
        } else {
            pd.subscriptionOfferDetails?.firstOrNull()
                ?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice
        }
    }

    fun refresh() {
        if (client.isReady) queryOwned() else start()
    }
}
