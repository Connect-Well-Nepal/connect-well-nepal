// Basic widget test for Connect Well Nepal app
//
// This test verifies that the app launches successfully
// and displays the splash screen, then navigates to main screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connect_well_nepal/main.dart';

void main() {
  testWidgets('Connect Well Nepal app launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConnectWellNepalApp());

    // Verify that we start with the splash screen
    expect(find.text('Connect Well'), findsOneWidget);
    expect(find.text('Nepal'), findsOneWidget);
    expect(find.text('Your Health, Our Priority'), findsOneWidget);
    
    // Wait for splash screen navigation (2 seconds + animation)
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Verify that we've navigated to the main screen
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify that the navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    
    // Verify that we start on the Home tab
    expect(find.text('Connect Well Nepal'), findsOneWidget);
  });
}
