import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

final apiKey = dotenv.env['PDF_PUBLIC_KEY'];

Future<String?> getToken() async {
  // Getting the authentication token from the server
  try {
    print(apiKey);
    var request =
        http.Request('POST', Uri.parse('https://api.ilovepdf.com/v1/auth'));
    request.headers['Content-Type'] = 'application/json';
    request.body = '''{"public_key": "$apiKey"}''';

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      Map<String, dynamic> decodedResponse = json.decode(responseBody);
      if (decodedResponse.containsKey('token')) {
        return decodedResponse['token'];
      } else {
        print('Token not found in response.');
        return null;
      }
    } else {
      print(response.reasonPhrase);
      return null;
    }
  } catch (e) {
    print('Encountered error while authentication $e');
    return null;
  }
}

Future<dynamic> uploadImages(
    File? images, String token, String taskId, String server) async {
  try {
    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    FormData formData = FormData.fromMap({
      'task': taskId,
      'file': await MultipartFile.fromFile(images!.path),
    });

    Response response = await dio.post(
      'https://$server/v1/upload',
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data['server_filename'];
      // return decodedResponse['server_filename'];
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  } catch (e) {
    print('Error during upload: $e');
    return null;
  }
}

Future<dynamic> downloadImages(String token, String server, String task) async {
  try {
    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    String url = 'https://$server/v1/download/$task';
    Directory appDocDir =
        await getTemporaryDirectory(); // use temporary directory
    String savePath = '${appDocDir.path}/temp_file';

    Response response = await dio.download(
      url,
      savePath,
    );

    if (response.statusCode == 200) {
      File file = File(savePath);
      return file;
    } else {
      print('Download failed: ${response.statusMessage}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

Future<dynamic> compressImage(File? images) async {
  try {
    String? token = await getToken();
    if (token != null) {
      // Getting which server and task id to use for the operation
      var request = http.Request(
          'GET', Uri.parse('https://api.ilovepdf.com/v1/start/compressimage'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print(responseBody);
        Map<String, dynamic> decodedResponse = json.decode(responseBody);

        // For Uploading Our file onto the mentioned server
        String? serverFilename = await uploadImages(
            images, token, decodedResponse['task'], decodedResponse['server']);
        if (serverFilename != null) {
          print(serverFilename);
          // Actually processing the file on ther server
          var processRequest = http.Request('POST',
              Uri.parse('https://${decodedResponse['server']}/v1/process'));
          processRequest.headers['Authorization'] = 'Bearer $token';
          processRequest.headers['Content-Type'] = 'application/json';
          processRequest.body =
              '''{"task": "${decodedResponse['task']}","tool": "compressimage","files": [{"server_filename": "$serverFilename","filename":"server.pdf"}]}''';

          http.StreamedResponse processResponse = await processRequest.send();

          if (processResponse.statusCode == 200) {
            String processResponseBody =
                await processResponse.stream.bytesToString();
            Map<String, dynamic> processDecodedResponse =
                json.decode(processResponseBody);
            print(processDecodedResponse);
            // Now downloading the reduced file back to mobile phone
            return downloadImages(
                token, decodedResponse['server'], decodedResponse['task']);
          } else {
            throw Exception(
                'Error occured while processing the image ${processResponse.reasonPhrase}');
          }
        } else {
          throw Exception("Error while uploading the image to the server");
        }
      } else {
        throw Exception("Something went wrong while asking for a server");
      }
    }
  } catch (e) {
    print('Encountered error while uploading for compression');
  }
}
