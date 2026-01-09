---
description: Generate Android Release Keystore
---
To sign your app for the Play Store, you need a private key. Run the following command in your terminal.
**IMPORTANT**: Keep the `upload-keystore.jks` file safe and remember the password!

1. Run this command to generate the key:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   *   It will ask for a password. Remember it!
   *   It will ask for some details (Name, Org, etc.). You can fill them or just hit Enter.
   *   Type `yes` when asked to confirm.

2. Create a file named `android/key.properties` with your password details:
   ```properties
   storePassword=YOUR_PASSWORD_HERE
   keyPassword=YOUR_PASSWORD_HERE
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
   *   Replace `YOUR_PASSWORD_HERE` with the password you set in step 1.

3. Once done, let me know and I will configure the build script!
