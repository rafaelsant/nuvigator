import 'package:example/samples/navigation/samples_router.dart';
import 'package:flutter/material.dart';
import 'package:nuvigator/nuvigator.dart';

import 'samples/modules/sample_one/navigation/sample_one_router.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static final router = GlobalRouter(baseRouter: samplesRouter);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nubank',
      builder: Nuvigator(
        screenType: cupertinoDialogScreenType,
        router: router,
        initialRoute: SamplesRoutes.home,
      ),
    );
  }
}

class HomeScreen extends ScreenWidget {
  HomeScreen(BuildContext context) : super(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nuvigator Example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Hero(
            child: const FlutterLogo(),
            tag: 'HERO',
          ),
          FlatButton(
              child: const Text('Go to sample one with flutter navigation'),
              onPressed: () async {
                final result = await SamplesNavigation.of(context)
                    .sampleOneNavigation
                    .toScreenOne(testId: 'From Home');
                print('RESULT $result');
              }),
          FlatButton(
            child: const Text('Go to sample one with deepLink'),
            onPressed: () => GlobalRouter.of(context)
                .openDeepLink<void>(Uri.parse(screenOneDeepLink)),
          ),
          FlatButton(
            child: const Text('Go to sample two with flow'),
            onPressed: () async {
              SamplesNavigation.of(context).toSecond(testId: 'From Home');
            },
          ),
        ],
      ),
    );
  }
}
