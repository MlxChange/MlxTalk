package mlx.codereader

import mlx.com.common.ext.PreferenceExt

/**
 * Project:codeReader
 * Created by malingxiang on 2018/8/28.
 */

object Settings{
    var username:String by PreferenceExt(AppContext,"username","")
    var password:String by PreferenceExt(AppContext,"password","")
}