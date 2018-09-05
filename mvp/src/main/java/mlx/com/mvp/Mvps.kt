package mlx.com.mvp

import android.view.View

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/5.
 */

interface IPresenter<out View:IView<IPresenter<View>>>:ILifeCycle{
    val view:View
}

interface IView<out Presenter:IPresenter<IView<Presenter>>>:ILifeCycle{
    val presenter:Presenter
}