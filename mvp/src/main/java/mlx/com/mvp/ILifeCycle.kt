package mlx.com.mvp

import android.content.res.Configuration
import android.os.Bundle

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/5.
 */

interface ILifeCycle{

    fun onCreate(savedInstanceState: Bundle?)

    fun onSaveInstanceState(outState: Bundle)

    fun onViewStateRestored(savedInstanceState: Bundle?)

    fun onConfigurationChanged(newConfig: Configuration)

    fun onDestroy()

    fun onStart()

    fun onStop()

    fun onResume()

    fun onPause()
}