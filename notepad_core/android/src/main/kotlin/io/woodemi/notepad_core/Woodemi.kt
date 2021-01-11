package io.woodemi.notepad_core

import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.util.Log
import com.bbb.bpen.command.BiBiCommand
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.*

val ScanResult.manufacturerData: ByteArray?
    get() {
        val sparseArray = scanRecord?.manufacturerSpecificData ?: return null
        if (sparseArray.size() == 0) return null

        return sparseArray.keyAt(0).toShort().toByteArray() + sparseArray.valueAt(0)
    }

fun Short.toByteArray(byteOrder: ByteOrder = ByteOrder.LITTLE_ENDIAN): ByteArray =
        ByteBuffer.allocate(2 /*Short.SIZE_BYTES*/).order(byteOrder).putShort(this).array()

fun BluetoothGatt.getCharacteristic(serviceCharacteristic: Pair<String, String>) =
        getService(UUID.fromString(serviceCharacteristic.first)).getCharacteristic(UUID.fromString(serviceCharacteristic.second))

val DESC__CLIENT_CHAR_CONFIGURATION = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

fun BluetoothGatt.setNotifiable(serviceCharacteristic: Pair<String, String>, bleInputProperty: String) {
    val descriptor = getCharacteristic(serviceCharacteristic).getDescriptor(DESC__CLIENT_CHAR_CONFIGURATION)
    val (value, enable) = when (bleInputProperty) {
        "notification" -> BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE to true
        "indication" -> BluetoothGattDescriptor.ENABLE_INDICATION_VALUE to true
        else -> BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE to false
    }
    descriptor.value = value
    setCharacteristicNotification(descriptor.characteristic, enable) && writeDescriptor(descriptor)
}

val NotepadCorePlugin.scanCallback: ScanCallback
    get() = object : ScanCallback() {
        override fun onScanFailed(errorCode: Int) {
            Log.v(TAG, "onScanFailed: $errorCode")
        }
    
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            Log.v(TAG, "onScanResult: $callbackType + $result")
            scanResultSink?.success(mapOf<String, Any>(
                    "name" to (result.device.name ?: ""),
                    "deviceId" to result.device.address,
                    "manufacturerData" to (result.manufacturerData ?: byteArrayOf()),
                    "rssi" to result.rssi
            ))
        }
    
        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            Log.v(TAG, "onBatchScanResults: $results")
        }
    }

val NotepadCorePlugin.gattCallback: BluetoothGattCallback
    get() = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onConnectionStateChange: status($status), newState($newState)")
            if (newState == BluetoothGatt.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                mainThreadHandler.post { connectorMessage.send(mapOf("ConnectionState" to "connected")) }
            } else {
                connectGatt?.close()
                connectGatt = null
                mainThreadHandler.post { connectorMessage.send(mapOf("ConnectionState" to "disconnected")) }
            }
        }
    
        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onServicesDiscovered $status")
            if (status != BluetoothGatt.GATT_SUCCESS) return
            gatt?.services?.forEach { service ->
                Log.v(TAG, "Service " + service.uuid)
                service.characteristics.forEach { characteristic ->
                    Log.v(TAG, "    Characteristic ${characteristic.uuid}")
                    characteristic.descriptors.forEach {
                        Log.v(TAG, "        Descriptor ${it.uuid}")
                    }
                }
            }
    
            mainThreadHandler.post {
                connectorMessage.send(mapOf(
                        "ServiceState" to "discovered",
                        "services" to gatt!!.services.map { it.uuid.toString() }
                ))
            }
        }
    
        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onMtuChanged $mtu, $status")
            if (status != BluetoothGatt.GATT_SUCCESS) return
            mainThreadHandler.post { clientMessage.send(mapOf("mtuConfig" to mtu)) }
        }
    
        override fun onDescriptorWrite(gatt: BluetoothGatt?, descriptor: BluetoothGattDescriptor, status: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onDescriptorWrite ${descriptor.uuid}, ${descriptor.characteristic.uuid}, $status")
            mainThreadHandler.post { clientMessage.send(mapOf("characteristicConfig" to descriptor.characteristic.uuid.toString())) }
        }
    
        override fun onCharacteristicRead(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic, status: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onCharacteristicRead ${characteristic.uuid}, ${characteristic.value.contentToString()} $status")
            val characteristicValue = mapOf(
                    "characteristic" to characteristic.uuid.toString(),
                    "value" to characteristic.value
            )
            mainThreadHandler.post { clientMessage.send(mapOf("characteristicValue" to characteristicValue)) }
        }
    
        override fun onCharacteristicWrite(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic, status: Int) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onCharacteristicWrite ${characteristic.uuid}, ${characteristic.value.contentToString()} $status")
        }
    
        override fun onCharacteristicChanged(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic) {
            if (gatt != connectGatt) {
                Log.e(TAG, "Probably MEMORY LEAK!")
                return
            }
            Log.v(TAG, "onCharacteristicChanged ${characteristic.uuid}, ${characteristic.value.contentToString()}")
            val characteristicValue = mapOf(
                    "characteristic" to characteristic.uuid.toString(),
                    "value" to characteristic.value
            )
            mainThreadHandler.post { clientMessage.send(mapOf("characteristicValue" to characteristicValue)) }
        }
    }
