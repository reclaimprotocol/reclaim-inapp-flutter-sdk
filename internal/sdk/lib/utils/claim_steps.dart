import 'package:reclaim_flutter_sdk/types/create_claim.dart';

Map<int, StepMeta> getClaimSteps(String hostUrl, String appName) {
  return {
    1: StepMeta(
      title: 'Verifying data from $hostUrl',
      iconIndex: 0,
    ),
    2: const StepMeta(
      title: 'Your phone seems to have low memory, but we can still try',
      iconIndex: 1,
    ),
    3: StepMeta(
      title: 'Reading your information from $hostUrl',
      iconIndex: 2,
    ),
    4: const StepMeta(
      title: 'Your information resides exclusively on your phone',
      iconIndex: 3,
    ),
    5: StepMeta(
      title: 'Only the data which you select is shared with $appName',
      iconIndex: 4,
    ),
    6: const StepMeta(
      title: 'Generating a proof is a complex computation',
      iconIndex: 5,
    ),
    7: const StepMeta(
      title: 'Generating proof that your claim is correct',
      iconIndex: 6,
    ),
    8: const StepMeta(
      title: 'Securing the proof cryptographically',
      iconIndex: 7,
    ),
    9: StepMeta(
      title:
          'Once the proof is generated, you would have reclaimed your data from $hostUrl',
      iconIndex: 8,
    ),
    10: const StepMeta(
      title:
          "Once you've reclaimed your data, you can use it in any way you like",
      iconIndex: 9,
    ),
    11: const StepMeta(
      title: 'Reclaiming data puts you in control of your data',
      iconIndex: 10,
    ),
    12: const StepMeta(
      title: 'We are glad you took this step to reclaim your data today',
      iconIndex: 11,
    ),
    13: const StepMeta(
      title:
          "After all, if you can't control how to use it - is it even your data?",
      iconIndex: 12,
    ),
    14: const StepMeta(
      title:
          'The proof is being generated, and should be ready in a few moments',
      iconIndex: 13,
    ),
    15: const StepMeta(
      title: 'Thank you for your patience',
      iconIndex: 14,
    ),
    16: const StepMeta(
      title: 'Please hold on for just a little longer',
      iconIndex: 15,
    ),
  };
}
