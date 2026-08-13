import 'package:my_soc/utils/app_logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A global service for sending emails throughout the application.
class EmailService {
  // Private constructor to enforce singleton pattern
  EmailService._();

  static final EmailService instance = EmailService._();

  // Load SMTP credentials from the .env file
  // Ensure SMTP_USERNAME and SMTP_PASSWORD are defined in your .env
  String get _username => dotenv.env['SMTP_USERNAME'] ?? 'your_email@gmail.com';
  String get _password => dotenv.env['SMTP_PASSWORD'] ?? 'your_app_password';

  // Defaulting to Gmail SMTP for this setup.
  SmtpServer get _smtpServer => gmail(_username, _password);

  /// Sends a generic email to a specified recipient.
  Future<void> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    bool isHtml = false,
  }) async {
    logger.i('EmailService.sendEmail starting for $toEmail');
    logger.d('Subject: $subject | HTML format: $isHtml');

    final message = Message()
      ..from = Address(_username, 'MySoc Admin')
      ..recipients.add(toEmail)
      ..subject = subject;

    if (isHtml) {
      message.html = body;
    } else {
      message.text = body;
    }

    try {
      final sendReport = await send(message, _smtpServer);
      logger.i(
          'EmailService.sendEmail completed successfully: ${sendReport.toString()}');
    } on MailerException catch (e) {
      logger.e('EmailService.sendEmail: Message not sent. \n${e.toString()}');
      for (var p in e.problems) {
        logger.e('EmailService.sendEmail Problem: ${p.code}: ${p.msg}');
      }
      rethrow;
    }
  }

  /// Sends an approval notification email when a building is verified.
  Future<void> sendBuildingApprovalEmail({
    required String toEmail,
    required String buildingName,
  }) async {
    logger
        .i('EmailService.sendBuildingApprovalEmail starting for $buildingName');

    final subject = 'Your Building "$buildingName" has been Verified!';
    final htmlBody = '''
      <h2>Congratulations!</h2>
      <p>Your building <strong>$buildingName</strong> has been successfully verified by our administration team.</p>
      <p>You can now access all verified features on the MySoc platform.</p>
      <br/>
      <p>Best regards,<br/>The MySoc Team</p>
    ''';

    await sendEmail(
      toEmail: toEmail,
      subject: subject,
      body: htmlBody,
      isHtml: true,
    );

    logger.i('EmailService.sendBuildingApprovalEmail completed successfully');
  }

  /// Sends a rejection notification email when a building is rejected.
  Future<void> sendBuildingRejectionEmail({
    required String toEmail,
    required String buildingName,
    required String remark,
  }) async {
    logger.i(
        'EmailService.sendBuildingRejectionEmail starting for $buildingName');

    final subject = 'Update on Your Building "$buildingName" Verification';
    final htmlBody = '''
      <h2>Verification Update</h2>
      <p>Unfortunately, your building <strong>$buildingName</strong> could not be verified at this time.</p>
      <p><strong>Reason provided by the administration team:</strong><br/>
      <em>$remark</em></p>
      <p>Please resolve the issues mentioned above and try submitting again.</p>
      <br/>
      <p>Best regards,<br/>The MySoc Team</p>
    ''';

    await sendEmail(
      toEmail: toEmail,
      subject: subject,
      body: htmlBody,
      isHtml: true,
    );

    logger.i('EmailService.sendBuildingRejectionEmail completed successfully');
  }
}
