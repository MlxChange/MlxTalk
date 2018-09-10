package com.mlx.codereader

import android.app.Application
import android.content.ContextWrapper

/**
 * Project:codeReader
 * Created by malingxiang on 2018/8/28.
 */

private lateinit var INSTANCE:Application


class CodeReaderAPP:Application(){
    override fun onCreate() {
        super.onCreate()
        INSTANCE =this
    }

}

object AppContext:ContextWrapper(INSTANCE)

