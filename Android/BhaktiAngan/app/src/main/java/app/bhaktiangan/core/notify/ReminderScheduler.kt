package app.bhaktiangan.core.notify

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.bhaktiangan.MainActivity
import app.bhaktiangan.R
import java.util.Calendar

/**
 * Schedules a daily local notification reminding the devotee to take their darshan.
 * Uses an inexact daily repeating alarm (no SCHEDULE_EXACT_ALARM permission needed) —
 * a few minutes of drift is fine for a gentle reminder.
 */
object ReminderScheduler {
    const val CHANNEL_ID = "daily_darshan"
    private const val ALARM_REQUEST = 4201
    private const val NOTIFICATION_ID = 4202

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Daily darshan", NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = "Your daily darshan reminder" }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    fun schedule(context: Context, hour: Int, minute: Int) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        am.setInexactRepeating(
            AlarmManager.RTC_WAKEUP, nextTrigger(hour, minute),
            AlarmManager.INTERVAL_DAY, alarmIntent(context),
        )
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(alarmIntent(context))
    }

    private fun nextTrigger(hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val t = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour); set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        if (!t.after(now)) t.add(Calendar.DAY_OF_YEAR, 1)
        return t.timeInMillis
    }

    private fun alarmIntent(context: Context): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
        return PendingIntent.getBroadcast(
            context, ALARM_REQUEST, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Builds + posts the reminder notification (called from [ReminderReceiver]). */
    fun postNotification(context: Context) {
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Your daily darshan is ready 🙏")
            .setContentText("Take one quiet minute for mantra, prayer, and stillness.")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted (API 33+) — nothing to show.
        }
    }
}
