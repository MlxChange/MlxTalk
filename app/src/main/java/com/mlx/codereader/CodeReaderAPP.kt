package com.mlx.codeReader

import android.app.Application
import android.content.ContextWrapper
import com.mlx.codeReader.api.BASE_URL
import com.mlx.codeReader.api.Service

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

