package app.bhaktiangan.core.notify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.bhaktiangan.core.data.PreferencesRepository
import kotlinx.coroutines.runBlocking

/** Reschedules the daily darshan reminder after a device reboot. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = runBlocking { PreferencesRepository(context).current() }
        if (prefs.reminderEnabled) {
            ReminderScheduler.schedule(context, prefs.reminderHour, prefs.reminderMinute)
        }
    }
}

/** Fires at the chosen time and posts the daily darshan notification. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderScheduler.postNotification(context)
    }
}
