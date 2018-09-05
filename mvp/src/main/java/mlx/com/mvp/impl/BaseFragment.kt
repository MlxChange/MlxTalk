package mlx.com.mvp.impl

import android.app.Fragment
import android.content.res.Configuration
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import mlx.com.mvp.IPresenter
import mlx.com.mvp.IView
import kotlin.coroutines.experimental.buildSequence
import kotlin.reflect.KClass
import kotlin.reflect.full.isSubclassOf
import kotlin.reflect.full.primaryConstructor
import kotlin.reflect.full.superclasses
import kotlin.reflect.jvm.jvmErasure

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/5.
 */
abstract class BaseFragment<out P:BasePresenter<BaseFragment<P>>>:IView<P>,Fragment(){

    final override val presenter: P

    init {
        presenter=initPresenter()
        presenter.view=this
    }

    private fun initPresenter(): P {
        buildSequence {
            var classType : KClass<*> = this@BaseFragment::class
            while (true){
                yield(classType.supertypes)
                classType=classType.supertypes.firstOrNull()?.jvmErasure ?:break
            }
        }.flatMap{
            it.flatMap{it.arguments}.asSequence()
        }.first{
            it.type?.jvmErasure?.isSubclassOf(IPresenter::class) ?: false
        }.let{
            return it.type!!.jvmErasure.primaryConstructor!!.call() as P
        }
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        presenter.onCreate(savedInstanceState)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        presenter.onSaveInstanceState(outState)
    }

    override fun onViewStateRestored(savedInstanceState: Bundle?) {
        super.onViewStateRestored(savedInstanceState)
        presenter.onViewStateRestored(savedInstanceState)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        presenter.onConfigurationChanged(newConfig)
    }

    override fun onDestroy() {
        super.onDestroy()
        presenter.onDestroy()
    }

    override fun onStart() {
        super.onStart()
        presenter.onStart()
    }

    override fun onStop() {
        super.onStop()
        presenter.onStop()
    }

    override fun onResume() {
        super.onResume()
        presenter.onResume()
    }

    override fun onPause() {
        super.onPause()
        presenter.onPause()
    }
}