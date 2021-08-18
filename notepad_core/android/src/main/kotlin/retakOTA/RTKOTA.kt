/*
 * Copyright (C) 2019 Realsil Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.realsil.ota
import android.content.*
import android.os.Build
import android.util.Log
import com.realsil.sdk.dfu.DfuException
import com.realsil.sdk.dfu.model.DfuConfig
import com.realsil.sdk.dfu.model.DfuProgressInfo
import com.realsil.sdk.dfu.support.DfuHelperImpl
import com.realsil.sdk.dfu.support.settings.SettingsHelper
import com.realsil.sdk.dfu.utils.DfuUtils

import io.woodemi.notepad_core.clientMessage
import io.woodemi.notepad_core.mainThreadHandler

enum class RTK_OTA_Method_Name {
    startUpgradeA2,
    stateChangeA2,
    upgradeFailA2,
    upgradeProgressA2
}
/**
 * @author bingshanguxue
 */
class RTKOTA {
    private val TAG = "RTKOTA"

    private lateinit var mContext: Context;

    private var mInnerBroadcastReceiver: InnerBroadcastReceiver? = null

    fun init(ctx: Context) {
        mContext = ctx

        Log.d(TAG, "mContext")

        SettingsHelper.initialize(mContext)

        //Mandatory
//        RtkCore.init(mContext)
//        RtkDfu.initialize(mContext)

        val intentFilter = IntentFilter()
        intentFilter.addAction(ACTION_BACKGROUND_OTA_ERROR)
        intentFilter.addAction(ACTION_BACKGROUND_OTA_PROGRESS_CHANGED)
        intentFilter.addAction(ACTION_BACKGROUND_OTA_PROGRESS_STATE_CHANGED)
        mInnerBroadcastReceiver = InnerBroadcastReceiver()
        mContext.registerReceiver(mInnerBroadcastReceiver, intentFilter)
    }

