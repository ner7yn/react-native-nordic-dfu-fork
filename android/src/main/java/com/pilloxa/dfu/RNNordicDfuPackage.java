package com.pilloxa.dfu;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import android.util.Log; // ← ДОБАВЬТЕ
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.facebook.react.bridge.JavaScriptModule;

public class RNNordicDfuPackage implements ReactPackage {
    private static final String TAG = "RNNordicDfuPackage";

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        Log.d(TAG, "Creating RNNordicDfuModule");
        return Arrays.<NativeModule>asList(new RNNordicDfuModule(reactContext));
    }

    public List<Class<? extends JavaScriptModule>> createJSModules() {
        Log.d(TAG, "Creating JS modules");
        return Collections.emptyList();
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        Log.d(TAG, "Creating view managers");
        return Collections.emptyList();
    }
}