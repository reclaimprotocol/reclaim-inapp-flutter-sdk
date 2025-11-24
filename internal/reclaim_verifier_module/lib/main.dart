import 'package:flutter/widgets.dart';

import 'reclaim_verifier_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY =
      'eyJraWQiOiI4NjgyNGJkMS04ZDU4LTQ5YWQtODVlMC03YzYxYWUyYTNjM2IiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Il80ekg2MFNJNEkyYXBuVlYzeUFTLWxQYWpwbzRHeTRmYV9NOFJYMGVaR0UiLCJ5IjoiSk5lWExnZ0JDdm9QZ1lYYTZxRGhCWHN6OGc1MkpHSDZPSHUyUmtpLXp5USIsImNydiI6IlAtMjU2In0';
  ReclaimEnv.IS_VERIFIER_INAPP_MODULE = true;

  runApp(ReclaimModuleApp.build());
}
