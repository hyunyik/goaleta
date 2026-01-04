# Gson이 제네릭 타입 정보를 유지하도록
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# Gson TypeToken 유지
-keep class com.google.gson.reflect.TypeToken { *; }

# flutter_local_notifications 내부 모델 보존 (보수적)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
