package com.mlx.codeReader

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import com.mlx.codeReader.utils.AccountUtils
import mlx.codeReader.R

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        AccountUtils.username="mlxChange"
        AccountUtils.password="7biezhideai"
        AccountUtils.Login().subscribe({
        },{})
    }
}
