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
            //it.arguments返回的是类型参数
            it.flatMap{it.arguments}.asSequence()
        }.first{
            /*
            *KTypeProjection表示类型投影,例如，
            * 在类型Array <out Number>中，out Number是由类Number表示的类型的协变投影。
            * jvmErasur返回表示在JVM上将此类型擦除到的运行时类的KClass实例。
            */
            it.type?.jvmErasure?.isSubclassOf(IPresenter::class) ?: false
        }.let{
            //返回此类的主要构造函数，如果此类没有主构造函数，则返回null。
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