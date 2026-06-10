import 'package:flutter/material.dart';

class NoBoardScreen extends StatelessWidget {
  const NoBoardScreen({
    super.key,
    required this.message,
    required this.onCreateBoard,
    required this.onJoinBoard,
    required this.onSignOut,
  });

  final String? message;
  final VoidCallback onCreateBoard;
  final VoidCallback onJoinBoard;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uAC00\uC871 \uBCF4\uB4DC \uC2DC\uC791',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '\uBCF4\uB4DC\uB97C \uB9CC\uB4E4\uAC70\uB098 \uCD08\uB300\uCF54\uB4DC\uB85C \uCC38\uAC00\uD574\uC8FC\uC138\uC694.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onCreateBoard,
                child: const Text('\uBCF4\uB4DC \uB9CC\uB4E4\uAE30'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onJoinBoard,
                child: const Text(
                  '\uCD08\uB300\uCF54\uB4DC\uB85C \uCC38\uAC00',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSignOut,
                child: const Text('\uB85C\uADF8\uC544\uC6C3'),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BoardLoadErrorScreen extends StatelessWidget {
  const BoardLoadErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uBCF4\uB4DC\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSignOut,
                child: const Text('\uB85C\uADF8\uC544\uC6C3'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
