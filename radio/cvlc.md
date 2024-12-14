To change the HTTP port used by `cvlc`, follow these steps:

---

### **1. Specify the HTTP Port Using Command-Line Options**
You can directly set the HTTP interface port when starting `cvlc`.

#### Example:
```bash
cvlc --intf http --http-port 8081
```
This starts the HTTP interface on port **8081** instead of the default port **8080**.

---

### **2. Use the `vlcrc` Configuration File**
You can change the default HTTP port in the VLC configuration file.

#### Steps:
1. Open the VLC configuration file:
   ```bash
   nano ~/.config/vlc/vlcrc
   ```
2. Search for the line containing:
   ```plaintext
   #http-port=8080
   ```
3. Uncomment the line by removing the `#` and set your desired port:
   ```plaintext
   http-port=8081
   ```
4. Save the file and exit.

#### Run `cvlc` with HTTP Interface:
```bash
cvlc --intf http
```
The HTTP interface will now use the port defined in the configuration file.

---

### **3. Confirm the New Port**
Once started, verify that VLC is listening on the new port using:
```bash
netstat -tuln | grep 8081
```

Or by visiting:
```
http://<your-ip>:8081/
```

---

### **4. Use Both HTTP and RC Interface**
If you need to combine HTTP with other interfaces (like RC), you can specify both:
```bash
cvlc --intf http --http-port 8081 --intf rc
```

This configuration allows simultaneous control through both the HTTP and RC interfaces.
