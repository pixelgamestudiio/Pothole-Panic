# The transitive Room runtime used by WorkManager predates R8 full-mode rules.
# Room instantiates generated databases by reflection during Android startup.
# Keeping only their class names drops the no-argument constructor and crashes
# InitializationProvider before Flutter starts. Preserve the constructors too.
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
