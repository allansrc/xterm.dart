import 'dart:collection';

import 'package:xterm/terminal/modes.dart';
import 'package:xterm/terminal/sgr.dart';
import 'package:xterm/terminal/terminal.dart';

typedef CsiSequenceHandler = void Function(CSI, Terminal);

final _csiHandlers = <int, CsiSequenceHandler>{
  'c'.codeUnitAt(0): csiSendDeviceAttributesHandler,
  'd'.codeUnitAt(0): csiLinePositionAbsolute,
  'f'.codeUnitAt(0): csiCursorPositionHandler,
  'g'.codeUnitAt(0): csiTabClearHandler,
  'h'.codeUnitAt(0): csiModeHandler, // SM - Set Mode
  'l'.codeUnitAt(0): csiModeHandler, // RM - Reset Mode
  'm'.codeUnitAt(0): sgrHandler,
  'n'.codeUnitAt(0): csiDeviceStatusReportHandler,
  'r'.codeUnitAt(0): csiSetMarginsHandler, // DECSTBM
  't'.codeUnitAt(0): csiWindowManipulation,
  'A'.codeUnitAt(0): csiCursorUpHandler,
  'B'.codeUnitAt(0): csiCursorDownHandler,
  'C'.codeUnitAt(0): csiCursorForwardHandler,
  'D'.codeUnitAt(0): csiCursorBackwardHandler,
  'E'.codeUnitAt(0): csiCursorNextLineHandler,
  'F'.codeUnitAt(0): csiCursorPrecedingLineHandler,
  'G'.codeUnitAt(0): csiCursorHorizontalAbsoluteHandler,
  'H'.codeUnitAt(0): csiCursorPositionHandler, // CUP - Cursor Position
  'J'.codeUnitAt(0): csiEraseInDisplayHandler, // DECSED - Selective Erase
  'K'.codeUnitAt(0): csiEraseInLineHandler,
  'L'.codeUnitAt(0): csiInsertLinesHandler,
  'M'.codeUnitAt(0): csiDeleteLinesHandler,
  'P'.codeUnitAt(0): csiDeleteHandler,
  'S'.codeUnitAt(0): csiScrollUpHandler,
  'T'.codeUnitAt(0): csiScrollDownHandler,
  'X'.codeUnitAt(0): csiEraseCharactersHandler,
  '@'.codeUnitAt(0): csiInsertBlankCharactersHandler,
};

class CSI {
  CSI({
    required this.params,
    required this.finalByte,
    required this.intermediates,
  });

  final List<String> params;
  final int finalByte;
  final List<int> intermediates;

  @override
  String toString() {
    return params.join(';') + String.fromCharCode(finalByte);
  }
}

CSI? _parseCsi(Queue<int> queue) {
  final paramBuffer = StringBuffer();
  final intermediates = <int>[];

  // Keep track of how many characters should be taken from the queue.
  var readOffset = 0;

  while (true) {
    // The sequence isn't completed, just ignore it.
    if (queue.length <= readOffset) {
      return null;
    }

    // final char = queue.removeFirst();
    final char = queue.elementAt(readOffset++);

    if (char >= 0x30 && char <= 0x3F) {
      paramBuffer.writeCharCode(char);
      continue;
    }

    if (char > 0 && char <= 0x2F) {
      intermediates.add(char);
      continue;
    }

    const csiMin = 0x40;
    const csiMax = 0x7e;

    if (char >= csiMin && char <= csiMax) {
      // The sequence is complete. So we consume it from the queue.
      for (var i = 0; i < readOffset; i++) {
        queue.removeFirst();
      }

      final params = paramBuffer.toString().split(';');
      return CSI(
        params: params,
        finalByte: char,
        intermediates: intermediates,
      );
    }
  }
}

bool csiHandler(Queue<int> queue, Terminal terminal) {
  final csi = _parseCsi(queue);

  if (csi == null) {
    return false;
  }

  terminal.debug.onCsi(csi);

  final handler = _csiHandlers[csi.finalByte];

  if (handler != null) {
    handler(csi, terminal);
  } else {
    terminal.debug.onError('unknown: $csi');
  }

  return true;
}

/// DECSED - Selective Erase In Display
///
/// ```text
/// CSI ? P s J
///
/// Erase in Display (DECSED)
///
/// P s = 0 → Selective Erase Below (default)
/// P s = 1 → Selective Erase Above
/// P s = 2 → Selective Erase All
/// ```
void csiEraseInDisplayHandler(CSI csi, Terminal terminal) {
  var ps = '0';

  if (csi.params.isNotEmpty) {
    ps = csi.params.first;
  }

  switch (ps) {
    case '':
    case '0':
      terminal.buffer.eraseDisplayFromCursor();
      break;
    case '1':
      terminal.buffer.eraseDisplayToCursor();
      break;
    case '2':
    case '3':
      terminal.buffer.eraseDisplay();
      break;
    default:
      terminal.debug.onError("Unsupported ED: CSI $ps J");
  }
}

void csiEraseInLineHandler(CSI csi, Terminal terminal) {
  var ps = '0';

  if (csi.params.isNotEmpty) {
    ps = csi.params.first;
  }

  switch (ps) {
    case '':
    case '0':
      terminal.buffer.eraseLineFromCursor();
      break;
    case '1':
      terminal.buffer.eraseLineToCursor();
      break;
    case '2':
      terminal.buffer.eraseLine();
      break;
    default:
      terminal.debug.onError("Unsupported EL: CSI $ps K");
  }
}

