package com.example.attendance_app

import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "ble_advertise"
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "startBLE" -> {
                        val permId = call.argument<String>("permId")!!
                        startAdvertising(permId)
                        result.success(null)
                    }

                    "stopBLE" -> {
                        stopAdvertising()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /*
    ---------------------------------------
    START BLE ADVERTISING (LEGACY)
    ---------------------------------------
    */
    private fun startAdvertising(permId: String) {

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter

        if (!adapter.isEnabled) return

        advertiser = adapter.bluetoothLeAdvertiser

        val dataBytes = permId.toByteArray(Charsets.UTF_8)

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addManufacturerData(0x1234, dataBytes) // 🔥 KEY
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                println("✅ BLE Advertising Started")
            }

            override fun onStartFailure(errorCode: Int) {
                println("❌ BLE Failed: $errorCode")
            }
        }

        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    /*
    ---------------------------------------
    STOP BLE
    ---------------------------------------
    */
    private fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
    }
}