import 'package:flutter/material.dart';

class GentleLoading extends StatelessWidget {
  const GentleLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 3)));
  }
}

class GentleError extends StatelessWidget {
  const GentleError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☁️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
