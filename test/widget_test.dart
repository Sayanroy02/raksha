import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:raksha_client/app/theme/app_theme.dart';
import 'package:raksha_client/app/widgets/feature_card.dart';

void main() {
  testWidgets('FeatureCard widget renders correctly with theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: FeatureCard(
            label: 'Live Location',
            subtitle: 'Share real-time GPS',
            icon: Icons.location_on,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Live Location'), findsOneWidget);
    expect(find.text('Share real-time GPS'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });
}
