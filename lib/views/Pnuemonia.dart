import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class Pneumonia extends StatefulWidget {
  const Pneumonia({Key? key}) : super(key: key);

  @override
  State<Pneumonia> createState() => _PneumoniaState();
}

class _PneumoniaState extends State<Pneumonia> {
  final ScanController scanController = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return scanController.isCameraInitialized.value
            ? Column(
                children: [
                  CameraPreview(scanController.cameraController),
                  Center(
                    child: Text(
                      "Detected Object: ${scanController.detectedLabel.value ?? 'None'}",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Go back'),
                    ),
                  )
                ],
              )
            : const Center(child: Text('Loading...'));
      }),
    );
  }
}

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
    Tflite.close(); // Close the TFLite interpreter when not in use
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  var detectedLabel = "None".obs;

  var x, y, w, h = 0.0;

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await cameraController.initialize().then((_) {
        cameraController.startImageStream((CameraImage image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });

      isCameraInitialized(true);
      update();
    } else {
      print("Permission Denied");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: "assets/models.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    try {
      List<Uint8List> bytesList = image.planes.map((plane) {
        return plane.bytes;
      }).toList();

      var recognitions = await Tflite.runModelOnFrame(
        bytesList: bytesList,
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        rotation: -90, // Adjust the rotation based on your requirements
        threshold: 0.4,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        String? label = recognitions[0]['label'];

        if (label != null) {
          detectedLabel.value = label;
          log('Detected label is: $label');
        } else {
          print('Label not found or recognizer data is empty');
        }
      }
    } catch (e) {
      print('Error during object detection: $e');
    }
  }
}
