/// Responsive font-size helper.
/// Scales linearly from a 375pt base width.
double scaledFontSize(double baseSize, double screenWidth) {
  return baseSize * (screenWidth / 375.0);
}
