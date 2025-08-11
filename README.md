# 📦 **Storage Devices Inspector**  
A cross-platform tool to gather detailed information about the connected storage devices on your system. It works seamlessly on both **Linux** and **Windows** environments.

## 🎯 **Purpose**  
The **Storage Device Inspector** enables you to inspect and gather comprehensive information about all the storage devices connected to your system, including USB drives, internal hard drives, and SSDs.  

### 🔑 **Key Features:**
- **Device Type**: USB, Fixed Disk (internal storage)
- **Serial Number**, **Model Information**
- **Vendor and Product IDs**
- **Total Size** and **Free Space** (in both GB and bytes)
- **Filesystem** Information (including partitions)
- **Health Status** (if available)

This tool is perfect for users needing a quick overview of all connected storage devices, or for those who wish to export this data for analysis.

---

## 🌟 **Benefits**
- **Cross-Platform Compatibility**: Works on both **Linux** and **Windows** with minimal setup.
- **Comprehensive Data**: Gathers in-depth information about each device’s type, size, partitions, filesystem, and more.
- **Simple & Fast**: No complex installations—just run the script to get instant results in a JSON format.
- **Exportable**: Results are saved in a `StorageDevicesInfo.json` file, making it easy to integrate with other tools or systems.

---

## ⚙️ **How to Use**
### 1. Clone the Repository
  ```bash
  git clone https://github.com/AliJ-Official/StorageDevicesInspector.git
  ```

If you don't have Git installed, you can download the zip file from [this link](https://codeload.github.com/AliJ-Official/StorageDevicesInspector/zip/refs/heads/main) and extract it.

### 2. Navigate to the **StorageDevicesInspector** Directory

---

### 🖥️ **Windows (PowerShell Script)**

#### 🧩 **Dependencies**

- No external dependencies are required for the PowerShell script. As long as you have **PowerShell** installed, you're all set. However, you’ll need to adjust the **Execution Policy** to allow scripts to run.

#### 🔒 **Set Execution Policy**

1. **Open PowerShell in the same directory**

2. **Check Current Execution Policy:**

   ```powershell
   Get-ExecutionPolicy
   ```

3. If the policy is set to **Restricted**, temporarily change it to **Bypass**:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

#### 🚀 **Run the Script**

  ```powershell
  .\StorageDevicesInspector.ps1
  ```

Once the script finishes, a `StorageDevicesInfo.json` file will be generated in the same directory, containing the detailed information of all connected storage devices.

---

### 💻 **Linux (Bash Script)**

#### 🧩 **Dependencies**
- This script requires `jq` to format the output as JSON. Depending on your distribution, follow the appropriate instructions to install it.

- For Debian/Ubuntu-based Systems (apt):
    ```bash
    sudo apt-get update && sudo apt-get upgrade
    sudo apt-get install jq
    ```

- For Red Hat/CentOS/Fedora-based Systems (dnf or yum):
    ```bash
    sudo dnf install jq
    # or 
    sudo yum install jq
    ```

- For Manual Installation (Universal)
   Download the binary and move it to the correct directory:

   ```bash
   curl -Lo jq https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64
   chmod +x jq
   sudo mv jq /usr/local/bin/
   ```

### 🛠️ **Make the Script Executable**
```bash
chmod +x StorageDevicesInspector.sh
```

#### 🚀 **Run the Script**
```bash
./StorageDeviceInspector.sh
```

Once the script finishes, a `StorageDevicesInfo.json` file will be generated in the same directory, containing the detailed information of all connected storage devices.

---

## 📂 **Result Output**

Both scripts will generate a `StorageDevicesInfo.json` file. The data will be structured in **JSON** format, making it easy to parse or integrate with other tools for analysis or reporting.

---

## 🎨 **Customization**

Feel free to modify and adapt these scripts to suit your needs. If you have suggestions, improvements, or new features, feel free to submit a Pull Request!

---

## 🤝 **Contributing**

Contributions are always welcome! If you find any bugs, or have feature requests, or improvements, please open an issue or submit a pull request.

---

## 📑 **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

## 📦 **Tools & Icons Used**

* Icons by [FontAwesome](https://fontawesome.com/)
* `jq` for JSON parsing: [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
* PowerShell for Windows: Pre-installed on most Windows systems

---


