package app.bhaktiangan.core.review

import android.app.Activity
import com.google.android.play.core.review.ReviewManagerFactory

/**
 * Asks Play for an in-app review at a positive moment (a completed mala). Play itself
 * throttles how often the dialog actually appears, so we can call it freely.
 */
object ReviewLauncher {
    fun launch(activity: Activity) {
        val manager = ReviewManagerFactory.create(activity)
        manager.requestReviewFlow().addOnCompleteListener { task ->
            if (task.isSuccessful) {
                runCatching { manager.launchReviewFlow(activity, task.result) }
            }
        }
    }
}
