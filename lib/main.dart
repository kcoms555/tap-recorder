import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:html';


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
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderWillRunning = false;
  bool _playerIsInited = false;
  bool _recorderIsInited = false;
  String status = 'unaccepted';
  final String _path = 'sound';
  DateTime startTimestamp;
  DateTime endTimestamp;

  @override
  void initState() {
    super.initState();
    _player.openAudioSession().then((value) {
      setState(() {
        _playerIsInited = true;
      });
    });
    initMic();
  }

  void initMic() {
    openTheRecorder().then((value) {
      setState(() {
        _recorderIsInited = true;
        status = 'ready';
      });
    }, onError: (e) {
      if (e is RecordingPermissionException) {
        _recorderIsInited = false;
        status = 'unaccepted';
        return;
      }
      throw e;
    });
  }

  @override
  void dispose() {
    _player.closeAudioSession();
    _recorder.closeAudioSession();
    _player = null;
    _recorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (kIsWeb) {
      try {
        await window.navigator.getUserMedia(audio: true);
      } catch (e){
        print(e);
        throw RecordingPermissionException('Microphone permission not granted');
      }
    } else{
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
   }
    await _recorder.openAudioSession();
    _recorderIsInited = true;
  }

  Future<void> stopRecord() async {
    if(!_recorder.isStopped) {
      _recorderWillRunning = false;
      endTimestamp = DateTime.now();
      await _recorder.stopRecorder();
      setState(() {
        status = 'ready';
      });
    }
  }

  Future<void> startRecord() async {
    _recorderWillRunning = true;
    await stopPlayer();
    await Future.delayed(Duration(milliseconds: 200));
    startTimestamp = DateTime.now();
    _recorder.startRecorder(
      toFile: _path,
      sampleRate: 48000,
      bitRate: 48000,
      codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
    );
    setState(() {
      status = 'recording';
    });
  }

  Future<void> stopPlayer() async {
    if(!_player.isStopped) {
      await _player.stopPlayer();
    }
  }

  Future<void> playPlayer() async {
    if(!_recorder.isStopped || _recorderWillRunning){
      return;
    }
    setState(() {
      status = 'playing';
    });
    await _player.startPlayer(
        fromURI: _path,
        codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
        whenFinished: () {
          playPlayer();
        }
    );
  }

  Future<void> cancelAndPlay() async {
    await Future.delayed(Duration(milliseconds: 400));
    await stopRecord();
    int lenInMilliseconds = endTimestamp.millisecondsSinceEpoch - startTimestamp.millisecondsSinceEpoch;
    print('len : $lenInMilliseconds');
    if(lenInMilliseconds <= 800){
      setState(() {
        status = 'ready';
      });
      return;
    }
    await playPlayer();
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
          onTap: _recorderIsInited ? (){cancelAndPlay();} : initMic,
          onTapDown: _recorderIsInited ? (detail){startRecord();} : null,
          onTapCancel: _recorderIsInited ? (){cancelAndPlay();} : null
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
      case 'unaccepted':
        iconData = Icons.not_interested;
        color = Colors.white;
        break;
      default:
        iconData = Icons.error_outline;
        color = Colors.white;
    }

    if (!_recorderIsInited){
      iconData = Icons.not_interested;
      color = Colors.white;
    }

    return Icon(
      iconData,
      color: color,
      size: 200
    );
  }
}

