package com.mlx.codeReader.api.services

import com.mlx.codeReader.api.Service
import io.reactivex.Flowable
import com.mlx.codeReader.model.request.AuthorizationReq
import com.mlx.codeReader.model.AuthorizationRsp
import com.mlx.codeReader.utils.Configs
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.PUT
import retrofit2.http.Path

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
interface AuthService {

    companion object {
        val INSTANCE=Service.getRetrofit().create(AuthService::class.java)!!
    }

    @PUT("authorizations/clients/${Configs.Account.CLIENT_ID}/{fingerprint}")
    fun createAuthorization(@Body request: AuthorizationReq, @Path("fingerprint")fingerprint:String= Configs.Account.FINGERPRINT)
            :Flowable<AuthorizationRsp>

    @DELETE("authorizations/{authorization_id}")
    fun deleteAuthorization(@Path("authorization_id")id:Int):Flowable<Response<Any>>

}