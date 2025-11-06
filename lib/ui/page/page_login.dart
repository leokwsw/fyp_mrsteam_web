import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_mrsteam_web/core/config/get_it.dart';
import 'package:fyp_mrsteam_web/core/router/router_app.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/login/bloc_login.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/login/event_login.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/login/state_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed(BuildContext context) {
    context.read<LoginBloc>().add(LoginSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: Scaffold(
        body: BlocConsumer<LoginBloc, LoginState>(
          listenWhen: (prev, curr) =>
              prev.error != curr.error || (prev.loading && !curr.loading),
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
              return;
            }
            if (!state.loading && state.error == null) {
              getIt<AppRouter>().router.go('/home');
              print("momo2");
            } else {
              print("momo1");
            }
          },
          builder: (context, state) {
            final bloc = context.read<LoginBloc>();

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign In to continue',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 26),

                    TextField(
                      controller: _usernameController,
                      onChanged: (v) => bloc.add(UsernameChanged(v)),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      onChanged: (v) => bloc.add(PasswordChanged(v)),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: state.loading
                            ? null
                            : () => _onLoginPressed(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B62FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: state.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
                    ),
                    // const SizedBox(height: 10),
                    // const Text(
                    //   "Don't have an account? Sign Up",
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     fontFamily: 'Poppins',
                    //     fontSize: 14,
                    //     color: Color(0xFF87879D),
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
