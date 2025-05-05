package io.github.edufolly.flutterbluetoothserial;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class PermissionManager implements PluginRegistry.RequestPermissionsResultListener {
    private static final String TAG = "BluetoothPermManager";
    private static final int REQUEST_BLUETOOTH_PERMISSIONS = 9823;
    
    private final Activity activity;
    private MethodChannel.Result pendingResult;
    
    public PermissionManager(Activity activity) {
        this.activity = activity;
    }
    
    public void handlePermission(MethodCall call, @NonNull MethodChannel.Result result) {
        if (pendingResult != null) {
            result.error("ALREADY_REQUESTING_PERMISSION", 
                         "Another permission request is already in progress", null);
            return;
        }
        
        pendingResult = result;
        requestPermissions();
    }
    
    private void requestPermissions() {
        List<String> permissionsToRequest = new ArrayList<>();
        
        // Permissions for Android 12+ (API 31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT) 
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT);
            }
            
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN) 
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN);
            }
        } 
        // Permissions for Android 6 to 11 (API 23-30)
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH) 
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH);
            }
            
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_ADMIN) 
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_ADMIN);
            }
            
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) 
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION);
            }
        }
        
        if (permissionsToRequest.isEmpty()) {
            // All permissions already granted
            finishWithSuccess(true);
            return;
        }
        
        String[] permissions = permissionsToRequest.toArray(new String[0]);
        ActivityCompat.requestPermissions(activity, permissions, REQUEST_BLUETOOTH_PERMISSIONS);
    }
    
    private void finishWithSuccess(boolean isSuccess) {
        if (pendingResult != null) {
            pendingResult.success(isSuccess);
            pendingResult = null;
        }
    }
    
    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != REQUEST_BLUETOOTH_PERMISSIONS || pendingResult == null) {
            return false;
        }
        
        boolean allPermissionsGranted = true;
        
        if (grantResults.length > 0) {
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allPermissionsGranted = false;
                    break;
                }
            }
        } else {
            // User canceled the permission request
            allPermissionsGranted = false;
        }
        
        finishWithSuccess(allPermissionsGranted);
        return true;
    }
    
    public static boolean hasPermissions(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) 
                    == PackageManager.PERMISSION_GRANTED
                   && ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) 
                    == PackageManager.PERMISSION_GRANTED;
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH) 
                    == PackageManager.PERMISSION_GRANTED
                   && ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADMIN) 
                    == PackageManager.PERMISSION_GRANTED
                   && ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
                    == PackageManager.PERMISSION_GRANTED;
        }
        
        // On older versions, permissions are granted at install time
        return true;
    }
} 