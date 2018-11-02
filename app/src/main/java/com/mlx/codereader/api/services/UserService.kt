package com.mlx.codeReader.api.services

import com.mlx.codeReader.api.Service
import com.mlx.codeReader.model.User
import io.reactivex.Flowable
import retrofit2.http.GET
import retrofit2.http.Path

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
interface UserService{


    companion object {
        val INSTANCE=Service.getRetrofit().create(UserService::class.java)
    }

    @GET("users/{username}")
    fun getUserByName(@Path("username")username:String):Flowable<User>




}