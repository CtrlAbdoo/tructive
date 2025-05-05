package io.github.edufolly.flutterbluetoothserial;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.core.app.ActivityCompat;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Manages Bluetooth connections to devices
 */
public class BluetoothConnection {
    private static final String TAG = "BluetoothConnection";
    
    // Standard UUID for Serial Port Profile
    private static final UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
    
    // Connection timeout in milliseconds
    private static final int CONNECTION_TIMEOUT = 10000; // 10 seconds
    
    private static final ConcurrentHashMap<String, BluetoothConnection> activeConnections = new ConcurrentHashMap<>();
    
    private final BluetoothSocket socket;
    private final InputStream inputStream;
    private final OutputStream outputStream;
    private final String deviceAddress;
    private boolean isConnected = false;
    
    /**
     * Creates a BluetoothConnection to the specified device
     */
    private BluetoothConnection(BluetoothSocket socket) throws IOException {
        this.socket = socket;
        this.inputStream = socket.getInputStream();
        this.outputStream = socket.getOutputStream();
        this.deviceAddress = socket.getRemoteDevice().getAddress();
        this.isConnected = true;
    }
    
    /**
     * Establishes a connection to the specified device
     */
    public static BluetoothConnection connect(String address) throws IOException {
        // Check if a connection already exists
        if (activeConnections.containsKey(address)) {
            BluetoothConnection existingConnection = activeConnections.get(address);
            if (existingConnection != null && existingConnection.isConnected) {
                return existingConnection;
            } else {
                activeConnections.remove(address);
            }
        }
        
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter == null) {
            throw new IOException("Bluetooth is not supported on this device");
        }
        
        if (!bluetoothAdapter.isEnabled()) {
            throw new IOException("Bluetooth is disabled");
        }
        
        BluetoothDevice device;
        try {
            device = bluetoothAdapter.getRemoteDevice(address);
        } catch (IllegalArgumentException e) {
            throw new IOException("Invalid Bluetooth address: " + address);
        }
        
        BluetoothSocket socket = null;
        boolean connectionSuccess = false;
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                ActivityCompat.checkSelfPermission(FlutterBluetoothSerialPlugin.getApplicationContext(), 
                    Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                throw new IOException("BLUETOOTH_CONNECT permission not granted");
            }
            
            // First try the standard way
            socket = device.createRfcommSocketToServiceRecord(SPP_UUID);
            
            // Cancel discovery as it slows down connection
            bluetoothAdapter.cancelDiscovery();
            
            // Set socket timeout
            socket.connect();
            connectionSuccess = true;
            
        } catch (IOException e) {
            Log.e(TAG, "First connection attempt failed, trying fallback...", e);
            
            // Close the failed socket before trying alternative methods
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException closeEx) {
                    Log.e(TAG, "Failed to close socket after failed connection", closeEx);
                }
            }
            
            try {
                // Fallback for some devices: try using reflection to get a different socket type
                socket = (BluetoothSocket) device.getClass()
                        .getMethod("createRfcommSocket", new Class[]{int.class})
                        .invoke(device, 1);
                
                // Set a timeout
                socket.connect();
                connectionSuccess = true;
                
            } catch (Exception fallbackEx) {
                Log.e(TAG, "Fallback connection also failed", fallbackEx);
                
                if (socket != null) {
                    try {
                        socket.close();
                    } catch (IOException closeEx) {
                        Log.e(TAG, "Failed to close socket after fallback failure", closeEx);
                    }
                }
                
                throw new IOException("Failed to connect to device: " + e.getMessage());
            }
        }
        
        if (connectionSuccess) {
            BluetoothConnection connection = new BluetoothConnection(socket);
            activeConnections.put(address, connection);
            return connection;
        } else {
            throw new IOException("Unknown connection error");
        }
    }
    
    /**
     * Read data from the connected device
     */
    public byte[] read() throws IOException {
        if (!isConnected) {
            throw new IOException("Device is not connected");
        }
        
        try {
            byte[] buffer = new byte[1024];
            int bytesRead = inputStream.read(buffer);
            
            if (bytesRead == -1) {
                throw new IOException("End of stream reached");
            }
            
            byte[] data = new byte[bytesRead];
            System.arraycopy(buffer, 0, data, 0, bytesRead);
            return data;
        } catch (IOException e) {
            // Mark as disconnected on error
            isConnected = false;
            throw e;
        }
    }
    
    /**
     * Write data to the connected device
     */
    public void write(byte[] data) throws IOException {
        if (!isConnected) {
            throw new IOException("Device is not connected");
        }
        
        try {
            outputStream.write(data);
            outputStream.flush();
        } catch (IOException e) {
            // Mark as disconnected on error
            isConnected = false;
            throw e;
        }
    }
    
    /**
     * Check if the connection is active
     */
    public boolean isConnected() {
        try {
            // Additional check to confirm socket is actually connected
            return isConnected && socket.isConnected() && 
                  (socket.getInputStream().available() >= 0); // Will throw if socket is closed
        } catch (Exception e) {
            isConnected = false;
            return false;
        }
    }
    
    /**
     * Close the connection
     */
    public void close() {
        try {
            isConnected = false;
            activeConnections.remove(deviceAddress);
            
            if (inputStream != null) {
                inputStream.close();
            }
            
            if (outputStream != null) {
                outputStream.close();
            }
            
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            Log.e(TAG, "Error closing connection", e);
        }
    }
} 