import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCollectionComplianceScreen extends StatefulWidget {
  final bool isRequired;
  
  const DataCollectionComplianceScreen({
    super.key,
    this.isRequired = false,
  });

  @override
  State<DataCollectionComplianceScreen> createState() =>
      _DataCollectionComplianceScreenState();
}

class _DataCollectionComplianceScreenState
    extends State<DataCollectionComplianceScreen> {
  bool _hasRead = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isRequired, // Allow back button if not required
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Collection and Compliance'),
          backgroundColor: Colors.green,
          automaticallyImplyLeading: !widget.isRequired,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Collection and Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                '1. Information We Collect',
                '''
We collect information that you provide directly to us when you:
• Create an account or profile
• Place an order or make a purchase
• Contact us for customer support
• Subscribe to our newsletter or marketing communications
• Participate in surveys or promotions

The types of information we may collect include:
• Personal Information: Name, email address, phone number, shipping address, billing address
• Payment Information: Credit card details, billing information (processed securely through third-party payment processors)
• Device Information: Device ID, IP address, browser type, operating system
• Usage Information: How you interact with our app, pages visited, products viewed, search queries
• Location Information: With your permission, we may collect location data to provide location-based services
                ''',
              ),
              _buildSection(
                '2. How We Use Your Information',
                '''
We use the information we collect to:
• Process and fulfill your orders
• Communicate with you about your orders, account, and our services
• Send you marketing communications (with your consent)
• Improve our app, products, and services
• Personalize your shopping experience
• Detect and prevent fraud and abuse
• Comply with legal obligations
• Respond to your inquiries and provide customer support
                ''',
              ),
              _buildSection(
                '3. Information Sharing and Disclosure',
                '''
We do not sell your personal information. We may share your information with:
• Service Providers: Third-party companies that help us operate our business (payment processors, shipping companies, analytics providers)
• Legal Requirements: When required by law, court order, or government regulation
• Business Transfers: In connection with a merger, acquisition, or sale of assets
• With Your Consent: When you explicitly authorize us to share your information

All third-party service providers are contractually obligated to protect your information and use it only for the purposes we specify.
                ''',
              ),
              _buildSection(
                '4. Data Security',
                '''
We implement appropriate technical and organizational security measures to protect your personal information, including:
• Encryption of data in transit and at rest
• Secure payment processing
• Regular security assessments
• Access controls and authentication
• Employee training on data protection

However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.
                ''',
              ),
              _buildSection(
                '5. Your Rights and Choices',
                '''
You have the right to:
• Access your personal information
• Correct inaccurate information
• Request deletion of your information
• Opt-out of marketing communications
• Withdraw consent for data processing
• Request a copy of your data
• File a complaint with data protection authorities

To exercise these rights, please contact us using the information provided in the "Contact Us" section.
                ''',
              ),
              _buildSection(
                '6. Data Retention',
                '''
We retain your personal information for as long as necessary to:
• Fulfill the purposes outlined in this policy
• Comply with legal obligations
• Resolve disputes and enforce agreements
• Maintain business records as required by law

When information is no longer needed, we will securely delete or anonymize it.
                ''',
              ),
              _buildSection(
                '7. Children\'s Privacy',
                '''
Our app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.
                ''',
              ),
              _buildSection(
                '8. International Data Transfers',
                '''
Your information may be transferred to and processed in countries other than your country of residence. These countries may have different data protection laws. We ensure appropriate safeguards are in place to protect your information in accordance with this policy.
                ''',
              ),
              _buildSection(
                '9. Changes to This Policy',
                '''
We may update this Data Collection and Privacy Policy from time to time. We will notify you of any material changes by:
• Posting the updated policy in the app
• Sending you an email notification (if you have provided your email)
• Displaying a prominent notice in the app

Your continued use of the app after changes become effective constitutes acceptance of the updated policy.
                ''',
              ),
              _buildSection(
                '10. Contact Us',
                '''
If you have questions, concerns, or requests regarding this Data Collection and Privacy Policy or our data practices, please contact us:

Midwest Grocery Store
Matingain 1, Lemery Batangas, beside Midwest Park
Phone: +63 917 150 5564
Email: privacy@midwestgrocery.com
                ''',
              ),
              if (widget.isRequired) ...[
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text(
                    'I have read and understood the Data Collection and Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _hasRead,
                  onChanged: (value) {
                    setState(() {
                      _hasRead = value ?? false;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasRead || !widget.isRequired
                      ? () async {
                          if (widget.isRequired) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('data_compliance_accepted', true);
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.isRequired ? 'I Accept' : 'Close',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

