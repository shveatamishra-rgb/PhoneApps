package app.bhaktiangan.core.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Provides a city-level device location for the Panchang sunrise calc. The fix is
 * used only on-device — never geocoded, transmitted, or stored — preserving the
 * "Data Not Collected" posture. Callers must hold a coarse-location permission.
 */
class LocationController(context: Context) {
    private val fused = LocationServices.getFusedLocationProviderClient(context)

    /** A fresh fix if available, otherwise the last known location, else null. */
    @SuppressLint("MissingPermission")
    suspend fun current(): Location? = awaitFresh() ?: awaitLast()

    @SuppressLint("MissingPermission")
    private suspend fun awaitFresh(): Location? = suspendCancellableCoroutine { cont ->
        val cts = CancellationTokenSource()
        fused.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, cts.token)
            .addOnSuccessListener { cont.resume(it) }
            .addOnFailureListener { cont.resume(null) }
        cont.invokeOnCancellation { cts.cancel() }
    }

    @SuppressLint("MissingPermission")
    private suspend fun awaitLast(): Location? = suspendCancellableCoroutine { cont ->
        fused.lastLocation
            .addOnSuccessListener { cont.resume(it) }
            .addOnFailureListener { cont.resume(null) }
    }
}
