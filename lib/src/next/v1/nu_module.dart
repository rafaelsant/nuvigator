import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nuvigator/next.dart';
import 'package:nuvigator/src/nu_route_settings.dart';

import '../../deeplink.dart';
import '../../nurouter.dart';
import '../../screen_route.dart';

typedef NuWidgetRouteBuilder = Widget Function(
    BuildContext context, NuRoute nuRoute, NuRouteSettings<dynamic> settings);

typedef NuRouteParametersParser<A> = A Function(Map<String, dynamic>);

typedef NuInitFunction = Future<bool> Function(BuildContext context);

typedef ParamsParser<T> = T Function(Map<String, dynamic> map);

abstract class NuRoute<T extends NuModule, A extends Object, R extends Object> {
  T _module;

  T get module => _module;

  NuvigatorState get nuvigator => module.nuvigator;

  bool canOpen(String deepLink) => _parser.matches(deepLink);

  ParamsParser<A> get paramsParser => null;

  Future<bool> init(BuildContext context) {
    return SynchronousFuture(true);
  }

  // TBD
  bool get prefix => false;

  ScreenType get screenType;

  String get path;

  Widget build(BuildContext context, NuRouteSettings<A> settings);

  DeepLinkParser get _parser => DeepLinkParser<A>(
        template: path,
        prefix: prefix,
        argumentParser: paramsParser,
      );

  void _install(T module) {
    _module = module;
  }

  ScreenRoute<R> _screenRoute({
    String deepLink,
    Map<String, dynamic> extraParameters,
  }) {
    final settings =
        _parser.toNuRouteSettings(deepLink, parameters: extraParameters);
    return ScreenRoute(
      builder: (context) => build(context, settings),
      screenType: screenType,
      nuRouteSettings: settings,
    );
  }

  ScreenRoute<R> _tryGetScreenRoute({
    String deepLink,
    Map<String, dynamic> extraParameters,
  }) {
    if (canOpen(deepLink)) {
      _screenRoute(
        deepLink: deepLink,
        extraParameters: extraParameters,
      );
    }
    return null;
  }
}

class NuRouteBuilder<A extends Object, R extends Object>
    extends NuRoute<NuModule, A, R> {
  NuRouteBuilder({
    @required String path,
    @required this.builder,
    this.initializer,
    this.parser,
    ScreenType screenType,
    bool prefix = false,
  })  : _path = path,
        _prefix = prefix,
        _screenType = screenType;

  final String _path;
  final NuInitFunction initializer;
  final NuRouteParametersParser<A> parser;
  final bool _prefix;
  final ScreenType _screenType;
  final NuWidgetRouteBuilder builder;

  @override
  Future<bool> init(BuildContext context) {
    if (initializer != null) {
      return initializer(context);
    }
    return super.init(context);
  }

  @override
  ParamsParser<A> get paramsParser => _parseParameters;

  A _parseParameters(Map<String, dynamic> map) =>
      parser != null ? parser(map) : null;

  @override
  Widget build(BuildContext context, NuRouteSettings<Object> settings) {
    return builder(context, this, settings);
  }

  @override
  bool get prefix => _prefix;

  @override
  String get path => _path;

  @override
  ScreenType get screenType => _screenType;
}

abstract class NuModule {
  List<NuRoute> _routes;

  // List<NuModule> _subModules;
  NuModuleRouter _router;
  List<NuRouter> _legacyRouters;

  /// InitilRoute that is going to be rendered
  String get initialRoute;

  /// NuRoutes to be registered in this Module
  List<NuRoute> get registerRoutes;

  /// Retrocompatibility with old routers API
  List<NuRouter> get legacyRouters => [];

  // List<NuModule> get registerModules => [];

  /// ScreenType to be used by the [NuRoute] registered in this Module
  /// ScreenType defined on the [NuRoute] takes precedence over the default one
  /// declared in the [NuModule]
  ScreenType get screenType => null;

  List<NuRoute> get routes => _routes;

  // TODO: Evaluate the need for subModules
  // List<NuModule> get subModules => _subModules;

  NuvigatorState get nuvigator => _router.nuvigator;

  /// While the module is initializing this Widget is going to be displayed
  Widget loadingWidget(BuildContext context) => Container();

  /// Override to perform some processing/initialization when this module
  /// is first initialized into a [Nuvigator].
  Future<void> init(BuildContext context) async {}

  /// A common wrapper that is going to be applied to all Routes returned by
  /// this Module.
  Widget routeWrapper(BuildContext context, Widget child) {
    return child;
  }

