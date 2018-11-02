package com.mlx.codeReader.utils

import android.util.Log
import com.google.gson.Gson
import com.mlx.codeReader.api.services.AccountService
import com.mlx.codeReader.api.services.AuthService
import com.mlx.codeReader.model.Account
import com.mlx.codeReader.model.request.AuthorizationReq
import io.reactivex.Flowable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import retrofit2.HttpException

/**
 * Project:codeReader
 * Created by malingxiang on 2018/9/12.
 */
object AccountUtils {

    var id: Int by pref(-1)
    var username: String by pref("")
    var password: String by pref("")
    var token: String by pref("")
    var userJson: String by pref("")
    var currentUser: Account? = null
        get() {
            if(field==null&& userJson.isNotEmpty()){
                return Gson().fromJson(userJson,Account::class.java)
            }
            return field
        }
        set(value) {
            userJson = if(value!=null){
                Gson().toJson(value)
            }else{
                ""
            }
            field=value

        }
    val onAccountStateChangeListeners= mutableListOf<OnAccountStateChangeListener>()

    private fun notifyLogin(account: Account){
        onAccountStateChangeListeners.forEach { it.onLogin(account) }
    }

    private fun notifyLogout(){
        onAccountStateChangeListeners.forEach { it.onLogout()}

    }

    fun Login() =
        AuthService.INSTANCE.createAuthorization(AuthorizationReq())
                .subscribeOn(Schedulers.io())
                .doOnNext {
                    it?.let {
                        Log.i("mlx",it.token)
                        if (it.token == null)
                            it.id?.let { throw AccountException(it) }
                    }
                }
                .retryWhen {
                    it.flatMap {
                        if (it is AccountException) {
                            AuthService.INSTANCE.deleteAuthorization(it.accountId)
                        } else {
                            Flowable.error(it)
                        }
                    }
                }
                .flatMap {
                    it.token?.let { token = it }
                    it.id?.let { id = it }
                    AccountService.INSTANCE.getAccount()
                            .observeOn(AndroidSchedulers.mainThread())
                }
                .map {
                    currentUser=it
                    notifyLogin(it)

                }





    fun Logout(){
        AuthService.INSTANCE.deleteAuthorization(id)
                .observeOn(AndroidSchedulers.mainThread())
                .subscribeOn(Schedulers.io())
                .doOnNext {
                    if (it.isSuccessful){
                        token=""
                        id=-1
                        currentUser=null
                        notifyLogout()
                    }else
                        throw HttpException(it)
                }
    }

    fun isLogin():Boolean{
        return token.isNotEmpty()
    }

}
class AccountException(val accountId: Int) : Exception("account already logged in")

interface OnAccountStateChangeListener{
    fun onLogin(account:Account)
    fun onLogout()
}