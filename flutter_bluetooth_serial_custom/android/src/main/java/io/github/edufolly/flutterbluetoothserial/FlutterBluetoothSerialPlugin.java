package io.github.edufolly.flutterbluetoothserial;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;

/** FlutterBluetoothSerialPlugin */
public class FlutterBluetoothSerialPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String TAG = "FlutterBlueSerialPlugin";
  
  /// The MethodChannel that will the communication between Flutter and native Android
  private MethodChannel channel;
  private MethodChannel permissionChannel;
  private static Context applicationContext;
  private BluetoothAdapter bluetoothAdapter;
  private ActivityPluginBinding activityBinding;
  private PermissionManager permissionManager;

  // Track active connections
  private final ConcurrentHashMap<String, BluetoothConnection> connections = new ConcurrentHashMap<>();

  /**
   * Provides access to the application context
   */
  public static Context getApplicationContext() {
    return applicationContext;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    applicationContext = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_bluetooth_serial");
    channel.setMethodCallHandler(this);
    
    // Separate channel for permission requests
    permissionChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_bluetooth_serial/permissions");
    
    // Initialize Bluetooth adapter
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      BluetoothManager bluetoothManager = applicationContext.getSystemService(BluetoothManager.class);
      if (bluetoothManager != null) {
        bluetoothAdapter = bluetoothManager.getAdapter();
      }
    } else {
      bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Check if we have permissions for Bluetooth operations
    if (!call.method.equals("isAvailable") && 
        !call.method.equals("requestPermissions") && 
        !PermissionManager.hasPermissions(applicationContext)) {
      result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null);
      return;
    }
    
    switch (call.method) {
      case "isAvailable":
        result.success(bluetoothAdapter != null);
        break;
        
      case "isEnabled":
        if (bluetoothAdapter == null) {
          result.success(false);
        } else {
          result.success(bluetoothAdapter.isEnabled());
        }
        break;
        
      case "getState":
        if (bluetoothAdapter == null) {
          result.success(BluetoothAdapter.STATE_OFF);
        } else {
          result.success(bluetoothAdapter.getState());
        }
        break;
        
      case "requestEnable":
        // This requires an activity context. In a real implementation,
        // we would start an intent to request enabling Bluetooth
        if (bluetoothAdapter == null) {
          result.success(false);
        } else {
          try {
            if (!bluetoothAdapter.isEnabled()) {
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ActivityCompat.checkSelfPermission(applicationContext, 
                    Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                  Log.w(TAG, "BLUETOOTH_CONNECT permission not granted");
                  result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null);
                  return;
                }
              }
              bluetoothAdapter.enable();
            }
            result.success(true);
          } catch (Exception e) {
            Log.e(TAG, "Error enabling Bluetooth", e);
            result.success(false);
          }
        }
        break;
        
      case "getBondedDevices":
        if (bluetoothAdapter == null) {
          result.success(new ArrayList<>());
        } else {
          try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              if (ActivityCompat.checkSelfPermission(applicationContext, 
                  Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "BLUETOOTH_CONNECT permission not granted");
                result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null);
                return;
              }
            }
            
            List<Map<String, Object>> devicesList = new ArrayList<>();
            Set<BluetoothDevice> bondedDevices = bluetoothAdapter.getBondedDevices();
            
            for (BluetoothDevice device : bondedDevices) {
              Map<String, Object> deviceMap = new HashMap<>();
              deviceMap.put("name", device.getName());
              deviceMap.put("address", device.getAddress());
              deviceMap.put("type", device.getType());
              deviceMap.put("isConnected", false);  // Connection state requires additional tracking
              devicesList.add(deviceMap);
            }
            
            result.success(devicesList);
          } catch (Exception e) {
            Log.e(TAG, "Error getting bonded devices", e);
            result.success(new ArrayList<>());
          }
        }
        break;
        
      case "connect":
        connectToDevice(call, result);
        break;
        
      case "disconnect":
        disconnectDevice(call, result);
        break;
        
      case "write":
        writeToDevice(call, result);
        break;
        
      case "isConnected":
        checkConnection(call, result);
        break;
        
      default:
        result.notImplemented();
        break;
    }
  }

  private void connectToDevice(MethodCall call, Result result) {
    String address = call.argument("address");
    if (address == null || address.isEmpty()) {
      result.error("INVALID_ARGUMENT", "Device address is required", null);
      return;
    }
    
    // Check if already connected
    if (connections.containsKey(address) && connections.get(address) != null && 
        connections.get(address).isConnected()) {
      result.success(1); // Connection handle (ID)
      return;
    }
    
    // Start connection in background thread to not block UI
    new Thread(() -> {
      try {
        BluetoothConnection connection = BluetoothConnection.connect(address);
        connections.put(address, connection);
        
        // Send success on main thread
        new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
          result.success(1); // Connection handle (ID)
        });
        
        // Start reading in background
        startReading(address);
      } catch (IOException e) {
        Log.e(TAG, "Error connecting: " + e.getMessage(), e);
        
        // Send error on main thread
        new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
          result.error("CONNECTION_FAILED", e.getMessage(), null);
        });
      }
    }).start();
  }
  
  private void disconnectDevice(MethodCall call, Result result) {
    String address = call.argument("address");
    if (address == null || address.isEmpty()) {
      result.error("INVALID_ARGUMENT", "Device address is required", null);
      return;
    }
    
    BluetoothConnection connection = connections.get(address);
    if (connection != null) {
      connection.close();
      connections.remove(address);
    }
    
    result.success(true);
  }
  
  private void writeToDevice(MethodCall call, Result result) {
    String address = call.argument("address");
    byte[] data = call.argument("data");
    
    if (address == null || address.isEmpty()) {
      result.error("INVALID_ARGUMENT", "Device address is required", null);
      return;
    }
    
    if (data == null || data.length == 0) {
      result.error("INVALID_ARGUMENT", "Data cannot be empty", null);
      return;
    }
    
    BluetoothConnection connection = connections.get(address);
    if (connection == null || !connection.isConnected()) {
      result.error("NOT_CONNECTED", "Device is not connected", null);
      return;
    }
    
    try {
      connection.write(data);
      result.success(true);
    } catch (IOException e) {
      Log.e(TAG, "Error writing data: " + e.getMessage(), e);
      result.error("WRITE_FAILED", e.getMessage(), null);
    }
  }
  
  private void checkConnection(MethodCall call, Result result) {
    String address = call.argument("address");
    
    if (address == null || address.isEmpty()) {
      result.error("INVALID_ARGUMENT", "Device address is required", null);
      return;
    }
    
    BluetoothConnection connection = connections.get(address);
    result.success(connection != null && connection.isConnected());
  }
  
  private void startReading(String address) {
    BluetoothConnection connection = connections.get(address);
    if (connection == null) {
      return;
    }
    
    new Thread(() -> {
      while (connections.containsKey(address) && 
             connections.get(address) != null && 
             connections.get(address).isConnected()) {
        try {
          byte[] data = connection.read();
          if (data.length > 0) {
            // Send data to Flutter
            Map<String, Object> message = new HashMap<>();
            message.put("address", address);
            message.put("data", data);
            
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
              channel.invokeMethod("onDataReceived", message);
            });
          }
        } catch (IOException e) {
          Log.e(TAG, "Error reading data: " + e.getMessage());
          
          // Disconnect on error
          if (connections.containsKey(address)) {
            BluetoothConnection conn = connections.get(address);
            if (conn != null) {
              conn.close();
            }
            connections.remove(address);
            
            // Notify Flutter about disconnection
            new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
              Map<String, Object> message = new HashMap<>();
              message.put("address", address);
              channel.invokeMethod("onDeviceDisconnected", message);
            });
          }
          break;
        }
      }
    }).start();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    permissionChannel.setMethodCallHandler(null);
    applicationContext = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    permissionManager = new PermissionManager(binding.getActivity());
    binding.addRequestPermissionsResultListener(permissionManager);
    
    // Set up the permission channel handler
    permissionChannel.setMethodCallHandler((call, result) -> {
      if (call.method.equals("requestPermissions")) {
        permissionManager.handlePermission(call, result);
      } else {
        result.notImplemented();
      }
    });
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    if (activityBinding != null && permissionManager != null) {
      activityBinding.removeRequestPermissionsResultListener(permissionManager);
    }
    activityBinding = null;
    permissionManager = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    permissionManager = new PermissionManager(binding.getActivity());
    binding.addRequestPermissionsResultListener(permissionManager);
  }

  @Override
  public void onDetachedFromActivity() {
    if (activityBinding != null && permissionManager != null) {
      activityBinding.removeRequestPermissionsResultListener(permissionManager);
    }
    activityBinding = null;
    permissionManager = null;
  }
} 