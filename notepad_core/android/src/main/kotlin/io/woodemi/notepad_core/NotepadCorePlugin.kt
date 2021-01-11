package io.woodemi.notepad_core

import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.*
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.*

const val TAG = "NotepadCorePlugin"

/** NotepadCorePlugin */
class NotepadCorePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, Closeable {
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        init(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            NotepadCorePlugin().init(registrar.context(), registrar.messenger())
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        close()
    }

    lateinit var context: Context

    private fun init(context: Context, messenger: BinaryMessenger) {
        this.context = context
        //  woodemi
        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        context.registerReceiver(bluetoothReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))

        MethodChannel(messenger, "notepad_core/method").setMethodCallHandler(this)
        EventChannel(messenger, "notepad_core/event.scanResult").setStreamHandler(this)
        connectorMessage = BasicMessageChannel(messenger, "notepad_core/message.connector", StandardMessageCodec.INSTANCE)
        clientMessage = BasicMessageChannel(messenger, "notepad_core/message.client", StandardMessageCodec.INSTANCE)
    }

    override fun close() {
        context.unregisterReceiver(bluetoothReceiver)
    }

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
            Log.d(TAG, "bluetoothReceiver onReceive $state")
            when (state) {
                BluetoothAdapter.STATE_OFF -> {
                    mainThreadHandler.post { connectorMessage.send(mapOf("BluetoothState" to "unavailable")) }
                }
                BluetoothAdapter.STATE_ON -> {
                    mainThreadHandler.post { connectorMessage.send(mapOf("BluetoothState" to "available")) }
                }
            }
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "$this onMethodCall " + call.method)
        when (call.method) {
            //  公共部分：Woodemi
            "isBluetoothAvailable" -> {
                result.success(bluetoothManager.adapter.isEnabled)
            }
            "startScan" -> {
                bluetoothManager.adapter.bluetoothLeScanner?.startScan(scanCallback)
                result.success(null)
            }
            "stopScan" -> {
                bluetoothManager.adapter.bluetoothLeScanner?.stopScan(scanCallback)
                result.success(null)
            }
            "connect" -> {
                connectGatt = bluetoothManager.adapter
                        .getRemoteDevice(call.argument<String>("deviceId"))
                        .connectGatt(context, false, gattCallback)
                result.success(null)
            }
            "disconnect" -> {
                connectGatt?.disconnect()
                connectGatt?.close()
                connectGatt = null
                result.success(null)
                connectorMessage.send(mapOf("ConnectionState" to "disconnected"))
            }

            //  以下为Woodemi专有
            "discoverServices" -> {
                connectGatt?.discoverServices()
                result.success(null)
            }
            "setNotifiable" -> {
                val service = call.argument<String>("service")!!
                val characteristic = call.argument<String>("characteristic")!!
                val bleInputProperty = call.argument<String>("bleInputProperty")!!
                connectGatt?.setNotifiable(service to characteristic, bleInputProperty)
                result.success(null)
            }
            "requestMtu" -> {
                connectGatt?.requestMtu(call.argument<Int>("expectedMtu")!!)
                result.success(null)
            }
            "requestConnectionPriority" -> {
                val bleConnectionPriority = call.argument<String>("bleConnectionPriority")!!
                connectGatt?.requestConnectionPriority(when (bleConnectionPriority) {
                    "high" -> BluetoothGatt.CONNECTION_PRIORITY_HIGH
                    "lowPower" -> BluetoothGatt.CONNECTION_PRIORITY_LOW_POWER
                    else -> BluetoothGatt.CONNECTION_PRIORITY_BALANCED
                })
                result.success(null)
            }
            "readValue" -> {
                val service = call.argument<String>("service")!!
                val characteristic = call.argument<String>("characteristic")!!
                connectGatt?.getCharacteristic(service to characteristic)?.let {
                    connectGatt?.readCharacteristic(it)
                }
                result.success(null)
            }
            "writeValue" -> {
                val service = call.argument<String>("service")!!
                val characteristic = call.argument<String>("characteristic")!!
                val value = call.argument<ByteArray>("value")!!
                val writeResult = connectGatt?.getCharacteristic(service to characteristic)?.let {
                    it.value = value
                    connectGatt?.writeCharacteristic(it)
                }
                if (writeResult == true)
                    result.success(null)
                else
                    result.error("Characteristic unavailable", null, null)
            }
            else -> result.notImplemented()
        }
    }

    var scanResultSink: EventChannel.EventSink? = null

    override fun onListen(args: Any?, eventSink: EventChannel.EventSink?) {
        val map = args as? Map<String, Any> ?: return
        when (map["name"]) {
            "scanResult" -> scanResultSink = eventSink
        }
    }

    override fun onCancel(args: Any?) {
        val map = args as? Map<String, Any> ?: return
        when (map["name"]) {
            "scanResult" -> scanResultSink = null
        }
    }

    var connectGatt: BluetoothGatt? = null

    val mainThreadHandler = Handler(Looper.getMainLooper())

    lateinit var connectorMessage: BasicMessageChannel<Any>

    lateinit var clientMessage: BasicMessageChannel<Any>
}