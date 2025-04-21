import 'package:flutter/material.dart';

class LoadImagesDemo extends StatelessWidget {
  const LoadImagesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load IMAGE demo'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Image.asset('assets/images/anh-nen-4k-cho-desktop_105907396.jpg'),
            ),
            Expanded(
                child: Image.asset('assets/images/anh-nen-anime-4k-thien-nhien_062607131.jpg')
            ),
            Expanded(
              child: Image.asset('assets/images/anh-nen-cho-may-tinh-4k_105908365.jpg'),
            ),
          ],
        ),
      ),

    );
  }
}