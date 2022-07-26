import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/instance_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voice_call_one_to_one/models/user_model.dart';
import 'package:voice_call_one_to_one/utils/utils.dart';
import 'package:http/http.dart' as http;

bool userDeclinedCall = false;

// Initilize Firebase Cloud Messaging for notifications service
subscribeToCallsInFCM() async {
  // Subscribe to calls channel for receiving calls
  FirebaseMessaging.instance.subscribeToTopic("CallsTopic");

  // This function is called when a notifcation is received while the app is opened
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }

    // If other user declined call then go back and end calling state
    if (message.data['callDeclined'] != null) {
      if (!userDeclinedCall) {
        MyApp.navigatorKey.currentState!.pop();
        userDeclinedCall = true;
      }
      print("POPPED CONTEXT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    } else {
      _HomePageState.createCallNotification(
        callerName: message.data['calledName'],
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");

  _HomePageState.createCallNotification(callerName: message.data['callerName']);
}

void main() async {
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
    null,
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
        enableLights: true,
        enableVibration: true,
      )
    ],
    // Channel groups are only visual and are not required
    channelGroups: [
      NotificationChannelGroup(
        channelGroupkey: 'basic_channel_group',
        channelGroupName: 'Basic group',
      )
    ],
    debug: true,
  );

  try {
    // Initialize the firebase app for storing data to database and using firebase messaging notifications service
    await Firebase.initializeApp();
    // Subscribe to notifications
    subscribeToCallsInFCM();
  } catch (ex) {
    print(ex.toString());
  }

  // Entry point for the application
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Global key for nvaigation between app screens
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Check permissions when app is launched
    checkPermissions();
  }

  checkPermissions() async {
    // request permissions for microphone and camera
    await [Permission.microphone, Permission.camera].request();

    // Check notifications for noticiations service
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              title: Text("Allow Notifications"),
              content: Text("Allow Notifications to get calls"),
            );
          },
        );
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Enter your email .. ",
                labelText: "Email",
              ),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Enter your password .. ",
                labelText: "Password",
              ),
              obscureText: true,
              controller: passController,
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () async {
                ////////////// This function is for logining with account /////////////

                // Check if email is empty
                if (emailController.text == "") {
                  Fluttertoast.showToast(msg: "Please enter your email .. ");
                  return;
                }

                // Check if password is empty
                if (passController.text == "") {
                  Fluttertoast.showToast(msg: "Please enter your password .. ");
                  return;
                }

                // Try to login on firebase
                FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                        email: emailController.text,
                        password: passController.text)
                    .then((value) async {
                  UserModel userModel = UserModel(
                    email: value.user!.email!,
                    uid: value.user!.uid,
                    token: await FirebaseMessaging.instance.getToken(),
                  );
                  await FirebaseDatabase.instance
                      .ref("/Users/" + FirebaseAuth.instance.currentUser!.uid)
                      .set(
                        userModel.toJson(),
                      );

                  // If login goes without issues go to Home page
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return HomePage();
                      },
                    ),
                  );
                }).onError((error, stackTrace) {
                  // Print the error while login
                  Fluttertoast.showToast(
                    msg: error.toString(),
                  );
                });
              },
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () {
                // Goto create account page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CreateAccountPage();
                    },
                  ),
                );
              },
              child: const Text("Create account"),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAccountPage extends StatefulWidget {
  @override
  CreateAccountPageState createState() => CreateAccountPageState();
}

