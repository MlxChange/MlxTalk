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
        val name: String,
        val default: T,
        val preName: String = "default") : ReadWriteProperty<Any?, T> {

    private val preferences by lazy {
        context.getSharedPreferences(preName, Context.MODE_PRIVATE)
    }

    override fun getValue(thisRef: Any?, property: KProperty<*>): T {
        return when (default) {
            is Boolean -> {
                preferences.getBoolean(name, default)
            }
            is Long -> {
                preferences.getLong(name, default)
            }
            is String -> {
                preferences.getString(name, default)
            }
            is Int -> {
                preferences.getInt(name, default)
            }
            else -> {
                throw IllegalAccessException("is not ")
            }
        } as T
    }

    override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
        preferences.edit().also {
            when (value) {
                is Boolean -> {
                    it.putBoolean(name, value)
                }
                is Long -> {
                    it.putLong(name, value)
                }
                is String -> {
                    it.putString(name, value)
                }
                is Int -> {
                    it.putInt(name, value)
                }
                else -> {
                    throw IllegalAccessException("is not ")
                }
            }
        }.apply()

    }

}