// To parse this JSON data, do
//
//     final confirmCodeResponse = confirmCodeResponseFromJson(jsonString);

import 'dart:convert';

ConfirmCodeResponse confirmCodeResponseFromJson(String str) => ConfirmCodeResponse.fromJson(json.decode(str));

String confirmCodeResponseToJson(ConfirmCodeResponse data) => json.encode(data.toJson());

class ConfirmCodeResponse {
  ConfirmCodeResponse({
    required this.result,
    required this.message,
  });

  bool result;
  String message;

  factory ConfirmCodeResponse.fromJson(Map<String, dynamic> json) => ConfirmCodeResponse(
    result: json["result"] ?? false,
    message: json["message"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "result": result,
    "message": message,
  };
}