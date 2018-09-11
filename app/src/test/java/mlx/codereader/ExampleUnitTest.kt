package mlx.codereader


import android.content.Context
import com.google.gson.GsonBuilder
import com.mlx.codereader.AppContext
import com.mlx.codereader.CodeReaderAPP
import com.mlx.codereader.api.HttpLog
import com.mlx.codereader.api.Service
import com.mlx.codereader.api.services.AccountService
import com.mlx.codereader.api.services.AuthService
import com.mlx.codereader.model.request.AuthorizationReq
import mlx.com.common.ext.ensureDir
import okhttp3.Cache
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.junit.Test

import org.junit.Assert.*
import retrofit2.Retrofit
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import retrofit2.converter.gson.GsonConverterFactory
import java.io.File

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
class ExampleUnitTest {
    @Test
    fun addition_isCorrect() {
        val encode=Base64.encode("test:test".toByteArray(),Base64.DEFAULT)
        val string="Basic "+String(encode).trim()
        val string2="Basic ${encode.toString()}"
        println(string)
        println(string2)
    }

    fun http(){
        val httpClient = OkHttpClient.Builder()
        httpClient.addInterceptor(HttpLoggingInterceptor(HttpLog()).setLevel(HttpLoggingInterceptor.Level.BODY))
        val gson = GsonBuilder()
                .setLenient()
                .create()
        val mRetrofit = Retrofit.Builder()
                .client(httpClient.build())
                .addConverterFactory(GsonConverterFactory.create(gson))
                .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                .baseUrl("https://api.github.com")
                .build()
        mRetrofit.create(AuthService::class.java)
                .createAuthorization(AuthorizationReq())
                .doOnNext {
                    it?.let {
                        println(it)
                    }
                }
    }
}
