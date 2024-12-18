import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYNKODOT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SYNKODOT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class CircleProps {
  int left;
  int top;
  Color color;
  double size;

  CircleProps(this.left, this.top, this.color, this.size);
}

class ResultSet {
  DateTime result;
  double xy;
  double z;
  double tot;

  ResultSet(this.result, this.xy, this.z, this.tot);
}

class _MyHomePageState extends State<MyHomePage> {
  var circles = <CircleProps>[];
  double circleSize = 40.0;
  double circleWiper = 42.0;
  List _dots = [];
  List _recorded = [];
  double _gamesize = 500;
  String _gameMessage = "Loading";
  String _gameState = "loading";
  String _timer = "0";
  double _xytotal = 0;
  double _ztotal = 0;
  double _xyscore = 0;
  double _zscore = 0;
  double _finalScore = 0;
  double _xyTodayHigh = -1.0;
  double _zTodayHigh = -1.0;
  double _todayHigh = -1.0;
  double _xyAllHigh = -1.0;
  double _zAllHigh = -1.0;
  double _allHigh = -1.0;
  DateTime _now = DateTime.now();
  DateTime _dtToday = DateTime.now();
  
  // Fetch content from the json file
  Future<void> readJson() async {    
    final String response = await rootBundle.loadString('assets/gamedef.json');
    final data = await json.decode(response);
    setState(() {
      _dots = data["dots"];
    });
  }

  Future<void> getPreviousResults() async {
    final prefs = await SharedPreferences.getInstance();
    _xyTodayHigh = prefs.getDouble('xyHigh') ?? -1.0;
    _zTodayHigh = prefs.getDouble('zHigh') ?? -1.0;
    _todayHigh = prefs.getDouble('totHigh') ?? -1.0;
  }

  Future<void> startGame() async {
    _gameState = "running";
    circles = [];
    await Future.delayed(const Duration(milliseconds: 750));
    setState(() {
      _timer = '0.0'; 
    });
    for (var i = 3; i > 0; i--) {
      setState(() {
        _gameMessage = '$i';
      });
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    setState(() {
      _gameMessage = '';
    });
    await Future.delayed(const Duration(milliseconds: 750));
    await _runDots();
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _gameMessage = 'Your turn';
    });
    await Future.delayed(const Duration(milliseconds: 2000));
    
    setState(() {
      _gameState = "yourturn";
      _timer = '0.0'; 
    });
    await checkPlayerRes();
    await Future.delayed(const Duration(milliseconds: 2000));
    
