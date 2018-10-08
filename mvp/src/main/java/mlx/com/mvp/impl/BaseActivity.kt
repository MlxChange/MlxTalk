package mlx.com.mvp.impl

import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import mlx.com.mvp.IPresenter
import mlx.com.mvp.IView
import kotlin.coroutines.experimental.buildSequence
import kotlin.reflect.KClass
import kotlin.reflect.full.isSubclassOf
import kotlin.reflect.full.primaryConstructor
import kotlin.reflect.jvm.jvmErasure

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/5.
 */
abstract class BaseActivity<out P:BasePresenter<BaseActivity<P>>>:IView<P>,AppCompatActivity(){
    override val presenter: P

    init {
        presenter=initPresenter()
        presenter.view=this
    }

    private fun initPresenter(): P {
        buildSequence {
            var classType : KClass<*> = this@BaseActivity::class
            while (true){
                yield(classType.supertypes)
                classType=classType.supertypes.firstOrNull()?.jvmErasure ?:break
            }
        }.flatMap{ it ->
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

    override fun onViewStateRestored(savedInstanceState: Bundle?) {}

    override fun onStart() {
        super.onStart()
        presenter.onStart()
    }

    override fun onResume() {
        super.onResume()
        presenter.onResume()
    }

    override fun onPause() {
        super.onPause()
        presenter.onPause()
    }

    override fun onStop() {
        super.onStop()
        presenter.onStop()
    }

    override fun onDestroy() {
        presenter.onDestroy()
        super.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        presenter.onSaveInstanceState(outState)
    }

    override fun onRestoreInstanceState(savedInstanceState: Bundle?) {
        super.onRestoreInstanceState(savedInstanceState)
        onViewStateRestored(savedInstanceState)
        presenter.onViewStateRestored(savedInstanceState)
    }

}