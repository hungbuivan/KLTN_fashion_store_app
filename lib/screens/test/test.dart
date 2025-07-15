import 'package:flutter/material.dart';

class Test extends StatelessWidget{
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    int a = 1;
    int b = 2;
    int c = a+b;
    return Scaffold(
      appBar: AppBar(
        title: Text('Màn hình chính'),
        centerTitle: true,
      ),
      body: Center(
        child:
          Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('data'),
          Text('Tổng a và b là: $c',),
        ],
      ),


      )

    );
  }
}