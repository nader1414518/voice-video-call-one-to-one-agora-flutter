# voice_call_one_to_one

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
