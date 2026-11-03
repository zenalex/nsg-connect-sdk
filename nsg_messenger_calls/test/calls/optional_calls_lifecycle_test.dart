import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';
import 'package:nsg_messenger_calls/nsg_messenger_calls.dart';

class _UnusedMedia extends Fake implements WebRtcAdapter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(NsgMessenger.dispose);

  test('core demo session has no calling module or controllers', () async {
    await NsgMessenger.initDemo(rooms: const []);
    expect(NsgMessenger.isInitialized, isTrue);
    expect(NsgMessenger.callsFeature, isNull);
    expect(NsgMessengerCalls.callControllerOrNull, isNull);
    expect(NsgMessengerCalls.conferenceCallsOrNull, isNull);
    expect(() => NsgMessengerCalls.callController, throwsStateError);
  });

  test(
    'account teardown removes old subscriptions and next session attaches fresh controllers',
    () async {
      for (final userId in [42, 99]) {
        await NsgMessenger.initDemo(rooms: const []);
        final events = StreamController<MessengerEvent>.broadcast();
        final client = Client('https://example.invalid/');
        final feature = NsgMessengerCalls.feature(
          webRtcAdapter: _UnusedMedia(),
        );
        feature.attach(
          MessengerCallsContext(
            client: client,
            events: events.stream,
            selfMessengerUserId: () => userId,
            authenticated: <T>(Future<T> Function() request) => request(),
          ),
        );
        MessengerRuntime.instance.debugSetCallsFeature(feature);
        final call = NsgMessengerCalls.callController;
        final conference = NsgMessengerCalls.conferenceCalls;
        expect(events.hasListener, isTrue);
        expect(call.state, isA<CallIdle>());
        expect(conference.state, isA<ConferenceCallIdle>());
        expect(feature.isBusy, isFalse);

        await NsgMessenger.dispose();
        expect(NsgMessenger.callsFeature, isNull);
        expect(NsgMessengerCalls.callControllerOrNull, isNull);
        expect(NsgMessengerCalls.conferenceCallsOrNull, isNull);
        expect(events.hasListener, isFalse);
        expect(() => call.addListener(() {}), throwsFlutterError);
        expect(() => conference.addListener(() {}), throwsFlutterError);
        expect(
          () => feature.attach(
            MessengerCallsContext(
              client: client,
              events: events.stream,
              selfMessengerUserId: () => userId,
              authenticated: <T>(Future<T> Function() request) => request(),
            ),
          ),
          throwsStateError,
        );
        await events.close();
        client.close();
      }
    },
  );
}
