package com.mlx.codereader.model.request

import com.mlx.codereader.annotation.NoArg
import com.mlx.codereader.utils.Configs

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
@NoArg
data class AuthorizationReq(
        var client_secret :String= Configs.Account.CLIENT_SECRET,
        var scopes :List<String> = Configs.Account.SCOPES,
        var note:String= Configs.Account.NOTE,
        var note_url:String= Configs.Account.NOTE_URL)