package app.bhaktiangan

import android.app.Application
import app.bhaktiangan.core.notify.ReminderScheduler

/** Application entry point. */
class BhaktiAnganApp : Application() {
    override fun onCreate() {
        super.onCreate()
        ReminderScheduler.createChannel(this)
    }
}
