import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bluetooth_hero.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'The best way to showcase your project.',
      body: 'Seamless connectivity, real-time data. Pair your BLE device and control it in a tap.',
    ),
    (
      title: 'Find your ESP32 in seconds.',
      body: 'The app scans for nearby boards running the BLEc firmware and shows their signal strength.',
    ),
    (
      title: 'Control it in real time.',
      body: 'Switch the LED on and off, and see the state the board reports back instantly.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandTitle(),
              const SizedBox(height: 20),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                  child: const BluetoothHero(),
                ),
              ),
              const SizedBox(height: 24),
              _Dots(count: _pages.length, index: _page),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pages[i].title,
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _pages[i].body,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Start Connect',
                trailingIcon: Icons.arrow_forward,
                onPressed: _start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 26 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : const Color(0xFFCBD2DC),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
