package com.mlx.codeReader.api

import android.util.Log
import okhttp3.logging.HttpLoggingInterceptor

/**
 * Created by malingxiang on 18/3/16.
 */
class HttpLog :HttpLoggingInterceptor.Logger {
    override fun log(message: String?) {
        Log.i("http",message)
    }
}