package mlx.codereader


import com.google.gson.GsonBuilder
import com.mlx.codeReader.api.HttpLog
import com.mlx.codeReader.api.services.AuthService
import com.mlx.codeReader.model.request.AuthorizationReq
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.junit.Test

import retrofit2.Retrofit
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import retrofit2.converter.gson.GsonConverterFactory

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