    setState(() {
      _gameState = "showresult";
    });
    //_showResults();
    await _showResults();
  }

  double hypot(double x, double y) {
    return sqrt(x * x + y * y);
  }

  void donothing() {

  }

  void setGameState(String newState) {
    if (newState == "ready") {
      setState(() {
        circles = [];
        _recorded = [];
        _xytotal = 0;
        _ztotal = 0;
        _timer = "0.0";
        _now = DateTime.now();
        _dtToday = DateTime(_now.year, _now.month, _now.day);
      });
    }
    print('setGameState: $_dtToday');
    setState(() {
      _gameState = "ready";
      _gameMessage = "ready";
    });
  }

  Future<bool> checkPlayerRes() async {
    while (_recorded.length < 5) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return true;
  }

  Future<void> _runDots() async {
    var blue = Colors.blue;
    print("_runDots: Game in play");
    _showTime(5);
    for (var dot in _dots) {   
      int left = (double.parse(dot["x"]) * _gamesize - circleSize / 2).round();
      int top = (double.parse(dot["y"]) * _gamesize - circleSize / 2).round();
      int waitForNext = int.parse(dot["z"]);
      await Future.delayed(Duration(milliseconds: waitForNext));
      circles.add(CircleProps(left, top, blue, circleSize));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
      var white = Colors.white;
      print('_runDots: id: ${dot["id"]} X: $left Y: $top Z: $waitForNext'); 
      circles.add(CircleProps((left - 1.0).toInt(), (top - 1.0).toInt(), white, circleWiper));
      setState(() {});
    }
    circles = [];
  }

  Future<void> _runDotsRes() async {
    var blue = Colors.blue;
    _showTime(10);
    for (var dot in _dots) {   
      int left = (double.parse(dot["x"]) * _gamesize - circleSize / 2).round();
      int top = (double.parse(dot["y"]) * _gamesize - circleSize / 2).round();
      int waitForNext = int.parse(dot["z"]);
      await Future.delayed(Duration(milliseconds: waitForNext));
      circles.add(CircleProps(left, top, blue, circleSize));
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _showTime(int x) async {
    for (var i = 0; i <= x; i++) {
      if(i < x) {
        for (var j = 0; j < 10; j++) {
          setState(() {
            _timer = '$i.$j'; 
          });
          await Future.delayed(Duration(milliseconds: 100));
        }
      } else {
        setState(() {
          _timer = '$i.0'; 
        });
      }
    }
  }

  Future<void> _showResults() async {
    var blue = const Color.fromARGB(170, 0, 100, 255);
    var green = const Color.fromARGB(170, 60, 126, 60);
    var white = Colors.white;
    
    print("_showResults: Showing the final results");
    circles.add(CircleProps(0, 0, white, 1.0));
    await Future.delayed(const Duration(milliseconds: 500));

    List expected = [];
    int intExpID = 0;
    for (var dot in _dots) {
      int left = (double.parse(dot["x"]) * _gamesize).round();
      int top = (double.parse(dot["y"]) * _gamesize).round();
      int totalTime = 0;
      print("_showResults: Printing dots"); 
      for (int i = 0; i <= intExpID; i++) {
        print('_showResults: ${_dots[i]}');
        totalTime += int.parse(_dots[i]['z']);
      }
      intExpID++;
      String strExpID = 'e$intExpID';
      Map<String, String> exp  = {
        'id': strExpID, 
        'x': '$left', 
        'y': '$top', 
        'z': '${dot['z']}', 
        'total': '$totalTime'
      };
      expected.add(exp);
      print("_showResults: Expected: $exp");
    }

    List played = [];
    int intPlyID = 0;
    for (var record in _recorded) {
      int duration = 0;
      int totalTime = 0;
      if (intPlyID > 0) {
        duration = record[2] - _recorded[intPlyID - 1][2];
        totalTime = record[2] - _recorded[0][2];
      }
      intPlyID++;
      String strPlyID = 'r$intPlyID';
      double zdiff = 0;
      double xydiff = 0.0; 
      for (var dot in expected) {
        if (dot['id'] == 'e$intPlyID') {
          xydiff = min(hypot(
              (double.parse(dot['x']) - record[0]),
              (double.parse(dot['y']) - record[1])
            ) / _gamesize*20, 10);
          zdiff = min((duration - int.parse(dot['z']))/1000*12.5, 12.5);
          _xytotal += xydiff;
          _ztotal += zdiff.abs();
        }
      }

      Map<String, String> ply = {
        'id': strPlyID, 
        'x': '${record[0]}', 
        'y': '${record[1]}', 
        'z': '$duration', 
        'total': '$totalTime',
        'xydiff' : '$xydiff',
        'zdiff' : '$zdiff'
      };
      played.add(ply);
      print('_showResults: $ply');
    } 

    int lastDot = max(int.parse(expected[4]['total']),int.parse(played[4]['total']));

    List results = [];
    int currentTime = 0;
    for (int t = 0; t <= lastDot; t++) {
      for (var ply in played) {
        if (int.parse(ply['total']) == t) {
          int dur = t - currentTime;
          ply['z'] = '$dur';
          results.add(ply);
          currentTime = t;
        }
      }
    }

    _runDotsRes();
    for (var dot in results) {
      double cs = circleSize;
      var col = blue;
      if (dot['id'].toString().startsWith('r')) {
        cs += (double.parse(dot['zdiff']) * 4);
        if (cs > 100) { cs = 100; }
        if (cs < 2) { cs = 2; }
        col = green;
      }
      int left = (double.parse(dot["x"]) - (cs / 2)).round();
      int top = (double.parse(dot["y"]) - (cs / 2)).round();
      int waitForNext = int.parse(dot["z"]);
      print('_runDotsRes: $dot');
      await Future.delayed(Duration(milliseconds: waitForNext));
      circles.add(CircleProps(left, top, col, cs));
      setState(() {});
    }

    setState(() {
      _xyscore = _xytotal;
      _zscore = _ztotal;
      _finalScore = max(100 - (_xyscore + _zscore), 0);
      _gameState = "showresultfinal";
    });

    print('_runDotsRes: Scores - Final: $_finalScore Today: $_todayHigh Best: $_allHigh');
    if (_finalScore > _todayHigh) {
      final prefs = await SharedPreferences.getInstance();
      _xyTodayHigh = _xyscore;
      _zTodayHigh = _zscore;
      _todayHigh = _finalScore;
      prefs.setDouble('xyHigh', _xyTodayHigh);
      prefs.setDouble('zHigh', _zTodayHigh);
      prefs.setDouble('totHigh', _todayHigh);
      prefs.setString('TodayHigh', "D:${_dtToday.year-_dtToday.month-_dtToday.day}XY:$_xyTodayHigh;Z:$_zTodayHigh;T:$_todayHigh");
    }
    if (_finalScore > _allHigh) {
      final prefs = await SharedPreferences.getInstance();
      _xyAllHigh = _xyscore;
      _zAllHigh = _zscore;
      _allHigh = _finalScore;
      prefs.setString('AllHigh', "D:${_dtToday.year-_dtToday.month-_dtToday.day};XY:$_xyTodayHigh;Z:$_zTodayHigh;T:$_todayHigh");
    }
    setState(() {});
  }

  Widget recordDots(BuildContext context) {  
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (_recorded.isEmpty) {
          _showTime(5);
        }
        double x = details.localPosition.dx;
        double y = details.localPosition.dy;
        int z = DateTime.now().millisecondsSinceEpoch;
        List playerTry = [x, y, z];
        setState(() {
          _recorded.add(playerTry);
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    readJson();
    getPreviousResults();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double gamesize = width - 20;
    
    if (gamesize > 520.0) {
      gamesize = 500.0;
    }
    
    setState(() {
      _gamesize = gamesize;
    });
    
    if (_dots.length == 5 && (_gameState != "running" && _gameState != "yourturn" && _gameState != "showresult" && _gameState != "showresultfinal")) {
      setGameState("ready");
    }

    return Container(
      margin: const EdgeInsets.all(0.0),
      color: Colors.grey,
      width: width,
      height: height,
      child: Center(
        child: Column(
          children: [
            const DefaultTextStyle(
              style: TextStyle(
                  fontSize: 45,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                  ),
              child: Text(
                '',
                textAlign: TextAlign.center
              )
            ),
            DefaultTextStyle(
              style: TextStyle(
                  fontSize: _gamesize/6,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                  ),
              child: const Text(
                'SYNKODOT',
                textAlign: TextAlign.center
              )
            ),
            DefaultTextStyle(
              style: TextStyle(
                  fontSize: _gamesize / 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                  ),
              child: Text(
                _timer,
                textAlign: TextAlign.center
              )
            ),
            GestureDetector(
              onTap: () { 
                _gameState == "ready" ?
                  startGame()
                  : _gameState == "showresultfinal" ?
                    setGameState("ready")
                    : donothing();
              },
              child: Container(
                margin: const EdgeInsets.all(10.0),
                color: Colors.white,
                width: _gamesize,
                height: _gamesize,
                child: Stack(
                  children: 
                    circles.isEmpty || _gameState == "yourturn" ?
                    [Center(
                      child: 
                        _gameState != "yourturn" ?
                        DefaultTextStyle(
                          style: TextStyle(
                              fontSize: _gamesize/5,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                              ),
                          child: Text(
                          _gameMessage,
                          textAlign: TextAlign.center),
                        )
                        : _recorded.length < 5 ?
                          recordDots(context)
                          : DefaultTextStyle(
                            style: TextStyle(
                                fontSize: _gamesize/8,
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                                ),
                            child: const Text(
                              "Result",
                              textAlign: TextAlign.center
                            ),
                          )
                      )]
                      : circles
                        .map<Widget>((e) => Positioned(
                            left: e.left.toDouble(), // distance between this child's left edge & left edge of stack
                            top: e.top.toDouble(), // distance between this child's top edge & top edge of stack
                            child: Container(
                              height: e.size,
                              width: e.size,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                        )).toList()
                ),
              ),
            ),
            /*DefaultTextStyle(
              style: TextStyle(
                  fontSize: _gamesize/16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                  ),
              child: Text('game size: $_gamesize', textAlign: TextAlign.center),
            ),*/
            _gameState != "showresultfinal" ?
              const Text ('')
              : DefaultTextStyle(
                style: TextStyle(
                    fontSize: _gamesize/12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                    ),
                child: Text('XY: ${_xyscore.toStringAsFixed(2)} Z: ${_zscore.toStringAsFixed(2)} T: ${_finalScore.toStringAsFixed(2)}', textAlign: TextAlign.center),
              ),
            Expanded(
              child: Container(),
            ),
            _todayHigh < 0 ?
              const Text ('')
              : DefaultTextStyle(
                style: TextStyle(
                    fontSize: _gamesize/12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                    ),
                child: Text('TODAY HIGH:\r\nXY: ${_xyTodayHigh.toStringAsFixed(2)} Z: ${_zTodayHigh.toStringAsFixed(2)} T: ${_todayHigh.toStringAsFixed(2)}', textAlign: TextAlign.center),
              ),
            _todayHigh < 0 ?
              const Text ('')
              : DefaultTextStyle(
                style: TextStyle(
                    fontSize: _gamesize/12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                    ),
                child: Text('ALL TIME HIGH:\r\nXY: ${_xyAllHigh.toStringAsFixed(2)} Z: ${_zAllHigh.toStringAsFixed(2)} T: ${_allHigh.toStringAsFixed(2)}', textAlign: TextAlign.center),
              )
          ]   //Column Children
        )
      )
    );
  }
}