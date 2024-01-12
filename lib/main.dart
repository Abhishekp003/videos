import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late VoidCallback _listener;
  bool _isPlaying = false;
  late Duration _currentPosition;
  double _sliderValue = 0.0;
  late bool _isFullScreen;
  bool _isLocked = false;
  double _videoClarity = 1.0; // Default clarity level

  // Add a description for the video
  String _videoDescription =
      "This is a sample video description. Add your own description here.";

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'asstes/videos/nagaharish.mp4',
    )..initialize().then((_) {
      setState(() {});
    });
    _listener = () {
      if (!_controller.value.isPlaying &&
          _controller.value.isInitialized) {
        setState(() {
          _isPlaying = false;
        });
      } else if (_controller.value.isPlaying && _isPlaying == false) {
        setState(() {
          _isPlaying = true;
        });
      }

      // Update the slider value based on the video's current position
      setState(() {
        _currentPosition = _controller.value.position;
        _sliderValue = _currentPosition.inMilliseconds /
            _controller.value.duration.inMilliseconds;
      });
    };
    _controller.addListener(_listener);
    _currentPosition = Duration.zero;
    _isFullScreen = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    final newPosition =
        _controller.value.position + Duration(seconds: seconds);
    if (newPosition.inMilliseconds < 0) {
      _controller.seekTo(Duration.zero);
    } else if (newPosition.inMilliseconds >
        _controller.value.duration.inMilliseconds) {
      _controller.seekTo(_controller.value.duration);
    } else {
      _controller.seekTo(newPosition);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPlayer(
            controller: _controller,
            isFullScreen: _isFullScreen,
          ),
        ),
      );
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Video Settings'),
          content: Column(
            children: [
              Text('Video Clarity'),
              Slider(
                value: _videoClarity,
                onChanged: (value) {
                  setState(() {
                    _videoClarity = value;
                  });
                },
                min: 0.5,
                max: 1.5,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.lock, color: Colors.white),
              onPressed: () {
                _toggleLock();
              },
            ),
            Text(
              '${formatDuration(_currentPosition)}',
              style: TextStyle(color: Colors.white),
            ),
            Expanded(
              child: Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    final newPosition = Duration(
                      milliseconds: (value *
                          _controller.value.duration.inMilliseconds)
                          .round(),
                    );
                    _controller.seekTo(newPosition);
                  });
                },
                activeColor: Colors.green[200],
              ),
            ),
            Text(
              '${formatDuration(_controller.value.duration)}',
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                _showSettingsDialog();
              },
            ),
            IconButton(
              icon: _isFullScreen
                  ? Icon(Icons.fullscreen_exit, color: Colors.white)
                  : Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                _toggleFullScreen();
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildAdditionalControls(),
        SizedBox(height: 8),
        // Display the video description
        Text(
          _videoDescription,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    if (_isLocked) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.replay_10, color: Colors.white),
            onPressed: () {
              _seekRelative(-10);
            },
          ),
          IconButton(
            icon: Icon(Icons.forward_10, color: Colors.white),
            onPressed: () {
              _seekRelative(10);
            },
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  _seekRelative(-10);
                },
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  _seekRelative(10);
                },
              ),
            ],
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Stack(
        children: [
          _isFullScreen
              ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size?.width ?? 0,
                height: _controller.value.size?.height ?? 0,
                child: VideoPlayer(_controller),
              ),
            ),
          )
              : OrientationBuilder(
            builder: (context, orientation) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildControls(),
                ],
              ),
            ),
          ),
          // Add content below the video and slider bar
          Positioned(
            bottom: 60, // Adjust the position as needed
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                'Additional content below the video and slider bar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isFullScreen;

  const FullScreenVideoPlayer({
    Key? key,
    required this.controller,
    required this.isFullScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isFullScreen
            ? Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayer(controller),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
              ),
            ),
          ],
        )
            : AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
