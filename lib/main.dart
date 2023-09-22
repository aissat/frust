import 'package:flutter/material.dart';
import 'package:rust_in_flutter/rust_in_flutter.dart';
import 'package:frust/messages/counter_tuto.pb.dart' as counter_tuto;
import 'package:frust/messages/increasing_number.pb.dart' as increasing_number;

void main() async {
  await RustInFlutter.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<RustSignal>(
              stream: rustBroadcaster.stream.where((rustSignal) {
                return rustSignal.resource == increasing_number.ID;
              }),
              builder: (context, snapshot) {
                final received = snapshot.data;
                if (received == null) {
                  return const Text("Nothing received yet");
                } else {
                  final singal = increasing_number.Signal.fromBuffer(
                    received.message!,
                  );
                  final currentNumber = singal.currentNumber;
                  return Text(currentNumber.toString());
                }
              },
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () async {
                final requestMsg = counter_tuto.ReadRequest(
                  inputNumbers: [1, 2, 3],
                  inputString: "Hello from Flutter",
                );
                final rustRequest = RustRequest(
                  resource: counter_tuto.ID,
                  operation: RustOperation.Read,
                  message: requestMsg.writeToBuffer(),
                );
                final rustResponse = await requestToRust(rustRequest);
                final responseMessage =
                    counter_tuto.ReadResponse.fromBuffer(rustResponse.message!);
                print(responseMessage.outputNumbers);
                print(responseMessage.outputString);
              },
              child: const Text("Request to Rust"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final requestMsg = increasing_number.CounterInc(
            counter: _counter,
          );

          final rustRequest = RustRequest(
            resource: increasing_number.ID,
            operation: RustOperation.Read,
            message: requestMsg.writeToBuffer(),
          );

          final rustResponse = await requestToRust(rustRequest);

          final responseMessage =
              increasing_number.CounterInc.fromBuffer(rustResponse.message!);
          _counter = responseMessage.counter;

          setState(() {});
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
