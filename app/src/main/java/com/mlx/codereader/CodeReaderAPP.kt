package com.mlx.codereader

import android.app.Application
import android.content.ContextWrapper
import com.mlx.codereader.api.BASE_URL
import com.mlx.codereader.api.Service

/**
 * Project:codeReader
 * Created by malingxiang on 2018/8/28.
 */

private lateinit var INSTANCE:Application


class CodeReaderAPP:Application(){
    override fun onCreate() {
        super.onCreate()
        INSTANCE =this
        Service.init(this, BASE_URL)
    }

}

object AppContext:ContextWrapper(INSTANCE)