  Future<void> _initModule(BuildContext context, NuModuleRouter router) async {
    assert(_router == null);
    _router = router;
    _legacyRouters = legacyRouters;
    await init(context);
    _routes = registerRoutes;
    await Future.wait(_routes.map((route) async {
      // Route should not be installed to another module
      assert(route._module == null);
      route._install(this);
      await route.init(context);
    }).toList());
    // await Future.wait(_subModules.map((module) async {
    //   return module._initModule(context, router);
    // }));
  }

  ScreenRoute<R> _getScreenRoute<R>(String deepLink,
      {Map<String, dynamic> parameters}) {
    for (final route in routes) {
      final screenRoute = route._tryGetScreenRoute(
        deepLink: deepLink,
        extraParameters: parameters,
      );
      if (screenRoute != null) return screenRoute;
    }
    // TODO: Evaluate the need for subModules
    // for (final subModule in subModules) {
    //   return subModule
    //       ._getScreenRoute(deepLink, parameters: parameters)
    //       ?.wrapWith(routeWrapper);
    // }
    return null;
  }
}

class NuModuleBuilder extends NuModule {
  NuModuleBuilder({
    @required String initialRoute,
    @required List<NuRoute> routes,
    ScreenType screenType,
    WidgetBuilder loadingWidget,
    NuInitFunction init,
  })  : _initialRoute = initialRoute,
        _registerRoutes = routes,
        _screenType = screenType,
        _loadingWidget = loadingWidget,
        _init = init;

  final String _initialRoute;
  final List<NuRoute> _registerRoutes;
  final ScreenType _screenType;
  final WidgetBuilder _loadingWidget;
  final NuInitFunction _init;

  @override
  String get initialRoute => _initialRoute;

  @override
  List<NuRoute> get registerRoutes => _registerRoutes;

  @override
  ScreenType get screenType => _screenType;

  @override
  Widget loadingWidget(BuildContext context) {
    if (_loadingWidget != null) {
      return _loadingWidget(context);
    }
    return Container();
  }

  @override
  Future<void> init(BuildContext context) {
    if (_init != null) {
      return _init(context);
    }
    return super.init(context);
  }
}

class NuModuleRouter<T extends NuModule> extends NuRouter {
  NuModuleRouter(this.module);

  final T module;

  Future<NuModuleRouter> _initModule(BuildContext context) async {
    await module._initModule(context, this);
    return this;
  }

  @override
  @deprecated
  RouteEntry getRouteEntryForDeepLink(String deepLink) {
    throw UnimplementedError(
        'getRouteEntryForDeepLink is deprecated and not implemented for NuModule API');
  }

  @override
  bool canOpenDeepLink(Uri url) {
    return getRoute<dynamic>(url.toString()) != null;
  }

  @override
  @deprecated
  Future<R> openDeepLink<R>(Uri url,
      [dynamic arguments, bool isFromNative = false]) {
    return nuvigator.open<R>(url.toString(), parameters: arguments);
  }

  @override
  Route<R> getRoute<R>(
    String deepLink, {
    Map<String, dynamic> parameters,
    ScreenType fallbackScreenType,
  }) {
    final route = module
        ._getScreenRoute<R>(deepLink,
            parameters: parameters ?? <String, dynamic>{})
        ?.fallbackScreenType(fallbackScreenType)
        ?.toRoute();
    if (route != null) return route;
    for (final legacyRouter in module._legacyRouters) {
      final r = legacyRouter.getRoute<R>(
        deepLink,
        parameters: parameters,
        fallbackScreenType: fallbackScreenType,
      );
      if (r != null) return r;
    }
    return null;
  }
}

class NuModuleLoader extends StatefulWidget {
  const NuModuleLoader({Key key, this.module, this.builder}) : super(key: key);

  final NuModule module;
  final Widget Function(NuModuleRouter router) builder;

  @override
  _NuModuleLoaderState createState() => _NuModuleLoaderState();
}

class _NuModuleLoaderState extends State<NuModuleLoader> {
  bool loading;
  NuModuleRouter router;

  void _initModule() {
    setState(() {
      loading = true;
    });
    router = NuModuleRouter(widget.module);
    router._initModule(context).then((value) {
      setState(() {
        loading = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant NuModuleLoader oldWidget) {
    if (oldWidget.module != widget.module) {
      _initModule();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _initModule();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return widget.module.loadingWidget(context);
    }
    return widget.builder(router);
  }
}
