package com.mlx.codeReader.model

import com.google.gson.annotations.SerializedName
import com.mlx.codeReader.annotation.NoArg


/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
@NoArg
data class AuthorizationRsp(
        @SerializedName("id")
        val id: Int?,
        @SerializedName("url")
        val url: String?,
        @SerializedName("scopes")
        val scopes: List<String?>?,
        @SerializedName("token")
        val token: String?,
        @SerializedName("token_last_eight")
        val tokenLastEight: String?,
        @SerializedName("hashed_token")
        val hashedToken: String?,
        @SerializedName("app")
        val app: App?,
        @SerializedName("note")
        val note: String?,
        @SerializedName("note_url")
        val noteUrl: String?,
        @SerializedName("updated_at")
        val updatedAt: String?,
        @SerializedName("created_at")
        val createdAt: String?,
        @SerializedName("fingerprint")
        val fingerprint: String?
) {

    data class App(
            @SerializedName("url")
            val url: String?,
            @SerializedName("name")
            val name: String?,
            @SerializedName("client_id")
            val clientId: String?
    )
}