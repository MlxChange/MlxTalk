package com.mlx.codereader

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import com.mlx.codereader.api.services.AuthService
import com.mlx.codereader.model.request.AuthorizationReq
import io.reactivex.Scheduler
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import mlx.codereader.R

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        AuthService.INSTANCE.createAuthorization(AuthorizationReq())
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .doOnNext {
                    it?.let {
                        Log.i("mlx",it.toString())
                    }
                }
                .subscribe()
    }
}