class CreateAccountPageState extends State<CreateAccountPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confPassController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Enter your email .. ",
                labelText: "Email",
              ),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Enter your password .. ",
                labelText: "Password",
              ),
              obscureText: true,
              controller: passController,
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Confirm your password .. ",
                labelText: "Confirm Password",
              ),
              obscureText: true,
              controller: confPassController,
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () async {
                ////////// This function is for creating accounts for user with credentials entered /////////

                // Check is email is empty
                if (emailController.text == "") {
                  Fluttertoast.showToast(msg: "Please enter your email .. ");
                  return;
                }

                // Check is password is empty
                if (passController.text == "") {
                  Fluttertoast.showToast(msg: "Please enter your password .. ");
                  return;
                }

                // Check if password and confirmed password are the same
                if (passController.text != confPassController.text) {
                  Fluttertoast.showToast(msg: "Passwords don't match .. ");
                  return;
                }

                // Try to create account on Firebase
                FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passController.text)
                    .then((value) {
                  Fluttertoast.showToast(
                    msg: "Created account successfully ... ",
                  );

                  // Go back to login page
                  Navigator.of(context).pop();
                }).onError((error, stackTrace) {
                  // Print the error
                  Fluttertoast.showToast(
                    msg: error.toString(),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // The user is logged in then he should be able to receive calls
    subscribeToCallsInFCM();

    // Listen to notifications input (answer, decline) call
    AwesomeNotifications().actionStream.listen((event) async {
      print('event received!');
      // print(event.toMap().toString());
      // do something based on event...
      var data = event.toMap();
      // print(data['buttonKeyPressed'].toString());

      AwesomeNotifications().cancel(15000);
      if (data['buttonKeyPressed'] == "answer") {
        print("Joining call ... ");

        // Get the users from database and compare the email entered to get user uid to construct channel name for agora
        var email = data['title'].toString().split(" ")[0];
        var usersData = await FirebaseDatabase.instance.ref("/Users").get();
        if (usersData.exists) {
          if (usersData.children.isNotEmpty) {
            for (var child in usersData.children) {
              var user = UserModel.fromJson(
                Map<String, dynamic>.from(
                  child.value as Map,
                ),
              );
              if (user.email == email) {
                // Found user with email as requested, (Channel name is constructed from caller uid and _ and called uid)
                String channelName =
                    user.uid! + "_" + FirebaseAuth.instance.currentUser!.uid;
                // Join call requested by other user
                joinCall(channelName);
              }
            }
          }
        }
      } else if (data['buttonKeyPressed'] == "decline") {
        // TODO: send notification for caller to exit call
        var email = data['title'].toString().split(" ")[0];
        var usersData = await FirebaseDatabase.instance.ref("/Users").get();
        if (usersData.exists) {
          if (usersData.children.isNotEmpty) {
            for (var child in usersData.children) {
              var user = UserModel.fromJson(
                Map<String, dynamic>.from(
                  child.value as Map,
                ),
              );
              if (user.email == email) {
                String channelName =
                    user.uid! + "_" + FirebaseAuth.instance.currentUser!.uid;
                CallingScreenState.sendNotificationToCaller(
                  user.token!,
                  user.email!,
                  channelName,
                );
              }
            }
          }
        }
      }
    });
  }

  // Show call notification when there's call notification comes from firebase messaging
  static createCallNotification({
    String? callerName,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 15000,
          channelKey: "basic_channel",
          title: "${callerName} is calling .. ",
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          summary: "${callerName} is calling you"),
      actionButtons: [
        NotificationActionButton(
          key: "answer",
          label: "Answer",
          color: Colors.green,
          enabled: true,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: "decline",
          label: "Decline",
          color: Colors.green,
          enabled: true,
          showInCompactView: true,
        )
      ],
    );
  }

  // Join call requested by other user
  joinCall(String? channelName) async {
    // Get agora token from the server for the requested channel name
    var tokenRes = await http.get(Uri.parse(
      Utils.agoraTokenServerUrl + "?channelName=" + channelName!,
    ));

    // Read the token from json response
    var token = jsonDecode(tokenRes.body);

    // Go to calling screen to call with the current channel name to join other user in the agora channel
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CallingScreen(
            channelName: channelName,
            token: token['token'],
            // User is not caller so he joins channel not create it
            isCaller: false,
          );
        },
      ),
    );
  }

  // Call person with specified email
  callPerson() async {
    // Check is user email is empty
    if (userIdController.text == "") {
      Fluttertoast.showToast(
        msg: "User ID cannot be empty ... ",
      );
      return;
    }

    // Get users to get uid of the requested email to construct the channel from uids
    var usersData = await FirebaseDatabase.instance.ref("/Users").get();
    if (usersData.exists) {
      if (usersData.children.isNotEmpty) {
        for (var child in usersData.children) {
          var user = UserModel.fromJson(
            Map<String, dynamic>.from(
              child.value as Map,
            ),
          );
          if (user.email!.toLowerCase().trim() ==
              userIdController.text.toLowerCase().trim()) {
            // Found user (channel name = "<caller_uid>_<called_uid>")
            String channelName =
                "${FirebaseAuth.instance.currentUser!.uid}_${user.uid}";

            // Get token for joining agora
            var tokenRes = await http.get(Uri.parse(
              Utils.agoraTokenServerUrl + "?channelName=" + channelName,
            ));

            // Decode the response
            var token = jsonDecode(tokenRes.body);

            // Goto calling screen to join the agora channel and wait for other user to join call
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return CallingScreen(
                    channelName: channelName,
                    token: token['token'],
                    isCaller: true,
                  );
                },
              ),
            );

            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("One-to-One Call Demo"),
        ),
        body: Center(
          child: TextFormField(
            controller: userIdController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: "Enter the email for whom you want to call .. ",
              labelText: "User Email",
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Call person
            await callPerson();
          },
          child: const Icon(
            Icons.call,
          ),
        ),
      ),
      onWillPop: () async {
        return false;
      },
    );
  }
}

