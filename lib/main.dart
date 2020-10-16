import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitra_SIPAS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Mitra_SIPAS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // inisiasi seluruh variabel yang akan digunakan: vaiabel kounter, kuota maksimal, database reference
  int _countermobil;
  int _countermotor;
  int _lahanmobil;
  int _lahanmotor;
  DatabaseReference _counterRef;
  DatabaseReference _counterRefMobil;
  DatabaseReference _counterRefMotor;
  DatabaseError _error;
  //DatabaseReference _messagesRef;
  StreamSubscription<Event> _counterSubscriptionMobil;
  StreamSubscription<Event> _counterSubscriptionMotor;
  //StreamSubscription<Event> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Demonstrates configuring to the database using a file
    // Menyiapkan referensi untuk pengolahan data dari database
    final FirebaseDatabase database = FirebaseDatabase();
    _counterRef = database
        .reference()
        .child('test')
        .child('lahanParkir')
        .child('namaMitra')
        .child('kuota');
    database.reference().child('hey').once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
    });
    _counterRefMobil = _counterRef.child('kuotaMobil').child('kuotaMobil');
    _counterRefMotor = _counterRef.child('kuotaMotor').child('kuotaMotor');
    //_counterRef = FirebaseDatabase.instance.reference().child('hey');
    // Demonstrates configuring the database directly
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _counterRefMobil.keepSynced(true);
    _counterRefMotor.keepSynced(true);

    // pembacaan data secara realt-time untuk mobil
    _counterSubscriptionMobil = _counterRefMobil.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _countermobil = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      setState(() {
        _error = error;
      });
    });

    // pembacaan data secara realtime motor
    _counterSubscriptionMotor = _counterRefMotor.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _countermotor = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      setState(() {
        _error = error;
      });
    });
  }

  // untuk menghentikan pembacaan data secara real-time
  @override
  void dispose() {
    super.dispose();
    _counterSubscriptionMobil.cancel();
    _counterSubscriptionMotor.cancel();
  }

  // fungsi tambahan untuk mengambil data batas maksimum kuota lahan
  Future<void> lahanparkir() async {
    final FirebaseDatabase database = FirebaseDatabase();
    //String temp;
    var eventref = database
        .reference()
        .child('test')
        .child('lahanParkir')
        .child('namaMitra')
        .child('kuota');
    var kmobil = await eventref.child('maksimal').child('mobil').once();
    _lahanmobil = kmobil.value;
    var kmotor = await eventref.child('maksimal').child('motor').once();
    _lahanmotor = kmotor.value;
  }

  // fungsi untuk manambahkan kuota
  void _increment(var count) {
    // penambahan kuota
    count.runTransaction((MutableData transaction) async {
      transaction.value = (transaction.value ?? 0) + 1;
      return transaction;
    });
  }

  // fungsi untuk mengurangi kuota
  void _minus(var count) {
    // pengurangan kuota
    count.runTransaction((MutableData transaction) async {
      transaction.value = (transaction.value ?? 0) - 1;
      return transaction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
      ),
      body: FutureBuilder(
          future: lahanparkir(),
          builder: (ctx, snapshot) => snapshot.connectionState ==
              ConnectionState.waiting
              ? Center(
            child: CircularProgressIndicator(),
          )
              : ListView(
            children: <Widget>[
              Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(
                          Icons.directions_car,
                          size: 50.0,
                        ),
                        title: Text('Kuota Mobil'),
                        subtitle:
                        Text('$_countermobil dari $_lahanmobil'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FlatButton(
                              onPressed: () =>
                                  _increment(_counterRefMobil),
                              child: Text('Plus')),
                          FlatButton(
                              onPressed: () => _minus(_counterRefMobil),
                              child: Text('Min'))
                        ],
                      )
                    ]),
              ),
              Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(
                          Icons.motorcycle,
                          size: 50.0,
                        ),
                        title: Text('Kuota Motor'),
                        subtitle:
                        Text('$_countermotor dari $_lahanmotor'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FlatButton(
                              onPressed: () =>
                                  _increment(_counterRefMotor),
                              child: Text('Plus')),
                          FlatButton(
                              onPressed: () =>
                                  _minus(_counterRefMotor),
                              child: Text('Min'))
                        ],
                      )
                    ]),
              ),
            ],
          )
      ),
    );
  }
}
