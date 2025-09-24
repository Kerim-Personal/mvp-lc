# Flutter embedding ve plugin sınıflarını koru
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.embedding.**

# Yansıma (reflection) kullanan kütüphaneler için önemli meta nitelikler
-keepattributes SourceFile,LineNumberTable,InnerClasses,EnclosingMethod,Signature,*Annotation*

# Not: Kütüphaneler kendi consumer proguard kurallarıyla gerekli sınıfları korur (Firebase, ML Kit vb.)