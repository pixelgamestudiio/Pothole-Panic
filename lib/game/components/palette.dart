import 'dart:ui';

abstract final class Palette {
  static const ink = Color(0xFF102D29);
  static const cream = Color(0xFFFFF1CD);
  static const yellow = Color(0xFFFFC83D);
  static const orange = Color(0xFFF07C45);
  static const mint = Color(0xFF98D5AD);
  static const asphalt = Color(0xFF424844);
}

void fillRound(Canvas c, Rect r, Color color, [double radius = 8]) =>
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = color,
    );

void drawLabel(
  Canvas canvas,
  String text,
  Offset offset, {
  double size = 12,
  Color color = Palette.cream,
  bool centered = true,
}) {
  final builder =
      ParagraphBuilder(
          ParagraphStyle(
            fontFamily: 'Bungee',
            fontSize: size,
            textAlign: centered ? TextAlign.center : TextAlign.left,
          ),
        )
        ..pushStyle(TextStyle(color: color))
        ..addText(text);
  final paragraph = builder.build()
    ..layout(const ParagraphConstraints(width: 400));
  canvas.drawParagraph(
    paragraph,
    Offset(centered ? offset.dx - 200 : offset.dx, offset.dy),
  );
}
