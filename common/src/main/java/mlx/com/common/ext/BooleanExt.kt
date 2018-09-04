package mlx.com.common.ext

/**
 * Project:codeReader
 * Created by malingxiang on 2018/8/27.
 */

sealed class BooleanExt<out T>

class IsFalse : BooleanExt<Nothing>()
class WithData<T>(val data: T) : BooleanExt<T>()

inline fun <T> Boolean.isTrue(block: () -> T) =
        when {
            this -> {
                WithData(block())
            }
            else -> {
                IsFalse()
            }
        }

inline fun <T> Boolean.isFalse(block: () -> T)=
        when{
            this->IsFalse()
            else->WithData(block())
        }


inline fun <T> BooleanExt<T>.Other(block: () -> T): T =
        when (this) {
            is IsFalse -> block()
            is WithData -> this.data
        }