class CallingScreen extends StatefulWidget {
  String? channelName;
  String? token;
  bool? isCaller;

  CallingScreen({
    Key? key,
    this.channelName,
    this.token,
    this.isCaller,
  }) : super(key: key);

  @override
  CallingScreenState createState() => CallingScreenState();
}

class CallingScreenState extends State<CallingScreen> {
  Widget body = Container();
  bool _localUserJoined = false;
  bool remoteUserJoined = false;
  bool _showStats = false;
  int? _remoteUid;
  RtcStats? _stats;
  RtcEngine? engine;

  // Timer for call (when 40 seconds pass then the user is not responding)
  Timer? callingTimer;
  int callingTimerStart = 40;
  // Timer for call duration (to show the seconds on the screen)
  Timer? callTimeTimer;
  int callTimeTimerStart = 0;

  bool micMuted = false;
  bool camOn = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    userDeclinedCall = false;

    body = Container();

    // Initialize agora rtc engine
    initRTC();
  }

  initRTC() async {
    // Inititialize agora engine params
    await initAgora();

    if (widget.isCaller!) {
      await initCall();
    } else {
      await joinCall();
    }
  }

  initAgora() async {
    // Create engine with app id
    engine = await RtcEngine.create(Utils.agoraAppId);

    // Set the callbacks for the engine
    engine!.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        // This is called when current user joins channel
        print('$uid successfully joined channel: $channel ');
        setState(() {
          _localUserJoined = true;
        });
      },
      userJoined: (int uid, int elapsed) {
        // This is called when the other user joins the channel
        print('remote user $uid joined channel');
        setState(() {
          remoteUserJoined = true;
          _remoteUid = uid;
          body = Stack(
            children: [
              Container(
                child: renderRemoteVideo(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.width * 0.4,
                    child: renderLocalPreview(),
                  ),
                ),
              )
            ],
          );
          callingTimer!.cancel();
        });
        // Other user joined call then start call duration counter
        startCallTimerTimer();
      },
      userOffline: (int uid, UserOfflineReason reason) async {
        // If the other user hangs up or disconnects
        print('remote user $uid left channel');
        setState(() {
          _remoteUid = null;
        });

        // Leave channel as well and go back to dialing page
        await engine!.leaveChannel();

        Navigator.of(context).pop();
      },
      rtcStats: (stats) {
        // TODO: show stats here if you want
      },
    ));
  }

  // This function is for initilizing call (caller)
  initCall() async {
    // Enable video in the agora rtc engine
    await engine!.enableVideo();
    // Join the agora rtc channel
    await engine!.joinChannel(
      widget.token,
      widget.channelName!,
      null,
      0,
    );

    // Get called person data
    var calledPersonData = await FirebaseDatabase.instance
        .ref("/Users/" + widget.channelName!.split("_")[1])
        .get();

    if (calledPersonData.exists) {
      if (calledPersonData.children.isNotEmpty) {
        UserModel userModel = UserModel.fromJson(
          Map<String, dynamic>.from(
            calledPersonData.value as Map,
          ),
        );

        setState(() {
          body = Center(
            child: Text(
              "Calling ${userModel.email} ... ",
            ),
          );
        });

        // Send notification to called person
        sendNotificationToCalledPerson(
          userModel.token!,
          context,
          userModel.email!,
        );
      }
    }

    startTimerForCall();
  }

  // Start the countdown for ringing state
  startCallTimerTimer() {
    const oneSec = Duration(seconds: 1);
    setState(() {
      callTimeTimerStart = 0;
    });
    callTimeTimer = Timer.periodic(oneSec, (timer) {
      setState(() {
        callTimeTimerStart++;
      });
    });
  }

  // Duration counter for the call
  startTimerForCall() {
    const oneSec = Duration(seconds: 1);
    setState(() {
      callingTimerStart = 40;
    });
    callingTimer = Timer.periodic(oneSec, (timer) {
      if (callingTimerStart == 0) {
        setState(() {
          callingTimer!.cancel();
        });
        endCallForCaller();
      } else {
        setState(() {
          callingTimerStart--;
        });
      }
    });
  }

  // End call for the person who called
  endCallForCaller() async {
    Navigator.of(context).pop();
  }

  // Join the call if you are being called (not caller)
  joinCall() async {
    // Enable video in the engine
    await engine!.enableVideo();
    // Join the channel
    await engine!.joinChannel(
      widget.token,
      widget.channelName!,
      null,
      0,
    );

    startCallTimerTimer();
  }

  // Send notification to caller that the user responded to call
  static sendNotificationToCaller(
      String token, String callerEmail, String? channelName) async {
    if (token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': "Bearer ${Utils.fcmServerKey}",
        },
        body: constructFCMPayloadCaller(token, callerEmail, channelName!),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  // Data for request to caller (token: the other user device id (look at the login page))
  static String constructFCMPayloadCaller(
      String token, String callerEmail, String channelName) {
    var res = jsonEncode({
      "token": token,
      "notification": {
        "body":
            "User ${FirebaseAuth.instance.currentUser!.email} declined your call.",
        "title": "User busy"
      },
      "priority": "high",
      "data": {
        "status": "done",
        "channel_name": channelName,
        "callerName": callerEmail,
        "calledName": FirebaseAuth.instance.currentUser!.email,
        "callDeclined": true
      },
      'to': token,
    });

    print(res.toString());
    return res;
  }

  // Send notification to called person to let him know that there's a call
  sendNotificationToCalledPerson(
      String token, context, String callerEmail) async {
    if (token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': "Bearer ${Utils.fcmServerKey}",
        },
        body: constructFCMPayload(token, callerEmail, widget.channelName!),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  // Data for request for called person
  static String constructFCMPayload(
      String token, String callerEmail, String channelName) {
    var res = jsonEncode({
      "token": token,
      "notification": {
        "body": "You have a new call from ${callerEmail}.",
        "title": "New Call"
      },
      "priority": "high",
      "data": {
        "status": "done",
        "channel_name": channelName,
        "callerName": callerEmail,
        "calledName": FirebaseAuth.instance.currentUser!.email
      },
      'to': token,
    });

    print(res.toString());
    return res;
  }

  // Format call time to display it on the screen
  String formatTime(int seconds) {
    return '${(Duration(seconds: seconds))}'.split('.')[0].padLeft(8, '0');
  }

  // Render the widget for the local user video
  Widget renderLocalPreview() {
    if (_localUserJoined) {
      return const RtcLocalView.SurfaceView();
    } else {
      return const Text(
        'Please join channel first',
        textAlign: TextAlign.center,
      );
    }
  }

  // Render the widget for the remote user video
  Widget renderRemoteVideo() {
    if (_remoteUid != null) {
      return RtcRemoteView.SurfaceView(
        uid: _remoteUid!,
        channelId: widget.channelName!,
      );
    } else {
      return const Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  void dispose() {
    try {
      // Try to cancel timers
      callingTimer!.cancel();
      callTimeTimer!.cancel();
    } catch (ex) {
      // Print the error if there's an error
      print(ex.toString());
    }
    // Dispose agora engine
    disposeAgora();
    super.dispose();
  }

  disposeAgora() async {
    try {
      // Try to leave channel
      await engine!.leaveChannel();
    } catch (ex) {
      // Print the error if there's any
      print(ex.toString());
    }
    // Destroy agora rtc engine
    engine!.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: Stack(
          children: [
            body,
            Padding(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    remoteUserJoined
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "${formatTime(callTimeTimerStart)}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        remoteUserJoined
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                        const CircleBorder()),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(10)),
                                    backgroundColor: MaterialStateProperty.all(
                                        !micMuted
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors
                                                .black87), // <-- Button color
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color?>((states) {
                                      if (states
                                          .contains(MaterialState.pressed))
                                        return Colors.red; // <-- Splash color
                                    }),
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      micMuted = !micMuted;
                                    });

                                    await engine!
                                        .muteLocalAudioStream(!micMuted);
                                  },
                                  child: micMuted
                                      ? const Icon(
                                          Icons.mic_off,
                                          size: 25,
                                        )
                                      : const Icon(
                                          Icons.mic,
                                          size: 25,
                                        ),
                                ),
                              )
                            : Container(),
                        remoteUserJoined
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                        const CircleBorder()),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(15)),
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.red), // <-- Button color
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color?>((states) {
                                      if (states
                                          .contains(MaterialState.pressed)) {
                                        return Colors.red;
                                      } // <-- Splash color
                                    }),
                                  ),
                                  onPressed: () async {
                                    // TODO: end call here
                                    try {
                                      await engine!.leaveChannel();
                                    } catch (ex) {
                                      print(ex.toString());
                                    }

                                    Navigator.of(context).pop();
                                  },
                                  child: const Icon(
                                    Icons.call_end,
                                    size: 35,
                                  ),
                                ),
                              )
                            : Container(),
                        remoteUserJoined
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                        const CircleBorder()),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(10)),
                                    backgroundColor: MaterialStateProperty.all(
                                        camOn
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors
                                                .black87), // <-- Button color
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color?>((states) {
                                      if (states
                                          .contains(MaterialState.pressed)) {
                                        return Colors.red;
                                      } // <-- Splash color
                                    }),
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      camOn = !camOn;
                                    });

                                    await engine!.muteLocalVideoStream(!camOn);
                                  },
                                  child: camOn
                                      ? const Icon(
                                          Icons.videocam,
                                          size: 25,
                                        )
                                      : const Icon(
                                          Icons.videocam_off,
                                          size: 25,
                                        ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        floatingActionButton: remoteUserJoined
            ? Container()
            : FloatingActionButton(
                onPressed: () async {
                  // TODO: end call here
                  try {
                    await engine!.leaveChannel();
                  } catch (ex) {
                    print(ex.toString());
                  }

                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              ),
      ),
      onWillPop: () async {
        return false;
      },
    );
  }
}
