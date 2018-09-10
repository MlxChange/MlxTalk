package com.mlx.codereader.api.services

import com.mlx.codereader.api.Service
import com.mlx.codereader.model.Account
import io.reactivex.Flowable
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.Path

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
interface AccountService{
    companion object {
        val INSTANCE=Service.getRetrofit().create(AccountService::class.java)
    }


    @GET("user")
    fun getAccount():Flowable<Account>

    @PATCH("user")
    fun updateAccount(@Body account: Account)

}