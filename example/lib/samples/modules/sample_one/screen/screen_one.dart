import 'package:example/samples/modules/sample_one/navigation/sample_one_router.dart';
import 'package:flutter/material.dart';
import 'package:nuvigator/nuvigator.dart';

class ScreenOne extends ScreenWidget {
  ScreenOne(BuildContext context) : super(context);

  static ScreenOne builder(BuildContext context) {
    return ScreenOne(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen One'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => nuvigator.maybePop(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'testId = ${ScreenOneArgs.of(context).testId}',
            textAlign: TextAlign.center,
          ),
          FlatButton(
            child: const Text('Go to screen two'),
            onPressed: () => SampleOneRouterNavigation.of(context).screenTwo(),
          ),
          Hero(
            child: const FlutterLogo(),
            tag: 'HERO',
          ),
        ],
      ),
    );
  }
}
