import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  late DatabaseReference _outputRef;

  FirebaseService() {
    _outputRef = _databaseReference.child('ESP8266_2/Outputs');
  }

  Stream<DatabaseEvent> get dataStream => _outputRef.onValue;
}
