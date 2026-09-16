import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('로그인'),
      ),


      body: Center(
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [


            const Text(
              'SNOB',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 50),


            ElevatedButton(

              onPressed: () {

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const BottomNavigation(),
                  ),
                );

              },


              child: const Text(
                '로그인',
              ),

            ),


          ],
        ),
      ),

    );
  }
}