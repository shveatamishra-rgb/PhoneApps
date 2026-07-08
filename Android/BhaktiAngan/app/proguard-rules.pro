# ── kotlinx.serialization ────────────────────────────────────────────────
# The release build runs R8. The generated $$serializer classes and the
# serializer() accessors must survive shrinking, or decoding the bundled
# cities.json / content catalog throws at runtime.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**

# Keep the synthetic serializers generated for @Serializable classes.
-keep,includedescriptorclasses class app.bhaktiangan.**$$serializer { *; }
-keepclassmembers class app.bhaktiangan.** {
    *** Companion;
}
-keepclasseswithmembers class app.bhaktiangan.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# kotlinx.serialization core/json internals.
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Play Billing and Play Review ship their own consumer rules in their AARs.
