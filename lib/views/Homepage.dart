import 'package:detector/views/Detection.dart';
import 'package:detector/views/Pnuemonia.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CameraView()));
                },
                child: Text("Object")),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Pneumonia()));
                },
                child: Text("Pnuemonia"))
          ],
        ),
      ),
    );
  }
}