    fun startOtaProcess(mFilePath: String, mDeviceAddress: String) {
        Log.d(TAG, "开始升级")

        Log.d(TAG, "mFilePath = " + mFilePath)
        Log.d(TAG, "mDeviceAddress = " + mDeviceAddress)

        val dfuConfig = DfuConfig()

        dfuConfig.filePath = mFilePath
        dfuConfig.address = mDeviceAddress

        dfuConfig.isBreakpointResumeEnabled =
                SettingsHelper.getInstance()!!.isDfuBreakpointResumeEnabled
        dfuConfig.isAutomaticActiveEnabled =
                SettingsHelper.getInstance()!!.isDfuAutomaticActiveEnabled
        dfuConfig.isBatteryCheckEnabled = SettingsHelper.getInstance()!!.isDfuBatteryCheckEnabled
        dfuConfig.lowBatteryThreshold = SettingsHelper.getInstance()!!.dfuLowBatteryThreshold
        dfuConfig.batteryLevelFormat = SettingsHelper.getInstance()!!.dfuBatteryLevelFormat
        dfuConfig.isVersionCheckEnabled = SettingsHelper.getInstance()!!.isDfuVersionCheckEnabled
        dfuConfig.isIcCheckEnabled = SettingsHelper.getInstance()!!.isDfuChipTypeCheckEnabled
        dfuConfig.isSectionSizeCheckEnabled =
                SettingsHelper.getInstance()!!.isDfuImageSectionSizeCheckEnabled
        dfuConfig.isThroughputEnabled = SettingsHelper.getInstance()!!.isDfuThroughputEnabled
        dfuConfig.isMtuUpdateEnabled = SettingsHelper.getInstance()!!.isDfuMtuUpdateEnabled
        dfuConfig.isConParamUpdateLatencyEnabled =
                SettingsHelper.getInstance()!!.isDfuConnectionParameterLatencyEnabled

        val bufferCheckLevel = SettingsHelper.getInstance()!!.dfuBufferCheckLevel
        Log.d(TAG,"bufferCheckLevel = " + bufferCheckLevel)
        if (bufferCheckLevel > 0) {
            dfuConfig.bufferCheckLevel = bufferCheckLevel
        } else {
            //  电量过低
        }

        val speed = DfuUtils.getControlSpeed(SettingsHelper.getInstance()!!.dfuSpeedControlLevel)
        if (speed > 0) {
            dfuConfig.isSpeedControlEnabled = true
            dfuConfig.controlSpeed = speed
        } else {
            dfuConfig.isSpeedControlEnabled = false
            dfuConfig.controlSpeed = 0
        }

        val intent = Intent()
        intent.putExtra(RtkUpdateService.EXTRA_DFU_CONFIG, dfuConfig)
        //Android 8.0 之后无法发送和接收自定义广播
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.action = ACTION_START_OTA
            intent.component = ComponentName(
                    "com.realsil.ota",
                    "com.realsil.ota.RtkUpdateService"
            )
        } else {
            intent.action = ACTION_START_OTA
        }
        mContext.sendBroadcast(intent)
    }

    private inner class InnerBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action

            Log.d(TAG + "onReceive", "action = " + action)

            if (ACTION_BACKGROUND_OTA_PROGRESS_STATE_CHANGED == action) {
                val state = intent.getIntExtra(EXTRA_PROGRESS_STATE, 0)
//                val message = context.getString(DfuHelperImpl.getProgressStateResId(state))
//                DfuConstants
//                state=513 message=初始化 …
//                state=514 message=启动中 …
//                state=516 message=连接设备…
//                state=517 message=准备升级环境 …
//                state=521 message=正在升级…
//                state=524 message=固件激活中
//                state=258 message=固件激活成功
//                Log.d(TAG, String.format("0x%04X - %s", state, message))
                mainThreadHandler.post {
                    clientMessage.send(
                        mapOf(
                            "method" to RTK_OTA_Method_Name.stateChangeA2.name,
                            "value" to state.toString()
                        )
                    )
                }
            } else if (ACTION_BACKGROUND_OTA_ERROR == action) {
                val type = intent.getIntExtra(EXTRA_ERROR_TYPE, DfuException.Type.CONNECTION)
                val code = intent.getIntExtra(EXTRA_ERROR_CODE, DfuException.ERROR_NA)
                val message: String
                if (type == DfuException.Type.CONNECTION) {
                    message = String.format("初始化连接对端设备异常", DfuHelperImpl.parseConnectionErrorCode(context, code))
                } else {
                    message = String.format("升级失败", DfuHelperImpl.parseConnectionErrorCode(context, code))
                }
                mainThreadHandler.post {
                    clientMessage.send(
                        mapOf(
                            "method" to RTK_OTA_Method_Name.upgradeFailA2.name,
                            "value" to message
                        )
                    )
                }
            } else if (ACTION_BACKGROUND_OTA_PROGRESS_CHANGED == action) {
                val dfuProgressInfo = intent.getParcelableExtra<DfuProgressInfo>(EXTRA_PROGRESS)
                if (dfuProgressInfo != null) {
                    Log.d(TAG, "升级中：" + dfuProgressInfo.getProgress())
                    mainThreadHandler.post {
                        clientMessage.send(
                            mapOf(
                                "method" to RTK_OTA_Method_Name.upgradeProgressA2.name,
                                "value" to dfuProgressInfo.getProgress().toString()
                            )
                        )
                    }
                } else {
                    Log.d(TAG, "升级中 dfuProgressInfo = null")
                    mainThreadHandler.post {
                        clientMessage.send(
                            mapOf(
                                "method" to RTK_OTA_Method_Name.upgradeFailA2.name,
                                "value" to "升级中 dfuProgressInfo = null"
                            )
                        )
                    }
                }
            }
        }
    }

    companion object {
        val ACTION_START_OTA = "rtk_ACTION_START_OTA"
        val ACTION_BACKGROUND_OTA_PROGRESS_STATE_CHANGED = "ACTION_BACKGROUND_OTA_PROGRESS_STATE_CHANGED"
        val ACTION_BACKGROUND_OTA_ERROR = "ACTION_BACKGROUND_OTA_ERROR"
        val ACTION_BACKGROUND_OTA_PROGRESS_CHANGED = "ACTION_BACKGROUND_OTA_PROGRESS_CHANGED"

        val EXTRA_PROGRESS_STATE = "EXTRA_PROGRESS_STATE"
        val EXTRA_PROGRESS = "EXTRA_PROGRESS"
        val EXTRA_ERROR_TYPE = "EXTRA_ERROR_TYPE"
        val EXTRA_ERROR_CODE = "EXTRA_ERROR_CODE"
    }
}