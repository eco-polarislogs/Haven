# Sürüm (release) derlemesinde R8 kodu küçültür ve kullanılmıyor sandığı her şeyi siler.
# AGP 9'un "tam modu" yalnızca yansımayla (reflection) çağrılan kurucuları da siler;
# aşağıdakiler olmadan uygulama AÇILIŞTA çöker.

# WorkManager'ın veritabanı (reklam ve bildirim kütüphaneleri getirir).
# Room, *_Impl sınıfını Class.forName(...).newInstance() ile oluşturur:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker { public <init>(android.content.Context, androidx.work.WorkerParameters); }
-keep class * extends androidx.startup.Initializer { <init>(); }
