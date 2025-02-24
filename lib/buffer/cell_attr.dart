import 'package:xterm/theme/terminal_color.dart';
import 'package:xterm/utli/hash_values.dart';

class CellAttr {
  CellAttr({
    this.fgColor,
    this.bgColor,
    this.bold = false,
    this.faint = false,
    this.italic = false,
    this.underline = false,
    this.blink = false,
    this.inverse = false,
    this.invisible = false,
  }) : hashCode = hashValues(
          fgColor?.value,
          bgColor?.value,
          bold,
          faint,
          italic,
          underline,
          blink,
          inverse,
          invisible,
        );

  final TerminalColor? fgColor;
  final TerminalColor? bgColor;
  final bool bold;
  final bool faint;
  final bool italic;
  final bool underline;
  final bool blink;
  final bool inverse;
  final bool invisible;

  @override
  final int hashCode;

  @override
  bool operator ==(Object other) => other.hashCode == hashCode;

  // CellAttr copy() {
  //   return CellAttr(
  //     fgColor: this.fgColor,
  //     bgColor: this.bgColor,
  //     bold: this.bold,
  //     faint: this.faint,
  //     italic: this.italic,
  //     underline: this.underline,
  //     blink: this.blink,
  //     inverse: this.inverse,
  //     invisible: this.invisible,
  //   );
  // }

  // void reset({
  //   @required fgColor,
  //   bgColor,
  //   bold = false,
  //   faint = false,
  //   italic = false,
  //   underline = false,
  //   blink = false,
  //   inverse = false,
  //   invisible = false,
  // }) {
  //   this.fgColor = fgColor;
  //   this.bgColor = bgColor;
  //   this.bold = bold;
  //   this.faint = faint;
  //   this.italic = italic;
  //   this.underline = underline;
  //   this.blink = blink;
  //   this.inverse = inverse;
  //   this.invisible = invisible;
  // }

  CellAttr copyWith({
    TerminalColor? fgColor,
    TerminalColor? bgColor,
    bool? bold,
    bool? faint,
    bool? italic,
    bool? underline,
    bool? blink,
    bool? inverse,
    bool? invisible,
  }) {
    return CellAttr(
      fgColor: fgColor ?? this.fgColor,
      bgColor: bgColor ?? this.bgColor,
      bold: bold ?? this.bold,
      faint: faint ?? this.faint,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      blink: blink ?? this.blink,
      inverse: inverse ?? this.inverse,
      invisible: invisible ?? this.invisible,
    );
  }
}

class CellAttrTemplate {
  CellAttrTemplate() {
    reset();
  }

  late CellAttr _attr;

  set fgColor(TerminalColor value) {
    _attr = _attr.copyWith(fgColor: value);
  }

  set bgColor(TerminalColor value) {
    _attr = _attr.copyWith(bgColor: value);
  }

  set bold(bool value) {
    _attr = _attr.copyWith(bold: value);
  }

  set faint(bool value) {
    _attr = _attr.copyWith(faint: value);
  }

  set italic(bool value) {
    _attr = _attr.copyWith(italic: value);
  }

  set underline(bool value) {
    _attr = _attr.copyWith(underline: value);
  }

  set blink(bool value) {
    _attr = _attr.copyWith(blink: value);
  }

  set inverse(bool value) {
    _attr = _attr.copyWith(inverse: value);
  }

  set invisible(bool value) {
    _attr = _attr.copyWith(invisible: value);
  }

  CellAttr get value => _attr;

  void reset() {
    _attr = CellAttr();
  }

  void use(CellAttr attr) {
    _attr = attr;
  }
}
