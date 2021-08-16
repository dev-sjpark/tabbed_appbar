import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TabbedTest(),
    );
  }
}

class TabbedTest extends StatefulWidget {
  const TabbedTest({Key? key}) : super(key: key);

  @override
  _TabbedTestState createState() => _TabbedTestState();
}

class _TabbedTestState extends State<TabbedTest>
    with SingleTickerProviderStateMixin{

  static const int _INITIAL_INDEX = 0;

  late final TabController _tabController;

  late final AnimationController _tabAnimController;

  late Map<String, StreamController<double>> _tabStream;

  final List<String> _tabs = [
    'first tab',
    'second tab',
    'third tab',
  ];

  late final List<double> _opacities;

  double prevValue = _INITIAL_INDEX.toDouble();

  @override
  void initState() {
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _INITIAL_INDEX,
    );

    _opacities = _tabs.map((e) => 0.0).toList();
    _opacities[_INITIAL_INDEX] = 1.0;

    _tabStream = <String, StreamController<double>>{
      for (String e in _tabs) e : StreamController<double>()
    };

    AnimationController? anim = _tabController.animation as AnimationController?;
    if (anim != null) {
      _tabAnimController = anim..addListener(_tabScrollListener);
    }

    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      _sinksOpacities();
    });

    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabScrollListener);
    super.dispose();
  }

  void _tabScrollListener() {
    final value = _tabAnimController.value;
    if ((value - prevValue).abs() < 0.001 ) {
      return;
    } else {
      prevValue = value;
    }

    int quotient = value.floor();
    double remainder = value - quotient;

    if (remainder == 0) {
      _opacities.fillRange(0, _opacities.length, 0.0);
      _opacities[quotient] = 1.0;
    } else {
      _opacities[quotient] = 1.0 - remainder;
      if (quotient + 1 < _opacities.length) {
        _opacities[quotient + 1] = remainder;
      }
    }

    _sinksOpacities();
  }

  void _sinksOpacities() {
    for (int i = 0; i < _opacities.length; i++){
      _tabStream[_tabs[i]]!.sink.add(_opacities[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar,
      body: TabBarView(
        controller: _tabController,
        physics: ClampingScrollPhysics(),
        children: _tabs.map((e) => Container(
          child: Center(
            child: Text(e),
          ),
        )).toList(),
      ),
    );
  }

  AppBar get _appBar => AppBar(
    title: Stack(
      children: _tabs.map((e){
        return StreamBuilder<double>(
          initialData: 0.0,
          stream: _tabStream[e]!.stream,
          builder: (context, snapShot) {
            return Opacity(
              opacity: snapShot.data ?? 0.0,
              child: Center(
                child: Text(
                  e,
                ),
              ),
            );
          },
        );
      }).toList(),
    ),
    centerTitle: true,
    bottom: TabBar(
      controller: _tabController,
      physics: ClampingScrollPhysics(),
      tabs: _tabs.map((e) => Tab(
        text: e,
      )).toList(),
    ),
  );
}
