import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chiikawa Study App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            //this da grass
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Image.asset(
                'assets/images/grassy_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            //foreground chiikawa

            Center(
              child: 
              Column(
                children: [
                  const Text( //REMEMBER THIS IS WHERE THE TEXT IS
                    "There's nothing here...",
                    style: TextStyle(
                      fontFamily: 'Doodle_Head',
                      fontSize: 29,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/images/chiikawa_confused.png',
                    width: 200,
                    height: 200,
                  ),
              ],)     
              )





          ]

        ),
      ),
    );


  }
}