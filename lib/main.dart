import 'package:flutter/material.dart';
import 'package:flutter_svg_clickable/svg_parser/parser.dart';
import 'package:touchable/touchable.dart';

import 'svg_parser/parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HumanBody(),
    );
  }
}

class HumanBody extends StatefulWidget {
  @override
  _HumanBodyState createState() => _HumanBodyState();
}

const double SvgWidth = 517.477; //1369; //612.54211;
const double SvgHeight = 1101.894; //1141; //723.61865;

class _HumanBodyState extends State<HumanBody> {
  Path _selectPath;
  final svgPath = "assets/body.svg";
  List<Path> paths = [];
  List<PathSegment> pathsegments = [];

  Offset touchPosition;

  GlobalKey _key = GlobalKey();

  String bodyPart;
  String selectedBodyPart;

  @override
  void initState() {
    parseSvgToPath();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("svg clickable Human body parts")),
      body: Center(
        child: Stack(
          children: [
            Container(
              key: _key,
              color: Colors.white, // just make a difference
              width:
                  double.infinity, // full screen here, you can change size to see different effect
              height: double.infinity,
              child: CanvasTouchDetector(
                builder: (context) => CustomPaint(
                  painter: PathPainter(
                    context: context,
                    paths: paths,
                    curPath: _selectPath,
                    segments: pathsegments,
                    onPressed: (curPath, details, pathname) {
                      print(details.globalPosition);
                      print(details.localPosition);
                      // if (bodyPart != pathname)
                      setState(() {
                        _selectPath = curPath;
                        touchPosition = details.localPosition;
                        bodyPart = pathname;
                        selectedBodyPart = null;
                      });
                    },
                  ),
                ),
              ),
            ),
            if (touchPosition != null)
              Builder(builder: (context) {
                CrossAxisAlignment alignment = CrossAxisAlignment.start;
                VerticalDirection direction = VerticalDirection.down;
                var box = _key.currentContext.findRenderObject() as RenderBox;
                var width;
                var height;
                var xpos = touchPosition.dx;
                var ypos = touchPosition.dy;
                if (box != null) {
                  width = box.size.width;
                  height = box.size.height;
                  if ((100 + touchPosition.dx) > width) {
                    xpos = xpos - 100 + 15;
                    alignment = CrossAxisAlignment.end;
                  }
                  if ((50 + touchPosition.dy) > height) {
                    ypos = ypos - 50 + 15;
                    direction = VerticalDirection.up;
                  }
                }
                return Positioned(
                  left: xpos - 8,
                  top: ypos - 8,
                  child: Container(
                    height: 50,
                    width: 100,
                    // color: Colors.redAccent,
                    child: Column(
                      crossAxisAlignment: alignment,
                      verticalDirection: direction,
                      children: [
                        Container(
                          height: 16,
                          width: 16,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        InkWell(
                          onTap: () {
                            print("clicked");
                            setState(() {
                              selectedBodyPart = bodyPart;
                            });
                          },
                          child: Container(
                            // margin: EdgeInsets.only(top: spacing2),
                            child: Text(
                              bodyPart.toUpperCase() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10),
                            ),
                            alignment: Alignment.center,
                            height: 18,
                            width: width,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 1),
                                color: selectedBodyPart == bodyPart
                                    ? Colors.blueGrey
                                    : Colors.grey),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void parseSvgToPath() {
    SvgParser parser = SvgParser();
    parser.loadFromFile(svgPath).then((value) {
      setState(() {
        paths = parser.getPaths();
        pathsegments = parser.pathSegmentList;
      });
    });
  }
}

class PathPainter extends CustomPainter {
  final BuildContext context;
  final List<Path> paths;
  final List<PathSegment> segments;
  final Path curPath;
  final Function(Path curPath, TapDownDetails tapDownDetails, String pathName)
      onPressed;
  PathPainter(
      {this.context, this.paths, this.curPath, this.onPressed, this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    // calculate the scale factor, use the min value
    final double xScale = size.width / SvgWidth;
    final double yScale = size.height / SvgHeight;
    final double scale = xScale < yScale ? xScale : yScale;

    // scale each path to match canvas size
    final Matrix4 matrix4 = Matrix4.identity();
    matrix4.scale(scale, scale);

    // calculate the scaled svg image width and height in order to get right offset
    double scaledSvgWidth = SvgWidth * scale;
    double scaledSvgHeight = SvgHeight * scale;
    // calculate offset to center the svg image
    double offsetX = (size.width - scaledSvgWidth) / 2;
    double offsetY = (size.height - scaledSvgHeight) / 2;

    // make canvas clickable, see: https://pub.dev/packages/touchable
    final TouchyCanvas touchCanvas = TouchyCanvas(context, canvas);
    // your paint
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // print(paths.length);
    // print(segments.length);
    for (var i = 0; i <= paths.length - 1; i++) {
      // paint.style =
      //     paths[i] == curPath ? PaintingStyle.fill : PaintingStyle.stroke;

      touchCanvas.drawPath(
        // scale and offset each path to match the canvas
        paths[i].transform(matrix4.storage).shift(Offset(offsetX, offsetY)),
        paint,
        onTapDown: (details) {
          // notify select change and redraw
          onPressed(paths[i], details, segments[i].pathname);
          print(segments[i].pathname);
        },
      );
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}
