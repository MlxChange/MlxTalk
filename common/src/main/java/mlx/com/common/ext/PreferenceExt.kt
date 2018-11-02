package mlx.com.common.ext

import android.content.Context
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

/**
 * Project:codeReader
 * Created by malingxiang on 2018/8/28.
 */
class PreferenceExt<T>(
        var context: Context,
        val name: String="",
        private val default: T,
        private val preName: String = "default") : ReadWriteProperty<Any?, T> {

    private val preferences by lazy {
        context.getSharedPreferences(preName, Context.MODE_PRIVATE)
    }

    override fun getValue(thisRef: Any?, property: KProperty<*>): T {
        val preferencesName=selectName(property)
        return when (default) {
            is Boolean -> {
                preferences.getBoolean(preferencesName, default)
            }
            is Long -> {
                preferences.getLong(preferencesName, default)
            }
            is String -> {
                preferences.getString(preferencesName, default)
            }
            is Int -> {
                preferences.getInt(preferencesName, default)
            }
            else -> {
                throw IllegalAccessException("is not ")
            }
        } as T
    }


    private fun selectName(property: KProperty<*>)=name.isBlank().isTrue { property.name }.other { name }

    override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
        val preferencesName=selectName(property)
        preferences.edit().also {
            when (value) {
                is Boolean -> {
                    it.putBoolean(preferencesName, value)
                }
                is Long -> {
                    it.putLong(preferencesName, value)
                }
                is String -> {
                    it.putString(preferencesName, value)
                }
                is Int -> {
                    it.putInt(preferencesName, value)
                }
                else -> {
                    throw IllegalAccessException("is not ")
                }
            }
        }.apply()

    }

}