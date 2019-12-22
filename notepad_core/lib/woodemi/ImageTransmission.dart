class ImageTransmission {
  static const HEADER_LENGTH = 58;
  static const EMPTY_LENGTH = HEADER_LENGTH + 6 /*empty imageTagValue*/ + 8 /*crcTagValue*/;
}