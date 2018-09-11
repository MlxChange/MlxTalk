package com.mlx.codereader.api


import android.util.Base64
import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException


class ApiHeaderInterceptor : Interceptor {



    @Throws(IOException::class)
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val encode= Base64.encode("".toByteArray(),Base64.DEFAULT)
        val author= "Basic "+String(encode).trim()
        val request = originalRequest.newBuilder()
                .addHeader("Authorization",author)
                .build()
        return chain.proceed(request)
    }


}
