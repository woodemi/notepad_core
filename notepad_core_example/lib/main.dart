import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'MobileApp.dart';
import 'WebApp.dart';

void main() {
  runApp(kIsWeb ? WebApp() : MobileApp());
}