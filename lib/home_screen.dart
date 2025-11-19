import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'browse_product_new.dart';
import 'orders_screen.dart';
import 'provider.dart';
import 'services/connectivity_service.dart';
import 'data_collection_compliance_screen.dart';
import 'terms_and_agreement_screen.dart';

// Theme mode options
enum ThemeSetting { light, dark, system }

// Global theme mode notifier
final ValueNotifier<ThemeSetting> themeSetting =
    ValueNotifier(ThemeSetting.system);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<ThemeSetting>(
          valueListenable: themeSetting,
          builder: (context, mode, _) {
            return AlertDialog(
              title: const Text('Select Theme Mode'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeSetting>(
                    secondary:
                        const Icon(Icons.light_mode, color: Colors.orange),
                    title: const Text('Light (Off)'),
                    value: ThemeSetting.light,
                    groupValue: mode,
                    onChanged: (value) {
                      themeSetting.value = value!;
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeSetting>(
                    secondary:
                        const Icon(Icons.dark_mode, color: Colors.blueGrey),
                    title: const Text('Dark (On)'),
                    value: ThemeSetting.dark,
                    groupValue: mode,
                    onChanged: (value) {
                      themeSetting.value = value!;
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeSetting>(
                    secondary: const Icon(Icons.brightness_auto,
                        color: Colors.green),
                    title: const Text('Automatic (System)'),
                    value: ThemeSetting.system,
                    groupValue: mode,
                    onChanged: (value) {
                      themeSetting.value = value!;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Browse Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BrowseProductsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrdersScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataCollectionComplianceScreen(isRequired: false),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms & Conditions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsAndAgreementScreen(isRequired: false),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Theme Mode'),
              onTap: () {
                Navigator.pop(context); // close drawer
                _showThemeDialog(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ConnectivityService.buildOfflineBanner(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/midwest_logo.jpg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Midwest Grocery App Store',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome to the Midwest Grocery Store!',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          ListTile(
                            leading: Icon(Icons.access_time, color: Colors.green),
                            title: Text('Store Hours'),
                            subtitle: Text('7:00 AM - 9:00 PM'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.location_on, color: Colors.green),
                            title: Text('Location'),
                            subtitle: Text(
                                'Matingain 1, Lemery Batangas, beside Midwest Park'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.phone, color: Colors.green),
                            title: Text('Contact'),
                            subtitle: Text('+63 917 150 5564'),
                          ),
                          Divider(),
                          ListTile(
                            leading:
                                Icon(Icons.local_grocery_store, color: Colors.green),
                            title: Text('About Us'),
                            subtitle: Text(
                                'Fresh produce, daily deals, and friendly service!'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
