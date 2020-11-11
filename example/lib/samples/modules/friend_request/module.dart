import 'package:nuvigator/nuvigator.dart';

import 'screens/list_requests_screen.dart';
import 'screens/success_screen.dart';

abstract class ListFriendRequestDelegate extends NuModuleRouter {}

class ListFriendRequestModule
    extends NuRouteModule<ListFriendRequestDelegate, void, void> {
  ListFriendRequestModule(ListFriendRequestDelegate delegate) : super(delegate);

  @override
  String get path => 'deepprefix/friendRequests/list';

  @override
  ScreenRoute<Object> getRoute(NuRouteMatch<Object> match) {
    return ScreenRoute(
      builder: (context) => ListRequestScreen(
        toSuccess: () => delegate.nuvigator.openDeepLink<void>(Uri.parse('')),
      ),
      screenType: materialScreenType,
    );
  }
}

abstract class FriendRequestSuccessDelegate extends NuModuleRouter {}

class FriendRequestSuccessModule
    extends NuRouteModule<FriendRequestSuccessDelegate, void, void> {
  FriendRequestSuccessModule(FriendRequestSuccessDelegate delegate)
      : super(delegate);

  @override
  String get path => 'deepprefix/friendRequests/success';

  @override
  ScreenRoute<void> getRoute(NuRouteMatch<void> match) {
    return ScreenRoute(
      builder: (context) => SuccessScreen(
        closeFlow: () => delegate.nuvigator.closeFlow(),
        toComposeText: () =>
            delegate.nuvigator.openDeepLink<void>(Uri.parse('')),
      ),
      screenType: materialScreenType,
    );
  }
}

class FriendRequestModuleRouter extends NuModuleRouter
    implements ListFriendRequestDelegate, FriendRequestSuccessDelegate {
  @override
  String get initialRoute => 'deepprefix/friendRequests/list';

  @override
  List<NuRouteModule> get modules => [
        ListFriendRequestModule(this),
        FriendRequestSuccessModule(this),
      ];
}
