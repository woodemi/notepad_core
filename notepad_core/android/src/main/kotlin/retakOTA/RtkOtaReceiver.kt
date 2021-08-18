package com.realsil.ota

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

import com.realsil.sdk.dfu.model.DfuConfig


/**
 * Android 3.1+ 处于'Stopped' 状态(首次安装或者强制关闭)的应用接收不到广播
 *
 * @author bingshanguxue
 * @date 2018/4/4
 */

class RtkOtaReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        Log.d(TAG, "action = " + action)

        when (action) {
            ACTION_START_OTA -> {
                val dfuConfig =
                    intent.getParcelableExtra<DfuConfig>(RtkUpdateService.EXTRA_DFU_CONFIG)

                val service = Intent(context, RtkUpdateService::class.java)
                service.action = ACTION_START_OTA
                service.putExtra(RtkUpdateService.EXTRA_DFU_CONFIG, dfuConfig)
                ContextCompat.startForegroundService(context, service)
            }
            else -> {
            }
        }
    }

    companion object {

        private val TAG = "RtkOtaReceiver"

        val ACTION_START_OTA = "rtk_ACTION_START_OTA"
    }

}
