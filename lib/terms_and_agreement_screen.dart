import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAndAgreementScreen extends StatefulWidget {
  final bool isRequired;
  
  const TermsAndAgreementScreen({
    super.key,
    this.isRequired = false,
  });

  @override
  State<TermsAndAgreementScreen> createState() =>
      _TermsAndAgreementScreenState();
}

class _TermsAndAgreementScreenState extends State<TermsAndAgreementScreen> {
  bool _hasRead = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isRequired, // Allow back button if not required
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms and Conditions'),
          backgroundColor: Colors.green,
          automaticallyImplyLeading: !widget.isRequired,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions of Use',
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
                '1. Acceptance of Terms',
                '''
By accessing and using the Midwest Grocery Store mobile application ("App"), you accept and agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use the App.

We reserve the right to modify these Terms at any time. Your continued use of the App after changes are posted constitutes your acceptance of the modified Terms.
                ''',
              ),
              _buildSection(
                '2. Eligibility',
                '''
You must be at least 18 years old to use this App and place orders. By using the App, you represent and warrant that:
• You are at least 18 years of age
• You have the legal capacity to enter into binding agreements
• You will comply with all applicable laws and regulations
• All information you provide is accurate and current
                ''',
              ),
              _buildSection(
                '3. Account Registration',
                '''
To use certain features of the App, you may be required to create an account. You agree to:
• Provide accurate, current, and complete information
• Maintain and update your account information
• Maintain the security of your account credentials
• Accept responsibility for all activities under your account
• Notify us immediately of any unauthorized use

You are responsible for maintaining the confidentiality of your account password and for all activities that occur under your account.
                ''',
              ),
              _buildSection(
                '4. Products and Pricing',
                '''
• Product Information: We strive to provide accurate product descriptions, images, and pricing. However, we do not warrant that product descriptions or other content is accurate, complete, or error-free.
• Pricing: All prices are subject to change without notice. Prices displayed are in the currency specified and may vary based on location.
• Availability: Product availability is subject to change. We reserve the right to limit quantities and refuse or cancel orders.
• Errors: We reserve the right to correct any errors in pricing or product information, even after an order has been placed.
                ''',
              ),
              _buildSection(
                '5. Orders and Payment',
                '''
• Order Acceptance: Your order is an offer to purchase. We reserve the right to accept or reject any order for any reason.
• Payment: You agree to provide current, complete, and accurate purchase and account information. You agree to pay all charges incurred by your account.
• Payment Methods: We accept various payment methods as displayed in the App. All payments are processed securely through third-party payment processors.
• Order Confirmation: You will receive an order confirmation via email or in-app notification once your order is received.
                ''',
              ),
              _buildSection(
                '6. Shipping and Delivery',
                '''
• Shipping: We will make reasonable efforts to ship products within the timeframes specified, but we do not guarantee delivery dates.
• Shipping Costs: Shipping costs are calculated at checkout and are your responsibility unless otherwise stated.
• Delivery: Risk of loss and title for products pass to you upon delivery to the carrier.
• Delivery Issues: If you experience delivery issues, please contact us promptly.
                ''',
              ),
              _buildSection(
                '7. Returns and Refunds',
                '''
• Return Policy: Returns are accepted within 30 days of purchase, subject to our return policy. Items must be in original condition.
• Refunds: Refunds will be processed to the original payment method within 5-10 business days after we receive and inspect the returned item.
• Non-Returnable Items: Certain items may not be returnable (e.g., perishable goods, personalized items). These will be clearly marked.
• Return Process: Contact customer service to initiate a return. You are responsible for return shipping costs unless the item is defective or incorrect.
                ''',
              ),
              _buildSection(
                '8. User Conduct',
                '''
You agree not to:
• Use the App for any illegal purpose or in violation of any laws
• Transmit any harmful code, viruses, or malicious software
• Attempt to gain unauthorized access to the App or its systems
• Interfere with or disrupt the App or servers
• Use automated systems to access the App without permission
• Impersonate any person or entity
• Collect or harvest information about other users
• Use the App to send spam or unsolicited communications
                ''',
              ),
              _buildSection(
                '9. Intellectual Property',
                '''
• Ownership: All content, features, and functionality of the App are owned by Midwest Grocery Store and are protected by copyright, trademark, and other intellectual property laws.
• License: We grant you a limited, non-exclusive, non-transferable license to access and use the App for personal, non-commercial purposes.
• Restrictions: You may not copy, modify, distribute, sell, or lease any part of the App without our written permission.
• Trademarks: All trademarks, logos, and service marks displayed in the App are our property or the property of their respective owners.
                ''',
              ),
              _buildSection(
                '10. Limitation of Liability',
                '''
TO THE MAXIMUM EXTENT PERMITTED BY LAW:
• THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND
• WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
• WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
• OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE PRODUCTS OR SERVICES IN QUESTION
                ''',
              ),
              _buildSection(
                '11. Indemnification',
                '''
You agree to indemnify, defend, and hold harmless Midwest Grocery Store, its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:
• Your use of the App
• Your violation of these Terms
• Your violation of any rights of another party
• Your violation of any applicable laws
                ''',
              ),
              _buildSection(
                '12. Termination',
                '''
We reserve the right to:
• Terminate or suspend your account and access to the App at any time, with or without cause or notice
• Remove or edit content at our sole discretion
• Discontinue the App or any part thereof at any time

You may terminate your account at any time by contacting us or using account deletion features in the App.
                ''',
              ),
              _buildSection(
                '13. Governing Law',
                '''
These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Midwest Grocery Store operates, without regard to its conflict of law provisions.

Any disputes arising from these Terms or your use of the App shall be resolved in the courts of competent jurisdiction in that jurisdiction.
                ''',
              ),
              _buildSection(
                '14. Severability',
                '''
If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.
                ''',
              ),
              _buildSection(
                '15. Contact Information',
                '''
If you have any questions about these Terms and Conditions, please contact us:

Midwest Grocery Store
Matingain 1, Lemery Batangas, beside Midwest Park
Phone: (555) 123-4567
Email: legal@midwestgrocery.com
                ''',
              ),
              if (widget.isRequired) ...[
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text(
                    'I have read and understood the Terms and Conditions',
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
                            await prefs.setBool('terms_accepted', true);
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

