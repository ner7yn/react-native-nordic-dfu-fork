package com.pilloxa.dfu;

import no.nordicsemi.android.dfu.DfuBaseService;
import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.util.Log;

public class DfuService extends DfuBaseService {
    private static final String TAG = "DfuService";

    @Override
    protected Class<? extends Activity> getNotificationTarget() {
        Log.d(TAG, "Getting notification target");
        return NotificationActivity.class;
    }

    @Override
    protected boolean isDebug() {
        Log.d(TAG, "Debug mode enabled");
        return true;
    }

    // @Override
    // protected String getNotificationChannel() {
    //     Log.d(TAG, "Creating notification channel");
    //     return createNotificationChannel();
    // }

    private String createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = "dfu_channel";
            String channelName = "DFU Updates";
            
            NotificationChannel channel = new NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("DFU firmware update notifications");
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
            
            Log.d(TAG, "Notification channel created: " + channelId);
            return channelId;
        }
        return null;
    }
}