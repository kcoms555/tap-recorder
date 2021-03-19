import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent
  ));
  runApp(Recorder());
}

class Recorder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Recorder',
      home: RecorderHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RecorderHome extends StatefulWidget {
  @override
  _RecorderHomeState createState() => _RecorderHomeState();
}

class _RecorderHomeState extends State<RecorderHome> {
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerIsInited = false;
  int i = 0;
  String status = 'ready';

  @override
  void initState() {
    super.initState();
    _player.openAudioSession().then((value) {
      setState(() {
        _playerIsInited = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _buildStatus()
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      width: 400,
      height: 400,
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(100.0)),
        color: Colors.indigoAccent,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(100.0)),
          child: Center(
              child: _getStatusIcon(),
            ),
          onTap: () {
            print('on tab');
            setState(() {
              i++;
              status = 'playing';
            });
          },
          onTapDown: (detail) {
            print('on tab down');
            SimpleRecorder()
            setState(() {
              i++;
              status = 'recording';
            });
          },
          onTapCancel: () {
            print('onTapCancel');
            setState(() {
              i++;
              status = 'playing';
            });
          },
        )
      )
    );
  }
  Icon _getStatusIcon() {
    IconData iconData = Icons.play_circle_fill;
    Color color = Colors.white;
    switch(status) {
      case 'ready':
        iconData = Icons.fiber_manual_record;
        color = Colors.red.shade50;
        break;
      case 'recording':
        iconData = Icons.stop;
        color = Colors.red.shade50;
        break;
      case 'playing':
        iconData = Icons.replay_outlined;
        color = Colors.white;
        break;
      default:
        iconData = Icons.error_outline;
        color = Colors.white;
    }
    return Icon(
      iconData,
      color: color,
      size: 200
    );
  }
}

