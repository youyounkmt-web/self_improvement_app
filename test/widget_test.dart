import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:self_improvement_app/main.dart'; // あなたのmain.dartをインポート

void main() {
  testWidgets('スタート画面にタイトルとボタンが表示されるかテスト', (WidgetTester tester) async {
    // あなたのアプリ（MyApp）をビルドしてフレームをトリガーします。
    await tester.pumpWidget(const MyApp(isSurveyDone: false));

    // '自分磨き（仮）'というテキストを持つウィジェットが1つ存在することを確認します。
    expect(find.text('自分磨き（仮）'), findsOneWidget);

    // 'START'というテキストを持つウィジェットが1つ存在することを確認します。
    expect(find.text('START'), findsOneWidget);

    // カレンダーアイコンが表示されることを確認します。
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
  });

  testWidgets('STARTボタンをタップするとカレンダー画面に遷移するかテスト', (WidgetTester tester) async {
    // アプリをビルドします。
    await tester.pumpWidget(const MyApp(isSurveyDone: false));

    // STARTボタンをタップします。
    await tester.tap(find.text('START'));

    // ウィジェットが新しい画面に切り替わるまで待機します。
    await tester.pumpAndSettle();

    // カレンダーアプリバーのタイトルが表示されることを確認します。
    expect(find.text('カレンダーアプリ'), findsOneWidget);
  });
}
