import 'package:home_widget/home_widget.dart';

// Home screen widget service — Flutter side only.
// Native Android XML setup is a manual step (see docs/MANUAL_STEPS.md).
class HomeWidgetService {
  static const _appGroupId = 'com.littlesteps.little_steps';
  static const _widgetName = 'LittleStepsWidget';

  static Future<void> initialize() async {
    HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  static Future<void> updateWidget({
    required String babyName,
    required String photoUrl,
    required String latestDate,
  }) async {
    await HomeWidget.saveWidgetData<String>('baby_name', babyName);
    await HomeWidget.saveWidgetData<String>('photo_url', photoUrl);
    await HomeWidget.saveWidgetData<String>('latest_date', latestDate);
    await HomeWidget.updateWidget(
      androidName: _widgetName,
    );
  }

  // Called when widget is tapped (runs in background isolate)
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    // Navigate to home when widget is tapped — handled by HomeWidget.widgetClicked
  }

  static Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;
}
