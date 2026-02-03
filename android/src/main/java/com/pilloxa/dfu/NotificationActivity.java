package com.pilloxa.dfu;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.Nullable;
import android.util.Log; // ← ДОБАВЬТЕ
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.bridge.ReactContext;

public class NotificationActivity extends Activity {
    private static final String TAG = "NotificationActivity";
    private ReactInstanceManager reactInstanceManager;

    private ReactContext getReactContext() {
        Log.d(TAG, "Getting React context");
        reactInstanceManager = ((ReactApplication) getApplication())
                .getReactNativeHost()
                .getReactInstanceManager();
        return reactInstanceManager.getCurrentReactContext();
    }

    public Class getMainActivityClass(ReactContext reactContext) {
        Log.d(TAG, "Getting main activity class");
        String packageName = reactContext.getPackageName();
        Intent launchIntent = reactContext.getPackageManager().getLaunchIntentForPackage(packageName);
        String className = launchIntent.getComponent().getClassName();
        try {
            return Class.forName(className);
        } catch (ClassNotFoundException e) {
            Log.e(TAG, "Main activity class not found", e);
            e.printStackTrace();
            return null;
        }
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "NotificationActivity onCreate");
        
        // If this activity is the root activity of the task, the app is not running
        if (isTaskRoot()) {
            Log.d(TAG, "Activity is task root, starting main app");
            ReactContext reactContext = getReactContext();
            Class HostActivity = getMainActivityClass(reactContext);
            // Start the app before finishing
            final Intent intent = new Intent(this, HostActivity);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.putExtras(getIntent().getExtras()); // copy all extras
            startActivity(intent);
        } else {
            Log.d(TAG, "Activity is not task root");
        }

        // Now finish, which will drop you to the activity at which you were at the top of the task stack
        Log.d(TAG, "Finishing NotificationActivity");
        finish();
    }
}