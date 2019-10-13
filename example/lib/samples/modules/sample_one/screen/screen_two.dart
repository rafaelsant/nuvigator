import 'package:example/samples/navigation/samples_router.dart';
import 'package:flutter/material.dart';
import 'package:nuvigator/nuvigator.dart';

class ScreenTwo extends ScreenWidget {
  ScreenTwo(BuildContext context) : super(context);

  static ScreenTwo builder(BuildContext context) {
    return ScreenTwo(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Two'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FlatButton(
              child: const Text('Open sample two flow'),
              onPressed: () => SamplesRouterNavigation.of(context)
                  .second(testId: 'From Sample One')),
        ],
      ),
    );
  }
}
