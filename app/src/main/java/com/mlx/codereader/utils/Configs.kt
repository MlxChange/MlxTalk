package com.mlx.codeReader.utils

import java.util.*

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/10.
 */
object Configs {

    object Account {

        val SCOPES = listOf("repo", "admin:org", "admin:public_key",
                "admin:repo_hook", "admin:org_hook", "user", "notifications",
                "delete_repo", "write:discussion")
        const val NOTE = "BestGithub"
        const val NOTE_URL ="https://github.com/MlxChange/BestGithub"
        const val CLIENT_ID="c25337868dc649accad3"
        const val CLIENT_SECRET="c930628b30062c47c7d8b40dc114a92663bc3dbd"
        val FINGERPRINT by lazy {
            UUID.randomUUID().toString()
        }
    }


}