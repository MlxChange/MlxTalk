package mlx.com.mvp.impl

import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import mlx.com.mvp.ILifeCycle
import mlx.com.mvp.IPresenter
import mlx.com.mvp.IView

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/5.
 */
abstract class BasePresenter<out V:IView<BasePresenter<V>>>:IPresenter<V>,ILifeCycle{

    override lateinit var  view: @UnsafeVariance V

    override fun onCreate(savedInstanceState: Bundle?) = Unit
    override fun onSaveInstanceState(outState: Bundle) = Unit
    override fun onViewStateRestored(savedInstanceState: Bundle?) = Unit
    override fun onConfigurationChanged(newConfig: Configuration) = Unit
    override fun onDestroy() = Unit
    override fun onStart() = Unit
    override fun onStop() = Unit
    override fun onResume() = Unit
    override fun onPause() = Unit
}