const MeChainStepsMap =
    {
  'taskRequested':
      0.02,
  'taskCreated':
      0.1,
  'attestorRequested':
      0.2,
};

double getMeChainProgress(
    String?
        type) {
  return MeChainStepsMap[type] ??
      0;
}

bool isMeChainStep(
    String?
        type) {
  if (type ==
      null) {
    return false;
  } else {
    return MeChainStepsMap.containsKey(
        type);
  }
}
