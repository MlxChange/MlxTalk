package com.mlx.codereader.api


import android.util.Base64
import com.mlx.codereader.utils.AccountUtils
import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException


class ApiHeaderInterceptor : Interceptor {



    @Throws(IOException::class)
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        return chain.proceed(originalRequest.newBuilder()
                .apply {
                    when{
                        originalRequest.url().pathSegments().contains("authorizations")->{
                            val nameAndpass=AccountUtils.username+":"+AccountUtils.password
                            val encode= Base64.encode(nameAndpass.toByteArray(),Base64.DEFAULT)
                            val author= "Basic "+String(encode).trim()
                            addHeader("Authorization",author)
                       }
                        AccountUtils.isLogin() -> {
                            val auth = "Token " + AccountUtils.token
                            addHeader("Authorization", auth)
                        }
                        else -> removeHeader("Authorization")
                    }
                    addHeader("Accept","application/vnd.github.v3+json, ${originalRequest.header("accept") ?: ""}")
                }
                .build())
    }


}
