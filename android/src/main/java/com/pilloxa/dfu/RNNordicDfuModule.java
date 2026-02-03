package com.pilloxa.dfu;

import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import androidx.annotation.Nullable;
import android.util.Log;
import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;
import no.nordicsemi.android.dfu.*;
import java.io.File; // ← ДОБАВЬТЕ ЭТОТ ИМПОРТ


public class RNNordicDfuModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

    private final String dfuStateEvent = "DFUStateChanged";
    private final String progressEvent = "DFUProgress";
    private static final String name = "RNNordicDfu";
    public static final String LOG_TAG = name;
    private final ReactApplicationContext reactContext;
    private Promise mPromise = null;

    public RNNordicDfuModule(ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addLifecycleEventListener(this);
        this.reactContext = reactContext;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            DfuServiceInitiator.createDfuNotificationChannel(reactContext);
        }
        Log.d(LOG_TAG, "RNNordicDfuModule initialized");
    }

   @ReactMethod
public void startDFU(String address, String name, String filePath, Promise promise) {
    Log.d(LOG_TAG, "=== START DFU CALLED ===");
    Log.d(LOG_TAG, "Привет");
    Log.d(LOG_TAG, "Address: " + address);
    Log.d(LOG_TAG, "Name: " + name);
    Log.d(LOG_TAG, "FilePath: " + filePath);
    
    mPromise = promise;

    try {
        // Проверка файла
        File file = new File(filePath);
        if (!file.exists()) {
            Log.e(LOG_TAG, "File does not exist: " + filePath);
            promise.reject("FILE_NOT_FOUND", "DFU file not found");
            return;
        }

        Log.d(LOG_TAG, "Creating DfuServiceInitiator...");
        final DfuServiceInitiator starter = new DfuServiceInitiator(address)
                .setKeepBond(false)
                .setPacketsReceiptNotificationsEnabled(true)
                .setPacketsReceiptNotificationsValue(8)
                .setDisableNotification(false) // Убедитесь, что уведомления включены
                .setForeground(true); // Используйте foreground service

        if (name != null) {
            starter.setDeviceName(name);
        }

        Log.d(LOG_TAG, "Setting ZIP file...");
        starter.setZip(filePath);
        
        // Отключите экспериментальные функции
        starter.setUnsafeExperimentalButtonlessServiceInSecureDfuEnabled(true);

        Log.d(LOG_TAG, "Starting DFU service...");
        final DfuServiceController controller = starter.start(this.reactContext, DfuService.class);
        
        if (controller != null) {
            Log.d(LOG_TAG, "DFU service started successfully");
            // Не резолвим промис здесь - он резолвится когда DFU завершится
        } else {
            Log.e(LOG_TAG, "Failed to start DFU service - controller is null");
            promise.reject("START_FAILED", "Failed to start DFU service");
            mPromise = null;
        }

    } catch (Exception e) {
        Log.e(LOG_TAG, "ERROR in startDFU: " + e.getMessage(), e);
        promise.reject("DFU_START_ERROR", "Failed to start DFU: " + e.getMessage());
        mPromise = null;
    }
}

    @Override
    public String getName() {
        return name;
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        Log.d(LOG_TAG, "Sending event: " + eventName);
        getReactApplicationContext()
                .getJSModule(RCTNativeAppEventEmitter.class)
                .emit(eventName, params);
    }

    private void sendStateUpdate(String state, String deviceAddress) {
        WritableMap map = new WritableNativeMap();
        Log.d(LOG_TAG, "State changed: " + state + " for device: " + deviceAddress);
        map.putString("state", state);
        map.putString("deviceAddress", deviceAddress);
        sendEvent(dfuStateEvent, map);
    }

    @Override
    public void onHostResume() {
        Log.d(LOG_TAG, "onHostResume - registering progress listener");
        DfuServiceListenerHelper.registerProgressListener(this.reactContext, mDfuProgressListener);
    }

    @Override
    public void onHostPause() {
        Log.d(LOG_TAG, "onHostPause");
    }

    @Override
    public void onHostDestroy() {
        Log.d(LOG_TAG, "onHostDestroy - unregistering progress listener");
        DfuServiceListenerHelper.unregisterProgressListener(this.reactContext, mDfuProgressListener);
    }

    private final DfuProgressListener mDfuProgressListener = new DfuProgressListenerAdapter() {
        @Override
        public void onDeviceConnecting(final String deviceAddress) {
            Log.d(LOG_TAG, "onDeviceConnecting: " + deviceAddress);
            sendStateUpdate("CONNECTING", deviceAddress);
        }

        @Override
        public void onDfuProcessStarting(final String deviceAddress) {
            Log.d(LOG_TAG, "onDfuProcessStarting: " + deviceAddress);
            sendStateUpdate("DFU_PROCESS_STARTING", deviceAddress);
        }

        @Override
        public void onEnablingDfuMode(final String deviceAddress) {
            Log.d(LOG_TAG, "onEnablingDfuMode: " + deviceAddress);
            sendStateUpdate("ENABLING_DFU_MODE", deviceAddress);
        }

        @Override
        public void onFirmwareValidating(final String deviceAddress) {
            Log.d(LOG_TAG, "onFirmwareValidating: " + deviceAddress);
            sendStateUpdate("FIRMWARE_VALIDATING", deviceAddress);
        }

        @Override
        public void onDeviceDisconnecting(final String deviceAddress) {
            Log.d(LOG_TAG, "onDeviceDisconnecting: " + deviceAddress);
            sendStateUpdate("DEVICE_DISCONNECTING", deviceAddress);
        }

        @Override
        public void onDfuCompleted(final String deviceAddress) {
            Log.d(LOG_TAG, "onDfuCompleted: " + deviceAddress);
            if (mPromise != null) {
                WritableMap map = new WritableNativeMap();
                map.putString("deviceAddress", deviceAddress);
                mPromise.resolve(map);
                mPromise = null;
            }
            sendStateUpdate("DFU_COMPLETED", deviceAddress);

            new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    Log.d(LOG_TAG, "Clearing notification");
                    final NotificationManager manager = (NotificationManager) reactContext.getSystemService(Context.NOTIFICATION_SERVICE);
                    manager.cancel(DfuService.NOTIFICATION_ID);
                }
            }, 200);
        }

        @Override
        public void onDfuAborted(final String deviceAddress) {
            Log.d(LOG_TAG, "onDfuAborted: " + deviceAddress);
            sendStateUpdate("DFU_ABORTED", deviceAddress);
            if (mPromise != null) {
                mPromise.reject("DFU_ABORTED", "DFU process was aborted");
                mPromise = null;
            }
        }

        @Override
        public void onProgressChanged(final String deviceAddress, final int percent, final float speed, final float avgSpeed, final int currentPart, final int partsTotal) {
            Log.d(LOG_TAG, "onProgressChanged: " + percent + "% for device: " + deviceAddress);
            WritableMap map = new WritableNativeMap();
            map.putString("deviceAddress", deviceAddress);
            map.putInt("percent", percent);
            map.putDouble("speed", speed);
            map.putDouble("avgSpeed", avgSpeed);
            map.putInt("currentPart", currentPart);
            map.putInt("partsTotal", partsTotal);
            sendEvent(progressEvent, map);
        }

        @Override
        public void onError(final String deviceAddress, final int error, final int errorType, final String message) {
            Log.e(LOG_TAG, "onError: device=" + deviceAddress + ", error=" + error + ", type=" + errorType + ", message=" + message);
            sendStateUpdate("DFU_FAILED", deviceAddress);
            if (mPromise != null) {
                mPromise.reject("DFU_ERROR_" + error, message);
                mPromise = null;
            }
        }
    };
}