/// CUP - Cursor Position
void csiCursorPositionHandler(CSI csi, Terminal terminal) {
  var x = 1;
  var y = 1;

  if (csi.params.length == 2) {
    y = int.tryParse(csi.params[0]) ?? x;
    x = int.tryParse(csi.params[1]) ?? y;
  }

  terminal.buffer.setPosition(x - 1, y - 1);
}

void csiLinePositionAbsolute(CSI csi, Terminal terminal) {
  var row = 1;

  if (csi.params.isNotEmpty) {
    row = int.tryParse(csi.params.first) ?? row;
  }

  terminal.buffer.setCursorY(row - 1);
}

void csiCursorHorizontalAbsoluteHandler(CSI csi, Terminal terminal) {
  var x = 1;

  if (csi.params.isNotEmpty) {
    x = int.tryParse(csi.params.first) ?? x;
  }

  terminal.buffer.setCursorX(x - 1);
}

void csiCursorForwardHandler(CSI csi, Terminal terminal) {
  var offset = 1;

  if (csi.params.isNotEmpty) {
    offset = int.tryParse(csi.params.first) ?? offset;
  }

  terminal.buffer.movePosition(offset, 0);
}

void csiCursorBackwardHandler(CSI csi, Terminal terminal) {
  var offset = 1;

  if (csi.params.isNotEmpty) {
    offset = int.tryParse(csi.params.first) ?? offset;
  }

  terminal.buffer.movePosition(-offset, 0);
}

void csiEraseCharactersHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  terminal.buffer.eraseCharacters(count);
}

void csiModeHandler(CSI csi, Terminal terminal) {
  // terminal.ActiveBuffer().ClearSelection()
  return csiSetModes(csi, terminal);
}

void csiDeviceStatusReportHandler(CSI csi, Terminal terminal) {
  if (csi.params.isEmpty) return;

  switch (csi.params[0]) {
    case "5":
      terminal.onInput("\x1b[0n");
      break;
    case "6": // report cursor position
      terminal.onInput("\x1b[${terminal.cursorX + 1};${terminal.cursorY + 1}R");
      break;
    default:
      terminal.debug
          .onError('Unknown Device Status Report identifier: ${csi.params[0]}');
      return;
  }
}

void csiSendDeviceAttributesHandler(CSI csi, Terminal terminal) {
  var response = '?1;2';

  if (csi.params.isNotEmpty && csi.params.first.startsWith('>')) {
    response = '>0;0;0';
  }

  terminal.onInput('\x1b[${response}c');
}

void csiCursorUpHandler(CSI csi, Terminal terminal) {
  var distance = 1;

  if (csi.params.isNotEmpty) {
    distance = int.tryParse(csi.params.first) ?? distance;
  }

  terminal.buffer.movePosition(0, -distance);
}

void csiCursorDownHandler(CSI csi, Terminal terminal) {
  var distance = 1;

  if (csi.params.isNotEmpty) {
    distance = int.tryParse(csi.params.first) ?? distance;
  }

  terminal.buffer.movePosition(0, distance);
}

/// DECSTBM – Set Top and Bottom Margins (DEC Private)
///
/// ESC [ Pn; Pn r
///
/// This sequence sets the top and bottom margins to define the scrolling
/// region. The first parameter is the line number of the first line in the
/// scrolling region; the second parameter is the line number of the bottom line
/// in the scrolling region. Default is the en tire screen (no margins). The
/// minimum size of the scrolling region allowed is two lines, i.e., the top
/// margin must be less than the bottom margin. The cursor is placed in the home
/// position (see Origin Mode DECOM).
void csiSetMarginsHandler(CSI csi, Terminal terminal) {
  var top = 1;
  var bottom = terminal.viewHeight;

  if (csi.params.length > 2) {
    return;
  }

  if (csi.params.isNotEmpty) {
    top = int.tryParse(csi.params[0]) ?? top;

    if (csi.params.length > 1) {
      bottom = int.tryParse(csi.params[1]) ?? bottom;
    }
  }

  terminal.buffer.setVerticalMargins(top - 1, bottom - 1);
  terminal.buffer.setPosition(0, 0);
}

void csiDeleteHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.deleteChars(count);
}

void csiTabClearHandler(CSI csi, Terminal terminal) {
  // TODO
}

void csiWindowManipulation(CSI csi, Terminal terminal) {
  // not supported
}

void csiCursorNextLineHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.moveCursorY(count);
  terminal.buffer.setCursorX(0);
}

void csiCursorPrecedingLineHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.moveCursorY(-count);
  terminal.buffer.setCursorX(0);
}

void csiInsertLinesHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.insertLines(count);
}

void csiDeleteLinesHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.deleteLines(count);
}

void csiScrollUpHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.areaScrollUp(count);
}

void csiScrollDownHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.areaScrollDown(count);
}

void csiInsertBlankCharactersHandler(CSI csi, Terminal terminal) {
  var count = 1;

  if (csi.params.isNotEmpty) {
    count = int.tryParse(csi.params.first) ?? count;
  }

  if (count < 1) {
    count = 1;
  }

  terminal.buffer.insertBlankCharacters(count);
}
