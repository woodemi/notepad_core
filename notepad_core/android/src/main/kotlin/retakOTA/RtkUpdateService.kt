package com.realsil.ota

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Message
import android.util.Log
import com.realsil.sdk.dfu.DfuConstants
import com.realsil.sdk.dfu.model.DfuConfig
import com.realsil.sdk.dfu.model.DfuProgressInfo
import com.realsil.sdk.dfu.model.Throughput
import com.realsil.sdk.dfu.support.settings.SettingsHelper
import com.realsil.sdk.dfu.utils.BaseDfuAdapter
import com.realsil.sdk.dfu.utils.DfuAdapter
import com.realsil.sdk.dfu.utils.GattDfuAdapter

/**
 * <pre> adb shell am startservice -n com.realsil.ota/com.realsil.ota.RtkUpdateService</pre>
 *
 * @author bingshanguxue
 */
class RtkUpdateService : Service() {
    
    val TAG = "RtkUpdateService"
    private val stopSelfWhenOtaSuccess = true

    private var mDfuHelper: GattDfuAdapter? = null
    private var mDfuConfig: DfuConfig? = null
    private var mHandler: Handler? = null

    val dfuHelper: GattDfuAdapter?
        get() {
            if (mDfuHelper == null) {
                mDfuHelper = GattDfuAdapter.getInstance(this)
            }

            return mDfuHelper
        }

    protected val dfuConfig: DfuConfig
        get() {
            if (mDfuConfig == null) {
                mDfuConfig = DfuConfig()
            }
            return mDfuConfig as DfuConfig
        }

    private val mDfuHelperCallback = object : BaseDfuAdapter.DfuHelperCallback() {
        override fun onStateChanged(state: Int) {
            super.onStateChanged(state)
            Log.d(TAG, String.format(">> onStateChanged: 0x%04X", state))
            if (state == DfuAdapter.STATE_INIT_OK) {
                //                startOtaProcess();
                val ret = dfuHelper!!.connectDevice(dfuConfig.address)
                if (!ret) {
                    Log.d(TAG, "connectDevice failed")
                }
            } else if (state == DfuAdapter.STATE_PREPARED) {
                val modeInfo = dfuHelper!!.getPriorityWorkMode(DfuConstants.OTA_MODE_SILENT_FUNCTION)
                dfuConfig.otaWorkMode = modeInfo.workmode
                mHandler!!.sendEmptyMessage(MSG_START_OTA_PROCEDURE)
            }
        }

        override fun onError(type: Int, code: Int) {
            Log.d(TAG, "type=$type, code=$code")
            val intent = Intent(RTKOTA.ACTION_BACKGROUND_OTA_ERROR)
            intent.putExtra(RTKOTA.EXTRA_ERROR_TYPE, type)
            intent.putExtra(RTKOTA.EXTRA_ERROR_CODE, code)
            sendBroadcast(intent)

            if (stopSelfWhenOtaSuccess) {
                stopSelf()
            }
        }

        override fun onProcessStateChanged(state: Int, throughput: Throughput?) {
            super.onProcessStateChanged(state, throughput)
            Log.d(TAG, String.format("onProcessStateChanged: 0x%04X", state))
            val intent = Intent(RTKOTA.ACTION_BACKGROUND_OTA_PROGRESS_STATE_CHANGED)
            intent.putExtra(RTKOTA.EXTRA_PROGRESS_STATE, state)
            sendBroadcast(intent)

            if (state == DfuConstants.PROGRESS_IMAGE_ACTIVE_SUCCESS) {
                if (stopSelfWhenOtaSuccess) {
                    stopSelf()
                }
            }
        }

        override fun onProgressChanged(dfuProgressInfo: DfuProgressInfo?) {
            super.onProgressChanged(dfuProgressInfo)
            if (dfuProgressInfo != null) {
                Log.d(TAG, dfuProgressInfo.toString())
                val intent = Intent(RTKOTA.ACTION_BACKGROUND_OTA_PROGRESS_CHANGED)
                intent.putExtra(RTKOTA.EXTRA_PROGRESS, dfuProgressInfo)
                sendBroadcast(intent)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "RtkUpdateService onCreate ++")

        SettingsHelper.initialize(this)

        val thread = HandlerThread(TAG)
        thread.start()
        mHandler = object : Handler(thread.looper) {
            override fun handleMessage(msg: Message) {
                super.handleMessage(msg)
                when (msg.what) {
                    MSG_START_OTA_PROCEDURE -> {
                        val ret = startOtaProcess()
                        if (!ret) {
                            Log.d(TAG, "startOtaProcess failed")
                        }
                    }
                    else -> {
                    }
                }
            }
        }
        Log.d(TAG, TAG + "RtkUpdateService onCreate --")
    }

    override fun onStartCommand(intent: Intent?, i: Int, i1: Int): Int {
        //        super.onStartCommand(intent, i, i1);
        Log.d(TAG, "onStartCommand")

        if (intent != null) {
            mDfuConfig = intent.getParcelableExtra(EXTRA_DFU_CONFIG)
        }

        if (dfuHelper!!.state >= DfuAdapter.STATE_INIT_OK) {
            mDfuHelper!!.addDfuHelperCallback(mDfuHelperCallback)
            if (dfuHelper!!.isIdle) {
                val ret = startOtaProcess()
                if (!ret) {
                    Log.d(TAG, "startOtaProcess failed")
                }
            } else {
                Log.d(TAG, "current ota state is busy")
            }
        } else {
            Log.d(TAG, "init DfuHelper object")
            val ret = dfuHelper!!.initialize(mDfuHelperCallback)
            Log.d(TAG, "init DfuHelper object: $ret")
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "RtkUpdateService onDestroy")
        if (mDfuHelper != null) {
            mDfuHelper!!.abort()
            mDfuHelper!!.close()
        }
    }

    private fun startOtaProcess(): Boolean {
        dfuConfig.isBreakpointResumeEnabled = SettingsHelper.getInstance()!!.isDfuBreakpointResumeEnabled
        dfuConfig.isAutomaticActiveEnabled = SettingsHelper.getInstance()!!.isDfuAutomaticActiveEnabled
        dfuConfig.isBatteryCheckEnabled = SettingsHelper.getInstance()!!.isDfuBatteryCheckEnabled
        dfuConfig.lowBatteryThreshold = SettingsHelper.getInstance()!!.dfuLowBatteryThreshold
        dfuConfig.batteryLevelFormat = SettingsHelper.getInstance()!!.dfuBatteryLevelFormat
        dfuConfig.isVersionCheckEnabled = SettingsHelper.getInstance()!!.isDfuVersionCheckEnabled
        dfuConfig.isIcCheckEnabled = SettingsHelper.getInstance()!!.isDfuChipTypeCheckEnabled
        dfuConfig.isSectionSizeCheckEnabled = SettingsHelper.getInstance()!!.isDfuImageSectionSizeCheckEnabled
        dfuConfig.isThroughputEnabled = SettingsHelper.getInstance()!!.isDfuThroughputEnabled
        dfuConfig.isMtuUpdateEnabled = SettingsHelper.getInstance()!!.isDfuMtuUpdateEnabled
        dfuConfig.isConParamUpdateLatencyEnabled = SettingsHelper.getInstance()!!.isDfuConnectionParameterLatencyEnabled

        return dfuHelper!!.startOtaProcess(dfuConfig)
    }

    companion object {

        private val TAG = "RtkUpdateService"
        val EXTRA_DFU_CONFIG = "DFU_CONFIG"

        private val MSG_START_OTA_PROCEDURE = 0x01
    }

}
