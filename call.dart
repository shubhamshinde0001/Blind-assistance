import 'package:url_launcher/url_launcher.dart';

class CallService {
  static final String phoneNumber = "9321828271"; // Change this to your desired number

  static void makePhoneCall() async {
    final Uri callUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      throw "Could not launch $callUri";
    }
  }
}
