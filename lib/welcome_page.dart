import 'package:flutter/material.dart';
import '../widget/CurvedBackground.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}
login()async{
  LoginPage();
}
class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          //curved background
          ClipPath(
            clipper: CurvedBackground(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              color: const Color(0xFF027a9c),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Character image
                Image.asset(
                  'img/character.png',
                  height: 460,
                ),

                const SizedBox(height: 40),

                // Text content
                const Text(
                  "Welcome to\nTeachMap.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: const Color(0xFF027a9c),

                      ),
                        child: const Text("Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFFFFFFFF) ,
                            fontWeight: FontWeight.bold,
                          ),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
