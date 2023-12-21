import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final ScanController1 scanController1 = Get.put(ScanController1());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return scanController1.isCameraInitialized.value
            ? Column(
                children: [
                  CameraPreview(scanController1.cameraController),
                  Center(
                    child: Text(
                      "Detected Object: ${scanController1.detectedLabel.value ?? 'None'}",
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

class ScanController1 extends GetxController {
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
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
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
      model: "assets/models1.tflite",
      labels: "assets/labels1.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    List? detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map(
        (plane) {
          return plane.bytes;
        },
      ).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector!.isNotEmpty) {
      String? label = detector.first['label'];

      if (label != null) {
        detectedLabel.value = label;
        log('Detected label is: $label');
      } else {
        print('Label not found or detector data is empty');
      }
    }
  }
}
