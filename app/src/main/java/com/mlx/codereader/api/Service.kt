package com.mlx.codeReader.api

import android.content.Context
import com.google.gson.GsonBuilder
import mlx.com.common.ext.ensureDir
import okhttp3.Cache
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import retrofit2.converter.gson.GsonConverterFactory
import java.io.File

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/6.
 */


const val BASE_URL="https://api.github.com"

class Service(ctx: Context, baseUrl: String, debugMode: Boolean=false) {
    private val mRetrofit: Retrofit

    companion object {
        private var INSTANCE: Service? = null
            get() {
                if (field == null) throw KotlinNullPointerException("check init first")
                return field
            }


        fun init(ctx: Context, baseUrl: String, debugMode: Boolean=true) {
            INSTANCE = Service(ctx, baseUrl, debugMode)
        }


        fun getRetrofit(): Retrofit {
            return INSTANCE!!.mRetrofit
        }

    }

    init {
        val httpClient = OkHttpClient.Builder()
        httpClient.addInterceptor(ApiHeaderInterceptor())
        httpClient.addInterceptor(HttpLoggingInterceptor(HttpLog()).setLevel(HttpLoggingInterceptor.Level.BODY))
        httpClient.cache(Cache(File(ctx.cacheDir,"service").apply { ensureDir() },8*1024*1024))
        val gson = GsonBuilder()
                .setLenient()
                .create()
        mRetrofit = Retrofit.Builder()
                .client(httpClient.build())
                .addConverterFactory(GsonConverterFactory.create(gson))
                .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                .baseUrl(baseUrl)
                .build()
    }
}
