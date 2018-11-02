package com.mlx.codeReader.utils

import com.mlx.codeReader.AppContext
import mlx.com.common.ext.PreferenceExt

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/12.
 */
inline fun <reified R,T> R.pref(default:T)=PreferenceExt(AppContext,"",default)