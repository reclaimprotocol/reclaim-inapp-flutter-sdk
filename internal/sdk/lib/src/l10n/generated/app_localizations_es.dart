// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ReclaimAppLocalizationsEs extends ReclaimAppLocalizations {
  ReclaimAppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageName => 'Español';

  @override
  String get helloWorld => '¡Hola mundo!';

  @override
  String get defaultLanguage => 'Idioma predeterminado';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get verificationCancelled => 'Verificación cancelada';

  @override
  String get verificationDismissedByUser => 'Verificación rechazada por el usuario';

  @override
  String get providerNotFound => 'Proveedor no encontrado';

  @override
  String weCouldntDeliverProofs({required String appName}) {
    return 'No pudimos entregar las pruebas a \"$appName\".';
  }

  @override
  String verifyingFor({required String appName}) {
    return 'Verificando $appName';
  }

  @override
  String get platformNotSupported => 'Plataforma no compatible';

  @override
  String get inappSdkVersionIsOutdatedAndNotFunctionalAnymore =>
      'La versión del SDK InApp está desactualizada y ya no funciona';

  @override
  String get requirementForVerificationCouldNotBeMet => 'No se cumplió el requisito necesario para la verificación';

  @override
  String get sessionExpired => 'Sesión expirada';

  @override
  String get submit => 'Enviar';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get gettingReady => 'Preparando…';

  @override
  String get gettingReadyToVerify => 'Preparándose para verificar';

  @override
  String get almostThereJustFinalizingTheDetails => 'Casi listo, finalizando los detalles';

  @override
  String get pleaseHoldOnForJustALittleLonger => 'Por favor, espera un poco más';

  @override
  String get thisShouldntTakeMuchLonger => 'Esto no debería tardar mucho más';

  @override
  String verifyingDataFrom({required String domain}) {
    return 'Verificando los datos de $domain';
  }

  @override
  String get waitingForVerificationStart => 'Esperando a que comience la verificación…';

  @override
  String get thisMightTakeAFewSeconds => 'Esto puede tardar unos segundos';

  @override
  String get waitingForVerification => 'Esperando verificación';

  @override
  String sharingWith({required String appName}) {
    return 'Compartiendo con $appName';
  }

  @override
  String get youAlwaysControlWhoYouShareYourDataWith => 'Tú decides con quién compartes tus datos.';

  @override
  String get youAreInCompleteControlOfYourData => 'Tienes control total sobre tus datos.';

  @override
  String get lookingForInformationToVerify => 'Buscando información para verificar';

  @override
  String get findOurTermsOfServicePrivacyPolicyAt =>
      'Encuentra nuestros términos de servicio y política de privacidad en _reclaimprotocol.org_';

  @override
  String get byContinuingYouAgreeToThese =>
      'Al continuar, aceptas estos _Términos de Servicio@1_ y _Política de Privacidad@2_';

  @override
  String get infinite => 'Infinito';

  @override
  String get empty => 'Vacío';

  @override
  String get loading => 'cargando…';

  @override
  String get copiedToYourClipboard => 'Copiado al portapapeles';

  @override
  String get proofsGeneratedByReclaimProtocolAreSecureAndPrivate =>
      'Las pruebas generadas por Reclaim Protocol son seguras y privadas.';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get allow => 'Permitir';

  @override
  String get dontAllow => 'No permitir';

  @override
  String get copySessionId => 'Copiar ID de sesión';

  @override
  String get refreshPage => 'Actualizar página';

  @override
  String get settings => 'Configuración';

  @override
  String get troubleshootingMode => 'Modo de solución de problemas';

  @override
  String get saveWebsiteData => 'Guardar datos del sitio web';

  @override
  String get requestingPermission => 'Solicitando permiso';

  @override
  String get areYouSureYouSeeAllTheDataThatNeedsVerification =>
      '¿Estás seguro de que ves todos los datos que necesitan verificación?';

  @override
  String get shareRequests => 'Solicitudes de acceso';

  @override
  String get tapShareToSendForManualReview => 'Toca (compartir) para enviar a revisión manual';

  @override
  String wantsToAccessYour({required String domain, required String resource}) {
    return '$domain quiere acceder a tu $resource';
  }

  @override
  String get contactApplicationSupportForMoreInformation =>
      'Contacta al soporte de la aplicación para más información.';

  @override
  String get share => 'Compartir';

  @override
  String get createAndVerifyDataInSeconds => 'Crea y verifica datos en segundos';

  @override
  String get orBrowseSomeOfOur => 'O explora algunos _ejemplos de nuestros proveedores de datos_';

  @override
  String returnTo({required String appName}) {
    return 'Volver a $appName';
  }

  @override
  String youCanNowReturnTo({required String appName}) {
    return 'Ahora puedes volver a $appName';
  }

  @override
  String get providers => 'Proveedores';

  @override
  String get invalidLink => 'Enlace inválido';

  @override
  String get theRequestedProofLinkIsInvalid => 'El enlace de prueba solicitado es inválido';

  @override
  String get ok => 'Aceptar';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get noProvidersFound => 'No se encontraron proveedores de datos';

  @override
  String get pasteTheRequestedProofLinkHere => 'Pega el enlace de prueba solicitado aquí';

  @override
  String get searchForAProvider => 'Buscar un proveedor';

  @override
  String get searchByProvider => 'Buscar por proveedor';

  @override
  String get youPreviouslyVerifiedThisData => 'Ya verificaste estos datos anteriormente';

  @override
  String get verifyAgain => 'Verificar de nuevo';

  @override
  String get shareData => 'Compartir datos';

  @override
  String isRequestingADataFrom({required String appName, required String user}) {
    return '$appName está solicitando datos de $user';
  }

  @override
  String get privacy => 'Privacidad';

  @override
  String get proofSubmissionFailed => 'Falló el envío de la prueba';

  @override
  String get anUnknownProblemOccurred => 'Ocurrió un problema desconocido';

  @override
  String get outdated => 'Desactualizado';

  @override
  String get verificationFailed => 'Verificación fallida';

  @override
  String verificationRequestInvalid({required String appName}) {
    return 'La solicitud de verificación es inválida. Por favor, intenta iniciar la verificación de nuevo. Si el problema persiste, contacta a $appName.';
  }

  @override
  String get unsupportedDevice => 'Dispositivo no compatible';

  @override
  String get thisDeviceIsNotSupportedForVerifications =>
      'Este dispositivo no es compatible para verificaciones. Por favor, inténtalo en un dispositivo diferente.';

  @override
  String get thisVersionOfAppIsNotSupportedAnymore =>
      'Esta versión de la aplicación ya no es compatible. Por favor, intenta de nuevo después de actualizar.';

  @override
  String yourLoginCredentialsAndPrivateDataStaySecure({required Object appName}) {
    return 'Tus credenciales de inicio de sesión y datos privados permanecen seguros y nunca son visibles para $appName, Reclaim Protocol, ni nadie más.';
  }

  @override
  String get theApplicationHasEncounteredAnUnknownError =>
      'La aplicación ha encontrado un error desconocido. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get tapOnTheLinkOnTheOtherAppBrowser =>
      'Toca el enlace en la otra aplicación/navegador que estabas usando para iniciar la verificación';

  @override
  String get proofGenerationWasCancelledByTheUser => 'La generación de la prueba fue cancelada por el usuario';

  @override
  String get whatWasShared => 'Qué se compartió';

  @override
  String get whatWentWrong => '¿Qué salió mal?';

  @override
  String get dataSavedShared => 'Datos Guardados y Compartidos';

  @override
  String get dataShared => 'Datos Compartidos';

  @override
  String get wereReviewingYourSubmission => 'Estamos revisando tu solicitud';

  @override
  String unexpectedErrorOccurredDuringVerification({required String message, required String appName}) {
    return 'Ocurrió un error inesperado durante la verificación. $message. Si el problema persiste, contacta a $appName.';
  }

  @override
  String get invalidVerificationRequest => 'Solicitud de verificación no válida';

  @override
  String get hideDetails => 'Ocultar detalles';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get yourDataHasBeenSubmittedSuccessfully =>
      'Tus datos se han enviado con éxito y están actualmente bajo revisión manual por nuestro equipo. No se requiere ninguna acción adicional de tu parte. Te notificaremos una vez que la revisión esté completa.';

  @override
  String get why => '¿POR QUÉ?';

  @override
  String verificationSessionExpired({required String appName}) {
    return 'La sesión de verificación ha expirado. Por favor, intenta iniciar la verificación de nuevo desde $appName.';
  }

  @override
  String get updateForInappSdkAvailableCritical =>
      '⚠️🚨 Hay una actualización disponible para el SDK InApp. La versión actual ya no se puede usar, por favor actualiza la versión del SDK InApp usada por esta aplicación para asegurar la compatibilidad.';

  @override
  String get updateForInappSdkAvailableWarning =>
      '⚠️ Hay una actualización disponible para el SDK InApp. Por favor actualiza la versión del SDK InApp usada por esta aplicación para asegurar la compatibilidad.';

  @override
  String get forMoreInformationAboutThisError =>
      'Para más información sobre este error, por favor _consulta las posibles razones de falla._';

  @override
  String verifyingStudentStatus({required String providerName}) {
    return 'Verificando el estado de estudiante para $providerName.';
  }
}
