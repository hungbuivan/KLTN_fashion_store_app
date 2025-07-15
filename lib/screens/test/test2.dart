import 'package:flutter/material.dart';

class Test2 extends StatelessWidget {
  const Test2({super.key});

  @override
  Widget build(BuildContext context) {
    int a = 1;
    int b = 2;
    int c = a+b;
    return Scaffold(
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('data'),
            Text('Tổng $a và $b là: $c'),
          ],
        ),
      ),
    );
  }
}