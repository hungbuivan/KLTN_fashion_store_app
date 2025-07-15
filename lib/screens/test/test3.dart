import 'package:flutter/material.dart';

class Test3 extends StatelessWidget {
  const Test3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HVNN'),
        centerTitle: true,
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('data',style: TextStyle(fontSize: 50,fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }

}