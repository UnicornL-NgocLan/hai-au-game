import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:haiau_game2/Screens/AdminAccountViewPage.dart';
import 'package:haiau_game2/Screens/AdminPage.dart';
import 'package:haiau_game2/Screens/AdminResultPage.dart';
import 'package:haiau_game2/Screens/AllTeamResult.dart';
import 'package:haiau_game2/Screens/CreateProgramPage.dart';
import 'package:haiau_game2/Screens/CreateStagePage.dart';
import 'package:haiau_game2/Screens/CurrentPlayerResult.dart';
import 'package:haiau_game2/Screens/EndingPage.dart';
import 'package:haiau_game2/Screens/EvaluationPage.dart';
import 'package:haiau_game2/Screens/LoginScreen.dart';
import 'package:haiau_game2/Screens/StageDescriptionPage.dart';
import 'package:haiau_game2/Screens/StageGamePage.dart';
import 'package:haiau_game2/Screens/UpdateInfoPage.dart';
import 'package:haiau_game2/Screens/WaitingRoom.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD8eXXM197pAVeb7cQislh5U2z2mam5eHA",
      authDomain: "haiau-game2.firebaseapp.com",
      projectId: "haiau-game2",
      storageBucket: "haiau-game2.appspot.com",
      messagingSenderId: "893777953328",
      appId: "1:893777953328:web:3bce781fefd9a668a2a3f5",
      measurementId: "G-XL8BNL7V0N"
    ),
  );
  runApp(const MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        initialRoute:'/login',
        routes:{
          "/read-description":(context) => StageDescription(),
          "/view-account":(context) => AdminAccountViewPage(),
          "/all-team-result":(context) => AllTeamResult(),
          "/player-result":(context) => CurrentPlayerResult(),
          "/ending":(context) =>  EndingPage(),
          "/update-info":(context) => UpdateInfoPage(),
          "/waiting-room":(context) => WaitingRoom(),
          "/login":(context) => const LoginScreen(),
          "/admin-home": (context) => const AdminPage(),
          "/add-program": (context) => CreateProgramPage(),
          "/add-stage": (context) => CreateStagePage(),
          "/evaluation":(context) => EvaluationPage(),
          "/admin-result":(context) => AdminResultPage(),
          "/game-stage":(context) => StageGamePage(),
        },
    );
  }
}
