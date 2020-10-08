import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart' as xml;
class SvgParser {
  final List<PathSegment> pathSegments = List<PathSegment>();

  List<PathSegment> pathSegmentList = List<PathSegment>();
  List<Path> _paths = new List<Path>();

  Color parseColor(String cStr) {
    if (cStr == null || cStr.isEmpty)
      throw UnsupportedError("Empty color field found.");
    if (cStr[0] == '#') {
      return new Color(int.parse(cStr.substring(1), radix: 16)).withOpacity(
          1.0); 
    } else if (cStr == 'none') {
      return Colors.transparent;
    } else {
      throw UnsupportedError(
          "Only hex color format currently supported. String:  $cStr");
    }
  }

  void addPathSegments(Path path, int index, double strokeWidth, Color color,String pathname) {
    int firstPathSegmentIndex = this.pathSegments.length;
    int relativeIndex = 0;
    path.computeMetrics().forEach((pp) {
      PathSegment segment = new PathSegment()
        ..path = pp.extractPath(0, pp.length)
        ..length = pp.length
        ..firstSegmentOfPathIndex = firstPathSegmentIndex
        ..pathIndex = index
        ..pathname = pathname
        ..relativeIndex = relativeIndex;

      if (color != null) segment.color = color;

      if (strokeWidth != null) segment.strokeWidth = strokeWidth;

      this.pathSegments.add(segment);
      relativeIndex++;
    });
  }

  void loadFromString(String svgString) {
    this.pathSegments.clear();
    int index = 0; 
    var doc = xml.parse(svgString);
    doc
        .findAllElements("path")
        .map((node) => node.attributes)
        .forEach((attributes) {
      var dPath = attributes.firstWhere((attr) => attr.name.local == "d",
          orElse: () => null);
      if (dPath != null) {
        Path path = new Path();
        writeSvgPathDataToPath(dPath.value, new PathModifier(path));

        Color color;
        double strokeWidth;
//-------------------------
        // var id = attributes.firstWhere((attr) => attr.name.local == "data-name",
        //     orElse: () => null);
            var id = attributes.firstWhere((attr) => attr.name.local == "id",
            orElse: () => null);
        String pathname;
        if (id != null) {
          // var newstr = id.toString().substring(11);
          var newstr = id.toString().substring(4);
          // print(id.toString().substring(11));
          pathname = newstr.substring(0, newstr.length - 1);
          print(pathname);
        }

//-------------------------
        //Attributes - [1] css-styling
        var style = attributes.firstWhere((attr) => attr.name.local == "style",
            orElse: () => null);

        if (style != null) {
          //Parse color of stroke
          RegExp exp = new RegExp(r"stroke:([^;]+);");
          Match match = exp.firstMatch(style.value);
          if (match != null) {
            String cStr = match.group(1);
            color = parseColor(cStr);
          }
          //Parse stroke-width
          exp = new RegExp(r"stroke-width:([0-9.]+)");
          match = exp.firstMatch(style.value);
          if (match != null) {
            String cStr = match.group(1);
            strokeWidth = double.tryParse(cStr) ?? null;
          }
        }

        //Attributes - [2] svg-attributes
        var strokeElement = attributes.firstWhere(
            (attr) => attr.name.local == "stroke",
            orElse: () => null);
        if (strokeElement != null) {
          color = parseColor(strokeElement.value);
        }

        var strokeWidthElement = attributes.firstWhere(
            (attr) => attr.name.local == "stroke-width",
            orElse: () => null);
        if (strokeWidthElement != null) {
          strokeWidth = double.tryParse(strokeWidthElement.value) ?? null;
        }

        this._paths.add(path);
        var segment = PathSegment()..pathname = pathname;
        
        pathSegmentList.add(segment);
        addPathSegments(path, index, strokeWidth, color,pathname);
        index++;
      }
    });
  }

  void loadFromPaths(List<Path> paths) {
    this.pathSegments.clear();
    this._paths = paths;

    int index = 0;
    paths.forEach((p) {
      assert(p != null,
          "Path element in `paths` must not be null."); 
      addPathSegments(p, index, null,null,
          null); 
      index++;
    });
  }

  /// Parses Svg from provided asset path
  Future<void> loadFromFile(String file) async {
    this.pathSegments.clear();
    String svgString = await rootBundle.loadString(file);
    loadFromString(svgString);
  }

  /// Returns extracted [PathSegment] elements of parsed Svg
  List<PathSegment> getPathSegments() {
    return this.pathSegments;
  }

  /// Returns extracted [Path] elements of parsed Svg
  List<Path> getPaths() {
    return this._paths;
  }
}

class PathSegment {
  PathSegment()
      : strokeWidth = 0.0,
        color = Colors.black,
        firstSegmentOfPathIndex = 0,
        relativeIndex = 0,
        pathIndex = 0 {
    //That is fun.
    // List colors = [Colors.red, Colors.green, Colors.yellow];
    // Random random = new Random();
    // color = colors[random.nextInt(3)];
  }

//--------------------
  String pathname;
//-------------------- 

  /// A continuous path/segment
  Path path;
  double strokeWidth;
  Color color;

  /// Length of the segment path
  double length;

  /// Denotes the index of the first segment of the containing path when PathOrder.original
  int firstSegmentOfPathIndex;

  /// Corresponding containing path index
  int pathIndex;

  /// Denotes relative index to  firstSegmentOfPathIndex
  int relativeIndex;
}

/// A [PathProxy] that saves Path command in path
class PathModifier extends PathProxy {
  PathModifier(this.path);

  Path path;

  @override
  void close() {
    path.close();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }
}
