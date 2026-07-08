package app.bhaktiangan.ui

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper

/** Walks the ContextWrapper chain to the host Activity (needed for billing/review flows). */
fun Context.findActivity(): Activity? {
    var c: Context = this
    while (c is ContextWrapper) {
        if (c is Activity) return c
        c = c.baseContext
    }
    return null
}
