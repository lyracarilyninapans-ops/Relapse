/// Responsive font-size helper.
/// Scales linearly from a 375pt base width, clamped to prevent
/// absurdly small or large text on extreme screen sizes.
const double _kBaseWidth = 375.0;
const double _kMinScale = 0.85;
const double _kMaxScale = 1.3;

double scaledFontSize(double baseSize, double screenWidth) {
  final scale = (screenWidth / _kBaseWidth).clamp(_kMinScale, _kMaxScale);
  return baseSize * scale;
}
