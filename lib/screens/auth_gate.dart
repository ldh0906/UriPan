import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/board_repository.dart';
import 'board_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.client, required this.repository});

  final SupabaseClient client;
  final BoardRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isClearingAnonymousSession = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: widget.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = widget.client.auth.currentSession;
        if (session == null) {
          return LoginScreen(client: widget.client);
        }

        if (widget.client.auth.currentUser?.isAnonymous == true) {
          if (!_isClearingAnonymousSession) {
            _isClearingAnonymousSession = true;
            widget.client.auth.signOut().whenComplete(() {
              if (mounted) setState(() => _isClearingAnonymousSession = false);
            });
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BoardHomeScreen(
          client: widget.client,
          repository: widget.repository,
        );
      },
    );
  }
}
