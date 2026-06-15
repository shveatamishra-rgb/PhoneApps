# OkHttp / Okio are well-behaved under R8; keep their optional platform shims quiet.
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
