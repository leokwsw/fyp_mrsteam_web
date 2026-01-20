import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/core/config/get_it.dart';
import 'package:fyp_mrsteam_web/core/router/router_app.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/home/bloc_home.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/home/event_home.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/home/state_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _onLogoutPressed(BuildContext context){
    context.read<HomeBloc>().add(LogoutSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final userId = AppPreferences.getUserId();

    return BlocProvider(
      create: (_) => HomeBloc(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("Hello $userId"),
        ),
        body: BlocConsumer<HomeBloc, HomeState>(
          listenWhen: (prev, curr) => prev.error != curr.error || (prev.loading && !curr.loading),
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
              return;
            }
            if (!state.loading && state.error == null) {
              getIt<AppRouter>().router.go('/login');
              print("momo2");
            } else {
              print("momo1");
            }
          },
          builder: (context, state) {
            final bloc = context.read<HomeBloc>();

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('You have pushed the button this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ElevatedButton(
                    onPressed: state.loading?null : () => _onLogoutPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B62FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.loading ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ) : const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
