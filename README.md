## Voice & Video Call one_to_one flutter agora rtc implementation

Flutter implementation of voice and video calls one to one style (Messenger and WhatsApp calls as an example).

## Getting Started

The project is ready to run just clone the repo and run `flutter run` in project root directory

However, if you want to create it a step by step read this guide

- First, Create a firebase project at [Firebase Console](https://console.firebase.google.com/)
- Then, enable authentication, realtime database and storage services in the build tab
- Then, go to project settings and add android app (or ios) 
- Then, write your package name (com.org.app_name)
- Then, follow the steps in the guide 
- Then, you should have downloaded `google-services.json` file, place the file in the `/project-root/android/app` folder
- Then, let's create agora project, go to [Agora Console](https://console.agora.io/)
- Then, copy your app id and place in the `utils.dart` file in `/project-root/lib/utils/utils.dart`
- Then, copy the code you will find in the `AgoraTokenServer` folder in the `/project-root` folder
- Note, update the app id and app certificate in `index.js` file to your project app id and certificate that you can get from agora console page for your project
- Then, upload the folder `AgoraTokenServer` to heroku [Read This if this is your first time with heroku](https://devcenter.heroku.com/articles/deploying-nodejs)
- Then, replace the `agoraTokenServerUrl` variable in `utils.dart` with your heroku app url
- Then, go to [Firebase Console](https://console.firebase.google.com/) and go to project settings
- Then. go to cloud messaging tab and enable `Cloud Messaging API (Legacy)` if it's not enabled already and copy the server key there and replace the `fcmServerKey` in `utils.dart` with the one you copied from firebase
- You may need to add these permissions to your `AndroidManifest.xml` in `/project-root/android/app/src/main`

  `<uses-permission android:name="android.permission.READ_PHONE_STATE" />`                                                                                
  `<uses-permission android:name="android.permission.INTERNET" />`                                                                                        
  `<uses-permission android:name="android.permission.RECORD_AUDIO" />`                                                                                    
  `<uses-permission android:name="android.permission.CAMERA" />`                                                                                          
  `<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />`                                                                           
  `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />`                                                                            
  `<uses-permission android:name="android.permission.BLUETOOTH" />`                                                                                       
  `<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />`                                                                               
  `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />`                                                                           
  `<uses-permission android:name="android.permission.WAKE_LOCK" />`   
  
 - Now, you're good to go run `flutter run` and see it for your self
 
 
 ## Screenshots from the app
![alt text](https://github.com/nader1414518/voice-video-call-one-to-one-agora/blob/screenshots/Screen%20Shot%202022-07-26%20at%2006.38.58.png)
