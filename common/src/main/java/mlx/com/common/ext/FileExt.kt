package mlx.com.common.ext

import android.util.Log
import java.io.File
import java.io.IOException

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/7.
 */
fun File.ensureDir():Boolean{
    try {
        isDirectory.isFalse {
            isFile.isTrue {
                delete()
            }
            return mkdirs()
        }
    }catch (e:IOException){

    }
    return false
}
