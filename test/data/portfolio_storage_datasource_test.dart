import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:linkstage/data/datasources/portfolio_storage_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fast_image_compress/fast_image_compress.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class _FakeFastImageCompress extends Mock implements FastImageCompress {}

void main() {
  group('PortfolioStorageDataSource', () {
    setUpAll(() {
      registerFallbackValue(Uint8List.fromList([1]));
      registerFallbackValue(ImageQuality.medium);
    });

    late MockFirebaseAuth auth;
    late MockUser user;

    setUp(() {
      auth = MockFirebaseAuth();
      user = MockUser();
    });

    test('uploadProfilePhoto throws when not authenticated', () async {
      when(() => auth.currentUser).thenReturn(null);

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async => http.Response('{}', 500),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'a.jpg');
      await expectLater(
        () => ds.uploadProfilePhoto(file, 'u1'),
        throwsA(isA<Exception>()),
      );
    });

    test('uploadProfilePhoto throws when file bytes empty', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async => http.Response('{}', 200),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List(0), name: 'a.jpg');
      await expectLater(
        () => ds.uploadProfilePhoto(file, 'u1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Could not read image file'),
          ),
        ),
      );
    });

    test(
      'uploadProfilePhoto requests signed url and uploads to signed url',
      () async {
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');
        final compressor = _FakeFastImageCompress();
        when(
          () => compressor.compressImage(
            imageData: any(named: 'imageData'),
            quality: any(named: 'quality'),
            targetWidth: any(named: 'targetWidth'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenAnswer((inv) async {
          final data = inv.namedArguments[#imageData] as Uint8List;
          return data.isEmpty ? Uint8List.fromList([1]) : data;
        });

        Uri? gotUrl;
        Object? gotBody;
        var uploadCalls = 0;
        String? uploadPath;
        String? uploadToken;
        Uint8List? uploadBytes;

        final ds = PortfolioStorageDataSource(
          firebaseAuth: auth,
          getUploadUrlUrl: 'https://example.com/get-upload-url',
          httpPost: (url, {headers, body}) async {
            gotUrl = url;
            gotBody = body;
            return http.Response(
              '{"path":"p","token":"t","publicUrl":"https://public/u"}',
              200,
            );
          },
          uploadBinaryToSignedUrl: (path, token, bytes) async {
            uploadCalls++;
            uploadPath = path;
            uploadToken = token;
            uploadBytes = bytes;
          },
          // Bypass native compression plugin in tests.
          imageCompress: compressor,
        );

        final file = XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'a.jpg',
        );
        final url = await ds.uploadProfilePhoto(file, 'u1');

        expect(url, 'https://public/u');
        expect(gotUrl.toString(), 'https://example.com/get-upload-url');
        expect(gotBody, isA<String>());
        expect(gotBody as String, contains('"type":"profile"'));
        expect(uploadCalls, 1);
        expect(uploadPath, 'p');
        expect(uploadToken, 't');
        expect(uploadBytes, isNotNull);
        expect(uploadBytes, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      '_getSignedUploadUrl surfaces JSON error message on non-200',
      () async {
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

        final ds = PortfolioStorageDataSource(
          firebaseAuth: auth,
          getUploadUrlUrl: 'https://example.com/get-upload-url',
          httpPost: (url, {headers, body}) async =>
              http.Response('{"error":"nope"}', 401),
          uploadBinaryToSignedUrl: (_, _, _) async {},
        );

        final file = XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg');
        await expectLater(
          () => ds.uploadPortfolioMedia(file, 'u1', isVideo: true),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('nope'),
            ),
          ),
        );
      },
    );

    test('uploadPortfolioMedia (image) compresses and uploads', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

      final compressor = _FakeFastImageCompress();
      var compressCalls = 0;
      when(
        () => compressor.compressImage(
          imageData: any(named: 'imageData'),
          quality: any(named: 'quality'),
          targetWidth: any(named: 'targetWidth'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((inv) async {
        compressCalls++;
        final data = inv.namedArguments[#imageData] as Uint8List;
        return Uint8List.fromList([...data, 9]);
      });

      var uploadCalls = 0;
      Uint8List? uploaded;
      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        imageCompress: compressor,
        getUploadUrlUrl: 'https://example.com/get-upload-url',
        httpPost: (url, {headers, body}) async => http.Response(
          '{"path":"p","token":"t","publicUrl":"https://public/u"}',
          200,
        ),
        uploadBinaryToSignedUrl: (path, token, bytes) async {
          uploadCalls++;
          uploaded = bytes;
        },
      );

      final file = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'a.jpg');
      final url = await ds.uploadPortfolioMedia(file, 'u1', isVideo: false);

      expect(url, 'https://public/u');
      expect(compressCalls, 1);
      expect(uploadCalls, 1);
      expect(uploaded, isNotNull);
      expect(uploaded, isNot(equals(Uint8List.fromList([1, 2, 3]))));
    });

    test(
      'uploadProfilePhoto throws on invalid signed-url response (missing token)',
      () async {
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

        final compressor = _FakeFastImageCompress();
        when(
          () => compressor.compressImage(
            imageData: any(named: 'imageData'),
            quality: any(named: 'quality'),
            targetWidth: any(named: 'targetWidth'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenAnswer(
          (inv) async => inv.namedArguments[#imageData] as Uint8List,
        );

        final ds = PortfolioStorageDataSource(
          firebaseAuth: auth,
          imageCompress: compressor,
          getUploadUrlUrl: 'https://example.com/get-upload-url',
          httpPost: (url, {headers, body}) async =>
              http.Response('{"path":"p","publicUrl":"https://public/u"}', 200),
          uploadBinaryToSignedUrl: (_, _, _) async {},
        );

        final file = XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'a.jpg',
        );
        await expectLater(
          () => ds.uploadProfilePhoto(file, 'u1'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid response from upload service'),
            ),
          ),
        );
      },
    );

    test('non-200 response with non-JSON body surfaces body text', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        getUploadUrlUrl: 'https://example.com/get-upload-url',
        httpPost: (url, {headers, body}) async =>
            http.Response('nope-nope', 500),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg');
      await expectLater(
        () => ds.uploadPortfolioMedia(file, 'u1', isVideo: true),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('nope-nope'),
          ),
        ),
      );
    });

    test('uploadPortfolioMedia throws when token is null', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => null);

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async => http.Response('{}', 200),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg');
      await expectLater(
        () => ds.uploadPortfolioMedia(file, 'u1', isVideo: true),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Not authenticated'),
          ),
        ),
      );
    });

    test(
      'uploadProfilePhoto throws when signed-url response missing publicUrl',
      () async {
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

        final compressor = _FakeFastImageCompress();
        when(
          () => compressor.compressImage(
            imageData: any(named: 'imageData'),
            quality: any(named: 'quality'),
            targetWidth: any(named: 'targetWidth'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenAnswer(
          (inv) async => inv.namedArguments[#imageData] as Uint8List,
        );

        final ds = PortfolioStorageDataSource(
          firebaseAuth: auth,
          imageCompress: compressor,
          getUploadUrlUrl: 'https://example.com/get-upload-url',
          httpPost: (url, {headers, body}) async =>
              http.Response('{"path":"p","token":"t"}', 200),
          uploadBinaryToSignedUrl: (_, _, _) async {},
        );

        final file = XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'a.jpg',
        );
        await expectLater(
          () => ds.uploadProfilePhoto(file, 'u1'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No public URL in response'),
            ),
          ),
        );
      },
    );

    test('uploadPortfolioMedia (video) does not call compressor', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

      final compressor = _FakeFastImageCompress();
      when(
        () => compressor.compressImage(
          imageData: any(named: 'imageData'),
          quality: any(named: 'quality'),
          targetWidth: any(named: 'targetWidth'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => Uint8List.fromList([9]));

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        imageCompress: compressor,
        getUploadUrlUrl: 'https://example.com/get-upload-url',
        httpPost: (url, {headers, body}) async => http.Response(
          '{"path":"p","token":"t","publicUrl":"https://public/u"}',
          200,
        ),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'v.mp4');
      await ds.uploadPortfolioMedia(file, 'u1', isVideo: true);

      verifyNever(
        () => compressor.compressImage(
          imageData: any(named: 'imageData'),
          quality: any(named: 'quality'),
          targetWidth: any(named: 'targetWidth'),
          imageQuality: any(named: 'imageQuality'),
        ),
      );
    });

    test('uploadProfilePhoto throws when compression returns null', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

      final compressor = _FakeFastImageCompress();
      when(
        () => compressor.compressImage(
          imageData: any(named: 'imageData'),
          quality: any(named: 'quality'),
          targetWidth: any(named: 'targetWidth'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => null);

      final ds = PortfolioStorageDataSource(
        firebaseAuth: auth,
        imageCompress: compressor,
        getUploadUrlUrl: 'https://example.com/get-upload-url',
        httpPost: (url, {headers, body}) async => http.Response(
          '{"path":"p","token":"t","publicUrl":"https://public/u"}',
          200,
        ),
        uploadBinaryToSignedUrl: (_, _, _) async {},
      );

      final file = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'a.jpg');
      await expectLater(
        () => ds.uploadProfilePhoto(file, 'u1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Image compression failed'),
          ),
        ),
      );
    });
  });
}
